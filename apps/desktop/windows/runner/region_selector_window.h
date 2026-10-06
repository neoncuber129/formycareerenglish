#ifndef RUNNER_REGION_SELECTOR_WINDOW_H_
#define RUNNER_REGION_SELECTOR_WINDOW_H_

#include <windows.h>

#include <functional>
#include <memory>

// A fullscreen transparent top-most window that lets the user drag a
// rectangle to select a screen region. Used as the first step of the image
// OCR flow.
//
// The window creates itself, handles all input, and invokes |callback| on the
// main thread once the user confirms or cancels the selection. The selector
// then destroys itself. Lifetime management is self-contained: callers just
// invoke Show().
class RegionSelectorWindow {
 public:
  // Callback is invoked with |success=true| and the selected rectangle in
  // virtual-screen coordinates, or |success=false| when the user cancels.
  using CompletionCallback =
      std::function<void(bool success, RECT selection)>;

  // Creates and displays the selector. Returns true on successful creation.
  // Only one selector may be active at a time; subsequent calls while another
  // selector is alive return false without invoking |callback|.
  static bool Show(CompletionCallback callback);

  // Win32 window-class name used for the selector. Exposed publicly so that
  // the class-registration helper can reference it from the translation unit.
  static const wchar_t* const kWindowClassName;

  static LRESULT CALLBACK WndProc(HWND hwnd, UINT message, WPARAM wparam,
                                  LPARAM lparam);

  ~RegionSelectorWindow();

 private:
  RegionSelectorWindow();

  bool Initialize(CompletionCallback callback);
  void Complete(bool success);

  LRESULT HandleMessage(UINT message, WPARAM wparam, LPARAM lparam);
  void PaintOverlay(HDC hdc);

  HWND hwnd_ = nullptr;
  POINT start_{};
  POINT current_{};
  RECT virtual_screen_{};
  bool dragging_ = false;
  bool completed_ = false;
  CompletionCallback callback_;

  static std::unique_ptr<RegionSelectorWindow> s_active_instance_;
};

#endif  // RUNNER_REGION_SELECTOR_WINDOW_H_
