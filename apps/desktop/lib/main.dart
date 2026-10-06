import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:app_l10n/app_l10n.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import 'overlay_main.dart' as overlay_entry;
import 'core/hotkey/hotkey_provider.dart';
import 'core/hotkey/hotkey_service.dart';
import 'core/local/local_db.dart';
import 'core/backup/scheduled_local_backup_service.dart';
import 'core/logging/logger_service.dart';
import 'core/auth/auth_service.dart';
import 'core/sync/sync_service.dart';
import 'core/theme/desktop_text_scale.dart';
import 'core/theme/fluent_theme.dart';
import 'core/context/foreground_window_context.dart';
import 'core/debug_ndjson_ingest.dart';
import 'core/window/native_overlay_window_controller.dart';
import 'core/window/popup_save_bridge.dart';
import 'core/monetization/app_state.dart';
import 'core/monetization/banner_ad_widget.dart';
import 'features/capture/application/capture_controller.dart';
import 'features/capture/data/ocr_adapter.dart';
import 'features/dashboard/presentation/dashboard_home_screen.dart';
import 'features/dashboard/presentation/fluent_dashboard_shell.dart';
import 'features/guides/presentation/guides_screen.dart';
import 'features/capture/presentation/capture_dashboard_page.dart';
import 'features/capture/presentation/desktop_capture_intents.dart';
import 'features/capture/presentation/capture_popup.dart';
import 'features/capture/presentation/region_selector_overlay.dart';
import 'features/settings/application/settings_service.dart';
import 'features/settings/presentation/language_settings_screen.dart';
import 'features/review/application/review_controller.dart';
import 'features/review/presentation/srs_review_screen.dart';
import 'features/vocab/data/vocab_repository_impl.dart';
import 'features/vocab/presentation/vocab_list_provider.dart';
import 'features/vocab/presentation/vocab_library_screen.dart';
import 'features/about/presentation/about_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalDb.initialize();

  final container = ProviderContainer();
  unawaited(TesseractLanguagePackManager.instance.ensureStarterPack());
  container.read(syncServiceProvider).startBackgroundRetry();
  container.read(scheduledLocalBackupServiceProvider).start();

  runApp(
    UncontrolledProviderScope(container: container, child: const DesktopApp()),
  );
}

@pragma('vm:entry-point')
Future<void> overlayMain() {
  return overlay_entry.runOverlayApp();
}

class DesktopApp extends ConsumerWidget {
  const DesktopApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uiTag = ref.watch(uiLocalePreferenceProvider);
    final uiTextScale = ref.watch(uiTextScalePreferenceProvider);
    final locale = localeFromUiPreferenceTag(uiTag);
    return fluent.FluentApp(
      debugShowCheckedModeBanner: false,
      title: 'Language Learner Desktop',
      theme: buildDesktopFluentLightTheme(),
      darkTheme: buildDesktopFluentDarkTheme(),
      themeMode: ThemeMode.dark,
      builder: (context, child) => attachDesktopCombinedTextScaler(
        context,
        child,
        userTextScaleMultiplier: uiTextScale,
      ),
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        fluent.FluentLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: const DesktopHomePage(),
    );
  }
}

class DesktopHomePage extends ConsumerStatefulWidget {
  const DesktopHomePage({super.key});

  @override
  ConsumerState<DesktopHomePage> createState() => _DesktopHomePageState();
}

class _DesktopHomePageState extends ConsumerState<DesktopHomePage> {
  /// `flutter test` does not always set `FLUTTER_TEST`; binding type is reliable.
  bool get _runningWidgetTest =>
      Platform.environment.containsKey('FLUTTER_TEST') ||
      WidgetsBinding.instance.runtimeType.toString().contains(
        'AutomatedTestWidgetsFlutterBinding',
      );
  static const Color _overlayTransparencyColor = Color(0xFFFF00FF);
  static const int _textCaptureHotkeyId = 1001;
  static const int _imageCaptureHotkeyId = 1002;
  static const int _toggleAutoCaptureHotkeyId = 1003;
  static const HotkeyBinding _textCaptureBinding = HotkeyBinding(
    id: _textCaptureHotkeyId,
    key: 'D',
    modifiers: <HotkeyModifier>{HotkeyModifier.control, HotkeyModifier.shift},
    mode: CaptureMode.text,
  );
  static const HotkeyBinding _imageCaptureBinding = HotkeyBinding(
    id: _imageCaptureHotkeyId,
    key: 'X',
    modifiers: <HotkeyModifier>{HotkeyModifier.control, HotkeyModifier.shift},
    mode: CaptureMode.image,
  );
  static HotkeyBinding _toggleAutoCaptureBinding(String key) => HotkeyBinding(
    id: _toggleAutoCaptureHotkeyId,
    key: key,
    modifiers: <HotkeyModifier>{HotkeyModifier.control, HotkeyModifier.shift},
    mode: CaptureMode.text,
  );

  bool _isCapturePopupOpen = false;
  bool _isRegionSelectorOpen = false;
  CaptureMode _activePopupMode = CaptureMode.text;
  late final HotkeyService _hotkeyService;
  final PopupSaveBridge _popupSaveBridge = const PopupSaveBridge();
  StreamSubscription<HotkeyPressEvent>? _hotkeySubscription;
  StreamSubscription<PopupSaveRequest>? _popupSaveSubscription;
  OverlayEntry? _captureOverlayEntry;
  OverlayEntry? _regionSelectorOverlayEntry;
  Offset _lastPointerPosition = const Offset(320, 220);
  Offset _capturePopupPosition = const Offset(320, 220);
  Offset? _nativeContentOffset;
  bool _globalHotkeyAvailable = true;
  bool _nativeOverlayActive = false;
  bool _overlaySessionActive = false;
  String? _overlayStatusMessage;
  String _toggleAutoCaptureHotkeyKey =
      AutoCaptureToggleHotkeyPreference.defaultKey;
  bool _hasSyncedToggleHotkeyPreference = false;
  bool _isRegisteringHotkeys = false;
  bool _hotkeyReregisterQueued = false;
  StreamSubscription<Object?>? _systemTextSelectionSubscription;
  DateTime? _lastSystemSelectionEvent;
  String? _lastSystemSelectionEmittedText;
  int _systemSelectionSessionId = 0;
  /// Short debounce only (native layer dedup resets when the overlay closes).
  static const Duration _systemSelectionDuplicateCooldown = Duration(
    milliseconds: 0,
  );

  @override
  void initState() {
    super.initState();
    _hotkeyService = ref.read(hotkeyServiceProvider);
    _popupSaveSubscription = _popupSaveBridge.requests().listen(
      _handlePopupSaveRequest,
    );
    Future<void>.microtask(() async {
      final hotkeyKey = await ref
          .read(settingsServiceProvider)
          .loadAutoCaptureToggleHotkeyKey();
      _toggleAutoCaptureHotkeyKey = hotkeyKey;
      try {
        await ref.read(syncServiceProvider).syncNow();
      } catch (error, stackTrace) {
        debugPrint('Initial sync failed (continuing app startup): $error');
        debugPrint('$stackTrace');
      }
      await _registerGlobalHotkeys();
    });
  }

  @override
  void dispose() {
    if (!_runningWidgetTest) {
      unawaited(
        ref
            .read(nativeOverlayWindowControllerProvider)
            .setSelectionCaptureExtras(
              clipboardListen: false,
              dragSendCtrlC: false,
              useUiaSelectionHost: false,
              strictAutoCaptureFilter: true,
            ),
      );
    }
    _detachSystemTextSelectionSubscription();
    _removeCaptureOverlay();
    _removeRegionSelectorOverlay();
    unawaited(_popupSaveSubscription?.cancel() ?? Future<void>.value());
    unawaited(_hotkeySubscription?.cancel() ?? Future<void>.value());
    unawaited(_hotkeyService.unregisterAll());
    super.dispose();
  }

  void _attachSystemTextSelectionSubscription() {
    if (_runningWidgetTest) {
      return;
    }
    if (_systemTextSelectionSubscription != null) {
      return;
    }
    const channel = EventChannel('formycareer/system_text_selection');
    _systemTextSelectionSubscription = channel.receiveBroadcastStream().listen(
      _onSystemTextSelectionEvent,
      onError: (_) {},
    );
  }

  Future<void> _attachSystemTextSelectionWithSyncedNative() async {
    await _syncSelectionCaptureExtrasToNative();
    if (!mounted) {
      return;
    }
    _attachSystemTextSelectionSubscription();
  }

  void _detachSystemTextSelectionSubscription() {
    unawaited(
      _systemTextSelectionSubscription?.cancel() ?? Future<void>.value(),
    );
    _systemTextSelectionSubscription = null;
  }

  Future<void> _syncSelectionCaptureExtrasToNative() async {
    if (_runningWidgetTest) {
      return;
    }
    final open = ref.read(openCaptureOnTextSelectionProvider);
    final strict = ref.read(strictAutoCaptureFilterProvider);
    await ref
        .read(nativeOverlayWindowControllerProvider)
        .setSelectionCaptureExtras(
          clipboardListen: false,
          dragSendCtrlC: open,
          useUiaSelectionHost: false,
          strictAutoCaptureFilter: strict,
        );
  }

  bool _passesSystemSelectionGuard(String text) {
    final t = text.trim();
    if (t.isEmpty || t.length > 5000) {
      return false;
    }
    final letterCount = RegExp(r'[\p{L}]', unicode: true).allMatches(t).length;
    if (letterCount == 0) {
      return false;
    }
    final symbolCount = RegExp(
      r"""[^\p{L}\p{N}\s\.,;:!?\-'"“”‘’()\[\]/]""",
      unicode: true,
    ).allMatches(t).length;
    final symbolRatio = symbolCount / t.length;
    if (symbolRatio > 0.45) {
      return false;
    }
    return true;
  }

  String _normalizeOcrAsSelectedText(String input) {
    final singleLine = input.replaceAll(RegExp(r'[\r\n]+'), ' ');
    return singleLine.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  void _onSystemTextSelectionEvent(Object? event) {
    if (!mounted) {
      return;
    }
    if (event is! Map<Object?, Object?>) {
      return;
    }
    final raw = event['selectedText'];
    if (raw is! String) {
      return;
    }
    final text = raw.trim();
    if (text.isEmpty) {
      return;
    }
    // #region agent log
    unawaited(
      _debugLog(
        hypothesisId: 'H18',
        location: 'main.dart:_onSystemTextSelectionEvent:received',
        message: 'Dart received system selection event',
        data: <String, Object?>{
          'len': text.length,
          'preview': text.length > 40 ? text.substring(0, 40) : text,
        },
      ),
    );
    // #endregion
    if (!_passesSystemSelectionGuard(text)) {
      // #region agent log
      unawaited(
        _debugLog(
          hypothesisId: 'H19',
          location: 'main.dart:_onSystemTextSelectionEvent:guardRejected',
          message: 'Dart guard rejected selection',
          data: <String, Object?>{'len': text.length},
        ),
      );
      // #endregion
      return;
    }
    if (!ref.read(openCaptureOnTextSelectionProvider)) {
      return;
    }
    final now = DateTime.now();
    if (text == _lastSystemSelectionEmittedText &&
        _lastSystemSelectionEvent != null &&
        now.difference(_lastSystemSelectionEvent!) <
            _systemSelectionDuplicateCooldown) {
      // #region agent log
      unawaited(
        _debugLog(
          hypothesisId: 'H18',
          location: 'main.dart:_onSystemTextSelectionEvent:duplicateCooldown',
          message: 'Dart duplicate cooldown skipped event',
          data: <String, Object?>{
            'elapsedMs': now.difference(_lastSystemSelectionEvent!).inMilliseconds,
            'cooldownMs': _systemSelectionDuplicateCooldown.inMilliseconds,
            'len': text.length,
          },
        ),
      );
      // #endregion
      return;
    }
    final selectionSessionId = ++_systemSelectionSessionId;
    if (_isCapturePopupOpen || _isRegionSelectorOpen || _nativeOverlayActive) {
      // #region agent log
      unawaited(
        _debugLog(
          hypothesisId: 'H65',
          location: 'main.dart:_onSystemTextSelectionEvent:resetPreviousSession',
          message: 'Resetting previous popup/session for new selection',
          data: <String, Object?>{
            'wasCapturePopupOpen': _isCapturePopupOpen,
            'wasRegionSelectorOpen': _isRegionSelectorOpen,
            'wasNativeOverlayActive': _nativeOverlayActive,
          },
        ),
      );
      // #endregion
      _removeRegionSelectorOverlay();
      _removeCaptureOverlay();
      unawaited(ref.read(nativeOverlayWindowControllerProvider).hide());
    }
    _lastSystemSelectionEvent = now;
    _lastSystemSelectionEmittedText = text;
    final sourceAtSelection = readForegroundSourceContext();
    unawaited(() async {
      if (!mounted || selectionSessionId != _systemSelectionSessionId) {
        return;
      }
      final cursor = await _resolveGlobalCursorPosition();
      if (!mounted || selectionSessionId != _systemSelectionSessionId) {
        return;
      }
      // #region agent log
      unawaited(
        _debugLog(
          hypothesisId: 'H20',
          location: 'main.dart:_onSystemTextSelectionEvent:openPopup',
          message: 'Dart opening popup for selection',
          data: <String, Object?>{'len': text.length},
        ),
      );
      // #endregion
      await _showCapturePopup(
        mode: CaptureMode.text,
        triggerCursor: cursor,
        preferNativeOverlay: true,
        allowInAppFallback: true,
        prefilledSelectedText: text,
        sourceAppHintOverride: sourceAtSelection.displayLabel,
        sourceUrlHintOverride: sourceAtSelection.sourceUrl,
      );
    }());
  }

  Future<void> _handlePopupSaveRequest(PopupSaveRequest request) async {
    final result = await ref
        .read(captureControllerProvider.notifier)
        .saveCapturedEntry(
          sourceText: request.sourceText,
          translatedText: request.translatedText,
          languagePair: request.languagePair,
          passageForContext: request.passage,
          selectionStart: request.selectionStart,
          selectionEnd: request.selectionEnd,
          sourceUrl: request.sourceUrl,
          tags: request.tags,
          sourceApp: request.sourceApp,
        );
    try {
      await _popupSaveBridge.completeSaveRequest(
        requestId: request.requestId,
        success: result.success,
        message: result.message,
      );
    } catch (_) {}
  }

  Future<void> _registerGlobalHotkeys() async {
    if (_isRegisteringHotkeys) {
      _hotkeyReregisterQueued = true;
      return;
    }
    _isRegisteringHotkeys = true;
    try {
      await _registerGlobalHotkeysCore();
    } finally {
      _isRegisteringHotkeys = false;
      if (_hotkeyReregisterQueued) {
        _hotkeyReregisterQueued = false;
        unawaited(_registerGlobalHotkeys());
      }
    }
  }

  Future<void> _registerGlobalHotkeysCore() async {
    await _hotkeySubscription?.cancel();
    _hotkeySubscription = null;
    await _hotkeyService.unregisterAll();

    bool textRegistered = false;
    bool imageRegistered = false;
    bool toggleRegistered = false;
    var attempt = 0;
    const maxAttempts = 3;
    while (attempt < maxAttempts) {
      attempt += 1;
      textRegistered = await _hotkeyService.registerHotkey(_textCaptureBinding);
      imageRegistered = await _hotkeyService.registerHotkey(_imageCaptureBinding);
      toggleRegistered = await _hotkeyService.registerHotkey(
        _toggleAutoCaptureBinding(_toggleAutoCaptureHotkeyKey),
      );
      if (textRegistered && imageRegistered && toggleRegistered) {
        break;
      }
      await _hotkeyService.unregisterAll();
      await Future<void>.delayed(const Duration(milliseconds: 120));
    }
    final registered = textRegistered && imageRegistered && toggleRegistered;
    if (!mounted) {
      return;
    }
    if (registered) {
      _hotkeySubscription = _hotkeyService.onHotkeyPressed.listen((event) {
        if (event.id == _toggleAutoCaptureHotkeyId) {
          _toggleAutoCaptureFromHotkey();
          return;
        }
        if (event.id == _textCaptureHotkeyId) {
          _onGlobalHotkeyPressed(mode: CaptureMode.text);
          return;
        }
        if (event.id == _imageCaptureHotkeyId) {
          _onGlobalHotkeyPressed(mode: CaptureMode.image);
        }
      });
      setState(() => _globalHotkeyAvailable = true);
      return;
    }

    LoggerService.logSync(
      source: 'desktop_hotkey',
      stage: 'fallback_in_app_shortcut',
      success: false,
    );
    setState(() => _globalHotkeyAvailable = false);
  }

  void _toggleAutoCaptureFromHotkey() {
    final current = ref.read(openCaptureOnTextSelectionProvider);
    final next = !current;
    unawaited(
      ref.read(openCaptureOnTextSelectionProvider.notifier).setEnabled(next),
    );
    final status = next ? 'ON' : 'OFF';
    unawaited(
      _showInfoBar(
        context,
        'Auto capture: $status ($_toggleAutoCaptureDisplayLabel)',
        severity: fluent.InfoBarSeverity.info,
      ),
    );
  }

  String get _toggleAutoCaptureDisplayLabel =>
      'Ctrl+Shift+$_toggleAutoCaptureHotkeyKey';

  LogicalKeyboardKey? _logicalKeyFromHotkeyValue(String key) {
    final normalized = key.trim().toUpperCase();
    if (normalized.length != 1) {
      return null;
    }
    final char = normalized.codeUnitAt(0);
    if (char >= 0x41 && char <= 0x5A) {
      return LogicalKeyboardKey(char + 0x20);
    }
    if (char >= 0x30 && char <= 0x39) {
      return LogicalKeyboardKey(char);
    }
    return null;
  }

  void _onGlobalHotkeyPressed({required CaptureMode mode}) {
    if (!mounted) {
      return;
    }
    unawaited(_handleGlobalHotkeyFlow(mode: mode));
  }

  Future<void> _handleGlobalHotkeyFlow({required CaptureMode mode}) async {
    if (_runningWidgetTest) {
      switch (mode) {
        case CaptureMode.text:
          await _showCapturePopup(
            mode: CaptureMode.text,
            triggerCursor: _lastPointerPosition,
            preferNativeOverlay: false,
          );
        case CaptureMode.image:
          _startImageRegionSelection();
      }
      return;
    }
    final cursorForPopup = await _resolveGlobalCursorPosition();
    final sourceAtTrigger = readForegroundSourceContext();
    switch (mode) {
      case CaptureMode.text:
        await _showCapturePopup(
          mode: CaptureMode.text,
          triggerCursor: cursorForPopup,
          preferNativeOverlay: true,
          allowInAppFallback: true,
          sourceAppHintOverride: sourceAtTrigger.displayLabel,
          sourceUrlHintOverride: sourceAtTrigger.sourceUrl,
        );
      case CaptureMode.image:
        if (Platform.isMacOS) {
          await _captureImageViaInteractiveOcr(
            triggerCursor: cursorForPopup,
            sourceAppHint: sourceAtTrigger.displayLabel,
            sourceUrlHint: sourceAtTrigger.sourceUrl,
          );
          return;
        }
        await _showCapturePopup(
          mode: CaptureMode.image,
          triggerCursor: cursorForPopup,
          preferNativeOverlay: true,
          allowInAppFallback: true,
          sourceAppHintOverride: sourceAtTrigger.displayLabel,
          sourceUrlHintOverride: sourceAtTrigger.sourceUrl,
        );
    }
  }

  Future<void> _captureImageViaInteractiveOcr({
    required Offset triggerCursor,
    String? sourceAppHint,
    String? sourceUrlHint,
  }) async {
    if (_isCapturePopupOpen || _isRegionSelectorOpen || !mounted) {
      return;
    }
    final raw = await ref.read(ocrAdapterProvider).extractText();
    final normalized = _normalizeOcrAsSelectedText(raw);
    if (normalized.isEmpty || !mounted) {
      return;
    }
    await _showCapturePopup(
      mode: CaptureMode.text,
      triggerCursor: triggerCursor,
      preferNativeOverlay: true,
      allowInAppFallback: true,
      prefilledSelectedText: normalized,
      sourceAppHintOverride: sourceAppHint,
      sourceUrlHintOverride: sourceUrlHint,
    );
  }

  Future<Offset> _resolveGlobalCursorPosition() async {
    if (_runningWidgetTest) {
      return _lastPointerPosition;
    }
    final cursor = await ref
        .read(nativeOverlayWindowControllerProvider)
        .getCursorPosition();
    if (cursor == null) {
      return _lastPointerPosition;
    }
    _lastPointerPosition = cursor;
    return cursor;
  }

  Future<void> _ensureRunnerForegroundForFallback() async {
    if (_runningWidgetTest) {
      return;
    }
    final overlayController = ref.read(nativeOverlayWindowControllerProvider);
    await overlayController.activateRunner();
    for (var i = 0; i < 8; i++) {
      final active = await overlayController.isRunnerForeground();
      if (active) {
        break;
      }
      await Future<void>.delayed(const Duration(milliseconds: 70));
    }
    await Future<void>.delayed(const Duration(milliseconds: 90));
  }

  Future<void> _showCapturePopup({
    CaptureMode mode = CaptureMode.text,
    Offset? triggerCursor,
    Rect? selectedRegion,
    bool preferNativeOverlay = false,
    bool allowInAppFallback = true,
    String? prefilledSelectedText,
    String? sourceAppHintOverride,
    String? sourceUrlHintOverride,
  }) async {
    if (_isCapturePopupOpen || _isRegionSelectorOpen || !mounted) {
      // #region agent log
      unawaited(
        _debugLog(
          hypothesisId: 'H21',
          location: 'main.dart:_showCapturePopup:blockedByUiGuard',
          message: 'Popup request blocked by UI guard',
          data: <String, Object?>{
            'isCapturePopupOpen': _isCapturePopupOpen,
            'isRegionSelectorOpen': _isRegionSelectorOpen,
            'mounted': mounted,
          },
        ),
      );
      // #endregion
      return;
    }
    var effectiveMode = mode;
    var effectiveSelectedRegion = selectedRegion;
    var effectivePrefilledText = prefilledSelectedText?.trim();
    final sourceAppHint =
        sourceAppHintOverride?.trim().isNotEmpty == true
        ? sourceAppHintOverride!.trim()
        : readForegroundWindowLabel();
    final sourceUrlHint = sourceUrlHintOverride?.trim() ?? '';
    final tagSuggestions = await _collectKnownTagsForPopup();
    if (effectiveMode == CaptureMode.image && effectiveSelectedRegion != null) {
      final ocrRaw = await ref
          .read(ocrAdapterProvider)
          .extractTextFromRegion(effectiveSelectedRegion);
      final ocrText = _normalizeOcrAsSelectedText(ocrRaw);
      if (ocrText.isEmpty) {
        return;
      }
      effectiveMode = CaptureMode.text;
      effectiveSelectedRegion = null;
      effectivePrefilledText = ocrText;
    }
    if (!mounted) {
      return;
    }
    _isCapturePopupOpen = true;
    _activePopupMode = effectiveMode;
    final overlay = Overlay.of(context);
    final screenSize = MediaQuery.sizeOf(context);
    final popupShell = capturePopupShellLayout(context);
    final cursor = triggerCursor ?? _lastPointerPosition;
    _capturePopupPosition = _popupOffsetNearCursor(
      context: context,
      shell: popupShell,
      cursor: cursor,
      screenSize: screenSize,
    );
    _nativeContentOffset = null;
    _nativeOverlayActive = false;
    _overlaySessionActive = false;
    _overlayStatusMessage = null;
    if (preferNativeOverlay) {
      final overlayController = ref.read(nativeOverlayWindowControllerProvider);
      var languageSettings = LanguageSettings.fallback;
      try {
        languageSettings = await ref.read(languageSettingsProvider.future);
      } catch (error, stack) {
        debugPrint('languageSettings failed, using fallback: $error\n$stack');
      }
      // Tall portrait frame for native overlay (avoid old 640×~420 landscape).
      final nativePopupH = math.min(
        popupShell.maxH.clamp(320.0, 1200.0),
        screenSize.height * 0.86,
      );
      final result = await overlayController.showNearCursor(
        popupWidth: popupShell.maxW.clamp(200.0, 720.0),
        popupHeight: nativePopupH,
        mode: effectiveMode == CaptureMode.image
            ? CapturePopupMode.image
            : CapturePopupMode.text,
        selectedRegion: effectiveSelectedRegion,
        offsetX: 10,
        offsetY: 10,
        nativeLanguage: languageSettings.nativeLanguage,
        sourceLanguages: languageSettings.sourceLanguages,
        tagSuggestions: tagSuggestions,
        selectedText:
            effectivePrefilledText != null && effectivePrefilledText.isNotEmpty
            ? effectivePrefilledText
            : null,
        sourceApp: sourceAppHint,
        sourceUrl: sourceUrlHint,
      );
      final isNativeActive = result.success && !result.fallbackUsed;
      // #region agent log
      unawaited(
        _debugLog(
          hypothesisId: 'H22',
          location: 'main.dart:_showCapturePopup:nativeResult',
          message: 'Native showNearCursor returned',
          data: <String, Object?>{
            'success': result.success,
            'fallbackUsed': result.fallbackUsed,
            'reason': result.reason,
            'isNativeActive': isNativeActive,
          },
        ),
      );
      // #endregion
      _nativeOverlayActive = isNativeActive;
      _overlaySessionActive = false;
      _nativeContentOffset = isNativeActive
          ? Offset(result.contentLeft, result.contentTop)
          : null;
      _overlayStatusMessage = result.reason.isEmpty ? null : result.reason;
      if (isNativeActive) {
        _nativeOverlayActive = false;
        _nativeContentOffset = null;
        _isCapturePopupOpen = false;
        return;
      }
      if (!allowInAppFallback) {
        _isCapturePopupOpen = false;
        return;
      }
      await _ensureRunnerForegroundForFallback();
    }

    _captureOverlayEntry = OverlayEntry(
      builder: (_) => TapRegionSurface(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: Listener(
                behavior: HitTestBehavior.opaque,
                onPointerDown: (_) => _removeCaptureOverlay(),
              ),
            ),
            Positioned(
              left: (_nativeOverlayActive && _nativeContentOffset != null)
                  ? _nativeContentOffset!.dx
                  : _capturePopupPosition.dx,
              top: (_nativeOverlayActive && _nativeContentOffset != null)
                  ? _nativeContentOffset!.dy
                  : _capturePopupPosition.dy,
              child: Builder(
                builder: (overlayContext) {
                  final shell = capturePopupShellLayout(overlayContext);
                  return ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: shell.maxW,
                      maxHeight: shell.maxH,
                    ),
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Material(
                        type: MaterialType.transparency,
                        child: CapturePopup(
                          onClose: _removeCaptureOverlay,
                          mode: _activePopupMode == CaptureMode.image
                              ? CapturePopupMode.image
                              : CapturePopupMode.text,
                          cursorPosition: triggerCursor ?? _lastPointerPosition,
                          selectedRegion: effectiveSelectedRegion,
                          initialSourceText:
                              effectivePrefilledText != null &&
                                  effectivePrefilledText.isNotEmpty
                              ? effectivePrefilledText
                              : null,
                          sourceAppHint: sourceAppHint,
                          sourceUrlHint: sourceUrlHint,
                          initialTagSuggestions: tagSuggestions,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
    overlay.insert(_captureOverlayEntry!);
  }

  Future<List<String>> _collectKnownTagsForPopup() async {
    try {
      final all = await ref.read(vocabRepositoryProvider).getAllVocab();
      final seen = <String>{};
      final tags = <String>[];
      for (final vocab in all) {
        for (final tag in vocab.tags) {
          final trimmed = tag.trim();
          if (trimmed.isEmpty) {
            continue;
          }
          final key = trimmed.toLowerCase();
          if (seen.add(key)) {
            tags.add(trimmed);
          }
        }
      }
      tags.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      return tags;
    } catch (_) {
      return const <String>[];
    }
  }

  void _startImageRegionSelection() {
    if (_isCapturePopupOpen || _isRegionSelectorOpen || !mounted) {
      return;
    }
    _isRegionSelectorOpen = true;
    final overlay = Overlay.of(context);
    _regionSelectorOverlayEntry = OverlayEntry(
      builder: (_) => Positioned.fill(
        child: RegionSelectorOverlay(
          onCancel: _removeRegionSelectorOverlay,
          onSelected: _onImageRegionSelected,
        ),
      ),
    );
    overlay.insert(_regionSelectorOverlayEntry!);
  }

  void _onImageRegionSelected(Rect region) {
    _removeRegionSelectorOverlay();
    unawaited(
      _showCapturePopup(
        mode: CaptureMode.image,
        triggerCursor: _lastPointerPosition,
        selectedRegion: region,
      ),
    );
  }

  Offset _popupOffsetNearCursor({
    required BuildContext context,
    required CapturePopupShellLayout shell,
    required Offset cursor,
    required Size screenSize,
  }) {
    // Match max size used by [CapturePopup] so the window stays on-screen.
    final popupWidth = shell.maxW;
    final popupHeight = shell.maxH;
    final gap = (12.0 * desktopOsTextLayoutFactor(context)).clamp(8.0, 22.0);

    final preferredX = cursor.dx + gap;
    final preferredY = cursor.dy + gap;
    final maxX = math.max(8.0, screenSize.width - popupWidth - 8);
    final maxY = math.max(8.0, screenSize.height - popupHeight - 8);

    final clampedX = preferredX.clamp(8.0, maxX).toDouble();
    final clampedY = preferredY.clamp(8.0, maxY).toDouble();
    return Offset(clampedX, clampedY);
  }

  void _removeCaptureOverlay() {
    _captureOverlayEntry?.remove();
    _captureOverlayEntry = null;
    _isCapturePopupOpen = false;
    _nativeContentOffset = null;
    if (_nativeOverlayActive) {
      unawaited(
        ref.read(nativeOverlayWindowControllerProvider).hide().then((result) {
          if (mounted) {
            setState(() {
              _nativeOverlayActive = false;
              _overlaySessionActive = false;
              if (!result.success) {
                _overlayStatusMessage = result.reason;
              }
            });
          } else {
            _nativeOverlayActive = false;
            _overlaySessionActive = false;
          }
        }),
      );
    } else {
      _overlaySessionActive = false;
    }
  }

  void _removeRegionSelectorOverlay() {
    _regionSelectorOverlayEntry?.remove();
    _regionSelectorOverlayEntry = null;
    _isRegionSelectorOpen = false;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<String?>>(currentAccountEmailProvider, (
      previous,
      next,
    ) async {
      final prevEmail = previous?.value;
      final nextEmail = next.value;
      if (prevEmail == nextEmail) {
        return;
      }
      ref.invalidate(vocabRepositoryProvider);
      ref.invalidate(syncServiceProvider);
      final syncService = ref.read(syncServiceProvider);
      syncService.startBackgroundRetry();
      await syncService.syncNow();
    });
    ref.listen<String>(
      localProfilesProvider.select((s) => s.activeProfileId),
      (previous, next) {
        if (previous != null && previous != next) {
          ref.invalidate(reviewControllerProvider);
          ref.invalidate(vocabListProvider);
        }
        ref.read(syncServiceProvider).startBackgroundRetry();
        ref.read(scheduledLocalBackupServiceProvider).start();
      },
    );
    ref.listen<bool>(openCaptureOnTextSelectionProvider, (previous, next) {
      if (next) {
        unawaited(_attachSystemTextSelectionWithSyncedNative());
      } else {
        _detachSystemTextSelectionSubscription();
        unawaited(_syncSelectionCaptureExtrasToNative());
      }
    });
    ref.listen<bool>(strictAutoCaptureFilterProvider, (previous, next) {
      unawaited(_syncSelectionCaptureExtrasToNative());
    });
    ref.listen<AutoCaptureToggleHotkeyPreference>(
      autoCaptureToggleHotkeyProvider,
      (previous, next) {
        final shouldSync =
            !_hasSyncedToggleHotkeyPreference ||
            _toggleAutoCaptureHotkeyKey != next.key;
        if (!shouldSync) {
          return;
        }
        _hasSyncedToggleHotkeyPreference = true;
        _toggleAutoCaptureHotkeyKey = next.key;
        unawaited(_registerGlobalHotkeys());
      },
    );
    final hotkeyPreference = ref.watch(autoCaptureToggleHotkeyProvider);
    final appState = ref.watch(appStateProvider);
    _toggleAutoCaptureHotkeyKey = hotkeyPreference.key;
    final hotkeyDiagnostics = _hotkeyService.diagnostics;
    final toggleAutoCaptureLogicalKey = _logicalKeyFromHotkeyValue(
      hotkeyPreference.key,
    );
    final shortcuts = <LogicalKeySet, Intent>{
      LogicalKeySet(
        LogicalKeyboardKey.control,
        LogicalKeyboardKey.shift,
        LogicalKeyboardKey.keyD,
      ): const DesktopCaptureTextIntent(),
      LogicalKeySet(
        LogicalKeyboardKey.control,
        LogicalKeyboardKey.shift,
        LogicalKeyboardKey.keyX,
      ): const DesktopCaptureImageIntent(),
    };
    if (toggleAutoCaptureLogicalKey != null) {
      shortcuts[LogicalKeySet(
        LogicalKeyboardKey.control,
        LogicalKeyboardKey.shift,
        toggleAutoCaptureLogicalKey,
      )] = const _ToggleAutoCaptureIntent();
    }
    return Shortcuts(
      shortcuts: shortcuts,
      child: Actions(
        actions: <Type, Action<Intent>>{
          DesktopCaptureTextIntent: CallbackAction<DesktopCaptureTextIntent>(
            onInvoke: (intent) {
              unawaited(
                _showCapturePopup(
                  mode: CaptureMode.text,
                  triggerCursor: _lastPointerPosition,
                  preferNativeOverlay: !_runningWidgetTest,
                ),
              );
              return null;
            },
          ),
          DesktopCaptureImageIntent:
              CallbackAction<DesktopCaptureImageIntent>(
            onInvoke: (intent) {
              _startImageRegionSelection();
              return null;
            },
          ),
          _ToggleAutoCaptureIntent: CallbackAction<_ToggleAutoCaptureIntent>(
            onInvoke: (intent) {
              _toggleAutoCaptureFromHotkey();
              return null;
            },
          ),
        },
        child: Listener(
          behavior: HitTestBehavior.translucent,
          onPointerHover: (event) => _lastPointerPosition = event.position,
          onPointerMove: (event) => _lastPointerPosition = event.position,
          onPointerDown: (event) => _lastPointerPosition = event.position,
          child: ScaffoldMessenger(
            child: _overlaySessionActive
                ? const ColoredBox(color: _overlayTransparencyColor)
                : Column(
                    children: [
                      Expanded(
                        child: FluentDashboardShell(
                          dashboardPaneBuilder:
                              (
                                openCapture,
                                openReview,
                                openVocabulary,
                                openSettings,
                                openAbout,
                              ) =>
                                  DashboardHomeScreen(
                            onOpenCapture: openCapture,
                            onOpenReview: openReview,
                            onOpenVocabulary: openVocabulary,
                            onOpenSettings: openSettings,
                            onOpenAbout: openAbout,
                          ),
                          capturePage: CaptureDashboardPage(
                            hotkeyDiagnostics: hotkeyDiagnostics,
                            globalHotkeyAvailable: _globalHotkeyAvailable,
                            nativeOverlayActive: _nativeOverlayActive,
                            overlayStatusMessage: _overlayStatusMessage,
                            autoCaptureToggleShortcutLabel:
                                _toggleAutoCaptureDisplayLabel,
                            onInfoBar: (message, severity) => _showInfoBar(
                              context,
                              message,
                              severity: severity,
                            ),
                          ),
                          reviewPage: const SrsReviewScreen(),
                          vocabPage: const VocabLibraryScreen(),
                          guidesPage: const GuidesScreen(),
                          settingsPage: const LanguageSettingsScreen(),
                          aboutPage: const AboutScreen(),
                        ),
                      ),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 180),
                          child: appState.isInitialized && appState.isAdsEnabled
                              ? BannerAdWidget(
                                  key: ValueKey<String>(
                                    '${appState.isPro}:${appState.adUrl}',
                                  ),
                                  isPro: appState.isPro,
                                  adUrl: appState.adUrl,
                                )
                              : const SizedBox.shrink(),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Future<void> _showInfoBar(
    BuildContext context,
    String text, {
    required fluent.InfoBarSeverity severity,
  }) {
    return fluent.displayInfoBar(
      context,
      duration: const Duration(seconds: 2),
      builder: (context, close) {
        return fluent.InfoBar(
          title: Text(text),
          severity: severity,
          action: IconButton(icon: const Icon(Icons.close), onPressed: close),
        );
      },
    );
  }

}

class _ToggleAutoCaptureIntent extends Intent {
  const _ToggleAutoCaptureIntent();
}

// #region agent log
Future<void> _debugLog({
  required String hypothesisId,
  required String location,
  required String message,
  required Map<String, Object?> data,
}) async {}
// #endregion
