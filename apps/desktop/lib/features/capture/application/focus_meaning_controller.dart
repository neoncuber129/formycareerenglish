import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/focused_span.dart';
import 'capture_controller.dart';

class FocusMeaningState {
  const FocusMeaningState({
    this.focusedText = '',
    this.translatedText = '',
    this.phonetic = '',
    this.pronunciation = '',
    this.audioUrl = '',
    this.languagePair = '',
    this.sourceLanguage = '',
    this.targetLanguage = '',
    this.isLoading = false,
    this.focusStart = -1,
    this.focusEnd = -1,
    this.partOfSpeech = '',
    this.microExplanation = '',
    this.exampleSentence = '',
    this.translateDailyQuotaExceeded = false,
  });

  final String focusedText;
  final String translatedText;
  final String phonetic;
  final String pronunciation;
  final String audioUrl;
  final String languagePair;
  final String sourceLanguage;
  final String targetLanguage;
  final bool isLoading;

  /// Character offsets into [CaptureState.sourceText] for context highlight.
  final int focusStart;
  final int focusEnd;
  final String partOfSpeech;
  final String microExplanation;
  final String exampleSentence;

  /// True when Free tier hit daily translation backend call limit.
  final bool translateDailyQuotaExceeded;

  bool get canSave =>
      focusedText.trim().isNotEmpty &&
      translatedText.trim().isNotEmpty &&
      !isLoading;

  FocusMeaningState copyWith({
    String? focusedText,
    String? translatedText,
    String? phonetic,
    String? pronunciation,
    String? audioUrl,
    String? languagePair,
    String? sourceLanguage,
    String? targetLanguage,
    bool? isLoading,
    int? focusStart,
    int? focusEnd,
    String? partOfSpeech,
    String? microExplanation,
    String? exampleSentence,
    bool? translateDailyQuotaExceeded,
  }) {
    final nextPhonetic = phonetic ?? this.phonetic;
    final nextPronunciation = pronunciation ?? phonetic ?? this.pronunciation;
    return FocusMeaningState(
      focusedText: focusedText ?? this.focusedText,
      translatedText: translatedText ?? this.translatedText,
      phonetic: nextPhonetic,
      pronunciation: nextPronunciation,
      audioUrl: audioUrl ?? this.audioUrl,
      languagePair: languagePair ?? this.languagePair,
      sourceLanguage: sourceLanguage ?? this.sourceLanguage,
      targetLanguage: targetLanguage ?? this.targetLanguage,
      isLoading: isLoading ?? this.isLoading,
      focusStart: focusStart ?? this.focusStart,
      focusEnd: focusEnd ?? this.focusEnd,
      partOfSpeech: partOfSpeech ?? this.partOfSpeech,
      microExplanation: microExplanation ?? this.microExplanation,
      exampleSentence: exampleSentence ?? this.exampleSentence,
      translateDailyQuotaExceeded:
          translateDailyQuotaExceeded ?? this.translateDailyQuotaExceeded,
    );
  }
}

class FocusMeaningController extends Notifier<FocusMeaningState> {
  int _serial = 0;

  @override
  FocusMeaningState build() => const FocusMeaningState();

  void reset() {
    _serial++;
    state = const FocusMeaningState();
  }

  Future<void> resolveSpan(FocusedSpan span, String fullPassage) async {
    final trimmed = span.trimmed;
    if (trimmed.isEmpty) {
      _serial++;
      state = const FocusMeaningState();
      return;
    }
    final pl = fullPassage.length;
    final start = span.start < 0 ? 0 : span.start.clamp(0, pl);
    final end = span.end < 0 ? pl : span.end.clamp(0, pl);
    final id = ++_serial;
    state = state.copyWith(
      focusedText: trimmed,
      focusStart: start,
      focusEnd: end,
      isLoading: true,
      translatedText: '',
      phonetic: '',
      pronunciation: '',
      audioUrl: '',
      partOfSpeech: '',
      microExplanation: '',
      exampleSentence: '',
      translateDailyQuotaExceeded: false,
    );
    final fragment = await ref
        .read(captureControllerProvider.notifier)
        .translateFragment(trimmed);
    if (id != _serial) {
      return;
    }
    if (!ref.mounted) {
      return;
    }
    state = state.copyWith(
      isLoading: false,
      translatedText: fragment.translatedText,
      phonetic: fragment.phonetic,
      pronunciation: fragment.pronunciation,
      audioUrl: fragment.audioUrl,
      languagePair: fragment.languagePair,
      sourceLanguage: fragment.sourceLanguage,
      targetLanguage: fragment.targetLanguage,
      partOfSpeech: fragment.partOfSpeech,
      microExplanation: fragment.microExplanation,
      exampleSentence: fragment.exampleSentence,
      translateDailyQuotaExceeded: fragment.translateDailyQuotaExceeded,
    );
  }

  /// Resolves meaning for default focus and returns a [TextSelection] for the
  /// interactive source field.
  Future<TextSelection?> bootstrap(String passage) async {
    if (passage.isEmpty) {
      reset();
      return null;
    }
    final selection = TextSelection(
      baseOffset: 0,
      extentOffset: passage.length,
    );
    await resolveSpan(
      FocusedSpan(text: passage, start: selection.start, end: selection.end),
      passage,
    );
    // Keep default meaning as whole-line while avoiding auto highlight on open.
    return null;
  }
}

final focusMeaningProvider =
    NotifierProvider<FocusMeaningController, FocusMeaningState>(
      FocusMeaningController.new,
    );
