import 'dart:async';

import 'package:app_l10n/app_l10n.dart';
import 'package:desktop/core/theme/desktop_text_scale.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_models/shared_models.dart';

import '../../../core/monetization/app_state.dart';
import '../../capture/application/tts_service.dart';
import '../../settings/application/settings_service.dart';
import '../application/review_controller.dart';
import 'review_summary_screen.dart';

const Duration _kSrsCardAnimDuration = Duration(milliseconds: 340);

double _reviewLayoutTf(BuildContext context) =>
    desktopOsTextLayoutFactor(context).clamp(0.85, 1.55);

String _reviewGradeChipLabel(AppLocalizations l10n, ReviewGrade g) {
  switch (g) {
    case ReviewGrade.again:
      return l10n.reviewGradeAgain;
    case ReviewGrade.hard:
      return l10n.reviewGradeHard;
    case ReviewGrade.good:
      return l10n.reviewGradeGood;
    case ReviewGrade.easy:
      return l10n.reviewGradeEasy;
  }
}

/// Deep SRS flashcard review (Riverpod session from [reviewControllerProvider]).
class SrsReviewScreen extends ConsumerStatefulWidget {
  const SrsReviewScreen({
    super.key,
    this.selectedVocabIds,
    this.reviewMode = ReviewMode.mixed,
    this.customStudyOptions,
  });

  final Set<String>? selectedVocabIds;
  final ReviewMode reviewMode;

  /// When null, defaults are loaded from [SettingsService.loadCustomStudyDefaults].
  final CustomStudyOptions? customStudyOptions;

  @override
  ConsumerState<SrsReviewScreen> createState() => _SrsReviewScreenState();
}

class _SrsReviewScreenState extends ConsumerState<SrsReviewScreen> {
  bool _summaryPushed = false;
  final TextEditingController _answerController = TextEditingController();
  final FocusNode _answerFocusNode = FocusNode();
  final FocusNode _pageFocusNode = FocusNode(debugLabel: 'review_page_focus');
  String? _activeCardId;
  bool _hasCheckedAnswer = false;
  bool _answerMatched = false;
  String? _lastAutoplayCardId;

  @override
  void initState() {
    super.initState();
    RawKeyboard.instance.addListener(_handleRawKeyEvent);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _pageFocusNode.requestFocus();
      }
    });
    Future<void>.microtask(() async {
      if (!mounted) {
        return;
      }
      final settings = ref.read(settingsServiceProvider);
      final defaults = await settings.loadCustomStudyDefaults();
      if (!mounted) {
        return;
      }
      final opts = widget.customStudyOptions ?? defaults;
      await ref.read(reviewControllerProvider.notifier).load(
            selectedVocabIds: widget.selectedVocabIds,
            reviewMode: widget.reviewMode,
            customStudyOptions: opts,
          );
    });
  }

  @override
  void dispose() {
    RawKeyboard.instance.removeListener(_handleRawKeyEvent);
    _pageFocusNode.dispose();
    _answerController.dispose();
    _answerFocusNode.dispose();
    super.dispose();
  }

  void _handleRawKeyEvent(RawKeyEvent event) {
    if (event is! RawKeyDownEvent) {
      return;
    }
    _handleReviewKey(
      key: event.logicalKey,
      controlPressed:
          HardwareKeyboard.instance.isControlPressed || event.isControlPressed,
    );
  }

  bool _handleReviewKey({
    required LogicalKeyboardKey key,
    required bool controlPressed,
  }) {
    final state = ref.read(reviewControllerProvider);
    final notifier = ref.read(reviewControllerProvider.notifier);
    if (state.loading || state.currentCard == null || state.hasFinished) {
      return false;
    }
    final isReverse = state.promptMode != ReviewMode.forward;
    final isEnter =
        key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter;

    if (controlPressed && isEnter) {
      unawaited(_playCurrentCardAudio(state));
      return true;
    }
    if (key == LogicalKeyboardKey.keyR &&
        !controlPressed &&
        !_isAnswerInputFocused()) {
      unawaited(_playCurrentCardAudio(state));
      return true;
    }
    if (isEnter) {
      if (isReverse) {
        _checkCurrentAnswer(state);
      } else {
        notifier.toggleFlip();
      }
      return true;
    }
    final grade = desktopReviewGradeFromKey(key);
    if (grade == null) return false;
    final canGrade = isReverse ? _hasCheckedAnswer : state.isFlipped;
    if (!canGrade) return false;
    unawaited(notifier.answer(grade));
    return true;
  }

  /// Avoid swallowing letter keys while the user is typing into the answer
  /// box (`reverseMeaning` / `reverseAudio` modes).
  bool _isAnswerInputFocused() => _answerFocusNode.hasFocus;

  @override
  Widget build(BuildContext context) {
    ref.listen<ReviewState>(reviewControllerProvider, (prev, next) {
      if (prev?.currentIndex != next.currentIndex) {}
    });

    ref.listen<ReviewState>(reviewControllerProvider, (prev, next) {
      final r = next.sessionResult;
      if (r != null && prev?.sessionResult == null) {
        _summaryPushed = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) {
            return;
          }
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
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) {
          return;
        }
        unawaited(
          fluent.displayInfoBar(
            context,
            builder: (ctx, close) => fluent.InfoBar(
              title: Text(msg),
              severity: fluent.InfoBarSeverity.warning,
            ),
          ),
        );
        ref.read(reviewControllerProvider.notifier).clearQuotaExceededMessage();
      });
    });

    final state = ref.watch(reviewControllerProvider);
    final notifier = ref.read(reviewControllerProvider.notifier);
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
      if (state.promptMode != ReviewMode.forward) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _answerFocusNode.requestFocus();
          }
        });
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _pageFocusNode.requestFocus();
          }
        });
      }
    }
    if (autoPlayAudio &&
        currentCardId != null &&
        currentCardId != _lastAutoplayCardId &&
        !state.loading &&
        !state.hasFinished) {
      _lastAutoplayCardId = currentCardId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
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
    final tf = _reviewLayoutTf(context);
    final l10n = context.l10n;

    final total = state.totalCards;
    final progress = total > 0 ? state.answeredCount / total : 0.0;
    return Focus(
      focusNode: _pageFocusNode,
      autofocus: true,
      child: fluent.ScaffoldPage(
        padding: EdgeInsets.zero,
        header: fluent.PageHeader(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                children: [
                  Text(
                    l10n.reviewSrsTitle,
                    style: theme.textTheme.titleLarge,
                  ),
                  if (!state.loading &&
                      state.totalCards > 0 &&
                      !state.customStudyOptions.respectScheduling)
                    Text(
                      l10n.reviewCramBadge,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.tertiary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
              if (!state.loading && state.totalCards > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    l10n.reviewQueueCounts(
                      state.sessionQueueCounts.newCount,
                      state.sessionQueueCounts.learningCount,
                      state.sessionQueueCounts.reviewCount,
                    ),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
            ],
          ),
          padding: (12 * tf).clamp(8.0, 20.0),
          commandBar: Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              fluent.ToggleSwitch(
                checked: autoPlayAudio,
                onChanged: (value) => unawaited(
                  ref
                      .read(reviewAutoPlayAudioProvider.notifier)
                      .setEnabled(value),
                ),
                content: Text(l10n.reviewAutoAudio),
              ),
              SizedBox(
                width: 170,
                child: fluent.ComboBox<String>(
                  isExpanded: true,
                  value: state.languageFilter ?? '__all__',
                  onChanged: (value) => unawaited(
                    notifier.setLanguageFilter(
                      value == null || value == '__all__' ? null : value,
                    ),
                  ),
                  items: [
                    fluent.ComboBoxItem<String>(
                      value: '__all__',
                      child: Text(l10n.reviewAllLanguages),
                    ),
                    ...state.languageOptions.map(
                      (lang) => fluent.ComboBoxItem<String>(
                        value: lang,
                        child: Text(
                          lang.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              fluent.Button(
                onPressed: () {
                  if (!isPro) {
                    unawaited(
                      fluent.displayInfoBar(
                        context,
                        builder: (ctx, close) => fluent.InfoBar(
                          title: Text(l10n.reviewMixedProOnly),
                          severity: fluent.InfoBarSeverity.info,
                        ),
                      ),
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
                },
                child: Text(
                  state.reviewMode == ReviewMode.forward
                      ? (isPro
                            ? l10n.reviewMixedEnable
                            : l10n.reviewMixedLocked)
                      : l10n.reviewBasicMode,
                ),
              ),
              fluent.Button(
                onPressed: () => Navigator.of(context).maybePop(),
                child: Text(l10n.reviewExitStudy),
              ),
            ],
          ),
        ),
        content: state.loading
            ? Center(
                child: SizedBox(
                  width: (28 * tf).clamp(22.0, 40.0),
                  height: (28 * tf).clamp(22.0, 40.0),
                  child: fluent.ProgressRing(
                    strokeWidth: (3 * tf).clamp(2.0, 5.0),
                  ),
                ),
              )
            : total == 0
            ? Center(
                child: Padding(
                  padding: EdgeInsets.all((20 * tf).clamp(12.0, 36.0)),
                  child: fluent.InfoBar(
                    title: Text(l10n.reviewNoCardsDue),
                    severity: fluent.InfoBarSeverity.info,
                  ),
                ),
              )
            : state.hasFinished
            ? Center(
                child: fluent.InfoBar(
                  title: Text(
                    _summaryPushed
                        ? l10n.reviewFinishing
                        : l10n.reviewCompleted,
                  ),
                  content: _summaryPushed
                      ? null
                      : fluent.Button(
                          onPressed: () => Navigator.of(context).maybePop(),
                          child: Text(l10n.commonBack),
                        ),
                  severity: fluent.InfoBarSeverity.success,
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      (16 * tf).clamp(10.0, 28.0),
                      (8 * tf).clamp(6.0, 16.0),
                      (16 * tf).clamp(10.0, 28.0),
                      0,
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: fluent.Button(
                        onPressed: () => _showReviewTipsDialog(),
                        child: Text(l10n.commonTips),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      (16 * tf).clamp(10.0, 28.0),
                      (8 * tf).clamp(6.0, 16.0),
                      (16 * tf).clamp(10.0, 28.0),
                      (4 * tf).clamp(2.0, 10.0),
                    ),
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
                          SizedBox(height: 4 * tf.clamp(0.9, 1.25)),
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
                        SizedBox(height: 6 * tf.clamp(0.9, 1.25)),
                        fluent.ProgressBar(
                          value: progress.clamp(0.0, 1.0) * 100,
                          strokeWidth: (4.5 * tf).clamp(2.5, 8.0),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        (16 * tf).clamp(10.0, 28.0),
                        (8 * tf).clamp(6.0, 16.0),
                        (16 * tf).clamp(10.0, 28.0),
                        (8 * tf).clamp(6.0, 16.0),
                      ),
                      child: isReverse
                          ? LayoutBuilder(
                              builder: (context, constraints) {
                                final wide = constraints.maxWidth >= 980;
                                final answerPanel = ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxWidth: (640 * tf).clamp(420.0, 900.0),
                                  ),
                                  child: _ReverseAnswerPanel(
                                    controller: _answerController,
                                    focusNode: _answerFocusNode,
                                    hasCheckedAnswer: _hasCheckedAnswer,
                                    answerMatched: _answerMatched,
                                    expectedAnswer:
                                        state.currentCard?.term ?? '',
                                    onCheckAnswer: () =>
                                        _checkCurrentAnswer(state),
                                  ),
                                );
                                if (wide) {
                                  return Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Expanded(
                                        flex: 3,
                                        child: _SessionCard(
                                          state: state,
                                          effectiveReviewMode: effectiveMode,
                                          onCardTap: null,
                                        ),
                                      ),
                                      SizedBox(
                                        width: (12 * tf).clamp(8.0, 20.0),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Center(child: answerPanel),
                                      ),
                                    ],
                                  );
                                }
                                return Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: _SessionCard(
                                        state: state,
                                        effectiveReviewMode: effectiveMode,
                                        onCardTap: null,
                                      ),
                                    ),
                                    SizedBox(
                                      height: (10 * tf).clamp(6.0, 18.0),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Center(child: answerPanel),
                                    ),
                                  ],
                                );
                              },
                            )
                          : _SessionCard(
                              state: state,
                              effectiveReviewMode: effectiveMode,
                              onCardTap: notifier.toggleFlip,
                            ),
                    ),
                  ),
                  _GradeActionsBar(
                    enabled: isReverse ? _hasCheckedAnswer : state.isFlipped,
                    hintText: isReverse
                        ? 'Enter: Check | 1-4: Grade | Ctrl+Enter: Audio | R: Replay'
                        : 'Enter: Flip | 1-4: Grade | Ctrl+Enter: Audio | R: Replay',
                    onGrade: notifier.answer,
                  ),
                ],
              ),
      ),
    );
  }

  void _checkCurrentAnswer(ReviewState state) {
    final expected = state.currentCard?.term ?? '';
    final input = _normalizeReviewInput(_answerController.text);
    final target = _normalizeReviewInput(expected);
    setState(() {
      _hasCheckedAnswer = true;
      _answerMatched = input.isNotEmpty && input == target;
    });
  }

  Future<void> _showReviewTipsDialog() {
    final l10n = context.l10n;
    return fluent.showDialog<void>(
      context: context,
      builder: (ctx) => fluent.ContentDialog(
        title: Text(l10n.reviewTipsTitle),
        content: Text(l10n.reviewTipsBody),
        actions: [
          fluent.Button(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.commonClose),
          ),
        ],
      ),
    );
  }

  Future<void> _playCurrentCardAudio(ReviewState state) async {
    final card = state.currentCard;
    if (card == null) {
      return;
    }
    const rate = 1.0;
    const loopCount = 1;
    try {
      await ref
          .read(ttsServiceProvider)
          .speak(
            text: card.term,
            language: sourceLanguageFromPair(card.languagePair),
            audioUrl: card.audioUrl.trim(),
            rate: rate,
            loopCount: loopCount,
          );
    } catch (_) {
      if (!mounted) {
        return;
      }
      unawaited(
        fluent.displayInfoBar(
          context,
          builder: (ctx, close) => fluent.InfoBar(
            title: Text(ctx.l10n.reviewAudioFailed),
            severity: fluent.InfoBarSeverity.error,
          ),
        ),
      );
    }
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
    final tf = _reviewLayoutTf(context);
    final cardPad = (16 * tf).clamp(10.0, 28.0);
    final radius = (16 * tf).clamp(12.0, 22.0);
    final sourceApp = card.sourceApp.trim();

    return fluent.Card(
      padding: EdgeInsets.all(cardPad),
      borderRadius: BorderRadius.all(Radius.circular(radius)),
      child: GestureDetector(
        onTap: onCardTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (sourceApp.isNotEmpty)
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: EdgeInsets.only(bottom: 10 * tf.clamp(0.9, 1.25)),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: scheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: (10 * tf).clamp(6.0, 16.0),
                        vertical: (4 * tf).clamp(2.0, 8.0),
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
    final tf = _reviewLayoutTf(context);
    final audio = card.audioUrl.trim();
    final phonetic = card.phonetic.trim();
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: 24 * tf.clamp(0.9, 1.25)),
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
              SizedBox(width: 10 * tf.clamp(0.9, 1.25)),
              _InlineAudioPlayButton(
                text: card.term,
                language: sourceLanguageFromPair(card.languagePair),
                audioUrl: audio,
              ),
            ],
          ),
          if (phonetic.isNotEmpty) ...[
            SizedBox(height: 10 * tf.clamp(0.9, 1.25)),
            Text(
              phonetic,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                color: scheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          SizedBox(height: 28 * tf.clamp(0.9, 1.25)),
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
    final tf = _reviewLayoutTf(context);
    final audio = card.audioUrl.trim();
    final phonetic = card.phonetic.trim();
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: 28 * tf.clamp(0.9, 1.25)),
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
              SizedBox(width: 10 * tf.clamp(0.9, 1.25)),
              _InlineAudioPlayButton(
                text: card.term,
                language: sourceLanguageFromPair(card.languagePair),
                audioUrl: audio,
                tooltip: context.l10n.reviewPlayTerm,
              ),
            ],
          ),
          if (phonetic.isNotEmpty) ...[
            SizedBox(height: 8 * tf.clamp(0.9, 1.25)),
            Text(
              phonetic,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleSmall?.copyWith(
                color: scheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          SizedBox(height: 14 * tf.clamp(0.9, 1.25)),
          Text(
            context.l10n.reviewMeaning,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelLarge?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 8 * tf.clamp(0.9, 1.25)),
          Text(
            card.definition,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              height: 1.35,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 24 * tf.clamp(0.9, 1.25)),
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
    final tf = _reviewLayoutTf(context);
    final audio = card.audioUrl.trim();
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: 24 * tf.clamp(0.9, 1.25)),
          Text(
            reviewMode == ReviewMode.reverseMeaning
                ? context.l10n.reviewMeaning
                : context.l10n.reviewListenType,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelLarge?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 10 * tf.clamp(0.9, 1.25)),
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
                  tooltip: context.l10n.reviewPlayAudio,
                ),
                SizedBox(height: 8 * tf.clamp(0.9, 1.25)),
                Text(
                  context.l10n.reviewListenInstructions,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          SizedBox(height: 16 * tf.clamp(0.9, 1.25)),
        ],
      ),
    );
  }
}

class _ReverseAnswerPanel extends StatelessWidget {
  const _ReverseAnswerPanel({
    required this.controller,
    required this.focusNode,
    required this.hasCheckedAnswer,
    required this.answerMatched,
    required this.expectedAnswer,
    required this.onCheckAnswer,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool hasCheckedAnswer;
  final bool answerMatched;
  final String expectedAnswer;
  final VoidCallback onCheckAnswer;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final tf = _reviewLayoutTf(context);
    final baseFont = (15 * tf).clamp(14.0, 20.0);
    final labelFont = (16 * tf).clamp(15.0, 22.0);
    final currentInput = controller.text;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        fluent.TextBox(
          controller: controller,
          focusNode: focusNode,
          autofocus: true,
          placeholder: l10n.reviewTypeOriginalPlaceholder,
          onSubmitted: (_) => onCheckAnswer(),
          style: TextStyle(fontSize: baseFont, fontWeight: FontWeight.w500),
        ),
        SizedBox(height: 8 * tf.clamp(0.9, 1.25)),
        Align(
          alignment: Alignment.centerLeft,
          child: fluent.FilledButton(
            onPressed: onCheckAnswer,
            child: Text(
              l10n.reviewCheckAnswer,
              style: TextStyle(fontSize: baseFont, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        if (hasCheckedAnswer) ...[
          SizedBox(height: 8 * tf.clamp(0.9, 1.25)),
          Text(
            answerMatched ? l10n.reviewCorrect : l10n.reviewIncorrect,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: labelFont,
              fontWeight: FontWeight.w800,
              color: answerMatched ? Colors.green : Colors.red,
            ),
          ),
          SizedBox(height: 4 * tf.clamp(0.9, 1.25)),
          _AnswerDiffView(
            userInput: currentInput,
            expected: expectedAnswer,
            style: theme.textTheme.bodyMedium,
            emptyAnswerLabel: l10n.reviewAnswerEmptyMarker,
          ),
        ],
      ],
    );
  }
}

class _AnswerDiffView extends StatelessWidget {
  const _AnswerDiffView({
    required this.userInput,
    required this.expected,
    this.style,
    required this.emptyAnswerLabel,
  });

  final String userInput;
  final String expected;
  final TextStyle? style;
  final String emptyAnswerLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tf = _reviewLayoutTf(context);
    final baseStyle =
        style?.copyWith(fontSize: (15 * tf).clamp(14.0, 20.0)) ??
        TextStyle(fontSize: (15 * tf).clamp(14.0, 20.0));
    final inputSpans = _buildDiffSpans(
      source: userInput,
      reference: expected,
      matchedColor: Colors.green.shade400,
      mismatchColor: Colors.red.shade400,
      emptyMarker: emptyAnswerLabel,
    );
    final expectedSpans = _buildDiffSpans(
      source: expected,
      reference: userInput,
      matchedColor: Colors.green.shade400,
      mismatchColor: Colors.red.shade400,
      emptyMarker: emptyAnswerLabel,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.reviewYourAnswer,
          style: baseStyle.copyWith(fontWeight: FontWeight.w600),
        ),
        RichText(
          text: TextSpan(style: baseStyle, children: inputSpans),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.reviewExpected,
          style: baseStyle.copyWith(fontWeight: FontWeight.w600),
        ),
        RichText(
          text: TextSpan(style: baseStyle, children: expectedSpans),
        ),
      ],
    );
  }
}

List<TextSpan> _buildDiffSpans({
  required String source,
  required String reference,
  required Color matchedColor,
  required Color mismatchColor,
  required String emptyMarker,
}) {
  if (source.isEmpty) {
    return <TextSpan>[
      TextSpan(
        text: emptyMarker,
        style: TextStyle(color: mismatchColor),
      ),
    ];
  }
  final src = source.split('');
  final ref = reference.split('');
  final matchedMask = _lcsMatchedMask(src, ref);
  final spans = <TextSpan>[];
  for (var i = 0; i < src.length; i += 1) {
    final char = src[i];
    final matches = matchedMask[i];
    spans.add(
      TextSpan(
        text: char,
        style: TextStyle(
          color: matches ? matchedColor : mismatchColor,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
  return spans;
}

List<bool> _lcsMatchedMask(List<String> source, List<String> reference) {
  final n = source.length;
  final m = reference.length;
  final dp = List<List<int>>.generate(n + 1, (_) => List<int>.filled(m + 1, 0));
  for (var i = 1; i <= n; i += 1) {
    for (var j = 1; j <= m; j += 1) {
      if (source[i - 1].toLowerCase() == reference[j - 1].toLowerCase()) {
        dp[i][j] = dp[i - 1][j - 1] + 1;
      } else {
        dp[i][j] = dp[i - 1][j] >= dp[i][j - 1] ? dp[i - 1][j] : dp[i][j - 1];
      }
    }
  }
  final matched = List<bool>.filled(n, false);
  var i = n;
  var j = m;
  while (i > 0 && j > 0) {
    if (source[i - 1].toLowerCase() == reference[j - 1].toLowerCase()) {
      matched[i - 1] = true;
      i -= 1;
      j -= 1;
      continue;
    }
    if (dp[i - 1][j] >= dp[i][j - 1]) {
      i -= 1;
    } else {
      j -= 1;
    }
  }
  return matched;
}

class _InlineAudioPlayButtonState
    extends ConsumerState<_InlineAudioPlayButton> {
  var _playing = false;

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
            rate: 1.0,
            loopCount: 1,
          );
    } catch (_) {
      if (mounted) {
        unawaited(
          fluent.displayInfoBar(
            context,
            builder: (ctx, close) => fluent.InfoBar(
              title: Text(ctx.l10n.reviewAudioFailed),
              severity: fluent.InfoBarSeverity.error,
            ),
          ),
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
    final tf = _reviewLayoutTf(context);
    final iconS = (18 * tf).clamp(16.0, 26.0);
    final button = fluent.IconButton(
      onPressed: _onPressed,
      icon: Icon(
        _playing
            ? FluentIcons.pause_24_regular
            : FluentIcons.speaker_2_24_regular,
        size: iconS,
      ),
    );
    final tooltip = widget.tooltip;
    if (tooltip == null || tooltip.isEmpty) {
      return button;
    }
    return fluent.Tooltip(message: tooltip, child: button);
  }
}

class _GradeActionsBar extends StatelessWidget {
  const _GradeActionsBar({
    required this.enabled,
    required this.onGrade,
    required this.hintText,
  });

  final bool enabled;
  final Future<void> Function(ReviewGrade grade) onGrade;
  final String hintText;

  static const _again = Color(0xFFC62828);
  static const _hard = Color(0xFFE65100);
  static const _good = Color(0xFF2E7D32);
  static const _easy = Color(0xFF1565C0);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tf = _reviewLayoutTf(context);
    final side = (12 * tf).clamp(8.0, 20.0);
    final bottom = (12 * tf).clamp(8.0, 22.0);
    final gap = (6 * tf).clamp(4.0, 12.0);
    return SafeArea(
      minimum: EdgeInsets.fromLTRB(side, 0, side, bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: 6 * tf.clamp(0.9, 1.25)),
            child: Text(
              hintText,
              style: TextStyle(
                fontSize: (12 * tf).clamp(11.0, 15.0),
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Row(
            children: [
              Expanded(
                child: _GradeChip(
                  label: _reviewGradeChipLabel(l10n, ReviewGrade.again),
                  color: _again,
                  enabled: enabled,
                  onPressed: () => unawaited(onGrade(ReviewGrade.again)),
                ),
              ),
              SizedBox(width: gap),
              Expanded(
                child: _GradeChip(
                  label: _reviewGradeChipLabel(l10n, ReviewGrade.hard),
                  color: _hard,
                  enabled: enabled,
                  onPressed: () => unawaited(onGrade(ReviewGrade.hard)),
                ),
              ),
              SizedBox(width: gap),
              Expanded(
                child: _GradeChip(
                  label: _reviewGradeChipLabel(l10n, ReviewGrade.good),
                  color: _good,
                  enabled: enabled,
                  onPressed: () => unawaited(onGrade(ReviewGrade.good)),
                ),
              ),
              SizedBox(width: gap),
              Expanded(
                child: _GradeChip(
                  label: _reviewGradeChipLabel(l10n, ReviewGrade.easy),
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
    final vPad = (12 * _reviewLayoutTf(context)).clamp(8.0, 20.0);
    final onColor = _foregroundForBackground(color);
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: fluent.FilledButton(
        onPressed: enabled ? onPressed : null,
        style: fluent.ButtonStyle(
          backgroundColor: fluent.WidgetStateProperty.resolveWith((states) {
            if (states.contains(fluent.WidgetState.disabled)) {
              return color.withValues(alpha: 0.45);
            }
            return color;
          }),
          foregroundColor: fluent.WidgetStateProperty.all(onColor),
          padding: fluent.WidgetStateProperty.all(
            EdgeInsets.symmetric(vertical: vPad),
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

ReviewGrade? desktopReviewGradeFromKey(LogicalKeyboardKey key) {
  switch (key) {
    case LogicalKeyboardKey.digit1:
    case LogicalKeyboardKey.numpad1:
      return ReviewGrade.again;
    case LogicalKeyboardKey.digit2:
    case LogicalKeyboardKey.numpad2:
      return ReviewGrade.hard;
    case LogicalKeyboardKey.digit3:
    case LogicalKeyboardKey.numpad3:
      return ReviewGrade.good;
    case LogicalKeyboardKey.digit4:
    case LogicalKeyboardKey.numpad4:
      return ReviewGrade.easy;
    default:
      return null;
  }
}
