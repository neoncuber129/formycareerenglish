import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/core/sync/sync_service.dart';
import 'package:mobile/features/review/presentation/review_page.dart';
import 'package:mobile/features/vocab/data/vocab_repository_impl.dart';
import 'package:mobile/features/vocab/domain/vocab_repository.dart';
import 'package:shared_models/shared_models.dart';

class FakeVocabRepository implements VocabRepository {
  FakeVocabRepository(this._store);

  final List<Vocab> _store;

  @override
  Future<List<Vocab>> getAllVocab() async => List<Vocab>.from(_store);

  @override
  Future<List<Vocab>> getDueCards(DateTime now) async {
    return _store
        .where((item) => !item.nextReviewAt.isAfter(now) && !item.isArchived)
        .toList();
  }

  @override
  Future<void> saveVocab(Vocab vocab) async {
    _store.add(vocab);
  }

  @override
  Future<void> syncPending() async {}

  @override
  Future<void> updateReviewProgress(Vocab vocab) async {
    final index = _store.indexWhere((item) => item.id == vocab.id);
    if (index >= 0) {
      _store[index] = vocab;
    }
  }

  @override
  Future<List<Vocab>> getTrashedVocab() async => const <Vocab>[];

  @override
  Future<void> updateVocabsBulk(
    List<String> ids,
    Map<String, dynamic> updates,
  ) async {}

  @override
  Future<void> deleteVocabsBulk(List<String> ids) async {}

  @override
  Future<void> resetSrsBulk(List<String> ids) async {}

  @override
  Future<void> renameTagAcrossVocabs(String oldTag, String newTag) async {}

  @override
  Future<void> deleteTagAcrossVocabs(String tag) async {}
}

class _NoOpSyncService extends SyncService {
  _NoOpSyncService(super._repository);

  @override
  Future<void> pushPending() async {}

  @override
  Future<void> syncNow() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues(<String, Object>{});

  testWidgets('ReviewPage reveals answer and completes card', (tester) async {
    final card =
        Vocab.initial(
          id: 'review-1',
          sourceText: 'apple',
          translatedText: 'tao',
          languagePair: 'en-vi',
        ).copyWith(
          nextReviewAt: DateTime.now().subtract(const Duration(minutes: 2)),
          newLearningStepIndex: -1,
          reviewCount: 2,
        );

    final fakeRepository = FakeVocabRepository([card]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          vocabRepositoryProvider.overrideWithValue(fakeRepository),
          syncServiceProvider.overrideWith(
            (ref) => _NoOpSyncService(fakeRepository),
          ),
        ],
        child: const MaterialApp(home: ReviewPage()),
      ),
    );

    await tester.pumpAndSettle(const Duration(seconds: 5));
    expect(find.text('apple'), findsOneWidget);
    expect(find.text('tao'), findsNothing);

    await tester.tap(find.text('Tap to reveal'));
    await tester.pumpAndSettle();
    expect(find.textContaining('tao'), findsOneWidget);

    await tester.tap(find.text('Good'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Completed 1/1 cards.'), findsOneWidget);
  });
}
