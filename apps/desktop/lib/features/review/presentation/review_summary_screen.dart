import 'dart:async' show unawaited;
import 'dart:math' as math show min, pi;

import 'package:app_l10n/app_l10n.dart';
import 'package:confetti/confetti.dart';
import 'package:desktop/core/theme/desktop_text_scale.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_models/shared_models.dart';

import '../application/review_controller.dart';

double _summaryLayoutTf(BuildContext context) =>
    desktopOsTextLayoutFactor(context).clamp(0.85, 1.55);

/// Windows 11 accent blue.
const Color _kFluentBlueAccent = Color(0xFF0078D4);

String formatStudyDuration(AppLocalizations l10n, Duration d) {
  final totalSeconds = d.inSeconds;
  if (totalSeconds <= 0) {
    return l10n.reviewDurSeconds(0);
  }
  if (totalSeconds < 60) {
    return l10n.reviewDurSeconds(totalSeconds);
  }
  final minutes = d.inMinutes;
  final seconds = totalSeconds % 60;
  if (d.inHours < 1) {
    return seconds > 0
        ? l10n.reviewDurMinutesSeconds(minutes, seconds)
        : l10n.reviewDurMinutes(minutes);
  }
  final hours = d.inHours;
  final mins = minutes % 60;
  if (mins == 0) {
    return l10n.reviewDurHours(hours);
  }
  return l10n.reviewDurHoursMinutes(hours, mins);
}

String localizedReviewGrade(AppLocalizations l10n, ReviewGrade g) {
  switch (g) {
    case ReviewGrade.again:
      return l10n.reviewGradeNameAgain;
    case ReviewGrade.hard:
      return l10n.reviewGradeNameHard;
    case ReviewGrade.good:
      return l10n.reviewGradeNameGood;
    case ReviewGrade.easy:
      return l10n.reviewGradeNameEasy;
  }
}

/// Summary after an SRS session (Fluent / Win11–inspired layout).
class ReviewSummaryScreen extends ConsumerStatefulWidget {
  const ReviewSummaryScreen({required this.result, super.key});

  final ReviewSessionResult result;

  @override
  ConsumerState<ReviewSummaryScreen> createState() =>
      _ReviewSummaryScreenState();
}

enum _CloudSyncPhase { syncing, success, error }

class _ReviewSummaryScreenState extends ConsumerState<ReviewSummaryScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _iconScaleController;
  late final Animation<double> _iconScale;
  late final ConfettiController _confettiLeft;
  late final ConfettiController _confettiRight;

  /// Cloud push runs in [ReviewController.answer] before navigation; UI only
  /// reflects the completed outcome.
  final _CloudSyncPhase _cloudSyncPhase = _CloudSyncPhase.success;

  static const _headlineFontFamily = 'Segoe UI Variable';
  static const _headlineFontFallback = <String>[
    'Segoe UI',
    'Roboto',
    'sans-serif',
  ];

  static const _confettiColors = <Color>[
    _kFluentBlueAccent,
    Color(0xFF107C10),
    Color(0xFF8764B8),
    Color(0xFFE9830F),
    Color(0xFF00A2AD),
  ];

  @override
  void initState() {
    super.initState();
    _iconScaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 720),
    );
    _iconScale = CurvedAnimation(
      parent: _iconScaleController,
      curve: Curves.easeOutCubic,
    );
    _iconScaleController.forward();

    _confettiLeft = ConfettiController(duration: const Duration(seconds: 3));
    _confettiRight = ConfettiController(duration: const Duration(seconds: 3));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _confettiLeft.play();
      _confettiRight.play();
    });
  }

  @override
  void dispose() {
    _confettiLeft.dispose();
    _confettiRight.dispose();
    _iconScaleController.dispose();
    super.dispose();
  }

  void _goToDashboard(BuildContext context) {
    ref.read(reviewControllerProvider.notifier).resetSession();
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _showReviewedWordsSheet(BuildContext context) {
    final history = ref.read(reviewControllerProvider).sessionHistory;
    unawaited(
      fluent.showDialog<void>(
        context: context,
        barrierDismissible: true,
        builder: (ctx) {
          final l10n = ctx.l10n;
          final dtf = _summaryLayoutTf(ctx);
          final dlgW = (440 * dtf).clamp(320.0, 560.0);
          final dlgH = (520 * dtf).clamp(380.0, 680.0);
          final listH = (360 * dtf).clamp(240.0, 480.0);
          return fluent.ContentDialog(
            constraints: BoxConstraints(maxWidth: dlgW, maxHeight: dlgH),
            title: Text(l10n.reviewSummaryWordsTitle(history.length)),
            content: SizedBox(
              width: double.maxFinite,
              height: listH,
              child: ListView(
                padding: EdgeInsets.only(top: 4 * dtf.clamp(0.9, 1.2)),
                children: [
                  for (final e in history)
                    fluent.ListTile(
                      title: Text(e.vocabAfterReview.sourceText),
                      subtitle: Text(localizedReviewGrade(l10n, e.grade)),
                    ),
                ],
              ),
            ),
            actions: [
              fluent.Button(
                child: Text(l10n.reviewSummaryClose),
                onPressed: () => Navigator.pop(ctx),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final tf = _summaryLayoutTf(context);
    final scrollPadL = (28 * tf).clamp(16.0, 44.0);
    final scrollPadT = (16 * tf).clamp(10.0, 28.0);
    final scrollPadB = (56 * tf).clamp(32.0, 80.0);
    final bodyMaxW = ((600 * math.min(tf, 1.08)).clamp(
      420.0,
      720.0,
    )).toDouble();
    final footerH = (10 * tf).clamp(6.0, 18.0);
    final footerSide = (24 * tf).clamp(14.0, 36.0);

    final reviewed = widget.result.totalReviewed;
    final well = widget.result.masteredCount;
    final elapsed = widget.result.duration;

    final micaBase = isDark ? const Color(0xFF1C1C1C) : const Color(0xFFF3F3F3);
    final micaLayer = isDark
        ? const Color(0xFF252526)
        : const Color(0xFFFAFAFA);

    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [micaBase, micaLayer],
            ),
          ),
        ),
        Positioned.fill(
          child: CustomPaint(
            painter: _MicaNoisePainter(
              color: scheme.onSurface.withValues(alpha: isDark ? 0.04 : 0.06),
            ),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final canvasSize = MediaQuery.sizeOf(context);
                final midY = constraints.maxHeight / 2 - 4;
                return Stack(
                  clipBehavior: Clip.none,
                  fit: StackFit.expand,
                  children: [
                    Positioned(
                      left: 0,
                      top: midY.clamp(0, double.infinity),
                      width: 8,
                      height: 8,
                      child: ConfettiWidget(
                        confettiController: _confettiLeft,
                        canvas: canvasSize,
                        blastDirection: 0,
                        emissionFrequency: 0.08,
                        numberOfParticles: 22,
                        maxBlastForce: 38,
                        minBlastForce: 14,
                        gravity: 0.14,
                        colors: _confettiColors,
                        pauseEmissionOnLowFrameRate: false,
                      ),
                    ),
                    Positioned(
                      right: 0,
                      top: midY.clamp(0, double.infinity),
                      width: 8,
                      height: 8,
                      child: ConfettiWidget(
                        confettiController: _confettiRight,
                        canvas: canvasSize,
                        blastDirection: math.pi,
                        emissionFrequency: 0.08,
                        numberOfParticles: 22,
                        maxBlastForce: 38,
                        minBlastForce: 14,
                        gravity: 0.14,
                        colors: _confettiColors,
                        pauseEmissionOnLowFrameRate: false,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
        SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              fluent.PageHeader(
                title: Text(l10n.reviewSummaryTitle),
                padding: (12 * tf).clamp(8.0, 20.0),
              ),
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Positioned.fill(
                      child: CallbackShortcuts(
                        bindings: <ShortcutActivator, VoidCallback>{
                          const SingleActivator(LogicalKeyboardKey.enter): () =>
                              _goToDashboard(context),
                          const SingleActivator(LogicalKeyboardKey.space): () =>
                              _goToDashboard(context),
                        },
                        child: Focus(
                          autofocus: true,
                          child: Center(
                            child: SingleChildScrollView(
                              padding: EdgeInsets.fromLTRB(
                                scrollPadL,
                                scrollPadT,
                                scrollPadL,
                                scrollPadB,
                              ),
                              child: ConstrainedBox(
                                constraints: BoxConstraints(maxWidth: bodyMaxW),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    SizedBox(height: 8 * tf.clamp(0.9, 1.25)),
                                    _buildCongratulationSection(
                                      context,
                                      theme,
                                      scheme,
                                      tf,
                                    ),
                                    SizedBox(height: 48 * tf.clamp(0.9, 1.2)),
                                    _buildBentoGrid(
                                      context,
                                      theme,
                                      scheme,
                                      tf,
                                      l10n,
                                      reviewed: reviewed,
                                      wellRemembered: well,
                                      elapsed: elapsed,
                                    ),
                                    SizedBox(height: 48 * tf.clamp(0.9, 1.2)),
                                    _buildActionsSection(
                                      context,
                                      theme,
                                      scheme,
                                      tf,
                                      l10n,
                                    ),
                                    SizedBox(height: 24 * tf.clamp(0.9, 1.25)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: footerSide,
                      right: footerSide,
                      bottom: footerH,
                      child: _CloudSyncFooter(
                        phase: _cloudSyncPhase,
                        scheme: scheme,
                        theme: theme,
                        l10n: l10n,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCongratulationSection(
    BuildContext context,
    ThemeData theme,
    ColorScheme scheme,
    double tf,
  ) {
    final l10n = context.l10n;
    final iconSize = (80 * tf).clamp(56.0, 108.0);
    return Column(
      children: [
        ScaleTransition(
          scale: _iconScale,
          child: Icon(
            Icons.check_circle_rounded,
            size: iconSize,
            color: _kFluentBlueAccent,
          ),
        ),
        SizedBox(height: 28 * tf.clamp(0.9, 1.2)),
        Text(
          l10n.reviewSummaryGreatJob(l10n.reviewSummaryYou),
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontFamily: _headlineFontFamily,
            fontFamilyFallback: _headlineFontFallback,
            fontWeight: FontWeight.w700,
            height: 1.2,
            letterSpacing: -0.5,
            color: scheme.onSurface,
          ),
        ),
        SizedBox(height: 16 * tf.clamp(0.9, 1.25)),
        Text(
          l10n.reviewSummaryEncourage,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium?.copyWith(
            color: scheme.onSurfaceVariant,
            height: 1.45,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildBentoGrid(
    BuildContext context,
    ThemeData theme,
    ColorScheme scheme,
    double tf,
    AppLocalizations l10n, {
    required int reviewed,
    required int wellRemembered,
    required Duration elapsed,
  }) {
    final spacing = (14 * tf).clamp(8.0, 22.0);
    final aspect = (0.92 / tf.clamp(0.9, 1.15)).clamp(0.78, 1.05);
    final borderColor = scheme.outlineVariant.withValues(alpha: 0.45);
    final fill = Colors.grey.withValues(
      alpha: isDarkFor(context) ? 0.08 : 0.05,
    );

    final valueStyleLarge = theme.textTheme.titleLarge?.copyWith(
      fontWeight: FontWeight.w700,
      color: scheme.onSurface,
      height: 1.15,
    );
    final valueStyleSmall = theme.textTheme.titleSmall?.copyWith(
      fontWeight: FontWeight.w700,
      color: scheme.onSurface,
      height: 1.15,
    );

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: spacing,
      crossAxisSpacing: spacing,
      childAspectRatio: aspect,
      children: [
        _BentoStatCard(
          icon: Icons.menu_book_rounded,
          label: l10n.reviewSummaryStatReviewed,
          valueChild: TweenAnimationBuilder<int>(
            duration: const Duration(seconds: 1),
            curve: Curves.easeOutCubic,
            tween: IntTween(begin: 0, end: reviewed),
            builder: (context, value, _) {
              return Text(
                '$value',
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: valueStyleLarge,
              );
            },
          ),
          fill: fill,
          borderColor: borderColor,
          scheme: scheme,
          theme: theme,
        ),
        _BentoStatCard(
          iconWidget: Icon(
            FluentIcons.data_histogram_24_regular,
            size: (26 * tf).clamp(20.0, 34.0),
            color: scheme.primary,
          ),
          label: l10n.reviewSummaryStatMastered,
          valueChild: TweenAnimationBuilder<int>(
            duration: const Duration(seconds: 1),
            curve: Curves.easeOutCubic,
            tween: IntTween(begin: 0, end: wellRemembered),
            builder: (context, value, _) {
              return Text(
                '$value',
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: valueStyleLarge,
              );
            },
          ),
          fill: fill,
          borderColor: borderColor,
          scheme: scheme,
          theme: theme,
        ),
        _BentoStatCard(
          icon: Icons.timer_outlined,
          label: l10n.reviewSummaryStatTime,
          valueChild: TweenAnimationBuilder<double>(
            duration: const Duration(seconds: 1),
            curve: Curves.easeOutCubic,
            tween: Tween<double>(
              begin: 0,
              end: elapsed.inMilliseconds.toDouble(),
            ),
            builder: (context, ms, _) {
              final clamped = ms.clamp(0, elapsed.inMilliseconds.toDouble());
              final label = formatStudyDuration(
                l10n,
                Duration(milliseconds: clamped.round()),
              );
              return Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: valueStyleSmall,
              );
            },
          ),
          fill: fill,
          borderColor: borderColor,
          scheme: scheme,
          theme: theme,
          compactValue: true,
        ),
      ],
    );
  }

  bool isDarkFor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  Widget _buildActionsSection(
    BuildContext context,
    ThemeData theme,
    ColorScheme scheme,
    double tf,
    AppLocalizations l10n,
  ) {
    final vPad = (14 * tf).clamp(10.0, 24.0);
    final linkPad = (10 * tf).clamp(8.0, 18.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        fluent.FilledButton(
          onPressed: () => _goToDashboard(context),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: vPad),
            child: Text(
              l10n.reviewSummaryBackDashboard,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        SizedBox(height: 16 * tf.clamp(0.9, 1.25)),
        fluent.HyperlinkButton(
          onPressed: () => _showReviewedWordsSheet(context),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: linkPad),
            child: Text(
              l10n.reviewSummarySeeWords,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleSmall?.copyWith(
                color: scheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CloudSyncFooter extends StatelessWidget {
  const _CloudSyncFooter({
    required this.phase,
    required this.scheme,
    required this.theme,
    required this.l10n,
  });

  final _CloudSyncPhase phase;
  final ColorScheme scheme;
  final ThemeData theme;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final tf = _summaryLayoutTf(context);
    final style = theme.textTheme.bodySmall?.copyWith(
      color: scheme.onSurfaceVariant,
      fontSize: 12,
      height: 1.25,
    );

    switch (phase) {
      case _CloudSyncPhase.syncing:
        return Text(
          l10n.reviewSummaryCloudSyncing,
          textAlign: TextAlign.center,
          style: style,
        );
      case _CloudSyncPhase.success:
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                l10n.reviewSummaryCloudOk,
                textAlign: TextAlign.center,
                style: style,
              ),
            ),
            SizedBox(width: 6 * tf.clamp(0.85, 1.35)),
            Icon(
              Icons.check_circle_rounded,
              size: (16 * tf).clamp(14.0, 24.0),
              color: const Color(0xFF107C10),
            ),
          ],
        );
      case _CloudSyncPhase.error:
        return Text(
          l10n.reviewSummaryCloudFail,
          textAlign: TextAlign.center,
          style: style?.copyWith(color: scheme.error),
        );
    }
  }
}

class _BentoStatCard extends StatelessWidget {
  const _BentoStatCard({
    required this.label,
    required this.valueChild,
    required this.fill,
    required this.borderColor,
    required this.scheme,
    required this.theme,
    this.icon,
    this.iconWidget,
    this.compactValue = false,
  }) : assert((icon != null) != (iconWidget != null));

  final IconData? icon;
  final Widget? iconWidget;
  final String label;
  final Widget valueChild;
  final Color fill;
  final Color borderColor;
  final ColorScheme scheme;
  final ThemeData theme;
  final bool compactValue;

  @override
  Widget build(BuildContext context) {
    final tf = _summaryLayoutTf(context);
    final padH = (12 * tf).clamp(8.0, 20.0);
    final padV = (16 * tf).clamp(10.0, 26.0);
    final iconS = (26 * tf).clamp(20.0, 34.0);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(padH, padV, padH, padV),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (iconWidget != null)
              iconWidget!
            else
              Icon(icon, size: iconS, color: scheme.primary),
            SizedBox(height: (compactValue ? 10 : 12) * tf.clamp(0.9, 1.2)),
            valueChild,
            SizedBox(height: 6 * tf.clamp(0.9, 1.2)),
            Text(
              label,
              textAlign: TextAlign.center,
              style: theme.textTheme.labelMedium?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Very subtle grain / noise overlay to suggest layered Mica material.
class _MicaNoisePainter extends CustomPainter {
  _MicaNoisePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    const step = 6.0;
    for (var x = 0.0; x < size.width; x += step) {
      for (var y = 0.0; y < size.height; y += step) {
        if (((x ~/ step) + (y ~/ step)) % 3 == 0) {
          canvas.drawRect(Rect.fromLTWH(x, y, 1.2, 1.2), paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
