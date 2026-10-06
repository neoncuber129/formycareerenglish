import 'dart:async';
import 'dart:ffi';

import 'package:desktop/core/hotkey/hotkey_service.dart';
import 'package:desktop/core/hotkey/windows_hotkey_event_bridge.dart';
import 'package:desktop/core/hotkey/windows_hotkey_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:win32/win32.dart';

class FakeWindowsHotkeyEventBridge implements WindowsHotkeyEventBridge {
  final StreamController<WindowsHotkeyNativeEvent> controller =
      StreamController<WindowsHotkeyNativeEvent>.broadcast();

  @override
  Stream<WindowsHotkeyNativeEvent> hotkeyIds() => controller.stream;
}

class FakeWin32HotkeyApi implements Win32HotkeyApi {
  Win32Result<bool> registerResult =
      const Win32Result<bool>(value: true, error: ERROR_SUCCESS);
  Win32Result<bool> unregisterResult =
      const Win32Result<bool>(value: true, error: ERROR_SUCCESS);

  int registerCallCount = 0;
  int unregisterCallCount = 0;
  int? lastRegisteredId;
  HWND? lastWindowHandle;

  @override
  Win32Result<bool> registerHotKey({
    required HWND? windowHandle,
    required int id,
    required HOT_KEY_MODIFIERS modifiers,
    required int virtualKey,
  }) {
    registerCallCount += 1;
    lastRegisteredId = id;
    lastWindowHandle = windowHandle;
    return registerResult;
  }

  @override
  Win32Result<bool> unregisterHotKey({
    required HWND? windowHandle,
    required int id,
  }) {
    unregisterCallCount += 1;
    lastWindowHandle = windowHandle;
    return unregisterResult;
  }
}

void main() {
  group('WindowsHotkeyService', () {
    test('returns false when registerHotKey fails', () async {
      final bridge = FakeWindowsHotkeyEventBridge();
      final api = FakeWin32HotkeyApi()
        ..registerResult =
            const Win32Result<bool>(value: false, error: WIN32_ERROR(1));
      final service = WindowsHotkeyService(
        eventBridge: bridge,
        win32Api: api,
        isWindows: () => true,
        windowHandleResolver: () => null,
      );

      final result = await service.registerHotkey(
        const HotkeyBinding(
          id: 1001,
          key: 'D',
          modifiers: <HotkeyModifier>{HotkeyModifier.control},
          mode: CaptureMode.text,
        ),
      );

      expect(result, isFalse);
      expect(api.registerCallCount, 1);

      service.dispose();
      await bridge.controller.close();
    });

    test('blocks duplicate registration for same id', () async {
      final bridge = FakeWindowsHotkeyEventBridge();
      final api = FakeWin32HotkeyApi();
      final service = WindowsHotkeyService(
        eventBridge: bridge,
        win32Api: api,
        isWindows: () => true,
        windowHandleResolver: () => null,
      );

      final first = await service.registerHotkey(
        const HotkeyBinding(
          id: 1001,
          key: 'D',
          modifiers: <HotkeyModifier>{
            HotkeyModifier.control,
            HotkeyModifier.shift,
          },
          mode: CaptureMode.text,
        ),
      );
      final second = await service.registerHotkey(
        const HotkeyBinding(
          id: 1001,
          key: 'D',
          modifiers: <HotkeyModifier>{
            HotkeyModifier.control,
            HotkeyModifier.shift,
          },
          mode: CaptureMode.text,
        ),
      );

      expect(first, isTrue);
      expect(second, isFalse);
      expect(api.registerCallCount, 1);

      service.dispose();
      await bridge.controller.close();
    });

    test('emits event only for registered id', () async {
      final bridge = FakeWindowsHotkeyEventBridge();
      final api = FakeWin32HotkeyApi();
      final service = WindowsHotkeyService(
        eventBridge: bridge,
        win32Api: api,
        isWindows: () => true,
        windowHandleResolver: () => null,
      );

      await service.registerHotkey(
        const HotkeyBinding(
          id: 1001,
          key: 'D',
          modifiers: <HotkeyModifier>{HotkeyModifier.control},
          mode: CaptureMode.text,
        ),
      );

      final events = <HotkeyPressEvent>[];
      final sub = service.onHotkeyPressed.listen(events.add);

      bridge.controller.add(
        const WindowsHotkeyNativeEvent(id: 2002, runnerWasForeground: true),
      );
      bridge.controller.add(
        const WindowsHotkeyNativeEvent(id: 1001, runnerWasForeground: true),
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(events, hasLength(1));
      expect(events.single.id, 1001);
      expect(events.single.mode, CaptureMode.text);

      await sub.cancel();
      service.dispose();
      await bridge.controller.close();
    });

    test('maps multiple registered ids to their capture modes', () async {
      final bridge = FakeWindowsHotkeyEventBridge();
      final api = FakeWin32HotkeyApi();
      final service = WindowsHotkeyService(
        eventBridge: bridge,
        win32Api: api,
        isWindows: () => true,
        windowHandleResolver: () => null,
      );

      await service.registerHotkey(
        const HotkeyBinding(
          id: 1001,
          key: 'D',
          modifiers: <HotkeyModifier>{HotkeyModifier.control},
          mode: CaptureMode.text,
        ),
      );
      await service.registerHotkey(
        const HotkeyBinding(
          id: 1002,
          key: 'X',
          modifiers: <HotkeyModifier>{HotkeyModifier.control},
          mode: CaptureMode.image,
        ),
      );

      final events = <HotkeyPressEvent>[];
      final sub = service.onHotkeyPressed.listen(events.add);

      bridge.controller.add(
        const WindowsHotkeyNativeEvent(id: 1001, runnerWasForeground: true),
      );
      bridge.controller.add(
        const WindowsHotkeyNativeEvent(id: 1002, runnerWasForeground: true),
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(events, hasLength(2));
      expect(events[0].mode, CaptureMode.text);
      expect(events[1].mode, CaptureMode.image);

      await sub.cancel();
      service.dispose();
      await bridge.controller.close();
    });

    test('unregisterAll delegates once per registered id', () async {
      final bridge = FakeWindowsHotkeyEventBridge();
      final api = FakeWin32HotkeyApi();
      final service = WindowsHotkeyService(
        eventBridge: bridge,
        win32Api: api,
        isWindows: () => true,
        windowHandleResolver: () => null,
      );

      await service.registerHotkey(
        const HotkeyBinding(
          id: 1001,
          key: 'D',
          modifiers: <HotkeyModifier>{HotkeyModifier.control},
          mode: CaptureMode.text,
        ),
      );
      await service.registerHotkey(
        const HotkeyBinding(
          id: 1002,
          key: 'A',
          modifiers: <HotkeyModifier>{HotkeyModifier.control},
          mode: CaptureMode.image,
        ),
      );

      await service.unregisterAll();

      expect(api.unregisterCallCount, 2);

      service.dispose();
      await bridge.controller.close();
    });

    test('exposes diagnostics with window handle and registered ids', () async {
      final bridge = FakeWindowsHotkeyEventBridge();
      final api = FakeWin32HotkeyApi();
      final service = WindowsHotkeyService(
        eventBridge: bridge,
        win32Api: api,
        isWindows: () => true,
        windowHandleResolver: () => HWND(Pointer<NativeType>.fromAddress(12345)),
      );

      await service.registerHotkey(
        const HotkeyBinding(
          id: 1001,
          key: 'D',
          modifiers: <HotkeyModifier>{HotkeyModifier.control},
          mode: CaptureMode.text,
        ),
      );

      final diagnostics = service.diagnostics;
      expect(diagnostics.windowHandle, 12345);
      expect(diagnostics.registeredIds, <int>[1001]);
      expect(diagnostics.lastError, isNull);
      expect(diagnostics.isEventBridgeConnected, isTrue);

      service.dispose();
      await bridge.controller.close();
    });
  });
}
