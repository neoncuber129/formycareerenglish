import 'package:clock/clock.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_models/shared_models.dart';

import '../../../core/monetization/app_state.dart';
import '../../../core/sync/sync_service.dart';
import '../../vocab/data/vocab_repository_impl.dart';
import '../../vocab/domain/vocab_repository.dart';

/// Immutable outcome when the user finishes the last card in a review session.
@immutable
class ReviewSessionResult {
  const ReviewSessionResult({
    required this.totalReviewed,
    required this.masteredCount,
    required this.duration,
  });

  /// Cards answered in this session (same as session history length).
  final int totalReviewed;

  /// Times the user chose Good or Easy.
  final int masteredCount;

  /// Wall-clock duration from session start to completion.
  final Duration duration;
}

enum ReviewMode { forward, reverseMeaning, reverseAudio, mixed }

class ReviewState {
  const ReviewState({
    this.cards = const <Vocab>[],
    this.currentIndex = 0,
    this.totalCards = 0,
    this.waitingCardCount = 0,
    this.sessionHistory = const <ReviewSessionEntry>[],
    this.isFlipped = false,
    this.loading = false,
    this.sourceOptions = const <String>[],
    this.sourceFilter,
    this.languageOptions = const <String>[],
    this.languageFilter,
    this.reviewMode = ReviewMode.forward,
    this.promptMode = ReviewMode.forward,
    this.sessionResult,
    this.quotaExceededMessage,
    this.customStudyOptions = CustomStudyOptions.defaults,
    this.sessionQueueCounts = const StudySessionQueueCounts(
      newCount: 0,
      learningCount: 0,
      reviewCount: 0,
    ),
  });

  final List<Vocab> cards;
  final int currentIndex;
  final int totalCards;
  final int waitingCardCount;
  final List<ReviewSessionEntry> sessionHistory;
  final bool isFlipped;
  final bool loading;
  final List<String> sourceOptions;
  final String? sourceFilter;
  final List<String> languageOptions;
  final String? languageFilter;
  final ReviewMode reviewMode;
  final ReviewMode promptMode;

  /// Set when the last answer completes the queue; drives navigation to summary.
  final ReviewSessionResult? sessionResult;

  /// One-shot UX message when Free daily SRS quota is exhausted.
  final String? quotaExceededMessage;

  final CustomStudyOptions customStudyOptions;

  final StudySessionQueueCounts sessionQueueCounts;

  Vocab? get currentCard {
    if (cards.isEmpty || currentIndex >= cards.length) {
      return null;
    }
    return cards[currentIndex];
  }

  bool get hasFinished =>
      totalCards > 0 && cards.isEmpty && waitingCardCount == 0;

  int get answeredCount => sessionHistory.length;

  ReviewState copyWith({
    List<Vocab>? cards,
    int? currentIndex,
    int? totalCards,
    int? waitingCardCount,
    List<ReviewSessionEntry>? sessionHistory,
    bool? isFlipped,
    bool? loading,
    List<String>? sourceOptions,
    String? sourceFilter,
    List<String>? languageOptions,
    String? languageFilter,
    ReviewMode? reviewMode,
    ReviewMode? promptMode,
    ReviewSessionResult? sessionResult,
    String? quotaExceededMessage,
    bool clearQuotaExceededMessage = false,
    CustomStudyOptions? customStudyOptions,
    StudySessionQueueCounts? sessionQueueCounts,
  }) {
    return ReviewState(
      cards: cards ?? this.cards,
      currentIndex: currentIndex ?? this.currentIndex,
      totalCards: totalCards ?? this.totalCards,
      waitingCardCount: waitingCardCount ?? this.waitingCardCount,
      sessionHistory: sessionHistory ?? this.sessionHistory,
      isFlipped: isFlipped ?? this.isFlipped,
      loading: loading ?? this.loading,
      sourceOptions: sourceOptions ?? this.sourceOptions,
      sourceFilter: sourceFilter ?? this.sourceFilter,
      languageOptions: languageOptions ?? this.languageOptions,
      languageFilter: languageFilter ?? this.languageFilter,
      reviewMode: reviewMode ?? this.reviewMode,
      promptMode: promptMode ?? this.promptMode,
      sessionResult: sessionResult ?? this.sessionResult,
      quotaExceededMessage: clearQuotaExceededMessage
          ? null
          : (quotaExceededMessage ?? this.quotaExceededMessage),
      customStudyOptions: customStudyOptions ?? this.customStudyOptions,
      sessionQueueCounts: sessionQueueCounts ?? this.sessionQueueCounts,
    );
  }
}

/// SRS review session. Reads/writes through [vocabRepositoryProvider]
/// (mobile production wiring uses HybridVocabRepository).
class ReviewController extends Notifier<ReviewState> {
  VocabRepository get _repository => ref.read(vocabRepositoryProvider);
  static const SrsCalculator _srsCalculator = SrsCalculator();
  static const int _relearningLastStepIndex = 1;

  DateTime? _sessionStartTime;
  int _masteredCount = 0;
  final Map<String, int> _relearningStepByCardId = <String, int>{};
  final Map<String, int> _preLapseIntervalByCardId = <String, int>{};
  final List<_PendingQueueCard> _delayedQueue = <_PendingQueueCard>[];
  final Map<String, List<ReviewMode>> _mixedModesRemainingByCardId =
      <String, List<ReviewMode>>{};
  Timer? _dueTimer;

  /// Pinned subset for custom study (mirrors mobile).
  Set<String>? _pinnedVocabIds;

  CustomStudyOptions _sessionOptions = CustomStudyOptions.defaults;

  @override
  ReviewState build() {
    return const ReviewState();
  }

  void dispose() {
    _dueTimer?.cancel();
  }

  Future<void> load({
    String? sourceApp,
    String? sourceLanguage,
    Set<String>? selectedVocabIds,
    ReviewMode reviewMode = ReviewMode.forward,
    CustomStudyOptions customStudyOptions = CustomStudyOptions.defaults,
  }) async {
    _sessionOptions = customStudyOptions;
    var effectiveReviewMode = reviewMode;
    if (effectiveReviewMode == ReviewMode.mixed &&
        !ref.read(appStateProvider).isPro) {
      effectiveReviewMode = ReviewMode.forward;
    }
    if (selectedVocabIds != null) {
      _pinnedVocabIds = selectedVocabIds.isEmpty
          ? null
          : Set<String>.from(selectedVocabIds);
    }
    state = state.copyWith(loading: true);
    final all = await _repository.getAllVocab();
    final options =
        all
            .map((v) => v.sourceApp.trim())
            .where((s) => s.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    final languageOptions =
        all
            .map((v) => _sourceLanguageFromPair(v.languagePair))
            .where((s) => s.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    final now = clock.now();
    final pinned = _pinnedVocabIds ?? const <String>{};
    final selectedFiltered = pinned.isEmpty
        ? all
        : all.where((v) => pinned.contains(v.id)).toList(growable: false);
    var dueSorted = selectDueVocabsSorted(selectedFiltered, now);
    if (pinned.isNotEmpty) {
      // In selected-study mode, review all selected words regardless of due date.
      dueSorted = selectedFiltered.toList(growable: false);
    }
    if (sourceApp != null && sourceApp.trim().isNotEmpty) {
      dueSorted = dueSorted
          .where((c) => c.sourceApp.trim() == sourceApp.trim())
          .toList(growable: false);
    }
    if (sourceLanguage != null && sourceLanguage.trim().isNotEmpty) {
      final selectedLang = sourceLanguage.trim().toLowerCase();
      dueSorted = dueSorted
          .where((c) => _sourceLanguageFromPair(c.languagePair) == selectedLang)
          .toList(growable: false);
    }
    _masteredCount = 0;
    _relearningStepByCardId.clear();
    _preLapseIntervalByCardId.clear();
    _delayedQueue.clear();
    _mixedModesRemainingByCardId.clear();
    _dueTimer?.cancel();
    _dueTimer = null;
    final mergedQueue = buildStudyQueueFromDue(
      dueSorted: dueSorted,
      options: _sessionOptions,
    );
    if (effectiveReviewMode == ReviewMode.mixed) {
      for (final card in mergedQueue) {
        _mixedModesRemainingByCardId[card.id] = _mixedSubModes();
      }
    }
    final sessionCounts = countStudySessionBuckets(mergedQueue);
    _sessionStartTime = mergedQueue.isEmpty ? null : clock.now();
    state = ReviewState(
      cards: mergedQueue,
      totalCards: mergedQueue.length,
      loading: false,
      sourceOptions: options,
      sourceFilter: sourceApp,
      languageOptions: languageOptions,
      languageFilter: sourceLanguage,
      reviewMode: effectiveReviewMode,
      promptMode: _resolvePromptMode(effectiveReviewMode, mergedQueue),
      quotaExceededMessage: null,
      customStudyOptions: _sessionOptions,
      sessionQueueCounts: sessionCounts,
    );
  }

  /// Clears session state after the user leaves the summary screen.
  void resetSession() {
    _sessionStartTime = null;
    _masteredCount = 0;
    _relearningStepByCardId.clear();
    _preLapseIntervalByCardId.clear();
    _delayedQueue.clear();
    _mixedModesRemainingByCardId.clear();
    _dueTimer?.cancel();
    _dueTimer = null;
    _pinnedVocabIds = null;
    _sessionOptions = CustomStudyOptions.defaults;
    state = const ReviewState();
  }

  Future<void> setSourceFilter(String? sourceApp) async {
    await load(
      sourceApp: sourceApp,
      sourceLanguage: state.languageFilter,
      reviewMode: state.reviewMode,
      customStudyOptions: _sessionOptions,
    );
  }

  Future<void> setLanguageFilter(String? sourceLanguage) async {
    await load(
      sourceApp: state.sourceFilter,
      sourceLanguage: sourceLanguage,
      reviewMode: state.reviewMode,
      customStudyOptions: _sessionOptions,
    );
  }

  Future<void> setReviewMode(
    ReviewMode reviewMode, {
    Set<String>? selectedVocabIds,
  }) async {
    await load(
      sourceApp: state.sourceFilter,
      sourceLanguage: state.languageFilter,
      selectedVocabIds: selectedVocabIds,
      reviewMode: reviewMode,
      customStudyOptions: _sessionOptions,
    );
  }

  void toggleFlip() {
    if (state.currentCard == null) {
      return;
    }
    state = state.copyWith(isFlipped: !state.isFlipped);
  }

  Future<void> answer(ReviewGrade grade) async {
    final card = state.currentCard;
    if (card == null) {
      return;
    }

    if (!await ref
        .read(appStateProvider.notifier)
        .tryConsumeDailyReviewGrade()) {
      final limit = ref.read(appStateProvider).freeDailyReviewLimit;
      state = state.copyWith(
        quotaExceededMessage:
            'Daily review limit reached ($limit/day). '
            'Upgrade to Pro for unlimited reviews.',
      );
      return;
    }

    final now = clock.now();
    final isRelearning = _relearningStepByCardId.containsKey(card.id);
    final List<Vocab> remainingQueue = state.cards.sublist(
      state.currentIndex + 1,
    );
    var nextQueue = remainingQueue;
    Vocab updated;

    if (isRelearning) {
      final stepIndex = _relearningStepByCardId[card.id]!;
      if (grade == ReviewGrade.again) {
        _relearningStepByCardId[card.id] = 0;
        updated = _srsCalculator.applyLapseAgain(card, now);
        _enqueueDelayedCard(updated);
      } else if (stepIndex < _relearningLastStepIndex) {
        _relearningStepByCardId[card.id] = stepIndex + 1;
        updated = _srsCalculator.scheduleRelearningStep(
          card,
          now,
          SrsCalculator.relearningSecondStep,
        );
        _enqueueDelayedCard(updated);
      } else {
        final preLapseInterval =
            _preLapseIntervalByCardId[card.id] ?? card.intervalDays;
        _relearningStepByCardId.remove(card.id);
        _preLapseIntervalByCardId.remove(card.id);
        updated = _srsCalculator.graduateFromRelearning(
          card,
          grade,
          now,
          preLapseIntervalDays: preLapseInterval,
        );
      }
    } else if (SrsCalculator.isInNewLearningPipeline(card)) {
      updated = _srsCalculator.applyNewCardLearning(card, grade, now);
      final shortDelay = SrsCalculator.isInNewLearningPipeline(updated) &&
          updated.nextReviewAt.difference(now) < const Duration(hours: 20);
      if (shortDelay) {
        _enqueueDelayedCard(updated);
      }
    } else if (grade == ReviewGrade.again) {
      _preLapseIntervalByCardId[card.id] = card.intervalDays;
      _relearningStepByCardId[card.id] = 0;
      updated = _srsCalculator.applyLapseAgain(card, now);
      _enqueueDelayedCard(updated);
    } else {
      updated = _srsCalculator.applyReview(card, grade, now);
    }

    if (_sessionOptions.respectScheduling) {
      await _repository.updateReviewProgress(updated);
      try {
        await ref.read(syncServiceProvider).pushPending();
      } catch (error) {
        debugPrint('ReviewController pushPending skipped: $error');
      }
    }

    if (grade == ReviewGrade.good || grade == ReviewGrade.easy) {
      _masteredCount++;
    }
    if (state.reviewMode == ReviewMode.mixed) {
      final remainingModes = _mixedModesRemainingByCardId[card.id];
      if (remainingModes != null && remainingModes.isNotEmpty) {
        remainingModes.remove(state.promptMode);
        if (remainingModes.isNotEmpty) {
          nextQueue = <Vocab>[...nextQueue, updated];
        } else {
          _mixedModesRemainingByCardId.remove(card.id);
        }
      }
    }

    final entry = ReviewSessionEntry(
      vocabAfterReview: updated,
      grade: grade,
      answeredAt: now,
    );

    final newHistory = [...state.sessionHistory, entry];
    if (nextQueue.isEmpty && _delayedQueue.isNotEmpty) {
      nextQueue = <Vocab>[...nextQueue, _takeNextDelayedCardNow()];
    }
    final finished = nextQueue.isEmpty && _delayedQueue.isEmpty;

    ReviewSessionResult? result;
    if (finished) {
      final start = _sessionStartTime ?? now;
      result = ReviewSessionResult(
        totalReviewed: newHistory.length,
        masteredCount: _masteredCount,
        duration: now.difference(start),
      );
    }

    state = ReviewState(
      cards: nextQueue,
      currentIndex: 0,
      totalCards: state.totalCards,
      waitingCardCount: _delayedQueue.length,
      sessionHistory: newHistory,
      isFlipped: false,
      loading: state.loading,
      sourceOptions: state.sourceOptions,
      sourceFilter: state.sourceFilter,
      languageOptions: state.languageOptions,
      languageFilter: state.languageFilter,
      reviewMode: state.reviewMode,
      promptMode: _resolvePromptMode(state.reviewMode, nextQueue),
      sessionResult: result,
      quotaExceededMessage: null,
      customStudyOptions: state.customStudyOptions,
      sessionQueueCounts: state.sessionQueueCounts,
    );
    _scheduleNextDue();
  }

  void clearQuotaExceededMessage() {
    if (state.quotaExceededMessage == null) {
      return;
    }
    state = state.copyWith(clearQuotaExceededMessage: true);
  }

  void _enqueueDelayedCard(Vocab card) {
    _delayedQueue.add(_PendingQueueCard(card: card, dueAt: card.nextReviewAt));
    _delayedQueue.sort((a, b) => a.dueAt.compareTo(b.dueAt));
  }

  Vocab _takeNextDelayedCardNow() {
    final pending = _delayedQueue.removeAt(0);
    return pending.card;
  }

  void _scheduleNextDue() {
    _dueTimer?.cancel();
    _dueTimer = null;
    if (_delayedQueue.isEmpty) {
      return;
    }
    final now = clock.now();
    final nextDue = _delayedQueue.first.dueAt;
    final wait = nextDue.isAfter(now) ? nextDue.difference(now) : Duration.zero;
    _dueTimer = Timer(wait, _promoteDueCards);
  }

  void _promoteDueCards() {
    final now = clock.now();
    if (_delayedQueue.isEmpty) {
      return;
    }
    final dueCards = <Vocab>[];
    _delayedQueue.removeWhere((pending) {
      if (!pending.dueAt.isAfter(now)) {
        dueCards.add(pending.card);
        return true;
      }
      return false;
    });
    if (dueCards.isNotEmpty) {
      state = ReviewState(
        cards: <Vocab>[...state.cards, ...dueCards],
        currentIndex: 0,
        totalCards: state.totalCards,
        waitingCardCount: _delayedQueue.length,
        sessionHistory: state.sessionHistory,
        isFlipped: false,
        loading: state.loading,
        sourceOptions: state.sourceOptions,
        sourceFilter: state.sourceFilter,
        languageOptions: state.languageOptions,
        languageFilter: state.languageFilter,
        reviewMode: state.reviewMode,
        promptMode: _resolvePromptMode(state.reviewMode, <Vocab>[
          ...state.cards,
          ...dueCards,
        ]),
        quotaExceededMessage: state.quotaExceededMessage,
        customStudyOptions: state.customStudyOptions,
        sessionQueueCounts: state.sessionQueueCounts,
      );
    } else {
      state = state.copyWith(waitingCardCount: _delayedQueue.length);
    }
    _scheduleNextDue();
  }

  ReviewMode _resolvePromptMode(ReviewMode selectedMode, List<Vocab> queue) {
    if (selectedMode != ReviewMode.mixed) {
      return selectedMode;
    }
    if (queue.isEmpty) {
      return ReviewMode.forward;
    }
    final cardId = queue.first.id;
    final remaining = _mixedModesRemainingByCardId[cardId];
    if (remaining == null || remaining.isEmpty) {
      _mixedModesRemainingByCardId[cardId] = _mixedSubModes();
      return ReviewMode.forward;
    }
    return remaining.first;
  }

  List<ReviewMode> _mixedSubModes() {
    return <ReviewMode>[
      ReviewMode.forward,
      ReviewMode.reverseMeaning,
      ReviewMode.reverseAudio,
    ];
  }
}

/// Strict variant: empty pair stays empty so option lists/filters can drop it.
String _sourceLanguageFromPair(String pair) =>
    sourceLanguageFromPair(pair, fallback: '');

class _PendingQueueCard {
  const _PendingQueueCard({required this.card, required this.dueAt});

  final Vocab card;
  final DateTime dueAt;
}

final reviewControllerProvider =
    NotifierProvider<ReviewController, ReviewState>(ReviewController.new);
