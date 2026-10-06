import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';

void main() {
  group('selectDueVocabsSorted', () {
    final now = DateTime.utc(2026, 4, 18, 12);

    test('excludes archived and future reviews', () {
      final due = Vocab.initial(
        id: '1',
        sourceText: 'a',
        translatedText: 'a',
        languagePair: 'en-vi',
      ).copyWith(nextReviewAt: now.subtract(const Duration(days: 1)));
      final future = Vocab.initial(
        id: '2',
        sourceText: 'b',
        translatedText: 'b',
        languagePair: 'en-vi',
      ).copyWith(nextReviewAt: now.add(const Duration(days: 1)));
      final archived = Vocab.initial(
        id: '3',
        sourceText: 'c',
        translatedText: 'c',
        languagePair: 'en-vi',
      ).copyWith(
        nextReviewAt: now,
        isArchived: true,
      );

      final q = selectDueVocabsSorted([due, future, archived], now);
      expect(q.map((e) => e.id).toList(), ['1']);
    });

    test('orders by easeFactor ascending then earliest nextReviewAt', () {
      final easyFirst = Vocab.initial(
        id: 'easy',
        sourceText: 'e',
        translatedText: 'e',
        languagePair: 'en-vi',
      ).copyWith(
        easeFactor: 2.4,
        nextReviewAt: now.subtract(const Duration(days: 10)),
      );
      final hardLater = Vocab.initial(
        id: 'hard',
        sourceText: 'h',
        translatedText: 'h',
        languagePair: 'en-vi',
      ).copyWith(
        easeFactor: 1.4,
        nextReviewAt: now.subtract(const Duration(days: 1)),
      );

      final q = selectDueVocabsSorted([easyFirst, hardLater], now);
      expect(q.map((e) => e.id).toList(), ['hard', 'easy']);
    });

    test('same ease: more overdue (earlier nextReviewAt) first', () {
      final recent = Vocab.initial(
        id: 'r',
        sourceText: 'r',
        translatedText: 'r',
        languagePair: 'en-vi',
      ).copyWith(
        easeFactor: 2.0,
        nextReviewAt: now.subtract(const Duration(hours: 1)),
      );
      final old = Vocab.initial(
        id: 'o',
        sourceText: 'o',
        translatedText: 'o',
        languagePair: 'en-vi',
      ).copyWith(
        easeFactor: 2.0,
        nextReviewAt: now.subtract(const Duration(days: 5)),
      );

      final q = selectDueVocabsSorted([recent, old], now);
      expect(q.map((e) => e.id).toList(), ['o', 'r']);
    });
  });
}
