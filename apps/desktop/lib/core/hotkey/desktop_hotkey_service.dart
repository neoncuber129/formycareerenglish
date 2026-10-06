import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:hotkey_manager/hotkey_manager.dart';

import '../logging/logger_service.dart';
import 'hotkey_service.dart';

class DesktopHotkeyService implements HotkeyService {
  final StreamController<HotkeyPressEvent> _controller =
      StreamController<HotkeyPressEvent>.broadcast();
  final Map<int, HotkeyBinding> _bindingsById = <int, HotkeyBinding>{};
  final Map<int, HotKey> _hotkeysById = <int, HotKey>{};
  String? _lastError;

  @override
  Stream<HotkeyPressEvent> get onHotkeyPressed => _controller.stream;

  @override
  HotkeyDiagnostics get diagnostics => HotkeyDiagnostics(
    isSupported: Platform.isWindows || Platform.isMacOS || Platform.isLinux,
    isEventBridgeConnected: true,
    registeredIds: _bindingsById.keys.toList()..sort(),
    lastError: _lastError,
  );

  @override
  Future<bool> registerHotkey(HotkeyBinding binding) async {
    final existing = _hotkeysById[binding.id];
    if (existing != null) {
      await hotKeyManager.unregister(existing);
      _bindingsById.remove(binding.id);
      _hotkeysById.remove(binding.id);
    }
    final key = _logicalKeyFromBinding(binding.key);
    if (key == null) {
      _lastError = 'Unsupported hotkey key "${binding.key}"';
      return false;
    }
    final hotKey = HotKey(
      key: key,
      modifiers: _mapModifiers(binding.modifiers),
      scope: HotKeyScope.system,
    );
    try {
      await hotKeyManager.register(
        hotKey,
        keyDownHandler: (_) {
          _controller.add(
            HotkeyPressEvent(
              id: binding.id,
              mode: binding.mode,
              timestamp: DateTime.now(),
            ),
          );
        },
      );
      _bindingsById[binding.id] = binding;
      _hotkeysById[binding.id] = hotKey;
      _lastError = null;
      return true;
    } catch (error) {
      _lastError = '$error';
      LoggerService.logError(
        source: 'desktop_hotkey',
        action: 'registerHotkey',
        error: error,
      );
      return false;
    }
  }

  @override
  Future<void> unregisterHotkey(int id) async {
    final hotKey = _hotkeysById.remove(id);
    _bindingsById.remove(id);
    if (hotKey == null) {
      return;
    }
    try {
      await hotKeyManager.unregister(hotKey);
    } catch (error) {
      _lastError = '$error';
    }
  }

  @override
  Future<void> unregisterAll() async {
    try {
      await hotKeyManager.unregisterAll();
      _bindingsById.clear();
      _hotkeysById.clear();
      _lastError = null;
    } catch (error) {
      _lastError = '$error';
    }
  }

  void dispose() {
    unawaited(unregisterAll());
    unawaited(_controller.close());
  }

  PhysicalKeyboardKey? _logicalKeyFromBinding(String raw) {
    final key = raw.trim().toUpperCase();
    return switch (key) {
      'A' => PhysicalKeyboardKey.keyA,
      'B' => PhysicalKeyboardKey.keyB,
      'C' => PhysicalKeyboardKey.keyC,
      'D' => PhysicalKeyboardKey.keyD,
      'E' => PhysicalKeyboardKey.keyE,
      'F' => PhysicalKeyboardKey.keyF,
      'G' => PhysicalKeyboardKey.keyG,
      'H' => PhysicalKeyboardKey.keyH,
      'I' => PhysicalKeyboardKey.keyI,
      'J' => PhysicalKeyboardKey.keyJ,
      'K' => PhysicalKeyboardKey.keyK,
      'L' => PhysicalKeyboardKey.keyL,
      'M' => PhysicalKeyboardKey.keyM,
      'N' => PhysicalKeyboardKey.keyN,
      'O' => PhysicalKeyboardKey.keyO,
      'P' => PhysicalKeyboardKey.keyP,
      'Q' => PhysicalKeyboardKey.keyQ,
      'R' => PhysicalKeyboardKey.keyR,
      'S' => PhysicalKeyboardKey.keyS,
      'T' => PhysicalKeyboardKey.keyT,
      'U' => PhysicalKeyboardKey.keyU,
      'V' => PhysicalKeyboardKey.keyV,
      'W' => PhysicalKeyboardKey.keyW,
      'X' => PhysicalKeyboardKey.keyX,
      'Y' => PhysicalKeyboardKey.keyY,
      'Z' => PhysicalKeyboardKey.keyZ,
      '0' => PhysicalKeyboardKey.digit0,
      '1' => PhysicalKeyboardKey.digit1,
      '2' => PhysicalKeyboardKey.digit2,
      '3' => PhysicalKeyboardKey.digit3,
      '4' => PhysicalKeyboardKey.digit4,
      '5' => PhysicalKeyboardKey.digit5,
      '6' => PhysicalKeyboardKey.digit6,
      '7' => PhysicalKeyboardKey.digit7,
      '8' => PhysicalKeyboardKey.digit8,
      '9' => PhysicalKeyboardKey.digit9,
      _ => null,
    };
  }

  List<HotKeyModifier> _mapModifiers(Set<HotkeyModifier> modifiers) {
    return modifiers
        .map(
          (modifier) => switch (modifier) {
            HotkeyModifier.control => HotKeyModifier.control,
            HotkeyModifier.shift => HotKeyModifier.shift,
            HotkeyModifier.alt => HotKeyModifier.alt,
            HotkeyModifier.meta => HotKeyModifier.meta,
          },
        )
        .toList(growable: false);
  }
}
