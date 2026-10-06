import 'package:app_l10n/app_l10n.dart';
import 'package:desktop/core/monetization/app_state.dart';
import 'package:desktop/core/theme/desktop_text_scale.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/capture_controller.dart';
import '../application/focus_meaning_controller.dart';
import '../application/tts_service.dart';

/// Meaning + dictionary gloss; only this subtree rebuilds when focus changes.
class MeaningPanel extends ConsumerWidget {
  const MeaningPanel({
    this.selectionAction,
    this.editableMeaningController,
    this.onMeaningChanged,
    super.key,
  });

  final Widget? selectionAction;
  final TextEditingController? editableMeaningController;
  final VoidCallback? onMeaningChanged;

  static bool isPhrase(String t) => RegExp(r'\s').hasMatch(t.trim());

  /// `WORD (POS)` or truncated phrase + phrase marker from [l10n].
  static String wordOrPhraseLabel(FocusMeaningState f, AppLocalizations l10n) {
    final raw = f.focusedText.trim();
    if (raw.isEmpty) {
      return '';
    }
    if (isPhrase(f.focusedText)) {
      const max = 52;
      final head = raw.length > max ? '${raw.substring(0, max - 1)}…' : raw;
      return '$head ${l10n.meaningPhraseMarker}';
    }
    final pos = f.partOfSpeech.trim();
    return pos.isEmpty ? raw : '$raw ($pos)';
  }

  /// Text shown for the main meaning line (focus translation, or capture-level
  /// translation when focus spans the whole passage — same rules as layout).
  /// True when [translation] is the same token as the focused word (API echo
  /// or fallback to source) — not a real target-language gloss.
  static bool isEchoTranslation(String translation, String focusedText) {
    final a = translation.trim().toLowerCase();
    final b = focusedText.trim().toLowerCase();
    return a.isNotEmpty && b.isNotEmpty && a == b;
  }

  static String effectiveTranslatedMeaning({
    required FocusMeaningState focus,
    required String sourceText,
    required String captureTranslatedText,
  }) {
    final ft = focus.translatedText.trim();
    if (ft.isNotEmpty) {
      return focus.translatedText;
    }
    final passageTrimmed = sourceText.trim();
    final focusTrimmed = focus.focusedText.trim();
    final coversFullPassage =
        sourceText.isNotEmpty &&
        focus.focusStart == 0 &&
        focus.focusEnd == sourceText.length &&
        focusTrimmed.isNotEmpty &&
        focusTrimmed == passageTrimmed;
    if (coversFullPassage) {
      final ct = captureTranslatedText.trim();
      if (ct.isNotEmpty) {
        return captureTranslatedText.trim();
      }
    }
    return '';
  }

  static String _ipaSlashed(String raw) {
    final t = raw.trim();
    if (t.isEmpty) {
      return '';
    }
    if (t.startsWith('/') && t.endsWith('/')) {
      return t;
    }
    return '/$t/';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final focus = ref.watch(focusMeaningProvider);
    final sourceText = ref.watch(
      captureControllerProvider.select((s) => s.sourceText),
    );
    final captureTranslated = ref.watch(
      captureControllerProvider.select((s) => s.translatedText),
    );
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;
    final hasSpecificSelection =
        sourceText.isNotEmpty &&
        focus.focusStart >= 0 &&
        focus.focusEnd <= sourceText.length &&
        focus.focusStart < focus.focusEnd &&
        (focus.focusEnd - focus.focusStart) < sourceText.length;
    final wordLine = hasSpecificSelection ? wordOrPhraseLabel(focus, l10n) : '';
    final ipa = _ipaSlashed(focus.pronunciation);
    final effectiveMeaning = effectiveTranslatedMeaning(
      focus: focus,
      sourceText: sourceText,
      captureTranslatedText: captureTranslated,
    );
    final micro = focus.microExplanation.trim();
    final isTranslating = focus.isLoading;
    final translateDailyLimit = ref.watch(
      appStateProvider.select((s) => s.freeDailyTranslateCallLimit),
    );
    final translateQuotaBlocked =
        !isTranslating && focus.translateDailyQuotaExceeded;
    final showPlaceholder =
        !translateQuotaBlocked &&
        !focus.isLoading &&
        effectiveMeaning.trim().isEmpty;
    final useDictAsPrimary =
        !showPlaceholder &&
        isEchoTranslation(effectiveMeaning, focus.focusedText) &&
        micro.isNotEmpty;
    final primaryBody = translateQuotaBlocked
        ? l10n.captureDailyTranslateLimitReached(translateDailyLimit)
        : isTranslating
        ? l10n.meaningTranslating
        : showPlaceholder
        ? l10n.meaningNoTranslationYet
        : useDictAsPrimary
        ? micro
        : effectiveMeaning;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (focus.isLoading) ...[
          LinearProgressIndicator(
            minHeight: (3 * capturePopupLayoutFactor(context)).clamp(2.0, 6.0),
            borderRadius: BorderRadius.circular(2),
          ),
          SizedBox(
            height: 8 * capturePopupLayoutFactor(context).clamp(0.9, 1.35),
          ),
        ],
        if (wordLine.isNotEmpty) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  wordLine,
                  style: tt.titleSmall?.copyWith(
                    letterSpacing: 0.2,
                    color: cs.onSurface,
                  ),
                ),
              ),
              if (!focus.isLoading && focus.focusedText.trim().isNotEmpty) ...[
                const SizedBox(width: 4),
                MeaningPlayButton(
                  text: focus.focusedText.trim(),
                  language: focus.sourceLanguage.trim().isEmpty
                      ? 'en'
                      : focus.sourceLanguage.trim(),
                  audioUrl: focus.audioUrl.trim().isEmpty
                      ? null
                      : focus.audioUrl,
                  tooltip: l10n.meaningPlayPronunciation,
                  pauseTooltip: l10n.meaningPause,
                ),
              ],
              if (ipa.isNotEmpty) ...[
                const SizedBox(width: 8),
                Text(
                  ipa,
                  style: tt.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
        ],
        if (useDictAsPrimary) ...[
          Text(
            l10n.meaningDictHeading,
            style: tt.labelSmall?.copyWith(
              color: cs.onSurfaceVariant,
              letterSpacing: 0.15,
            ),
          ),
          SizedBox(
            height: 4 * capturePopupLayoutFactor(context).clamp(0.9, 1.2),
          ),
        ],
        if (editableMeaningController != null)
          TextField(
            controller: editableMeaningController,
            minLines: 2,
            maxLines: 6,
            onChanged: (_) => onMeaningChanged?.call(),
            decoration: const InputDecoration(
              isDense: true,
              labelText: 'Meaning',
              hintText: 'Edit translation',
            ),
          )
        else
          Text(
            primaryBody,
            textAlign: TextAlign.justify,
            style: (tt.bodyLarge ?? tt.bodyMedium ?? const TextStyle())
                .copyWith(
                  fontWeight: translateQuotaBlocked
                      ? FontWeight.w600
                      : showPlaceholder || isTranslating
                      ? FontWeight.w400
                      : FontWeight.w500,
                  height: 1.45,
                  color: translateQuotaBlocked
                      ? cs.error
                      : showPlaceholder || isTranslating
                      ? cs.onSurfaceVariant
                      : cs.onSurface,
                ),
          ),
        if (isTranslating) ...[
          const SizedBox(height: 6),
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: cs.primary),
          ),
        ],
        if (micro.isNotEmpty && !useDictAsPrimary) ...[
          const SizedBox(height: 8),
          Text(
            micro,
            textAlign: TextAlign.justify,
            style: tt.bodySmall?.copyWith(
              height: 1.3,
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
        if (focus.exampleSentence.trim().isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            '“${focus.exampleSentence.trim()}”',
            textAlign: TextAlign.justify,
            style: tt.bodySmall?.copyWith(
              fontStyle: FontStyle.italic,
              height: 1.3,
              color: cs.onSurface,
            ),
          ),
        ],
        if (focus.languagePair.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            focus.languagePair,
            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
        ],
        if (selectionAction != null) ...[
          const SizedBox(height: 10),
          Align(alignment: Alignment.centerRight, child: selectionAction),
        ],
      ],
    );
  }
}

class MeaningPlayButton extends ConsumerStatefulWidget {
  const MeaningPlayButton({
    required this.text,
    required this.language,
    this.audioUrl,
    this.tooltip,
    this.pauseTooltip,
    super.key,
  });

  final String text;
  final String language;
  final String? audioUrl;
  final String? tooltip;
  final String? pauseTooltip;

  @override
  ConsumerState<MeaningPlayButton> createState() => _MeaningPlayButtonState();
}

class _MeaningPlayButtonState extends ConsumerState<MeaningPlayButton> {
  bool _playing = false;

  @override
  Widget build(BuildContext context) {
    final noSource = widget.text.trim().isEmpty;
    final iconSize = (18 * capturePopupLayoutFactor(context)).clamp(16.0, 32.0);
    final pause = widget.pauseTooltip;
    final play = widget.tooltip;
    final tip = _playing ? pause : play;
    Widget button = IconButton(
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: BoxConstraints.tightFor(
        width: iconSize + 8,
        height: iconSize + 8,
      ),
      onPressed: (noSource && !_playing) ? null : _onPressed,
      icon: Icon(
        _playing ? Icons.pause_rounded : Icons.volume_up_rounded,
        size: iconSize,
      ),
    );
    if (tip != null && tip.isNotEmpty) {
      button = Tooltip(message: tip, child: button);
    }
    return button;
  }

  Future<void> _onPressed() async {
    if (_playing) {
      await ref.read(ttsServiceProvider).stop();
      if (mounted) {
        setState(() => _playing = false);
      }
      return;
    }
    setState(() => _playing = true);
    try {
      await ref
          .read(ttsServiceProvider)
          .speak(
            text: widget.text,
            language: widget.language,
            audioUrl: widget.audioUrl,
          );
    } finally {
      if (mounted) {
        setState(() => _playing = false);
      }
    }
  }
}
