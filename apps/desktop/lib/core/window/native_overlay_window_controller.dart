import 'dart:io';

import 'package:desktop/features/capture/presentation/capture_popup.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NativeOverlayResult {
  const NativeOverlayResult({
    required this.success,
    required this.fallbackUsed,
    required this.reason,
    required this.contentLeft,
    required this.contentTop,
    required this.scale,
  });

  final bool success;
  final bool fallbackUsed;
  final String reason;
  final double contentLeft;
  final double contentTop;
  final double scale;

  factory NativeOverlayResult.fromMap(Map<Object?, Object?> map) {
    double readDouble(String key, double fallback) {
      final value = map[key];
      if (value is num) {
        return value.toDouble();
      }
      return fallback;
    }

    return NativeOverlayResult(
      success: map['success'] == true,
      fallbackUsed: map['fallbackUsed'] == true,
      reason: (map['reason'] as String?) ?? '',
      contentLeft: readDouble('contentLeft', 10),
      contentTop: readDouble('contentTop', 10),
      scale: readDouble('scale', 1),
    );
  }
}

class DesktopPermissionStatus {
  const DesktopPermissionStatus({
    required this.accessibility,
    required this.screenRecording,
  });

  final bool accessibility;
  final bool screenRecording;

  bool get allGranted => accessibility && screenRecording;

  factory DesktopPermissionStatus.fromMap(Map<Object?, Object?> map) {
    return DesktopPermissionStatus(
      accessibility: map['accessibility'] == true,
      screenRecording: map['screenRecording'] == true,
    );
  }
}

class NativeOverlayWindowController {
  NativeOverlayWindowController({
    MethodChannel? channel,
    Duration responseTimeout = const Duration(milliseconds: 800),
  }) : _channel = channel ?? const MethodChannel('formycareer/overlay_window'),
       _responseTimeout = responseTimeout;

  final MethodChannel _channel;
  final Duration _responseTimeout;
  static final bool _isRunningUnderFlutterTest = Platform.environment
      .containsKey('FLUTTER_TEST');

  Future<NativeOverlayResult> showNearCursor({
    required double popupWidth,
    required double popupHeight,
    required CapturePopupMode mode,
    Rect? selectedRegion,
    double offsetX = 10,
    double offsetY = 10,
    String? nativeLanguage,
    List<String>? sourceLanguages,
    List<String>? tagSuggestions,
    String? selectedText,
    String? sourceApp,
    String? sourceUrl,
  }) async {
    try {
      final timeout = _isRunningUnderFlutterTest
          ? const Duration(milliseconds: 1)
          : (Platform.isMacOS
                ? const Duration(milliseconds: 2500)
                : _responseTimeout);
      final response = await _channel
          .invokeMethod<Object>('showOverlayNearCursor', <String, Object>{
            'popupWidth': popupWidth,
            'popupHeight': popupHeight,
            'mode': mode.name,
            'offsetX': offsetX,
            'offsetY': offsetY,
            if (selectedRegion != null) ...<String, Object>{
              'regionLeft': selectedRegion.left,
              'regionTop': selectedRegion.top,
              'regionWidth': selectedRegion.width,
              'regionHeight': selectedRegion.height,
            },
            if (nativeLanguage != null && nativeLanguage.isNotEmpty)
              'nativeLanguage': nativeLanguage,
            if (sourceLanguages != null && sourceLanguages.isNotEmpty)
              'sourceLanguages': sourceLanguages,
            if (tagSuggestions != null && tagSuggestions.isNotEmpty)
              'tagSuggestions': tagSuggestions,
            if (selectedText != null && selectedText.isNotEmpty)
              'selectedText': selectedText,
            if (sourceApp != null && sourceApp.isNotEmpty)
              'sourceApp': sourceApp,
            if (sourceUrl != null && sourceUrl.isNotEmpty)
              'sourceUrl': sourceUrl,
          })
          .timeout(timeout, onTimeout: () => null);
      if (response is Map<Object?, Object?>) {
        return NativeOverlayResult.fromMap(response);
      }
      if (response == null) {
        return const NativeOverlayResult(
          success: false,
          fallbackUsed: true,
          reason: 'Native overlay call timed out',
          contentLeft: 10,
          contentTop: 10,
          scale: 1,
        );
      }
      return const NativeOverlayResult(
        success: false,
        fallbackUsed: true,
        reason: 'Unexpected native response',
        contentLeft: 10,
        contentTop: 10,
        scale: 1,
      );
    } catch (error) {
      debugPrint('Native overlay show failed: $error');
      return const NativeOverlayResult(
        success: false,
        fallbackUsed: true,
        reason: 'showOverlayNearCursor threw exception',
        contentLeft: 10,
        contentTop: 10,
        scale: 1,
      );
    }
  }

  Future<bool> isRunnerForeground() async {
    if (_isRunningUnderFlutterTest) {
      return true;
    }
    try {
      final response = await _channel.invokeMethod<Object>(
        'isRunnerForeground',
      );
      if (response is bool) {
        return response;
      }
      return true;
    } catch (_) {
      return true;
    }
  }

  Future<Offset?> getCursorPosition() async {
    try {
      final response = await _channel.invokeMethod<Object>('getCursorPosition');
      if (response is Map<Object?, Object?>) {
        final x = response['x'];
        final y = response['y'];
        if (x is num && y is num) {
          return Offset(x.toDouble(), y.toDouble());
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> activateRunner() async {
    if (_isRunningUnderFlutterTest) {
      return;
    }
    try {
      await _channel.invokeMethod<void>('activateRunner');
    } catch (_) {}
  }

  /// Pushes optional Windows-only selection fallbacks to the runner
  /// (`WM_CLIPBOARDUPDATE` listener and low-level mouse → Ctrl+C capture).
  /// When [useUiaSelectionHost] is false, `Formycareer.SelectionHost.exe` is not
  /// started; only clipboard / hook paths emit on the selection EventChannel.
  Future<void> setSelectionCaptureExtras({
    required bool clipboardListen,
    required bool dragSendCtrlC,
    required bool useUiaSelectionHost,
    bool strictAutoCaptureFilter = true,
  }) async {
    if (_isRunningUnderFlutterTest) {
      return;
    }
    try {
      await _channel
          .invokeMethod<void>('setSelectionCaptureExtras', <String, Object>{
            'clipboardListen': clipboardListen,
            'dragSendCtrlC': dragSendCtrlC,
            'useUiaSelectionHost': useUiaSelectionHost,
            'strictAutoCaptureFilter': strictAutoCaptureFilter,
          });
    } catch (error) {
      debugPrint('setSelectionCaptureExtras failed: $error');
    }
  }

  Future<NativeOverlayResult> hide() async {
    try {
      final timeout = _isRunningUnderFlutterTest
          ? const Duration(milliseconds: 1)
          : _responseTimeout;
      final response = await _channel
          .invokeMethod<Object>('hideOverlay')
          .timeout(timeout, onTimeout: () => null);
      if (response is Map<Object?, Object?>) {
        return NativeOverlayResult.fromMap(response);
      }
      return const NativeOverlayResult(
        success: false,
        fallbackUsed: true,
        reason: 'Unexpected native response',
        contentLeft: 10,
        contentTop: 10,
        scale: 1,
      );
    } catch (error) {
      debugPrint('Native overlay hide failed: $error');
      return const NativeOverlayResult(
        success: false,
        fallbackUsed: true,
        reason: 'hideOverlay threw exception',
        contentLeft: 10,
        contentTop: 10,
        scale: 1,
      );
    }
  }

  Future<DesktopPermissionStatus> getPermissionStatus() async {
    try {
      final response = await _channel.invokeMethod<Object>('getPermissionStatus');
      if (response is Map<Object?, Object?>) {
        return DesktopPermissionStatus.fromMap(response);
      }
    } catch (_) {}
    return const DesktopPermissionStatus(
      accessibility: false,
      screenRecording: false,
    );
  }

  Future<DesktopPermissionStatus> requestMissingPermissions() async {
    try {
      final response = await _channel.invokeMethod<Object>(
        'requestMissingPermissions',
      );
      if (response is Map<Object?, Object?>) {
        return DesktopPermissionStatus.fromMap(response);
      }
    } catch (_) {}
    return const DesktopPermissionStatus(
      accessibility: false,
      screenRecording: false,
    );
  }
}

final nativeOverlayWindowControllerProvider =
    Provider<NativeOverlayWindowController>((ref) {
      return NativeOverlayWindowController();
    });
