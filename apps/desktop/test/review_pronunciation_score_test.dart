import 'package:desktop/features/review/application/stt_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('pronunciationSimilarityPercent', () {
    test('identical words score 100', () {
      expect(pronunciationSimilarityPercent('apple', 'apple'), 100);
      expect(pronunciationSimilarityPercent('Apple ', 'apple'), 100);
    });

    test('case + punctuation insensitive', () {
      expect(pronunciationSimilarityPercent('hello!', 'HELLO'), 100);
    });

    test('partial match is in 0..100 range', () {
      final score = pronunciationSimilarityPercent('aple', 'apple');
      expect(score, greaterThan(50));
      expect(score, lessThan(100));
    });

    test('very different words score below 50', () {
      expect(
        pronunciationSimilarityPercent('zebra', 'apple'),
        lessThanOrEqualTo(40),
      );
    });

    test('empty inputs score 0', () {
      expect(pronunciationSimilarityPercent('', 'apple'), 0);
      expect(pronunciationSimilarityPercent('apple', ''), 0);
    });
  });

  group('sttLocaleFromLanguageCode', () {
    test('common languages map to BCP-47 locales', () {
      expect(sttLocaleFromLanguageCode('en'), 'en-US');
      expect(sttLocaleFromLanguageCode('vi'), 'vi-VN');
      expect(sttLocaleFromLanguageCode('ja'), 'ja-JP');
    });

    test('unknown codes get a sensible default region', () {
      expect(sttLocaleFromLanguageCode('xx'), 'xx-XX');
    });

    test('empty falls back to en-US', () {
      expect(sttLocaleFromLanguageCode(''), 'en-US');
    });
  });
}
