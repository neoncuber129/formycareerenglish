import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'desktop_hotkey_service.dart';
import 'hotkey_service.dart';
import 'windows_hotkey_service.dart';

class UnsupportedHotkeyService implements HotkeyService {
  const UnsupportedHotkeyService();

  @override
  Stream<HotkeyPressEvent> get onHotkeyPressed =>
      const Stream<HotkeyPressEvent>.empty();

  @override
  HotkeyDiagnostics get diagnostics => const HotkeyDiagnostics(
    isSupported: false,
    isEventBridgeConnected: false,
    registeredIds: <int>[],
    lastError: 'Unsupported platform',
  );

  @override
  Future<bool> registerHotkey(HotkeyBinding binding) async {
    return false;
  }

  @override
  Future<void> unregisterAll() async {}

  @override
  Future<void> unregisterHotkey(int id) async {}
}

final hotkeyServiceProvider = Provider<HotkeyService>((ref) {
  if (Platform.isWindows) {
    final service = WindowsHotkeyService();
    ref.onDispose(service.dispose);
    return service;
  }

  if (Platform.isMacOS || Platform.isLinux) {
    final service = DesktopHotkeyService();
    ref.onDispose(service.dispose);
    return service;
  }

  return const UnsupportedHotkeyService();
});
