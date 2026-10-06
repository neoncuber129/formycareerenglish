import 'dart:async';

import 'package:app_l10n/app_l10n.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/monetization/app_state.dart';
import 'package:mobile/core/sync/sync_service.dart';
import 'package:mobile/features/review/application/review_controller.dart';
import 'package:mobile/features/review/presentation/review_summary_screen.dart';
import 'package:mobile/features/review/presentation/srs_review_screen.dart';
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
    final index = _items.indexWhere((item) => item.id == vocab.id);
    if (index >= 0) {
      _items[index] = vocab;
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

class _ReviewScreenTestAppState extends AppStateController {
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

class _NoOpSyncService extends SyncService {
  _NoOpSyncService(super._repository);

  @override
  Future<void> pushPending() async {}

  @override
  Future<void> syncNow() async {}
}

Widget _buildTestApp({required Widget home}) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: home,
  );
}

AppLocalizations _l10n(WidgetTester tester) {
  final context = tester.element(find.byType(SrsReviewScreen));
  return AppLocalizations.of(context)!;
}

Future<void> _pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  int maxPumps = 40,
  Duration step = const Duration(milliseconds: 100),
}) async {
  for (var i = 0; i < maxPumps; i++) {
    await tester.pump(step);
    if (finder.evaluate().isNotEmpty) {
      return;
    }
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues(<String, Object>{});

  testWidgets('inline audio button is visible on both faces', (tester) async {
    final now = DateTime.now();
    final card = Vocab.initial(
      id: 'srs-1',
      sourceText: 'neuron',
      translatedText: 'nơ-ron',
      languagePair: 'en-vi',
    ).copyWith(
      nextReviewAt: now.subtract(const Duration(minutes: 2)),
      newLearningStepIndex: -1,
      reviewCount: 2,
    );
    final repo = _FakeRepo([card]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          vocabRepositoryProvider.overrideWithValue(repo),
          syncServiceProvider.overrideWith((ref) => _NoOpSyncService(repo)),
          appStateProvider.overrideWith(_ReviewScreenTestAppState.new),
        ],
        child: _buildTestApp(
          home: const SrsReviewScreen(reviewMode: ReviewMode.forward),
        ),
      ),
    );

    await tester.pumpAndSettle(const Duration(seconds: 5));
    expect(find.byIcon(Icons.volume_up_rounded), findsOneWidget);

    await tester.tap(find.text('neuron'));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.volume_up_rounded), findsOneWidget);
  });

  testWidgets('grading is gated until card is flipped', (tester) async {
    final now = DateTime.now();
    final card = Vocab.initial(
      id: 'srs-2',
      sourceText: 'axon',
      translatedText: 'sợi trục',
      languagePair: 'en-vi',
    ).copyWith(
      nextReviewAt: now.subtract(const Duration(minutes: 2)),
      newLearningStepIndex: -1,
      reviewCount: 2,
    );
    final repo = _FakeRepo([card]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          vocabRepositoryProvider.overrideWithValue(repo),
          syncServiceProvider.overrideWith((ref) => _NoOpSyncService(repo)),
          appStateProvider.overrideWith(_ReviewScreenTestAppState.new),
        ],
        child: _buildTestApp(
          home: const SrsReviewScreen(reviewMode: ReviewMode.forward),
        ),
      ),
    );

    await tester.pumpAndSettle(const Duration(seconds: 5));
    final l10n = _l10n(tester);
    expect(find.text('axon'), findsOneWidget);

    await tester.tap(find.text(l10n.reviewGradeGood));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('axon'), findsOneWidget);

    await tester.tap(find.text('axon'));
    await tester.pumpAndSettle();
    expect(find.text(l10n.reviewMeaning), findsOneWidget);

    await tester.tap(find.text(l10n.reviewGradeGood));
    await tester.pump();
    final summaryOrFinish = find.byWidgetPredicate(
      (widget) => widget is ReviewSummaryScreen,
    );
    await _pumpUntilFound(tester, summaryOrFinish);
    expect(summaryOrFinish, findsOneWidget);
  });

  testWidgets('reverse meaning mode checks typed answer before grading', (
    tester,
  ) async {
    final now = DateTime.now();
    final card = Vocab.initial(
      id: 'srs-reverse',
      sourceText: 'neuron',
      translatedText: 'nơ-ron',
      languagePair: 'en-vi',
    ).copyWith(
      nextReviewAt: now.subtract(const Duration(minutes: 2)),
      newLearningStepIndex: -1,
      reviewCount: 2,
    );
    final repo = _FakeRepo([card]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          vocabRepositoryProvider.overrideWithValue(repo),
          syncServiceProvider.overrideWith((ref) => _NoOpSyncService(repo)),
          appStateProvider.overrideWith(_ReviewScreenTestAppState.new),
        ],
        child: _buildTestApp(
          home: const SrsReviewScreen(reviewMode: ReviewMode.reverseMeaning),
        ),
      ),
    );

    await tester.pumpAndSettle(const Duration(seconds: 5));
    final l10n = _l10n(tester);
    expect(find.text(l10n.reviewMeaning), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'neuron');
    await tester.tap(find.text(l10n.reviewCheckAnswer));
    await tester.pumpAndSettle();
    expect(find.text(l10n.reviewCorrect), findsOneWidget);

    await tester.tap(find.text(l10n.reviewGradeGood));
    await tester.pump();
    final summaryFinder = find.byWidgetPredicate(
      (widget) => widget is ReviewSummaryScreen,
    );
    await _pumpUntilFound(tester, summaryFinder);
    expect(summaryFinder, findsOneWidget);
  });
}
