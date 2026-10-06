import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';

void main() {
  group('sourceLanguageFromPair', () {
    test('returns the lhs of a normal pair', () {
      expect(sourceLanguageFromPair('en-vi'), 'en');
      expect(sourceLanguageFromPair('JA-EN'), 'ja');
    });

    test('falls back to default when empty / malformed', () {
      expect(sourceLanguageFromPair(''), 'en');
      expect(sourceLanguageFromPair('   '), 'en');
      expect(sourceLanguageFromPair('-vi'), 'en');
    });

    test('respects custom fallback for filter use cases', () {
      expect(sourceLanguageFromPair('', fallback: ''), '');
      expect(sourceLanguageFromPair('-vi', fallback: ''), '');
    });

    test('returns the trimmed pair when there is no dash', () {
      expect(sourceLanguageFromPair('en'), 'en');
    });
  });

  group('targetLanguageFromPair', () {
    test('returns the rhs of a normal pair', () {
      expect(targetLanguageFromPair('en-vi'), 'vi');
      expect(targetLanguageFromPair('JA-EN'), 'en');
    });

    test('falls back to default when empty / malformed', () {
      expect(targetLanguageFromPair(''), 'vi');
      expect(targetLanguageFromPair('en'), 'vi');
      expect(targetLanguageFromPair('en-'), 'vi');
    });

    test('respects custom fallback', () {
      expect(targetLanguageFromPair('', fallback: 'en'), 'en');
    });
  });
}
