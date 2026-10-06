import 'dart:async';

import 'package:app_l10n/app_l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:settings_core/settings_core.dart';
import 'package:shared_models/shared_models.dart';

import '../../../core/monetization/app_state.dart';
import '../application/review_tts_service.dart';
import '../application/review_controller.dart';
import 'review_summary_screen.dart';

const Duration _kSrsCardAnimDuration = Duration(milliseconds: 340);
enum _ReviewTopAction { toggleAutoAudio, toggleMode, exitStudy }

/// Deep SRS flashcard review (Riverpod session from [reviewControllerProvider]).
class SrsReviewScreen extends ConsumerStatefulWidget {
  const SrsReviewScreen({
    super.key,
    this.reviewMode = ReviewMode.mixed,
    this.selectedVocabIds,
    this.customStudyOptions,
  });

  final ReviewMode reviewMode;

  /// When non-empty, reviews these words regardless of due date (library “study selected”).
  final Set<String>? selectedVocabIds;

  /// When null, defaults are loaded from [SettingsService.loadCustomStudyDefaults].
  final CustomStudyOptions? customStudyOptions;

  @override
  ConsumerState<SrsReviewScreen> createState() => _SrsReviewScreenState();
}

class _SrsReviewScreenState extends ConsumerState<SrsReviewScreen> {
  bool _summaryPushed = false;
  final TextEditingController _answerController = TextEditingController();
  String? _activeCardId;
  bool _hasCheckedAnswer = false;
  bool _answerMatched = false;
  String? _lastAutoplayCardId;

  /// Cached in [initState] so [dispose] never touches [WidgetRef] (Riverpod restriction).
  late final ReviewController _reviewNotifier;

  /// [IndexedStack] keeps an idle `SrsReviewScreen` mounted under [MobileShell].
  /// Only the **topmost** route should react to session-wide events (summary push,
  /// quota snackbars, autoplay); otherwise duplicate navigation/audio races occur
  /// when a pushed study session shares [reviewControllerProvider].
  bool _handlesLiveReviewUi(BuildContext context) {
    final route = ModalRoute.of(context);
    return route?.isCurrent ?? false;
  }

  @override
  void initState() {
    super.initState();
    _reviewNotifier = ref.read(reviewControllerProvider.notifier);
    Future<void>.microtask(() async {
      final settings = ref.read(settingsServiceProvider);
      final defaults = await settings.loadCustomStudyDefaults();
      if (!mounted) {
        return;
      }
      final opts = widget.customStudyOptions ?? defaults;
      await _reviewNotifier.load(
            reviewMode: widget.reviewMode,
            selectedVocabIds: widget.selectedVocabIds,
            customStudyOptions: opts,
          );
    });
  }

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  Future<void> _playCurrentCardAudio(ReviewState state) async {
    final card = state.currentCard;
    if (card == null) return;
    const rate = 1.0;
    const loopCount = 1;
    try {
      await ref
          .read(reviewTtsServiceProvider)
          .speak(
            text: card.term,
            language: sourceLanguageFromPair(card.languagePair),
            audioUrl: card.audioUrl.trim(),
            rate: rate,
            loopCount: loopCount,
          );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.reviewAudioFailed)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<ReviewState>(reviewControllerProvider, (prev, next) {
      final r = next.sessionResult;
      if (r != null && prev?.sessionResult == null) {
        if (!_handlesLiveReviewUi(context)) {
          return;
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted || !_handlesLiveReviewUi(context)) {
            return;
          }
          _summaryPushed = true;
          unawaited(
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => ReviewSummaryScreen(result: r),
              ),
            ),
          );
        });
      }
    });

    ref.listen<ReviewState>(reviewControllerProvider, (prev, next) {
      final msg = next.quotaExceededMessage;
      if (msg == null || msg.isEmpty || msg == prev?.quotaExceededMessage) {
        return;
      }
      if (!_handlesLiveReviewUi(context)) {
        return;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted || !_handlesLiveReviewUi(context)) {
          return;
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
        ref.read(reviewControllerProvider.notifier).clearQuotaExceededMessage();
      });
    });

    final state = ref.watch(reviewControllerProvider);
    final notifier = ref.read(reviewControllerProvider.notifier);
    final l10n = context.l10n;
    final autoPlayAudio = ref.watch(reviewAutoPlayAudioProvider);
    if (!autoPlayAudio) {
      _lastAutoplayCardId = null;
    }
    final currentCardId = state.currentCard?.id;
    if (_activeCardId != currentCardId) {
      _activeCardId = currentCardId;
      _answerController.clear();
      _hasCheckedAnswer = false;
      _answerMatched = false;
    }
    if (autoPlayAudio &&
        currentCardId != null &&
        currentCardId != _lastAutoplayCardId &&
        !state.loading &&
        !state.hasFinished &&
        _handlesLiveReviewUi(context)) {
      _lastAutoplayCardId = currentCardId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _handlesLiveReviewUi(context)) {
          unawaited(_playCurrentCardAudio(state));
        }
      });
    }
    final appState = ref.watch(appStateProvider);
    final isPro = appState.isPro;

    final effectiveMode = state.promptMode;
    final isReverse = effectiveMode != ReviewMode.forward;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final total = state.totalCards;
    final progress = total > 0 ? state.answeredCount / total : 0.0;

    final cramSuffix =
        !state.loading &&
            state.totalCards > 0 &&
            !state.customStudyOptions.respectScheduling;

    return Scaffold(
      appBar: AppBar(
        title: LayoutBuilder(
          builder: (context, constraints) {
            return SizedBox(
              width: constraints.maxWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text.rich(
                    TextSpan(
                      style: theme.textTheme.titleLarge,
                      children: [
                        TextSpan(text: l10n.reviewSrsTitle),
                        if (cramSuffix)
                          TextSpan(
                            children: [
                              TextSpan(
                                text: ' · ',
                                style: theme.textTheme.titleLarge,
                              ),
                              TextSpan(
                                text: l10n.reviewCramBadge,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: scheme.tertiary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (!state.loading && state.totalCards > 0)
                    Text(
                      l10n.reviewQueueCounts(
                        state.sessionQueueCounts.newCount,
                        state.sessionQueueCounts.learningCount,
                        state.sessionQueueCounts.reviewCount,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            );
          },
        ),
        actions: [
          PopupMenuButton<String?>(
            tooltip: l10n.reviewLanguageFilterTooltip,
            initialValue: state.languageFilter,
            onSelected: (value) => unawaited(notifier.setLanguageFilter(value)),
            itemBuilder: (context) => [
              PopupMenuItem<String?>(
                value: null,
                child: Text(l10n.reviewAllLanguages),
              ),
              ...state.languageOptions.map(
                (lang) => PopupMenuItem<String?>(
                  value: lang,
                  child: Text(lang.toUpperCase()),
                ),
              ),
            ],
            icon: const Icon(Icons.language),
          ),
          PopupMenuButton<_ReviewTopAction>(
            tooltip: 'More actions',
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (action) {
              switch (action) {
                case _ReviewTopAction.toggleAutoAudio:
                  unawaited(
                    ref
                        .read(reviewAutoPlayAudioProvider.notifier)
                        .setEnabled(!ref.read(reviewAutoPlayAudioProvider)),
                  );
                  break;
                case _ReviewTopAction.toggleMode:
                  if (!isPro) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.reviewMixedProOnly)),
                    );
                    return;
                  }
                  unawaited(
                    notifier.setReviewMode(
                      state.reviewMode == ReviewMode.forward
                          ? ReviewMode.mixed
                          : ReviewMode.forward,
                      selectedVocabIds: widget.selectedVocabIds,
                    ),
                  );
                  break;
                case _ReviewTopAction.exitStudy:
                  unawaited(Navigator.of(context).maybePop());
                  break;
              }
            },
            itemBuilder: (context) => [
              CheckedPopupMenuItem<_ReviewTopAction>(
                value: _ReviewTopAction.toggleAutoAudio,
                checked: autoPlayAudio,
                child: Text(l10n.reviewAutoAudio),
              ),
              PopupMenuItem<_ReviewTopAction>(
                value: _ReviewTopAction.toggleMode,
                child: Text(
                  state.reviewMode == ReviewMode.forward
                      ? (isPro ? l10n.reviewMixedEnable : l10n.reviewMixedLocked)
                      : l10n.reviewBasicMode,
                ),
              ),
              PopupMenuItem<_ReviewTopAction>(
                value: _ReviewTopAction.exitStudy,
                child: Text(l10n.reviewExitStudy),
              ),
            ],
          ),
        ],
      ),
      body: state.loading
          ? const Center(child: CircularProgressIndicator())
          : total == 0
          ? Center(
              child: Text(
                l10n.reviewNoCardsDue,
                style: theme.textTheme.titleMedium,
              ),
            )
          : state.hasFinished
          ? Center(
              child: Card(
                margin: const EdgeInsets.all(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _summaryPushed
                            ? l10n.reviewFinishing
                            : l10n.reviewCompleted,
                      ),
                      if (!_summaryPushed) ...[
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: () => Navigator.of(context).maybePop(),
                          child: Text(l10n.commonBack),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        '${state.answeredCount}/$total',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (!isPro) ...[
                        const SizedBox(height: 4),
                        Text(
                          l10n.reviewReviewsToday(
                            appState.freeDailyReviewGradesUsed,
                            appState.freeDailyReviewLimit,
                          ),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          minHeight: 6,
                          value: progress.clamp(0.0, 1.0),
                          backgroundColor: scheme.surfaceContainerHighest,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: _SessionCard(
                      state: state,
                      effectiveReviewMode: effectiveMode,
                      onCardTap: isReverse ? null : notifier.toggleFlip,
                    ),
                  ),
                ),
                if (isReverse)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: _ReverseAnswerPanel(
                      l10n: l10n,
                      controller: _answerController,
                      hasCheckedAnswer: _hasCheckedAnswer,
                      answerMatched: _answerMatched,
                      expectedAnswer: state.currentCard?.term ?? '',
                      onCheckAnswer: () {
                        final expected = state.currentCard?.term ?? '';
                        final input = _normalizeReviewInput(
                          _answerController.text,
                        );
                        final target = _normalizeReviewInput(expected);
                        setState(() {
                          _hasCheckedAnswer = true;
                          _answerMatched = input.isNotEmpty && input == target;
                        });
                      },
                    ),
                  ),
                _GradeActionsBar(
                  l10n: l10n,
                  enabled: isReverse ? _hasCheckedAnswer : state.isFlipped,
                  onGrade: notifier.answer,
                ),
              ],
            ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({
    required this.state,
    required this.effectiveReviewMode,
    required this.onCardTap,
  });

  final ReviewState state;
  final ReviewMode effectiveReviewMode;
  final VoidCallback? onCardTap;

  @override
  Widget build(BuildContext context) {
    final card = state.currentCard!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final sourceApp = card.sourceApp.trim();

    return Card(
      elevation: 3,
      shadowColor: Colors.black.withValues(alpha: 0.18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onCardTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (sourceApp.isNotEmpty)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Material(
                      color: scheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        child: Text(
                          sourceApp,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: scheme.onSecondaryContainer,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: _kSrsCardAnimDuration,
                  switchInCurve: Curves.easeInOutCubic,
                  switchOutCurve: Curves.easeInOutCubic,
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: ScaleTransition(
                        scale: Tween<double>(begin: 0.94, end: 1).animate(
                          CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeOutCubic,
                          ),
                        ),
                        child: child,
                      ),
                    );
                  },
                  child: effectiveReviewMode == ReviewMode.forward
                      ? (state.isFlipped
                            ? KeyedSubtree(
                                key: const ValueKey<String>('back'),
                                child: _CardBackFace(
                                  card: card,
                                  theme: theme,
                                  scheme: scheme,
                                ),
                              )
                            : KeyedSubtree(
                                key: const ValueKey<String>('front'),
                                child: _CardFrontFace(
                                  card: card,
                                  theme: theme,
                                  scheme: scheme,
                                ),
                              ))
                      : KeyedSubtree(
                          key: const ValueKey<String>('reverse-prompt'),
                          child: _ReversePromptFace(
                            card: card,
                            reviewMode: effectiveReviewMode,
                            theme: theme,
                            scheme: scheme,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardFrontFace extends StatelessWidget {
  const _CardFrontFace({
    required this.card,
    required this.theme,
    required this.scheme,
  });

  final Vocab card;
  final ThemeData theme;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final audio = card.audioUrl.trim();
    final phonetic = card.phonetic.trim();
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  card.term,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _InlineAudioPlayButton(
                text: card.term,
                language: sourceLanguageFromPair(card.languagePair),
                audioUrl: audio,
              ),
            ],
          ),
          if (phonetic.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              phonetic,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                color: scheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          const SizedBox(height: 28),
          const SizedBox.shrink(),
        ],
      ),
    );
  }
}

class _CardBackFace extends StatelessWidget {
  const _CardBackFace({
    required this.card,
    required this.theme,
    required this.scheme,
  });

  final Vocab card;
  final ThemeData theme;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final audio = card.audioUrl.trim();
    final phonetic = card.phonetic.trim();
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  card.term,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _InlineAudioPlayButton(
                text: card.term,
                language: sourceLanguageFromPair(card.languagePair),
                audioUrl: audio,
                tooltip: context.l10n.reviewPlayTerm,
              ),
            ],
          ),
          if (phonetic.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              phonetic,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleSmall?.copyWith(
                color: scheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          const SizedBox(height: 14),
          Text(
            context.l10n.reviewMeaning,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelLarge?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            card.definition,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              height: 1.35,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 24),
          const SizedBox.shrink(),
        ],
      ),
    );
  }
}

class _InlineAudioPlayButton extends ConsumerStatefulWidget {
  const _InlineAudioPlayButton({
    required this.text,
    required this.language,
    required this.audioUrl,
    this.tooltip,
  });

  final String text;
  final String language;
  final String audioUrl;
  final String? tooltip;

  @override
  ConsumerState<_InlineAudioPlayButton> createState() =>
      _InlineAudioPlayButtonState();
}

class _ReversePromptFace extends ConsumerWidget {
  const _ReversePromptFace({
    required this.card,
    required this.reviewMode,
    required this.theme,
    required this.scheme,
  });

  final Vocab card;
  final ReviewMode reviewMode;
  final ThemeData theme;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audio = card.audioUrl.trim();
    final l10n = context.l10n;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 24),
          Text(
            reviewMode == ReviewMode.reverseMeaning
                ? l10n.reviewMeaning
                : l10n.reviewListenType,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelLarge?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          if (reviewMode == ReviewMode.reverseMeaning)
            Text(
              card.definition,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                height: 1.35,
                fontWeight: FontWeight.w700,
              ),
            )
          else
            Column(
              children: [
                _InlineAudioPlayButton(
                  text: card.term,
                  language: sourceLanguageFromPair(card.languagePair),
                  audioUrl: audio,
                  tooltip: l10n.reviewPlayAudio,
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.reviewListenInstructions,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _ReverseAnswerPanel extends StatelessWidget {
  const _ReverseAnswerPanel({
    required this.l10n,
    required this.controller,
    required this.hasCheckedAnswer,
    required this.answerMatched,
    required this.expectedAnswer,
    required this.onCheckAnswer,
  });

  final AppLocalizations l10n;
  final TextEditingController controller;
  final bool hasCheckedAnswer;
  final bool answerMatched;
  final String expectedAnswer;
  final VoidCallback onCheckAnswer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: l10n.reviewTypeOriginalPlaceholder,
            border: const OutlineInputBorder(),
          ),
          onSubmitted: (_) => onCheckAnswer(),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton(
            onPressed: onCheckAnswer,
            child: Text(l10n.reviewCheckAnswer),
          ),
        ),
        if (hasCheckedAnswer) ...[
          const SizedBox(height: 8),
          Text(
            answerMatched ? l10n.reviewCorrect : l10n.reviewIncorrect,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: answerMatched ? Colors.green : Colors.red,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${l10n.reviewExpected} $expectedAnswer',
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ],
    );
  }
}

class _InlineAudioPlayButtonState
    extends ConsumerState<_InlineAudioPlayButton> {
  var _playing = false;

  Future<void> _onPressed() async {
    final service = ref.read(reviewTtsServiceProvider);
    if (_playing) {
      await service.stop();
      if (mounted) {
        setState(() => _playing = false);
      }
      return;
    }
    setState(() => _playing = true);
    try {
      await service.speak(
        text: widget.text,
        language: widget.language,
        audioUrl: widget.audioUrl,
        rate: 1.0,
        loopCount: 1,
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.reviewAudioFailed)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _playing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: widget.tooltip ?? context.l10n.reviewPlayAudio,
      onPressed: _onPressed,
      icon: Icon(_playing ? Icons.pause_rounded : Icons.volume_up_rounded),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _GradeActionsBar extends StatelessWidget {
  const _GradeActionsBar({
    required this.l10n,
    required this.enabled,
    required this.onGrade,
  });

  final AppLocalizations l10n;
  final bool enabled;
  final Future<void> Function(ReviewGrade grade) onGrade;

  static const _again = Color(0xFFC62828);
  static const _hard = Color(0xFFE65100);
  static const _good = Color(0xFF2E7D32);
  static const _easy = Color(0xFF1565C0);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: _GradeChip(
                  label: l10n.reviewGradeAgain,
                  color: _again,
                  enabled: enabled,
                  onPressed: () => unawaited(onGrade(ReviewGrade.again)),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _GradeChip(
                  label: l10n.reviewGradeHard,
                  color: _hard,
                  enabled: enabled,
                  onPressed: () => unawaited(onGrade(ReviewGrade.hard)),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _GradeChip(
                  label: l10n.reviewGradeGood,
                  color: _good,
                  enabled: enabled,
                  onPressed: () => unawaited(onGrade(ReviewGrade.good)),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _GradeChip(
                  label: l10n.reviewGradeEasy,
                  color: _easy,
                  enabled: enabled,
                  onPressed: () => unawaited(onGrade(ReviewGrade.easy)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GradeChip extends StatelessWidget {
  const _GradeChip({
    required this.label,
    required this.color,
    required this.enabled,
    required this.onPressed,
  });

  final String label;
  final Color color;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final onColor = _foregroundForBackground(color);
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: FilledButton(
        onPressed: enabled ? onPressed : null,
        style: FilledButton.styleFrom(
          backgroundColor: color,
          foregroundColor: onColor,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
      ),
    );
  }
}

Color _foregroundForBackground(Color background) {
  return background.computeLuminance() > 0.45 ? Colors.black : Colors.white;
}

String _normalizeReviewInput(String raw) {
  final lowered = raw.trim().toLowerCase();
  return lowered.replaceAll(RegExp(r'\s+'), ' ');
}
