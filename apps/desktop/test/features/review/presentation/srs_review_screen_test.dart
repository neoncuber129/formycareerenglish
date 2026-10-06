import 'dart:async';

import 'package:app_l10n/app_l10n.dart';
import 'package:desktop/core/monetization/app_state.dart';
import 'package:desktop/core/sync/sync_service.dart';
import 'package:desktop/features/review/application/review_controller.dart';
import 'package:desktop/features/review/presentation/srs_review_screen.dart';
import 'package:desktop/features/review/presentation/review_summary_screen.dart';
import 'package:desktop/features/vocab/data/vocab_repository_impl.dart';
import 'package:desktop/features/vocab/domain/vocab_repository.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_models/shared_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
      proWebsiteUrl: 'https://formycareer.vercel.app',
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
      lemonInstanceName: 'FormyCareer Desktop',
      lemonStoreName: 'Lemon Squeezy',
      lemonExpectedStoreId: '',
      lemonExpectedProductId: '',
      lemonExpectedVariantId: '',
      freeDailyReviewGradesUsed: 0,
      freeDailyReviewLimit: AppState.defaultFreeDailyReviewLimit,
      freeDailyVocabSavesUsed: 0,
      freeDailyVocabSaveLimit: AppState.defaultFreeDailyVocabSaveLimit,
      freeDailyTranslateCallsUsed: 0,
      freeDailyTranslateCallLimit: AppState.defaultFreeDailyTranslateCallLimit,
      capturePopupBannerEnabled: true,
      capturePopupBannerCooldownMinutes:
          AppState.defaultCapturePopupBannerCooldownMinutes,
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues(<String, Object>{});

  test('desktopReviewGradeFromKey maps number keys to grades', () {
    expect(
      desktopReviewGradeFromKey(LogicalKeyboardKey.digit1),
      ReviewGrade.again,
    );
    expect(
      desktopReviewGradeFromKey(LogicalKeyboardKey.digit2),
      ReviewGrade.hard,
    );
    expect(
      desktopReviewGradeFromKey(LogicalKeyboardKey.digit3),
      ReviewGrade.good,
    );
    expect(
      desktopReviewGradeFromKey(LogicalKeyboardKey.digit4),
      ReviewGrade.easy,
    );
    expect(desktopReviewGradeFromKey(LogicalKeyboardKey.keyQ), isNull);
  });

  testWidgets('inline audio button is visible on both faces', (tester) async {
    final now = DateTime.now();
    final card = Vocab.initial(
      id: 'desk-review-audio',
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
        child: fluent.FluentApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            fluent.FluentLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: const SrsReviewScreen(reviewMode: ReviewMode.forward),
        ),
      ),
    );

    await tester.pumpAndSettle(const Duration(seconds: 5));
    expect(find.byIcon(FluentIcons.speaker_2_24_regular), findsOneWidget);

    await tester.tap(find.text('neuron'));
    await tester.pumpAndSettle();

    expect(find.byIcon(FluentIcons.speaker_2_24_regular), findsOneWidget);
  });

  testWidgets('reverse meaning mode requires answer check before grading', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final now = DateTime.now();
    final card = Vocab.initial(
      id: 'desk-review-reverse',
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
        child: fluent.FluentApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            fluent.FluentLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: const SrsReviewScreen(reviewMode: ReviewMode.reverseMeaning),
        ),
      ),
    );
    await tester.pumpAndSettle(const Duration(seconds: 5));

    expect(find.text('Meaning'), findsOneWidget);
    expect(find.textContaining('Check answer'), findsOneWidget);

    await tester.enterText(find.byType(fluent.TextBox), 'neuron');
    await tester.tap(find.textContaining('Check answer'));
    await tester.pumpAndSettle();
    expect(find.text('Correct'), findsOneWidget);

    await tester.tap(find.textContaining('Good'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(seconds: 2));
    expect(
      find.byType(ReviewSummaryScreen).evaluate().isNotEmpty ||
          find.text('Finishing review session…').evaluate().isNotEmpty,
      isTrue,
    );
  });
}
