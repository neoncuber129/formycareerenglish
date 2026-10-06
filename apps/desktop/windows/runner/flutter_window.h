#ifndef RUNNER_FLUTTER_WINDOW_H_
#define RUNNER_FLUTTER_WINDOW_H_

#include <flutter/dart_project.h>
#include <flutter/encodable_value.h>
#include <flutter/event_channel.h>
#include <flutter/event_sink.h>
#include <flutter/flutter_view_controller.h>
#include <flutter/method_channel.h>

#include <functional>
#include <memory>
#include <string>
#include <unordered_map>
#include <vector>

#include "win32_window.h"

class PopupFlutterWindow;
class SelectionHostBridge;

// A window that does nothing but host a Flutter view.
class FlutterWindow : public Win32Window {
 public:
  // Creates a new FlutterWindow hosting a Flutter view running |project|.
  explicit FlutterWindow(const flutter::DartProject& project);
  virtual ~FlutterWindow();

  void SetHotkeyPressedCallback(std::function<void(int)> callback);
  void SetPopupWindow(PopupFlutterWindow* popup_window);
  void DispatchPopupSaveRequest(
      flutter::EncodableMap payload,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

 protected:
  // Win32Window:
  bool OnCreate() override;
  void OnDestroy() override;
  LRESULT MessageHandler(HWND window, UINT const message, WPARAM const wparam,
                         LPARAM const lparam) noexcept override;

 private:
  void SetupHotkeyEventChannel();
  void SetupOverlayMethodChannel();
  void SetupPopupBridgeEventChannel();
  void SetupPopupBridgeMethodChannel();
  void SetupSystemTextSelectionEventChannel();
  void PublishHotkeyPressed(int id, bool runner_was_foreground);
  bool SetupKeyboardHook();
  void TearDownKeyboardHook();
  bool HandleLowLevelKeyboardEvent(const KBDLLHOOKSTRUCT* info, WPARAM wparam);
  bool ShouldPublishFromHook(int hotkey_id);
  static LRESULT CALLBACK LowLevelKeyboardProc(int nCode, WPARAM wparam,
                                               LPARAM lparam);
  void ApplySelectionFallbackSettings(bool clipboard_listen, bool drag_send_ctrl_c);
  void TearDownSelectionFallbackHooks();
  void HandleClipboardUpdateNotification();
  void ScheduleDragSelectionCopyCapture();
  bool SetupMouseHook();
  void TearDownMouseHook();
  bool ShouldIgnoreForegroundForSelection(HWND foreground);
  bool IsDeniedForegroundForSelection(HWND foreground);
  bool IsPointOverAppOwnedWindow(POINT screen_pt);
  bool IsLikelyValidSelectionText(const std::string& utf8);
  static std::wstring ToLowerWide(std::wstring value);
  static std::string ToLowerUtf8(std::string value);
  static bool ContainsAnyToken(const std::wstring& text,
                               const std::vector<std::wstring>& tokens);
  static std::wstring ProcessImagePath(HWND hwnd);
  static std::wstring FileNameFromPath(const std::wstring& path);
  void SyncSelectionHostUiaIfSubscribed();
  static LRESULT CALLBACK LowLevelMouseProc(int nCode, WPARAM wparam,
                                            LPARAM lparam);
  flutter::EncodableMap ShowOverlayNearCursor(const flutter::EncodableMap& args);
  flutter::EncodableMap HideOverlayWindow();
  UINT ResolveDpiForPoint(POINT point);

  // The project to run.
  flutter::DartProject project_;

  // The Flutter instance hosted by this window.
  std::unique_ptr<flutter::FlutterViewController> flutter_controller_;
  std::unique_ptr<flutter::EventChannel<flutter::EncodableValue>>
      hotkey_event_channel_;
  std::unique_ptr<flutter::EventSink<flutter::EncodableValue>>
      hotkey_event_sink_;
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>>
      overlay_method_channel_;
  std::unique_ptr<flutter::EventChannel<flutter::EncodableValue>>
      popup_bridge_event_channel_;
  std::unique_ptr<flutter::EventSink<flutter::EncodableValue>>
      popup_bridge_event_sink_;
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>>
      popup_bridge_method_channel_;
  std::unique_ptr<flutter::EventChannel<flutter::EncodableValue>>
      system_text_selection_event_channel_;
  std::unique_ptr<SelectionHostBridge> selection_host_bridge_;

  bool selection_uia_host_enabled_ = true;
  bool selection_clipboard_listen_ = false;
  bool selection_drag_send_ctrl_c_ = false;
  bool selection_strict_filter_enabled_ = true;
  bool clipboard_listener_installed_ = false;
  ULONGLONG suppress_clipboard_notifications_until_tick_ = 0;
  std::string last_clipboard_emit_utf8_;
  ULONGLONG last_clipboard_emit_tick_ = 0;
  POINT drag_anchor_pt_{};
  bool drag_left_button_down_ = false;
  ULONGLONG last_click_up_tick_ = 0;
  POINT last_click_anchor_pt_{};
  bool has_last_click_for_double_ = false;
  bool word_select_on_next_lbuttonup_ = false;
  ULONGLONG last_drag_copy_emit_tick_ = 0;
  HHOOK mouse_hook_ = nullptr;
  static FlutterWindow* s_mouse_hook_instance_;

  std::function<void(int)> hotkey_pressed_callback_;
  bool overlay_active_ = false;
  RECT restore_rect_{};
  bool has_restore_rect_ = false;
  WINDOWPLACEMENT restore_placement_{};
  bool has_restore_placement_ = false;
  LONG_PTR restore_window_style_ = 0;
  LONG_PTR restore_window_ex_style_ = 0;
  bool has_restore_window_styles_ = false;
  HHOOK keyboard_hook_ = nullptr;
  std::unordered_map<int, ULONGLONG> hook_last_publish_tick_by_id_;
  std::unordered_map<
      int, std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>>
      pending_popup_save_results_;
  int next_popup_bridge_request_id_ = 1;
  static FlutterWindow* s_keyboard_hook_instance_;
  PopupFlutterWindow* popup_window_ = nullptr;
};

#endif  // RUNNER_FLUTTER_WINDOW_H_
