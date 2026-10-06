#ifndef RUNNER_POPUP_FLUTTER_WINDOW_H_
#define RUNNER_POPUP_FLUTTER_WINDOW_H_

#include <optional>
#include <string>
#include <vector>

#include <flutter/dart_project.h>
#include <flutter/encodable_value.h>
#include <flutter/event_channel.h>
#include <flutter/event_sink.h>
#include <flutter/flutter_view_controller.h>
#include <flutter/method_channel.h>

#include "win32_window.h"

class FlutterWindow;

class PopupFlutterWindow : public Win32Window {
 public:
  explicit PopupFlutterWindow(const flutter::DartProject& project);
  virtual ~PopupFlutterWindow();
  void SetMainWindow(FlutterWindow* main_window);

  flutter::EncodableMap ShowPopup(const std::string& mode,
                                  POINT cursor,
                                  const std::optional<RECT>& region,
                                  double popup_width,
                                  double popup_height,
                                  double offset_x,
                                  double offset_y,
                                  const std::string& selected_text = "",
                                  const std::string& source_app = "",
                                  const std::string& native_language = "",
                                  const std::vector<std::string>& source_languages = {},
                                  const std::vector<std::string>& tag_suggestions = {});
  flutter::EncodableMap HidePopupWindow();
  flutter::EncodableMap SetPopupFrameSize(double popup_width,
                                          double popup_height);

 protected:
  bool OnCreate() override;
  void OnDestroy() override;
  LRESULT MessageHandler(HWND window, UINT const message, WPARAM const wparam,
                         LPARAM const lparam) noexcept override;

 private:
  void SetupPopupEventChannel();
  void SetupPopupControlMethodChannel();
  void InstallOutsideClickHook();
  void UninstallOutsideClickHook();
  static LRESULT CALLBACK LowLevelMouseProc(int nCode, WPARAM wParam,
                                            LPARAM lParam);
  UINT ResolveDpiForPoint(POINT point);

  flutter::DartProject project_;
  std::unique_ptr<flutter::FlutterViewController> flutter_controller_;
  std::unique_ptr<flutter::EventChannel<flutter::EncodableValue>>
      popup_event_channel_;
  std::unique_ptr<flutter::EventSink<flutter::EncodableValue>>
      popup_event_sink_;
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>>
      popup_control_method_channel_;
  int next_request_id_ = 1;
  FlutterWindow* main_window_ = nullptr;
  HHOOK outside_click_hook_ = nullptr;
  bool popup_visible_ = false;
  static PopupFlutterWindow* hook_owner_;
};

#endif  // RUNNER_POPUP_FLUTTER_WINDOW_H_
