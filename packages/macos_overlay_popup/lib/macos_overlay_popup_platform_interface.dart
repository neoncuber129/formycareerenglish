import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'macos_overlay_popup_method_channel.dart';

abstract class MacosOverlayPopupPlatform extends PlatformInterface {
  /// Constructs a MacosOverlayPopupPlatform.
  MacosOverlayPopupPlatform() : super(token: _token);

  static final Object _token = Object();

  static MacosOverlayPopupPlatform _instance = MethodChannelMacosOverlayPopup();

  /// The default instance of [MacosOverlayPopupPlatform] to use.
  ///
  /// Defaults to [MethodChannelMacosOverlayPopup].
  static MacosOverlayPopupPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [MacosOverlayPopupPlatform] when
  /// they register themselves.
  static set instance(MacosOverlayPopupPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
