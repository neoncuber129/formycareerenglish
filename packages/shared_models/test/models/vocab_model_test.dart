import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';

void main() {
  group('Vocab model', () {
    test('initial factory sets expected defaults', () {
      final vocab = Vocab.initial(
        id: 'v1',
        sourceText: 'hello',
        translatedText: 'xin chao',
        languagePair: 'en-vi',
      );

      expect(vocab.id, 'v1');
      expect(vocab.sourceUrl, isEmpty);
      expect(vocab.intervalDays, 1);
      expect(vocab.reviewCount, 0);
      expect(vocab.newLearningStepIndex, 0);
      expect(vocab.easeFactor, 2.5);
      expect(vocab.nextReviewAt.isAfter(vocab.createdAt.subtract(const Duration(seconds: 1))), isTrue);
      expect(vocab.isArchived, isFalse);
      expect(vocab.deletedAt, isNull);
    });

    test('initial factory accepts sourceUrl', () {
      final vocab = Vocab.initial(
        id: 'v1',
        sourceText: 'hello',
        translatedText: 'xin chao',
        languagePair: 'en-vi',
        sourceUrl: 'https://example.com/article#frag',
      );
      expect(vocab.sourceUrl, 'https://example.com/article#frag');
    });

    test('toJson and fromJson round trip works', () {
      final now = DateTime(2026, 4, 17, 12, 0);
      final vocab = Vocab(
        id: 'abc',
        sourceText: 'book',
        translatedText: 'sach',
        languagePair: 'en-vi',
        createdAt: now,
        updatedAt: now,
        nextReviewAt: now.add(const Duration(days: 2)),
        intervalDays: 2,
        easeFactor: 2.6,
        reviewCount: 3,
        partOfSpeech: 'noun',
        phonetic: 'bʊk',
        originalSentence: 'I read a book.',
        contextParagraph: 'Paragraph about books.',
        sourceApp: 'Reader',
        sourceUrl: 'https://doc.example/page',
        imageAnchor: '/tmp/x.png',
        audioUrl: 'https://a.example/audio.mp3',
        tags: const <String>['tag1', 'tag2'],
        isArchived: true,
        deletedAt: now,
        newLearningStepIndex: -1,
      );

      final json = vocab.toJson();
      final restored = Vocab.fromJson(json);

      expect(restored.id, vocab.id);
      expect(restored.sourceText, vocab.sourceText);
      expect(restored.translatedText, vocab.translatedText);
      expect(restored.languagePair, vocab.languagePair);
      expect(restored.createdAt, vocab.createdAt);
      expect(restored.updatedAt, vocab.updatedAt);
      expect(restored.nextReviewAt, vocab.nextReviewAt);
      expect(restored.intervalDays, vocab.intervalDays);
      expect(restored.easeFactor, vocab.easeFactor);
      expect(restored.reviewCount, vocab.reviewCount);
      expect(restored.partOfSpeech, 'noun');
      expect(restored.phonetic, 'bʊk');
      expect(restored.originalSentence, 'I read a book.');
      expect(restored.contextParagraph, 'Paragraph about books.');
      expect(restored.sourceApp, 'Reader');
      expect(restored.sourceUrl, vocab.sourceUrl);
      expect(restored.imageAnchor, '/tmp/x.png');
      expect(restored.audioUrl, 'https://a.example/audio.mp3');
      expect(restored.tags, const <String>['tag1', 'tag2']);
      expect(restored.isArchived, isTrue);
      expect(restored.deletedAt, now);
      expect(restored.newLearningStepIndex, -1);
    });

    test('fromJson migrates missing learning index for fresh cards', () {
      final json = <String, dynamic>{
        'id': 'x',
        'source_text': 'a',
        'translated_text': 'b',
        'language_pair': 'en-vi',
        'created_at': '2026-05-01T00:00:00.000Z',
        'updated_at': '2026-05-01T00:00:00.000Z',
        'next_review_at': '2026-05-01T00:00:00.000Z',
        'interval_days': 1,
        'ease_factor': 2.5,
        'review_count': 0,
      };
      final v = Vocab.fromJson(json);
      expect(v.newLearningStepIndex, 0);
    });

    test('fromJson migrates missing learning index for studied cards', () {
      final json = <String, dynamic>{
        'id': 'x',
        'source_text': 'a',
        'translated_text': 'b',
        'language_pair': 'en-vi',
        'created_at': '2026-05-01T00:00:00.000Z',
        'updated_at': '2026-05-01T00:00:00.000Z',
        'next_review_at': '2026-05-02T00:00:00.000Z',
        'interval_days': 3,
        'ease_factor': 2.5,
        'review_count': 2,
      };
      final v = Vocab.fromJson(json);
      expect(v.newLearningStepIndex, -1);
    });

    test('copyWith overrides selective fields only', () {
      final base = Vocab.initial(
        id: 'v2',
        sourceText: 'water',
        translatedText: 'nuoc',
        languagePair: 'en-vi',
      );

      final updated = base.copyWith(
        translatedText: 'nuoc uong',
        reviewCount: 10,
      );

      expect(updated.id, base.id);
      expect(updated.sourceText, base.sourceText);
      expect(updated.translatedText, 'nuoc uong');
      expect(updated.reviewCount, 10);
      expect(updated.intervalDays, base.intervalDays);
    });

    test('applyVocabBulkUpdates soft delete and restore', () {
      final base = Vocab.initial(
        id: 'v3',
        sourceText: 'sun',
        translatedText: 'mat troi',
        languagePair: 'en-vi',
      );
      final t0 = DateTime(2026, 4, 18, 10, 0);
      final deleted = applyVocabBulkUpdates(
        base,
        <String, dynamic>{'deletedAt': t0},
        t0,
      );
      expect(deleted.deletedAt, t0);
      expect(deleted.updatedAt, t0);

      final restored = applyVocabBulkUpdates(
        deleted,
        <String, dynamic>{'deleted_at': null},
        t0.add(const Duration(minutes: 1)),
      );
      expect(restored.deletedAt, isNull);
    });
  });
}
