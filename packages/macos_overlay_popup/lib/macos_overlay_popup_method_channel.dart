import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'macos_overlay_popup_platform_interface.dart';

/// An implementation of [MacosOverlayPopupPlatform] that uses method channels.
class MethodChannelMacosOverlayPopup extends MacosOverlayPopupPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('macos_overlay_popup');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>(
      'getPlatformVersion',
    );
    return version;
  }
}
