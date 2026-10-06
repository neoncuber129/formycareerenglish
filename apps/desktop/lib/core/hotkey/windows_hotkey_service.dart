import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:win32/win32.dart';

import '../logging/logger_service.dart';
import 'hotkey_service.dart';
import 'windows_hotkey_event_bridge.dart';

typedef IsWindowsChecker = bool Function();
typedef WindowHandleResolver = HWND? Function();

abstract class Win32HotkeyApi {
  Win32Result<bool> registerHotKey({
    required HWND? windowHandle,
    required int id,
    required HOT_KEY_MODIFIERS modifiers,
    required int virtualKey,
  });

  Win32Result<bool> unregisterHotKey({
    required HWND? windowHandle,
    required int id,
  });
}

class Win32HotkeyApiImpl implements Win32HotkeyApi {
  const Win32HotkeyApiImpl();

  @override
  Win32Result<bool> registerHotKey({
    required HWND? windowHandle,
    required int id,
    required HOT_KEY_MODIFIERS modifiers,
    required int virtualKey,
  }) {
    return RegisterHotKey(windowHandle, id, modifiers, virtualKey);
  }

  @override
  Win32Result<bool> unregisterHotKey({
    required HWND? windowHandle,
    required int id,
  }) {
    return UnregisterHotKey(windowHandle, id);
  }
}

class WindowsHotkeyService implements HotkeyService {
  WindowsHotkeyService({
    WindowsHotkeyEventBridge? eventBridge,
    Win32HotkeyApi? win32Api,
    IsWindowsChecker? isWindows,
    WindowHandleResolver? windowHandleResolver,
  })  : _eventBridge = eventBridge ?? EventChannelWindowsHotkeyEventBridge(),
        _win32Api = win32Api ?? const Win32HotkeyApiImpl(),
        _isWindows = isWindows ?? _defaultIsWindows,
        _windowHandleResolver = windowHandleResolver ?? _defaultWindowHandleResolver {
    _eventSubscription = _eventBridge.hotkeyIds().listen(
      _handleHotkeyIdFromWindows,
      onError: (Object error) {
        _isEventBridgeConnected = false;
        _lastError = 'Event bridge error: $error';
        LoggerService.logError(
          source: 'windows_hotkey',
          action: 'event_bridge_listen',
          error: error,
        );
      },
    );
    _windowHandle = _windowHandleResolver();
    // #region agent log
    unawaited(
      _debugLog(
        hypothesisId: 'H1',
        location: 'windows_hotkey_service.dart:72',
        message: 'Hotkey service initialized',
        data: <String, Object?>{
          'windowHandle': _windowHandle?.address,
          'isWindows': _isWindows(),
        },
      ),
    );
    // #endregion
  }

  final StreamController<HotkeyPressEvent> _controller =
      StreamController<HotkeyPressEvent>.broadcast();
  final Map<int, CaptureMode> _registeredModesById = <int, CaptureMode>{};
  final Map<int, DateTime> _lastDispatchById = <int, DateTime>{};
  final WindowsHotkeyEventBridge _eventBridge;
  final Win32HotkeyApi _win32Api;
  final IsWindowsChecker _isWindows;
  final WindowHandleResolver _windowHandleResolver;
  late final StreamSubscription<WindowsHotkeyNativeEvent> _eventSubscription;
  HWND? _windowHandle;
  bool _isEventBridgeConnected = true;
  String? _lastError;

  @override
  Stream<HotkeyPressEvent> get onHotkeyPressed => _controller.stream;

  @override
  HotkeyDiagnostics get diagnostics => HotkeyDiagnostics(
        isSupported: _isWindows(),
        isEventBridgeConnected: _isEventBridgeConnected,
        registeredIds: _registeredModesById.keys.toList()..sort(),
        lastError: _lastError,
        windowHandle: _windowHandle?.address,
      );

  @override
  Future<bool> registerHotkey(HotkeyBinding binding) async {
    if (!_isWindows()) {
      _lastError = 'Platform is not Windows';
      LoggerService.logSync(
        source: 'windows_hotkey',
        stage: 'register_unsupported_platform',
        success: false,
      );
      return false;
    }

    if (_registeredModesById.containsKey(binding.id)) {
      _lastError = 'Duplicate hotkey id=${binding.id}';
      LoggerService.logSync(
        source: 'windows_hotkey',
        stage: 'register_duplicate_id',
        success: false,
        count: binding.id,
      );
      return false;
    }

    final vk = _resolveVirtualKey(binding.key);
    if (vk == null) {
      _lastError = 'Invalid hotkey key="${binding.key}"';
      LoggerService.logSync(
        source: 'windows_hotkey',
        stage: 'register_invalid_key',
        success: false,
      );
      return false;
    }

    final modifierMask = _resolveModifierMask(binding.modifiers);
    _windowHandle ??= _windowHandleResolver();
    if (_windowHandle == null) {
      LoggerService.logSync(
        source: 'windows_hotkey',
        stage: 'register_window_handle_missing',
        success: false,
      );
    }
    // #region agent log
    unawaited(
      _debugLog(
        hypothesisId: 'H1',
        location: 'windows_hotkey_service.dart:145',
        message: 'RegisterHotKey call',
        data: <String, Object?>{
          'id': binding.id,
          'mode': binding.mode.name,
          'key': binding.key,
          'windowHandle': _windowHandle?.address,
          'modifierMask': '$modifierMask',
          'virtualKey': vk,
        },
      ),
    );
    // #endregion
    final result = _win32Api.registerHotKey(
      windowHandle: null,
      id: binding.id,
      modifiers: modifierMask,
      virtualKey: vk,
    );
    if (!result.value) {
      // #region agent log
      unawaited(
        _debugLog(
          hypothesisId: 'H8',
          location: 'windows_hotkey_service.dart:163',
          message: 'RegisterHotKey failed',
          data: <String, Object?>{
            'id': binding.id,
            'mode': binding.mode.name,
            'resultValue': result.value,
            'error': result.error,
            'registeredIdsBeforeFail': _registeredModesById.keys.toList(),
          },
        ),
      );
      // #endregion
      _lastError = 'RegisterHotKey failed id=${binding.id} error=${result.error}';
      LoggerService.logError(
        source: 'windows_hotkey',
        action: 'RegisterHotKey',
        error: 'id=${binding.id} error=${result.error}',
      );
      return false;
    }
    // #region agent log
    unawaited(
      _debugLog(
        hypothesisId: 'H2',
        location: 'windows_hotkey_service.dart:171',
        message: 'RegisterHotKey success',
        data: <String, Object?>{
          'id': binding.id,
          'mode': binding.mode.name,
          'registeredCount': _registeredModesById.length + 1,
        },
      ),
    );
    // #endregion

    _registeredModesById[binding.id] = binding.mode;
    _lastError = null;
    LoggerService.logSync(
      source: 'windows_hotkey',
      stage: 'register_done',
      success: true,
      count: binding.id,
    );
    return true;
  }

  @override
  Future<void> unregisterHotkey(int id) async {
    if (!_registeredModesById.containsKey(id)) {
      // #region agent log
      unawaited(
        _debugLog(
          hypothesisId: 'H8',
          location: 'windows_hotkey_service.dart:194',
          message: 'Unregister skipped: id not found',
          data: <String, Object?>{
            'id': id,
            'registeredIds': _registeredModesById.keys.toList(),
          },
        ),
      );
      // #endregion
      return;
    }
    final result = _win32Api.unregisterHotKey(
      windowHandle: null,
      id: id,
    );
    if (!result.value) {
      // #region agent log
      unawaited(
        _debugLog(
          hypothesisId: 'H8',
          location: 'windows_hotkey_service.dart:212',
          message: 'UnregisterHotKey failed',
          data: <String, Object?>{
            'id': id,
            'resultValue': result.value,
            'error': result.error,
            'registeredIdsBeforeFail': _registeredModesById.keys.toList(),
          },
        ),
      );
      // #endregion
      _lastError = 'UnregisterHotKey failed id=$id error=${result.error}';
      LoggerService.logError(
        source: 'windows_hotkey',
        action: 'UnregisterHotKey',
        error: 'id=$id error=${result.error}',
      );
      return;
    }
    // #region agent log
    unawaited(
      _debugLog(
        hypothesisId: 'H8',
        location: 'windows_hotkey_service.dart:231',
        message: 'UnregisterHotKey success',
        data: <String, Object?>{
          'id': id,
        },
      ),
    );
    // #endregion
    _registeredModesById.remove(id);
    if (_registeredModesById.isEmpty) {
      _lastError = null;
    }
  }

  @override
  Future<void> unregisterAll() async {
    final ids = List<int>.from(_registeredModesById.keys);
    for (final id in ids) {
      await unregisterHotkey(id);
    }
  }

  void emitHotkeyPressed(int id) {
    final mode = _registeredModesById[id];
    if (mode == null) {
      return;
    }
    _controller.add(
      HotkeyPressEvent(
        id: id,
        mode: mode,
        timestamp: DateTime.now(),
      ),
    );
  }

  void dispose() {
    unawaited(_eventSubscription.cancel());
    _controller.close();
  }

  void _handleHotkeyIdFromWindows(WindowsHotkeyNativeEvent nativeEvent) {
    _isEventBridgeConnected = true;
    final id = nativeEvent.id;
    final mode = _registeredModesById[id];
    // #region agent log
    unawaited(
      _debugLog(
        hypothesisId: 'H2',
        location: 'windows_hotkey_service.dart:251',
        message: 'Hotkey event received from Windows',
        data: <String, Object?>{
          'id': id,
          'mappedMode': mode?.name,
          'registeredIds': _registeredModesById.keys.toList(),
        },
      ),
    );
    // #endregion
    if (mode == null) {
      _lastError = 'Received unknown hotkey id=$id';
      return;
    }
    final now = DateTime.now();
    final lastDispatch = _lastDispatchById[id];
    if (lastDispatch != null &&
        now.difference(lastDispatch) < const Duration(milliseconds: 220)) {
      return;
    }
    _lastDispatchById[id] = now;
    _controller.add(
      HotkeyPressEvent(
        id: id,
        mode: mode,
        timestamp: now,
        triggeredWhileForeground: nativeEvent.runnerWasForeground,
      ),
    );
  }

  HOT_KEY_MODIFIERS _resolveModifierMask(Set<HotkeyModifier> modifiers) {
    var mask = const HOT_KEY_MODIFIERS(0);
    if (modifiers.contains(HotkeyModifier.control)) {
      mask |= MOD_CONTROL;
    }
    if (modifiers.contains(HotkeyModifier.shift)) {
      mask |= MOD_SHIFT;
    }
    if (modifiers.contains(HotkeyModifier.alt)) {
      mask |= MOD_ALT;
    }
    if (modifiers.contains(HotkeyModifier.meta)) {
      mask |= MOD_WIN;
    }
    return mask;
  }

  int? _resolveVirtualKey(String key) {
    final normalized = key.trim().toUpperCase();
    if (normalized.length == 1) {
      final unit = normalized.codeUnitAt(0);
      final isLetter = unit >= 0x41 && unit <= 0x5A;
      final isDigit = unit >= 0x30 && unit <= 0x39;
      if (isLetter || isDigit) {
        return unit;
      }
    }
    return null;
  }

  static bool _defaultIsWindows() {
    return Platform.isWindows;
  }

  static HWND? _defaultWindowHandleResolver() {
    final activeWindow = GetActiveWindow();
    if (activeWindow.address != 0) {
      return activeWindow;
    }

    final className = 'FLUTTER_RUNNER_WIN32_WINDOW'.toPcwstr();
    try {
      final runnerWindowResult = FindWindow(className, null);
      final runnerWindow = runnerWindowResult.value;
      if (runnerWindow.address != 0) {
        return runnerWindow;
      }
    } finally {
      free(className);
    }

    final foregroundWindow = GetForegroundWindow();
    if (foregroundWindow.address == 0) {
      return null;
    }
    final ownerThreadId = GetWindowThreadProcessId(foregroundWindow, null);
    if (ownerThreadId == GetCurrentThreadId()) {
      return foregroundWindow;
    }
    return null;
  }

  Future<void> _debugLog({
    required String hypothesisId,
    required String location,
    required String message,
    required Map<String, Object?> data,
  }) async {
    final payload = <String, Object?>{
      'sessionId': 'ae424f',
      'runId': 'run1',
      'hypothesisId': hypothesisId,
      'location': location,
      'message': message,
      'data': data,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    try {
      File('debug-ae424f.log').writeAsStringSync(
        '${jsonEncode(payload)}\n',
        mode: FileMode.append,
      );
    } catch (_) {}
  }
}

