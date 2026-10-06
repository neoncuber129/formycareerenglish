import 'package:flutter_test/flutter_test.dart';
import 'package:macos_overlay_popup/macos_overlay_popup.dart';
import 'package:macos_overlay_popup/macos_overlay_popup_platform_interface.dart';
import 'package:macos_overlay_popup/macos_overlay_popup_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockMacosOverlayPopupPlatform
    with MockPlatformInterfaceMixin
    implements MacosOverlayPopupPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final MacosOverlayPopupPlatform initialPlatform = MacosOverlayPopupPlatform.instance;

  test('$MethodChannelMacosOverlayPopup is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelMacosOverlayPopup>());
  });

  test('getPlatformVersion', () async {
    MacosOverlayPopup macosOverlayPopupPlugin = MacosOverlayPopup();
    MockMacosOverlayPopupPlatform fakePlatform = MockMacosOverlayPopupPlatform();
    MacosOverlayPopupPlatform.instance = fakePlatform;

    expect(await macosOverlayPopupPlugin.getPlatformVersion(), '42');
  });
}
