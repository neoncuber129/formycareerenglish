import 'package:desktop/core/hotkey/global_hotkey_service.dart';
import 'package:flutter/services.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeHotkeyManagerClient implements HotkeyManagerClient {
  bool throwOnRegister = false;
  bool unregistered = false;
  HotKey? registeredHotKey;
  void Function(HotKey hotKey)? keyDownHandler;

  @override
  Future<void> register({
    required HotKey hotKey,
    required void Function(HotKey hotKey) onKeyDown,
  }) async {
    if (throwOnRegister) {
      throw Exception('register failed');
    }
    registeredHotKey = hotKey;
    keyDownHandler = onKeyDown;
  }

  @override
  Future<void> unregisterAll() async {
    unregistered = true;
  }
}

void main() {
  group('DesktopGlobalHotkeyService', () {
    test('registers default hotkey and triggers callback', () async {
      final manager = FakeHotkeyManagerClient();
      var triggered = false;
      final service = DesktopGlobalHotkeyService(
        manager: manager,
        isSupportedPlatform: () => true,
      );

      final success = await service.registerCaptureHotkey(
        onTriggered: () => triggered = true,
      );
      manager.keyDownHandler?.call(
        HotKey(
          key: PhysicalKeyboardKey.keyD,
          modifiers: <HotKeyModifier>[HotKeyModifier.control],
        ),
      );

      expect(success, isTrue);
      expect(manager.registeredHotKey, isNotNull);
      expect(manager.registeredHotKey!.key, PhysicalKeyboardKey.keyD);
      expect(
        manager.registeredHotKey!.modifiers,
        containsAll(<HotKeyModifier>[
          HotKeyModifier.control,
          HotKeyModifier.shift,
        ]),
      );
      expect(manager.registeredHotKey!.scope, HotKeyScope.system);
      expect(triggered, isTrue);
    });

    test('returns false when platform is unsupported', () async {
      final manager = FakeHotkeyManagerClient();
      final service = DesktopGlobalHotkeyService(
        manager: manager,
        isSupportedPlatform: () => false,
      );

      final success = await service.registerCaptureHotkey(onTriggered: () {});

      expect(success, isFalse);
      expect(manager.registeredHotKey, isNull);
    });

    test('returns false when register throws', () async {
      final manager = FakeHotkeyManagerClient()..throwOnRegister = true;
      final service = DesktopGlobalHotkeyService(
        manager: manager,
        isSupportedPlatform: () => true,
      );

      final success = await service.registerCaptureHotkey(onTriggered: () {});

      expect(success, isFalse);
    });

    test('unregisterAll delegates to manager', () async {
      final manager = FakeHotkeyManagerClient();
      final service = DesktopGlobalHotkeyService(
        manager: manager,
        isSupportedPlatform: () => true,
      );

      await service.unregisterAll();

      expect(manager.unregistered, isTrue);
    });
  });
}
