import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';

void main() {
  group('SrsCalculator new-card learning', () {
    final now = DateTime.utc(2026, 5, 2, 8, 0);
    const calc = SrsCalculator();

    test('Good from step 0 schedules first delay (1m)', () {
      final v = Vocab.initial(
        id: 'n1',
        sourceText: 'a',
        translatedText: 'b',
        languagePair: 'en-vi',
      );
      expect(v.newLearningStepIndex, 0);
      final next = calc.applyNewCardLearning(v, ReviewGrade.good, now);
      expect(next.newLearningStepIndex, 1);
      expect(next.nextReviewAt, now.add(SrsCalculator.newCardLearningDelays[0]));
      expect(next.reviewCount, 1);
    });

    test('Good from final learning step graduates to day-based', () {
      final v = Vocab.initial(
        id: 'n2',
        sourceText: 'a',
        translatedText: 'b',
        languagePair: 'en-vi',
      ).copyWith(newLearningStepIndex: 2, reviewCount: 2);
      final next = calc.applyNewCardLearning(v, ReviewGrade.good, now);
      expect(next.newLearningStepIndex, -1);
      expect(next.intervalDays, 1);
      expect(next.nextReviewAt, now.add(const Duration(days: 1)));
    });

    test('Again resets to step 0 with 1m delay', () {
      final v = Vocab.initial(
        id: 'n3',
        sourceText: 'a',
        translatedText: 'b',
        languagePair: 'en-vi',
      ).copyWith(newLearningStepIndex: 1, reviewCount: 1);
      final next = calc.applyNewCardLearning(v, ReviewGrade.again, now);
      expect(next.newLearningStepIndex, 0);
      expect(next.nextReviewAt, now.add(SrsCalculator.relearningFirstStep));
    });

    test('Easy during learning graduates immediately', () {
      final v = Vocab.initial(
        id: 'n4',
        sourceText: 'a',
        translatedText: 'b',
        languagePair: 'en-vi',
      ).copyWith(newLearningStepIndex: 0);
      final next = calc.applyNewCardLearning(v, ReviewGrade.easy, now);
      expect(next.newLearningStepIndex, -1);
      expect(next.intervalDays, 2);
    });
  });

  group('buildStudyQueueFromDue', () {
    final now = DateTime.utc(2026, 5, 2, 12, 0);
    Vocab mature(String id, double ease) => Vocab.initial(
          id: id,
          sourceText: id,
          translatedText: 't',
          languagePair: 'en-vi',
        ).copyWith(
          newLearningStepIndex: -1,
          reviewCount: 3,
          easeFactor: ease,
          nextReviewAt: now,
        );

    Vocab fresh(String id) => Vocab.initial(
          id: id,
          sourceText: id,
          translatedText: 't',
          languagePair: 'en-vi',
        );

    test('interleaves with cap on new side', () {
      final matureList = List.generate(15, (i) => mature('m$i', 2.4));
      final freshList = List.generate(8, (i) => fresh('f$i'));
      final due = [...matureList, ...freshList];
      due.sort(compareVocabReviewPriority);
      final q = buildStudyQueueFromDue(
        dueSorted: due,
        options: const CustomStudyOptions(
          maxNewCardsPerSession: 3,
          reviewsBeforeInsertNew: 5,
        ),
      );
      expect(q.length, 18);
      expect(q.where((v) => v.id.startsWith('f')).length, 3);
    });
  });
}
