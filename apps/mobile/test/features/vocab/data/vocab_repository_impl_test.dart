import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/vocab/data/vocab_datasource.dart';
import 'package:mobile/features/vocab/data/vocab_repository_impl.dart';
import 'package:shared_models/shared_models.dart';

void main() {
  group('VocabRepositoryImpl (mock datasource)', () {
    late VocabRepositoryImpl repository;

    setUp(() {
      repository = VocabRepositoryImpl(
        VocabDataSource(client: null, profileId: kDefaultLocalProfileId),
      );
    });

    test('saveVocab and getAllVocab persist data in mock store', () async {
      final vocab = Vocab.initial(
        id: '1',
        sourceText: 'hello',
        translatedText: 'xin chao',
        languagePair: 'en-vi',
      );

      await repository.saveVocab(vocab);
      final all = await repository.getAllVocab();

      expect(all, hasLength(1));
      expect(all.first.id, '1');
      expect(all.first.sourceText, 'hello');
    });

    test('updateReviewProgress updates existing entry', () async {
      final base = Vocab.initial(
        id: '2',
        sourceText: 'book',
        translatedText: 'sach',
        languagePair: 'en-vi',
      );

      await repository.saveVocab(base);
      await repository.updateReviewProgress(
        base.copyWith(
          reviewCount: 4,
          nextReviewAt: DateTime.now().add(const Duration(days: 7)),
        ),
      );

      final all = await repository.getAllVocab();
      expect(all, hasLength(1));
      expect(all.first.reviewCount, 4);
    });

    test('getDueCards returns only due cards', () async {
      final now = DateTime(2026, 4, 17, 12, 0);
      final due = Vocab.initial(
        id: 'due',
        sourceText: 'sun',
        translatedText: 'mat troi',
        languagePair: 'en-vi',
      ).copyWith(nextReviewAt: now.subtract(const Duration(minutes: 1)));

      final future = Vocab.initial(
        id: 'future',
        sourceText: 'moon',
        translatedText: 'mat trang',
        languagePair: 'en-vi',
      ).copyWith(nextReviewAt: now.add(const Duration(days: 1)));

      await repository.saveVocab(due);
      await repository.saveVocab(future);

      final dueCards = await repository.getDueCards(now);
      expect(dueCards.map((v) => v.id), ['due']);
    });

    test('syncPending is safe when supabase client is absent', () async {
      final vocab = Vocab.initial(
        id: '3',
        sourceText: 'tree',
        translatedText: 'cay',
        languagePair: 'en-vi',
      );

      await repository.saveVocab(vocab);
      await repository.syncPending();

      final all = await repository.getAllVocab();
      expect(all, hasLength(1));
    });
  });
}
