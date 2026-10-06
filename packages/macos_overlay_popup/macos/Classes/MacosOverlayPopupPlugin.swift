import Cocoa
import FlutterMacOS
import ApplicationServices
import Carbon.HIToolbox
import Vision
#if canImport(just_audio)
import just_audio
#endif

public class MacosOverlayPopupPlugin: NSObject, FlutterPlugin {
  private let overlayPopupEventsHandler = DesktopEventStreamHandler()
  private let popupBridgeEventsHandler = DesktopEventStreamHandler()
  private let systemSelectionHandler = MacSystemSelectionStreamHandler()
  private let popupWindowController = FloatingPopupWindowController(entrypoint: "overlayMain")
  private var popupSaveRequestId = 1
  private var pendingPopupSaveResults: [Int: FlutterResult] = [:]
  private var overlayChannelsRegistered = false

  // #region agent log
  fileprivate static func emitDebugLog(
    hypothesisId: String,
    location: String,
    message: String,
    data: [String: Any] = [:]
  ) {
    _ = hypothesisId
    _ = location
    _ = message
    _ = data
  }
  // #endregion

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "formycareer/overlay_window",
      binaryMessenger: registrar.messenger
    )
    let instance = MacosOverlayPopupPlugin()
    instance.systemSelectionHandler.setCaptureSuppressedProvider { [weak instance] in
      instance?.popupWindowController.isPopupVisible ?? false
    }
    instance.systemSelectionHandler.setDismissPopupHandler { [weak instance] in
      instance?.popupWindowController.hidePopup()
    }
    instance.popupWindowController.onPopupWillHide = { [weak instance] in
      instance?.systemSelectionHandler.armSyntheticCopyMinGapBypassOnce()
    }
    instance.popupWindowController.onPopupDidHide = { [weak instance] hadVisible in
      instance?.systemSelectionHandler.resetEmittedSelectionDedup()
      if hadVisible,
        let inst = instance,
        !inst.systemSelectionHandler.shouldSkipPostHideSyntheticRecaptureAndConsume()
      {
        inst.systemSelectionHandler.schedulePostHideRecapture()
      }
    }
    instance.popupWindowController.onOutsidePointerWillDismissPopup = { [weak instance] event in
      instance?.systemSelectionHandler.handleOutsidePointerWillDismissPopup(for: event)
    }
    instance.popupWindowController.prepareOverlayIfNeeded()
    instance.registerOverlayEngineChannelsIfNeeded()
    registrar.addMethodCallDelegate(instance, channel: channel)

    let popupBridgeEvents = FlutterEventChannel(
      name: "formycareer/popup_bridge_events",
      binaryMessenger: registrar.messenger
    )
    popupBridgeEvents.setStreamHandler(instance.popupBridgeEventsHandler)

    let popupBridge = FlutterMethodChannel(
      name: "formycareer/popup_bridge",
      binaryMessenger: registrar.messenger
    )
    popupBridge.setMethodCallHandler { call, result in
      switch call.method {
      case "completeSaveRequest":
        instance.handleCompleteSaveRequest(call: call, result: result)
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    let systemSelection = FlutterEventChannel(
      name: "formycareer/system_text_selection",
      binaryMessenger: registrar.messenger
    )
    systemSelection.setStreamHandler(instance.systemSelectionHandler)

    let ocrChannel = FlutterMethodChannel(
      name: "formycareer/ocr",
      binaryMessenger: registrar.messenger
    )
    ocrChannel.setMethodCallHandler { call, result in
      instance.handleOcrMethodCall(call: call, result: result)
    }
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "showOverlayNearCursor":
      let args = call.arguments as? [String: Any]
      let popupWidth = CGFloat((args?["popupWidth"] as? Double) ?? 460.0)
      let popupHeight = CGFloat((args?["popupHeight"] as? Double) ?? 540.0)
      let offsetX = CGFloat((args?["offsetX"] as? Double) ?? 10.0)
      let offsetY = CGFloat((args?["offsetY"] as? Double) ?? 10.0)
      let selectedText = (args?["selectedText"] as? String) ?? ""
      let sourceUrl = resolvedSourceUrlHint((args?["sourceUrl"] as? String) ?? "")
      let sourceApp = resolveSourceAppHint(
        (args?["sourceApp"] as? String) ?? "",
        sourceUrl: sourceUrl
      )

      let response = popupWindowController.showPopupNearCursor(
        width: popupWidth,
        height: popupHeight,
        offsetX: offsetX,
        offsetY: offsetY,
        selectedText: selectedText,
        sourceApp: sourceApp
      )
      if response["success"] as? Bool == true {
        let requestId = nextPopupRequestId()
        let regionLeft = args?["regionLeft"] ?? NSNull()
        let regionTop = args?["regionTop"] ?? NSNull()
        let regionWidth = args?["regionWidth"] ?? NSNull()
        let regionHeight = args?["regionHeight"] ?? NSNull()
        let nativeLanguage = args?["nativeLanguage"] ?? NSNull()
        registerOverlayEngineChannelsIfNeeded()
        overlayPopupEventsHandler.emit([
          "requestId": requestId,
          "mode": (args?["mode"] as? String) ?? "text",
          "cursorX": NSEvent.mouseLocation.x,
          "cursorY": NSEvent.mouseLocation.y,
          "regionLeft": regionLeft,
          "regionTop": regionTop,
          "regionWidth": regionWidth,
          "regionHeight": regionHeight,
          "selectedText": selectedText,
          "sourceApp": sourceApp,
          "sourceUrl": sourceUrl,
          "tagSuggestions": (args?["tagSuggestions"] as? [String]) ?? [],
          "nativeLanguage": nativeLanguage,
          "sourceLanguages": (args?["sourceLanguages"] as? [String]) ?? [],
        ])
      }
      result(response)
    case "hideOverlay":
      popupWindowController.hidePopup()
      result([
        "success": true,
        "fallbackUsed": false,
        "reason": "ok",
      ])
    case "isRunnerForeground":
      result(NSApp.isActive)
    case "activateRunner":
      Self.bringRunnerToFront()
      result(nil)
    case "getCursorPosition":
      let location = NSEvent.mouseLocation
      result(["x": location.x, "y": location.y])
    case "setSelectionCaptureExtras":
      if let args = call.arguments as? [String: Any] {
        let clipboardListen = (args["clipboardListen"] as? Bool) ?? false
        let dragSendCtrlC = (args["dragSendCtrlC"] as? Bool) ?? false
        systemSelectionHandler.setAutoCaptureEnabled(clipboardListen || dragSendCtrlC)
      }
      result(nil)
    case "getPermissionStatus":
      result([
        "accessibility": DesktopPermissionBridge.accessibilityGranted(),
        "screenRecording": DesktopPermissionBridge.screenRecordingGranted(),
      ])
    case "requestMissingPermissions":
      DesktopPermissionBridge.requestMissingPermissions()
      result([
        "accessibility": DesktopPermissionBridge.accessibilityGranted(),
        "screenRecording": DesktopPermissionBridge.screenRecordingGranted(),
      ])
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private static func bringRunnerToFront() {
    DispatchQueue.main.async {
      NSRunningApplication.current.activate(options: [.activateAllWindows, .activateIgnoringOtherApps])
      NSApp.activate(ignoringOtherApps: true)
      for window in NSApp.windows {
        if window.isMiniaturized {
          window.deminiaturize(nil)
        }
        window.orderFrontRegardless()
        window.makeKey()
      }
    }
  }

  private func nextPopupRequestId() -> Int {
    popupSaveRequestId += 1
    if popupSaveRequestId > 1_000_000_000 {
      popupSaveRequestId = 2
    }
    return popupSaveRequestId
  }

  private func handleSaveCapturedWord(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any] else {
      result([
        "success": false,
        "message": "Invalid save request payload.",
      ])
      return
    }
    let requestId = nextPopupRequestId()
    pendingPopupSaveResults[requestId] = result
    let selectionStart = args["selectionStart"] ?? NSNull()
    let selectionEnd = args["selectionEnd"] ?? NSNull()
    popupBridgeEventsHandler.emit([
      "requestId": requestId,
      "sourceText": args["sourceText"] as? String ?? "",
      "translatedText": args["translatedText"] as? String ?? "",
      "languagePair": args["languagePair"] as? String ?? "",
      "passage": args["passage"] as? String ?? "",
      "sourceUrl": args["sourceUrl"] as? String ?? "",
      "selectionStart": selectionStart,
      "selectionEnd": selectionEnd,
      "sourceApp": args["sourceApp"] as? String ?? "",
      "tags": (args["tags"] as? [String]) ?? [],
    ])
    DispatchQueue.main.asyncAfter(deadline: .now() + 6.0) { [weak self] in
      guard let self else {
        return
      }
      if let pending = self.pendingPopupSaveResults.removeValue(forKey: requestId) {
        pending([
          "success": false,
          "message": "Timed out waiting for save result.",
        ])
      }
    }
  }

  private func handleCompleteSaveRequest(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any] else {
      result(false)
      return
    }
    let requestId = args["requestId"] as? Int ?? -1
    let success = args["success"] as? Bool ?? false
    let message = args["message"] as? String ?? (success ? "Saved ✓" : "Save failed")
    if let pending = pendingPopupSaveResults.removeValue(forKey: requestId) {
      pending([
        "success": success,
        "message": message,
      ])
      result(true)
      return
    }
    result(false)
  }

  private func registerOverlayEngineChannelsIfNeeded() {
    guard !overlayChannelsRegistered else {
      return
    }
    guard let messenger = popupWindowController.overlayBinaryMessenger else {
      return
    }
    overlayChannelsRegistered = true
    let popupWindowEvents = FlutterEventChannel(
      name: "formycareer/popup_window_events",
      binaryMessenger: messenger
    )
    popupWindowEvents.setStreamHandler(overlayPopupEventsHandler)

    let popupWindowControl = FlutterMethodChannel(
      name: "formycareer/popup_window_control",
      binaryMessenger: messenger
    )
    popupWindowControl.setMethodCallHandler { [weak self] call, result in
      guard let self else {
        result(FlutterMethodNotImplemented)
        return
      }
      switch call.method {
      case "hidePopupWindow":
        self.popupWindowController.hidePopup()
        result([
          "success": true,
          "fallbackUsed": false,
          "reason": "ok",
        ])
      case "setPopupFrameSize":
        if
          let args = call.arguments as? [String: Any],
          let width = args["width"] as? Double,
          let height = args["height"] as? Double
        {
          self.popupWindowController.setPopupSize(
            width: CGFloat(width),
            height: CGFloat(height)
          )
        }
        result([
          "success": true,
          "reason": "ok",
        ])
      case "saveCapturedWord":
        self.handleSaveCapturedWord(call: call, result: result)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func resolveSourceAppHint(_ provided: String, sourceUrl: String) -> String {
    let normalizedProvided = provided.trimmingCharacters(in: .whitespacesAndNewlines)
    let currentAppName = NSRunningApplication.current.localizedName ?? ""
    let frontmost = NSWorkspace.shared.frontmostApplication?.localizedName?.trimmingCharacters(
      in: .whitespacesAndNewlines
    ) ?? ""
    let appName: String
    if !frontmost.isEmpty && frontmost.caseInsensitiveCompare(currentAppName) != .orderedSame {
      appName = frontmost
    } else {
      appName = normalizedProvided
    }
    if appName.isEmpty {
      return normalizedProvided
    }
    // Keep detailed labels from Dart as-is.
    if normalizedProvided.contains("—") || normalizedProvided.contains("|") {
      return normalizedProvided
    }
    let title = frontmostWindowTitle(ownerAppName: appName)
    let domain = domainFromUrl(sourceUrl)
    if !title.isEmpty && !domain.isEmpty {
      return "\(title) — \(appName) — \(domain)"
    }
    if !title.isEmpty {
      return "\(title) — \(appName)"
    }
    if !domain.isEmpty {
      return "\(appName) — \(domain)"
    }
    return appName
  }

  private func resolvedSourceUrlHint(_ provided: String) -> String {
    let normalized = provided.trimmingCharacters(in: .whitespacesAndNewlines)
    if !normalized.isEmpty {
      return normalized
    }
    let frontmost = NSWorkspace.shared.frontmostApplication?.localizedName?.trimmingCharacters(
      in: .whitespacesAndNewlines
    ) ?? ""
    return frontBrowserUrl(appName: frontmost)
  }

  private func frontmostWindowTitle(ownerAppName: String) -> String {
    let owner = ownerAppName.trimmingCharacters(in: .whitespacesAndNewlines)
    if owner.isEmpty {
      return ""
    }
    guard
      let infos = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID)
        as? [[String: Any]]
    else {
      return ""
    }
    for info in infos {
      let ownerName = (info[kCGWindowOwnerName as String] as? String)?.trimmingCharacters(
        in: .whitespacesAndNewlines
      ) ?? ""
      if ownerName.caseInsensitiveCompare(owner) != .orderedSame {
        continue
      }
      let layer = info[kCGWindowLayer as String] as? Int ?? 0
      if layer != 0 {
        continue
      }
      let title = (info[kCGWindowName as String] as? String)?.trimmingCharacters(
        in: .whitespacesAndNewlines
      ) ?? ""
      if !title.isEmpty {
        return title
      }
    }
    return ""
  }

  private func frontBrowserUrl(appName: String) -> String {
    let app = appName.trimmingCharacters(in: .whitespacesAndNewlines)
    if app.isEmpty {
      return ""
    }
    let script: String
    switch app {
    case "Google Chrome", "Chromium", "Microsoft Edge", "Brave Browser", "Arc", "Opera":
      script = "tell application \"\(app)\" to get URL of active tab of front window"
    case "Safari":
      script = "tell application \"Safari\" to get URL of front document"
    default:
      script = ""
    }
    if script.isEmpty {
      return ""
    }
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
    process.arguments = ["-e", script]
    let outputPipe = Pipe()
    process.standardOutput = outputPipe
    process.standardError = Pipe()
    do {
      try process.run()
      process.waitUntilExit()
      if process.terminationStatus != 0 {
        return ""
      }
      let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
      let output = String(data: outputData, encoding: .utf8)?
        .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
      return output.lowercased() == "missing value" ? "" : output
    } catch {
      return ""
    }
  }

  private func domainFromUrl(_ raw: String) -> String {
    let value = raw.trimmingCharacters(in: .whitespacesAndNewlines)
    if value.isEmpty {
      return ""
    }
    guard let url = URL(string: value), let host = url.host?.lowercased() else {
      return ""
    }
    return host.hasPrefix("www.") ? String(host.dropFirst(4)) : host
  }

  private func handleOcrMethodCall(call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getSupportedLanguages":
      DispatchQueue.global(qos: .userInitiated).async {
        let langs = Self.supportedVisionRecognitionLanguages()
        DispatchQueue.main.async {
          result(langs)
        }
      }
    case "extractText":
      DispatchQueue.global(qos: .userInitiated).async {
        let text = Self.extractTextInteractiveMac()
        DispatchQueue.main.async {
          result(text)
        }
      }
    case "extractTextFromRegion":
      guard let args = call.arguments as? [String: Any] else {
        result("")
        return
      }
      let left = (args["left"] as? Double) ?? 0.0
      let top = (args["top"] as? Double) ?? 0.0
      let width = (args["width"] as? Double) ?? 0.0
      let height = (args["height"] as? Double) ?? 0.0
      DispatchQueue.global(qos: .userInitiated).async {
        let text = Self.extractTextFromRegionMac(
          left: left,
          top: top,
          width: width,
          height: height
        )
        DispatchQueue.main.async {
          result(text)
        }
      }
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private static func supportedVisionRecognitionLanguages() -> [String] {
    if #available(macOS 10.15, *) {
      do {
        let langs = try VNRecognizeTextRequest.supportedRecognitionLanguages(
          for: .accurate,
          revision: VNRecognizeTextRequest.currentRevision
        )
        return langs
      } catch {
        return []
      }
    }
    return []
  }

  private static func extractTextInteractiveMac() -> String {
    guard let imagePath = captureInteractiveRegionToTempPng() else {
      return ""
    }
    defer {
      try? FileManager.default.removeItem(atPath: imagePath)
    }
    return recognizeTextFromImage(atPath: imagePath)
  }

  private static func extractTextFromRegionMac(
    left: Double,
    top: Double,
    width: Double,
    height: Double
  ) -> String {
    guard let imagePath = captureRegionToTempPng(
      left: left,
      top: top,
      width: width,
      height: height
    ) else {
      return ""
    }
    defer {
      try? FileManager.default.removeItem(atPath: imagePath)
    }
    return recognizeTextFromImage(atPath: imagePath)
  }

  private static func captureInteractiveRegionToTempPng() -> String? {
    let tempPath = (NSTemporaryDirectory() as NSString)
      .appendingPathComponent("fmc-ocr-\(UUID().uuidString).png")
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
    process.arguments = ["-i", "-x", tempPath]
    do {
      try process.run()
      process.waitUntilExit()
      guard process.terminationStatus == 0 else {
        return nil
      }
      return FileManager.default.fileExists(atPath: tempPath) ? tempPath : nil
    } catch {
      return nil
    }
  }

  private static func captureRegionToTempPng(
    left: Double,
    top: Double,
    width: Double,
    height: Double
  ) -> String? {
    let w = Int(width.rounded())
    let h = Int(height.rounded())
    guard w > 0, h > 0 else {
      return nil
    }
    let x = Int(left.rounded())
    let y = Int(top.rounded())
    let regionArg = "\(x),\(y),\(w),\(h)"
    let tempPath = (NSTemporaryDirectory() as NSString)
      .appendingPathComponent("fmc-ocr-\(UUID().uuidString).png")
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
    process.arguments = ["-x", "-R", regionArg, tempPath]
    do {
      try process.run()
      process.waitUntilExit()
      guard process.terminationStatus == 0 else {
        return nil
      }
      return FileManager.default.fileExists(atPath: tempPath) ? tempPath : nil
    } catch {
      return nil
    }
  }

  private static func recognizeTextFromImage(atPath path: String) -> String {
    guard let image = NSImage(contentsOfFile: path) else {
      return ""
    }
    guard
      let tiffData = image.tiffRepresentation,
      let bitmap = NSBitmapImageRep(data: tiffData),
      let cgImage = bitmap.cgImage
    else {
      return ""
    }
    let request = VNRecognizeTextRequest()
    request.recognitionLevel = .accurate
    request.usesLanguageCorrection = true
    let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
    do {
      try handler.perform([request])
      guard let observations = request.results else {
        return ""
      }
      let lines = observations.compactMap { observation in
        observation.topCandidates(1).first?.string.trimmingCharacters(in: .whitespacesAndNewlines)
      }.filter { !$0.isEmpty }
      return lines.joined(separator: "\n")
    } catch {
      return ""
    }
  }
}

private enum DesktopPermissionBridge {
  static func accessibilityGranted() -> Bool {
    AXIsProcessTrusted()
  }

  static func screenRecordingGranted() -> Bool {
    if #available(macOS 10.15, *) {
      return CGPreflightScreenCaptureAccess()
    }
    return true
  }

  static func requestMissingPermissions() {
    if !accessibilityGranted() {
      let options = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: true] as CFDictionary
      _ = AXIsProcessTrustedWithOptions(options)
    }
    if #available(macOS 10.15, *) {
      if !screenRecordingGranted() {
        _ = CGRequestScreenCaptureAccess()
      }
    }
  }
}

private final class FloatingPopupWindowController {
  private let overlayEntrypoint: String
  private var panel: NSPanel?
  private var overlayEngine: FlutterEngine?
  private var outsideClickMonitor: Any?
  /// PID of the app that was frontmost immediately before `makeKey` on the popup
  /// (usually the browser where text was selected). Restored on hide so Cmd+C /
  /// selection capture targets the correct process.
  private var hostAppPidToRestoreAfterPopup: pid_t?
  /// Fired once when popup was visible before hide (selection handler may widen
  /// the synthetic Cmd+C throttle for the gesture that follows activation).
  var onPopupWillHide: (() -> Void)?
  /// Clears selection-stream dedup state so the user can trigger auto-capture
  /// again with the same literal text after dismissing the popup.
  /// `true` when the panel was visible at the start of `hidePopup` (before teardown).
  var onPopupDidHide: ((_ hadVisiblePopup: Bool) -> Void)?
  /// Fired on the global event that dismisses the popup because the pointer is outside
  /// the panel (before `hidePopup`). Used to defer synthetic Cmd+C until the outside
  /// gesture finishes so the user can select the next word on a clean pointer state.
  var onOutsidePointerWillDismissPopup: ((NSEvent) -> Void)?

  init(entrypoint: String) {
    overlayEntrypoint = entrypoint
  }

  func prepareOverlayIfNeeded() {
    ensurePanel(size: NSSize(width: 520, height: 620))
  }

  var overlayBinaryMessenger: FlutterBinaryMessenger? {
    overlayEngine?.binaryMessenger
  }

  var isPopupVisible: Bool {
    guard let panel else {
      return false
    }
    // Treat fully transparent panel as not visible for capture suppression.
    // This avoids stale "visible" state when UI has already faded out.
    return panel.isVisible && panel.alphaValue > 0.01
  }

  func showPopupNearCursor(
    width: CGFloat,
    height: CGFloat,
    offsetX: CGFloat,
    offsetY: CGFloat,
    selectedText: String,
    sourceApp: String
  ) -> [String: Any] {
    let contentSize = NSSize(width: max(260, width), height: max(180, height))
    let popupSize = panel?.frameRect(forContentRect: NSRect(origin: .zero, size: contentSize)).size
      ?? contentSize
    let cursor = NSEvent.mouseLocation
    let frameOrigin = clampedOrigin(
      cursor: cursor,
      popupSize: popupSize,
      offsetX: offsetX,
      offsetY: offsetY
    )
    ensurePanel(size: popupSize)
    panel?.setFrame(NSRect(origin: frameOrigin, size: popupSize), display: true)
    panel?.alphaValue = 0.0
    let selfPid = ProcessInfo.processInfo.processIdentifier
    if let front = NSWorkspace.shared.frontmostApplication,
       front.processIdentifier != selfPid
    {
      hostAppPidToRestoreAfterPopup = front.processIdentifier
    } else {
      hostAppPidToRestoreAfterPopup = nil
    }
    panel?.orderFrontRegardless()
    panel?.makeKey()
    panel?.alphaValue = 1.0
    startOutsideClickMonitor()
    return [
      "success": true,
      "fallbackUsed": false,
      "reason": "ok",
      "contentLeft": frameOrigin.x,
      "contentTop": frameOrigin.y,
      "scale": 1.0,
    ]
  }

  func hidePopup() {
    let hadVisiblePopup = panel?.isVisible == true
    if hadVisiblePopup {
      onPopupWillHide?()
    }
    panel?.resignKey()
    panel?.orderOut(nil)
    panel?.alphaValue = 0.0
    stopOutsideClickMonitor()
    let pid = hostAppPidToRestoreAfterPopup
    hostAppPidToRestoreAfterPopup = nil
    let selfPid = ProcessInfo.processInfo.processIdentifier
    if let pid, pid != selfPid,
      let hostApp = NSRunningApplication(processIdentifier: pid)
    {
      // #region agent log
      MacosOverlayPopupPlugin.emitDebugLog(
        hypothesisId: "H36",
        location: "FloatingPopupWindowController.hidePopup",
        message: "Re-activating host app before next selection/copy",
        data: ["hostPid": Int(pid)]
      )
      // #endregion
      hostApp.activate(options: [.activateIgnoringOtherApps])
    }
    onPopupDidHide?(hadVisiblePopup)
  }

  func setPopupSize(width: CGFloat, height: CGFloat) {
    guard let panel else {
      return
    }
    let newContentSize = NSSize(width: max(260, width), height: max(180, height))
    let framedSize = panel.frameRect(forContentRect: NSRect(origin: .zero, size: newContentSize)).size
    var frame = panel.frame
    // Keep top edge stable while content grows/shrinks to avoid visual jump.
    let oldTop = frame.maxY
    frame.size = framedSize
    frame.origin.y = oldTop - frame.size.height
    frame.origin = clampedOriginForFrameOrigin(frame.origin, popupSize: frame.size)
    panel.setFrame(frame, display: true)
    if panel.alphaValue < 1.0 {
      panel.alphaValue = 1.0
    }
  }

  private func ensurePanel(size: NSSize) {
    if panel == nil {
      let style: NSWindow.StyleMask = [.nonactivatingPanel, .borderless, .fullSizeContentView]
      let popup = NSPanel(
        contentRect: NSRect(origin: .zero, size: size),
        styleMask: style,
        backing: .buffered,
        defer: false
      )
      popup.level = .floating
      popup.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
      popup.isFloatingPanel = true
      popup.hidesOnDeactivate = false
      popup.titleVisibility = .hidden
      popup.titlebarAppearsTransparent = true
      popup.isReleasedWhenClosed = false
      let engine = FlutterEngine(
        name: "formycareer_overlay_engine",
        project: nil,
        allowHeadlessExecution: true
      )
      let _ = engine.run(withEntrypoint: overlayEntrypoint)
      registerOverlayEnginePlugins(engine: engine)
      let flutterViewController = FlutterViewController(engine: engine, nibName: nil, bundle: nil)
      popup.contentViewController = flutterViewController

      panel = popup
      overlayEngine = engine
    }
  }

  private func startOutsideClickMonitor() {
    if outsideClickMonitor != nil {
      return
    }
    // Any pointer activity outside the panel dismisses the popup; selection capture
    // is deferred until all mouse buttons are released (see `MacSystemSelectionStreamHandler`).
    outsideClickMonitor = NSEvent.addGlobalMonitorForEvents(
      matching: [
        .leftMouseDown, .leftMouseUp, .leftMouseDragged,
        .rightMouseDown, .rightMouseUp, .rightMouseDragged,
        .otherMouseDown, .otherMouseUp, .otherMouseDragged,
        .scrollWheel,
      ]
    ) { [weak self] event in
      self?.handleOutsideClickWhilePopupVisible(event)
    }
  }

  private func stopOutsideClickMonitor() {
    guard let monitor = outsideClickMonitor else {
      return
    }
    NSEvent.removeMonitor(monitor)
    outsideClickMonitor = nil
  }

  private func handleOutsideClickWhilePopupVisible(_ event: NSEvent) {
    guard let panel, panel.isVisible else {
      return
    }
    // event.locationInWindow is nil/undefined for global monitor; use current
    // global mouse location in screen coordinates.
    let mouse = NSEvent.mouseLocation
    if !panel.frame.contains(mouse) {
      let phase: String
      switch event.type {
      case .leftMouseDown: phase = "leftMouseDown"
      case .leftMouseUp: phase = "leftMouseUp"
      case .leftMouseDragged: phase = "leftMouseDragged"
      case .rightMouseDown: phase = "rightMouseDown"
      case .rightMouseUp: phase = "rightMouseUp"
      case .rightMouseDragged: phase = "rightMouseDragged"
      case .otherMouseDown: phase = "otherMouseDown"
      case .otherMouseUp: phase = "otherMouseUp"
      case .otherMouseDragged: phase = "otherMouseDragged"
      case .scrollWheel: phase = "scrollWheel"
      default: phase = "other"
      }
      // #region agent log
      MacosOverlayPopupPlugin.emitDebugLog(
        hypothesisId: "H13",
        location: "MacosOverlayPopupPlugin.swift:handleOutsideClickWhilePopupVisible",
        message: "Popup hidden by outside click monitor",
        data: [
          "mouseX": mouse.x,
          "mouseY": mouse.y,
          "phase": phase,
        ]
      )
      // #endregion
      onOutsidePointerWillDismissPopup?(event)
      hidePopup()
    }
  }

  private func clampedOrigin(
    cursor: NSPoint,
    popupSize: NSSize,
    offsetX: CGFloat,
    offsetY: CGFloat
  ) -> NSPoint {
    let screen = NSScreen.screens.first(where: { NSMouseInRect(cursor, $0.frame, false) }) ?? NSScreen.main
    guard let visibleFrame = screen?.visibleFrame else {
      return NSPoint(x: cursor.x + offsetX, y: cursor.y - popupSize.height - offsetY)
    }
    var x = cursor.x + offsetX
    var y = cursor.y - popupSize.height - offsetY
    if x + popupSize.width > visibleFrame.maxX {
      x = visibleFrame.maxX - popupSize.width - 8
    }
    if x < visibleFrame.minX {
      x = visibleFrame.minX + 8
    }
    if y < visibleFrame.minY {
      y = visibleFrame.minY + 8
    }
    if y + popupSize.height > visibleFrame.maxY {
      y = visibleFrame.maxY - popupSize.height - 8
    }
    return NSPoint(x: x, y: y)
  }

  private func clampedOriginForFrameOrigin(_ origin: NSPoint, popupSize: NSSize) -> NSPoint {
    let screen = NSScreen.screens.first(where: { NSMouseInRect(NSEvent.mouseLocation, $0.frame, false) }) ?? NSScreen.main
    guard let visibleFrame = screen?.visibleFrame else {
      return origin
    }
    var x = origin.x
    var y = origin.y
    if x + popupSize.width > visibleFrame.maxX {
      x = visibleFrame.maxX - popupSize.width - 8
    }
    if x < visibleFrame.minX {
      x = visibleFrame.minX + 8
    }
    if y < visibleFrame.minY {
      y = visibleFrame.minY + 8
    }
    if y + popupSize.height > visibleFrame.maxY {
      y = visibleFrame.maxY - popupSize.height - 8
    }
    return NSPoint(x: x, y: y)
  }

  private func registerOverlayEnginePlugins(engine: FlutterEngine) {
#if canImport(just_audio)
    JustAudioPlugin.register(with: engine.registrar(forPlugin: "JustAudioPlugin"))
#endif
  }
}

private final class DesktopEventStreamHandler: NSObject, FlutterStreamHandler {
  private var sink: FlutterEventSink?
  private var pendingEvents: [[String: Any]] = []

  func onListen(withArguments _: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    sink = events
    if !pendingEvents.isEmpty {
      for event in pendingEvents {
        events(event)
      }
      pendingEvents.removeAll()
    }
    return nil
  }

  func onCancel(withArguments _: Any?) -> FlutterError? {
    sink = nil
    return nil
  }

  func emit(_ event: [String: Any]) {
    if let sink {
      sink(event)
    } else {
      pendingEvents.append(event)
    }
  }
}

private final class MacSystemSelectionStreamHandler: NSObject, FlutterStreamHandler {
  /// Ignore tiny pointer jitter on plain clicks (Finder, Dock, icons).
  private static let minMeaningfulTextDragPoints: CGFloat = 14

  private var eventSink: FlutterEventSink?
  private var pollTimer: Timer?
  private var lastPasteboardChangeCount: Int = NSPasteboard.general.changeCount
  private var lastEmittedText: String = ""
  private var autoCaptureEnabled = false
  private var didPromptAccessibilityPermission = false
  private var globalMouseMonitor: Any?
  /// Arms clipboard + AX polling emits only after a deliberate selection gesture
  /// (mouse drag/word-select or Shift+arrow), avoiding stray captures when opening
  /// folders/apps or when unrelated clipboard updates occur.
  private var selectionCaptureArmedUntil = Date.distantPast
  private var keyboardShiftArrowArmMonitor: Any?
  /// Screen location at leftMouseDown for drag metrics (global coords).
  private var pointerSequenceLeftDownScreen: NSPoint?
  /// True when drag resembles a cross-axis marquee (area screenshot tools).
  private var screenshotLikeMarqueeThisSequence = false
  private var lastSyntheticCopyAt = Date.distantPast
  private var observedDragSelection = false
  private var captureSuppressedProvider: (() -> Bool)?
  private var dismissPopupHandler: (() -> Void)?
  private var forceEmitNextSelection = false
  private var didDismissPopupForCurrentSelectionGesture = false
  /// `cancelPendingCaptureWork` stops overlapping recapture: AX burst and optional
  /// synthetic fallback share one token so a new dismiss / gesture replaces the old chain.
  private var axRecaptureWorkItem: DispatchWorkItem?
  private var axRecaptureToken: UUID?
  private var axFocusedElementFailureStreak = 0
  private var axFocusedElementBlockedUntil = Date.distantPast
  private var lastRecaptureKickAt = Date.distantPast
  private var pendingCooldownRetryWorkItem: DispatchWorkItem?
  private var pendingNoCaptureRetryWorkItem: DispatchWorkItem?
  private var shouldBypassCooldownForImmediateSentinelRetry = false
  private var didUseImmediateSentinelRetryInCycle = false
  private var syntheticPostsInCurrentPointerSequence = 0
  /// One-shot widen: after popup hide restores host activation, next Cmd+C may
  /// run sooner than minimumSyntheticCopyInterval (log run2 showed paired H31 ~362ms
  /// that confused WebKit selections when the gap was still >120ms but < practical double-fire).
  private var bypassSyntheticCopyMinGapOnce = false
  /// Throttle between synthetic Cmd+C posts. A **long** (1s) window is applied only after we
  /// actually emit (`emitSelectedTextIfNeeded` → event sink) to stop WebKit double-burst H12.
  /// A **short** window after every post avoids H41 blocking a quick retry when the first
  /// Cmd+C missed capture (log: H31 with no H42/H11, then H41 ~0.88s later).
  private var blockSyntheticCopyUntil = Date.distantPast
  /// `RunLoop.run` during sentinel polling can dispatch the 350ms poll timer, which
  /// re-entered `pollPasteboardSelection` and emitted partial text then H12 dedup same tick.
  private var isSyntheticClipboardPollingBusy = false
  /// After outside-pointer dismiss while a button is still down, skip H44 and block
  /// synthetic copy / poll emit until `pressedMouseButtons == 0` (Vietnamese UX: finish
  /// the outside gesture, then choose the next word).
  private var skipPostHideSyntheticRecaptureOnce = false
  private var ignoreSyntheticCopyUntilMouseButtonsReleased = false
  /// When true, AX text is only emitted if focus is not under Finder-like `AXBrowser` / `AXOutline`
  /// (double-click there opens items but can still surface spurious selected-text attributes).
  private var verifyTextSurfaceChromeForMultiClick = false

  /// Roles on the focused element or its ancestors that indicate file-browsing chrome, not
  /// "double-click to select a word" text surfaces (Safari/WebKit use `AXWebArea`, editors `AXTextArea`, etc.).
  private static let axRolesRejectingMultiClickWordCapture: Set<String> = [
    kAXBrowserRole as String,
    kAXOutlineRole as String,
  ]

  func setCaptureSuppressedProvider(_ provider: @escaping () -> Bool) {
    captureSuppressedProvider = provider
  }

  func setDismissPopupHandler(_ handler: @escaping () -> Void) {
    dismissPopupHandler = handler
  }

  func armSyntheticCopyMinGapBypassOnce() {
    bypassSyntheticCopyMinGapOnce = true
    blockSyntheticCopyUntil = .distantPast
  }

  func setAutoCaptureEnabled(_ isEnabled: Bool) {
    autoCaptureEnabled = isEnabled
    if isEnabled {
      requestAccessibilityPermissionIfNeeded()
    }
    restartPollingIfNeeded()
  }

  func onListen(withArguments _: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    eventSink = events
    lastPasteboardChangeCount = NSPasteboard.general.changeCount
    restartPollingIfNeeded()
    return nil
  }

  func onCancel(withArguments _: Any?) -> FlutterError? {
    eventSink = nil
    cancelPendingCaptureWork()
    bypassSyntheticCopyMinGapOnce = false
    blockSyntheticCopyUntil = .distantPast
    isSyntheticClipboardPollingBusy = false
    skipPostHideSyntheticRecaptureOnce = false
    ignoreSyntheticCopyUntilMouseButtonsReleased = false
    axFocusedElementFailureStreak = 0
    axFocusedElementBlockedUntil = .distantPast
    lastRecaptureKickAt = .distantPast
    pendingNoCaptureRetryWorkItem?.cancel()
    pendingNoCaptureRetryWorkItem = nil
    shouldBypassCooldownForImmediateSentinelRetry = false
    didUseImmediateSentinelRetryInCycle = false
    stopPolling()
    stopMouseMonitor()
    selectionCaptureArmedUntil = .distantPast
    return nil
  }

  private func armSelectionCapturePolling(seconds: TimeInterval = 2.8) {
    selectionCaptureArmedUntil = Date().addingTimeInterval(seconds)
  }

  /// Large diagonal rectangle drags are usually area screenshot capture, not text selection.
  private static func isLikelyScreenshotMarqueeDrag(
    deltaX: CGFloat,
    deltaY: CGFloat,
    dragStartScreen: NSPoint
  ) -> Bool {
    let adx = abs(deltaX)
    let ady = abs(deltaY)
    let span = hypot(adx, ady)
    guard adx >= 72, ady >= 72 else {
      return false
    }
    let screen =
      NSScreen.screens.first(where: { NSMouseInRect(dragStartScreen, $0.frame, false) })
      ?? NSScreen.main
    guard let frame = screen?.frame else {
      return span >= 520
    }
    let m = min(frame.width, frame.height)
    return span >= m * CGFloat(0.34)
  }

  private func restartPollingIfNeeded() {
    stopPolling()
    stopMouseMonitor()
    guard autoCaptureEnabled, eventSink != nil else {
      return
    }
    startMouseMonitor()
    pollTimer = Timer.scheduledTimer(
      withTimeInterval: 0.35,
      repeats: true
    ) { [weak self] _ in
      self?.pollPasteboardSelection()
    }
    if let pollTimer {
      RunLoop.main.add(pollTimer, forMode: .common)
    }
  }

  private func stopPolling() {
    pollTimer?.invalidate()
    pollTimer = nil
  }

  private func startMouseMonitor() {
    guard globalMouseMonitor == nil else {
      return
    }
    globalMouseMonitor = NSEvent.addGlobalMonitorForEvents(
      matching: [
        .leftMouseDown, .rightMouseDown, .otherMouseDown,
        .leftMouseDragged, .leftMouseUp,
        .rightMouseDragged, .rightMouseUp,
        .otherMouseDragged, .otherMouseUp,
      ]
    ) { [weak self] event in
      self?.handleGlobalMouseEvent(event)
    }
    startKeyboardShiftArrowArmMonitor()
  }

  private func stopMouseMonitor() {
    if let km = keyboardShiftArrowArmMonitor {
      NSEvent.removeMonitor(km)
      keyboardShiftArrowArmMonitor = nil
    }
    guard let monitor = globalMouseMonitor else {
      return
    }
    NSEvent.removeMonitor(monitor)
    globalMouseMonitor = nil
  }

  private func startKeyboardShiftArrowArmMonitor() {
    guard keyboardShiftArrowArmMonitor == nil else {
      return
    }
    keyboardShiftArrowArmMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.keyDown]) {
      [weak self] ev in
      guard let self else {
        return
      }
      guard self.autoCaptureEnabled, self.eventSink != nil else {
        return
      }
      let arrows: Set<UInt16> = [123, 124, 125, 126]
      if ev.modifierFlags.contains(.shift), arrows.contains(ev.keyCode) {
        self.armSelectionCapturePolling(seconds: 4)
      }
    }
  }

  private func handleGlobalMouseEvent(_ event: NSEvent) {
    if [.leftMouseDown, .rightMouseDown, .otherMouseDown].contains(event.type) {
      resetCaptureChainForNewPointerSequence(event: event)
      if event.type == .leftMouseDown {
        pointerSequenceLeftDownScreen = NSEvent.mouseLocation
      }
    }
    if ignoreSyntheticCopyUntilMouseButtonsReleased {
      let isButtonUp = [.leftMouseUp, .rightMouseUp, .otherMouseUp].contains(event.type)
      if isButtonUp, NSEvent.pressedMouseButtons == 0 {
        ignoreSyntheticCopyUntilMouseButtonsReleased = false
        didDismissPopupForCurrentSelectionGesture = false
        // #region agent log
        MacosOverlayPopupPlugin.emitDebugLog(
          hypothesisId: "H48",
          location: "MacosOverlayPopupPlugin.swift:handleGlobalMouseEvent",
          message: "Mouse-up after outside-dismiss deferral; scheduling capture",
          data: [:]
        )
        // #endregion
        if autoCaptureEnabled, eventSink != nil {
          let hadDrag = observedDragSelection
          let multiClickWithoutDrag =
            !hadDrag && event.type == .leftMouseUp && event.clickCount >= 2
          observedDragSelection = false
          kickAccessibilitySelectionRecapture(
            source: "mouseUpAfterOutsideDismiss",
            firstDelay: 0.04,
            attempts: 6,
            stride: 0.05,
            syntheticFallback: !multiClickWithoutDrag,
            armClipboardPolling: !multiClickWithoutDrag,
            verifyTextSurfaceChromeForMultiClick: multiClickWithoutDrag
          )
        }
      }
      return
    }
    let suppressed = captureSuppressedProvider?() == true
    if event.type == .leftMouseDragged {
      if let origin = pointerSequenceLeftDownScreen {
        let p = NSEvent.mouseLocation
        let dx = p.x - origin.x
        let dy = p.y - origin.y
        let dist = hypot(dx, dy)
        if dist >= Self.minMeaningfulTextDragPoints {
          observedDragSelection = true
        }
        if Self.isLikelyScreenshotMarqueeDrag(
          deltaX: dx,
          deltaY: dy,
          dragStartScreen: origin
        ) {
          screenshotLikeMarqueeThisSequence = true
        }
      }
      if suppressed && !didDismissPopupForCurrentSelectionGesture {
        didDismissPopupForCurrentSelectionGesture = true
        forceEmitNextSelection = true
        // #region agent log
        MacosOverlayPopupPlugin.emitDebugLog(
          hypothesisId: "H17",
          location: "MacosOverlayPopupPlugin.swift:handleGlobalMouseEvent",
          message: "Dismiss popup at drag start to avoid suppressing next selection",
          data: [:]
        )
        // #endregion
        dismissPopupHandler?()
        cancelPendingCaptureWork()
        skipPostHideSyntheticRecaptureOnce = true
        ignoreSyntheticCopyUntilMouseButtonsReleased = true
      }
      return
    }
    guard event.type == .leftMouseUp else {
      return
    }
    defer {
      didDismissPopupForCurrentSelectionGesture = false
      pointerSequenceLeftDownScreen = nil
      screenshotLikeMarqueeThisSequence = false
    }
    if screenshotLikeMarqueeThisSequence {
      observedDragSelection = false
      return
    }
    if suppressed {
      let hadDragSelection = observedDragSelection
      let likelySelectionGesture = hadDragSelection || event.clickCount >= 2
      observedDragSelection = false
      guard likelySelectionGesture else {
        return
      }
      let multiClickWithoutDrag =
        !hadDragSelection && event.clickCount >= 2
      // #region agent log
      MacosOverlayPopupPlugin.emitDebugLog(
        hypothesisId: "H16",
        location: "MacosOverlayPopupPlugin.swift:handleGlobalMouseEvent",
        message: "Dismiss popup on leftMouseUp and continue selection capture",
        data: [:]
      )
      // #endregion
      // Force the immediate post-dismiss selection to be emitted even if
      // text happens to equal the previous emitted token.
      forceEmitNextSelection = true
      dismissPopupHandler?()
      kickAccessibilitySelectionRecapture(
        source: "suppressedLeftMouseUp",
        firstDelay: 0.03,
        attempts: 5,
        stride: 0.05,
        syntheticFallback: !multiClickWithoutDrag,
        armClipboardPolling: !multiClickWithoutDrag,
        verifyTextSurfaceChromeForMultiClick: multiClickWithoutDrag
      )
      return
    }
    guard autoCaptureEnabled, eventSink != nil else {
      return
    }
    let hadDragSelection = observedDragSelection
    let likelySelectionGesture = hadDragSelection || event.clickCount >= 2
    observedDragSelection = false
    guard likelySelectionGesture else {
      return
    }
    let multiClickWithoutDrag =
      !hadDragSelection && event.clickCount >= 2
    kickAccessibilitySelectionRecapture(
      source: "regularLeftMouseUp",
      firstDelay: 0.06,
      attempts: 6,
      stride: 0.05,
      syntheticFallback: !multiClickWithoutDrag,
      armClipboardPolling: !multiClickWithoutDrag,
      verifyTextSurfaceChromeForMultiClick: multiClickWithoutDrag
    )
  }

  private func cancelPendingCaptureWork() {
    axRecaptureToken = nil
    axRecaptureWorkItem?.cancel()
    axRecaptureWorkItem = nil
    pendingNoCaptureRetryWorkItem?.cancel()
    pendingNoCaptureRetryWorkItem = nil
    shouldBypassCooldownForImmediateSentinelRetry = false
    didUseImmediateSentinelRetryInCycle = false
    verifyTextSurfaceChromeForMultiClick = false
  }

  private func resetCaptureChainForNewPointerSequence(event: NSEvent) {
    cancelPendingCaptureWork()
    lastRecaptureKickAt = .distantPast
    blockSyntheticCopyUntil = .distantPast
    lastSyntheticCopyAt = .distantPast
    bypassSyntheticCopyMinGapOnce = true
    syntheticPostsInCurrentPointerSequence = 0
    resetEmittedSelectionDedup()
    // #region agent log
    MacosOverlayPopupPlugin.emitDebugLog(
      hypothesisId: "H62",
      location: "MacosOverlayPopupPlugin.swift:resetCaptureChainForNewPointerSequence",
      message: "Reset capture chain on new pointer-down",
      data: [
        "eventType": event.type.rawValue,
        "popupSuppressed": captureSuppressedProvider?() == true,
        "dedupCleared": true,
        "syntheticBudgetReset": true,
      ]
    )
    // #endregion
    observedDragSelection = false
    screenshotLikeMarqueeThisSequence = false
    pointerSequenceLeftDownScreen = nil
    selectionCaptureArmedUntil = .distantPast
  }

  fileprivate func handleOutsidePointerWillDismissPopup(for event: NSEvent) {
    cancelPendingCaptureWork()
    if event.type == .scrollWheel {
      return
    }
    let isPointerUpWithNonePressed =
      [.leftMouseUp, .rightMouseUp, .otherMouseUp].contains(event.type)
        && NSEvent.pressedMouseButtons == 0
    if isPointerUpWithNonePressed {
      return
    }
    skipPostHideSyntheticRecaptureOnce = true
    ignoreSyntheticCopyUntilMouseButtonsReleased = true
  }

  fileprivate func shouldSkipPostHideSyntheticRecaptureAndConsume() -> Bool {
    if skipPostHideSyntheticRecaptureOnce {
      skipPostHideSyntheticRecaptureOnce = false
      return true
    }
    return false
  }

  /// After `hidePopup`, read selection via Accessibility in a short burst; synthetic
  /// Cmd+C is only used if AX yields nothing (H50).
  fileprivate func schedulePostHideRecapture() {
    // #region agent log
    MacosOverlayPopupPlugin.emitDebugLog(
      hypothesisId: "H44",
      location: "MacosOverlayPopupPlugin.swift:schedulePostHideRecapture",
      message: "Scheduled post-hide AX selection recapture (Cmd+C only if AX fails)",
      data: ["firstDelayMs": 90, "attempts": 6, "strideMs": 55]
    )
    // #endregion
    kickAccessibilitySelectionRecapture(
      source: "postHide",
      firstDelay: 0.09,
      attempts: 6,
      stride: 0.055,
      syntheticFallback: true
    )
  }

  /// Polls `kAXSelectedTextAttribute` on the focused element — no clipboard mutation / Cmd+C
  /// unless `syntheticFallback` runs after all attempts (H50).
  private func kickAccessibilitySelectionRecapture(
    source: String,
    firstDelay: TimeInterval,
    attempts: Int,
    stride: TimeInterval,
    syntheticFallback: Bool,
    armClipboardPolling: Bool = true,
    verifyTextSurfaceChromeForMultiClick: Bool = false
  ) {
    let now = Date()
    let elapsedMs = Int(now.timeIntervalSince(lastRecaptureKickAt) * 1000)
    if elapsedMs >= 0, elapsedMs < 320 {
      // #region agent log
      MacosOverlayPopupPlugin.emitDebugLog(
        hypothesisId: "H53",
        location: "MacosOverlayPopupPlugin.swift:kickAccessibilitySelectionRecapture",
        message: "Recapture trigger coalesced (same gesture/window)",
        data: [
          "source": source,
          "elapsedMs": elapsedMs,
        ]
      )
      // #endregion
      return
    }
    lastRecaptureKickAt = now
    if armClipboardPolling {
      armSelectionCapturePolling()
    }
    beginAccessibilitySelectionRecapture(
      firstDelay: firstDelay,
      attempts: attempts,
      stride: stride,
      syntheticFallback: syntheticFallback,
      verifyTextSurfaceChromeForMultiClick: verifyTextSurfaceChromeForMultiClick
    )
  }

  private func beginAccessibilitySelectionRecapture(
    firstDelay: TimeInterval,
    attempts: Int,
    stride: TimeInterval,
    syntheticFallback: Bool,
    verifyTextSurfaceChromeForMultiClick: Bool = false
  ) {
    guard autoCaptureEnabled, eventSink != nil else {
      return
    }
    if Date() < axFocusedElementBlockedUntil {
      // #region agent log
      MacosOverlayPopupPlugin.emitDebugLog(
        hypothesisId: "H52",
        location: "MacosOverlayPopupPlugin.swift:beginAccessibilitySelectionRecapture",
        message: "AX recapture bypassed due to recent focused-element failures",
        data: [
          "remainingMs": Int(ceil(axFocusedElementBlockedUntil.timeIntervalSinceNow * 1000)),
          "streak": axFocusedElementFailureStreak,
        ]
      )
      // #endregion
      if syntheticFallback {
        // Single-use budget in `sendSyntheticCopyIfNeeded` prevents spam.
        sendSyntheticCopyIfNeeded()
      }
      return
    }
    cancelPendingCaptureWork()
    self.verifyTextSurfaceChromeForMultiClick = verifyTextSurfaceChromeForMultiClick
    let token = UUID()
    axRecaptureToken = token
    enqueueAxRecaptureStep(
      token: token,
      remaining: attempts,
      stride: stride,
      syntheticFallback: syntheticFallback,
      delay: firstDelay
    )
  }

  private func enqueueAxRecaptureStep(
    token: UUID,
    remaining: Int,
    stride: TimeInterval,
    syntheticFallback: Bool,
    delay: TimeInterval
  ) {
    let work = DispatchWorkItem { [weak self] in
      self?.executeAxRecaptureStep(
        token: token,
        remaining: remaining,
        stride: stride,
        syntheticFallback: syntheticFallback
      )
    }
    axRecaptureWorkItem = work
    DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: work)
  }

  private func executeAxRecaptureStep(
    token: UUID,
    remaining: Int,
    stride: TimeInterval,
    syntheticFallback: Bool
  ) {
    guard axRecaptureToken == token else {
      return
    }
    if ignoreSyntheticCopyUntilMouseButtonsReleased {
      enqueueAxRecaptureStep(
        token: token,
        remaining: remaining,
        stride: stride,
        syntheticFallback: syntheticFallback,
        delay: stride
      )
      return
    }
    if remaining <= 0 {
      verifyTextSurfaceChromeForMultiClick = false
      if syntheticFallback {
        // #region agent log
        MacosOverlayPopupPlugin.emitDebugLog(
          hypothesisId: "H50",
          location: "MacosOverlayPopupPlugin.swift:executeAxRecaptureStep",
          message: "AX recapture exhausted; falling back to synthetic Cmd+C",
          data: [:]
        )
        // #endregion
        sendSyntheticCopyIfNeeded()
      }
      axRecaptureToken = nil
      axRecaptureWorkItem = nil
      return
    }
    if let ax = readSelectedTextViaAccessibility(logFailures: true),
      isLikelyUserSelection(ax)
    {
      // #region agent log
      MacosOverlayPopupPlugin.emitDebugLog(
        hypothesisId: "H49",
        location: "MacosOverlayPopupPlugin.swift:executeAxRecaptureStep",
        message: "Accessibility-only selection read succeeded",
        data: ["textLength": ax.count, "remainingBeforeThis": remaining]
      )
      // #endregion
      if verifyTextSurfaceChromeForMultiClick {
        if !multiClickGestureFocusPermitsWordSelectionEmit() {
          verifyTextSurfaceChromeForMultiClick = false
          // #region agent log
          MacosOverlayPopupPlugin.emitDebugLog(
            hypothesisId: "H71",
            location: "MacosOverlayPopupPlugin.swift:executeAxRecaptureStep",
            message: "Multi-click AX selection dropped (focus under browser/outline chrome)",
            data: ["textLength": ax.count]
          )
          // #endregion
          axRecaptureToken = nil
          axRecaptureWorkItem = nil
          return
        }
        verifyTextSurfaceChromeForMultiClick = false
      }
      emitSelectedTextIfNeeded(ax)
      axRecaptureToken = nil
      axRecaptureWorkItem = nil
      return
    }
    enqueueAxRecaptureStep(
      token: token,
      remaining: remaining - 1,
      stride: stride,
      syntheticFallback: syntheticFallback,
      delay: stride
    )
  }

  /// Bounds rapid double Cmd+C bursts (distinct schedules after coalescing); log
  /// showed back-to-back H31 ~363ms corrupting WebKit selections. Post-hide-first
  /// copy uses bypassSyntheticCopyMinGapOnce so legitimate quick re-select keeps working.
  private static let minimumSyntheticCopyInterval: TimeInterval = 0.40
  /// Matches `CaptureSelectedTextFromForegroundApp` sentinel in Windows `flutter_window.cpp`.
  private static let syntheticPasteboardSentinel = "__fmc_sentinel__"
  /// Windows polls clipboard 12×20ms (~240ms) after SendInput Ctrl+C before restoring.
  // Keep polling longer before deciding "no data" to avoid retrying Cmd+C too early
  // on short-word selections where source apps publish clipboard data slightly later.
  private static let syntheticCopyPollAttempts = 24
  private static let syntheticCopyPollStrideSeconds: TimeInterval = 0.02
  /// Minimum spacing after posting Cmd+C when nothing was emitted yet (see `emitSelectedTextIfNeeded`).
  private static let postSyntheticCmdCNoEmitCooldown: TimeInterval = 0.34
  /// Keep post-emit guard close to `minimumSyntheticCopyInterval`; long texts get slightly
  /// longer protection, short texts stay responsive for quick follow-up selection.
  private static func postEmitSyntheticCooldown(forTextLength len: Int) -> TimeInterval {
    if len <= 24 { return 0.42 }
    if len <= 80 { return 0.50 }
    return 0.62
  }

  /// Release stuck modifiers so Cmd+C isn't misread as e.g. Cmd+Shift+C (Windows does the same).
  private func releaseHeldModifierKeysForSyntheticCopy() {
    let vkCodes: [CGKeyCode] = [
      CGKeyCode(kVK_Command),
      CGKeyCode(kVK_Shift),
      CGKeyCode(kVK_Option),
      CGKeyCode(kVK_Control),
      CGKeyCode(kVK_RightCommand),
      CGKeyCode(kVK_RightShift),
      CGKeyCode(kVK_RightOption),
      CGKeyCode(kVK_RightControl),
    ]
    for vk in vkCodes {
      guard
        let up = CGEvent(
          keyboardEventSource: CGEventSource(stateID: .combinedSessionState),
          virtualKey: vk,
          keyDown: false
        )
      else {
        continue
      }
      up.flags = []
      up.post(tap: .cgSessionEventTap)
    }
  }

  private func sendSyntheticCopyIfNeeded() {
    guard AXIsProcessTrusted() else {
      return
    }
    if syntheticPostsInCurrentPointerSequence >= 1 {
      // #region agent log
      MacosOverlayPopupPlugin.emitDebugLog(
        hypothesisId: "H68",
        location: "MacosOverlayPopupPlugin.swift:sendSyntheticCopyIfNeeded",
        message: "Skip synthetic Cmd+C: budget exhausted for current pointer sequence",
        data: [:]
      )
      // #endregion
      return
    }
    if ignoreSyntheticCopyUntilMouseButtonsReleased {
      return
    }
    let now = Date()
    let bypassCooldownForImmediateSentinelRetry = shouldBypassCooldownForImmediateSentinelRetry
    if bypassCooldownForImmediateSentinelRetry {
      shouldBypassCooldownForImmediateSentinelRetry = false
      // #region agent log
      MacosOverlayPopupPlugin.emitDebugLog(
        hypothesisId: "H60",
        location: "MacosOverlayPopupPlugin.swift:sendSyntheticCopyIfNeeded",
        message: "Bypassing post-capture cooldown for immediate sentinel-only retry",
        data: [:]
      )
      // #endregion
    }
    if !bypassCooldownForImmediateSentinelRetry, now < blockSyntheticCopyUntil {
      let remainingMs = max(
        0,
        Int(ceil(blockSyntheticCopyUntil.timeIntervalSince(now) * 1000))
      )
      // #region agent log
      MacosOverlayPopupPlugin.emitDebugLog(
        hypothesisId: "H41",
        location: "MacosOverlayPopupPlugin.swift:sendSyntheticCopyIfNeeded",
        message: "Synthetic Cmd+C suppressed: post-capture cooldown",
        data: [
          "remainingMs": remainingMs,
        ]
      )
      // #endregion
      if pendingCooldownRetryWorkItem == nil, remainingMs > 0 {
        let retryDelay = blockSyntheticCopyUntil.timeIntervalSince(now) + 0.03
        let retryWork = DispatchWorkItem { [weak self] in
          self?.pendingCooldownRetryWorkItem = nil
          self?.armSyntheticCopyMinGapBypassOnce()
          // #region agent log
          MacosOverlayPopupPlugin.emitDebugLog(
            hypothesisId: "H56",
            location: "MacosOverlayPopupPlugin.swift:sendSyntheticCopyIfNeeded",
            message: "Executing one-shot retry after cooldown",
            data: [:]
          )
          // #endregion
          self?.sendSyntheticCopyIfNeeded()
        }
        pendingCooldownRetryWorkItem = retryWork
        // #region agent log
        MacosOverlayPopupPlugin.emitDebugLog(
          hypothesisId: "H54",
          location: "MacosOverlayPopupPlugin.swift:sendSyntheticCopyIfNeeded",
          message: "Scheduled one-shot retry right after cooldown",
          data: ["retryDelayMs": Int(ceil(retryDelay * 1000))]
        )
        // #endregion
        DispatchQueue.main.asyncAfter(deadline: .now() + retryDelay, execute: retryWork)
      }
      return
    }
    if pendingCooldownRetryWorkItem != nil {
      pendingCooldownRetryWorkItem?.cancel()
      pendingCooldownRetryWorkItem = nil
    }
    let elapsed = now.timeIntervalSince(lastSyntheticCopyAt)
    let bypassMinGap = bypassSyntheticCopyMinGapOnce || bypassCooldownForImmediateSentinelRetry
    if !bypassMinGap, elapsed < Self.minimumSyntheticCopyInterval {
      // #region agent log
      MacosOverlayPopupPlugin.emitDebugLog(
        hypothesisId: "H29",
        location: "MacosOverlayPopupPlugin.swift:sendSyntheticCopyIfNeeded",
        message: "Synthetic Cmd+C suppressed by interval guard",
        data: [
          "elapsedMs": Int(elapsed * 1000),
          "minGapMs": Int(Self.minimumSyntheticCopyInterval * 1000),
        ]
      )
      // #endregion
      return
    }
    guard
      let source = CGEventSource(stateID: .combinedSessionState),
      let keyDown = CGEvent(
        keyboardEventSource: source,
        virtualKey: CGKeyCode(kVK_ANSI_C),
        keyDown: true
      ),
      let keyUp = CGEvent(
        keyboardEventSource: source,
        virtualKey: CGKeyCode(kVK_ANSI_C),
        keyDown: false
      )
    else {
      return
    }
    lastSyntheticCopyAt = Date()
    if bypassMinGap {
      bypassSyntheticCopyMinGapOnce = false
    }

    // --- Windows-aligned capture (flutter_window.cpp `CaptureSelectedTextFromForegroundApp`) ---
    releaseHeldModifierKeysForSyntheticCopy()
    let pasteboard = NSPasteboard.general
    let backupPlain = pasteboard.string(forType: .string)

    pasteboard.clearContents()
    let sentinelWritten = pasteboard.setString(
      Self.syntheticPasteboardSentinel,
      forType: .string
    )
    if !sentinelWritten {
      if let backupPlain {
        pasteboard.clearContents()
        _ = pasteboard.setString(backupPlain, forType: .string)
      }
      lastPasteboardChangeCount = pasteboard.changeCount
    }

    keyDown.flags = .maskCommand
    keyUp.flags = .maskCommand
    keyDown.post(tap: .cgSessionEventTap)
    keyUp.post(tap: .cgSessionEventTap)
    syntheticPostsInCurrentPointerSequence += 1
    // #region agent log
    MacosOverlayPopupPlugin.emitDebugLog(
      hypothesisId: "H31",
      location: "MacosOverlayPopupPlugin.swift:sendSyntheticCopyIfNeeded",
      message: "Synthetic Cmd+C posted",
      data: [:]
    )
    // #endregion
    blockSyntheticCopyUntil = Date().addingTimeInterval(Self.postSyntheticCmdCNoEmitCooldown)

    guard sentinelWritten else {
      DispatchQueue.main.async { [weak self] in
        self?.pollPasteboardSelection()
      }
      return
    }
    lastPasteboardChangeCount = pasteboard.changeCount

    var captured: String?
    var sawSentinel = false
    var sawOnlyWhitespace = false
    var sawNonSentinelRaw = false
    isSyntheticClipboardPollingBusy = true
    defer { isSyntheticClipboardPollingBusy = false }
    for _ in 0 ..< Self.syntheticCopyPollAttempts {
      RunLoop.current.run(
        mode: .default,
        before: Date().addingTimeInterval(Self.syntheticCopyPollStrideSeconds)
      )
      guard let rawUntrimmed = pasteboard.string(forType: .string) else {
        continue
      }
      let raw = rawUntrimmed.trimmingCharacters(in: .whitespacesAndNewlines)
      if raw == Self.syntheticPasteboardSentinel {
        sawSentinel = true
        continue
      }
      if raw.isEmpty {
        sawOnlyWhitespace = true
        continue
      }
      sawNonSentinelRaw = true
      captured = raw
      break
    }

    pasteboard.clearContents()
    if let backupPlain {
      _ = pasteboard.setString(backupPlain, forType: .string)
    }
    lastPasteboardChangeCount = pasteboard.changeCount

    let trimmedCAP = captured?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    if !trimmedCAP.isEmpty, isLikelyUserSelection(trimmedCAP) {
      didUseImmediateSentinelRetryInCycle = false
      if pendingNoCaptureRetryWorkItem != nil {
        pendingNoCaptureRetryWorkItem?.cancel()
        pendingNoCaptureRetryWorkItem = nil
      }
      // #region agent log
      MacosOverlayPopupPlugin.emitDebugLog(
        hypothesisId: "H42",
        location: "MacosOverlayPopupPlugin.swift:sendSyntheticCopyIfNeeded",
        message: "Synchronous sentinel capture (Windows-parity)",
        data: ["textLength": trimmedCAP.count]
      )
      // #endregion
      emitSelectedTextIfNeeded(trimmedCAP)
    } else {
      // #region agent log
      MacosOverlayPopupPlugin.emitDebugLog(
        hypothesisId: "H59",
        location: "MacosOverlayPopupPlugin.swift:sendSyntheticCopyIfNeeded",
        message: "Immediate synthetic poll produced no usable text",
        data: [
          "pollWindowMs": Int(Self.syntheticCopyPollAttempts)
            * Int(Self.syntheticCopyPollStrideSeconds * 1000),
          "sawSentinel": sawSentinel,
          "sawOnlyWhitespace": sawOnlyWhitespace,
          "sawNonSentinelRaw": sawNonSentinelRaw,
          "popupSuppressed": captureSuppressedProvider?() == true,
          "frontmostApp": NSWorkspace.shared.frontmostApplication?.localizedName ?? "",
        ]
      )
      // #endregion
      if sawSentinel && !sawNonSentinelRaw && !didUseImmediateSentinelRetryInCycle {
        didUseImmediateSentinelRetryInCycle = true
        shouldBypassCooldownForImmediateSentinelRetry = true
        armSyntheticCopyMinGapBypassOnce()
        // #region agent log
        MacosOverlayPopupPlugin.emitDebugLog(
          hypothesisId: "H60",
          location: "MacosOverlayPopupPlugin.swift:sendSyntheticCopyIfNeeded",
          message: "Scheduling immediate one-shot retry for sentinel-only poll",
          data: [:]
        )
        // #endregion
        // Execute immediately to avoid race with new pointer-down resets (H62)
        // that can interleave before the queued retry runs and recreate cooldown.
        // #region agent log
        MacosOverlayPopupPlugin.emitDebugLog(
          hypothesisId: "H63",
          location: "MacosOverlayPopupPlugin.swift:sendSyntheticCopyIfNeeded",
          message: "Executing immediate sentinel-only retry inline",
          data: [:]
        )
        // #endregion
        sendSyntheticCopyIfNeeded()
        return
      }
      if pendingNoCaptureRetryWorkItem == nil {
        let retryWork = DispatchWorkItem { [weak self] in
          self?.pendingNoCaptureRetryWorkItem = nil
          self?.shouldBypassCooldownForImmediateSentinelRetry = true
          self?.armSyntheticCopyMinGapBypassOnce()
          // #region agent log
          MacosOverlayPopupPlugin.emitDebugLog(
            hypothesisId: "H61",
            location: "MacosOverlayPopupPlugin.swift:sendSyntheticCopyIfNeeded",
            message: "Retry synthetic copy after empty immediate capture (bypass cooldown/min-gap once)",
            data: [:]
          )
          // #endregion
          self?.sendSyntheticCopyIfNeeded()
        }
        pendingNoCaptureRetryWorkItem = retryWork
        // #region agent log
        MacosOverlayPopupPlugin.emitDebugLog(
          hypothesisId: "H57",
          location: "MacosOverlayPopupPlugin.swift:sendSyntheticCopyIfNeeded",
          message: "Scheduled one-shot retry after empty immediate capture",
          data: ["retryDelayMs": 80]
        )
        // #endregion
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08, execute: retryWork)
      }
      DispatchQueue.main.async { [weak self] in
        self?.pollPasteboardSelection()
      }
    }
  }

  private func pollPasteboardSelection() {
    if isSyntheticClipboardPollingBusy {
      return
    }
    if ignoreSyntheticCopyUntilMouseButtonsReleased {
      return
    }
    let suppressed = captureSuppressedProvider?() == true
    let armed = Date() < selectionCaptureArmedUntil
    if suppressed {
      // Clipboard polling is unreliable while our overlay may influence the general
      // pasteboard state; Accessibility still reflects the foreground app selection.
      // Without this branch, timers only emitted H15 and short follow-up selections
      // commonly missed ("first OK, subsequent miss") when suppression stayed true.
      if armed,
        let accessibilityText = readSelectedTextViaAccessibility(),
        isLikelyUserSelection(accessibilityText)
      {
        if accessibilityText == lastEmittedText && !forceEmitNextSelection {
          return
        }
        // #region agent log
        MacosOverlayPopupPlugin.emitDebugLog(
          hypothesisId: "H33",
          location: "MacosOverlayPopupPlugin.swift:pollPasteboardSelection",
          message: "AX selection while popup visible (suppressed clipboard poll)",
          data: ["textLength": accessibilityText.count]
        )
        // #endregion
        emitSelectedTextIfNeeded(accessibilityText)
      } else {
        // #region agent log
        MacosOverlayPopupPlugin.emitDebugLog(
          hypothesisId: "H15",
          location: "MacosOverlayPopupPlugin.swift:pollPasteboardSelection",
          message: "Selection polling suppressed while popup is visible",
          data: [
            "frontmostApp": NSWorkspace.shared.frontmostApplication?.localizedName ?? "",
            "axTrusted": AXIsProcessTrusted(),
          ]
        )
        // #endregion
      }
      return
    }
    let pasteboard = NSPasteboard.general
    let currentChangeCount = pasteboard.changeCount
    if currentChangeCount != lastPasteboardChangeCount {
      lastPasteboardChangeCount = currentChangeCount
      if armed,
        let selectedText = pasteboard.string(forType: .string)?
          .trimmingCharacters(in: .whitespacesAndNewlines),
        isLikelyUserSelection(selectedText)
      {
        emitSelectedTextIfNeeded(selectedText)
        return
      }
    }

    if armed,
      let accessibilityText = readSelectedTextViaAccessibility(),
      isLikelyUserSelection(accessibilityText)
    {
      emitSelectedTextIfNeeded(accessibilityText)
    }
  }

  private func emitSelectedTextIfNeeded(_ selectedText: String) {
    let shouldBypassDedup = forceEmitNextSelection
    forceEmitNextSelection = false
    if !shouldBypassDedup, selectedText == lastEmittedText {
      // #region agent log
      MacosOverlayPopupPlugin.emitDebugLog(
        hypothesisId: "H64",
        location: "MacosOverlayPopupPlugin.swift:emitSelectedTextIfNeeded",
        message: "Duplicate selection forwarded (dedup disabled by user request)",
        data: [
          "textLength": selectedText.count
        ]
      )
      // #endregion
    }
    let appName = NSWorkspace.shared.frontmostApplication?.localizedName ?? ""
    if appName == "desktop" {
      // #region agent log
      MacosOverlayPopupPlugin.emitDebugLog(
        hypothesisId: "H14",
        location: "MacosOverlayPopupPlugin.swift:emitSelectedTextIfNeeded",
        message: "Selection dropped because frontmost app is desktop",
        data: [
          "textLength": selectedText.count,
          "appName": appName
        ]
      )
      // #endregion
      return
    }
    lastEmittedText = selectedText
    let postEmitCooldown = Self.postEmitSyntheticCooldown(forTextLength: selectedText.count)
    blockSyntheticCopyUntil = Date().addingTimeInterval(postEmitCooldown)
    // #region agent log
    MacosOverlayPopupPlugin.emitDebugLog(
      hypothesisId: "H55",
      location: "MacosOverlayPopupPlugin.swift:emitSelectedTextIfNeeded",
      message: "Applied post-emit synthetic cooldown",
      data: [
        "textLength": selectedText.count,
        "cooldownMs": Int(ceil(postEmitCooldown * 1000)),
      ]
    )
    // #endregion
    // #region agent log
    MacosOverlayPopupPlugin.emitDebugLog(
      hypothesisId: "H11",
      location: "MacosOverlayPopupPlugin.swift:emitSelectedTextIfNeeded",
      message: "Selection emitted to Flutter event channel",
      data: [
        "textLength": selectedText.count
      ]
    )
    // #endregion
    eventSink?(["selectedText": selectedText])
  }

  fileprivate func resetEmittedSelectionDedup() {
    lastEmittedText = ""
  }

  private func isLikelyUserSelection(_ text: String) -> Bool {
    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
    if trimmed.count < 1 {
      // #region agent log
      MacosOverlayPopupPlugin.emitDebugLog(
        hypothesisId: "H23",
        location: "MacosOverlayPopupPlugin.swift:isLikelyUserSelection",
        message: "Selection rejected by native length filter",
        data: ["len": trimmed.count]
      )
      // #endregion
      return false
    }
    return true
  }

  private func requestAccessibilityPermissionIfNeeded() {
    if didPromptAccessibilityPermission {
      return
    }
    didPromptAccessibilityPermission = true
    let options = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: true] as CFDictionary
    _ = AXIsProcessTrustedWithOptions(options)
  }

  private func copyAppFocusedAXUIElement() -> AXUIElement? {
    if let front = NSWorkspace.shared.frontmostApplication {
      let appAx = AXUIElementCreateApplication(front.processIdentifier)
      var appFocused: CFTypeRef?
      let appFocusedResult = AXUIElementCopyAttributeValue(
        appAx,
        kAXFocusedUIElementAttribute as CFString,
        &appFocused
      )
      if appFocusedResult == .success, let appFocused {
        return unsafeBitCast(appFocused, to: AXUIElement.self)
      }
    }
    let systemWide = AXUIElementCreateSystemWide()
    var focusedElement: CFTypeRef?
    let focusedResult = AXUIElementCopyAttributeValue(
      systemWide,
      kAXFocusedUIElementAttribute as CFString,
      &focusedElement
    )
    guard focusedResult == .success, let element = focusedElement else {
      return nil
    }
    return unsafeBitCast(element, to: AXUIElement.self)
  }

  private func axRole(of element: AXUIElement) -> String? {
    var roleValue: CFTypeRef?
    guard AXUIElementCopyAttributeValue(element, kAXRoleAttribute as CFString, &roleValue) == .success,
      let role = roleValue as? String
    else {
      return nil
    }
    return role
  }

  /// Double-click without drag only emits when AX reports selected text **and** focus is not under
  /// Finder-like `AXBrowser` / `AXOutline` trees (those clicks normally open items, not word-select).
  private func multiClickGestureFocusPermitsWordSelectionEmit() -> Bool {
    guard let focused = copyAppFocusedAXUIElement() else {
      return false
    }
    var current: AXUIElement? = focused
    var depth = 0
    while let el = current, depth < 14 {
      if let role = axRole(of: el), Self.axRolesRejectingMultiClickWordCapture.contains(role) {
        return false
      }
      var parentRef: CFTypeRef?
      guard AXUIElementCopyAttributeValue(el, kAXParentAttribute as CFString, &parentRef) == .success,
        let parentRef
      else {
        break
      }
      current = unsafeBitCast(parentRef, to: AXUIElement.self)
      depth += 1
    }
    return true
  }

  private func readSelectedTextViaAccessibility(logFailures: Bool = false) -> String? {
    func debugFail(_ stage: String, _ code: AXError? = nil, _ extra: [String: Any] = [:]) {
      if stage.hasPrefix("focused_element_"), code?.rawValue == -25204 {
        axFocusedElementFailureStreak += 1
        if axFocusedElementFailureStreak >= 2 {
          axFocusedElementBlockedUntil = Date().addingTimeInterval(12)
        }
      }
      guard logFailures else { return }
      var payload: [String: Any] = [
        "stage": stage,
        "frontmostApp": NSWorkspace.shared.frontmostApplication?.localizedName ?? "",
      ]
      if let code {
        payload["axErrorRaw"] = Int(code.rawValue)
      }
      for (k, v) in extra {
        payload[k] = v
      }
      // #region agent log
      MacosOverlayPopupPlugin.emitDebugLog(
        hypothesisId: "H51",
        location: "MacosOverlayPopupPlugin.swift:readSelectedTextViaAccessibility",
        message: "AX selected-text read failed at stage",
        data: payload
      )
      // #endregion
    }

    guard AXIsProcessTrusted() else {
      axFocusedElementFailureStreak = 0
      debugFail("not_trusted")
      return nil
    }
    func readFromFocusedElement(_ uiElement: AXUIElement, source: String) -> String? {
      var selectedTextValue: CFTypeRef?
      let selectedResult = AXUIElementCopyAttributeValue(
        uiElement,
        kAXSelectedTextAttribute as CFString,
        &selectedTextValue
      )
      if selectedResult == .success, let raw = selectedTextValue as? String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
          return trimmed
        }
      } else {
        debugFail("selected_text_attr_\(source)", selectedResult)
      }

      var selectedRangeValue: CFTypeRef?
      let rangeResult = AXUIElementCopyAttributeValue(
        uiElement,
        kAXSelectedTextRangeAttribute as CFString,
        &selectedRangeValue
      )
      guard
        rangeResult == .success,
        let selectedRangeValue,
        CFGetTypeID(selectedRangeValue) == AXValueGetTypeID()
      else {
        debugFail("selected_text_range_attr_\(source)", rangeResult)
        return nil
      }
      let rangeAX = unsafeBitCast(selectedRangeValue, to: AXValue.self)
      guard AXValueGetType(rangeAX) == .cfRange else {
        debugFail("selected_text_range_type_\(source)")
        return nil
      }
      var selectedRange = CFRange()
      AXValueGetValue(rangeAX, .cfRange, &selectedRange)
      guard selectedRange.length > 0 else {
        debugFail("selected_text_range_empty_\(source)", nil, ["length": Int(selectedRange.length)])
        return nil
      }

      var rangedTextValue: CFTypeRef?
      let rangedResult = AXUIElementCopyParameterizedAttributeValue(
        uiElement,
        kAXStringForRangeParameterizedAttribute as CFString,
        rangeAX,
        &rangedTextValue
      )
      guard rangedResult == .success, let rangedText = rangedTextValue as? String else {
        debugFail("string_for_range_\(source)", rangedResult, ["length": Int(selectedRange.length)])
        return nil
      }
      let trimmed = rangedText.trimmingCharacters(in: .whitespacesAndNewlines)
      if trimmed.isEmpty {
        debugFail("string_for_range_empty_\(source)", nil, ["length": Int(selectedRange.length)])
        return nil
      }
      return trimmed
    }

    // Prefer app-scoped AX focused element (more reliable than system-wide in Chrome/WebView).
    if let front = NSWorkspace.shared.frontmostApplication {
      let appAx = AXUIElementCreateApplication(front.processIdentifier)
      var appFocused: CFTypeRef?
      let appFocusedResult = AXUIElementCopyAttributeValue(
        appAx,
        kAXFocusedUIElementAttribute as CFString,
        &appFocused
      )
      if appFocusedResult == .success, let appFocused {
        let uiElement = unsafeBitCast(appFocused, to: AXUIElement.self)
        if let text = readFromFocusedElement(uiElement, source: "app") {
          axFocusedElementFailureStreak = 0
          axFocusedElementBlockedUntil = .distantPast
          return text
        }
      } else {
        debugFail("focused_element_app", appFocusedResult, ["pid": Int(front.processIdentifier)])
      }
    }

    // Fallback: system-wide focused element.
    let systemWide = AXUIElementCreateSystemWide()
    var focusedElement: CFTypeRef?
    let focusedResult = AXUIElementCopyAttributeValue(
      systemWide,
      kAXFocusedUIElementAttribute as CFString,
      &focusedElement
    )
    guard focusedResult == .success, let element = focusedElement else {
      debugFail("focused_element_system", focusedResult)
      return nil
    }
    let uiElement = unsafeBitCast(element, to: AXUIElement.self)
    if let text = readFromFocusedElement(uiElement, source: "system") {
      axFocusedElementFailureStreak = 0
      axFocusedElementBlockedUntil = .distantPast
      return text
    }
    return nil
  }
}
