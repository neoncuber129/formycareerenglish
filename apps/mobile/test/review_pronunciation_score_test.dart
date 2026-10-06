import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/review/application/stt_service.dart';

void main() {
  group('mobile pronunciationSimilarityPercent', () {
    test('identical words score 100', () {
      expect(pronunciationSimilarityPercent('apple', 'apple'), 100);
    });

    test('partial match is in (0,100) range', () {
      final score = pronunciationSimilarityPercent('aple', 'apple');
      expect(score, greaterThan(50));
      expect(score, lessThan(100));
    });

    test('empty inputs score 0', () {
      expect(pronunciationSimilarityPercent('', 'apple'), 0);
      expect(pronunciationSimilarityPercent('apple', ''), 0);
    });
  });

  group('mobile sttLocaleFromLanguageCode', () {
    test('common languages map correctly', () {
      expect(sttLocaleFromLanguageCode('en'), 'en-US');
      expect(sttLocaleFromLanguageCode('vi'), 'vi-VN');
    });

    test('empty falls back to en-US', () {
      expect(sttLocaleFromLanguageCode(''), 'en-US');
    });
  });
}
