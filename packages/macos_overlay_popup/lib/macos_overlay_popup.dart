
import 'macos_overlay_popup_platform_interface.dart';

class MacosOverlayPopup {
  Future<String?> getPlatformVersion() {
    return MacosOverlayPopupPlatform.instance.getPlatformVersion();
  }
}
