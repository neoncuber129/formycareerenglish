#include "selection_host_bridge.h"

#include <cstdio>
#include <random>
#include <vector>

namespace {

constexpr DWORD kPipeBufferBytes = 65536;
constexpr DWORD kMaxPayload = 512 * 1024;

bool ReadExact(HANDLE handle, void* buffer, size_t total) {
  auto* bytes = static_cast<uint8_t*>(buffer);
  size_t got = 0;
  while (got < total) {
    DWORD chunk = 0;
    if (!::ReadFile(handle, bytes + got, static_cast<DWORD>(total - got), &chunk,
                    nullptr)) {
      return false;
    }
    if (chunk == 0) {
      return false;
    }
    got += chunk;
  }
  return true;
}

}  // namespace

SelectionHostBridge::SelectionHostBridge() = default;

SelectionHostBridge::~SelectionHostBridge() {
  Stop();
}

void SelectionHostBridge::SetSink(
    std::unique_ptr<flutter::EventSink<flutter::EncodableValue>> sink) {
  std::lock_guard<std::mutex> lock(sink_mutex_);
  sink_ = std::move(sink);
}

void SelectionHostBridge::ClearSink() {
  std::lock_guard<std::mutex> lock(sink_mutex_);
  sink_.reset();
}

bool SelectionHostBridge::HasSink() const {
  std::lock_guard<std::mutex> lock(sink_mutex_);
  return sink_ != nullptr;
}

void SelectionHostBridge::PublishExternalSelection(const std::string& utf8) {
  if (utf8.empty()) {
    return;
  }
  PublishSelection(utf8);
}

void SelectionHostBridge::PublishSelection(const std::string& utf8) {
  std::lock_guard<std::mutex> lock(sink_mutex_);
  if (!sink_) {
    return;
  }
  flutter::EncodableMap payload;
  payload[flutter::EncodableValue("selectedText")] =
      flutter::EncodableValue(utf8);
  sink_->Success(flutter::EncodableValue(payload));
}

std::wstring SelectionHostBridge::HostExecutablePath() {
  wchar_t module[MAX_PATH]{};
  const DWORD n = ::GetModuleFileNameW(nullptr, module, MAX_PATH);
  if (n == 0 || n >= MAX_PATH) {
    return L"";
  }
  std::wstring path(module, n);
  const auto slash = path.find_last_of(L"\\/");
  if (slash == std::wstring::npos) {
    return L"";
  }
  return path.substr(0, slash + 1) + L"Formycareer.SelectionHost.exe";
}

void SelectionHostBridge::AssignPipeNames() {
  const DWORD pid = ::GetCurrentProcessId();
  std::random_device rd;
  std::mt19937 gen(rd());
  std::uniform_int_distribution<uint32_t> dist(0, 0xFFFFFFFFu);
  wchar_t name[128]{};
  swprintf_s(name, L"FMC_Sel_%lu_%08X", static_cast<unsigned long>(pid),
             static_cast<unsigned int>(dist(gen)));
  pipe_name_token_ = name;
  pipe_path_ = std::wstring(L"\\\\.\\pipe\\") + pipe_name_token_;
}

bool SelectionHostBridge::Start(HWND main_window,
                                HWND popup_window,
                                bool spawn_uia_host) {
  Stop();
  if (!spawn_uia_host) {
    return true;
  }

  stop_requested_.store(false);
  AssignPipeNames();

  pipe_handle_ = ::CreateNamedPipeW(
      pipe_path_.c_str(), PIPE_ACCESS_INBOUND,
      PIPE_TYPE_BYTE | PIPE_READMODE_BYTE | PIPE_WAIT, 1, kPipeBufferBytes,
      kPipeBufferBytes, 0, nullptr);
  if (pipe_handle_ == INVALID_HANDLE_VALUE) {
    return false;
  }

  reader_thread_ = std::thread(&SelectionHostBridge::ReaderThreadMain, this);

  const std::wstring exe = HostExecutablePath();
  if (exe.empty()) {
    Stop();
    return false;
  }

  wchar_t cmd[1024]{};
  swprintf_s(cmd, LR"("%s" "%s" %p %p)", exe.c_str(), pipe_name_token_.c_str(),
             reinterpret_cast<void*>(main_window),
             reinterpret_cast<void*>(popup_window));

  STARTUPINFOW si{};
  si.cb = sizeof(si);
  PROCESS_INFORMATION pi{};
  std::vector<wchar_t> cmd_buf(cmd, cmd + wcslen(cmd) + 1);
  std::wstring work_dir;
  const auto slash = exe.find_last_of(L"\\/");
  if (slash != std::wstring::npos) {
    work_dir = exe.substr(0, slash);
  }

  const BOOL ok = ::CreateProcessW(
      exe.c_str(), cmd_buf.data(), nullptr, nullptr, FALSE,
      CREATE_NO_WINDOW | DETACHED_PROCESS, nullptr,
      work_dir.empty() ? nullptr : work_dir.c_str(), &si, &pi);
  if (!ok) {
    Stop();
    return false;
  }
  ::CloseHandle(pi.hThread);
  process_handle_ = pi.hProcess;
  return true;
}

void SelectionHostBridge::Stop() {
  stop_requested_.store(true);
  if (pipe_handle_ != INVALID_HANDLE_VALUE) {
    ::CancelIoEx(pipe_handle_, nullptr);
  }
  if (reader_thread_.joinable()) {
    reader_thread_.join();
  }
  if (pipe_handle_ != INVALID_HANDLE_VALUE) {
    ::DisconnectNamedPipe(pipe_handle_);
    ::CloseHandle(pipe_handle_);
    pipe_handle_ = INVALID_HANDLE_VALUE;
  }
  if (process_handle_ != nullptr) {
    ::TerminateProcess(process_handle_, 0);
    ::CloseHandle(process_handle_);
    process_handle_ = nullptr;
  }
}

void SelectionHostBridge::ReaderThreadMain() {
  if (pipe_handle_ == INVALID_HANDLE_VALUE) {
    return;
  }
  if (!::ConnectNamedPipe(pipe_handle_, nullptr)) {
    const DWORD err = ::GetLastError();
    if (err != ERROR_PIPE_CONNECTED) {
      return;
    }
  }

  while (!stop_requested_.load()) {
    uint32_t len = 0;
    if (!ReadExact(pipe_handle_, &len, sizeof(len))) {
      break;
    }
    if (len == 0 || len > kMaxPayload) {
      break;
    }
    std::string utf8(len, '\0');
    if (!ReadExact(pipe_handle_, utf8.data(), len)) {
      break;
    }
    PublishSelection(utf8);
  }
}
