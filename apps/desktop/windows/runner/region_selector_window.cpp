#include "region_selector_window.h"

#include <windowsx.h>

#include <algorithm>
#include <utility>

std::unique_ptr<RegionSelectorWindow> RegionSelectorWindow::s_active_instance_;
const wchar_t* const RegionSelectorWindow::kWindowClassName =
    L"FormyCareerRegionSelector";

namespace {
constexpr BYTE kOverlayAlpha = 110;
constexpr int kMinimumSelectionPixels = 6;

void EnsureClassRegistered(HINSTANCE hinstance) {
  WNDCLASSEXW wc{};
  if (GetClassInfoExW(hinstance, RegionSelectorWindow::kWindowClassName, &wc)) {
    return;
  }
  wc = {};
  wc.cbSize = sizeof(WNDCLASSEXW);
  wc.style = CS_HREDRAW | CS_VREDRAW;
  wc.lpfnWndProc = RegionSelectorWindow::WndProc;
  wc.hInstance = hinstance;
  wc.hCursor = LoadCursor(nullptr, IDC_CROSS);
  wc.hbrBackground = nullptr;
  wc.lpszClassName = RegionSelectorWindow::kWindowClassName;
  RegisterClassExW(&wc);
}

RECT NormalizedRect(POINT a, POINT b) {
  RECT rc;
  rc.left = std::min(a.x, b.x);
  rc.top = std::min(a.y, b.y);
  rc.right = std::max(a.x, b.x);
  rc.bottom = std::max(a.y, b.y);
  return rc;
}

}  // namespace

// static
bool RegionSelectorWindow::Show(CompletionCallback callback) {
  if (s_active_instance_) {
    return false;
  }
  std::unique_ptr<RegionSelectorWindow> instance(new RegionSelectorWindow());
  if (!instance->Initialize(std::move(callback))) {
    return false;
  }
  s_active_instance_ = std::move(instance);
  return true;
}

RegionSelectorWindow::RegionSelectorWindow() = default;

RegionSelectorWindow::~RegionSelectorWindow() {
  if (hwnd_ != nullptr) {
    DestroyWindow(hwnd_);
    hwnd_ = nullptr;
  }
}

bool RegionSelectorWindow::Initialize(CompletionCallback callback) {
  callback_ = std::move(callback);
  HINSTANCE hinstance = GetModuleHandleW(nullptr);
  EnsureClassRegistered(hinstance);

  virtual_screen_.left = GetSystemMetrics(SM_XVIRTUALSCREEN);
  virtual_screen_.top = GetSystemMetrics(SM_YVIRTUALSCREEN);
  virtual_screen_.right = virtual_screen_.left +
                          GetSystemMetrics(SM_CXVIRTUALSCREEN);
  virtual_screen_.bottom = virtual_screen_.top +
                           GetSystemMetrics(SM_CYVIRTUALSCREEN);

  const DWORD ex_style =
      WS_EX_TOPMOST | WS_EX_TOOLWINDOW | WS_EX_LAYERED;
  const DWORD style = WS_POPUP;

  hwnd_ = CreateWindowExW(
      ex_style, kWindowClassName, L"FormyCareer Region Selector", style,
      virtual_screen_.left, virtual_screen_.top,
      virtual_screen_.right - virtual_screen_.left,
      virtual_screen_.bottom - virtual_screen_.top, nullptr, nullptr,
      hinstance, this);
  if (hwnd_ == nullptr) {
    return false;
  }

  SetLayeredWindowAttributes(hwnd_, 0, kOverlayAlpha, LWA_ALPHA);
  ShowWindow(hwnd_, SW_SHOW);
  UpdateWindow(hwnd_);
  SetForegroundWindow(hwnd_);
  SetFocus(hwnd_);
  return true;
}

void RegionSelectorWindow::Complete(bool success) {
  if (completed_) {
    return;
  }
  completed_ = true;

  RECT selection{};
  if (success) {
    selection = NormalizedRect(start_, current_);
    if ((selection.right - selection.left) < kMinimumSelectionPixels ||
        (selection.bottom - selection.top) < kMinimumSelectionPixels) {
      success = false;
    } else {
      // Translate client coords to virtual-screen coords for OCR callers.
      OffsetRect(&selection, virtual_screen_.left, virtual_screen_.top);
    }
  }

  CompletionCallback cb = std::move(callback_);
  if (hwnd_ != nullptr) {
    HWND to_destroy = hwnd_;
    hwnd_ = nullptr;
    DestroyWindow(to_destroy);
  }

  // Tear down the active instance before invoking the callback so that
  // re-entrant Show() calls from the callback are allowed.
  auto self = std::move(s_active_instance_);
  if (cb) {
    cb(success, selection);
  }
  // |self| (this) is destroyed on scope exit.
}

// static
LRESULT CALLBACK RegionSelectorWindow::WndProc(HWND hwnd, UINT message,
                                               WPARAM wparam, LPARAM lparam) {
  RegionSelectorWindow* self = nullptr;
  if (message == WM_NCCREATE) {
    auto* cs = reinterpret_cast<CREATESTRUCTW*>(lparam);
    self = static_cast<RegionSelectorWindow*>(cs->lpCreateParams);
    SetWindowLongPtrW(hwnd, GWLP_USERDATA, reinterpret_cast<LONG_PTR>(self));
    if (self != nullptr) {
      self->hwnd_ = hwnd;
    }
  } else {
    self = reinterpret_cast<RegionSelectorWindow*>(
        GetWindowLongPtrW(hwnd, GWLP_USERDATA));
  }

  if (self != nullptr) {
    return self->HandleMessage(message, wparam, lparam);
  }
  return DefWindowProcW(hwnd, message, wparam, lparam);
}

LRESULT RegionSelectorWindow::HandleMessage(UINT message, WPARAM wparam,
                                            LPARAM lparam) {
  switch (message) {
    case WM_LBUTTONDOWN: {
      POINT pt{GET_X_LPARAM(lparam), GET_Y_LPARAM(lparam)};
      start_ = pt;
      current_ = pt;
      dragging_ = true;
      SetCapture(hwnd_);
      InvalidateRect(hwnd_, nullptr, FALSE);
      return 0;
    }
    case WM_MOUSEMOVE: {
      if (dragging_) {
        current_.x = GET_X_LPARAM(lparam);
        current_.y = GET_Y_LPARAM(lparam);
        InvalidateRect(hwnd_, nullptr, FALSE);
      }
      return 0;
    }
    case WM_LBUTTONUP: {
      if (dragging_) {
        dragging_ = false;
        ReleaseCapture();
        current_.x = GET_X_LPARAM(lparam);
        current_.y = GET_Y_LPARAM(lparam);
        Complete(true);
      }
      return 0;
    }
    case WM_RBUTTONDOWN: {
      Complete(false);
      return 0;
    }
    case WM_KEYDOWN: {
      if (wparam == VK_ESCAPE) {
        Complete(false);
        return 0;
      }
      return 0;
    }
    case WM_PAINT: {
      PAINTSTRUCT ps;
      HDC hdc = BeginPaint(hwnd_, &ps);
      PaintOverlay(hdc);
      EndPaint(hwnd_, &ps);
      return 0;
    }
    case WM_ERASEBKGND:
      return 1;
    case WM_DESTROY: {
      SetWindowLongPtrW(hwnd_, GWLP_USERDATA, 0);
      return 0;
    }
    default:
      break;
  }
  return DefWindowProcW(hwnd_, message, wparam, lparam);
}

void RegionSelectorWindow::PaintOverlay(HDC hdc) {
  RECT client;
  GetClientRect(hwnd_, &client);

  HBRUSH background = CreateSolidBrush(RGB(0, 0, 0));
  FillRect(hdc, &client, background);
  DeleteObject(background);

  if (dragging_ || (start_.x != current_.x || start_.y != current_.y)) {
    RECT selection = NormalizedRect(start_, current_);

    HBRUSH highlight = CreateSolidBrush(RGB(255, 255, 255));
    FillRect(hdc, &selection, highlight);
    DeleteObject(highlight);

    HPEN pen = CreatePen(PS_SOLID, 2, RGB(0, 180, 255));
    HGDIOBJ old_pen = SelectObject(hdc, pen);
    HGDIOBJ old_brush = SelectObject(hdc, GetStockObject(NULL_BRUSH));
    Rectangle(hdc, selection.left, selection.top, selection.right,
              selection.bottom);
    SelectObject(hdc, old_pen);
    SelectObject(hdc, old_brush);
    DeleteObject(pen);
  }

  // Hint text at top-left.
  SetBkMode(hdc, TRANSPARENT);
  SetTextColor(hdc, RGB(255, 255, 255));
  const wchar_t* hint = L"Drag to select region  -  Esc to cancel";
  TextOutW(hdc, 24, 24, hint, lstrlenW(hint));
}
