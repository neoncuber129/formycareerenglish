import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const bool useMockOcr = bool.fromEnvironment(
  'USE_MOCK_OCR',
  defaultValue: false,
);
const bool useMethodChannelOcr = bool.fromEnvironment(
  'USE_METHOD_CHANNEL_OCR',
  defaultValue: false,
);
const bool useWindowsMediaOcr = bool.fromEnvironment(
  'USE_WINDOWS_MEDIA_OCR',
  defaultValue: false,
);

/// Language string passed to Tesseract (see
/// https://tesseract-ocr.github.io/tessdoc/Command-Line-Usage.html). Defaults
/// to English + Vietnamese; override at build time with
/// `--dart-define=TESSERACT_LANGS=eng+vie+jpn` if needed.
const String tesseractLanguages = String.fromEnvironment(
  'TESSERACT_LANGS',
  defaultValue: 'eng+vie',
);
const List<String> kTesseractStarterPack = <String>[
  'eng',
  'vie',
  'jpn',
  'kor',
  'chi_sim',
  'chi_tra',
];

class TesseractLanguagePackManager {
  TesseractLanguagePackManager._();

  static final TesseractLanguagePackManager instance =
      TesseractLanguagePackManager._();
  static const String _baseUrl =
      'https://raw.githubusercontent.com/tesseract-ocr/tessdata_fast/main';
  final Set<String> _downloading = <String>{};

  String? _resolvedCacheDir;

  String get cacheDirPath {
    _resolvedCacheDir ??= _defaultCacheDirPath();
    return _resolvedCacheDir!;
  }

  Future<void> ensureStarterPack() async {
    await ensureLanguagesAvailable(kTesseractStarterPack);
  }

  Future<void> ensureLanguagesAvailable(List<String> tesseractCodes) async {
    final normalized = tesseractCodes
        .map((code) => code.trim().toLowerCase())
        .where((code) => code.isNotEmpty)
        .toSet()
        .toList(growable: false);
    if (normalized.isEmpty) {
      return;
    }
    final dir = Directory(cacheDirPath);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    for (final code in normalized) {
      final trainedData = File(
        '${dir.path}${Platform.pathSeparator}$code.traineddata',
      );
      if (await trainedData.exists()) {
        continue;
      }
      if (_downloading.contains(code)) {
        continue;
      }
      _downloading.add(code);
      try {
        await _downloadLanguagePack(code, trainedData.path);
      } catch (error) {
        debugPrint('Tesseract language download failed ($code): $error');
      } finally {
        _downloading.remove(code);
      }
    }
  }

  Future<void> _downloadLanguagePack(String code, String destinationPath) async {
    final uri = Uri.parse('$_baseUrl/$code.traineddata');
    final client = HttpClient();
    try {
      final request = await client.getUrl(uri);
      final response = await request.close().timeout(const Duration(seconds: 20));
      if (response.statusCode != HttpStatus.ok) {
        throw HttpException(
          'HTTP ${response.statusCode} when downloading $code',
          uri: uri,
        );
      }
      final tempPath = '$destinationPath.download';
      final tempFile = File(tempPath);
      final sink = tempFile.openWrite();
      await response.pipe(sink);
      await sink.close();
      await tempFile.rename(destinationPath);
    } finally {
      client.close(force: true);
    }
  }

  String _defaultCacheDirPath() {
    if (Platform.isWindows) {
      final localAppData = Platform.environment['LOCALAPPDATA'];
      if (localAppData != null && localAppData.trim().isNotEmpty) {
        return '$localAppData\\FormyCareer\\tessdata';
      }
    }
    final home = Platform.environment['HOME'] ??
        Platform.environment['USERPROFILE'] ??
        Directory.systemTemp.path;
    return '$home${Platform.pathSeparator}.formycareer${Platform.pathSeparator}tessdata';
  }
}

abstract class OcrAdapter {
  Future<String> extractText();

  Future<String> extractTextFromRegion(Rect region) {
    return extractText();
  }
}

class MockOcrAdapter implements OcrAdapter {
  @override
  Future<String> extractText() async {
    return '';
  }

  @override
  Future<String> extractTextFromRegion(Rect region) async {
    return extractText();
  }
}

class RustMethodChannelOcrAdapter implements OcrAdapter {
  RustMethodChannelOcrAdapter({
    this.timeout = const Duration(milliseconds: 900),
    this.maxAttempts = 2,
    this.retryDelay = const Duration(milliseconds: 100),
  });

  static const MethodChannel _channel = MethodChannel('formycareer/ocr');
  final Duration timeout;
  final int maxAttempts;
  final Duration retryDelay;

  @override
  Future<String> extractText() async {
    final attempts = maxAttempts < 1 ? 1 : maxAttempts;
    for (var attempt = 1; attempt <= attempts; attempt += 1) {
      try {
        final text = await _channel
            .invokeMethod<String>('extractText')
            .timeout(timeout);
        if (text != null && text.trim().isNotEmpty) {
          return text;
        }
      } on TimeoutException {
        debugPrint('MethodChannel OCR extractText timeout');
      } catch (error) {
        debugPrint('MethodChannel OCR extractText failed: $error');
      }
      if (attempt < attempts) {
        await Future<void>.delayed(retryDelay * attempt);
      }
    }
    return '';
  }

  @override
  Future<String> extractTextFromRegion(Rect region) async {
    final attempts = maxAttempts < 1 ? 1 : maxAttempts;
    for (var attempt = 1; attempt <= attempts; attempt += 1) {
      try {
        final text = await _channel
            .invokeMethod<String>('extractTextFromRegion', <String, double>{
              'left': region.left,
              'top': region.top,
              'width': region.width,
              'height': region.height,
            })
            .timeout(timeout);
        if (text != null && text.trim().isNotEmpty) {
          return text;
        }
      } on TimeoutException {
        debugPrint('MethodChannel OCR extractTextFromRegion timeout');
      } catch (error) {
        debugPrint('MethodChannel OCR extractTextFromRegion failed: $error');
      }
      if (attempt < attempts) {
        await Future<void>.delayed(retryDelay * attempt);
      }
    }
    return extractText();
  }
}

/// Captures a region of the virtual screen to a temp PNG using a short
/// PowerShell invocation. Returns the PNG file path, or an empty string on
/// failure. Shared by both Tesseract and Windows.Media.Ocr adapters.
/// Captures a region of the virtual screen to a temp PNG (Windows).
Future<String> captureRegionToPng(
  Rect region, {
  Duration timeout = const Duration(seconds: 5),
}) async {
  if (!Platform.isWindows && !Platform.isMacOS) {
    return '';
  }
  final x = region.left.round();
  final y = region.top.round();
  final w = region.width.round();
  final h = region.height.round();
  if (w <= 0 || h <= 0) {
    return '';
  }
  if (Platform.isMacOS) {
    final tempDir = await Directory.systemTemp.createTemp('fmc-ocr-');
    final outputPath = '${tempDir.path}/capture.png';
    final captureArg = '$x,$y,$w,$h';
    try {
      final result = await Process.run('screencapture', <String>[
        '-x',
        '-R',
        captureArg,
        outputPath,
      ]).timeout(timeout);
      if (result.exitCode == 0 && await File(outputPath).exists()) {
        return outputPath;
      }
      return '';
    } catch (_) {
      return '';
    }
  }

  final script =
      '''
\$ErrorActionPreference = "Stop"
\$ProgressPreference = "SilentlyContinue"
Add-Type -AssemblyName System.Drawing
\$bitmap = New-Object System.Drawing.Bitmap($w, $h)
\$graphics = [System.Drawing.Graphics]::FromImage(\$bitmap)
\$graphics.CopyFromScreen($x, $y, 0, 0, \$bitmap.Size)
\$path = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), "fmc-ocr-" + [System.Guid]::NewGuid().ToString() + ".png")
\$bitmap.Save(\$path, [System.Drawing.Imaging.ImageFormat]::Png)
\$graphics.Dispose()
\$bitmap.Dispose()
[Console]::Write(\$path)
''';
  final encodedScript = base64.encode(_encodeUtf16Le(script));
  try {
    final result = await Process.run('powershell', <String>[
      '-NoProfile',
      '-STA',
      '-ExecutionPolicy',
      'Bypass',
      '-EncodedCommand',
      encodedScript,
    ]).timeout(timeout);
    final stdoutText = (result.stdout as String? ?? '').trim();
    if (result.exitCode == 0 && stdoutText.isNotEmpty) {
      return stdoutText;
    }
    debugPrint(
      'Screen capture failed exit=${result.exitCode} stderr=${result.stderr}',
    );
    return '';
  } catch (error) {
    debugPrint('Screen capture exception: $error');
    return '';
  }
}

Future<String> captureInteractiveRegionToPngMac({
  Duration timeout = const Duration(seconds: 30),
}) async {
  if (!Platform.isMacOS) {
    return '';
  }
  final tempDir = await Directory.systemTemp.createTemp('fmc-ocr-');
  final outputPath = '${tempDir.path}/capture.png';
  try {
    final result = await Process.run('screencapture', <String>[
      '-i',
      '-x',
      outputPath,
    ]).timeout(timeout);
    if (result.exitCode == 0 && await File(outputPath).exists()) {
      return outputPath;
    }
    return '';
  } catch (_) {
    return '';
  }
}

/// OCR adapter backed by the bundled/installed Tesseract 5 CLI binary. Looks
/// for `tesseract.exe` in:
///   1. The `TESSERACT_EXE` env var (highest priority, for testing)
///   2. The build-time `--dart-define=TESSERACT_PATH=...`
///   3. Standard install paths (Program Files, chocolatey, user LocalAppData)
///   4. System PATH via `where tesseract`
/// The adapter expects `tessdata/<lang>.traineddata` to be accessible either
/// through the Tesseract install's default tessdata folder or a custom dir
/// supplied via `--dart-define=TESSDATA_DIR=...`.
class TesseractOcrAdapter implements OcrAdapter {
  TesseractOcrAdapter({
    String languages = tesseractLanguages,
    this.pageSegMode = 6,
    Duration timeout = const Duration(seconds: 12),
    this.tessdataDir,
  }) : _languages = languages,
       _timeout = timeout;

  static const String _buildTimeTesseractPath = String.fromEnvironment(
    'TESSERACT_PATH',
    defaultValue: '',
  );
  static const String _buildTimeTessdataDir = String.fromEnvironment(
    'TESSDATA_DIR',
    defaultValue: '',
  );

  String _languages;
  final int pageSegMode;
  final Duration _timeout;
  final String? tessdataDir;

  String? _resolvedExe;
  static const List<String> _ocrRetryLanguages = <String>[
    'eng',
    'vie',
    'jpn',
    'kor',
    'chi_sim',
    'chi_tra',
  ];

  String get languages => _languages;

  /// Allows the capture controller to update recognised languages at runtime
  /// based on user preferences.
  void setLanguages(List<String> tesseractCodes) {
    final cleaned = tesseractCodes
        .map((s) => s.trim().toLowerCase())
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList(growable: false);
    if (cleaned.isEmpty) return;
    _languages = cleaned.join('+');
  }

  @override
  Future<String> extractText() async {
    if (!Platform.isWindows && !Platform.isMacOS) {
      return '';
    }
    if (Platform.isMacOS) {
      final exe = await _locateTesseract();
      if (exe == null) {
        return '';
      }
      final pngPath = await captureInteractiveRegionToPngMac();
      if (pngPath.isEmpty) {
        return '';
      }
      try {
        return await _extractTextFromPngPath(exe: exe, pngPath: pngPath);
      } finally {
        try {
          final file = File(pngPath);
          if (await file.exists()) {
            await file.delete();
          }
        } catch (_) {}
      }
    }
    final full = Rect.fromLTWH(
      0,
      0,
      PlatformDispatcher.instance.views.first.physicalSize.width,
      PlatformDispatcher.instance.views.first.physicalSize.height,
    );
    return extractTextFromRegion(full);
  }

  @override
  Future<String> extractTextFromRegion(Rect region) async {
    if (!Platform.isWindows && !Platform.isMacOS) {
      return '';
    }
    final exe = await _locateTesseract();
    if (exe == null) {
      unawaited(
        _debugLog(
          hypothesisId: 'H4',
          location: 'ocr_adapter.dart:TesseractOcrAdapter',
          message: 'Tesseract binary not found',
          data: const <String, Object?>{},
        ),
      );
      return '';
    }

    final pngPath = await captureRegionToPng(region);
    if (pngPath.isEmpty) {
      unawaited(
        _debugLog(
          hypothesisId: 'H5',
          location: 'ocr_adapter.dart:TesseractOcrAdapter',
          message: 'Screen capture failed',
          data: <String, Object?>{
            'region': <String, double>{
              'left': region.left,
              'top': region.top,
              'width': region.width,
              'height': region.height,
            },
          },
        ),
      );
      return '';
    }

    try {
      return await _extractTextFromPngPath(exe: exe, pngPath: pngPath);
    } on TimeoutException {
      debugPrint('Tesseract timeout');
      return '';
    } catch (error) {
      debugPrint('Tesseract error: $error');
      return '';
    } finally {
      try {
        final file = File(pngPath);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (_) {}
    }
  }

  Future<String> _extractTextFromPngPath({
    required String exe,
    required String pngPath,
  }) async {
    await TesseractLanguagePackManager.instance.ensureLanguagesAvailable(
      _languages.split('+'),
    );
    final effectiveTessdata =
        tessdataDir ??
        (_buildTimeTessdataDir.isNotEmpty
            ? _buildTimeTessdataDir
            : TesseractLanguagePackManager.instance.cacheDirPath);
    final primary = await _runTesseractProcess(
      exe: exe,
      pngPath: pngPath,
      languageBundle: _languages,
      effectiveTessdata: effectiveTessdata,
    );
    if (primary.exitCode != 0) {
      return '';
    }
    if (!_looksLikeSuspiciousOcr(primary.stdoutText)) {
      return primary.stdoutText;
    }
    final retryLanguages = _expandedLanguagesForRetry(_languages);
    if (retryLanguages == _languages) {
      return primary.stdoutText;
    }
    final retry = await _runTesseractProcess(
      exe: exe,
      pngPath: pngPath,
      languageBundle: retryLanguages,
      effectiveTessdata: effectiveTessdata,
    );
    if (retry.exitCode == 0 && !_looksLikeSuspiciousOcr(retry.stdoutText)) {
      return retry.stdoutText;
    }
    // Let composite adapter fallback (Windows OCR) when Tesseract output is
    // very short/garbled for CJK glyphs.
    return '';
  }

  Future<_TesseractRun> _runTesseractProcess({
    required String exe,
    required String pngPath,
    required String languageBundle,
    required String? effectiveTessdata,
  }) async {
    final args = <String>[
      pngPath,
      'stdout',
      '-l',
      languageBundle,
      '--psm',
      pageSegMode.toString(),
      '--oem',
      '1',
    ];
    if (effectiveTessdata != null && effectiveTessdata.isNotEmpty) {
      args
        ..add('--tessdata-dir')
        ..add(effectiveTessdata);
    }
    unawaited(
      _debugLog(
        hypothesisId: 'H7',
        location: 'ocr_adapter.dart:TesseractOcrAdapter',
        message: 'Running Tesseract',
        data: <String, Object?>{
          'exe': exe,
          'languages': languageBundle,
          'psm': pageSegMode,
          'png': pngPath,
          'tessdata': effectiveTessdata,
        },
      ),
    );
    final result = await Process.run(
      exe,
      args,
      stdoutEncoding: utf8,
    ).timeout(_timeout);
    final stdoutText = (result.stdout as String? ?? '').trim();
    final stderrText = (result.stderr as String? ?? '').trim();
    unawaited(
      _debugLog(
        hypothesisId: 'H4',
        location: 'ocr_adapter.dart:TesseractOcrAdapter',
        message: 'Tesseract finished',
        data: <String, Object?>{
          'exitCode': result.exitCode,
          'stdoutLength': stdoutText.length,
          'stderrLength': stderrText.length,
          'stdoutPreview': stdoutText.length > 240
              ? stdoutText.substring(0, 240)
              : stdoutText,
          'stderrPreview': stderrText.length > 200
              ? stderrText.substring(0, 200)
              : stderrText,
        },
      ),
    );
    return _TesseractRun(
      exitCode: result.exitCode,
      stdoutText: stdoutText,
      stderrText: stderrText,
    );
  }

  String _expandedLanguagesForRetry(String currentBundle) {
    final merged = <String>{};
    for (final code in currentBundle.split('+')) {
      final cleaned = code.trim().toLowerCase();
      if (cleaned.isNotEmpty) {
        merged.add(cleaned);
      }
    }
    merged.addAll(_ocrRetryLanguages);
    return merged.join('+');
  }

  bool _looksLikeSuspiciousOcr(String value) {
    final text = value.trim();
    if (text.isEmpty) {
      return true;
    }
    // Common bad OCR for CJK glyphs (e.g. "VK", "7X"): very short ASCII-only.
    if (text.length <= 2 && RegExp(r'^[A-Za-z0-9]+$').hasMatch(text)) {
      return true;
    }
    return false;
  }

  Future<String?> _locateTesseract() async {
    if (_resolvedExe != null) {
      return _resolvedExe;
    }
    final envPath = Platform.environment['TESSERACT_EXE'];
    final candidates = <String>[
      if (envPath != null && envPath.isNotEmpty) envPath,
      if (_buildTimeTesseractPath.isNotEmpty) _buildTimeTesseractPath,
      '/opt/homebrew/bin/tesseract',
      '/usr/local/bin/tesseract',
      r'C:\Program Files\Tesseract-OCR\tesseract.exe',
      r'C:\Program Files (x86)\Tesseract-OCR\tesseract.exe',
      r'C:\tools\tesseract\tesseract.exe',
      _joinPath(
        Platform.environment['LOCALAPPDATA'],
        r'Programs\Tesseract-OCR\tesseract.exe',
      ),
    ];
    for (final candidate in candidates) {
      if (candidate.isEmpty) continue;
      if (await File(candidate).exists()) {
        _resolvedExe = candidate;
        return candidate;
      }
    }
    // Fallback: `where/which tesseract`.
    try {
      final lookupTool = Platform.isWindows ? 'where' : 'which';
      final result = await Process.run(lookupTool, <String>['tesseract']);
      final stdoutText = (result.stdout as String? ?? '').trim();
      if (result.exitCode == 0 && stdoutText.isNotEmpty) {
        final first = stdoutText.split(RegExp(r'\r?\n')).first.trim();
        if (first.isNotEmpty && await File(first).exists()) {
          _resolvedExe = first;
          return first;
        }
      }
    } catch (_) {}
    return null;
  }

  static String _joinPath(String? base, String tail) {
    if (base == null || base.isEmpty) return '';
    final sep = base.endsWith(r'\') || base.endsWith('/') ? '' : r'\';
    return '$base$sep$tail';
  }
}

class _TesseractRun {
  const _TesseractRun({
    required this.exitCode,
    required this.stdoutText,
    required this.stderrText,
  });

  final int exitCode;
  final String stdoutText;
  final String stderrText;
}

class WindowsPowerShellOcrAdapter implements OcrAdapter {
  WindowsPowerShellOcrAdapter({
    Duration timeout = const Duration(milliseconds: 15000),
    this.maxAttempts = 1,
    this.retryDelay = const Duration(milliseconds: 120),
  }) : _timeout = timeout;

  final Duration _timeout;
  final int maxAttempts;
  final Duration retryDelay;

  @override
  Future<String> extractText() async {
    if (!Platform.isWindows) {
      return '';
    }
    final fullScreen = _fullScreenRect();
    return extractTextFromRegion(fullScreen);
  }

  @override
  Future<String> extractTextFromRegion(Rect region) async {
    if (!Platform.isWindows) {
      return '';
    }
    final safeRegion = _normalizeRegion(region);
    // #region agent log
    unawaited(
      _debugLog(
        hypothesisId: 'H5',
        location: 'ocr_adapter.dart:132',
        message: 'OCR region requested',
        data: <String, Object?>{
          'requested': <String, double>{
            'left': region.left,
            'top': region.top,
            'width': region.width,
            'height': region.height,
          },
          'normalized': <String, double>{
            'left': safeRegion.left,
            'top': safeRegion.top,
            'width': safeRegion.width,
            'height': safeRegion.height,
          },
        },
      ),
    );
    // #endregion
    final script = _buildPowerShellOcrScript(safeRegion);
    final encodedScript = base64.encode(_encodeUtf16Le(script));
    final attempts = maxAttempts < 1 ? 1 : maxAttempts;
    for (var attempt = 1; attempt <= attempts; attempt += 1) {
      final output = await _runScriptOnce(encodedScript);
      if (output.isNotEmpty) {
        return output;
      }
      if (attempt < attempts) {
        await Future<void>.delayed(retryDelay * attempt);
      }
    }
    return '';
  }

  Future<String> _runScriptOnce(String encodedScript) async {
    try {
      // #region agent log
      unawaited(
        _debugLog(
          hypothesisId: 'H7',
          location: 'ocr_adapter.dart:181',
          message: 'Starting PowerShell OCR process',
          data: <String, Object?>{
            'encodedScriptLength': encodedScript.length,
            'timeoutMs': _timeout.inMilliseconds,
          },
        ),
      );
      // #endregion
      final result = await Process.run('powershell', <String>[
        '-NoProfile',
        '-STA',
        '-ExecutionPolicy',
        'Bypass',
        '-EncodedCommand',
        encodedScript,
      ]).timeout(_timeout);
      final stdoutText = (result.stdout as String? ?? '').trim();
      final stderrText = (result.stderr as String? ?? '').trim();
      if (stderrText.isNotEmpty) {
        debugPrint('PowerShell OCR stderr: $stderrText');
      }
      // #region agent log
      unawaited(
        _debugLog(
          hypothesisId: 'H4',
          location: 'ocr_adapter.dart:195',
          message: 'PowerShell OCR process finished',
          data: <String, Object?>{
            'exitCode': result.exitCode,
            'stdoutLength': stdoutText.length,
            'stderrLength': stderrText.length,
            'stdoutPreview': stdoutText.length > 240
                ? stdoutText.substring(0, 240)
                : stdoutText,
            'stderrPreview': stderrText.length > 200
                ? stderrText.substring(0, 200)
                : stderrText,
          },
        ),
      );
      // #endregion
      return stdoutText;
    } on TimeoutException {
      debugPrint('PowerShell OCR timed out');
      // #region agent log
      unawaited(
        _debugLog(
          hypothesisId: 'H4',
          location: 'ocr_adapter.dart:215',
          message: 'PowerShell OCR timeout',
          data: <String, Object?>{'timeoutMs': _timeout.inMilliseconds},
        ),
      );
      // #endregion
      return '';
    } catch (error) {
      debugPrint('PowerShell OCR failed: $error');
      // #region agent log
      unawaited(
        _debugLog(
          hypothesisId: 'H4',
          location: 'ocr_adapter.dart:228',
          message: 'PowerShell OCR exception',
          data: <String, Object?>{'error': '$error'},
        ),
      );
      // #endregion
      return '';
    }
  }

  Rect _normalizeRegion(Rect region) {
    // IMPORTANT: Preserve negative coordinates so multi-monitor setups where
    // secondary displays sit above/left of the primary (virtual-screen
    // coordinates) capture the correct area. Graphics.CopyFromScreen accepts
    // negative x/y values directly.
    final left = region.left.isFinite ? region.left.round() : 0;
    final top = region.top.isFinite ? region.top.round() : 0;
    final width = region.width.isFinite ? region.width.round() : 1;
    final height = region.height.isFinite ? region.height.round() : 1;
    return Rect.fromLTWH(
      left.toDouble(),
      top.toDouble(),
      width <= 0 ? 1 : width.toDouble(),
      height <= 0 ? 1 : height.toDouble(),
    );
  }

  Rect _fullScreenRect() {
    final views = PlatformDispatcher.instance.views;
    final width = views.isNotEmpty ? views.first.physicalSize.width : 1920.0;
    final height = views.isNotEmpty ? views.first.physicalSize.height : 1080.0;
    return Rect.fromLTWH(0, 0, width, height);
  }

  String _buildPowerShellOcrScript(Rect region) {
    final x = region.left.round();
    final y = region.top.round();
    final width = region.width.round();
    final height = region.height.round();
    return '''
\$ErrorActionPreference = "Stop"
\$ProgressPreference = "SilentlyContinue"
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Runtime.WindowsRuntime

\$bitmap = New-Object System.Drawing.Bitmap($width, $height)
\$graphics = [System.Drawing.Graphics]::FromImage(\$bitmap)
\$graphics.CopyFromScreen($x, $y, 0, 0, \$bitmap.Size)
\$tempPath = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), [System.Guid]::NewGuid().ToString() + ".png")
\$bitmap.Save(\$tempPath, [System.Drawing.Imaging.ImageFormat]::Png)
\$graphics.Dispose()
\$bitmap.Dispose()

\$stage = "init"
try {
  \$stage = "types"
  \$null = [Windows.Storage.StorageFile, Windows.Storage, ContentType=WindowsRuntime]
  \$null = [Windows.Graphics.Imaging.BitmapDecoder, Windows.Graphics.Imaging, ContentType=WindowsRuntime]
  \$null = [Windows.Media.Ocr.OcrEngine, Windows.Foundation.Metadata, ContentType=WindowsRuntime]

  \$stage = "awaiters"
  # Build generic AsTask helpers so WinRT IAsyncOperation<T>/IAsyncOperationWithProgress<T,U>
  # can be awaited synchronously via .NET Tasks. Polling Status on PowerShell STA
  # threads is unreliable because completion handlers never fire without a message pump.
  \$asTaskMethods = [System.WindowsRuntimeSystemExtensions].GetMethods() |
      Where-Object { \$_.Name -eq 'AsTask' -and \$_.IsGenericMethodDefinition }
  \$asTaskOp = \$asTaskMethods | Where-Object {
    \$p = \$_.GetParameters()
    \$p.Count -eq 1 -and \$p[0].ParameterType.Name -eq 'IAsyncOperation`1'
  } | Select-Object -First 1
  \$asTaskOpWithProgress = \$asTaskMethods | Where-Object {
    \$p = \$_.GetParameters()
    \$p.Count -eq 1 -and \$p[0].ParameterType.Name -eq 'IAsyncOperationWithProgress`2'
  } | Select-Object -First 1

  function Await-IAsyncOperation(\$operation, \$resultType) {
    if (\$null -eq \$operation) { throw "null IAsyncOperation" }
    \$generic = \$asTaskOp.MakeGenericMethod(\$resultType)
    \$task = \$generic.Invoke(\$null, @(\$operation))
    \$null = \$task.Wait(20000)
    if (-not \$task.IsCompleted) { throw "IAsyncOperation timed out" }
    if (\$task.IsFaulted) { throw \$task.Exception }
    return \$task.Result
  }
  function Await-IAsyncOperationWithProgress(\$operation, \$resultType, \$progressType) {
    if (\$null -eq \$operation) { throw "null IAsyncOperationWithProgress" }
    \$generic = \$asTaskOpWithProgress.MakeGenericMethod(@(\$resultType, \$progressType))
    \$task = \$generic.Invoke(\$null, @(\$operation))
    \$null = \$task.Wait(20000)
    if (-not \$task.IsCompleted) { throw "IAsyncOperationWithProgress timed out" }
    if (\$task.IsFaulted) { throw \$task.Exception }
    return \$task.Result
  }

  \$stage = "getFile"
  \$file = Await-IAsyncOperation (
    [Windows.Storage.StorageFile]::GetFileFromPathAsync(\$tempPath)
  ) ([Windows.Storage.StorageFile])
  if (\$null -eq \$file) {
    [Console]::Write("__OCR_ERROR__:StorageFile is null")
    exit 10
  }

  \$stage = "openRead"
  \$stream = Await-IAsyncOperation (\$file.OpenReadAsync()) (
    [Windows.Storage.Streams.IRandomAccessStreamWithContentType]
  )
  if (\$null -eq \$stream) {
    [Console]::Write("__OCR_ERROR__:IRandomAccessStream is null")
    exit 11
  }

  \$stage = "decoder"
  \$decoder = Await-IAsyncOperation (
    [Windows.Graphics.Imaging.BitmapDecoder]::CreateAsync(\$stream)
  ) ([Windows.Graphics.Imaging.BitmapDecoder])
  if (\$null -eq \$decoder) {
    [Console]::Write("__OCR_ERROR__:BitmapDecoder is null")
    exit 12
  }

  \$stage = "softwareBitmap"
  \$softwareBitmap = Await-IAsyncOperation (
    \$decoder.GetSoftwareBitmapAsync()
  ) ([Windows.Graphics.Imaging.SoftwareBitmap])
  if (\$null -eq \$softwareBitmap) {
    [Console]::Write("__OCR_ERROR__:SoftwareBitmap is null")
    exit 13
  }

  \$stage = "ocrEngine"
  \$ocrEngine = [Windows.Media.Ocr.OcrEngine]::TryCreateFromUserProfileLanguages()
  if (\$null -eq \$ocrEngine) {
    [Console]::Write("__OCR_ERROR__:Unable to initialize OcrEngine from user profile languages")
    exit 3
  }

  \$stage = "recognize"
  \$ocrResult = Await-IAsyncOperation (
    \$ocrEngine.RecognizeAsync(\$softwareBitmap)
  ) ([Windows.Media.Ocr.OcrResult])
  [Console]::Write(\$ocrResult.Text)
} catch {
  \$msg = \$_.Exception.Message
  if (\$_.Exception.InnerException) { \$msg = \$_.Exception.InnerException.Message }
  [Console]::Write(
    "__OCR_ERROR__:" + \$msg +
    " | stage=" + \$stage +
    " | at=" + \$_.InvocationInfo.ScriptLineNumber
  )
  exit 2
} finally {
  Remove-Item -LiteralPath \$tempPath -ErrorAction SilentlyContinue
}
''';
  }
}

/// Tries a sequence of [OcrAdapter]s, returning the first non-empty result.
/// Used so users without Tesseract still get the built-in Windows OCR path.
class CompositeOcrAdapter implements OcrAdapter {
  CompositeOcrAdapter(this._adapters);

  final List<OcrAdapter> _adapters;

  List<OcrAdapter> get adapters => List<OcrAdapter>.unmodifiable(_adapters);

  @override
  Future<String> extractText() async {
    for (final adapter in _adapters) {
      final text = await adapter.extractText();
      if (text.trim().isNotEmpty) {
        return text;
      }
    }
    return '';
  }

  @override
  Future<String> extractTextFromRegion(Rect region) async {
    for (final adapter in _adapters) {
      final text = await adapter.extractTextFromRegion(region);
      if (text.trim().isNotEmpty) {
        return text;
      }
    }
    return '';
  }
}

/// Propagates the user's preferred Tesseract languages through any nested
/// adapter composition. Safe to call on non-Tesseract adapters (no-op).
void applyOcrLanguages(OcrAdapter adapter, List<String> tesseractCodes) {
  if (adapter is TesseractOcrAdapter) {
    adapter.setLanguages(tesseractCodes);
    unawaited(
      TesseractLanguagePackManager.instance.ensureLanguagesAvailable(
        tesseractCodes,
      ),
    );
    return;
  }
  if (adapter is CompositeOcrAdapter) {
    for (final inner in adapter.adapters) {
      applyOcrLanguages(inner, tesseractCodes);
    }
  }
}

final ocrAdapterProvider = Provider<OcrAdapter>((ref) {
  if (useMockOcr) {
    return MockOcrAdapter();
  }
  if (useMethodChannelOcr) {
    return RustMethodChannelOcrAdapter();
  }
  if (useWindowsMediaOcr) {
    return WindowsPowerShellOcrAdapter();
  }
  if (Platform.isMacOS) {
    // Prefer native Apple Vision OCR via method channel on macOS.
    return CompositeOcrAdapter(<OcrAdapter>[
      RustMethodChannelOcrAdapter(
        timeout: const Duration(seconds: 35),
        maxAttempts: 1,
      ),
      TesseractOcrAdapter(),
    ]);
  }
  // Default: Tesseract 5 with Windows.Media.Ocr as graceful fallback. When
  // Tesseract isn't installed the built-in Windows OCR still provides usable
  // results for Latin-script text.
  return CompositeOcrAdapter(<OcrAdapter>[
    TesseractOcrAdapter(
      tessdataDir: TesseractLanguagePackManager.instance.cacheDirPath,
    ),
    WindowsPowerShellOcrAdapter(),
  ]);
});

List<int> _encodeUtf16Le(String value) {
  final output = <int>[];
  for (final codeUnit in value.codeUnits) {
    output.add(codeUnit & 0xFF);
    output.add((codeUnit >> 8) & 0xFF);
  }
  return output;
}

Future<void> _debugLog({
  required String hypothesisId,
  required String location,
  required String message,
  required Map<String, Object?> data,
}) async {
  final payload = <String, Object?>{
    'sessionId': 'ae424f',
    'runId': 'run1',
    'hypothesisId': hypothesisId,
    'location': location,
    'message': message,
    'data': data,
    'timestamp': DateTime.now().millisecondsSinceEpoch,
  };
  try {
    File(
      'debug-ae424f.log',
    ).writeAsStringSync('${jsonEncode(payload)}\n', mode: FileMode.append);
  } catch (_) {}
}
