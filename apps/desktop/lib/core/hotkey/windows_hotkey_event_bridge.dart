import 'package:flutter/services.dart';

class WindowsHotkeyNativeEvent {
  const WindowsHotkeyNativeEvent({
    required this.id,
    required this.runnerWasForeground,
  });

  final int id;
  final bool runnerWasForeground;
}

abstract class WindowsHotkeyEventBridge {
  Stream<WindowsHotkeyNativeEvent> hotkeyIds();
}

class EventChannelWindowsHotkeyEventBridge implements WindowsHotkeyEventBridge {
  static const EventChannel _channel =
      EventChannel('formycareer/hotkey_events');

  @override
  Stream<WindowsHotkeyNativeEvent> hotkeyIds() {
    return _channel
        .receiveBroadcastStream()
        .map<WindowsHotkeyNativeEvent?>((dynamic event) {
          if (event is int) {
            return WindowsHotkeyNativeEvent(
              id: event,
              runnerWasForeground: true,
            );
          }
          if (event is Map && event['id'] is int) {
            return WindowsHotkeyNativeEvent(
              id: event['id'] as int,
              runnerWasForeground: event['runnerWasForeground'] == true,
            );
          }
          return null;
        })
        .where((WindowsHotkeyNativeEvent? event) => event != null)
        .cast<WindowsHotkeyNativeEvent>();
  }
}

