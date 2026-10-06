import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:just_audio/just_audio.dart';

import '../../../core/audio/audio_source.dart';
import '../../../core/audio/tts_cache.dart';

const String _kTtsBackend = String.fromEnvironment(
  'FORMYCAREER_TTS_BACKEND',
  defaultValue: 'auto',
);

/// Plays pronunciation audio for review cards.
///
/// Source priority:
///   1. `audioUrl` if provided (e.g. dictionaryapi.dev pronunciation).
///   2. Google Translate TTS chunked MP3s for the card language (cached on
///      disk after the first download).
///   3. OS TTS via `flutter_tts` as a final fallback.
class ReviewTtsService {
  ReviewTtsService({
    AudioPlayer? player,
    FlutterTts? tts,
    TtsBackendChoice? backendOverride,
    MobileTtsCache? cache,
  }) : _player = player ?? AudioPlayer(),
       _tts = tts ?? FlutterTts(),
       _backend = backendOverride ?? ttsBackendFromString(_kTtsBackend),
       _cache = cache ?? MobileTtsCache() {
    _tts.setSpeechRate(_kBaselineFlutterTtsRate);
    _tts.setVolume(1.0);
    _tts.awaitSpeakCompletion(true);
  }

  /// flutter_tts's default rate maps roughly to "natural" 175 wpm.
  static const double _kBaselineFlutterTtsRate = 0.45;

  final AudioPlayer _player;
  final FlutterTts _tts;
  final TtsBackendChoice _backend;
  final MobileTtsCache _cache;

  bool _stopRequested = false;

  Future<void> speak({
    required String text,
    required String language,
    String? audioUrl,
    double rate = 1.0,
    int loopCount = 1,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    await stop();
    _stopRequested = false;
    final clampedRate = _clampRate(rate);
    final loops = loopCount < 1 ? 1 : loopCount;

    final extUrl = audioUrl?.trim() ?? '';
    if (extUrl.isNotEmpty) {
      if (await _playRemoteUrls(
        [_normalizeAudioUrl(extUrl)],
        rate: clampedRate,
        loopCount: loops,
      )) {
        return;
      }
      if (_stopRequested) return;
    }

    if (_backend != TtsBackendChoice.os) {
      final googleUrls = buildGoogleTtsUrls(trimmed, language);
      if (googleUrls.isNotEmpty) {
        final cacheKey = MobileTtsCache.makeCacheKey(trimmed, language);
        if (await _playRemoteUrls(
          googleUrls,
          rate: clampedRate,
          loopCount: loops,
          cacheKey: cacheKey,
        )) {
          return;
        }
        if (_stopRequested) return;
      }
    }

    if (_backend == TtsBackendChoice.google) {
      return;
    }

    await _speakViaFlutterTts(
      trimmed,
      language: language,
      rate: clampedRate,
      loopCount: loops,
    );
  }

  Future<bool> _playRemoteUrls(
    List<String> urls, {
    required double rate,
    required int loopCount,
    String? cacheKey,
  }) async {
    if (urls.isEmpty) return false;
    final cachedFiles = cacheKey != null
        ? await _cache.cacheGet(cacheKey)
        : null;
    final List<AudioSource> sources;
    if (cachedFiles != null) {
      sources = cachedFiles
          .map((f) => AudioSource.uri(Uri.file(f.path)))
          .toList(growable: false);
    } else {
      // Stream from network for low-latency playback. In parallel, populate
      // the on-disk cache so subsequent reviews of the same word are faster
      // and offline-friendly.
      final headers = <String, String>{
        'User-Agent': googleTtsUserAgent,
        'Accept': '*/*',
        'Accept-Language': 'en-US,en;q=0.9',
        'Referer': 'https://translate.google.com/',
      };
      sources = urls
          .map((url) => AudioSource.uri(Uri.parse(url), headers: headers))
          .toList(growable: false);
      if (cacheKey != null) {
        unawaited(_cacheInBackground(cacheKey, urls));
      }
    }
    try {
      final source = sources.length == 1
          ? sources.first
          : ConcatenatingAudioSource(children: sources);
      await _player.setAudioSource(source);
      await _player.setSpeed(rate);
      for (var i = 0; i < loopCount; i++) {
        if (_stopRequested) break;
        if (i > 0) {
          await _player.seek(Duration.zero);
        }
        await _player.play();
        final state = await _player.playerStateStream.firstWhere(
          (s) =>
              s.processingState == ProcessingState.completed ||
              s.processingState == ProcessingState.idle,
          orElse: () => PlayerState(false, ProcessingState.idle),
        );
        if (_stopRequested) break;
        if (state.processingState != ProcessingState.completed) {
          return false;
        }
      }
      return !_stopRequested;
    } catch (_) {
      return false;
    }
  }

  Future<void> _cacheInBackground(String key, List<String> urls) async {
    try {
      final downloaded = await _cache.fetchAll(urls);
      if (downloaded == null || downloaded.isEmpty) {
        return;
      }
      try {
        await _cache.cachePut(key, downloaded);
      } finally {
        try {
          final dir = downloaded.first.parent;
          if (await dir.exists()) {
            await dir.delete(recursive: true);
          }
        } catch (_) {
          // Best-effort cleanup.
        }
      }
    } catch (_) {
      // Background priming is best-effort; ignore failures.
    }
  }

  Future<void> _speakViaFlutterTts(
    String text, {
    required String language,
    required double rate,
    required int loopCount,
  }) async {
    try {
      await _tts.stop();
      await _tts.setLanguage(language);
      // flutter_tts rejects very low rates on some devices; keep within a safe band.
      final effectiveRate = (_kBaselineFlutterTtsRate * rate).clamp(0.12, 1.0);
      await _tts.setSpeechRate(effectiveRate);
      for (var i = 0; i < loopCount; i++) {
        if (_stopRequested) break;
        await _tts.speak(text);
      }
    } catch (_) {
      // Last-resort fallback already failed; nothing else we can do here.
    }
  }

  Future<void> stop() async {
    _stopRequested = true;
    try {
      await _player.stop();
    } catch (_) {
      // Player may be in idle state; ignore.
    }
    try {
      await _tts.stop();
    } catch (_) {
      // FlutterTts may be uninitialised on some platforms.
    }
  }

  Future<void> dispose() async {
    await stop();
    try {
      await _player.dispose();
    } catch (_) {
      // Best-effort cleanup.
    }
  }
}

String _normalizeAudioUrl(String raw) {
  final trimmed = raw.trim();
  if (trimmed.startsWith('//')) {
    return 'https:$trimmed';
  }
  return trimmed;
}

double _clampRate(double rate) {
  if (rate.isNaN) return 1.0;
  if (rate < 0.5) return 0.5;
  if (rate > 1.5) return 1.5;
  return rate;
}

final reviewTtsServiceProvider = Provider<ReviewTtsService>((ref) {
  final service = ReviewTtsService();
  ref.onDispose(() => unawaited(service.dispose()));
  return service;
});
