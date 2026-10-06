import 'dart:io';

import 'package:win32/win32.dart';

class ForegroundSourceContext {
  const ForegroundSourceContext({
    required this.appLabel,
    required this.windowTitle,
    required this.sourceUrl,
  });

  final String appLabel;
  final String windowTitle;
  final String sourceUrl;

  String get displayLabel {
    final domain = _domainFromUrl(sourceUrl);
    final title = windowTitle.trim();
    final app = appLabel.trim();
    if (title.isNotEmpty && app.isNotEmpty && domain.isNotEmpty) {
      return '$title — $app — $domain';
    }
    if (title.isNotEmpty && app.isNotEmpty) {
      return '$title — $app';
    }
    if (title.isNotEmpty && domain.isNotEmpty) {
      return '$title — $domain';
    }
    if (title.isNotEmpty) {
      return title;
    }
    if (app.isNotEmpty && domain.isNotEmpty) {
      return '$app — $domain';
    }
    return app;
  }
}

/// Best-effort foreground window title (Windows). Used as [Vocab.sourceApp] label.
String readForegroundWindowLabel() {
  return readForegroundSourceContext().displayLabel;
}

ForegroundSourceContext readForegroundSourceContext() {
  if (Platform.isMacOS) {
    return _readMacForegroundSourceContext();
  }
  if (!Platform.isWindows) {
    return ForegroundSourceContext(
      appLabel: Platform.operatingSystem,
      windowTitle: '',
      sourceUrl: '',
    );
  }
  final hwnd = GetForegroundWindow();
  if (hwnd.address == 0) {
    return const ForegroundSourceContext(
      appLabel: '',
      windowTitle: '',
      sourceUrl: '',
    );
  }
  final len = GetWindowTextLength(hwnd).value;
  if (len <= 0) {
    return const ForegroundSourceContext(
      appLabel: '',
      windowTitle: '',
      sourceUrl: '',
    );
  }
  final buf = wsalloc(len + 1);
  try {
    GetWindowText(hwnd, buf, len + 1);
    final title = buf.toDartString().trim();
    return ForegroundSourceContext(
      appLabel: title,
      windowTitle: title,
      sourceUrl: '',
    );
  } finally {
    free(buf);
  }
}

ForegroundSourceContext _readMacForegroundSourceContext() {
  final appName = _runAppleScript(
    'tell application "System Events" to get name of first application process whose frontmost is true',
  );
  final fallbackWindowTitle = _runAppleScript(
    'tell application "System Events" to tell (first application process whose frontmost is true) to get value of attribute "AXTitle" of front window',
  );
  final fallbackWindowName = _runAppleScript(
    'tell application "System Events" to tell (first application process whose frontmost is true) to get name of front window',
  );
  final browserTitle = _readMacFrontBrowserTitle(appName);
  final browserUrl = _readMacFrontBrowserUrl(appName).trim();
  final axDocument = _normalizeAppleScriptValue(
    _runAppleScript(
      'tell application "System Events" to tell (first application process whose frontmost is true) to get value of attribute "AXDocument" of front window',
    ),
  );
  final sourceUrl = browserUrl.isNotEmpty
      ? browserUrl
      : axDocument;
  final windowTitle = browserTitle.isNotEmpty
      ? browserTitle
      : _normalizeAppleScriptValue(fallbackWindowTitle).isNotEmpty
      ? _normalizeAppleScriptValue(fallbackWindowTitle)
      : _normalizeAppleScriptValue(fallbackWindowName).isNotEmpty
      ? _normalizeAppleScriptValue(fallbackWindowName)
      : _nameFromPathLikeValue(axDocument);
  return ForegroundSourceContext(
    appLabel: appName,
    windowTitle: windowTitle,
    sourceUrl: sourceUrl,
  );
}

String _runAppleScript(String statement) {
  try {
    final result = Process.runSync('osascript', <String>[
      '-e',
      statement,
    ]);
    if (result.exitCode != 0) {
      return '';
    }
    return (result.stdout as String? ?? '').trim();
  } catch (_) {
    return '';
  }
}

String _readMacFrontBrowserUrl(String appName) {
  final app = appName.trim();
  if (app.isEmpty) {
    return '';
  }
  final script = switch (app) {
    'Google Chrome' ||
    'Chromium' ||
    'Microsoft Edge' ||
    'Brave Browser' ||
    'Arc' ||
    'Opera' =>
      'tell application "$app" to get URL of active tab of front window',
    'Safari' => 'tell application "Safari" to get URL of front document',
    _ => '',
  };
  if (script.isEmpty) {
    return '';
  }
  return _normalizeAppleScriptValue(_runAppleScript(script));
}

String _readMacFrontBrowserTitle(String appName) {
  final app = appName.trim();
  if (app.isEmpty) {
    return '';
  }
  final script = switch (app) {
    'Google Chrome' ||
    'Chromium' ||
    'Microsoft Edge' ||
    'Brave Browser' ||
    'Arc' ||
    'Opera' =>
      'tell application "$app" to get title of active tab of front window',
    'Safari' => 'tell application "Safari" to get name of front document',
    _ => '',
  };
  if (script.isEmpty) {
    return '';
  }
  return _normalizeAppleScriptValue(_runAppleScript(script));
}

String _domainFromUrl(String rawUrl) {
  final value = rawUrl.trim();
  if (value.isEmpty) {
    return '';
  }
  final uri = Uri.tryParse(value);
  if (uri == null || uri.host.trim().isEmpty) {
    return '';
  }
  final host = uri.host.toLowerCase();
  return host.startsWith('www.') ? host.substring(4) : host;
}

String _normalizeAppleScriptValue(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return '';
  }
  if (trimmed.toLowerCase() == 'missing value') {
    return '';
  }
  return trimmed;
}

String _nameFromPathLikeValue(String value) {
  final normalized = _normalizeAppleScriptValue(value);
  if (normalized.isEmpty) {
    return '';
  }
  if (normalized.startsWith('http://') || normalized.startsWith('https://')) {
    return '';
  }
  final idx = normalized.lastIndexOf('/');
  if (idx < 0 || idx >= normalized.length - 1) {
    return normalized;
  }
  return normalized.substring(idx + 1);
}
