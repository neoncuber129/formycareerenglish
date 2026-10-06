#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include "flutter_window.h"
#include "popup_flutter_window.h"
#include "utils.h"

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();
  std::vector<std::string> popup_command_line_arguments = command_line_arguments;

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);
  flutter::DartProject popup_project(L"data");
  popup_project.set_dart_entrypoint("overlayMain");
  popup_project.set_dart_entrypoint_arguments(
      std::move(popup_command_line_arguments));
  PopupFlutterWindow popup_window(popup_project);
  Win32Window::Point origin(10, 10);
  Win32Window::Size size(1280, 720);
  if (!window.Create(L"desktop", origin, size)) {
    return EXIT_FAILURE;
  }
  window.SetPopupWindow(&popup_window);
  popup_window.SetMainWindow(&window);
  Win32Window::Point popup_origin(0, 0);
  Win32Window::Size popup_size(344, 214);
  if (!popup_window.Create(L"desktop_popup", popup_origin, popup_size)) {
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    if (msg.message == WM_HOTKEY) {
      // Hotkeys registered with hWnd = nullptr are posted to the thread queue.
      // Forward them to the Flutter runner window so existing channel logic can
      // publish hotkey events into Dart.
      const HWND hwnd = window.GetHandle();
      if (hwnd != nullptr) {
        ::SendMessage(hwnd, WM_HOTKEY, msg.wParam, msg.lParam);
      }
      continue;
    }
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  return EXIT_SUCCESS;
}
