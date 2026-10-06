import 'dart:async';

import 'package:desktop/core/monetization/app_state.dart';
import 'package:desktop/core/sync/sync_service.dart';
import 'package:desktop/features/capture/application/smart_capture_service.dart';
import 'package:desktop/features/capture/application/translation_service.dart';
import 'package:desktop/features/capture/application/translation_cache.dart';
import 'package:desktop/features/capture/data/ocr_adapter.dart';
import 'package:app_l10n/app_l10n.dart';
import 'package:desktop/features/capture/presentation/capture_popup.dart';
import 'package:desktop/features/settings/application/settings_service.dart';
import 'package:desktop/features/vocab/data/vocab_repository_impl.dart';
import 'package:desktop/features/vocab/domain/vocab_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _capturePopupTestApp(Widget body) {
  return MaterialApp(
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey),
    ),
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: body),
  );
}

class _NoopClipboardReader implements ClipboardReader {
  @override
  Future<String?> readText() async => null;
}

class _FakeSmartCaptureService extends SmartCaptureService {
  _FakeSmartCaptureService({required this.handler})
    : super(clipboardReader: _NoopClipboardReader());

  final Future<SmartCaptureResult> Function() handler;

  @override
  Future<SmartCaptureResult> detectBestWord({
    required OcrExtractor ocrExtractor,
  }) {
    return handler();
  }

  @override
  Future<SmartCaptureResult> detectTextMode({
    required OcrExtractor ocrFallbackExtractor,
  }) {
    return handler();
  }

  @override
  Future<SmartCaptureResult> detectFromOcrOnly({
    required OcrExtractor ocrExtractor,
  }) {
    return handler();
  }
}

class _FakeOcrAdapter implements OcrAdapter {
  @override
  Future<String> extractText() async => 'ignored';

  @override
  Future<String> extractTextFromRegion(Rect region) async => extractText();
}

class _FakeVocabRepository implements VocabRepository {
  @override
  Future<List<Vocab>> getAllVocab() async => <Vocab>[];

  @override
  Future<List<Vocab>> getDueCards(DateTime now) async => <Vocab>[];

  @override
  Future<void> saveVocab(Vocab vocab) async {}

  @override
  Future<void> syncPending() async {}

  @override
  Future<void> updateReviewProgress(Vocab vocab) async {}

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

class _FakeSyncService extends SyncService {
  _FakeSyncService() : super(_FakeVocabRepository());
}

class _FakeTranslationService implements TranslationService {
  @override
  Future<TranslationResult> translate(TranslationRequest request) async =>
      TranslationResult(translatedText: 'translated:${request.text}');
}

class _TestLanguageSettings extends LanguageSettingsController {
  @override
  Future<LanguageSettings> build() async => LanguageSettings.fallback;
}

class _CapturePopupTestAppState extends AppStateController {
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
  Future<bool> tryReserveCapturePopupBannerSlot() async => false;
}

void main() {
  setUpAll(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  group('CapturePopup behavior', () {
    testWidgets('does not close when clicking inside popup', (tester) async {
      var closeCount = 0;
      final container = ProviderContainer(
        overrides: [
          vocabRepositoryProvider.overrideWithValue(_FakeVocabRepository()),
          syncServiceProvider.overrideWithValue(_FakeSyncService()),
          smartCaptureServiceProvider.overrideWithValue(
            _FakeSmartCaptureService(
              handler: () async => const SmartCaptureResult(
                detectedText: 'inside click sample',
                rawText: 'inside click sample',
                source: CaptureInputSource.selection,
              ),
            ),
          ),
          ocrAdapterProvider.overrideWithValue(_FakeOcrAdapter()),
          translationCacheProvider.overrideWithValue(
            TranslationCache(maxEntries: 20),
          ),
          translationServiceProvider.overrideWithValue(
            _FakeTranslationService(),
          ),
          languageSettingsProvider.overrideWith(_TestLanguageSettings.new),
          appStateProvider.overrideWith(_CapturePopupTestAppState.new),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: _capturePopupTestApp(
            CapturePopup(
              onClose: () => closeCount += 1,
              mode: CapturePopupMode.text,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 5));
      expect(closeCount, 0);
      expect(find.byType(FilledButton), findsOneWidget);
      await tester.tap(find.byType(EditableText).first);
      await tester.pump(const Duration(milliseconds: 100));
      expect(closeCount, 0);
    });

    testWidgets('does not auto-dismiss after idle', (tester) async {
      var closeCount = 0;
      final container = ProviderContainer(
        overrides: [
          vocabRepositoryProvider.overrideWithValue(_FakeVocabRepository()),
          syncServiceProvider.overrideWithValue(_FakeSyncService()),
          smartCaptureServiceProvider.overrideWithValue(
            _FakeSmartCaptureService(
              handler: () async => const SmartCaptureResult(
                detectedText: 'obscure',
                rawText: 'obscure',
                source: CaptureInputSource.selection,
              ),
            ),
          ),
          ocrAdapterProvider.overrideWithValue(_FakeOcrAdapter()),
          translationCacheProvider.overrideWithValue(
            TranslationCache(maxEntries: 20),
          ),
          translationServiceProvider.overrideWithValue(
            _FakeTranslationService(),
          ),
          languageSettingsProvider.overrideWith(_TestLanguageSettings.new),
          appStateProvider.overrideWith(_CapturePopupTestAppState.new),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: _capturePopupTestApp(
            CapturePopup(
              onClose: () => closeCount += 1,
              mode: CapturePopupMode.text,
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 10));
      await tester.pump(const Duration(milliseconds: 50));
      expect(closeCount, 0);
      await tester.pump(const Duration(seconds: 7));
      expect(closeCount, 0);
    });

    testWidgets('stays open after capture session completes', (tester) async {
      var closeCount = 0;
      final completer = Completer<SmartCaptureResult>();
      final container = ProviderContainer(
        overrides: [
          vocabRepositoryProvider.overrideWithValue(_FakeVocabRepository()),
          syncServiceProvider.overrideWithValue(_FakeSyncService()),
          smartCaptureServiceProvider.overrideWithValue(
            _FakeSmartCaptureService(handler: () => completer.future),
          ),
          ocrAdapterProvider.overrideWithValue(_FakeOcrAdapter()),
          translationCacheProvider.overrideWithValue(
            TranslationCache(maxEntries: 20),
          ),
          translationServiceProvider.overrideWithValue(
            _FakeTranslationService(),
          ),
          languageSettingsProvider.overrideWith(_TestLanguageSettings.new),
          appStateProvider.overrideWith(_CapturePopupTestAppState.new),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: _capturePopupTestApp(
            CapturePopup(
              onClose: () => closeCount += 1,
              mode: CapturePopupMode.text,
            ),
          ),
        ),
      );

      await tester.pump();
      expect(closeCount, 0);
      completer.complete(
        const SmartCaptureResult(
          detectedText: 'hello',
          rawText: 'hello',
          source: CaptureInputSource.ocr,
        ),
      );
      await tester.pumpAndSettle();
      expect(closeCount, 0);
    });

    testWidgets('shows save line when bootstrap selects full passage', (
      tester,
    ) async {
      final container = ProviderContainer(
        overrides: [
          vocabRepositoryProvider.overrideWithValue(_FakeVocabRepository()),
          syncServiceProvider.overrideWithValue(_FakeSyncService()),
          smartCaptureServiceProvider.overrideWithValue(
            _FakeSmartCaptureService(
              handler: () async => const SmartCaptureResult(
                detectedText: 'alpha beta',
                rawText: 'alpha beta',
                source: CaptureInputSource.selection,
              ),
            ),
          ),
          ocrAdapterProvider.overrideWithValue(_FakeOcrAdapter()),
          translationCacheProvider.overrideWithValue(
            TranslationCache(maxEntries: 20),
          ),
          translationServiceProvider.overrideWithValue(
            _FakeTranslationService(),
          ),
          languageSettingsProvider.overrideWith(_TestLanguageSettings.new),
          appStateProvider.overrideWith(_CapturePopupTestAppState.new),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: _capturePopupTestApp(
            const CapturePopup(
              onClose: _noopClose,
              mode: CapturePopupMode.text,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 5));
      expect(find.byType(FilledButton), findsOneWidget);
      expect(find.text('Whole line'), findsNothing);
      final saveTexts = find.descendant(
        of: find.byType(FilledButton),
        matching: find.byType(Text),
      );
      expect(saveTexts, findsOneWidget);
      expect(tester.widget<Text>(saveTexts).data, 'Save line');
    });
  });
}

void _noopClose() {}
