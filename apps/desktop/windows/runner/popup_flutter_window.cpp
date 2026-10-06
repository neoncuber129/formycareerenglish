#include "popup_flutter_window.h"

#include <algorithm>
#include <cmath>
#include <fstream>
#include <optional>
#include <sstream>

#include "flutter_window.h"
#include "flutter/generated_plugin_registrant.h"
#include <flutter/event_stream_handler_functions.h>
#include <flutter/standard_method_codec.h>

namespace {

constexpr double kWindowPadding = 0.0;
// Must match Flutter overlay scaffold color (0xFFFF00FF). Only areas using
// this exact RGB should be "punched out"; popup surfaces must be opaque so
// content is not tinted by the color key.
constexpr COLORREF kTransparencyKey = RGB(255, 0, 255);
constexpr UINT kMsgHideFromOutsideClick = WM_APP + 7;

void PopupNativeLog(const std::string& msg) {
  std::ofstream out("overlay-native-debug.log", std::ios::app);
  if (out) {
    out << msg << std::endl;
  }
}

std::optional<double> ReadEncodableDouble(const flutter::EncodableValue& v) {
  if (const auto* d = std::get_if<double>(&v)) {
    return *d;
  }
  if (const auto* i = std::get_if<int32_t>(&v)) {
    return static_cast<double>(*i);
  }
  if (const auto* l = std::get_if<int64_t>(&v)) {
    return static_cast<double>(*l);
  }
  return std::nullopt;
}

}  // namespace

PopupFlutterWindow* PopupFlutterWindow::hook_owner_ = nullptr;

PopupFlutterWindow::PopupFlutterWindow(const flutter::DartProject& project)
    : project_(project) {}

PopupFlutterWindow::~PopupFlutterWindow() {}

void PopupFlutterWindow::SetMainWindow(FlutterWindow* main_window) {
  main_window_ = main_window;
}

bool PopupFlutterWindow::OnCreate() {
  PopupNativeLog("[popup] OnCreate entered");
  if (!Win32Window::OnCreate()) {
    PopupNativeLog("[popup] Win32Window::OnCreate failed");
    return false;
  }

  RECT frame = GetClientArea();
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    PopupNativeLog("[popup] FlutterViewController creation failed");
    return false;
  }
  PopupNativeLog("[popup] FlutterViewController created");

  RegisterPlugins(flutter_controller_->engine());
  SetupPopupEventChannel();
  SetupPopupControlMethodChannel();
  PopupNativeLog("[popup] channels registered");
  SetChildContent(flutter_controller_->view()->GetNativeWindow());
  SetFocusEnabled(false);

  const HWND hwnd = GetHandle();
  SetWindowLongPtr(hwnd, GWL_STYLE, WS_POPUP | WS_CLIPSIBLINGS | WS_CLIPCHILDREN);
  SetWindowLongPtr(hwnd, GWL_EXSTYLE,
                   WS_EX_TOOLWINDOW | WS_EX_TOPMOST |
                       WS_EX_LAYERED);
  SetLayeredWindowAttributes(hwnd, kTransparencyKey, 0, LWA_COLORKEY);
  // Keep the popup visible off-screen so the Flutter engine warms up and the
  // Dart side subscribes to popup_window_events. Without this, a hidden
  // window pauses first-frame rendering and the event sink stays null.
  SetWindowPos(hwnd, HWND_TOPMOST, -32000, -32000, 1, 1,
               SWP_NOACTIVATE | SWP_FRAMECHANGED | SWP_SHOWWINDOW);

  flutter_controller_->ForceRedraw();
  return true;
}

void PopupFlutterWindow::InstallOutsideClickHook() {
  if (outside_click_hook_ != nullptr) {
    return;
  }
  hook_owner_ = this;
  outside_click_hook_ =
      SetWindowsHookExW(WH_MOUSE_LL, LowLevelMouseProc, nullptr, 0);
}

void PopupFlutterWindow::UninstallOutsideClickHook() {
  if (outside_click_hook_ == nullptr) {
    if (hook_owner_ == this) {
      hook_owner_ = nullptr;
    }
    return;
  }
  UnhookWindowsHookEx(outside_click_hook_);
  outside_click_hook_ = nullptr;
  if (hook_owner_ == this) {
    hook_owner_ = nullptr;
  }
}

LRESULT CALLBACK PopupFlutterWindow::LowLevelMouseProc(int nCode,
                                                       WPARAM wParam,
                                                       LPARAM lParam) {
  if (nCode < HC_ACTION || hook_owner_ == nullptr || !hook_owner_->popup_visible_) {
    return CallNextHookEx(nullptr, nCode, wParam, lParam);
  }
  const bool isMouseDown =
      wParam == WM_LBUTTONDOWN || wParam == WM_RBUTTONDOWN ||
      wParam == WM_MBUTTONDOWN || wParam == WM_NCLBUTTONDOWN ||
      wParam == WM_NCRBUTTONDOWN || wParam == WM_NCMBUTTONDOWN;
  if (!isMouseDown) {
    return CallNextHookEx(nullptr, nCode, wParam, lParam);
  }
  const auto* info = reinterpret_cast<const MSLLHOOKSTRUCT*>(lParam);
  if (info == nullptr) {
    return CallNextHookEx(nullptr, nCode, wParam, lParam);
  }
  const HWND hwnd = hook_owner_->GetHandle();
  if (hwnd == nullptr) {
    return CallNextHookEx(nullptr, nCode, wParam, lParam);
  }
  RECT wr{};
  if (!GetWindowRect(hwnd, &wr)) {
    return CallNextHookEx(nullptr, nCode, wParam, lParam);
  }
  if (!PtInRect(&wr, info->pt)) {
    PostMessage(hwnd, kMsgHideFromOutsideClick, 0, 0);
  }
  return CallNextHookEx(nullptr, nCode, wParam, lParam);
}

void PopupFlutterWindow::SetupPopupEventChannel() {
  popup_event_channel_ =
      std::make_unique<flutter::EventChannel<flutter::EncodableValue>>(
          flutter_controller_->engine()->messenger(),
          "formycareer/popup_window_events",
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
            popup_event_sink_ = std::move(events);
            PopupNativeLog("[popup] event sink attached");
            return nullptr;
          },
          [this](const flutter::EncodableValue*)
              -> std::unique_ptr<
                  flutter::StreamHandlerError<flutter::EncodableValue>> {
            popup_event_sink_.reset();
            PopupNativeLog("[popup] event sink detached");
            return nullptr;
          });

  popup_event_channel_->SetStreamHandler(std::move(handler));
}

void PopupFlutterWindow::SetupPopupControlMethodChannel() {
  popup_control_method_channel_ =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          flutter_controller_->engine()->messenger(),
          "formycareer/popup_window_control",
          &flutter::StandardMethodCodec::GetInstance());

  popup_control_method_channel_->SetMethodCallHandler(
      [this](const flutter::MethodCall<flutter::EncodableValue>& call,
             std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>
                 result) {
        if (call.method_name() == "hidePopupWindow") {
          result->Success(flutter::EncodableValue(HidePopupWindow()));
          return;
        }
        if (call.method_name() == "saveCapturedWord") {
          const auto* args = std::get_if<flutter::EncodableMap>(call.arguments());
          if (main_window_ == nullptr || args == nullptr) {
            flutter::EncodableMap payload;
            payload[flutter::EncodableValue("success")] =
                flutter::EncodableValue(false);
            payload[flutter::EncodableValue("message")] =
                flutter::EncodableValue("Main app bridge unavailable");
            result->Success(flutter::EncodableValue(payload));
            return;
          }
          main_window_->DispatchPopupSaveRequest(*args, std::move(result));
          return;
        }
        if (call.method_name() == "setPopupFrameSize") {
          const auto* args = std::get_if<flutter::EncodableMap>(call.arguments());
          if (args == nullptr) {
            flutter::EncodableMap payload;
            payload[flutter::EncodableValue("success")] =
                flutter::EncodableValue(false);
            payload[flutter::EncodableValue("reason")] =
                flutter::EncodableValue("Expected argument map");
            result->Success(flutter::EncodableValue(payload));
            return;
          }
          auto wit = args->find(flutter::EncodableValue("width"));
          auto hit = args->find(flutter::EncodableValue("height"));
          if (wit == args->end() || hit == args->end()) {
            flutter::EncodableMap payload;
            payload[flutter::EncodableValue("success")] =
                flutter::EncodableValue(false);
            payload[flutter::EncodableValue("reason")] =
                flutter::EncodableValue("Missing width/height");
            result->Success(flutter::EncodableValue(payload));
            return;
          }
          const auto w = ReadEncodableDouble(wit->second);
          const auto h = ReadEncodableDouble(hit->second);
          if (!w.has_value() || !h.has_value() ||
              !std::isfinite(*w) || !std::isfinite(*h) || *w <= 0 || *h <= 0) {
            flutter::EncodableMap payload;
            payload[flutter::EncodableValue("success")] =
                flutter::EncodableValue(false);
            payload[flutter::EncodableValue("reason")] =
                flutter::EncodableValue("Invalid width/height");
            result->Success(flutter::EncodableValue(payload));
            return;
          }
          result->Success(
              flutter::EncodableValue(SetPopupFrameSize(*w, *h)));
          return;
        }
        result->NotImplemented();
      });
}

flutter::EncodableMap PopupFlutterWindow::ShowPopup(
    const std::string& mode,
    POINT cursor,
    const std::optional<RECT>& region,
    double popup_width,
    double popup_height,
    double offset_x,
    double offset_y,
    const std::string& selected_text,
    const std::string& source_app,
    const std::string& native_language,
    const std::vector<std::string>& source_languages,
    const std::vector<std::string>& tag_suggestions) {
  flutter::EncodableMap response;
  const HWND hwnd = GetHandle();
  if (hwnd == nullptr) {
    response[flutter::EncodableValue("success")] = flutter::EncodableValue(false);
    response[flutter::EncodableValue("fallbackUsed")] =
        flutter::EncodableValue(true);
    response[flutter::EncodableValue("reason")] =
        flutter::EncodableValue("Popup window handle unavailable");
    return response;
  }
  if (!popup_event_sink_) {
    response[flutter::EncodableValue("success")] = flutter::EncodableValue(false);
    response[flutter::EncodableValue("fallbackUsed")] =
        flutter::EncodableValue(true);
    response[flutter::EncodableValue("reason")] =
        flutter::EncodableValue("Popup event sink unavailable");
    return response;
  }

  HMONITOR monitor = MonitorFromPoint(cursor, MONITOR_DEFAULTTONEAREST);
  MONITORINFO monitor_info{};
  monitor_info.cbSize = sizeof(MONITORINFO);
  if (!GetMonitorInfo(monitor, &monitor_info)) {
    response[flutter::EncodableValue("success")] = flutter::EncodableValue(false);
    response[flutter::EncodableValue("fallbackUsed")] =
        flutter::EncodableValue(true);
    response[flutter::EncodableValue("reason")] =
        flutter::EncodableValue("GetMonitorInfo failed");
    return response;
  }

  const UINT dpi = ResolveDpiForPoint(cursor);
  const double scale = dpi > 0 ? static_cast<double>(dpi) / 96.0 : 1.0;
  const int window_width = std::max(
      1, static_cast<int>((popup_width + (kWindowPadding * 2.0)) * scale));
  const int window_height = std::max(
      1, static_cast<int>((popup_height + (kWindowPadding * 2.0)) * scale));
  const int logical_offset_x = static_cast<int>(offset_x * scale);
  const int logical_offset_y = static_cast<int>(offset_y * scale);

  const int min_x = static_cast<int>(monitor_info.rcWork.left);
  const int min_y = static_cast<int>(monitor_info.rcWork.top);
  const int max_x =
      std::max(min_x, static_cast<int>(monitor_info.rcWork.right) - window_width);
  const int max_y = std::max(
      min_y, static_cast<int>(monitor_info.rcWork.bottom) - window_height);
  const int preferred_x = cursor.x + logical_offset_x;
  const int preferred_y = cursor.y + logical_offset_y;
  const int clamped_x = std::clamp(preferred_x, min_x, max_x);
  const int clamped_y = std::clamp(preferred_y, min_y, max_y);

  flutter::EncodableMap payload;
  payload[flutter::EncodableValue("requestId")] =
      flutter::EncodableValue(next_request_id_++);
  payload[flutter::EncodableValue("mode")] = flutter::EncodableValue(mode);
  payload[flutter::EncodableValue("cursorX")] =
      flutter::EncodableValue(static_cast<double>(cursor.x));
  payload[flutter::EncodableValue("cursorY")] =
      flutter::EncodableValue(static_cast<double>(cursor.y));
  if (region.has_value()) {
    payload[flutter::EncodableValue("regionLeft")] =
        flutter::EncodableValue(static_cast<double>(region->left));
    payload[flutter::EncodableValue("regionTop")] =
        flutter::EncodableValue(static_cast<double>(region->top));
    payload[flutter::EncodableValue("regionWidth")] = flutter::EncodableValue(
        static_cast<double>(region->right - region->left));
    payload[flutter::EncodableValue("regionHeight")] = flutter::EncodableValue(
        static_cast<double>(region->bottom - region->top));
  }
  if (!selected_text.empty()) {
    payload[flutter::EncodableValue("selectedText")] =
        flutter::EncodableValue(selected_text);
  }
  if (!source_app.empty()) {
    payload[flutter::EncodableValue("sourceApp")] =
        flutter::EncodableValue(source_app);
  }
  if (!native_language.empty()) {
    payload[flutter::EncodableValue("nativeLanguage")] =
        flutter::EncodableValue(native_language);
  }
  if (!source_languages.empty()) {
    flutter::EncodableList sources;
    sources.reserve(source_languages.size());
    for (const auto& code : source_languages) {
      sources.emplace_back(flutter::EncodableValue(code));
    }
    payload[flutter::EncodableValue("sourceLanguages")] =
        flutter::EncodableValue(sources);
  }
  if (!tag_suggestions.empty()) {
    flutter::EncodableList suggestions;
    suggestions.reserve(tag_suggestions.size());
    for (const auto& tag : tag_suggestions) {
      suggestions.emplace_back(flutter::EncodableValue(tag));
    }
    payload[flutter::EncodableValue("tagSuggestions")] =
        flutter::EncodableValue(suggestions);
  }

  popup_event_sink_->Success(flutter::EncodableValue(payload));

  const bool positioned = SetWindowPos(
      hwnd, HWND_TOPMOST, clamped_x, clamped_y, window_width, window_height,
      SWP_NOACTIVATE | SWP_SHOWWINDOW | SWP_FRAMECHANGED);
  const bool shown = ShowNoActivate();
  if (!positioned || !shown) {
    response[flutter::EncodableValue("success")] = flutter::EncodableValue(false);
    response[flutter::EncodableValue("fallbackUsed")] =
        flutter::EncodableValue(true);
    response[flutter::EncodableValue("reason")] =
        flutter::EncodableValue("SetWindowPos/ShowNoActivate failed");
    return response;
  }

  response[flutter::EncodableValue("success")] = flutter::EncodableValue(true);
  popup_visible_ = true;
  InstallOutsideClickHook();
  response[flutter::EncodableValue("fallbackUsed")] =
      flutter::EncodableValue(false);
  response[flutter::EncodableValue("reason")] = flutter::EncodableValue("");
  response[flutter::EncodableValue("contentLeft")] = flutter::EncodableValue(
      static_cast<int>(kWindowPadding * scale));
  response[flutter::EncodableValue("contentTop")] = flutter::EncodableValue(
      static_cast<int>(kWindowPadding * scale));
  response[flutter::EncodableValue("scale")] = flutter::EncodableValue(scale);
  return response;
}

flutter::EncodableMap PopupFlutterWindow::SetPopupFrameSize(
    double popup_width,
    double popup_height) {
  flutter::EncodableMap response;
  const HWND hwnd = GetHandle();
  if (hwnd == nullptr) {
    response[flutter::EncodableValue("success")] = flutter::EncodableValue(false);
    response[flutter::EncodableValue("reason")] =
        flutter::EncodableValue("Popup window handle unavailable");
    return response;
  }

  RECT wr{};
  if (!GetWindowRect(hwnd, &wr)) {
    response[flutter::EncodableValue("success")] = flutter::EncodableValue(false);
    response[flutter::EncodableValue("reason")] =
        flutter::EncodableValue("GetWindowRect failed");
    return response;
  }

  const POINT center{(wr.left + wr.right) / 2, (wr.top + wr.bottom) / 2};
  HMONITOR monitor = MonitorFromPoint(center, MONITOR_DEFAULTTONEAREST);
  MONITORINFO monitor_info{};
  monitor_info.cbSize = sizeof(MONITORINFO);
  if (!GetMonitorInfo(monitor, &monitor_info)) {
    response[flutter::EncodableValue("success")] = flutter::EncodableValue(false);
    response[flutter::EncodableValue("reason")] =
        flutter::EncodableValue("GetMonitorInfo failed");
    return response;
  }

  const UINT dpi = ResolveDpiForPoint(center);
  const double scale = dpi > 0 ? static_cast<double>(dpi) / 96.0 : 1.0;
  const int window_width = std::max(
      1, static_cast<int>((popup_width + (kWindowPadding * 2.0)) * scale));
  const int window_height = std::max(
      1, static_cast<int>((popup_height + (kWindowPadding * 2.0)) * scale));

  const int min_x = static_cast<int>(monitor_info.rcWork.left);
  const int min_y = static_cast<int>(monitor_info.rcWork.top);
  const int max_x =
      std::max(min_x, static_cast<int>(monitor_info.rcWork.right) - window_width);
  const int max_y = std::max(
      min_y, static_cast<int>(monitor_info.rcWork.bottom) - window_height);
  const int preferred_x = static_cast<int>(wr.left);
  const int preferred_y = static_cast<int>(wr.top);
  const int clamped_x = std::clamp(preferred_x, min_x, max_x);
  const int clamped_y = std::clamp(preferred_y, min_y, max_y);

  const bool positioned = SetWindowPos(
      hwnd, HWND_TOPMOST, clamped_x, clamped_y, window_width, window_height,
      SWP_NOACTIVATE | SWP_SHOWWINDOW | SWP_FRAMECHANGED);
  if (!positioned) {
    response[flutter::EncodableValue("success")] = flutter::EncodableValue(false);
    response[flutter::EncodableValue("reason")] =
        flutter::EncodableValue("SetWindowPos failed");
    return response;
  }

  response[flutter::EncodableValue("success")] = flutter::EncodableValue(true);
  response[flutter::EncodableValue("reason")] = flutter::EncodableValue("ok");
  return response;
}

flutter::EncodableMap PopupFlutterWindow::HidePopupWindow() {
  flutter::EncodableMap response;
  const HWND hwnd = GetHandle();
  if (hwnd == nullptr) {
    response[flutter::EncodableValue("success")] = flutter::EncodableValue(false);
    response[flutter::EncodableValue("fallbackUsed")] =
        flutter::EncodableValue(true);
    response[flutter::EncodableValue("reason")] =
        flutter::EncodableValue("Popup window handle unavailable");
    return response;
  }

  // Keep the window alive but move it off-screen so the Flutter engine keeps
  // rendering and holds the event channel subscription. Do not call SW_HIDE
  // because a hidden window would pause first-frame work on a fresh reopen.
  SetWindowPos(hwnd, HWND_TOPMOST, -32000, -32000, 1, 1,
               SWP_NOACTIVATE | SWP_NOREDRAW);
  popup_visible_ = false;
  UninstallOutsideClickHook();
  response[flutter::EncodableValue("success")] = flutter::EncodableValue(true);
  response[flutter::EncodableValue("fallbackUsed")] =
      flutter::EncodableValue(false);
  response[flutter::EncodableValue("reason")] = flutter::EncodableValue("ok");
  return response;
}

void PopupFlutterWindow::OnDestroy() {
  popup_visible_ = false;
  UninstallOutsideClickHook();
  popup_event_sink_.reset();
  popup_event_channel_.reset();
  popup_control_method_channel_.reset();
  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }
  Win32Window::OnDestroy();
}

LRESULT PopupFlutterWindow::MessageHandler(HWND hwnd,
                                           UINT const message,
                                           WPARAM const wparam,
                                           LPARAM const lparam) noexcept {
  if (message == kMsgHideFromOutsideClick) {
    HidePopupWindow();
    return 0;
  }
  if (message == WM_ACTIVATEAPP) {
    if (wparam == FALSE) {
      HidePopupWindow();
      return 0;
    }
  }

  if (message == WM_ACTIVATE) {
    const UINT state = LOWORD(wparam);
    if (state == WA_INACTIVE) {
      HidePopupWindow();
      return 0;
    }
  }

  if (message == WM_MOUSEACTIVATE) {
    return MA_ACTIVATE;
  }

  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      return *result;
    }
  }

  if (message == WM_FONTCHANGE && flutter_controller_) {
    flutter_controller_->engine()->ReloadSystemFonts();
    return 0;
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}

UINT PopupFlutterWindow::ResolveDpiForPoint(POINT point) {
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
