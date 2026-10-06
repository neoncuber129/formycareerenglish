#ifndef RUNNER_SELECTION_HOST_BRIDGE_H_
#define RUNNER_SELECTION_HOST_BRIDGE_H_

#include <windows.h>

#include <atomic>
#include <memory>
#include <mutex>
#include <string>
#include <thread>

#include <flutter/encodable_value.h>
#include <flutter/event_sink.h>

// Spawns Formycareer.SelectionHost.exe, reads length-prefixed UTF-8 on a named
// pipe, and forwards { selectedText } to a Flutter EventSink.
class SelectionHostBridge {
 public:
  SelectionHostBridge();
  ~SelectionHostBridge();

  SelectionHostBridge(const SelectionHostBridge&) = delete;
  SelectionHostBridge& operator=(const SelectionHostBridge&) = delete;

  void SetSink(
      std::unique_ptr<flutter::EventSink<flutter::EncodableValue>> sink);
  void ClearSink();

  /// When |spawn_uia_host| is false, only keeps the sink for
  /// PublishExternalSelection / clipboard / hook paths (no SelectionHost.exe).
  bool Start(HWND main_window, HWND popup_window, bool spawn_uia_host);
  void Stop();

  bool HasSink() const;

  void PublishExternalSelection(const std::string& utf8);

 private:
  void ReaderThreadMain();
  void PublishSelection(const std::string& utf8);
  static std::wstring HostExecutablePath();
  void AssignPipeNames();

  std::wstring pipe_path_;
  std::wstring pipe_name_token_;
  HANDLE pipe_handle_ = INVALID_HANDLE_VALUE;
  HANDLE process_handle_ = nullptr;
  std::thread reader_thread_;
  std::atomic<bool> stop_requested_{false};

  mutable std::mutex sink_mutex_;
  std::unique_ptr<flutter::EventSink<flutter::EncodableValue>> sink_;
};

#endif  // RUNNER_SELECTION_HOST_BRIDGE_H_
