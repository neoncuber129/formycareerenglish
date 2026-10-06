import 'dart:async';

import 'package:desktop/core/monetization/app_state.dart';
import 'package:desktop/core/sync/sync_service.dart';
import 'package:desktop/features/capture/application/capture_controller.dart';
import 'package:desktop/features/capture/application/smart_capture_service.dart';
import 'package:desktop/features/capture/application/translation_service.dart';
import 'package:desktop/features/capture/application/translation_cache.dart';
import 'package:desktop/features/capture/data/ocr_adapter.dart';
import 'package:desktop/features/vocab/data/vocab_repository_impl.dart';
import 'package:desktop/features/vocab/domain/vocab_repository.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_models/shared_models.dart';

class _NoopClipboardReader implements ClipboardReader {
  @override
  Future<String?> readText() async => null;
}

class FakeSmartCaptureService extends SmartCaptureService {
  FakeSmartCaptureService({required this.handler})
    : super(clipboardReader: _NoopClipboardReader());

  final Future<SmartCaptureResult> Function() handler;
  int callCount = 0;

  @override
  Future<SmartCaptureResult> detectBestWord({
    required OcrExtractor ocrExtractor,
  }) async {
    callCount += 1;
    return handler();
  }

  @override
  Future<SmartCaptureResult> detectTextMode({
    required OcrExtractor ocrFallbackExtractor,
  }) async {
    callCount += 1;
    return handler();
  }

  @override
  Future<SmartCaptureResult> detectFromOcrOnly({
    required OcrExtractor ocrExtractor,
  }) async {
    callCount += 1;
    return handler();
  }
}

class FakeOcrAdapter implements OcrAdapter {
  @override
  Future<String> extractText() async => 'ignored';

  @override
  Future<String> extractTextFromRegion(Rect region) async => extractText();
}

class FakeVocabRepository implements VocabRepository {
  FakeVocabRepository({List<Vocab>? seed})
    : _store = List<Vocab>.from(seed ?? const <Vocab>[]);

  final List<Vocab> _store;
  int saveCalls = 0;

  @override
  Future<List<Vocab>> getAllVocab() async => List<Vocab>.from(_store);

  @override
  Future<List<Vocab>> getDueCards(DateTime now) async => <Vocab>[];

  @override
  Future<void> saveVocab(Vocab vocab) async {
    saveCalls += 1;
    _store.add(vocab);
  }

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

class FakeSyncService extends SyncService {
  FakeSyncService() : super(FakeVocabRepository());
  int syncNowCalls = 0;

  @override
  Future<void> syncNow() async {
    syncNowCalls += 1;
  }

  @override
  void triggerSync() {
    unawaited(syncNow());
  }
}

class FakeTranslationService implements TranslationService {
  @override
  Future<TranslationResult> translate(TranslationRequest request) async =>
      TranslationResult(translatedText: 'translated:${request.text}');
}

class _CaptureControllerTestAppState extends AppStateController {
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

/// First response is empty or echo; later calls return a real target string.
class _RefineTranslationFake implements TranslationService {
  _RefineTranslationFake(this._sequence);
  final List<TranslationResult> _sequence;
  int callCount = 0;

  @override
  Future<TranslationResult> translate(TranslationRequest request) async {
    if (callCount >= _sequence.length) {
      return TranslationResult.empty;
    }
    return _sequence[callCount++];
  }
}

class _FailingHttpClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    return http.StreamedResponse(Stream<List<int>>.value(<int>[]), 404);
  }
}

DictionaryLookupService _stubDictionary() {
  return DictionaryLookupService(client: _FailingHttpClient());
}

void main() {
  group('CaptureController', () {
    test('shows Already saved and skips duplicate save', () async {
      final existing = Vocab.initial(
        id: 'existing',
        sourceText: 'obscure',
        translatedText: 'Nghia: obscure',
        languagePair: 'en-vi',
      );
      final fakeRepo = FakeVocabRepository(seed: <Vocab>[existing]);
      final fakeSync = FakeSyncService();
      final fakeSmart = FakeSmartCaptureService(
        handler: () async => const SmartCaptureResult(
          detectedText: 'obscure',
          rawText: 'obscure',
          source: CaptureInputSource.selection,
        ),
      );
      final container = ProviderContainer(
        overrides: [
          appStateProvider.overrideWith(_CaptureControllerTestAppState.new),
          vocabRepositoryProvider.overrideWithValue(fakeRepo),
          syncServiceProvider.overrideWithValue(fakeSync),
          smartCaptureServiceProvider.overrideWithValue(fakeSmart),
          ocrAdapterProvider.overrideWithValue(FakeOcrAdapter()),
          translationCacheProvider.overrideWithValue(
            TranslationCache(maxEntries: 20),
          ),
          translationServiceProvider.overrideWithValue(
            FakeTranslationService(),
          ),
          dictionaryLookupServiceProvider.overrideWithValue(_stubDictionary()),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(captureControllerProvider.notifier);
      await controller.capture();
      await controller.saveFocusedFragment(
        sourceText: 'obscure',
        translatedText: 'any',
        languagePair: 'en-vi',
      );

      final state = container.read(captureControllerProvider);
      expect(state.message, 'Already saved');
      expect(fakeRepo.saveCalls, 0);
      expect(fakeSync.syncNowCalls, 0);
    });

    test('skips overlapping capture calls during rapid triggers', () async {
      final fakeRepo = FakeVocabRepository();
      final fakeSync = FakeSyncService();
      final completer = Completer<SmartCaptureResult>();
      final fakeSmart = FakeSmartCaptureService(
        handler: () => completer.future,
      );
      final container = ProviderContainer(
        overrides: [
          appStateProvider.overrideWith(_CaptureControllerTestAppState.new),
          vocabRepositoryProvider.overrideWithValue(fakeRepo),
          syncServiceProvider.overrideWithValue(fakeSync),
          smartCaptureServiceProvider.overrideWithValue(fakeSmart),
          ocrAdapterProvider.overrideWithValue(FakeOcrAdapter()),
          translationCacheProvider.overrideWithValue(
            TranslationCache(maxEntries: 20),
          ),
          translationServiceProvider.overrideWithValue(
            FakeTranslationService(),
          ),
          dictionaryLookupServiceProvider.overrideWithValue(_stubDictionary()),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(captureControllerProvider.notifier);
      final first = controller.capture();
      final second = controller.capture();
      completer.complete(
        const SmartCaptureResult(
          detectedText: 'rapid',
          rawText: 'rapid',
          source: CaptureInputSource.ocr,
        ),
      );
      await Future.wait(<Future<void>>[first, second]);

      expect(fakeSmart.callCount, 1);
    });

    test('handles capture failure without throwing', () async {
      final fakeRepo = FakeVocabRepository();
      final fakeSync = FakeSyncService();
      final fakeSmart = FakeSmartCaptureService(
        handler: () =>
            Future<SmartCaptureResult>.error(Exception('ocr failed')),
      );
      final container = ProviderContainer(
        overrides: [
          appStateProvider.overrideWith(_CaptureControllerTestAppState.new),
          vocabRepositoryProvider.overrideWithValue(fakeRepo),
          syncServiceProvider.overrideWithValue(fakeSync),
          smartCaptureServiceProvider.overrideWithValue(fakeSmart),
          ocrAdapterProvider.overrideWithValue(FakeOcrAdapter()),
          translationCacheProvider.overrideWithValue(
            TranslationCache(maxEntries: 20),
          ),
          translationServiceProvider.overrideWithValue(
            FakeTranslationService(),
          ),
          dictionaryLookupServiceProvider.overrideWithValue(_stubDictionary()),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(captureControllerProvider.notifier);
      await controller.capture();

      final state = container.read(captureControllerProvider);
      expect(state.message, 'Capture failed.');
      expect(state.sourceText, isEmpty);
    });

    test('captureImageMode applies shared capture text state path', () async {
      final fakeRepo = FakeVocabRepository();
      final fakeSync = FakeSyncService();
      var call = 0;
      final fakeSmart = FakeSmartCaptureService(
        handler: () async {
          call += 1;
          if (call == 1) {
            return const SmartCaptureResult(
              detectedText: 'text mode passage',
              rawText: 'text mode passage',
              source: CaptureInputSource.selection,
            );
          }
          return const SmartCaptureResult(
            detectedText: 'ocr mode passage',
            rawText: 'ocr mode passage',
            source: CaptureInputSource.ocr,
          );
        },
      );
      final container = ProviderContainer(
        overrides: [
          appStateProvider.overrideWith(_CaptureControllerTestAppState.new),
          vocabRepositoryProvider.overrideWithValue(fakeRepo),
          syncServiceProvider.overrideWithValue(fakeSync),
          smartCaptureServiceProvider.overrideWithValue(fakeSmart),
          ocrAdapterProvider.overrideWithValue(FakeOcrAdapter()),
          translationCacheProvider.overrideWithValue(
            TranslationCache(maxEntries: 20),
          ),
          translationServiceProvider.overrideWithValue(
            FakeTranslationService(),
          ),
          dictionaryLookupServiceProvider.overrideWithValue(_stubDictionary()),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(captureControllerProvider.notifier);
      await controller.captureTextMode();
      var state = container.read(captureControllerProvider);
      expect(state.sourceText, 'text mode passage');
      expect(state.message, 'Captured selected text.');

      await controller.captureImageMode(region: null);
      state = container.read(captureControllerProvider);
      expect(state.sourceText, 'ocr mode passage');
      expect(state.translatedText, isEmpty);
      expect(state.phonetic, isEmpty);
      expect(state.audioUrl, isEmpty);
      expect(state.message, 'Captured text from OCR.');
    });

    test('save shows local-only message when user is not signed in', () async {
      final fakeRepo = FakeVocabRepository();
      final fakeSync = FakeSyncService();
      final fakeSmart = FakeSmartCaptureService(
        handler: () async => const SmartCaptureResult(
          detectedText: 'offlineword',
          rawText: 'offlineword',
          source: CaptureInputSource.selection,
        ),
      );
      final container = ProviderContainer(
        overrides: [
          appStateProvider.overrideWith(_CaptureControllerTestAppState.new),
          vocabRepositoryProvider.overrideWithValue(fakeRepo),
          syncServiceProvider.overrideWithValue(fakeSync),
          smartCaptureServiceProvider.overrideWithValue(fakeSmart),
          ocrAdapterProvider.overrideWithValue(FakeOcrAdapter()),
          translationCacheProvider.overrideWithValue(
            TranslationCache(maxEntries: 20),
          ),
          translationServiceProvider.overrideWithValue(
            FakeTranslationService(),
          ),
          dictionaryLookupServiceProvider.overrideWithValue(_stubDictionary()),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(captureControllerProvider.notifier);
      await controller.capture();
      await controller.saveFocusedFragment(
        sourceText: 'offlineword',
        translatedText: 'translated:offlineword',
        languagePair: 'en-vi',
      );

      final state = container.read(captureControllerProvider);
      expect(state.message, 'Saved locally. Sign in to sync.');
      expect(fakeRepo.saveCalls, 1);
      expect(fakeSync.syncNowCalls, 1);
    });

    test(
      'translateFragment refines empty first pass with explicit en→native',
      () async {
        final fakeRepo = FakeVocabRepository();
        final fakeSync = FakeSyncService();
        final fakeSmart = FakeSmartCaptureService(
          handler: () async => const SmartCaptureResult(
            detectedText: 'x',
            rawText: 'x',
            source: CaptureInputSource.selection,
          ),
        );
        final refine = _RefineTranslationFake(<TranslationResult>[
          TranslationResult.empty,
          const TranslationResult(
            translatedText: 'bản dịch',
            detectedSourceLanguage: 'en',
          ),
        ]);
        final container = ProviderContainer(
          overrides: [
            appStateProvider.overrideWith(_CaptureControllerTestAppState.new),
            vocabRepositoryProvider.overrideWithValue(fakeRepo),
            syncServiceProvider.overrideWithValue(fakeSync),
            smartCaptureServiceProvider.overrideWithValue(fakeSmart),
            ocrAdapterProvider.overrideWithValue(FakeOcrAdapter()),
            translationCacheProvider.overrideWithValue(
              TranslationCache(maxEntries: 20),
            ),
            translationServiceProvider.overrideWithValue(refine),
            dictionaryLookupServiceProvider.overrideWithValue(
              _stubDictionary(),
            ),
          ],
        );
        addTearDown(container.dispose);

        final controller = container.read(captureControllerProvider.notifier);
        controller.updateLanguagePreferences(
          nativeLanguage: 'vi',
          sourceLanguages: const <String>['en'],
        );
        final fragment = await controller.translateFragment('hello');

        expect(fragment.translatedText, 'bản dịch');
        expect(refine.callCount, 2);
      },
    );

    test(
      'translateFragment refines echo en token when native is Vietnamese',
      () async {
        final fakeRepo = FakeVocabRepository();
        final fakeSync = FakeSyncService();
        final fakeSmart = FakeSmartCaptureService(
          handler: () async => const SmartCaptureResult(
            detectedText: 'x',
            rawText: 'x',
            source: CaptureInputSource.selection,
          ),
        );
        final refine = _RefineTranslationFake(<TranslationResult>[
          TranslationResult(
            translatedText: 'primary',
            detectedSourceLanguage: 'en',
          ),
          const TranslationResult(
            translatedText: 'sơ cấp',
            detectedSourceLanguage: 'en',
          ),
        ]);
        final container = ProviderContainer(
          overrides: [
            appStateProvider.overrideWith(_CaptureControllerTestAppState.new),
            vocabRepositoryProvider.overrideWithValue(fakeRepo),
            syncServiceProvider.overrideWithValue(fakeSync),
            smartCaptureServiceProvider.overrideWithValue(fakeSmart),
            ocrAdapterProvider.overrideWithValue(FakeOcrAdapter()),
            translationCacheProvider.overrideWithValue(
              TranslationCache(maxEntries: 20),
            ),
            translationServiceProvider.overrideWithValue(refine),
            dictionaryLookupServiceProvider.overrideWithValue(
              _stubDictionary(),
            ),
          ],
        );
        addTearDown(container.dispose);

        final controller = container.read(captureControllerProvider.notifier);
        controller.updateLanguagePreferences(
          nativeLanguage: 'vi',
          sourceLanguages: const <String>['en'],
        );
        final fragment = await controller.translateFragment('primary');

        expect(fragment.translatedText, 'sơ cấp');
        expect(refine.callCount, 2);
      },
    );

    test(
      'translateFragment accepts echo when native language matches English',
      () async {
        final fakeRepo = FakeVocabRepository();
        final fakeSync = FakeSyncService();
        final fakeSmart = FakeSmartCaptureService(
          handler: () async => const SmartCaptureResult(
            detectedText: 'x',
            rawText: 'x',
            source: CaptureInputSource.selection,
          ),
        );
        final refine = _RefineTranslationFake(<TranslationResult>[
          TranslationResult(
            translatedText: 'table',
            detectedSourceLanguage: 'en',
          ),
        ]);
        final container = ProviderContainer(
          overrides: [
            appStateProvider.overrideWith(_CaptureControllerTestAppState.new),
            vocabRepositoryProvider.overrideWithValue(fakeRepo),
            syncServiceProvider.overrideWithValue(fakeSync),
            smartCaptureServiceProvider.overrideWithValue(fakeSmart),
            ocrAdapterProvider.overrideWithValue(FakeOcrAdapter()),
            translationCacheProvider.overrideWithValue(
              TranslationCache(maxEntries: 20),
            ),
            translationServiceProvider.overrideWithValue(refine),
            dictionaryLookupServiceProvider.overrideWithValue(
              _stubDictionary(),
            ),
          ],
        );
        addTearDown(container.dispose);

        final controller = container.read(captureControllerProvider.notifier);
        controller.updateLanguagePreferences(
          nativeLanguage: 'en',
          sourceLanguages: const <String>['en'],
        );
        final fragment = await controller.translateFragment('table');

        expect(fragment.translatedText, 'table');
        expect(refine.callCount, 1);
      },
    );
  });
}
