import 'dart:io';

import 'package:flutter/services.dart';
import 'package:hotkey_manager/hotkey_manager.dart';

import '../logging/logger_service.dart';

typedef PlatformSupportChecker = bool Function();

abstract class GlobalHotkeyService {
  Future<bool> registerCaptureHotkey({
    required VoidCallback onTriggered,
  });

  Future<void> unregisterAll();
}

abstract class HotkeyManagerClient {
  Future<void> register({
    required HotKey hotKey,
    required void Function(HotKey hotKey) onKeyDown,
  });

  Future<void> unregisterAll();
}

class HotkeyManagerClientImpl implements HotkeyManagerClient {
  const HotkeyManagerClientImpl();

  @override
  Future<void> register({
    required HotKey hotKey,
    required void Function(HotKey hotKey) onKeyDown,
  }) {
    return hotKeyManager.register(hotKey, keyDownHandler: onKeyDown);
  }

  @override
  Future<void> unregisterAll() {
    return hotKeyManager.unregisterAll();
  }
}

class DesktopGlobalHotkeyService implements GlobalHotkeyService {
  DesktopGlobalHotkeyService({
    required HotkeyManagerClient manager,
    PlatformSupportChecker? isSupportedPlatform,
  })  : _manager = manager,
        _isSupportedPlatform = isSupportedPlatform ?? _defaultSupportedPlatform;

  final HotkeyManagerClient _manager;
  final PlatformSupportChecker _isSupportedPlatform;

  static final HotKey _defaultCaptureHotKey = HotKey(
    key: PhysicalKeyboardKey.keyD,
    modifiers: <HotKeyModifier>[
      HotKeyModifier.control,
      HotKeyModifier.shift,
    ],
    scope: HotKeyScope.system,
  );

  @override
  Future<bool> registerCaptureHotkey({
    required VoidCallback onTriggered,
  }) async {
    if (!_isSupportedPlatform()) {
      LoggerService.logSync(
        source: 'desktop_hotkey',
        stage: 'register_unsupported_platform',
        success: false,
      );
      return false;
    }

    try {
      await _manager.register(
        hotKey: _defaultCaptureHotKey,
        onKeyDown: (_) => onTriggered(),
      );
      LoggerService.logSync(
        source: 'desktop_hotkey',
        stage: 'register_done',
        success: true,
      );
      return true;
    } catch (error) {
      LoggerService.logError(
        source: 'desktop_hotkey',
        action: 'registerCaptureHotkey',
        error: error,
      );
      return false;
    }
  }

  @override
  Future<void> unregisterAll() async {
    try {
      await _manager.unregisterAll();
      LoggerService.logSync(
        source: 'desktop_hotkey',
        stage: 'unregister_done',
        success: true,
      );
    } catch (error) {
      LoggerService.logError(
        source: 'desktop_hotkey',
        action: 'unregisterAll',
        error: error,
      );
    }
  }

  static bool _defaultSupportedPlatform() {
    return Platform.isWindows || Platform.isMacOS || Platform.isLinux;
  }
}
