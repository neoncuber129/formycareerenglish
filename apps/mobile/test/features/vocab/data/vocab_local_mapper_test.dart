import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/vocab/data/vocab_local_mapper.dart';
import 'package:shared_models/shared_models.dart';

void main() {
  group('VocabLocalMapper', () {
    test('toRecord/fromRecord keeps vocab data', () {
      final now = DateTime(2026, 4, 17, 10, 30);
      final vocab = Vocab(
        id: '123e4567-e89b-12d3-a456-426614174000',
        sourceText: 'hello',
        translatedText: 'xin chao',
        languagePair: 'en-vi',
        createdAt: now,
        updatedAt: now,
        nextReviewAt: now,
        intervalDays: 1,
        easeFactor: 2.5,
        reviewCount: 0,
      );

      final record = VocabLocalMapper.toRecord(
        vocab,
        syncStatus: SyncStatus.synced,
      );

      final restored = VocabLocalMapper.fromRecord(record);
      final syncStatus = VocabLocalMapper.readSyncStatus(record);

      expect(restored.id, vocab.id);
      expect(restored.sourceText, vocab.sourceText);
      expect(restored.translatedText, vocab.translatedText);
      expect(restored.languagePair, vocab.languagePair);
      expect(syncStatus, SyncStatus.synced);
    });

    test('legacy map is supported and defaults sync status pending', () {
      final now = DateTime(2026, 4, 17, 10, 30);
      final legacy = <String, dynamic>{
        'id': 'legacy-id',
        'source_text': 'book',
        'translated_text': 'sach',
        'language_pair': 'en-vi',
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
        'next_review_at': now.toIso8601String(),
        'interval_days': 1,
        'ease_factor': 2.5,
        'review_count': 0,
      };

      final restored = VocabLocalMapper.fromRecord(legacy);
      final syncStatus = VocabLocalMapper.readSyncStatus(legacy);

      expect(restored.id, 'legacy-id');
      expect(restored.sourceText, 'book');
      expect(syncStatus, SyncStatus.pending);
    });
  });
}
