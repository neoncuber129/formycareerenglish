# Formycareer.SelectionHost (Windows UI Automation)

Small .NET 8 **Windows** helper that listens for text selection changes via **UI Automation**, debounces them, and sends UTF-8 length-framed payloads to the Flutter **Windows runner** over a **named pipe**. The runner forwards events to Dart on `EventChannel('formycareer/system_text_selection')`.

## Projects

| Project | Role |
|--------|------|
| `Formycareer.UiaSelection` | Class library: `TextSelectionUiaWatcher` (STA, UIA handlers, debounce). |
| `Formycareer.SelectionHost` | WinExe: message pump, named-pipe client, hosts the watcher. |

## Build (manual)

From this directory:

```bash
dotnet build Formycareer.SelectionHost/Formycareer.SelectionHost.csproj -c Release
```

Publish a **framework-dependent** `win-x64` layout (matches CMake post-build):

```bash
dotnet publish Formycareer.SelectionHost/Formycareer.SelectionHost.csproj -c Release -r win-x64 --self-contained false -o out
```

The app host machine must have the **.NET 8 (or compatible) desktop/runtime** installed unless you switch CMake to `--self-contained true` (larger output).

## Integration

- [apps/desktop/windows/runner/CMakeLists.txt](../../apps/desktop/windows/runner/CMakeLists.txt) runs `dotnet publish` on each **POST_BUILD** of `desktop.exe` and copies `Formycareer.SelectionHost.exe`, `*.dll`, `*.deps.json`, and `*.runtimeconfig.json` next to the runner executable.
- If `dotnet` is not on `PATH`, the Windows build step fails at link/post-build; install the [.NET SDK 8](https://dotnet.microsoft.com/download/dotnet/8.0).

## Pipe protocol (host → runner)

1. Little-endian `uint32_t` length of UTF-8 payload (must be `> 0` and `<= 524288`).
2. `length` bytes of UTF-8 text.

## Command line

```
Formycareer.SelectionHost.exe "<PipeNameToken>" <MainHwndHex> <PopupHwndHex>
```

`PipeNameToken` is the segment after `\\.\pipe\` (e.g. `FMC_Sel_12345_ABC`). HWNDs are hexadecimal (`%p` style from the C++ runner).

## Limitations

- **Chromium / Electron** (including Google Chrome) often expose little or no UIA text selection to third-party watchers; the SelectionHost may stay silent even when the user selects text.
- Not every application exposes `TextPattern` / selection events; **Ctrl+Shift+D** remains the manual fallback.
- Listening is active only while Dart holds a subscription on `formycareer/system_text_selection` (see Capture tab: **Auto capture**).

## Runner-side selection (same EventChannel)

The desktop app currently drives the channel **without** starting `Formycareer.SelectionHost.exe` and **without** the clipboard listener: when **Auto capture** is on, Dart passes `useUiaSelectionHost: false`, `clipboardListen: false`, and `dragSendCtrlC: true` so only the low-level mouse path below is active.

| Path | Behavior (current app defaults) |
|------|--------------------------------|
| **Drag → Ctrl+C** | Low-level mouse hook: after a left-button **drag** past a small distance, or a **double-click** word-select gesture (timing/rectangle per Windows), when the pointer is **not** over the runner’s main or capture-popup window (`WindowFromPoint` + `GA_ROOT`); then a short delay and **sentinel + simulated Ctrl+C** like `showOverlayNearCursor` without prefilled text. **Can overwrite the clipboard**; use only where acceptable. |
| **UI Automation** | Code path remains in the runner for optional `useUiaSelectionHost`; the app does not enable it. |
| **Clipboard** | Code path remains for optional `clipboardListen`; the app does not enable it. |

A **browser extension** (or in-page script) that pushes selection into the app remains the most precise option where UIA is insufficient and synthetic copy is undesirable.
