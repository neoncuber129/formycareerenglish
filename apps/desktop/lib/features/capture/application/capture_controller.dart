import 'dart:async';
import 'dart:io';
import 'dart:core';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_models/shared_models.dart';
import 'package:uuid/uuid.dart';

import '../../../core/context/foreground_window_context.dart';
import '../../../core/monetization/app_state.dart';
import '../../../core/hotkey/hotkey_service.dart';
import '../../../core/logging/logger_service.dart';
import '../../../core/supabase/supabase_client_provider.dart';
import '../../../core/sync/sync_service.dart';
import '../../vocab/data/vocab_repository_impl.dart';
import '../../vocab/domain/vocab_repository.dart';
import '../../settings/application/settings_service.dart';
import '../data/capture_image_storage.dart';
import '../data/ocr_adapter.dart';
import 'capture_pipeline.dart';
import 'translation_service.dart';
import 'translation_cache.dart';

class CaptureState {
  const CaptureState({
    this.sourceText = '',
    this.translatedText = '',
    this.languagePair = 'en-vi',
    this.sourceLanguage = 'en',
    this.targetLanguage = 'vi',
    this.phonetic = '',
    this.audioUrl = '',
    this.tags = const <String>[],
    this.sourceApp = '',
    this.isSaving = false,
    this.message,
  });

  final String sourceText;
  final String translatedText;
  final String languagePair;
  final String sourceLanguage;
  final String targetLanguage;
  final String phonetic;
  final String audioUrl;
  final List<String> tags;
  final String sourceApp;
  final bool isSaving;
  final String? message;

  bool get canSave => sourceText.isNotEmpty && translatedText.isNotEmpty;

  CaptureState copyWith({
    String? sourceText,
    String? translatedText,
    String? languagePair,
    String? sourceLanguage,
    String? targetLanguage,
    String? phonetic,
    String? audioUrl,
    List<String>? tags,
    String? sourceApp,
    bool? isSaving,
    String? message,
  }) {
    return CaptureState(
      sourceText: sourceText ?? this.sourceText,
      translatedText: translatedText ?? this.translatedText,
      languagePair: languagePair ?? this.languagePair,
      sourceLanguage: sourceLanguage ?? this.sourceLanguage,
      targetLanguage: targetLanguage ?? this.targetLanguage,
      phonetic: phonetic ?? this.phonetic,
      audioUrl: audioUrl ?? this.audioUrl,
      tags: tags ?? this.tags,
      sourceApp: sourceApp ?? this.sourceApp,
      isSaving: isSaving ?? this.isSaving,
      message: message,
    );
  }
}

class CaptureSaveResult {
  const CaptureSaveResult({
    required this.success,
    required this.message,
    this.dailySaveQuotaExceeded = false,
  });

  final bool success;
  final String message;

  /// Free-tier daily vocab save limit ([AppState.tryConsumeDailyVocabSave]).
  final bool dailySaveQuotaExceeded;
}

/// [dictionaryGloss] is non-null only when a single-token English dictionary
/// fetch was performed (same HTTP response reused for [translateFragment]).
class _TranslationWithOptionalGloss {
  const _TranslationWithOptionalGloss({
    required this.result,
    this.dictionaryGloss,
    this.servedFromCache = false,
    this.quotaExceeded = false,
  });

  final TranslationResult result;
  final DictionaryGloss? dictionaryGloss;

  /// True when [result] came from [TranslationCache] (not a fresh HTTP call).
  final bool servedFromCache;

  /// True when Free tier hit [AppState.freeDailyTranslateCallLimit].
  final bool quotaExceeded;
}

/// Translation + metadata for a user-selected substring (interactive popup).
class FragmentTranslation {
  const FragmentTranslation({
    required this.translatedText,
    required this.phonetic,
    required this.pronunciation,
    required this.audioUrl,
    required this.languagePair,
    required this.sourceLanguage,
    required this.targetLanguage,
    this.partOfSpeech = '',
    this.microExplanation = '',
    this.exampleSentence = '',
    this.translateDailyQuotaExceeded = false,
  });

  final String translatedText;
  final String phonetic;

  /// IPA / pronunciation text (same source as [phonetic] from dictionary path).
  final String pronunciation;
  final String audioUrl;
  final String languagePair;
  final String sourceLanguage;
  final String targetLanguage;
  final String partOfSpeech;

  /// Short English gloss from dictionary (optional).
  final String microExplanation;
  final String exampleSentence;

  /// Free-tier daily translation call limit reached for this fragment request.
  final bool translateDailyQuotaExceeded;

  FragmentTranslation copyWith({
    String? translatedText,
    String? phonetic,
    String? pronunciation,
    String? audioUrl,
    String? languagePair,
    String? sourceLanguage,
    String? targetLanguage,
    String? partOfSpeech,
    String? microExplanation,
    String? exampleSentence,
    bool? translateDailyQuotaExceeded,
  }) {
    final nextPhonetic = phonetic ?? this.phonetic;
    final nextPronunciation = pronunciation ?? phonetic ?? this.pronunciation;
    return FragmentTranslation(
      translatedText: translatedText ?? this.translatedText,
      phonetic: nextPhonetic,
      pronunciation: nextPronunciation,
      audioUrl: audioUrl ?? this.audioUrl,
      languagePair: languagePair ?? this.languagePair,
      sourceLanguage: sourceLanguage ?? this.sourceLanguage,
      targetLanguage: targetLanguage ?? this.targetLanguage,
      partOfSpeech: partOfSpeech ?? this.partOfSpeech,
      microExplanation: microExplanation ?? this.microExplanation,
      exampleSentence: exampleSentence ?? this.exampleSentence,
      translateDailyQuotaExceeded:
          translateDailyQuotaExceeded ?? this.translateDailyQuotaExceeded,
    );
  }
}

class CaptureController extends Notifier<CaptureState> {
  static const Uuid _uuid = Uuid();
  static const Duration _translationDebounce = Duration(milliseconds: 20);
  static const Duration _translationWarmupCooldown = Duration(minutes: 2);
  int _messageEpoch = 0;
  bool _isCapturing = false;
  bool _knownWordsHydrated = false;
  final Set<String> _knownWords = <String>{};
  String _lastCaptureRawPassage = '';
  String? _pendingImageAnchorPath;
  String? _pendingVocabIdForSnapshot;
  Timer? _translateDebounceTimer;
  Completer<void>? _translateDebounceCompleter;
  String _lastDebounceKey = '';
  int _translationRequestCount = 0;
  DateTime? _lastTranslationWarmupAt;

  OcrAdapter get _ocrAdapter => ref.read(ocrAdapterProvider);
  VocabRepository get _repository => ref.read(vocabRepositoryProvider);
  CapturePipeline get _capturePipeline => ref.read(capturePipelineProvider);
  TranslationCache get _translationCache => ref.read(translationCacheProvider);
  TranslationService get _translationService =>
      ref.read(translationServiceProvider);
  TranslationService get _fragmentRefineTranslation =>
      ref.read(fragmentRefineTranslationServiceProvider);
  DictionaryLookupService get _dictionaryService =>
      ref.read(dictionaryLookupServiceProvider);
  SyncService get _syncService => ref.read(syncServiceProvider);
  String? get _currentUserId => ref.read(currentUserIdProvider);

  /// Overridable at runtime via OverlayPopupCommand so the popup can honour
  /// the user's language settings without requiring its own Hive instance.
  String _nativeLanguage = 'vi';
  List<String> _sourceLanguages = const <String>['en'];

  void updateLanguagePreferences({
    required String nativeLanguage,
    required List<String> sourceLanguages,
  }) {
    final normalizedNative = nativeLanguage.trim().toLowerCase();
    if (normalizedNative.isNotEmpty) {
      _nativeLanguage = normalizedNative;
    }
    final cleaned = sourceLanguages
        .map((lang) => lang.trim().toLowerCase())
        .where((lang) => lang.isNotEmpty)
        .toList(growable: false);
    if (cleaned.isNotEmpty) {
      _sourceLanguages = cleaned;
    }
    // Forward Tesseract language codes so OCR can recognise all selected
    // source languages, not just English.
    final tesseractCodes = <String>[];
    for (final code in _sourceLanguages) {
      final option = findLanguageOption(code);
      if (option != null) tesseractCodes.add(option.tesseractCode);
    }
    if (tesseractCodes.isNotEmpty) {
      applyOcrLanguages(_ocrAdapter, tesseractCodes);
    }
  }

  // Translation uses provider auto-detection. Source language preferences are
  // still used for OCR language packs.
  String get _preferredSourceLanguage => '';
  bool get _isDictionaryLookupEnabled => !Platform.isMacOS;

  String _buildLanguagePairLabel(String source) {
    final src = source.isEmpty ? 'auto' : source;
    return '$src-$_nativeLanguage';
  }

  @override
  CaptureState build() {
    ref.onDispose(() {
      _translateDebounceTimer?.cancel();
      if (_translateDebounceCompleter != null &&
          !_translateDebounceCompleter!.isCompleted) {
        _translateDebounceCompleter!.complete();
      }
    });
    return const CaptureState();
  }

  void prepareSession() {
    _lastCaptureRawPassage = '';
    _pendingImageAnchorPath = null;
    _pendingVocabIdForSnapshot = null;
    state = state.copyWith(
      sourceText: '',
      translatedText: '',
      phonetic: '',
      audioUrl: '',
      tags: const <String>[],
      sourceApp: '',
      message: 'Detecting...',
    );
  }

  /// Fire-and-forget warmup so the first visible translation feels faster.
  Future<void> warmupTranslationEngine() async {
    final now = DateTime.now();
    if (_lastTranslationWarmupAt != null &&
        now.difference(_lastTranslationWarmupAt!) < _translationWarmupCooldown) {
      return;
    }
    _lastTranslationWarmupAt = now;
    try {
      await _translationService.translate(
        TranslationRequest(
          text: 'hello',
          sourceLanguage: 'auto',
          targetLanguage: _nativeLanguage,
        ),
      );
    } catch (_) {
      // Ignore warmup failures; real user requests will retry normally.
    }
  }

  /// Translates [text] without updating [CaptureState] (for focus/meaning UI).
  Future<FragmentTranslation> translateFragment(String text) async {
    final input = text.trim();
    if (input.isEmpty) {
      return FragmentTranslation(
        translatedText: '',
        phonetic: '',
        pronunciation: '',
        audioUrl: '',
        languagePair: _buildLanguagePairLabel(''),
        sourceLanguage: _preferredSourceLanguage.isEmpty
            ? 'auto'
            : _preferredSourceLanguage,
        targetLanguage: _nativeLanguage,
      );
    }
    _translationRequestCount += 1;
    await _debounceTranslationInput(input);
    final requestStopwatch = Stopwatch()..start();
    final pack = await _translateTextWithGloss(input);
    if (pack.quotaExceeded) {
      requestStopwatch.stop();
      return FragmentTranslation(
        translatedText: '',
        phonetic: '',
        pronunciation: '',
        audioUrl: '',
        languagePair: _buildLanguagePairLabel(''),
        sourceLanguage: _preferredSourceLanguage.isEmpty
            ? 'auto'
            : _preferredSourceLanguage,
        targetLanguage: _nativeLanguage,
        translateDailyQuotaExceeded: true,
      );
    }
    final enrichment = pack.result;
    final effectiveTranslation = await _refineFragmentTranslation(
      input,
      enrichment,
      initialServedFromCache: pack.servedFromCache,
    );
    if (effectiveTranslation.isNotEmpty &&
        _isAcceptableFragmentTranslation(
          input,
          effectiveTranslation,
          enrichment,
        )) {
      _translationCache.save(input, effectiveTranslation);
    }
    final detectedSource = _resolveSourceLanguage(enrichment);
    var fragment = FragmentTranslation(
      translatedText: effectiveTranslation,
      phonetic: enrichment.phonetic,
      pronunciation: enrichment.phonetic,
      audioUrl: enrichment.audioUrl,
      languagePair: _buildLanguagePairLabel(detectedSource),
      sourceLanguage: detectedSource,
      targetLanguage: _nativeLanguage,
    );
    final isEnWord =
        _isSingleAsciiWord(input) &&
        detectedSource.toLowerCase().startsWith('en');
    if (isEnWord && _isDictionaryLookupEnabled) {
      final gloss =
          pack.dictionaryGloss ?? await _dictionaryService.lookupGloss(input);
      final ph = fragment.phonetic.isNotEmpty
          ? fragment.phonetic
          : gloss.phonetic;
      fragment = fragment.copyWith(
        phonetic: ph,
        pronunciation: ph,
        audioUrl: fragment.audioUrl.isNotEmpty
            ? fragment.audioUrl
            : gloss.audioUrl,
        partOfSpeech: gloss.partOfSpeech,
        microExplanation: gloss.shortDefinition,
        exampleSentence: gloss.example,
      );
    }
    requestStopwatch.stop();
    _debugTranslationLine(
      input: input,
      elapsedMs: requestStopwatch.elapsedMilliseconds,
      cacheServed: pack.servedFromCache,
    );
    return fragment;
  }

  Future<void> _debounceTranslationInput(String input) async {
    final key = TranslationCache.normalizeKey(input);
    if (key.isEmpty) {
      return;
    }
    if (_lastDebounceKey == key && _translateDebounceCompleter != null) {
      return _translateDebounceCompleter!.future;
    }
    if (_translationDebounce.inMilliseconds <= 0) {
      return;
    }
    _translateDebounceTimer?.cancel();
    final completer = Completer<void>();
    _translateDebounceCompleter = completer;
    _lastDebounceKey = key;
    _translateDebounceTimer = Timer(_translationDebounce, () {
      if (!completer.isCompleted) {
        completer.complete();
      }
    });
    return completer.future;
  }

  Future<void> capture() async {
    await captureTextMode();
  }

  Future<void> captureTextMode() async {
    await captureTextModeAtCursor();
  }

  Future<void> captureTextModeAtCursor({Offset? cursorPosition}) async {
    await _captureWithStrategy(
      strategy: () => _capturePipeline.captureText(
        ocrFallbackExtractor: () {
          if (cursorPosition == null) {
            return _ocrAdapter.extractText();
          }
          final nearCursorRegion = Rect.fromCenter(
            center: cursorPosition,
            width: 260,
            height: 140,
          );
          return _ocrAdapter.extractTextFromRegion(nearCursorRegion);
        },
      ),
      stageLabel: 'capture_text_latency_ms',
    );
  }

  Future<void> captureWithPrefilledText(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      state = state.copyWith(
        sourceText: '',
        translatedText: '',
        message: 'No selected text detected.',
      );
      return;
    }
    if (_isCapturing) {
      LoggerService.logSync(
        source: 'desktop_capture',
        stage: 'skip_capture_in_progress',
        success: true,
      );
      return;
    }
    _isCapturing = true;
    final stopwatch = Stopwatch()..start();
    try {
      await _applyCapturedPassageState(
        passage: trimmed,
        rawText: trimmed,
        mode: CaptureMode.text,
        imageRegion: null,
      );
      LoggerService.logOcrResult('desktop_capture', trimmed);
    } catch (error) {
      LoggerService.logError(
        source: 'desktop_capture',
        action: 'captureWithPrefilledText',
        error: error,
      );
      state = state.copyWith(
        sourceText: trimmed,
        translatedText: '',
        phonetic: '',
        audioUrl: '',
        message: 'Capture failed.',
      );
    } finally {
      stopwatch.stop();
      LoggerService.logSync(
        source: 'desktop_capture',
        stage: 'capture_text_latency_ms',
        success: stopwatch.elapsedMilliseconds < 500,
        count: stopwatch.elapsedMilliseconds,
      );
      _isCapturing = false;
    }
  }

  Future<void> captureImageMode({Rect? region}) async {
    await _captureWithStrategy(
      strategy: () => _capturePipeline.captureImage(
        ocrExtractor: () {
          if (region == null) {
            return _ocrAdapter.extractText();
          }
          return _ocrAdapter.extractTextFromRegion(region);
        },
      ),
      stageLabel: 'capture_image_latency_ms',
      imageRegion: region,
      modeOverride: CaptureMode.image,
    );
  }

  Future<void> _captureWithStrategy({
    required Future<CaptureResult> Function() strategy,
    required String stageLabel,
    Rect? imageRegion,
    CaptureMode? modeOverride,
  }) async {
    if (_isCapturing) {
      LoggerService.logSync(
        source: 'desktop_capture',
        stage: 'skip_capture_in_progress',
        success: true,
      );
      return;
    }
    _isCapturing = true;
    final stopwatch = Stopwatch()..start();
    try {
      final result = await strategy();
      if (result.detectedWord.isEmpty) {
        state = state.copyWith(
          sourceText: '',
          translatedText: '',
          message: 'No text detected.',
        );
        return;
      }
      await _applyCapturedPassageState(
        passage: result.detectedWord,
        rawText: result.rawText,
        mode: modeOverride ?? result.mode,
        imageRegion: modeOverride == CaptureMode.text ? null : imageRegion,
      );
    } catch (error) {
      LoggerService.logError(
        source: 'desktop_capture',
        action: 'capture',
        error: error,
      );
      state = state.copyWith(
        sourceText: '',
        translatedText: '',
        message: 'Capture failed.',
      );
    } finally {
      stopwatch.stop();
      LoggerService.logSync(
        source: 'desktop_capture',
        stage: stageLabel,
        success: stopwatch.elapsedMilliseconds < 500,
        count: stopwatch.elapsedMilliseconds,
      );
      _isCapturing = false;
    }
  }

  Future<void> _applyCapturedPassageState({
    required String passage,
    required String rawText,
    required CaptureMode mode,
    Rect? imageRegion,
  }) async {
    final normalizedPassage = passage.trim();
    final normalizedRaw = rawText.trim();
    if (normalizedPassage.isEmpty) {
      return;
    }
    LoggerService.logOcrResult(
      'desktop_capture',
      normalizedRaw.isEmpty ? normalizedPassage : normalizedRaw,
    );
    _lastCaptureRawPassage = normalizedRaw.isNotEmpty
        ? normalizedRaw
        : normalizedPassage;
    await _updatePendingImageMetadata(mode: mode, imageRegion: imageRegion);
    state = state.copyWith(
      sourceText: normalizedPassage,
      translatedText: '',
      phonetic: '',
      audioUrl: '',
      tags: const <String>[],
      message: _sourceMessageForMode(mode),
    );
  }

  Future<void> _updatePendingImageMetadata({
    required CaptureMode mode,
    Rect? imageRegion,
  }) async {
    if (mode == CaptureMode.image &&
        imageRegion != null &&
        (Platform.isWindows || Platform.isMacOS)) {
      final snapId = _uuid.v4();
      final path = await CaptureImageStorage.persistRegionPng(
        imageRegion,
        fileBaseName: snapId,
      );
      if (path.isNotEmpty) {
        _pendingImageAnchorPath = path;
        _pendingVocabIdForSnapshot = snapId;
      } else {
        _pendingImageAnchorPath = null;
        _pendingVocabIdForSnapshot = null;
      }
      return;
    }
    _pendingImageAnchorPath = null;
    _pendingVocabIdForSnapshot = null;
  }

  String _sourceMessageForMode(CaptureMode mode) {
    return switch (mode) {
      CaptureMode.text => 'Captured selected text.',
      CaptureMode.image => 'Captured text from OCR.',
    };
  }

  Future<void> saveCurrent() async {
    final passage = state.sourceText;
    await saveFocusedFragment(
      sourceText: state.sourceText,
      translatedText: state.translatedText,
      languagePair: state.languagePair,
      passageForContext: passage,
      selectionStart: 0,
      selectionEnd: passage.length,
      phoneticExtra: state.phonetic,
      audioUrlExtra: state.audioUrl,
      sourceUrl: '',
    );
  }

  Future<CaptureSaveResult> saveFocusedFragment({
    required String sourceText,
    required String translatedText,
    required String languagePair,
    String? passageForContext,
    int? selectionStart,
    int? selectionEnd,
    String phoneticExtra = '',
    String audioUrlExtra = '',
    String partOfSpeechExtra = '',
    String sourceUrl = '',
    List<String> tags = const <String>[],
    String sourceApp = '',
  }) async {
    if (state.isSaving) {
      return const CaptureSaveResult(success: false, message: '');
    }
    final trimmedSource = sourceText.trim();
    final trimmedTranslated = translatedText.trim();
    if (trimmedSource.isEmpty || trimmedTranslated.isEmpty) {
      state = state.copyWith(message: 'Nothing to save yet.');
      return const CaptureSaveResult(success: false, message: 'Nothing to save yet.');
    }

    state = state.copyWith(isSaving: true, message: null);
    final result = await saveCapturedEntry(
      sourceText: trimmedSource,
      translatedText: trimmedTranslated,
      languagePair: languagePair,
      passageForContext: passageForContext,
      selectionStart: selectionStart,
      selectionEnd: selectionEnd,
      phoneticExtra: phoneticExtra.isNotEmpty ? phoneticExtra : state.phonetic,
      audioUrlExtra: audioUrlExtra.isNotEmpty ? audioUrlExtra : state.audioUrl,
      partOfSpeechExtra: partOfSpeechExtra,
      sourceUrl: sourceUrl,
      tags: tags,
      sourceApp: sourceApp,
    );
    state = state.copyWith(isSaving: false, message: result.message);
    if (result.success) {
      _messageEpoch += 1;
      final epoch = _messageEpoch;
      unawaited(
        _clearTransientMessage(
          expectedMessage: result.message,
          epoch: epoch,
          delay: const Duration(milliseconds: 900),
        ),
      );
    }
    return result;
  }

  Future<CaptureSaveResult> saveCapturedEntry({
    required String sourceText,
    required String translatedText,
    required String languagePair,
    String? passageForContext,
    int? selectionStart,
    int? selectionEnd,
    String phoneticExtra = '',
    String audioUrlExtra = '',
    String partOfSpeechExtra = '',
    String sourceUrl = '',
    List<String> tags = const <String>[],
    String sourceApp = '',
  }) async {
    final normalizedTags = tags
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .take(1)
        .toList(growable: false);
    final trimmedSource = sourceText.trim();
    final trimmedTranslated = translatedText.trim();
    final trimmedPair = languagePair.trim().isEmpty
        ? 'en-vi'
        : languagePair.trim();
    if (trimmedSource.isEmpty || trimmedTranslated.isEmpty) {
      return const CaptureSaveResult(
        success: false,
        message: 'Nothing to save yet.',
      );
    }

    await _ensureKnownWordsHydrated();
    final normalizedWord = _normalizeWord(trimmedSource);
    if (normalizedWord.isNotEmpty && _knownWords.contains(normalizedWord)) {
      return const CaptureSaveResult(success: true, message: 'Already saved');
    }

    if (!ref.read(appStateProvider).isPro) {
      final allowed = await ref
          .read(appStateProvider.notifier)
          .tryConsumeDailyVocabSave();
      if (!allowed) {
        return const CaptureSaveResult(
          success: false,
          message: '',
          dailySaveQuotaExceeded: true,
        );
      }
    }

    try {
      final passage =
          (passageForContext != null && passageForContext.trim().isNotEmpty)
          ? passageForContext.trim()
          : (_lastCaptureRawPassage.trim().isNotEmpty
                ? _lastCaptureRawPassage.trim()
                : trimmedSource);
      final originalSentence = ContextSentenceExtractor.sentenceContaining(
        passage: passage,
        term: trimmedSource,
        termStart: selectionStart,
        termEnd: selectionEnd,
      );
      final sourceAppLabel = sourceApp.trim().isNotEmpty
          ? sourceApp.trim()
          : (state.sourceApp.trim().isNotEmpty
                ? state.sourceApp.trim()
                : readForegroundWindowLabel());
      final normalizedSourceUrl = _normalizeSourceUrlForSave(sourceUrl);
      final enrichedSourceAppLabel = _enrichSourceLabel(
        sourceLabel: sourceAppLabel,
        sourceUrl: normalizedSourceUrl,
      );
      final vocabId =
          (_pendingImageAnchorPath != null &&
              _pendingImageAnchorPath!.trim().isNotEmpty)
          ? (_pendingVocabIdForSnapshot ?? _uuid.v4())
          : _uuid.v4();
      final vocab = Vocab.initial(
        id: vocabId,
        sourceText: trimmedSource,
        translatedText: trimmedTranslated,
        languagePair: trimmedPair,
        partOfSpeech: partOfSpeechExtra.trim(),
        phonetic: phoneticExtra.trim(),
        originalSentence: originalSentence,
        contextParagraph: passage,
        sourceApp: enrichedSourceAppLabel,
        sourceUrl: normalizedSourceUrl,
        imageAnchor: _pendingImageAnchorPath?.trim() ?? '',
        audioUrl: audioUrlExtra.trim(),
        tags: normalizedTags,
      );
      _pendingImageAnchorPath = null;
      _pendingVocabIdForSnapshot = null;
      await _repository.saveVocab(vocab);
      LoggerService.logSaveAction(
        source: 'desktop_capture',
        vocabId: vocab.id,
        success: true,
      );
      if (normalizedWord.isNotEmpty) {
        _knownWords.add(normalizedWord);
      }
      await _enrichSavedVocabIfEligible(vocab);
      if (ref.read(cloudMediaSyncProvider)) {
        unawaited(_uploadCaptureImageIfNeeded(vocab));
      }
      final savedMessage = _currentUserId == null
          ? 'Saved locally. Sign in to sync.'
          : 'Saved ✓';
      unawaited(_triggerBackgroundSync());
      return CaptureSaveResult(success: true, message: savedMessage);
    } catch (error) {
      LoggerService.logError(
        source: 'desktop_capture',
        action: 'saveCurrent',
        error: error,
      );
      return CaptureSaveResult(success: false, message: 'Save failed: $error');
    }
  }

  Future<void> _uploadCaptureImageIfNeeded(Vocab saved) async {
    // Supabase storage upload is removed in Drive-only mode.
    return;
  }

  Future<void> _enrichSavedVocabIfEligible(Vocab saved) async {
    if (!_isDictionaryLookupEnabled) {
      return;
    }
    final term = saved.sourceText.trim();
    if (!_isSingleAsciiWord(term)) {
      return;
    }
    final pairParts = saved.languagePair.split('-');
    final sourceCode = pairParts.isNotEmpty
        ? pairParts.first.trim().toLowerCase()
        : '';
    if (!sourceCode.startsWith('en')) {
      return;
    }
    try {
      final gloss = await _dictionaryService.lookupGloss(term);
      if (gloss.phonetic.isEmpty &&
          gloss.partOfSpeech.isEmpty &&
          gloss.audioUrl.isEmpty) {
        return;
      }
      final nextPhonetic = saved.phonetic.isNotEmpty
          ? saved.phonetic
          : gloss.phonetic;
      final nextAudio = saved.audioUrl.isNotEmpty
          ? saved.audioUrl
          : gloss.audioUrl;
      final nextPos = saved.partOfSpeech.isNotEmpty
          ? saved.partOfSpeech
          : gloss.partOfSpeech;
      final updated = saved.copyWith(
        phonetic: nextPhonetic,
        audioUrl: nextAudio,
        partOfSpeech: nextPos,
        updatedAt: DateTime.now(),
      );
      await _repository.saveVocab(updated);
    } catch (error) {
      LoggerService.logError(
        source: 'desktop_capture',
        action: 'enrichVocab',
        error: error,
      );
    }
  }

  Future<_TranslationWithOptionalGloss> _translateTextWithGloss(
    String text,
  ) async {
    final input = text.trim();
    if (input.isEmpty) {
      return const _TranslationWithOptionalGloss(
        result: TranslationResult.empty,
      );
    }
    TranslationResult base = TranslationResult.empty;
    var servedFromCache = false;
    final cached = _translationCache.getCached(input);
    if (cached != null && cached.isNotEmpty) {
      base = TranslationResult(translatedText: cached);
      servedFromCache = true;
    } else {
      final ok = await ref
          .read(appStateProvider.notifier)
          .tryConsumeDailyTranslateCall();
      if (!ok) {
        return const _TranslationWithOptionalGloss(
          result: TranslationResult.empty,
          quotaExceeded: true,
        );
      }
      final translated = await _translationService.translate(
        TranslationRequest(
          text: input,
          sourceLanguage: _preferredSourceLanguage,
          targetLanguage: _nativeLanguage,
        ),
      );
      if (translated.translatedText.trim().isEmpty) {
        // Backend call failed/empty: do not burn user's daily quota.
        await ref.read(appStateProvider.notifier).refundDailyTranslateCall();
      }
      if (translated.translatedText.isNotEmpty &&
          _isAcceptableFragmentTranslation(
            input,
            translated.translatedText,
            translated,
          )) {
        _translationCache.save(input, translated.translatedText);
      }
      base = translated;
    }

    // Prioritize translation latency: don't block UI translation on dictionary
    // lookup when translation already succeeded.
    final isLikelyEnglishWord =
        _isSingleAsciiWord(input) &&
        _resolveSourceLanguage(base).startsWith('en');
    if (_isDictionaryLookupEnabled &&
        isLikelyEnglishWord &&
        base.translatedText.trim().isEmpty) {
      final gloss = await _dictionaryService.lookupGloss(input);
      base = base.copyWith(
        phonetic: gloss.phonetic,
        audioUrl: gloss.audioUrl,
        detectedSourceLanguage: base.detectedSourceLanguage.isEmpty
            ? 'en'
            : base.detectedSourceLanguage,
      );
      return _TranslationWithOptionalGloss(
        result: base,
        dictionaryGloss: gloss,
        servedFromCache: servedFromCache,
      );
    }
    return _TranslationWithOptionalGloss(
      result: base,
      servedFromCache: servedFromCache,
    );
  }

  String _resolveSourceLanguage(TranslationResult result) {
    if (result.detectedSourceLanguage.isNotEmpty) {
      return result.detectedSourceLanguage;
    }
    return _preferredSourceLanguage.isEmpty ? 'auto' : _preferredSourceLanguage;
  }

  String _primaryLanguageCode(String code) {
    final t = code.trim().toLowerCase();
    if (t.isEmpty) {
      return '';
    }
    return t.split(RegExp(r'[-_]')).first;
  }

  /// True when [translated] is a usable gloss for the popup (non-empty, and not
  /// a spurious copy of [input] while translating into a different language).
  bool _isAcceptableFragmentTranslation(
    String input,
    String translated,
    TranslationResult meta,
  ) {
    final t = translated.trim();
    if (t.isEmpty) {
      return false;
    }
    if (input.trim().toLowerCase() != t.toLowerCase()) {
      return true;
    }
    final det = _primaryLanguageCode(_resolveSourceLanguage(meta));
    final tgt = _primaryLanguageCode(_nativeLanguage);
    if (tgt.isEmpty) {
      return true;
    }
    if (det.isEmpty) {
      return false;
    }
    return det == tgt;
  }

  /// Retries translation when the first pass is empty or only echoes [input]
  /// while the user's native language differs from the detected source.
  ///
  /// Skips a redundant `en|…` request when the first pass was already a fresh
  /// call with English as the preferred source (avoids duplicate work).
  Future<String> _refineFragmentTranslation(
    String input,
    TranslationResult initial, {
    required bool initialServedFromCache,
  }) async {
    if (_isAcceptableFragmentTranslation(
      input,
      initial.translatedText,
      initial,
    )) {
      return initial.translatedText.trim();
    }
    final target = _nativeLanguage.trim().isEmpty
        ? null
        : _nativeLanguage.trim();
    final prefCode = _primaryLanguageCode(_preferredSourceLanguage);
    final sourceOverrides = <String?>[];
    if (prefCode != 'en' || initialServedFromCache) {
      sourceOverrides.add('en');
    }
    sourceOverrides.add(null);
    for (final sourceOverride in sourceOverrides) {
      final ok = await ref
          .read(appStateProvider.notifier)
          .tryConsumeDailyTranslateCall();
      if (!ok) {
        break;
      }
      final r = await _fragmentRefineTranslation.translate(
        TranslationRequest(
          text: input,
          sourceLanguage: sourceOverride,
          targetLanguage: target,
        ),
      );
      if (_isAcceptableFragmentTranslation(input, r.translatedText, r)) {
        return r.translatedText.trim();
      }
    }
    final t0 = initial.translatedText.trim();
    if (t0.isNotEmpty) {
      return t0;
    }
    return '';
  }

  bool _isSingleAsciiWord(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return false;
    return RegExp(r"^[A-Za-z][A-Za-z'\-]*$").hasMatch(trimmed);
  }

  Future<void> _triggerBackgroundSync() async {
    try {
      _syncService.triggerSync();
    } catch (error) {
      LoggerService.logError(
        source: 'desktop_capture',
        action: 'triggerBackgroundSync',
        error: error,
      );
    }
  }

  Future<void> _clearTransientMessage({
    required String expectedMessage,
    required int epoch,
    required Duration delay,
  }) async {
    await Future<void>.delayed(delay);
    if (_messageEpoch != epoch) {
      return;
    }
    if (state.message != expectedMessage || state.isSaving) {
      return;
    }
    state = state.copyWith(message: null);
  }

  Future<void> _ensureKnownWordsHydrated() async {
    if (_knownWordsHydrated) {
      return;
    }
    final all = await _repository.getAllVocab();
    for (final item in all) {
      final normalized = _normalizeWord(item.sourceText);
      if (normalized.isNotEmpty) {
        _knownWords.add(normalized);
      }
    }
    _knownWordsHydrated = true;
  }

  String _normalizeWord(String value) {
    return value.trim().toLowerCase();
  }

  String _enrichSourceLabel({
    required String sourceLabel,
    required String sourceUrl,
  }) {
    final label = _normalizeSourceLabelForSave(sourceLabel);
    if (label.isEmpty) {
      return label;
    }
    final hasDetails = label.contains('—') || label.contains('|');
    if (hasDetails) {
      return label;
    }
    final domain = _domainFromUrl(sourceUrl);
    if (domain.isEmpty) {
      return label;
    }
    if (label.toLowerCase().contains(domain.toLowerCase())) {
      return label;
    }
    return '$label — $domain';
  }

  String _normalizeSourceLabelForSave(String raw) {
    final cleaned = raw.trim();
    if (cleaned.isEmpty) {
      return '';
    }
    final parts = cleaned
        .split(RegExp(r'\s*(?:—|\||•|›|»|>|-)\s*'))
        .map((p) => _collapseWhitespace(p))
        .where((p) => p.isNotEmpty)
        .toList(growable: false);
    if (parts.isEmpty) {
      return '';
    }
    final seen = <String>{};
    final deduped = <String>[];
    for (final part in parts) {
      final key = part.toLowerCase();
      if (seen.add(key)) {
        deduped.add(part);
      }
    }
    return deduped.join(' — ');
  }

  String _normalizeSourceUrlForSave(String rawUrl) {
    final value = rawUrl.trim();
    if (value.isEmpty) {
      return '';
    }
    final uri = Uri.tryParse(value);
    if (uri == null || uri.host.trim().isEmpty) {
      return _collapseWhitespace(value);
    }
    final host = uri.host.toLowerCase();
    final normHost = host.startsWith('www.') ? host.substring(4) : host;
    final path = uri.path.trim();
    final normalizedPath = path == '/' ? '' : path;
    final query = _dedupeQuery(uri.query);
    return Uri(
      scheme: uri.scheme.isEmpty ? 'https' : uri.scheme.toLowerCase(),
      host: normHost,
      path: normalizedPath,
      query: query.isEmpty ? null : query,
      fragment: '',
    ).toString();
  }

  String _dedupeQuery(String rawQuery) {
    if (rawQuery.trim().isEmpty) {
      return '';
    }
    final pairs = rawQuery
        .split('&')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList(growable: false);
    final seen = <String>{};
    final out = <String>[];
    for (final pair in pairs) {
      if (seen.add(pair)) {
        out.add(pair);
      }
    }
    return out.join('&');
  }

  String _collapseWhitespace(String input) {
    return input.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  String _domainFromUrl(String rawUrl) {
    final value = rawUrl.trim();
    if (value.isEmpty) {
      return '';
    }
    final uri = Uri.tryParse(value);
    if (uri == null || uri.host.trim().isEmpty) {
      return '';
    }
    final host = uri.host.toLowerCase();
    return host.startsWith('www.') ? host.substring(4) : host;
  }

  void _debugTranslationLine({
    required String input,
    required int elapsedMs,
    required bool cacheServed,
  }) {
    assert(() {
      final hit = _translationCache.hitCount;
      final miss = _translationCache.missCount;
      final ratio = (_translationCache.hitRatio * 100).toStringAsFixed(1);
      debugPrint(
        'translate_dbg controller lat=${elapsedMs}ms cache=${cacheServed ? 'hit' : 'miss'} '
        'hit=$hit miss=$miss hitRatio=$ratio% req=$_translationRequestCount textLen=${input.length}',
      );
      return true;
    }());
  }
}

final captureControllerProvider =
    NotifierProvider<CaptureController, CaptureState>(CaptureController.new);
