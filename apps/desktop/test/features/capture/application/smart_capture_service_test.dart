import 'package:desktop/features/capture/application/smart_capture_service.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeClipboardReader implements ClipboardReader {
  FakeClipboardReader(this.value, {this.throwOnRead = false});

  final String? value;
  final bool throwOnRead;

  @override
  Future<String?> readText() async {
    if (throwOnRead) {
      throw Exception('clipboard failed');
    }
    return value;
  }
}

void main() {
  group('SmartCaptureService', () {
    test('uses selected text before OCR when selection is short', () async {
      final service = SmartCaptureService(
        clipboardReader: FakeClipboardReader('obscure'),
      );

      final result = await service.detectBestWord(
        ocrExtractor: () async => 'paragraph from ocr',
      );

      expect(result.detectedText, 'obscure');
      expect(result.source, CaptureInputSource.selection);
    });

    test('falls back to OCR and extracts likely word', () async {
      final service = SmartCaptureService(
        clipboardReader: FakeClipboardReader(null),
      );

      final result = await service.detectBestWord(
        ocrExtractor: () async =>
            'The quick brown fox jumps over the sleeping dog near river.',
      );

      expect(result.detectedText.isNotEmpty, isTrue);
      expect(result.source, CaptureInputSource.ocr);
      expect(result.detectedText.length, greaterThanOrEqualTo(2));
    });

    test('ignores long selection and still uses OCR', () async {
      final service = SmartCaptureService(
        clipboardReader: FakeClipboardReader(
          'This is a very long selected sentence that should not be kept as one token.',
        ),
      );

      final result = await service.detectBestWord(
        ocrExtractor: () async => 'aberration detected around cursor',
      );

      expect(result.source, CaptureInputSource.ocr);
      expect(result.detectedText, isNotEmpty);
    });

    test('returns none when clipboard and OCR are unusable', () async {
      final service = SmartCaptureService(
        clipboardReader: FakeClipboardReader(null, throwOnRead: true),
      );

      final result = await service.detectBestWord(
        ocrExtractor: () async => '',
      );

      expect(result.source, CaptureInputSource.none);
      expect(result.detectedText, isEmpty);
    });

    test('text mode uses clipboard when valid and short', () async {
      final service = SmartCaptureService(
        clipboardReader: FakeClipboardReader('obscure'),
      );

      final result = await service.detectTextMode(
        ocrFallbackExtractor: () async => 'ocr fallback text',
      );

      expect(result.source, CaptureInputSource.selection);
      expect(result.detectedText, 'obscure');
    });

    test('text mode uses full clipboard even when long', () async {
      final long = List<String>.filled(220, 'a').join();
      final service = SmartCaptureService(
        clipboardReader: FakeClipboardReader(long),
      );

      final result = await service.detectTextMode(
        ocrFallbackExtractor: () async => 'fallbackword',
      );

      expect(result.source, CaptureInputSource.selection);
      expect(result.detectedText, long);
    });

    test('prefers content word over stopwords for OCR text', () async {
      final service = SmartCaptureService(
        clipboardReader: FakeClipboardReader(null),
      );

      final result = await service.detectBestWord(
        ocrExtractor: () async => 'the and but because vocabulary appears here',
      );

      expect(result.source, CaptureInputSource.ocr);
      expect(result.detectedText, 'vocabulary');
    });

    test('text mode uses clipboard even when only stopwords', () async {
      final service = SmartCaptureService(
        clipboardReader: FakeClipboardReader('the and but'),
      );

      final result = await service.detectTextMode(
        ocrFallbackExtractor: () async => 'aberration',
      );

      expect(result.source, CaptureInputSource.selection);
      expect(result.detectedText, 'the and but');
    });

    test('filters common Vietnamese stopwords from OCR text', () async {
      final service = SmartCaptureService(
        clipboardReader: FakeClipboardReader(null),
      );

      final result = await service.detectBestWord(
        ocrExtractor: () async => 'đây là một từ vocabulary cần học',
      );

      expect(result.source, CaptureInputSource.ocr);
      expect(result.detectedText, 'vocabulary');
    });

    test('keeps useful acronym tokens from OCR', () async {
      final service = SmartCaptureService(
        clipboardReader: FakeClipboardReader(null),
      );

      final result = await service.detectBestWord(
        ocrExtractor: () async => 'the and API integration',
      );

      expect(result.source, CaptureInputSource.ocr);
      expect(result.detectedText, 'integration');
    });

    test('text mode ignores clipboardMaxLength for full-passage selection', () async {
      final service = SmartCaptureService(
        clipboardReader: FakeClipboardReader('chosenword'),
        config: const SmartCaptureHeuristicConfig(
          clipboardMaxLength: 5,
        ),
      );

      final result = await service.detectTextMode(
        ocrFallbackExtractor: () async => 'fallbackword',
      );

      expect(result.source, CaptureInputSource.selection);
      expect(result.detectedText, 'chosenword');
    });

    test('supports runtime config to raise minimum token length', () async {
      final service = SmartCaptureService(
        clipboardReader: FakeClipboardReader(null),
        config: const SmartCaptureHeuristicConfig(
          minTokenLength: 4,
        ),
      );

      final result = await service.detectBestWord(
        ocrExtractor: () async => 'API understanding',
      );

      expect(result.source, CaptureInputSource.ocr);
      expect(result.detectedText, 'understanding');
    });

    test('pickDefaultFocusSpan returns null when passage exceeds token limit', () {
      final service = SmartCaptureService(
        clipboardReader: FakeClipboardReader(null),
      );
      expect(service.pickDefaultFocusSpan('one two three four'), isNull);
    });

    test('pickDefaultFocusSpan returns null when passage exceeds character limit', () {
      final service = SmartCaptureService(
        clipboardReader: FakeClipboardReader(null),
      );
      expect(
        service.pickDefaultFocusSpan('abcdefghijklmnopqrstuvwxyz1234567'),
        isNull,
      );
    });

    test('pickDefaultFocusSpan returns span for short passage', () {
      final service = SmartCaptureService(
        clipboardReader: FakeClipboardReader(null),
      );
      const passage = 'hello obscure world';
      final span = service.pickDefaultFocusSpan(passage);
      expect(span, isNotNull);
      expect(span!.start, greaterThanOrEqualTo(0));
      expect(span.end, lessThanOrEqualTo(passage.length));
      expect(passage.substring(span.start, span.end), isNotEmpty);
    });

    test('builds config from override map safely', () {
      final config = buildSmartCaptureHeuristicConfigFromEnvironment(
        overrides: <String, String>{
          'FORMYCAREER_CAPTURE_CLIPBOARD_MAX_LENGTH': '111',
          'FORMYCAREER_CAPTURE_MIN_TOKEN_LENGTH': '5',
          'FORMYCAREER_CAPTURE_STOPWORD_PENALTY': '9',
          'FORMYCAREER_CAPTURE_STOPWORDS_CSV': 'foo, bar ,baz',
        },
      );

      expect(config.clipboardMaxLength, 111);
      expect(config.minTokenLength, 5);
      expect(config.stopwordPenalty, 9);
      expect(config.stopwords, containsAll(<String>{'foo', 'bar', 'baz'}));
    });

    test('falls back to defaults when override values are invalid', () {
      final config = buildSmartCaptureHeuristicConfigFromEnvironment(
        overrides: <String, String>{
          'FORMYCAREER_CAPTURE_CLIPBOARD_MAX_LENGTH': 'oops',
          'FORMYCAREER_CAPTURE_STOPWORDS_CSV': '   ',
        },
      );

      expect(config.clipboardMaxLength, 200);
      expect(config.stopwords, contains('the'));
      expect(config.stopwords, contains('và'));
    });
  });
}
