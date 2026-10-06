using System.Runtime.InteropServices;
using System.Text;
using System.Windows.Automation;

namespace Formycareer.UiaSelection;

/// <summary>
/// Subscribes to UI Automation text selection changes and invokes a callback with UTF-16 text.
/// Must run on an STA thread with a Win32 message pump.
/// </summary>
public sealed class TextSelectionUiaWatcher : IDisposable
{
    private readonly nint _mainHwnd;
    private readonly nint _popupHwnd;
    private readonly Action<string> _onSelectedText;
    private readonly int _minChars;
    private readonly int _debounceMs;
    private AutomationEventHandler? _selectionHandler;
    private AutomationFocusChangedEventHandler? _focusHandler;
    private System.Windows.Forms.Timer? _debounceTimer;
    private string _pendingText = string.Empty;
    private readonly object _pendingLock = new();
    private bool _disposed;

    public TextSelectionUiaWatcher(
        nint mainHwnd,
        nint popupHwnd,
        Action<string> onSelectedText,
        int minChars = 1,
        int debounceMs = 320)
    {
        _mainHwnd = mainHwnd;
        _popupHwnd = popupHwnd;
        _onSelectedText = onSelectedText;
        _minChars = minChars;
        _debounceMs = debounceMs;
    }

    public void Start()
    {
        _selectionHandler = OnTextSelectionChanged;
        Automation.AddAutomationEventHandler(
            TextPattern.TextSelectionChangedEvent,
            AutomationElement.RootElement,
            TreeScope.Subtree,
            _selectionHandler);

        _focusHandler = OnFocusChanged;
        Automation.AddAutomationFocusChangedEventHandler(_focusHandler);

        _debounceTimer = new System.Windows.Forms.Timer { Interval = _debounceMs };
        _debounceTimer.Tick += (_, _) =>
        {
            _debounceTimer!.Stop();
            string t;
            lock (_pendingLock)
            {
                t = _pendingText;
                _pendingText = string.Empty;
            }

            if (t.Length >= _minChars)
            {
                _onSelectedText(t);
            }
        };
    }

    private void ScheduleEmit(string text)
    {
        if (string.IsNullOrEmpty(text))
        {
            return;
        }

        if (text.Length < _minChars)
        {
            return;
        }

        lock (_pendingLock)
        {
            _pendingText = text;
        }

        _debounceTimer?.Stop();
        _debounceTimer?.Start();
    }

    private bool ShouldIgnoreForeground()
    {
        var fg = GetForegroundWindow();
        if (fg == nint.Zero)
        {
            return true;
        }

        if (_mainHwnd != nint.Zero && fg == _mainHwnd)
        {
            return true;
        }

        if (_popupHwnd != nint.Zero && fg == _popupHwnd)
        {
            return true;
        }

        return false;
    }

    private static string? TryReadSelection(AutomationElement element)
    {
        try
        {
            if (!element.TryGetCurrentPattern(TextPattern.Pattern, out var patternObj) ||
                patternObj is not TextPattern pattern)
            {
                return null;
            }

            var ranges = pattern.GetSelection();
            if (ranges == null || ranges.Length == 0)
            {
                return null;
            }

            var sb = new StringBuilder();
            foreach (var range in ranges)
            {
                try
                {
                    var chunk = range.GetText(-1);
                    if (!string.IsNullOrEmpty(chunk))
                    {
                        sb.Append(chunk);
                    }
                }
                catch (ElementNotAvailableException)
                {
                    // ignore
                }
            }

            return sb.Length == 0 ? null : sb.ToString();
        }
        catch (ElementNotAvailableException)
        {
            return null;
        }
    }

    private void OnTextSelectionChanged(object sender, AutomationEventArgs e)
    {
        if (_disposed || ShouldIgnoreForeground())
        {
            return;
        }

        if (sender is not AutomationElement element)
        {
            return;
        }

        var text = TryReadSelection(element);
        if (string.IsNullOrEmpty(text))
        {
            return;
        }

        ScheduleEmit(text.Trim());
    }

    private void OnFocusChanged(object sender, AutomationFocusChangedEventArgs e)
    {
        if (_disposed || ShouldIgnoreForeground())
        {
            return;
        }

        try
        {
            var focused = AutomationElement.FocusedElement;
            if (focused == null)
            {
                return;
            }

            var text = TryReadSelection(focused);
            if (!string.IsNullOrEmpty(text) && text.Trim().Length >= _minChars)
            {
                ScheduleEmit(text.Trim());
            }
        }
        catch (ElementNotAvailableException)
        {
            // ignore
        }
    }

    public void Dispose()
    {
        if (_disposed)
        {
            return;
        }

        _disposed = true;
        _debounceTimer?.Stop();
        _debounceTimer?.Dispose();
        _debounceTimer = null;

        if (_selectionHandler != null)
        {
            try
            {
                Automation.RemoveAutomationEventHandler(
                    TextPattern.TextSelectionChangedEvent,
                    AutomationElement.RootElement,
                    _selectionHandler);
            }
            catch
            {
                // ignore
            }

            _selectionHandler = null;
        }

        if (_focusHandler != null)
        {
            try
            {
                Automation.RemoveAutomationFocusChangedEventHandler(_focusHandler);
            }
            catch
            {
                // ignore
            }

            _focusHandler = null;
        }
    }

    [DllImport("user32.dll")]
    private static extern nint GetForegroundWindow();
}
