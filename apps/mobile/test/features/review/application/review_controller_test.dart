import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/monetization/app_state.dart';
import 'package:mobile/core/sync/sync_service.dart';
import 'package:mobile/features/review/application/review_controller.dart';
import 'package:mobile/features/vocab/data/vocab_repository_impl.dart';
import 'package:mobile/features/vocab/domain/vocab_repository.dart';
import 'package:shared_models/shared_models.dart';

class _FakeRepo implements VocabRepository {
  _FakeRepo(this._items);

  final List<Vocab> _items;

  @override
  Future<List<Vocab>> getAllVocab() async => List<Vocab>.from(_items);

  @override
  Future<List<Vocab>> getDueCards(DateTime now) async => const [];

  @override
  Future<void> saveVocab(Vocab vocab) async {}

  @override
  Future<void> syncPending() async {}

  @override
  Future<void> updateReviewProgress(Vocab vocab) async {
    final i = _items.indexWhere((e) => e.id == vocab.id);
    if (i >= 0) {
      _items[i] = vocab;
    }
  }

  @override
  Future<List<Vocab>> getTrashedVocab() async => const [];

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

class _ReviewTestAppState extends AppStateController {
  @override
  AppState build() {
    unawaited(initialize());
    return AppState(
      isPro: true,
      isInitialized: true,
      isAdsEnabled: true,
      adUrl: 'https://formycareer.vercel.app',
      currentVersion: '0.0.0',
      latestVersion: '0.0.0',
      minSupportedVersion: '0.0.0',
      downloadUrl: 'https://formycareer.vercel.app',
      forceUpdate: false,
      releaseNotes: '',
      licenseVerifyUrl: '',
      proProvider: 'lemonsqueezy',
      gumroadProductPermalink: '',
      gumroadVerifyUrl: 'https://api.gumroad.com/v2/licenses/verify',
      gumroadUseIncrementUsesCount: false,
      lemonLicenseProxyUrl: '',
      lemonLicenseProxyAuthToken: '',
      lemonVerifyUrl: 'https://api.lemonsqueezy.com/v1/licenses/validate',
      lemonActivateUrl: 'https://api.lemonsqueezy.com/v1/licenses/activate',
      lemonInstanceName: 'FormyCareer Mobile',
      lemonStoreName: 'Lemon Squeezy',
      lemonExpectedStoreId: '',
      lemonExpectedProductId: '',
      lemonExpectedVariantId: '',
      freeDailyReviewGradesUsed: 0,
      freeDailyReviewLimit: AppState.defaultFreeDailyReviewLimit,
    );
  }

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> tryConsumeDailyReviewGrade() async => true;
}

class _CountingSyncService extends SyncService {
  _CountingSyncService(super._repository);

  int pushPendingCallCount = 0;

  @override
  Future<void> pushPending() async {
    pushPendingCallCount++;
  }

  @override
  Future<void> syncNow() async {}
}

Vocab _dueVocab({required String id, required DateTime now}) {
  return Vocab.initial(
    id: id,
    sourceText: id,
    translatedText: id,
    languagePair: 'en-vi',
  ).copyWith(
    nextReviewAt: now.subtract(const Duration(hours: 1)),
    newLearningStepIndex: -1,
    reviewCount: 3,
  );
}

void main() {
  test('load uses due filter and ease-first sort', () async {
    final now = DateTime.now();
    final easy =
        Vocab.initial(
          id: 'easy',
          sourceText: 'a',
          translatedText: 'a',
          languagePair: 'en-vi',
        ).copyWith(
          easeFactor: 2.5,
          nextReviewAt: now.subtract(const Duration(days: 1)),
          newLearningStepIndex: -1,
          reviewCount: 2,
        );
    final hard =
        Vocab.initial(
          id: 'hard',
          sourceText: 'b',
          translatedText: 'b',
          languagePair: 'en-vi',
        ).copyWith(
          easeFactor: 1.4,
          nextReviewAt: now.subtract(const Duration(days: 2)),
          newLearningStepIndex: -1,
          reviewCount: 2,
        );
    final future = Vocab.initial(
      id: 'future',
      sourceText: 'c',
      translatedText: 'c',
      languagePair: 'en-vi',
    ).copyWith(nextReviewAt: now.add(const Duration(days: 1)));

    final repo = _FakeRepo([easy, hard, future]);
    final sync = _CountingSyncService(repo);
    final container = ProviderContainer(
      overrides: [
        vocabRepositoryProvider.overrideWithValue(repo),
        syncServiceProvider.overrideWith((ref) => sync),
        appStateProvider.overrideWith(_ReviewTestAppState.new),
      ],
    );
    addTearDown(container.dispose);

    await container.read(reviewControllerProvider.notifier).load();
    final s = container.read(reviewControllerProvider);
    expect(s.cards.map((e) => e.id).toList(), ['hard', 'easy']);
    expect(sync.pushPendingCallCount, 0);
  });

  test('answer records history and advances', () async {
    final now = DateTime.now();
    final card = Vocab.initial(
      id: 'c1',
      sourceText: 'w',
      translatedText: 't',
      languagePair: 'en-vi',
    ).copyWith(
      nextReviewAt: now.subtract(const Duration(hours: 1)),
      newLearningStepIndex: -1,
      reviewCount: 2,
    );

    final repo = _FakeRepo([card]);
    final sync = _CountingSyncService(repo);
    final container = ProviderContainer(
      overrides: [
        vocabRepositoryProvider.overrideWithValue(repo),
        syncServiceProvider.overrideWith((ref) => sync),
        appStateProvider.overrideWith(_ReviewTestAppState.new),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(reviewControllerProvider.notifier);
    await notifier.load();
    notifier.toggleFlip();
    expect(container.read(reviewControllerProvider).isFlipped, isTrue);

    await notifier.answer(ReviewGrade.good);
    final after = container.read(reviewControllerProvider);
    expect(after.answeredCount, 1);
    expect(after.sessionHistory.single.grade, ReviewGrade.good);
    expect(after.sessionHistory.single.vocabAfterReview.id, 'c1');
    expect(after.isFlipped, isFalse);
    expect(after.hasFinished, isTrue);
    expect(after.currentIndex, 0);
    final result = after.sessionResult;
    expect(result, isNotNull);
    expect(result!.totalReviewed, 1);
    expect(result.masteredCount, 1);
    expect(result.duration, isNot(lessThan(Duration.zero)));
    expect(sync.pushPendingCallCount, 1);
  });

  test(
    'session end duration equals elapsed wall time from load to last answer',
    () async {
      var now = DateTime.utc(2024, 6, 10, 14, 0, 0);
      await withClock(Clock(() => now), () async {
        final card = _dueVocab(id: 'solo', now: now);
        final repo = _FakeRepo([card]);
        final sync = _CountingSyncService(repo);
        final container = ProviderContainer(
          overrides: [
            vocabRepositoryProvider.overrideWithValue(repo),
            syncServiceProvider.overrideWith((ref) => sync),
            appStateProvider.overrideWith(_ReviewTestAppState.new),
          ],
        );
        addTearDown(container.dispose);

        final notifier = container.read(reviewControllerProvider.notifier);
        await notifier.load();

        now = now.add(const Duration(minutes: 4, seconds: 7));

        await notifier.answer(ReviewGrade.good);
        final result = container.read(reviewControllerProvider).sessionResult!;

        expect(result.duration, const Duration(minutes: 4, seconds: 7));
        expect(sync.pushPendingCallCount, 1);
      });
    },
  );

  test('masteredCount increases on Good and Easy, not on Again', () async {
    var now = DateTime.utc(2024, 3, 1, 9, 0, 0);
    await withClock(Clock(() => now), () async {
      final a = _dueVocab(id: 'a', now: now);
      final b = _dueVocab(id: 'b', now: now);
      final repo = _FakeRepo([a, b]);
      final sync = _CountingSyncService(repo);
      final container = ProviderContainer(
        overrides: [
          vocabRepositoryProvider.overrideWithValue(repo),
          syncServiceProvider.overrideWith((ref) => sync),
          appStateProvider.overrideWith(_ReviewTestAppState.new),
        ],
      );
      addTearDown(container.dispose);
      final notifier = container.read(reviewControllerProvider.notifier);
      await notifier.load();

      await notifier.answer(ReviewGrade.again);
      var s = container.read(reviewControllerProvider);
      expect(s.sessionResult, isNull);
      expect(s.waitingCardCount, 1);
      expect(sync.pushPendingCallCount, 1);

      await notifier.answer(ReviewGrade.good);
      s = container.read(reviewControllerProvider);
      expect(s.sessionResult, isNull);
      expect(s.hasFinished, isFalse);
      expect(sync.pushPendingCallCount, 2);
    });
  });

  test('masteredCount tracks Good and Easy across session', () async {
    var now = DateTime.utc(2024, 3, 1, 9, 0, 0);
    await withClock(Clock(() => now), () async {
      final cards = [
        _dueVocab(id: 'x1', now: now),
        _dueVocab(id: 'x2', now: now),
        _dueVocab(id: 'x3', now: now),
      ];
      final repo = _FakeRepo(cards);
      final sync = _CountingSyncService(repo);
      final container = ProviderContainer(
        overrides: [
          vocabRepositoryProvider.overrideWithValue(repo),
          syncServiceProvider.overrideWith((ref) => sync),
          appStateProvider.overrideWith(_ReviewTestAppState.new),
        ],
      );
      addTearDown(container.dispose);
      final notifier = container.read(reviewControllerProvider.notifier);
      await notifier.load();

      await notifier.answer(ReviewGrade.good);
      await notifier.answer(ReviewGrade.easy);
      await notifier.answer(ReviewGrade.again);

      final state = container.read(reviewControllerProvider);
      expect(state.sessionResult, isNull);
      expect(state.waitingCardCount, 0);
      expect(state.currentCard, isNotNull);
      expect(sync.pushPendingCallCount, 3);
    });
  });

  test('navigation signal: last answer sets currentIndex == cards.length '
      'and sessionResult (was null)', () async {
    var now = DateTime.utc(2024, 5, 1, 12, 0, 0);
    await withClock(Clock(() => now), () async {
      final cards = [
        _dueVocab(id: 'n1', now: now),
        _dueVocab(id: 'n2', now: now),
      ];
      final repo = _FakeRepo(cards);
      final sync = _CountingSyncService(repo);
      final container = ProviderContainer(
        overrides: [
          vocabRepositoryProvider.overrideWithValue(repo),
          syncServiceProvider.overrideWith((ref) => sync),
          appStateProvider.overrideWith(_ReviewTestAppState.new),
        ],
      );
      addTearDown(container.dispose);
      final notifier = container.read(reviewControllerProvider.notifier);
      await notifier.load();

      final initial = container.read(reviewControllerProvider);
      expect(initial.sessionResult, isNull);
      expect(initial.currentIndex, 0);
      expect(initial.hasFinished, isFalse);

      await notifier.answer(ReviewGrade.good);
      final mid = container.read(reviewControllerProvider);
      expect(mid.sessionResult, isNull);
      expect(mid.currentIndex, 0);
      expect(mid.hasFinished, isFalse);

      await notifier.answer(ReviewGrade.good);
      final end = container.read(reviewControllerProvider);
      expect(end.sessionResult, isNotNull);
      expect(end.currentIndex, 0);
      expect(end.hasFinished, isTrue);
      expect(end.currentCard, isNull);

      // Mirrors [SrsReviewScreen] listener: first non-null sessionResult.
      expect(initial.sessionResult, isNull);
      expect(mid.sessionResult, isNull);
      expect(end.sessionResult, isNotNull);
      expect(sync.pushPendingCallCount, 2);
    });
  });

  test('Again schedules card into relearning waiting queue', () async {
    final now = DateTime.utc(2024, 7, 2, 10, 0, 0);
    final card = _dueVocab(id: 'again', now: now);
    final repo = _FakeRepo([card]);
    final sync = _CountingSyncService(repo);
    final container = ProviderContainer(
      overrides: [
        vocabRepositoryProvider.overrideWithValue(repo),
        syncServiceProvider.overrideWith((ref) => sync),
        appStateProvider.overrideWith(_ReviewTestAppState.new),
      ],
    );
    addTearDown(container.dispose);
    final notifier = container.read(reviewControllerProvider.notifier);
    await notifier.load();

    await notifier.answer(ReviewGrade.again);
    final state = container.read(reviewControllerProvider);
    expect(state.currentCard, isNotNull);
    expect(state.currentCard!.id, 'again');
    expect(state.waitingCardCount, 0);
    expect(state.hasFinished, isFalse);
  });

  test('pushPending is called after every answer', () async {
    var now = DateTime.utc(2024, 7, 1, 8, 0, 0);
    await withClock(Clock(() => now), () async {
      final cards = [
        _dueVocab(id: 'p1', now: now),
        _dueVocab(id: 'p2', now: now),
      ];
      final repo = _FakeRepo(cards);
      final sync = _CountingSyncService(repo);
      final container = ProviderContainer(
        overrides: [
          vocabRepositoryProvider.overrideWithValue(repo),
          syncServiceProvider.overrideWith((ref) => sync),
          appStateProvider.overrideWith(_ReviewTestAppState.new),
        ],
      );
      addTearDown(container.dispose);
      final notifier = container.read(reviewControllerProvider.notifier);
      await notifier.load();

      await notifier.answer(ReviewGrade.good);
      expect(sync.pushPendingCallCount, 1);

      await notifier.answer(ReviewGrade.good);
      expect(sync.pushPendingCallCount, 2);
    });
  });
}
