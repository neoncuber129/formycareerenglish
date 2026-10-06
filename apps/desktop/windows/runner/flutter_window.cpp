#include "flutter_window.h"

#include <algorithm>
#include <cctype>
#include <cstdint>
#include <cwctype>
#include <optional>
#include <thread>
#include <utility>
#include <vector>

#include "popup_flutter_window.h"
#include "selection_host_bridge.h"
#include "region_selector_window.h"
#include "flutter/generated_plugin_registrant.h"
#include <flutter/event_stream_handler_functions.h>
#include <flutter/standard_method_codec.h>

namespace {
constexpr int kTextCaptureHotkeyId = 1001;
constexpr int kImageCaptureHotkeyId = 1002;
constexpr ULONGLONG kHookDebounceMs = 220;
constexpr LONG kStrictDragThresholdPx = 26;
constexpr int kMainWindowMinWidth = 1280;
constexpr int kMainWindowMinHeight = 760;

double ReadDoubleArg(const flutter::EncodableMap& args,
                     const char* key,
                     double fallback) {
  auto it = args.find(flutter::EncodableValue(key));
  if (it == args.end()) {
    return fallback;
  }
  if (const auto* value = std::get_if<double>(&it->second)) {
    return *value;
  }
  if (const auto* value = std::get_if<int32_t>(&it->second)) {
    return static_cast<double>(*value);
  }
  if (const auto* value = std::get_if<int64_t>(&it->second)) {
    return static_cast<double>(*value);
  }
  return fallback;
}

std::string ReadStringArg(const flutter::EncodableMap& args,
                          const char* key) {
  auto it = args.find(flutter::EncodableValue(key));
  if (it == args.end()) {
    return std::string();
  }
  if (const auto* value = std::get_if<std::string>(&it->second)) {
    return *value;
  }
  return std::string();
}

bool ReadBoolArg(const flutter::EncodableMap& args,
                 const char* key,
                 bool fallback) {
  auto it = args.find(flutter::EncodableValue(key));
  if (it == args.end()) {
    return fallback;
  }
  if (const auto* value = std::get_if<bool>(&it->second)) {
    return *value;
  }
  if (const auto* iv = std::get_if<int32_t>(&it->second)) {
    return *iv != 0;
  }
  if (const auto* il = std::get_if<int64_t>(&it->second)) {
    return *il != 0;
  }
  return fallback;
}

std::vector<std::string> ReadStringListArg(const flutter::EncodableMap& args,
                                           const char* key) {
  std::vector<std::string> result;
  auto it = args.find(flutter::EncodableValue(key));
  if (it == args.end()) {
    return result;
  }
  if (const auto* list = std::get_if<flutter::EncodableList>(&it->second)) {
    result.reserve(list->size());
    for (const auto& entry : *list) {
      if (const auto* s = std::get_if<std::string>(&entry)) {
        if (!s->empty()) {
          result.push_back(*s);
        }
      }
    }
  }
  return result;
}

std::wstring ReadUnicodeTextFromClipboard() {
  std::wstring result;
  if (!OpenClipboard(nullptr)) {
    return result;
  }
  HANDLE handle = GetClipboardData(CF_UNICODETEXT);
  if (handle != nullptr) {
    auto* text = static_cast<wchar_t*>(GlobalLock(handle));
    if (text != nullptr) {
      result.assign(text);
      GlobalUnlock(handle);
    }
  }
  CloseClipboard();
  return result;
}

void WriteUnicodeTextToClipboard(const std::wstring& text) {
  if (!OpenClipboard(nullptr)) {
    return;
  }
  EmptyClipboard();
  const size_t bytes = (text.size() + 1) * sizeof(wchar_t);
  HGLOBAL buffer = GlobalAlloc(GMEM_MOVEABLE, bytes);
  if (buffer != nullptr) {
    auto* dst = static_cast<wchar_t*>(GlobalLock(buffer));
    if (dst != nullptr) {
      memcpy(dst, text.c_str(), bytes);
      GlobalUnlock(buffer);
      SetClipboardData(CF_UNICODETEXT, buffer);
    } else {
      GlobalFree(buffer);
    }
  }
  CloseClipboard();
}

void SendKeyTap(WORD vk, bool keyup) {
  INPUT input{};
  input.type = INPUT_KEYBOARD;
  input.ki.wVk = vk;
  input.ki.dwFlags = keyup ? KEYEVENTF_KEYUP : 0;
  SendInput(1, &input, sizeof(INPUT));
}

std::string WideToUtf8(const std::wstring& input) {
  if (input.empty()) {
    return std::string();
  }
  const int size_needed = WideCharToMultiByte(
      CP_UTF8, 0, input.data(), static_cast<int>(input.size()), nullptr, 0,
      nullptr, nullptr);
  if (size_needed <= 0) {
    return std::string();
  }
  std::string output(size_needed, '\0');
  WideCharToMultiByte(CP_UTF8, 0, input.data(),
                       static_cast<int>(input.size()), output.data(),
                       size_needed, nullptr, nullptr);
  return output;
}

std::wstring Utf8ToWide(const std::string& input) {
  if (input.empty()) {
    return std::wstring();
  }
  const int size_needed =
      MultiByteToWideChar(CP_UTF8, 0, input.data(),
                          static_cast<int>(input.size()), nullptr, 0);
  if (size_needed <= 0) {
    return std::wstring();
  }
  std::wstring output(size_needed, L'\0');
  MultiByteToWideChar(CP_UTF8, 0, input.data(), static_cast<int>(input.size()),
                      output.data(), size_needed);
  return output;
}

// Captures user-selected text from the foreground application by simulating
// Ctrl+C and reading the clipboard. Preserves existing clipboard contents.
std::string CaptureSelectedTextFromForegroundApp() {
  const std::wstring previous_clipboard = ReadUnicodeTextFromClipboard();
  const std::wstring sentinel = L"__fmc_sentinel__";
  WriteUnicodeTextToClipboard(sentinel);

  // Release any modifiers the user may still be holding from the hotkey so the
  // simulated Ctrl+C isn't interpreted as Ctrl+Shift+C by the target app.
  SendKeyTap(VK_SHIFT, /*keyup=*/true);
  SendKeyTap(VK_LCONTROL, /*keyup=*/true);
  SendKeyTap(VK_RCONTROL, /*keyup=*/true);
  SendKeyTap(VK_MENU, /*keyup=*/true);

  INPUT inputs[4]{};
  inputs[0].type = INPUT_KEYBOARD;
  inputs[0].ki.wVk = VK_CONTROL;
  inputs[1].type = INPUT_KEYBOARD;
  inputs[1].ki.wVk = 'C';
  inputs[2].type = INPUT_KEYBOARD;
  inputs[2].ki.wVk = 'C';
  inputs[2].ki.dwFlags = KEYEVENTF_KEYUP;
  inputs[3].type = INPUT_KEYBOARD;
  inputs[3].ki.wVk = VK_CONTROL;
  inputs[3].ki.dwFlags = KEYEVENTF_KEYUP;
  SendInput(4, inputs, sizeof(INPUT));

  // Poll the clipboard for up to ~240 ms waiting for the target app to
  // actually process the copy command.
  std::wstring captured;
  for (int attempt = 0; attempt < 12; ++attempt) {
    Sleep(20);
    captured = ReadUnicodeTextFromClipboard();
    if (!captured.empty() && captured != sentinel) {
      break;
    }
  }

  WriteUnicodeTextToClipboard(previous_clipboard);

  if (captured == sentinel) {
    captured.clear();
  }
  return WideToUtf8(captured);
}

}  // namespace

FlutterWindow* FlutterWindow::s_keyboard_hook_instance_ = nullptr;
FlutterWindow* FlutterWindow::s_mouse_hook_instance_ = nullptr;

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

void FlutterWindow::SetHotkeyPressedCallback(std::function<void(int)> callback) {
  hotkey_pressed_callback_ = std::move(callback);
}

void FlutterWindow::SetPopupWindow(PopupFlutterWindow* popup_window) {
  popup_window_ = popup_window;
}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  RECT frame = GetClientArea();

  // The size here must match the window dimensions to avoid unnecessary surface
  // creation / destruction in the startup path.
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  // Ensure that basic setup of the controller was successful.
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }
  RegisterPlugins(flutter_controller_->engine());
  SetupHotkeyEventChannel();
  SetupOverlayMethodChannel();
  SetupPopupBridgeEventChannel();
  SetupPopupBridgeMethodChannel();
  SetupSystemTextSelectionEventChannel();
  SetupKeyboardHook();
  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  flutter_controller_->engine()->SetNextFrameCallback([&]() {
    this->Show();
  });

  // Flutter can complete the first frame before the "show window" callback is
  // registered. The following call ensures a frame is pending to ensure the
  // window is shown. It is a no-op if the first frame hasn't completed yet.
  flutter_controller_->ForceRedraw();

  ApplySelectionFallbackSettings(selection_clipboard_listen_,
                                 selection_drag_send_ctrl_c_);

  return true;
}

void FlutterWindow::SetupHotkeyEventChannel() {
  hotkey_event_channel_ =
      std::make_unique<flutter::EventChannel<flutter::EncodableValue>>(
          flutter_controller_->engine()->messenger(),
          "formycareer/hotkey_events",
          &flutter::StandardMethodCodec::GetInstance());

  auto handler =
      std::make_unique<
          flutter::StreamHandlerFunctions<flutter::EncodableValue>>(
          [this](
              const flutter::EncodableValue*,
              std::unique_ptr<flutter::EventSink<flutter::EncodableValue>>
                  &&events)
              -> std::unique_ptr<
                  flutter::StreamHandlerError<flutter::EncodableValue>> {
            hotkey_event_sink_ = std::move(events);
            return nullptr;
          },
          [this](const flutter::EncodableValue*)
              -> std::unique_ptr<
                  flutter::StreamHandlerError<flutter::EncodableValue>> {
            hotkey_event_sink_.reset();
            return nullptr;
          });

  hotkey_event_channel_->SetStreamHandler(std::move(handler));
}

void FlutterWindow::SetupOverlayMethodChannel() {
  overlay_method_channel_ =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          flutter_controller_->engine()->messenger(),
          "formycareer/overlay_window",
          &flutter::StandardMethodCodec::GetInstance());

  overlay_method_channel_->SetMethodCallHandler(
      [this](const flutter::MethodCall<flutter::EncodableValue>& call,
             std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>
                 result) {
        const auto* args = std::get_if<flutter::EncodableMap>(call.arguments());
        if (call.method_name() == "showOverlayNearCursor") {
          flutter::EncodableMap payload = ShowOverlayNearCursor(
              args == nullptr ? flutter::EncodableMap{} : *args);
          result->Success(flutter::EncodableValue(payload));
          return;
        }
        if (call.method_name() == "hideOverlay") {
          flutter::EncodableMap payload = HideOverlayWindow();
          result->Success(flutter::EncodableValue(payload));
          return;
        }
        if (call.method_name() == "isRunnerForeground") {
          const HWND hwnd = GetHandle();
          const bool is_foreground =
              hwnd != nullptr && GetForegroundWindow() == hwnd;
          result->Success(flutter::EncodableValue(is_foreground));
          return;
        }
        if (call.method_name() == "getCursorPosition") {
          POINT cursor{};
          flutter::EncodableMap payload;
          if (GetCursorPos(&cursor)) {
            payload[flutter::EncodableValue("x")] =
                flutter::EncodableValue(static_cast<int32_t>(cursor.x));
            payload[flutter::EncodableValue("y")] =
                flutter::EncodableValue(static_cast<int32_t>(cursor.y));
          }
          result->Success(flutter::EncodableValue(payload));
          return;
        }
        if (call.method_name() == "setSelectionCaptureExtras") {
          if (args == nullptr) {
            result->Error("bad_args", "Expected map");
            return;
          }
          const bool clip = ReadBoolArg(*args, "clipboardListen", false);
          const bool drag = ReadBoolArg(*args, "dragSendCtrlC", false);
          selection_strict_filter_enabled_ =
              ReadBoolArg(*args, "strictAutoCaptureFilter", true);
          selection_uia_host_enabled_ =
              ReadBoolArg(*args, "useUiaSelectionHost", true);
          ApplySelectionFallbackSettings(clip, drag);
          SyncSelectionHostUiaIfSubscribed();
          result->Success();
          return;
        }
        result->NotImplemented();
      });
}

void FlutterWindow::SetupPopupBridgeEventChannel() {
  popup_bridge_event_channel_ =
      std::make_unique<flutter::EventChannel<flutter::EncodableValue>>(
          flutter_controller_->engine()->messenger(),
          "formycareer/popup_bridge_events",
          &flutter::StandardMethodCodec::GetInstance());

  auto handler =
      std::make_unique<
          flutter::StreamHandlerFunctions<flutter::EncodableValue>>(
          [this](
              const flutter::EncodableValue*,
              std::unique_ptr<flutter::EventSink<flutter::EncodableValue>>
                  &&events)
              -> std::unique_ptr<
                  flutter::StreamHandlerError<flutter::EncodableValue>> {
            popup_bridge_event_sink_ = std::move(events);
            return nullptr;
          },
          [this](const flutter::EncodableValue*)
              -> std::unique_ptr<
                  flutter::StreamHandlerError<flutter::EncodableValue>> {
            popup_bridge_event_sink_.reset();
            return nullptr;
          });

  popup_bridge_event_channel_->SetStreamHandler(std::move(handler));
}

void FlutterWindow::SetupSystemTextSelectionEventChannel() {
  system_text_selection_event_channel_ =
      std::make_unique<flutter::EventChannel<flutter::EncodableValue>>(
          flutter_controller_->engine()->messenger(),
          "formycareer/system_text_selection",
          &flutter::StandardMethodCodec::GetInstance());

  auto handler =
      std::make_unique<
          flutter::StreamHandlerFunctions<flutter::EncodableValue>>(
          [this](
              const flutter::EncodableValue*,
              std::unique_ptr<flutter::EventSink<flutter::EncodableValue>>
                  &&events)
              -> std::unique_ptr<
                  flutter::StreamHandlerError<flutter::EncodableValue>> {
            if (!selection_host_bridge_) {
              selection_host_bridge_ = std::make_unique<SelectionHostBridge>();
            }
            selection_host_bridge_->SetSink(std::move(events));
            HWND popup_hwnd =
                popup_window_ != nullptr ? popup_window_->GetHandle() : nullptr;
            selection_host_bridge_->Start(GetHandle(), popup_hwnd,
                                          selection_uia_host_enabled_);
            return nullptr;
          },
          [this](const flutter::EncodableValue*)
              -> std::unique_ptr<
                  flutter::StreamHandlerError<flutter::EncodableValue>> {
            if (selection_host_bridge_) {
              selection_host_bridge_->ClearSink();
              selection_host_bridge_->Stop();
            }
            return nullptr;
          });

  system_text_selection_event_channel_->SetStreamHandler(std::move(handler));
}

void FlutterWindow::SetupPopupBridgeMethodChannel() {
  popup_bridge_method_channel_ =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          flutter_controller_->engine()->messenger(),
          "formycareer/popup_bridge",
          &flutter::StandardMethodCodec::GetInstance());

  popup_bridge_method_channel_->SetMethodCallHandler(
      [this](const flutter::MethodCall<flutter::EncodableValue>& call,
             std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>
                 result) {
        const auto* args = std::get_if<flutter::EncodableMap>(call.arguments());
        if (call.method_name() != "completeSaveRequest" || args == nullptr) {
          result->NotImplemented();
          return;
        }

        auto request_id_it = args->find(flutter::EncodableValue("requestId"));
        auto success_it = args->find(flutter::EncodableValue("success"));
        auto message_it = args->find(flutter::EncodableValue("message"));
        if (request_id_it == args->end() || success_it == args->end() ||
            message_it == args->end()) {
          result->Success(flutter::EncodableValue(false));
          return;
        }

        int request_id = 0;
        if (const auto* rid32 = std::get_if<int32_t>(&request_id_it->second)) {
          request_id = *rid32;
        } else if (const auto* rid64 =
                       std::get_if<int64_t>(&request_id_it->second)) {
          request_id = static_cast<int>(*rid64);
        } else {
          result->Success(flutter::EncodableValue(false));
          return;
        }
        const auto* success = std::get_if<bool>(&success_it->second);
        const auto* message = std::get_if<std::string>(&message_it->second);
        if (success == nullptr || message == nullptr) {
          result->Success(flutter::EncodableValue(false));
          return;
        }

        auto pending_it = pending_popup_save_results_.find(request_id);
        if (pending_it == pending_popup_save_results_.end()) {
          result->Success(flutter::EncodableValue(false));
          return;
        }

        flutter::EncodableMap payload;
        payload[flutter::EncodableValue("success")] =
            flutter::EncodableValue(*success);
        payload[flutter::EncodableValue("message")] =
            flutter::EncodableValue(*message);
        pending_it->second->Success(flutter::EncodableValue(payload));
        pending_popup_save_results_.erase(pending_it);
        result->Success(flutter::EncodableValue(true));
      });
}

void FlutterWindow::DispatchPopupSaveRequest(
    flutter::EncodableMap payload,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  if (!popup_bridge_event_sink_) {
    flutter::EncodableMap failure;
    failure[flutter::EncodableValue("success")] = flutter::EncodableValue(false);
    failure[flutter::EncodableValue("message")] =
        flutter::EncodableValue("Main app bridge unavailable");
    result->Success(flutter::EncodableValue(failure));
    return;
  }

  const int request_id = next_popup_bridge_request_id_++;
  payload[flutter::EncodableValue("requestId")] =
      flutter::EncodableValue(request_id);
  pending_popup_save_results_[request_id] = std::move(result);
  popup_bridge_event_sink_->Success(flutter::EncodableValue(payload));
}

void FlutterWindow::PublishHotkeyPressed(int id, bool runner_was_foreground) {
  if (!hotkey_event_sink_) {
    return;
  }
  flutter::EncodableMap payload;
  payload[flutter::EncodableValue("id")] = flutter::EncodableValue(id);
  payload[flutter::EncodableValue("runnerWasForeground")] =
      flutter::EncodableValue(runner_was_foreground);
  hotkey_event_sink_->Success(flutter::EncodableValue(payload));
}

bool FlutterWindow::SetupKeyboardHook() {
  if (keyboard_hook_ != nullptr) {
    return true;
  }
  s_keyboard_hook_instance_ = this;
  keyboard_hook_ = SetWindowsHookEx(WH_KEYBOARD_LL, LowLevelKeyboardProc,
                                    GetModuleHandle(nullptr), 0);
  return keyboard_hook_ != nullptr;
}

void FlutterWindow::TearDownKeyboardHook() {
  if (keyboard_hook_ != nullptr) {
    UnhookWindowsHookEx(keyboard_hook_);
    keyboard_hook_ = nullptr;
  }
  if (s_keyboard_hook_instance_ == this) {
    s_keyboard_hook_instance_ = nullptr;
  }
}

LRESULT CALLBACK FlutterWindow::LowLevelKeyboardProc(int nCode,
                                                     WPARAM wparam,
                                                     LPARAM lparam) {
  if (nCode == HC_ACTION && s_keyboard_hook_instance_ != nullptr &&
      lparam != 0) {
    const auto* info = reinterpret_cast<KBDLLHOOKSTRUCT*>(lparam);
    s_keyboard_hook_instance_->HandleLowLevelKeyboardEvent(info, wparam);
  }
  return CallNextHookEx(nullptr, nCode, wparam, lparam);
}

bool FlutterWindow::HandleLowLevelKeyboardEvent(const KBDLLHOOKSTRUCT* info,
                                                WPARAM wparam) {
  if (info == nullptr) {
    return false;
  }
  if (wparam != WM_KEYDOWN && wparam != WM_SYSKEYDOWN) {
    return false;
  }

  const bool ctrl_down = (GetAsyncKeyState(VK_CONTROL) & 0x8000) != 0;
  const bool shift_down = (GetAsyncKeyState(VK_SHIFT) & 0x8000) != 0;
  if (!ctrl_down || !shift_down) {
    return false;
  }

  if (info->vkCode == 'D') {
    if (!ShouldPublishFromHook(kTextCaptureHotkeyId)) {
      return false;
    }
    if (hotkey_pressed_callback_) {
      hotkey_pressed_callback_(kTextCaptureHotkeyId);
    }
    PublishHotkeyPressed(kTextCaptureHotkeyId, GetForegroundWindow() == GetHandle());
    return true;
  }
  if (info->vkCode == 'X') {
    if (!ShouldPublishFromHook(kImageCaptureHotkeyId)) {
      return false;
    }
    if (hotkey_pressed_callback_) {
      hotkey_pressed_callback_(kImageCaptureHotkeyId);
    }
    PublishHotkeyPressed(kImageCaptureHotkeyId, GetForegroundWindow() == GetHandle());
    return true;
  }
  return false;
}

bool FlutterWindow::ShouldPublishFromHook(int hotkey_id) {
  const ULONGLONG now = GetTickCount64();
  auto it = hook_last_publish_tick_by_id_.find(hotkey_id);
  if (it != hook_last_publish_tick_by_id_.end() &&
      now - it->second < kHookDebounceMs) {
    return false;
  }
  hook_last_publish_tick_by_id_[hotkey_id] = now;
  return true;
}

void FlutterWindow::OnDestroy() {
  TearDownKeyboardHook();
  TearDownSelectionFallbackHooks();
  // Tear down the selection channel first so the stream onCancel stops the
  // SelectionHost process while the bridge object is still alive.
  system_text_selection_event_channel_.reset();
  if (selection_host_bridge_) {
    selection_host_bridge_->Stop();
    selection_host_bridge_.reset();
  }
  if (overlay_active_) {
    HideOverlayWindow();
  }
  for (auto& pending : pending_popup_save_results_) {
    flutter::EncodableMap failure;
    failure[flutter::EncodableValue("success")] = flutter::EncodableValue(false);
    failure[flutter::EncodableValue("message")] =
        flutter::EncodableValue("Main app bridge disposed");
    pending.second->Success(flutter::EncodableValue(failure));
  }
  pending_popup_save_results_.clear();
  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  if (overlay_active_ && message == WM_MOUSEACTIVATE) {
    return MA_NOACTIVATE;
  }

  // Give Flutter, including plugins, an opportunity to handle window messages.
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      return *result;
    }
  }

  switch (message) {
    case WM_GETMINMAXINFO: {
      auto* minmax = reinterpret_cast<MINMAXINFO*>(lparam);
      if (minmax != nullptr) {
        const UINT dpi = GetDpiForWindow(hwnd);
        const double scale = static_cast<double>(dpi) / 96.0;
        minmax->ptMinTrackSize.x =
            static_cast<LONG>(kMainWindowMinWidth * scale);
        minmax->ptMinTrackSize.y =
            static_cast<LONG>(kMainWindowMinHeight * scale);
      }
      return 0;
    }
    case WM_CLIPBOARDUPDATE:
      HandleClipboardUpdateNotification();
      return 0;
    case WM_HOTKEY: {
      const bool runner_was_foreground = GetForegroundWindow() == hwnd;
      if (hotkey_pressed_callback_) {
        hotkey_pressed_callback_(static_cast<int>(wparam));
      }
      PublishHotkeyPressed(static_cast<int>(wparam), runner_was_foreground);
      return 0;
    }
    case WM_FONTCHANGE:
      flutter_controller_->engine()->ReloadSystemFonts();
      break;
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}

flutter::EncodableMap FlutterWindow::ShowOverlayNearCursor(
    const flutter::EncodableMap& args) {
  POINT cursor{};
  if (!GetCursorPos(&cursor)) {
    flutter::EncodableMap response;
    response[flutter::EncodableValue("success")] = flutter::EncodableValue(false);
    response[flutter::EncodableValue("fallbackUsed")] =
        flutter::EncodableValue(true);
    response[flutter::EncodableValue("reason")] =
        flutter::EncodableValue("GetCursorPos failed");
    return response;
  }

  if (popup_window_ == nullptr) {
    flutter::EncodableMap response;
    response[flutter::EncodableValue("success")] = flutter::EncodableValue(false);
    response[flutter::EncodableValue("fallbackUsed")] =
        flutter::EncodableValue(true);
    response[flutter::EncodableValue("reason")] =
        flutter::EncodableValue("Popup window unavailable");
    return response;
  }

  const double popup_width = ReadDoubleArg(args, "popupWidth", 320.0);
  const double popup_height = ReadDoubleArg(args, "popupHeight", 190.0);
  const double offset_x = ReadDoubleArg(args, "offsetX", 10.0);
  const double offset_y = ReadDoubleArg(args, "offsetY", 10.0);
  std::string mode = "text";
  auto mode_it = args.find(flutter::EncodableValue("mode"));
  if (mode_it != args.end()) {
    if (const auto* mode_value = std::get_if<std::string>(&mode_it->second)) {
      mode = *mode_value;
    }
  }

  std::optional<RECT> region = std::nullopt;
  auto left_it = args.find(flutter::EncodableValue("regionLeft"));
  auto top_it = args.find(flutter::EncodableValue("regionTop"));
  auto width_it = args.find(flutter::EncodableValue("regionWidth"));
  auto height_it = args.find(flutter::EncodableValue("regionHeight"));
  if (left_it != args.end() && top_it != args.end() && width_it != args.end() &&
      height_it != args.end()) {
    const double left = ReadDoubleArg(args, "regionLeft", 0.0);
    const double top = ReadDoubleArg(args, "regionTop", 0.0);
    const double width = ReadDoubleArg(args, "regionWidth", 0.0);
    const double height = ReadDoubleArg(args, "regionHeight", 0.0);
    if (width > 0 && height > 0) {
      RECT rect{};
      rect.left = static_cast<LONG>(left);
      rect.top = static_cast<LONG>(top);
      rect.right = static_cast<LONG>(left + width);
      rect.bottom = static_cast<LONG>(top + height);
      region = rect;
    }
  }

  std::string selected_text = ReadStringArg(args, "selectedText");
  if (mode == "text" && selected_text.empty()) {
    suppress_clipboard_notifications_until_tick_ = GetTickCount64() + 900;
    selected_text = CaptureSelectedTextFromForegroundApp();
  }

  const std::string native_language = ReadStringArg(args, "nativeLanguage");
  const std::string source_app = ReadStringArg(args, "sourceApp");
  const std::vector<std::string> source_languages =
      ReadStringListArg(args, "sourceLanguages");
  const std::vector<std::string> tag_suggestions =
      ReadStringListArg(args, "tagSuggestions");

  if (mode == "image" && !region.has_value()) {
    PopupFlutterWindow* popup = popup_window_;
    const double w = popup_width;
    const double h = popup_height;
    const double ox = offset_x;
    const double oy = offset_y;
    const std::string native_copy = native_language;
    const std::string source_app_copy = source_app;
    const std::vector<std::string> sources_copy = source_languages;
    const std::vector<std::string> tags_copy = tag_suggestions;
    const bool launched = RegionSelectorWindow::Show(
        [popup, w, h, ox, oy, source_app_copy, native_copy, sources_copy, tags_copy](bool success,
                                                          RECT selection) {
          if (!success || popup == nullptr) {
            return;
          }
          POINT region_cursor{selection.left, selection.bottom};
          Sleep(60);
          MSG msg;
          while (PeekMessageW(&msg, nullptr, 0, 0, PM_REMOVE)) {
            TranslateMessage(&msg);
            DispatchMessageW(&msg);
          }
          popup->ShowPopup("image", region_cursor, selection, w, h, ox, oy,
                           std::string(), source_app_copy, native_copy,
                           sources_copy, tags_copy);
        });
    flutter::EncodableMap response;
    response[flutter::EncodableValue("success")] =
        flutter::EncodableValue(launched);
    response[flutter::EncodableValue("fallbackUsed")] =
        flutter::EncodableValue(false);
    response[flutter::EncodableValue("deferred")] =
        flutter::EncodableValue(true);
    if (!launched) {
      response[flutter::EncodableValue("reason")] =
          flutter::EncodableValue("Region selector already active");
    }
    return response;
  }

  return popup_window_->ShowPopup(mode, cursor, region, popup_width, popup_height,
                                  offset_x, offset_y, selected_text, source_app,
                                  native_language, source_languages,
                                  tag_suggestions);
}

flutter::EncodableMap FlutterWindow::HideOverlayWindow() {
  if (popup_window_ != nullptr) {
    return popup_window_->HidePopupWindow();
  }
  flutter::EncodableMap response;
  response[flutter::EncodableValue("success")] = flutter::EncodableValue(false);
  response[flutter::EncodableValue("fallbackUsed")] =
      flutter::EncodableValue(true);
  response[flutter::EncodableValue("reason")] =
      flutter::EncodableValue("Popup window unavailable");
  return response;
}

UINT FlutterWindow::ResolveDpiForPoint(POINT point) {
  HMONITOR monitor = MonitorFromPoint(point, MONITOR_DEFAULTTONEAREST);
  HMODULE shcore = LoadLibraryW(L"Shcore.dll");
  if (shcore != nullptr) {
    using GetDpiForMonitorFn = HRESULT(WINAPI*)(HMONITOR, int, UINT*, UINT*);
    auto get_dpi_for_monitor = reinterpret_cast<GetDpiForMonitorFn>(
        GetProcAddress(shcore, "GetDpiForMonitor"));
    if (get_dpi_for_monitor != nullptr) {
      UINT dpi_x = 96;
      UINT dpi_y = 96;
      if (SUCCEEDED(get_dpi_for_monitor(monitor, 0, &dpi_x, &dpi_y))) {
        FreeLibrary(shcore);
        return dpi_x;
      }
    }
    FreeLibrary(shcore);
  }

  if (GetHandle() != nullptr) {
    return GetDpiForWindow(GetHandle());
  }
  return 96;
}

void FlutterWindow::ApplySelectionFallbackSettings(bool clipboard_listen,
                                                   bool drag_send_ctrl_c) {
  selection_clipboard_listen_ = clipboard_listen;
  selection_drag_send_ctrl_c_ = drag_send_ctrl_c;
  const HWND hwnd = GetHandle();
  if (hwnd != nullptr) {
    if (clipboard_listen && !clipboard_listener_installed_) {
      if (::AddClipboardFormatListener(hwnd)) {
        clipboard_listener_installed_ = true;
      }
    } else if (!clipboard_listen && clipboard_listener_installed_) {
      ::RemoveClipboardFormatListener(hwnd);
      clipboard_listener_installed_ = false;
    }
  }
  if (drag_send_ctrl_c) {
    SetupMouseHook();
  } else {
    TearDownMouseHook();
  }
}

void FlutterWindow::TearDownSelectionFallbackHooks() {
  const HWND hwnd = GetHandle();
  if (clipboard_listener_installed_ && hwnd != nullptr) {
    ::RemoveClipboardFormatListener(hwnd);
  }
  clipboard_listener_installed_ = false;
  TearDownMouseHook();
}

std::wstring FlutterWindow::ToLowerWide(std::wstring value) {
  std::transform(value.begin(), value.end(), value.begin(),
                 [](wchar_t ch) { return static_cast<wchar_t>(std::towlower(ch)); });
  return value;
}

std::string FlutterWindow::ToLowerUtf8(std::string value) {
  std::transform(value.begin(), value.end(), value.begin(),
                 [](unsigned char ch) { return static_cast<char>(std::tolower(ch)); });
  return value;
}

bool FlutterWindow::ContainsAnyToken(const std::wstring& text,
                                     const std::vector<std::wstring>& tokens) {
  for (const auto& token : tokens) {
    if (!token.empty() && text.find(token) != std::wstring::npos) {
      return true;
    }
  }
  return false;
}

std::wstring FlutterWindow::FileNameFromPath(const std::wstring& path) {
  const auto slash = path.find_last_of(L"\\/");
  if (slash == std::wstring::npos) {
    return path;
  }
  return path.substr(slash + 1);
}

std::wstring FlutterWindow::ProcessImagePath(HWND hwnd) {
  DWORD pid = 0;
  GetWindowThreadProcessId(hwnd, &pid);
  if (pid == 0) {
    return std::wstring();
  }
  HANDLE process = OpenProcess(PROCESS_QUERY_LIMITED_INFORMATION, FALSE, pid);
  if (process == nullptr) {
    return std::wstring();
  }
  wchar_t buffer[MAX_PATH * 2]{};
  DWORD size = static_cast<DWORD>(std::size(buffer));
  std::wstring result;
  if (QueryFullProcessImageNameW(process, 0, buffer, &size)) {
    result.assign(buffer, size);
  }
  CloseHandle(process);
  return result;
}

bool FlutterWindow::ShouldIgnoreForegroundForSelection(HWND foreground) {
  if (foreground == nullptr) {
    return true;
  }
  const HWND main = GetHandle();
  if (main != nullptr && foreground == main) {
    return true;
  }
  if (popup_window_ != nullptr) {
    const HWND popup = popup_window_->GetHandle();
    if (popup != nullptr && foreground == popup) {
      return true;
    }
  }
  return false;
}

bool FlutterWindow::IsDeniedForegroundForSelection(HWND foreground) {
  if (foreground == nullptr || !selection_strict_filter_enabled_) {
    return false;
  }
  wchar_t class_name[256]{};
  GetClassNameW(foreground, class_name, static_cast<int>(std::size(class_name)));
  std::wstring class_l = ToLowerWide(class_name);
  wchar_t title[512]{};
  GetWindowTextW(foreground, title, static_cast<int>(std::size(title)));
  std::wstring title_l = ToLowerWide(title);
  const std::wstring process_path = ToLowerWide(ProcessImagePath(foreground));
  const std::wstring process_name = FileNameFromPath(process_path);

  static const std::vector<std::wstring> kDeniedExe = {
      L"snippingtool.exe", L"screencapturehost.exe", L"screenclippinghost.exe",
      L"sharex.exe",       L"greenshot.exe",         L"lightshot.exe",
      L"flameshot.exe",    L"snagit32.exe",          L"snagiteditor.exe"};
  static const std::vector<std::wstring> kDeniedClass = {
      L"screenclippinghost", L"snip"};
  static const std::vector<std::wstring> kDeniedTitle = {
      L"snipping tool", L"screen snip", L"screenshot", L"sharex", L"greenshot"};

  if (ContainsAnyToken(process_name, kDeniedExe) ||
      ContainsAnyToken(class_l, kDeniedClass) ||
      ContainsAnyToken(title_l, kDeniedTitle)) {
    return true;
  }
  return false;
}

bool FlutterWindow::IsLikelyValidSelectionText(const std::string& utf8) {
  if (utf8.empty()) {
    return false;
  }
  if (!selection_strict_filter_enabled_) {
    return utf8.size() >= 2;
  }
  const std::wstring w = Utf8ToWide(utf8);
  if (w.size() < 3 || w.size() > 5000) {
    return false;
  }
  size_t letters = 0;
  size_t digits = 0;
  size_t symbols = 0;
  for (wchar_t ch : w) {
    if (std::iswalpha(ch)) {
      letters++;
    } else if (std::iswdigit(ch)) {
      digits++;
    } else if (!std::iswspace(ch)) {
      symbols++;
    }
  }
  if (letters == 0) {
    return false;
  }
  const double symbol_ratio =
      static_cast<double>(symbols) / static_cast<double>(w.size());
  if (symbol_ratio > 0.45) {
    return false;
  }
  if (letters < 2 && digits > letters * 3) {
    return false;
  }
  return true;
}

bool FlutterWindow::IsPointOverAppOwnedWindow(POINT screen_pt) {
  HWND hit = WindowFromPoint(screen_pt);
  if (hit == nullptr) {
    return false;
  }
  HWND root = GetAncestor(hit, GA_ROOT);
  if (root == nullptr) {
    return false;
  }
  const HWND main = GetHandle();
  if (main != nullptr && root == main) {
    return true;
  }
  if (popup_window_ != nullptr) {
    const HWND popup = popup_window_->GetHandle();
    if (popup != nullptr && root == popup) {
      return true;
    }
  }
  return false;
}

void FlutterWindow::SyncSelectionHostUiaIfSubscribed() {
  if (!selection_host_bridge_ || !selection_host_bridge_->HasSink()) {
    return;
  }
  HWND popup_hwnd =
      popup_window_ != nullptr ? popup_window_->GetHandle() : nullptr;
  selection_host_bridge_->Start(GetHandle(), popup_hwnd,
                                 selection_uia_host_enabled_);
}

void FlutterWindow::HandleClipboardUpdateNotification() {
  if (!selection_clipboard_listen_) {
    return;
  }
  if (GetTickCount64() < suppress_clipboard_notifications_until_tick_) {
    return;
  }
  HWND fg = GetForegroundWindow();
  if (ShouldIgnoreForegroundForSelection(fg) ||
      IsDeniedForegroundForSelection(fg)) {
    return;
  }
  std::wstring w = ReadUnicodeTextFromClipboard();
  if (w.empty() || w.size() > 200000) {
    return;
  }
  std::string u8 = WideToUtf8(w);
  if (u8.size() < 2) {
    return;
  }
  const ULONGLONG now = GetTickCount64();
  if (u8 == last_clipboard_emit_utf8_ &&
      now - last_clipboard_emit_tick_ < 500) {
    return;
  }
  last_clipboard_emit_utf8_ = u8;
  last_clipboard_emit_tick_ = now;
  if (selection_host_bridge_ && IsLikelyValidSelectionText(u8)) {
    selection_host_bridge_->PublishExternalSelection(u8);
  }
}

void FlutterWindow::ScheduleDragSelectionCopyCapture() {
  if (!selection_drag_send_ctrl_c_) {
    return;
  }
  const ULONGLONG now = GetTickCount64();
  if (now - last_drag_copy_emit_tick_ < 1500) {
    return;
  }
  last_drag_copy_emit_tick_ = now;
  std::thread([this]() {
    Sleep(120);
    if (!selection_drag_send_ctrl_c_) {
      return;
    }
    HWND fg = GetForegroundWindow();
    if (ShouldIgnoreForegroundForSelection(fg) ||
        IsDeniedForegroundForSelection(fg)) {
      return;
    }
    suppress_clipboard_notifications_until_tick_ = GetTickCount64() + 900;
    std::string t = CaptureSelectedTextFromForegroundApp();
    if (t.empty() || t.size() < 2) {
      return;
    }
    if (selection_host_bridge_ && IsLikelyValidSelectionText(t)) {
      selection_host_bridge_->PublishExternalSelection(t);
    }
  }).detach();
}

bool FlutterWindow::SetupMouseHook() {
  if (mouse_hook_ != nullptr) {
    return true;
  }
  s_mouse_hook_instance_ = this;
  mouse_hook_ = SetWindowsHookEx(WH_MOUSE_LL, LowLevelMouseProc,
                                 GetModuleHandle(nullptr), 0);
  return mouse_hook_ != nullptr;
}

void FlutterWindow::TearDownMouseHook() {
  if (mouse_hook_ != nullptr) {
    UnhookWindowsHookEx(mouse_hook_);
    mouse_hook_ = nullptr;
  }
  if (s_mouse_hook_instance_ == this) {
    s_mouse_hook_instance_ = nullptr;
  }
  drag_left_button_down_ = false;
  has_last_click_for_double_ = false;
  word_select_on_next_lbuttonup_ = false;
}

LRESULT CALLBACK FlutterWindow::LowLevelMouseProc(int nCode,
                                                  WPARAM wparam,
                                                  LPARAM lparam) {
  if (nCode != HC_ACTION || s_mouse_hook_instance_ == nullptr) {
    return CallNextHookEx(nullptr, nCode, wparam, lparam);
  }
  FlutterWindow* self = s_mouse_hook_instance_;
  if (!self->selection_drag_send_ctrl_c_) {
    return CallNextHookEx(nullptr, nCode, wparam, lparam);
  }
  auto* info = reinterpret_cast<MSLLHOOKSTRUCT*>(lparam);
  if (wparam == WM_LBUTTONDOWN) {
    if (self->IsPointOverAppOwnedWindow(info->pt)) {
      return CallNextHookEx(nullptr, nCode, wparam, lparam);
    }
    const ULONGLONG now = GetTickCount64();
    const UINT dbl_ms = GetDoubleClickTime();
    const LONG dcx = GetSystemMetrics(SM_CXDOUBLECLK);
    const LONG dcy = GetSystemMetrics(SM_CYDOUBLECLK);
    bool second_click_of_double = false;
    if (self->has_last_click_for_double_ &&
        now - self->last_click_up_tick_ <= static_cast<ULONGLONG>(dbl_ms)) {
      const LONG pdx = info->pt.x - self->last_click_anchor_pt_.x;
      const LONG pdy = info->pt.y - self->last_click_anchor_pt_.y;
      if (pdx <= dcx && pdx >= -dcx && pdy <= dcy && pdy >= -dcy) {
        second_click_of_double = true;
      }
    }
    self->word_select_on_next_lbuttonup_ = second_click_of_double;
    self->drag_anchor_pt_ = info->pt;
    self->drag_left_button_down_ = true;
  } else if (wparam == WM_LBUTTONUP && self->drag_left_button_down_) {
    self->drag_left_button_down_ = false;
    const bool up_on_app = self->IsPointOverAppOwnedWindow(info->pt);
    const LONG dx = info->pt.x - self->drag_anchor_pt_.x;
    const LONG dy = info->pt.y - self->drag_anchor_pt_.y;
    const LONG dist2 = dx * dx + dy * dy;
    const LONG drag_threshold = self->selection_strict_filter_enabled_
                                    ? kStrictDragThresholdPx
                                    : 18;
    const bool drag_select = dist2 >= drag_threshold * drag_threshold;
    const bool word_select = self->word_select_on_next_lbuttonup_;
    self->word_select_on_next_lbuttonup_ = false;
    if (up_on_app) {
      return CallNextHookEx(nullptr, nCode, wparam, lparam);
    }
    if (drag_select || word_select) {
      HWND fg = GetForegroundWindow();
      if (!self->ShouldIgnoreForegroundForSelection(fg) &&
          !self->IsDeniedForegroundForSelection(fg)) {
        self->ScheduleDragSelectionCopyCapture();
      }
    }
    self->last_click_up_tick_ = GetTickCount64();
    self->last_click_anchor_pt_ = self->drag_anchor_pt_;
    self->has_last_click_for_double_ = true;
  }
  return CallNextHookEx(nullptr, nCode, wparam, lparam);
}
