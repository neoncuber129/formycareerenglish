import 'package:desktop/features/capture/application/tts_service.dart';
import 'package:desktop/features/settings/application/settings_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('clampDesktopTtsRate', () {
    test('keeps in-range values', () {
      expect(clampDesktopTtsRate(0.5), 0.5);
      expect(clampDesktopTtsRate(0.75), 0.75);
      expect(clampDesktopTtsRate(1.0), 1.0);
      expect(clampDesktopTtsRate(1.5), 1.5);
    });

    test('clamps outliers to 0.5..1.5 range', () {
      expect(clampDesktopTtsRate(0.1), 0.5);
      expect(clampDesktopTtsRate(2.5), 1.5);
    });

    test('NaN coerces to 1.0', () {
      expect(clampDesktopTtsRate(double.nan), 1.0);
    });
  });

  group('sapiRateFromMultiplier', () {
    test('1.0 maps to 0 (default speed)', () {
      expect(sapiRateFromMultiplier(1.0), 0);
    });

    test('0.5 maps to -5 (slowest in our menu)', () {
      expect(sapiRateFromMultiplier(0.5), -5);
    });

    test('0.75 maps to roughly -3', () {
      expect(sapiRateFromMultiplier(0.75), inInclusiveRange(-3, -2));
    });

    test('values stay within SAPI -10..10 bounds', () {
      expect(sapiRateFromMultiplier(0.0), inInclusiveRange(-10, 10));
      expect(sapiRateFromMultiplier(5.0), 10);
    });
  });

  group('macOsSayRateFromMultiplier', () {
    test('1.0 maps to baseline 175 wpm', () {
      expect(macOsSayRateFromMultiplier(1.0), 175);
    });

    test('0.5 halves the wpm', () {
      expect(macOsSayRateFromMultiplier(0.5), inInclusiveRange(86, 90));
    });

    test('non-positive rate falls back to 175 wpm', () {
      expect(macOsSayRateFromMultiplier(0), 175);
      expect(macOsSayRateFromMultiplier(-1.0), 175);
    });
  });

  group('settings clamps', () {
    test('clampReviewTtsRate snaps to nearest allowed option', () {
      expect(clampReviewTtsRate(0.5), 0.5);
      expect(clampReviewTtsRate(0.6), 0.5);
      expect(clampReviewTtsRate(0.7), 0.75);
      expect(clampReviewTtsRate(0.95), 1.0);
      expect(clampReviewTtsRate(2.0), 1.0);
      expect(clampReviewTtsRate(double.nan), 1.0);
    });

    test('clampReviewAudioLoopCount stays within 1..3', () {
      expect(clampReviewAudioLoopCount(0), 1);
      expect(clampReviewAudioLoopCount(1), 1);
      expect(clampReviewAudioLoopCount(3), 3);
      expect(clampReviewAudioLoopCount(99), 3);
    });
  });
}
