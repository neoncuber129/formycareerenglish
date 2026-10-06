import 'dart:async';

enum HotkeyModifier {
  control,
  shift,
  alt,
  meta,
}

enum CaptureMode {
  text,
  image,
}

class HotkeyBinding {
  const HotkeyBinding({
    required this.id,
    required this.key,
    required this.modifiers,
    required this.mode,
  });

  final int id;
  final String key;
  final Set<HotkeyModifier> modifiers;
  final CaptureMode mode;
}

class HotkeyPressEvent {
  const HotkeyPressEvent({
    required this.id,
    required this.mode,
    required this.timestamp,
    this.triggeredWhileForeground = true,
  });

  final int id;
  final CaptureMode mode;
  final DateTime timestamp;
  final bool triggeredWhileForeground;
}

class HotkeyDiagnostics {
  const HotkeyDiagnostics({
    required this.isSupported,
    required this.isEventBridgeConnected,
    required this.registeredIds,
    required this.lastError,
    this.windowHandle,
  });

  final bool isSupported;
  final bool isEventBridgeConnected;
  final List<int> registeredIds;
  final String? lastError;
  final int? windowHandle;
}

abstract class HotkeyService {
  Stream<HotkeyPressEvent> get onHotkeyPressed;

  HotkeyDiagnostics get diagnostics;

  Future<bool> registerHotkey(HotkeyBinding binding);

  Future<void> unregisterHotkey(int id);

  Future<void> unregisterAll();
}

