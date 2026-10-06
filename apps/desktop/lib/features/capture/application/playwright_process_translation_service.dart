import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'playwright_runtime_paths.dart';
import 'translation_chunking.dart';
import 'translation_models.dart';
import 'translation_process_runner.dart';

enum PlaywrightTranslationMode { googleWeb, deeplWeb }

/// Translation via Node + Playwright sidecar (`run_playwright_translate.mjs`),
/// targeting Google Translate web automation.
class PlaywrightProcessTranslationService implements TranslationService {
  PlaywrightProcessTranslationService({
    required TranslationProcessRunner runner,
    this.mode = PlaywrightTranslationMode.googleWeb,
    this.defaultTargetLanguage = kDefaultTranslationNativeLanguage,
    this.fallbackSourceWhenAuto = 'en',
    this.segmentTimeout = const Duration(seconds: 120),
    this.idleTimeout = const Duration(minutes: 2),
    this.failureCooldown = const Duration(seconds: 8),
    this.pathsResolver = PlaywrightRuntimePaths.resolve,
    Map<String, String>? environment,
  }) : _runner = runner,
       _environment = environment;

  final TranslationProcessRunner _runner;
  final PlaywrightTranslationMode mode;
  final String defaultTargetLanguage;
  final String fallbackSourceWhenAuto;
  final Duration segmentTimeout;
  final Duration idleTimeout;
  final Duration failureCooldown;
  final Directory? Function({Map<String, String>? environment}) pathsResolver;
  final Map<String, String>? _environment;
  DateTime? _lastSegmentCompletedAt;
  DateTime? _lastFailureAt;
  String _lastFailureKey = '';
  int _coldRuns = 0;
  int _warmRuns = 0;
  int _coalescedRuns = 0;
  final Map<String, Future<TranslationResult>> _inFlight =
      <String, Future<TranslationResult>>{};

  @override
  Future<TranslationResult> translate(TranslationRequest request) async {
    final input = request.text.trim();
    if (input.isEmpty) {
      return TranslationResult.empty;
    }

    final root = pathsResolver(environment: _environment);
    if (root == null || !PlaywrightRuntimePaths.isRunnableBundle(root)) {
      return TranslationResult.empty;
    }

    final script = PlaywrightRuntimePaths.scriptPath(root);
    if (script == null) {
      return TranslationResult.empty;
    }

    final targetRaw =
        (request.targetLanguage == null ||
            request.targetLanguage!.trim().isEmpty)
        ? defaultTargetLanguage
        : request.targetLanguage!.trim();
    final to = _toProviderLanguage(targetRaw);
    if (to.isEmpty) {
      return TranslationResult.empty;
    }

    final srcRaw =
        (request.sourceLanguage == null ||
            request.sourceLanguage!.trim().isEmpty)
        ? fallbackSourceWhenAuto
        : request.sourceLanguage!.trim();
    final from = _toProviderLanguage(
      srcRaw == 'autodetect' ? fallbackSourceWhenAuto : srcRaw,
    );
    if (from.isEmpty) {
      return TranslationResult.empty;
    }

    final node = PlaywrightRuntimePaths.nodeExecutableLabel();
    final flowKey = '$from|$to|${TranslationChunking.normalizeWhitespace(input)}';

    if (_isInFailureCooldown(flowKey)) {
      if (kDebugMode) {
        debugPrint('translate_dbg cooldown key=$flowKey');
      }
      return TranslationResult.empty;
    }

    final existing = _inFlight[flowKey];
    if (existing != null) {
      _coalescedRuns += 1;
      return existing;
    }

    Future<TranslationResult> one(String text) {
      final segmentKey = '$from|$to|${TranslationChunking.normalizeWhitespace(text)}';
      return _translateSegmentCoalesced(
        flowKey: segmentKey,
        node: node,
        script: script,
        workingDirectory: root.path,
        text: text,
        from: from,
        to: to,
      );
    }

    final flowFuture = () async {
      if (TranslationChunking.needsChunkingForLocal(input)) {
        return TranslationChunking.translateWithChunks(
          input: input,
          translateSegment: one,
          monolithicCoerce: true,
        );
      }
      return one(input);
    }();
    _inFlight[flowKey] = flowFuture;
    try {
      return await flowFuture;
    } finally {
      _inFlight.remove(flowKey);
    }
  }

  bool _isInFailureCooldown(String key) {
    if (_lastFailureKey != key || _lastFailureAt == null) {
      return false;
    }
    return DateTime.now().difference(_lastFailureAt!) < failureCooldown;
  }

  Future<TranslationResult> _translateSegmentCoalesced({
    required String flowKey,
    required String node,
    required String script,
    required String workingDirectory,
    required String text,
    required String from,
    required String to,
  }) async {
    final existing = _inFlight[flowKey];
    if (existing != null) {
      _coalescedRuns += 1;
      return existing;
    }
    final startedAt = DateTime.now();
    final isWarm =
        _lastSegmentCompletedAt != null &&
        startedAt.difference(_lastSegmentCompletedAt!) < idleTimeout;
    if (isWarm) {
      _warmRuns += 1;
    } else {
      _coldRuns += 1;
    }
    final future = _translateSegment(
      node: node,
      script: script,
      workingDirectory: workingDirectory,
      text: text,
      from: from,
      to: to,
      isWarmRun: isWarm,
    );
    _inFlight[flowKey] = future;
    try {
      return await future;
    } finally {
      _inFlight.remove(flowKey);
    }
  }

  Future<TranslationResult> _translateSegment({
    required String node,
    required String script,
    required String workingDirectory,
    required String text,
    required String from,
    required String to,
    required bool isWarmRun,
  }) async {
    final stopwatch = Stopwatch()..start();
    final payload = jsonEncode(<String, Object?>{
      'text': text,
      'from': from,
      'to': to,
      'mode': switch (mode) {
        PlaywrightTranslationMode.googleWeb => 'google_web',
        PlaywrightTranslationMode.deeplWeb => 'deepl_web',
      },
    });
    try {
      final result = await _runWithSafeRestart(
        executable: node,
        script: script,
        stdinText: payload,
        workingDirectory: workingDirectory,
      );
      if (result.exitCode != 0) {
        _recordFailure('$from|$to|${TranslationChunking.normalizeWhitespace(text)}');
        if (kDebugMode) {
          debugPrint(
            'Playwright translate exit=${result.exitCode} stderr=${result.stderr}',
          );
        }
        return TranslationResult.empty;
      }
      final out = result.stdout.trim();
      if (out.isEmpty) {
        _recordFailure('$from|$to|${TranslationChunking.normalizeWhitespace(text)}');
        if (kDebugMode) {
          debugPrint(
            'Playwright translate empty stdout; stderr=${result.stderr}',
          );
        }
        return TranslationResult.empty;
      }
      _lastSegmentCompletedAt = DateTime.now();
      _lastFailureAt = null;
      _lastFailureKey = '';
      final parsed = _parseSidecarOutput(out);
      _debugLatencyLine(
        isWarmRun: isWarmRun,
        elapsedMs: stopwatch.elapsedMilliseconds,
      );
      return TranslationResult(
        translatedText: parsed.$1,
        detectedSourceLanguage: parsed.$2.isEmpty ? from : parsed.$2,
      );
    } catch (e, st) {
      _recordFailure('$from|$to|${TranslationChunking.normalizeWhitespace(text)}');
      debugPrint('Playwright translate error: $e\n$st');
      return TranslationResult.empty;
    } finally {
      stopwatch.stop();
    }
  }

  Future<ProcessRunResult> _runWithSafeRestart({
    required String executable,
    required String script,
    required String stdinText,
    required String workingDirectory,
  }) async {
    final first = await _runner.run(
      executable: executable,
      arguments: <String>[script],
      stdinText: stdinText,
      workingDirectory: workingDirectory,
      timeout: segmentTimeout,
    );
    if (first.exitCode == 0 && first.stdout.trim().isNotEmpty) {
      return first;
    }
    // Safe restart-on-failure: rerun once with a fresh sidecar process.
    return _runner.run(
      executable: executable,
      arguments: <String>[script],
      stdinText: stdinText,
      workingDirectory: workingDirectory,
      timeout: segmentTimeout,
    );
  }

  void _recordFailure(String key) {
    _lastFailureKey = key;
    _lastFailureAt = DateTime.now();
  }

  void _debugLatencyLine({
    required bool isWarmRun,
    required int elapsedMs,
  }) {
    if (!kDebugMode) {
      return;
    }
    final modeLabel = switch (mode) {
      PlaywrightTranslationMode.googleWeb => 'google',
      PlaywrightTranslationMode.deeplWeb => 'deepl',
    };
    debugPrint(
      'translate_dbg mode=$modeLabel run=${isWarmRun ? 'warm' : 'cold'} '
      'lat=${elapsedMs}ms cold=$_coldRuns warm=$_warmRuns '
      'coalesced=$_coalescedRuns inflight=${_inFlight.length}',
    );
  }

  String _toProviderLanguage(String appCode) {
    final c = appCode.trim().toLowerCase();
    if (c.isEmpty) {
      return '';
    }
    if (c == 'autodetect') {
      return 'auto';
    }
    final base = c.split('-').first;
    if (mode == PlaywrightTranslationMode.deeplWeb) {
      switch (base) {
        case 'zt':
          return 'zh';
        default:
          return base;
      }
    }
    switch (base) {
      case 'zt':
        return 'zh-TW';
      case 'zh':
        return 'zh-CN';
      default:
        return base;
    }
  }

  (String, String) _parseSidecarOutput(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        final translated = (decoded['translatedText'] as String? ?? '').trim();
        if (translated.isNotEmpty) {
          final detected =
              (decoded['detectedSourceLanguage'] as String? ?? '').trim();
          return (translated, detected);
        }
      }
    } catch (_) {
      // Backward compatibility with older sidecar emitting plain text.
    }
    return (raw.trim(), '');
  }
}
