using System.Globalization;
using System.IO.Pipes;
using System.Text;
using System.Windows.Forms;
using Formycareer.UiaSelection;

namespace Formycareer.SelectionHost;

internal static class Program
{
    private const int MaxPayloadBytes = 512 * 1024;
    private static readonly object PipeGate = new();

    [STAThread]
    private static int Main(string[] args)
    {
        if (args.Length < 3)
        {
            return 1;
        }

        var pipeName = args[0];
        if (!TryParseHwnd(args[1], out var mainHwnd) || !TryParseHwnd(args[2], out var popupHwnd))
        {
            return 1;
        }

        using var pipe = new NamedPipeClientStream(
            ".",
            pipeName,
            PipeDirection.Out,
            PipeOptions.Asynchronous);

        try
        {
            pipe.Connect(20_000);
        }
        catch
        {
            return 2;
        }

        TextSelectionUiaWatcher? watcher = null;
        try
        {
            watcher = new TextSelectionUiaWatcher(
                mainHwnd,
                popupHwnd,
                text => SendUtf8(pipe, text));
            watcher.Start();
        }
        catch
        {
            return 3;
        }

        using var pump = new MessagePumpForm();
        Application.Run(pump);
        watcher.Dispose();
        return 0;
    }

    private static bool TryParseHwnd(string s, out nint hwnd)
    {
        hwnd = nint.Zero;
        if (string.IsNullOrWhiteSpace(s))
        {
            return true;
        }

        var t = s.Trim();
        if (t.StartsWith("0x", StringComparison.OrdinalIgnoreCase))
        {
            t = t[2..];
        }

        if (ulong.TryParse(
                t,
                NumberStyles.HexNumber,
                CultureInfo.InvariantCulture,
                out var u))
        {
            hwnd = unchecked((nint)u);
            return true;
        }

        return false;
    }

    private static void SendUtf8(NamedPipeClientStream pipe, string text)
    {
        if (string.IsNullOrEmpty(text))
        {
            return;
        }

        var bytes = Encoding.UTF8.GetBytes(text);
        if (bytes.Length > MaxPayloadBytes)
        {
            return;
        }

        var len = BitConverter.GetBytes((uint)bytes.Length);
        lock (PipeGate)
        {
            if (!pipe.IsConnected)
            {
                return;
            }

            pipe.Write(len, 0, 4);
            pipe.Write(bytes, 0, bytes.Length);
            pipe.Flush();
        }
    }
}

internal sealed class MessagePumpForm : Form
{
    public MessagePumpForm()
    {
        FormBorderStyle = FormBorderStyle.FixedToolWindow;
        ShowInTaskbar = false;
        Opacity = 0;
        Size = new Size(1, 1);
        StartPosition = FormStartPosition.Manual;
        Location = new Point(-32000, -32000);
    }

    protected override void SetVisibleCore(bool value)
    {
        base.SetVisibleCore(false);
    }
}
