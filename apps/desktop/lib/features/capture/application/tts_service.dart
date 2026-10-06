import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../core/audio/audio_source.dart';
import '../../../core/logging/logger_service.dart';
import 'translation_service.dart';

const String _kTtsBackend = String.fromEnvironment(
  'FORMYCAREER_TTS_BACKEND',
  defaultValue: 'auto',
);

/// Plays audio for a piece of text.
///
/// Resolution order:
///   1. `audioUrl` (e.g. dictionaryapi.dev pronunciation, single MP3).
///   2. Google Translate TTS (`translate.google.com/translate_tts`) chunked
///      MP3s, supports 100+ languages and falls back gracefully.
///   3. OS-native synth (Windows SAPI, macOS `say`, …).
abstract class TtsService {
  Future<bool> speak({
    required String text,
    String? language,
    String? audioUrl,
    double rate = 1.0,
    int loopCount = 1,
  });

  Future<void> stop();
}

/// Downloads remote TTS audio (single URL or chunked Google list) into temp
/// files, with optional disk cache keyed by `(language, text)`.
class _TtsAudioFetcher {
  _TtsAudioFetcher({required this.httpClient});

  final http.Client httpClient;
  static const Duration _fetchTimeout = Duration(seconds: 6);

  static const String _cacheDirName = 'fmc_tts_cache';
  static const String _indexFileName = 'index.txt';

  static final Map<String, String> _headers = <String, String>{
    'User-Agent': googleTtsUserAgent,
    'Accept': '*/*',
    'Accept-Language': 'en-US,en;q=0.9',
    'Referer': 'https://translate.google.com/',
  };

  /// Downloads each URL to its own temp file. Returns null on any failure.
  /// Caller owns the returned files (located in `Directory.systemTemp`).
  Future<List<File>?> fetchAll(List<String> urls) async {
    if (urls.isEmpty) return null;
    final tempDir = await Directory.systemTemp.createTemp('fmc_tts_');
    final files = <File>[];
    try {
      for (var i = 0; i < urls.length; i++) {
        final raw = urls[i].trim();
        if (raw.isEmpty) {
          return null;
        }
        final uri =
            raw.startsWith('//') ? Uri.parse('https:$raw') : Uri.parse(raw);
        final response = await httpClient
            .get(uri, headers: _headers)
            .timeout(_fetchTimeout);
        if (response.statusCode != 200 || response.bodyBytes.isEmpty) {
          return null;
        }
        final ext = _guessExtension(uri.path);
        final file = File('${tempDir.path}${Platform.pathSeparator}chunk_$i$ext');
        await file.writeAsBytes(response.bodyBytes, flush: true);
        files.add(file);
      }
      return files;
    } catch (error) {
      LoggerService.logError(
        source: 'desktop_tts',
        action: 'fetchAll',
        error: error,
      );
      return null;
    }
  }

  /// Returns previously cached chunk files for [key] if all referenced files
  /// are present and non-empty.
  Future<List<File>?> cacheGet(String key) async {
    if (key.isEmpty) return null;
    try {
      final dir = Directory(_keyDirPath(key));
      if (!await dir.exists()) {
        return null;
      }
      final indexFile = File('${dir.path}${Platform.pathSeparator}$_indexFileName');
      if (!await indexFile.exists()) {
        return null;
      }
      final names = (await indexFile.readAsString())
          .split('\n')
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .toList(growable: false);
      if (names.isEmpty) {
        return null;
      }
      final files = <File>[];
      for (final name in names) {
        final f = File('${dir.path}${Platform.pathSeparator}$name');
        if (!await f.exists() || (await f.length()) == 0) {
          return null;
        }
        files.add(f);
      }
      return files;
    } catch (_) {
      return null;
    }
  }

  /// Persists [files] under [key]; silent on failure (cache is best-effort).
  Future<void> cachePut(String key, List<File> files) async {
    if (key.isEmpty || files.isEmpty) return;
    try {
      final dir = Directory(_keyDirPath(key));
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
      await dir.create(recursive: true);
      final names = <String>[];
      for (var i = 0; i < files.length; i++) {
        final src = files[i];
        final ext = _guessExtension(src.path);
        final name = 'chunk_$i$ext';
        await src.copy('${dir.path}${Platform.pathSeparator}$name');
        names.add(name);
      }
      final indexFile = File('${dir.path}${Platform.pathSeparator}$_indexFileName');
      await indexFile.writeAsString(names.join('\n'), flush: true);
    } catch (_) {
      // Cache writes are best-effort.
    }
  }

  String _keyDirPath(String key) =>
      '${Directory.systemTemp.path}${Platform.pathSeparator}$_cacheDirName${Platform.pathSeparator}$key';

  static String makeCacheKey(String text, String? language) {
    final material =
        '${(language ?? '').trim().toLowerCase()}|${text.trim().toLowerCase()}';
    return sha1.convert(utf8.encode(material)).toString().substring(0, 24);
  }

  String _guessExtension(String path) {
    final clean = path.split('?').first;
    final dot = clean.lastIndexOf('.');
    if (dot < 0) return '.mp3';
    final ext = clean.substring(dot).toLowerCase();
    if (const {'.mp3', '.wav', '.ogg', '.aac', '.m4a'}.contains(ext)) {
      return ext;
    }
    return '.mp3';
  }
}

class WindowsSapiTtsService implements TtsService {
  WindowsSapiTtsService({
    required http.Client httpClient,
    Duration speakTimeout = const Duration(seconds: 30),
    String? backendOverride,
  })  : _speakTimeout = speakTimeout,
        _backend = ttsBackendFromString(backendOverride ?? _kTtsBackend),
        _fetcher = _TtsAudioFetcher(httpClient: httpClient);

  final Duration _speakTimeout;
  final TtsBackendChoice _backend;
  final _TtsAudioFetcher _fetcher;

  Process? _activeProcess;
  bool _stopRequested = false;

  @override
  Future<bool> speak({
    required String text,
    String? language,
    String? audioUrl,
    double rate = 1.0,
    int loopCount = 1,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return false;
    }
    await stop();
    _stopRequested = false;
    final clampedRate = _clampRate(rate);
    final loops = loopCount < 1 ? 1 : loopCount;

    final extUrl = audioUrl?.trim() ?? '';
    if (extUrl.isNotEmpty) {
      if (await _playFromUrls(
        [extUrl],
        rate: clampedRate,
        loopCount: loops,
      )) {
        return true;
      }
      if (_stopRequested) return false;
    }

    if (_backend != TtsBackendChoice.os) {
      final googleUrls = buildGoogleTtsUrls(trimmed, language);
      if (googleUrls.isNotEmpty) {
        final cacheKey = _TtsAudioFetcher.makeCacheKey(trimmed, language);
        if (await _playFromUrls(
          googleUrls,
          cacheKey: cacheKey,
          rate: clampedRate,
          loopCount: loops,
        )) {
          return true;
        }
        if (_stopRequested) return false;
      }
    }

    if (_backend == TtsBackendChoice.google) {
      return false;
    }

    return _speakViaSapi(
      trimmed,
      language: language,
      rate: clampedRate,
      loopCount: loops,
    );
  }

  @override
  Future<void> stop() async {
    _stopRequested = true;
    final process = _activeProcess;
    _activeProcess = null;
    if (process == null) return;
    try {
      process.kill(ProcessSignal.sigterm);
    } catch (_) {
      // Best-effort cleanup.
    }
  }

  Future<bool> _playFromUrls(
    List<String> urls, {
    String? cacheKey,
    double rate = 1.0,
    int loopCount = 1,
  }) async {
    List<File>? files;
    if (cacheKey != null) {
      files = await _fetcher.cacheGet(cacheKey);
    }
    final fromCache = files != null;
    if (files == null) {
      files = await _fetcher.fetchAll(urls);
      if (files == null) return false;
      if (cacheKey != null) {
        unawaited(_fetcher.cachePut(cacheKey, files));
      }
    }
    final ok = await _playFilesSequential(
      files,
      rate: rate,
      loopCount: loopCount,
    );
    if (!fromCache) {
      _scheduleCleanup(files);
    }
    return ok;
  }

  Future<bool> _playFilesSequential(
    List<File> files, {
    double rate = 1.0,
    int loopCount = 1,
  }) async {
    if (files.isEmpty) return false;
    try {
      final script = _buildSequentialPlayerScript(
        files,
        rate: rate,
        loopCount: loopCount,
      );
      final process = await Process.start(
        'powershell.exe',
        [
          '-NoProfile',
          '-ExecutionPolicy',
          'Bypass',
          '-WindowStyle',
          'Hidden',
          '-Command',
          script,
        ],
        runInShell: false,
      );
      _activeProcess = process;
      final perChunkTimeout = _speakTimeout;
      // Slow rates stretch playback duration; account for that in the budget.
      final speedFactor = rate <= 0 ? 1.0 : (1.0 / rate);
      final totalTimeout = Duration(
        milliseconds:
            (perChunkTimeout.inMilliseconds *
                        files.length *
                        loopCount *
                        speedFactor)
                    .round() +
                5000,
      );
      try {
        await process.exitCode.timeout(totalTimeout, onTimeout: () {
          process.kill(ProcessSignal.sigkill);
          return -1;
        });
      } finally {
        if (_activeProcess == process) {
          _activeProcess = null;
        }
      }
      return !_stopRequested;
    } catch (error) {
      LoggerService.logError(
        source: 'desktop_tts',
        action: 'playFiles',
        error: error,
      );
      return false;
    }
  }

  Future<bool> _speakViaSapi(
    String text, {
    String? language,
    double rate = 1.0,
    int loopCount = 1,
  }) async {
    try {
      final script = _buildSapiScript(
        text: text,
        language: language,
        rate: rate,
        loopCount: loopCount,
      );
      final process = await Process.start(
        'powershell.exe',
        [
          '-NoProfile',
          '-ExecutionPolicy',
          'Bypass',
          '-WindowStyle',
          'Hidden',
          '-Command',
          script,
        ],
        runInShell: false,
      );
      _activeProcess = process;
      final speedFactor = rate <= 0 ? 1.0 : (1.0 / rate);
      final timeout = Duration(
        milliseconds:
            (_speakTimeout.inMilliseconds * loopCount * speedFactor).round() +
                2000,
      );
      try {
        await process.exitCode.timeout(timeout, onTimeout: () {
          process.kill(ProcessSignal.sigkill);
          return -1;
        });
      } finally {
        if (_activeProcess == process) {
          _activeProcess = null;
        }
      }
      return !_stopRequested;
    } catch (error) {
      LoggerService.logError(
        source: 'desktop_tts',
        action: 'speakViaSapi',
        error: error,
      );
      return false;
    }
  }

  void _scheduleCleanup(List<File> files) {
    Future<void>(() async {
      try {
        if (files.isEmpty) return;
        final dir = files.first.parent;
        if (await dir.exists()) {
          await dir.delete(recursive: true);
        }
      } catch (_) {
        // Cleanup is best-effort.
      }
    });
  }

  String _buildSapiScript({
    required String text,
    String? language,
    double rate = 1.0,
    int loopCount = 1,
  }) {
    final encoded = base64Encode(utf8.encode(text));
    final langLine = (language == null || language.trim().isEmpty)
        ? ''
        : "\$preferred = '${_escapeSingleQuote(language.trim().toLowerCase())}';";
    final loops = loopCount < 1 ? 1 : loopCount;
    final sapiRate = _sapiRateFromMultiplier(rate);
    return '''
\$ErrorActionPreference = 'Stop';
Add-Type -AssemblyName System.Speech;
\$bytes = [Convert]::FromBase64String('$encoded');
\$text = [System.Text.Encoding]::UTF8.GetString(\$bytes);
\$synth = New-Object System.Speech.Synthesis.SpeechSynthesizer;
$langLine
if (\$preferred) {
  \$match = \$null;
  foreach (\$voice in \$synth.GetInstalledVoices()) {
    \$info = \$voice.VoiceInfo;
    if (\$info.Culture.Name.ToLower().StartsWith(\$preferred)) {
      \$match = \$info.Name; break;
    }
  }
  if (\$match) { \$synth.SelectVoice(\$match) }
}
\$synth.Rate = $sapiRate;
\$synth.Volume = 100;
for (\$i = 0; \$i -lt $loops; \$i++) { \$synth.Speak(\$text); }
\$synth.Dispose();
''';
  }

  String _buildSequentialPlayerScript(
    List<File> files, {
    double rate = 1.0,
    int loopCount = 1,
  }) {
    final escapedPaths = files
        .map((file) => "'${_escapeSingleQuote(file.path)}'")
        .join(', ');
    final loops = loopCount < 1 ? 1 : loopCount;
    final speedRatio = rate <= 0 ? 1.0 : rate;
    return '''
\$ErrorActionPreference = 'Stop';
Add-Type -AssemblyName PresentationCore;
\$paths = @($escapedPaths);
\$speed = [double]$speedRatio;
\$inverseSpeed = if (\$speed -le 0) { 1.0 } else { 1.0 / \$speed };
for (\$loop = 0; \$loop -lt $loops; \$loop++) {
  foreach (\$path in \$paths) {
    \$item = Get-Item -LiteralPath \$path;
    \$estimatedMs = [Math]::Max(1000, [int](([double]\$item.Length / 4) * \$inverseSpeed));
    \$player = New-Object System.Windows.Media.MediaPlayer;
    \$fullPath = [System.IO.Path]::GetFullPath(\$path);
    \$uriPath = 'file:///' + (\$fullPath.Replace([char]92, '/'));
    \$player.Open([Uri]::new(\$uriPath));
    \$player.Play();
    Start-Sleep -Milliseconds 120;
    \$player.SpeedRatio = \$speed;
    Start-Sleep -Milliseconds 130;
    \$waited = 0;
    while (\$waited -lt 1500 -and -not \$player.NaturalDuration.HasTimeSpan) {
      Start-Sleep -Milliseconds 50;
      \$waited += 50;
    }
    \$durationMs = 0;
    if (\$player.NaturalDuration.HasTimeSpan) {
      \$natural = [double]\$player.NaturalDuration.TimeSpan.TotalMilliseconds;
      \$durationMs = [int](\$natural * \$inverseSpeed);
    }
    \$totalMs = [Math]::Max(\$durationMs, \$estimatedMs);
    Start-Sleep -Milliseconds ([int]\$totalMs + 200);
    \$player.Stop();
    \$player.Close();
  }
}
''';
  }

  String _escapeSingleQuote(String input) => input.replaceAll("'", "''");
}

/// Maps a desktop playback multiplier (0.5..1.5) to SAPI's `Rate` field
/// (clamped to its native -10..10 scale; 1.0 -> 0, 0.5 -> -5, 1.5 -> 5).
@visibleForTesting
int sapiRateFromMultiplier(double rate) => _sapiRateFromMultiplier(rate);

int _sapiRateFromMultiplier(double rate) {
  if (rate.isNaN) return 0;
  final mapped = ((rate - 1.0) * 10).round();
  return mapped.clamp(-10, 10);
}

/// Maps a desktop playback multiplier (0.5..1.5) to macOS `say -r` words per
/// minute (anchored on the default 175 wpm).
@visibleForTesting
int macOsSayRateFromMultiplier(double rate) => _macOsSayRateFromMultiplier(rate);

int _macOsSayRateFromMultiplier(double rate) {
  if (rate.isNaN || rate <= 0) {
    return 175;
  }
  final wpm = (175.0 * rate).round();
  return wpm.clamp(60, 360);
}

@visibleForTesting
double clampDesktopTtsRate(double rate) => _clampRate(rate);

double _clampRate(double rate) {
  if (rate.isNaN) return 1.0;
  if (rate < 0.5) return 0.5;
  if (rate > 1.5) return 1.5;
  return rate;
}

class MacosTtsService implements TtsService {
  MacosTtsService({
    required http.Client httpClient,
    Duration speakTimeout = const Duration(seconds: 30),
    String? backendOverride,
  })  : _speakTimeout = speakTimeout,
        _backend = ttsBackendFromString(backendOverride ?? _kTtsBackend),
        _fetcher = _TtsAudioFetcher(httpClient: httpClient);

  final Duration _speakTimeout;
  final TtsBackendChoice _backend;
  final _TtsAudioFetcher _fetcher;

  Process? _activeProcess;
  bool _stopRequested = false;

  @override
  Future<bool> speak({
    required String text,
    String? language,
    String? audioUrl,
    double rate = 1.0,
    int loopCount = 1,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return false;
    }
    await stop();
    _stopRequested = false;
    final clampedRate = _clampRate(rate);
    final loops = loopCount < 1 ? 1 : loopCount;

    final extUrl = audioUrl?.trim() ?? '';
    if (extUrl.isNotEmpty) {
      if (await _playFromUrls(
        [extUrl],
        rate: clampedRate,
        loopCount: loops,
      )) {
        return true;
      }
      if (_stopRequested) return false;
    }

    if (_backend != TtsBackendChoice.os) {
      final googleUrls = buildGoogleTtsUrls(trimmed, language);
      if (googleUrls.isNotEmpty) {
        final cacheKey = _TtsAudioFetcher.makeCacheKey(trimmed, language);
        if (await _playFromUrls(
          googleUrls,
          cacheKey: cacheKey,
          rate: clampedRate,
          loopCount: loops,
        )) {
          return true;
        }
        if (_stopRequested) return false;
      }
    }

    if (_backend == TtsBackendChoice.google) {
      return false;
    }

    return _speakViaSay(
      trimmed,
      language: language,
      rate: clampedRate,
      loopCount: loops,
    );
  }

  @override
  Future<void> stop() async {
    _stopRequested = true;
    final process = _activeProcess;
    _activeProcess = null;
    if (process == null) return;
    try {
      process.kill(ProcessSignal.sigterm);
    } catch (_) {
      // Best-effort cleanup.
    }
  }

  Future<bool> _playFromUrls(
    List<String> urls, {
    String? cacheKey,
    double rate = 1.0,
    int loopCount = 1,
  }) async {
    List<File>? files;
    if (cacheKey != null) {
      files = await _fetcher.cacheGet(cacheKey);
    }
    final fromCache = files != null;
    if (files == null) {
      files = await _fetcher.fetchAll(urls);
      if (files == null) return false;
      if (cacheKey != null) {
        unawaited(_fetcher.cachePut(cacheKey, files));
      }
    }
    final ok = await _playFilesSequential(
      files,
      rate: rate,
      loopCount: loopCount,
    );
    if (!fromCache) {
      _scheduleCleanup(files);
    }
    return ok;
  }

  Future<bool> _playFilesSequential(
    List<File> files, {
    double rate = 1.0,
    int loopCount = 1,
  }) async {
    final loops = loopCount < 1 ? 1 : loopCount;
    final rateArg = rate <= 0 ? '1.0' : rate.toStringAsFixed(2);
    for (var loop = 0; loop < loops; loop++) {
      for (final file in files) {
        if (_stopRequested) return false;
        try {
          final process = await Process.start(
            'afplay',
            <String>['-r', rateArg, file.path],
            runInShell: false,
          );
          _activeProcess = process;
          try {
            await process.exitCode.timeout(_speakTimeout, onTimeout: () {
              process.kill(ProcessSignal.sigkill);
              return -1;
            });
          } finally {
            if (_activeProcess == process) {
              _activeProcess = null;
            }
          }
        } catch (error) {
          LoggerService.logError(
            source: 'desktop_tts',
            action: 'macosPlayFile',
            error: error,
          );
          return false;
        }
      }
    }
    return !_stopRequested;
  }

  Future<bool> _speakViaSay(
    String text, {
    String? language,
    double rate = 1.0,
    int loopCount = 1,
  }) async {
    final loops = loopCount < 1 ? 1 : loopCount;
    try {
      final voice = _voiceForLanguage(language);
      final wpm = _macOsSayRateFromMultiplier(rate);
      final args = <String>[
        if (voice != null) ...['-v', voice],
        '-r',
        wpm.toString(),
        text,
      ];
      for (var i = 0; i < loops; i++) {
        if (_stopRequested) return false;
        final process = await Process.start('say', args, runInShell: false);
        _activeProcess = process;
        try {
          await process.exitCode.timeout(_speakTimeout, onTimeout: () {
            process.kill(ProcessSignal.sigkill);
            return -1;
          });
        } finally {
          if (_activeProcess == process) {
            _activeProcess = null;
          }
        }
      }
      return !_stopRequested;
    } catch (error) {
      LoggerService.logError(
        source: 'desktop_tts',
        action: 'macosSpeakViaSay',
        error: error,
      );
      return false;
    }
  }

  void _scheduleCleanup(List<File> files) {
    Future<void>(() async {
      try {
        if (files.isEmpty) return;
        final dir = files.first.parent;
        if (await dir.exists()) {
          await dir.delete(recursive: true);
        }
      } catch (_) {
        // Cleanup is best-effort.
      }
    });
  }

  String? _voiceForLanguage(String? language) {
    final code = (language ?? '').trim().toLowerCase();
    if (code.startsWith('vi')) {
      return null;
    }
    if (code.startsWith('en')) {
      return 'Samantha';
    }
    return null;
  }
}

class NoopTtsService implements TtsService {
  @override
  Future<bool> speak({
    required String text,
    String? language,
    String? audioUrl,
    double rate = 1.0,
    int loopCount = 1,
  }) async {
    return false;
  }

  @override
  Future<void> stop() async {}
}

final ttsServiceProvider = Provider<TtsService>((ref) {
  final client = ref.watch(translationHttpClientProvider);
  final TtsService service;
  if (Platform.isWindows) {
    service = WindowsSapiTtsService(httpClient: client);
  } else if (Platform.isMacOS) {
    service = MacosTtsService(httpClient: client);
  } else {
    service = NoopTtsService();
  }
  ref.onDispose(() => unawaited(service.stop()));
  return service;
});
