import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';

void main() {
  group('SrsCalculator next review scheduling', () {
    final now = DateTime.utc(2026, 4, 18, 10, 30);
    const calc = SrsCalculator();

    test('Again: 1 day interval and nextReviewAt is tomorrow', () {
      final v = Vocab.initial(
        id: '1',
        sourceText: 'x',
        translatedText: 'y',
        languagePair: 'en-vi',
      ).copyWith(
        intervalDays: 5,
        easeFactor: 2.5,
        nextReviewAt: now,
      );
      final next = calc.applyReview(v, ReviewGrade.again, now);
      expect(next.intervalDays, 1);
      expect(next.nextReviewAt, now.add(const Duration(days: 1)));
      expect(next.reviewCount, v.reviewCount + 1);
      expect(next.easeFactor, lessThan(v.easeFactor));
    });

    test('Lapse again enters relearning first step (1 minute)', () {
      final v = Vocab.initial(
        id: 'lapse-1',
        sourceText: 'x',
        translatedText: 'y',
        languagePair: 'en-vi',
      ).copyWith(intervalDays: 9, easeFactor: 2.4, nextReviewAt: now);
      final next = calc.applyLapseAgain(v, now);
      expect(next.nextReviewAt, now.add(const Duration(minutes: 1)));
      expect(next.reviewCount, v.reviewCount + 1);
      expect(next.easeFactor, lessThan(v.easeFactor));
    });

    test('Relearning pass schedules second step (10 minutes)', () {
      final v = Vocab.initial(
        id: 'lapse-2',
        sourceText: 'x',
        translatedText: 'y',
        languagePair: 'en-vi',
      ).copyWith(nextReviewAt: now);
      final next = calc.scheduleRelearningStep(
        v,
        now,
        SrsCalculator.relearningSecondStep,
      );
      expect(next.nextReviewAt, now.add(const Duration(minutes: 10)));
      expect(next.reviewCount, v.reviewCount + 1);
    });

    test('Relearning graduation uses strict short interval reset', () {
      final v = Vocab.initial(
        id: 'lapse-3',
        sourceText: 'x',
        translatedText: 'y',
        languagePair: 'en-vi',
      ).copyWith(intervalDays: 30, easeFactor: 2.1, nextReviewAt: now);
      final next = calc.graduateFromRelearning(
        v,
        ReviewGrade.good,
        now,
        preLapseIntervalDays: 30,
      );
      expect(next.intervalDays, 1);
      expect(next.nextReviewAt, now.add(const Duration(days: 1)));
    });

    test('Hard: interval between Again and Good', () {
      final v = Vocab.initial(
        id: '1',
        sourceText: 'x',
        translatedText: 'y',
        languagePair: 'en-vi',
      ).copyWith(
        intervalDays: 10,
        easeFactor: 2.5,
        nextReviewAt: now,
      );
      final again = calc.applyReview(v, ReviewGrade.again, now);
      final hard = calc.applyReview(v, ReviewGrade.hard, now);
      final good = calc.applyReview(v, ReviewGrade.good, now);
      expect(hard.intervalDays, greaterThan(again.intervalDays));
      expect(hard.intervalDays, lessThan(good.intervalDays));
      expect(hard.nextReviewAt.isAfter(again.nextReviewAt), isTrue);
      expect(good.nextReviewAt.isAfter(hard.nextReviewAt), isTrue);
    });

    test('Good: interval from formula and nextReviewAt matches interval days', () {
      final v = Vocab.initial(
        id: '1',
        sourceText: 'x',
        translatedText: 'y',
        languagePair: 'en-vi',
      ).copyWith(
        intervalDays: 4,
        easeFactor: 2.5,
        nextReviewAt: now,
      );
      final next = calc.applyReview(v, ReviewGrade.good, now);
      final expectedDays = (4 * 2.5).round();
      expect(next.intervalDays, expectedDays);
      expect(next.nextReviewAt, now.add(Duration(days: expectedDays)));
    });

    test('Easy: longer interval than Good for same card', () {
      final v = Vocab.initial(
        id: '1',
        sourceText: 'x',
        translatedText: 'y',
        languagePair: 'en-vi',
      ).copyWith(
        intervalDays: 4,
        easeFactor: 2.5,
        nextReviewAt: now,
      );
      final good = calc.applyReview(v, ReviewGrade.good, now);
      final easy = calc.applyReview(v, ReviewGrade.easy, now);
      expect(
        easy.nextReviewAt.isAfter(good.nextReviewAt) ||
            easy.nextReviewAt.isAtSameMomentAs(good.nextReviewAt),
        isTrue,
      );
      expect(easy.intervalDays, greaterThanOrEqualTo(good.intervalDays));
    });

    test('Again on repeatedly failed card adds leech tag', () {
      final v = Vocab.initial(
        id: 'leech-candidate',
        sourceText: 'x',
        translatedText: 'y',
        languagePair: 'en-vi',
      ).copyWith(
        intervalDays: 2,
        easeFactor: 1.62,
        reviewCount: 8,
        nextReviewAt: now,
      );
      final next = calc.applyReview(v, ReviewGrade.again, now);
      expect(next.tags, contains(SrsCalculator.leechTag));
    });

    test('Good review can remove leech tag after recovery interval', () {
      final v = Vocab.initial(
        id: 'leech-recovery',
        sourceText: 'x',
        translatedText: 'y',
        languagePair: 'en-vi',
        tags: const [SrsCalculator.leechTag],
      ).copyWith(
        intervalDays: 3,
        easeFactor: 1.8,
        reviewCount: 12,
        nextReviewAt: now,
      );
      final next = calc.applyReview(v, ReviewGrade.good, now);
      expect(next.tags, isNot(contains(SrsCalculator.leechTag)));
    });
  });
}
