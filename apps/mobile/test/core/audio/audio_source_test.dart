import 'package:mobile/core/audio/audio_source.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('normalizeGoogleTtsLanguage', () {
    test('falls back when input is empty or auto', () {
      expect(normalizeGoogleTtsLanguage(null), 'en');
      expect(normalizeGoogleTtsLanguage(''), 'en');
      expect(normalizeGoogleTtsLanguage('auto'), 'en');
      expect(normalizeGoogleTtsLanguage('autodetect'), 'en');
      expect(normalizeGoogleTtsLanguage(' AUTO '), 'en');
      expect(normalizeGoogleTtsLanguage('', fallback: 'vi'), 'vi');
    });

    test('strips region tag and lowercases', () {
      expect(normalizeGoogleTtsLanguage('en-US'), 'en');
      expect(normalizeGoogleTtsLanguage('VI_VN'), 'vi');
      expect(normalizeGoogleTtsLanguage('  Fr-fr '), 'fr');
    });

    test('Chinese maps to zh-CN by default and zh-TW for traditional', () {
      expect(normalizeGoogleTtsLanguage('zh'), 'zh-CN');
      expect(normalizeGoogleTtsLanguage('zh-CN'), 'zh-CN');
      expect(normalizeGoogleTtsLanguage('zh-TW'), 'zh-TW');
      expect(normalizeGoogleTtsLanguage('zh-Hant'), 'zh-TW');
      expect(normalizeGoogleTtsLanguage('zt'), 'zh-TW');
    });

    test('legacy ISO codes are remapped (iw->he, jw->jv)', () {
      expect(normalizeGoogleTtsLanguage('iw'), 'he');
      expect(normalizeGoogleTtsLanguage('jw'), 'jv');
    });
  });

  group('chunkTextForGoogleTts', () {
    test('returns single chunk when below limit', () {
      expect(
        chunkTextForGoogleTts('hello world'),
        ['hello world'],
      );
    });

    test('returns empty list for blank input', () {
      expect(chunkTextForGoogleTts(''), isEmpty);
      expect(chunkTextForGoogleTts('   '), isEmpty);
    });

    test('splits at sentence boundary without breaking words', () {
      final long = 'First sentence. Second sentence here. Third one. ' * 4;
      final chunks = chunkTextForGoogleTts(long, maxChunk: 60);
      expect(chunks.length, greaterThan(1));
      for (final chunk in chunks) {
        expect(chunk.length, lessThanOrEqualTo(60));
        expect(chunk.trim(), isNotEmpty);
      }
      expect(chunks.join(' ').replaceAll(RegExp(r'\s+'), ' ').trim(),
          contains('First sentence.'));
    });

    test('splits long sentence by words', () {
      final long = 'word ' * 60; // 300 chars without periods
      final chunks = chunkTextForGoogleTts(long.trim(), maxChunk: 50);
      expect(chunks, isNotEmpty);
      for (final chunk in chunks) {
        expect(chunk.length, lessThanOrEqualTo(50));
        expect(chunk.contains('  '), isFalse);
      }
    });

    test('hard splits a single oversized token', () {
      final huge = 'x' * 250;
      final chunks = chunkTextForGoogleTts(huge, maxChunk: 100);
      expect(chunks.length, 3);
      expect(chunks[0].length, 100);
      expect(chunks[1].length, 100);
      expect(chunks[2].length, 50);
    });
  });

  group('buildGoogleTtsUrls', () {
    test('returns empty list for empty text', () {
      expect(buildGoogleTtsUrls('', 'en'), isEmpty);
      expect(buildGoogleTtsUrls('   ', 'en'), isEmpty);
    });

    test('produces a URL with the expected query parameters', () {
      final urls = buildGoogleTtsUrls('hello', 'en-US');
      expect(urls, hasLength(1));
      final uri = Uri.parse(urls.first);
      expect(uri.host, 'translate.google.com');
      expect(uri.path, '/translate_tts');
      expect(uri.queryParameters['client'], 'tw-ob');
      expect(uri.queryParameters['tl'], 'en');
      expect(uri.queryParameters['q'], 'hello');
      expect(uri.queryParameters['idx'], '0');
      expect(uri.queryParameters['total'], '1');
      expect(uri.queryParameters['textlen'], '5');
    });

    test('emits one url per chunk and idx counts up', () {
      final input = List.generate(6, (i) => 'Sentence number $i.').join(' ');
      final urls = buildGoogleTtsUrls(input, 'vi', maxChunk: 30);
      expect(urls.length, greaterThan(1));
      for (var i = 0; i < urls.length; i++) {
        final uri = Uri.parse(urls[i]);
        expect(uri.queryParameters['idx'], '$i');
        expect(uri.queryParameters['total'], '${urls.length}');
        expect(uri.queryParameters['tl'], 'vi');
      }
    });

    test('empty language falls back to en', () {
      final urls = buildGoogleTtsUrls('hello', '', maxChunk: 30);
      expect(urls, hasLength(1));
      expect(Uri.parse(urls.first).queryParameters['tl'], 'en');
    });
  });

  group('ttsBackendFromString', () {
    test('defaults to auto', () {
      expect(ttsBackendFromString(null), TtsBackendChoice.auto);
      expect(ttsBackendFromString(''), TtsBackendChoice.auto);
      expect(ttsBackendFromString('AUTO'), TtsBackendChoice.auto);
      expect(ttsBackendFromString('something_else'), TtsBackendChoice.auto);
    });

    test('recognises google aliases', () {
      expect(ttsBackendFromString('google'), TtsBackendChoice.google);
      expect(ttsBackendFromString('gtrans'), TtsBackendChoice.google);
      expect(ttsBackendFromString('Translate'), TtsBackendChoice.google);
    });

    test('recognises os aliases', () {
      expect(ttsBackendFromString('os'), TtsBackendChoice.os);
      expect(ttsBackendFromString('native'), TtsBackendChoice.os);
      expect(ttsBackendFromString('sapi'), TtsBackendChoice.os);
      expect(ttsBackendFromString('say'), TtsBackendChoice.os);
      expect(ttsBackendFromString('flutter_tts'), TtsBackendChoice.os);
    });
  });
}

