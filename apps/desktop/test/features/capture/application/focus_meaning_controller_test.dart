import 'dart:async';

import 'package:desktop/core/monetization/app_state.dart';
import 'package:desktop/core/sync/sync_service.dart';
import 'package:desktop/features/capture/application/focus_meaning_controller.dart';
import 'package:desktop/features/capture/domain/focused_span.dart';
import 'package:desktop/features/capture/application/smart_capture_service.dart';
import 'package:desktop/features/capture/application/translation_cache.dart';
import 'package:desktop/features/capture/application/translation_service.dart';
import 'package:desktop/features/capture/data/ocr_adapter.dart';
import 'package:desktop/features/vocab/data/vocab_repository_impl.dart';
import 'package:desktop/features/vocab/domain/vocab_repository.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';

class _NoopClipboardReader implements ClipboardReader {
  @override
  Future<String?> readText() async => null;
}

class _FakeSmartForFocus extends SmartCaptureService {
  _FakeSmartForFocus() : super(clipboardReader: _NoopClipboardReader());

  @override
  Future<SmartCaptureResult> detectTextMode({
    required OcrExtractor ocrFallbackExtractor,
  }) async {
    return const SmartCaptureResult(
      detectedText: 'x',
      rawText: 'x',
      source: CaptureInputSource.none,
    );
  }

  @override
  Future<SmartCaptureResult> detectFromOcrOnly({
    required OcrExtractor ocrExtractor,
  }) async {
    return const SmartCaptureResult(
      detectedText: 'x',
      rawText: 'x',
      source: CaptureInputSource.none,
    );
  }
}

class _FakeOcrAdapter implements OcrAdapter {
  @override
  Future<String> extractText() async => '';

  @override
  Future<String> extractTextFromRegion(Rect region) async => '';
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
      TranslationResult(
        translatedText: 'translated:${request.text}',
        phonetic: 'ipa:${request.text}',
        detectedSourceLanguage: 'en',
      );
}

class _FocusMeaningTestAppState extends AppStateController {
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
}

void main() {
  group('FocusMeaningController', () {
    test('bootstrap picks default span and resolves meaning', () async {
      final container = ProviderContainer(
        overrides: [
          appStateProvider.overrideWith(_FocusMeaningTestAppState.new),
          vocabRepositoryProvider.overrideWithValue(_FakeVocabRepository()),
          syncServiceProvider.overrideWithValue(_FakeSyncService()),
          smartCaptureServiceProvider.overrideWithValue(_FakeSmartForFocus()),
          ocrAdapterProvider.overrideWithValue(_FakeOcrAdapter()),
          translationCacheProvider.overrideWithValue(
            TranslationCache(maxEntries: 20),
          ),
          translationServiceProvider.overrideWithValue(
            _FakeTranslationService(),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(focusMeaningProvider.notifier)
          .bootstrap('hello obscure world');

      final focus = container.read(focusMeaningProvider);
      expect(focus.focusedText, isNotEmpty);
      expect(focus.translatedText, startsWith('translated:'));
      expect(focus.isLoading, isFalse);
      expect(focus.pronunciation, isNotEmpty);
      expect(focus.pronunciation, focus.phonetic);
    });

    test('bootstrap long passage defaults to full passage meaning', () async {
      final container = ProviderContainer(
        overrides: [
          appStateProvider.overrideWith(_FocusMeaningTestAppState.new),
          vocabRepositoryProvider.overrideWithValue(_FakeVocabRepository()),
          syncServiceProvider.overrideWithValue(_FakeSyncService()),
          smartCaptureServiceProvider.overrideWithValue(_FakeSmartForFocus()),
          ocrAdapterProvider.overrideWithValue(_FakeOcrAdapter()),
          translationCacheProvider.overrideWithValue(
            TranslationCache(maxEntries: 20),
          ),
          translationServiceProvider.overrideWithValue(
            _FakeTranslationService(),
          ),
        ],
      );
      addTearDown(container.dispose);

      const longPassage = 'one two three four five six seven';
      await container
          .read(focusMeaningProvider.notifier)
          .bootstrap(longPassage);

      final focus = container.read(focusMeaningProvider);
      expect(focus.focusStart, 0);
      expect(focus.focusEnd, longPassage.length);
      expect(focus.focusedText, longPassage.trim());
      expect(focus.translatedText, 'translated:${longPassage.trim()}');
      expect(focus.isLoading, isFalse);
    });

    test('resolve updates meaning for new fragment', () async {
      final container = ProviderContainer(
        overrides: [
          appStateProvider.overrideWith(_FocusMeaningTestAppState.new),
          vocabRepositoryProvider.overrideWithValue(_FakeVocabRepository()),
          syncServiceProvider.overrideWithValue(_FakeSyncService()),
          smartCaptureServiceProvider.overrideWithValue(_FakeSmartForFocus()),
          ocrAdapterProvider.overrideWithValue(_FakeOcrAdapter()),
          translationCacheProvider.overrideWithValue(
            TranslationCache(maxEntries: 20),
          ),
          translationServiceProvider.overrideWithValue(
            _FakeTranslationService(),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(focusMeaningProvider.notifier)
          .resolveSpan(
            const FocusedSpan(text: 'alpha', start: 0, end: 5),
            'alpha',
          );
      expect(container.read(focusMeaningProvider).focusedText, 'alpha');
      await container
          .read(focusMeaningProvider.notifier)
          .resolveSpan(
            const FocusedSpan(text: 'beta', start: 0, end: 4),
            'beta',
          );
      expect(container.read(focusMeaningProvider).focusedText, 'beta');
      expect(
        container.read(focusMeaningProvider).translatedText,
        'translated:beta',
      );
      final endState = container.read(focusMeaningProvider);
      expect(endState.pronunciation, endState.phonetic);
    });

    test('resolve clears pronunciation while loading', () async {
      final container = ProviderContainer(
        overrides: [
          appStateProvider.overrideWith(_FocusMeaningTestAppState.new),
          vocabRepositoryProvider.overrideWithValue(_FakeVocabRepository()),
          syncServiceProvider.overrideWithValue(_FakeSyncService()),
          smartCaptureServiceProvider.overrideWithValue(_FakeSmartForFocus()),
          ocrAdapterProvider.overrideWithValue(_FakeOcrAdapter()),
          translationCacheProvider.overrideWithValue(
            TranslationCache(maxEntries: 20),
          ),
          translationServiceProvider.overrideWithValue(
            _FakeTranslationService(),
          ),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(focusMeaningProvider.notifier);
      await notifier.resolveSpan(
        const FocusedSpan(text: 'alpha', start: 0, end: 5),
        'alpha',
      );
      final afterAlpha = container.read(focusMeaningProvider);
      expect(afterAlpha.pronunciation, afterAlpha.phonetic);

      final pending = notifier.resolveSpan(
        const FocusedSpan(text: 'beta', start: 0, end: 4),
        'beta',
      );
      expect(container.read(focusMeaningProvider).isLoading, isTrue);
      expect(container.read(focusMeaningProvider).pronunciation, '');
      await pending;
      final afterBeta = container.read(focusMeaningProvider);
      expect(afterBeta.pronunciation, afterBeta.phonetic);
    });
  });
}
