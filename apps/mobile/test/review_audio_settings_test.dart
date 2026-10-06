import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/review/application/review_audio_settings.dart';

void main() {
  group('clampReviewTtsRate', () {
    test('snaps to nearest allowed option', () {
      expect(clampReviewTtsRate(0.5), 0.5);
      expect(clampReviewTtsRate(0.6), 0.5);
      expect(clampReviewTtsRate(0.7), 0.75);
      expect(clampReviewTtsRate(0.95), 1.0);
      expect(clampReviewTtsRate(2.0), 1.0);
    });

    test('coerces NaN / non-positive to 1.0', () {
      expect(clampReviewTtsRate(double.nan), 1.0);
      expect(clampReviewTtsRate(0), 1.0);
      expect(clampReviewTtsRate(-2), 1.0);
    });
  });

  group('clampReviewAudioLoopCount', () {
    test('keeps in-range counts', () {
      expect(clampReviewAudioLoopCount(1), 1);
      expect(clampReviewAudioLoopCount(2), 2);
      expect(clampReviewAudioLoopCount(3), 3);
    });

    test('clamps below 1 to 1 and above 3 to 3', () {
      expect(clampReviewAudioLoopCount(0), 1);
      expect(clampReviewAudioLoopCount(-5), 1);
      expect(clampReviewAudioLoopCount(99), 3);
    });
  });
}
