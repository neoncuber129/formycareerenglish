import 'dart:math' show pi;

import 'package:confetti/confetti.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/presentation/mobile_layout.dart';
import '../application/review_controller.dart';

/// Windows 11 accent blue.
const Color _kFluentBlueAccent = Color(0xFF0078D4);

String formatVietnameseStudyDuration(Duration d) {
  final totalSeconds = d.inSeconds;
  if (totalSeconds <= 0) {
    return '0 giây';
  }
  if (totalSeconds < 60) {
    return '$totalSeconds giây';
  }
  final minutes = d.inMinutes;
  final seconds = totalSeconds % 60;
  if (d.inHours < 1) {
    return seconds > 0 ? '$minutes phút $seconds giây' : '$minutes phút';
  }
  final hours = d.inHours;
  final mins = minutes % 60;
  if (mins == 0) {
    return '$hours giờ';
  }
  return '$hours giờ $mins phút';
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

  static const _displayName = 'Bạn';
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
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              Text(
                'Từ vừa ôn (${history.length})',
                style: Theme.of(
                  ctx,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              ...history.map(
                (e) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(e.vocabAfterReview.sourceText),
                  subtitle: Text(
                    e.grade.name,
                    style: Theme.of(ctx).textTheme.bodySmall,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final reviewed = widget.result.totalReviewed;
    final well = widget.result.masteredCount;
    final elapsed = widget.result.duration;

    final micaBase = isDark ? const Color(0xFF1C1C1C) : const Color(0xFFF3F3F3);
    final micaLayer = isDark
        ? const Color(0xFF252526)
        : const Color(0xFFFAFAFA);

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        title: Text(
          'Tổng kết phiên ôn',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: Stack(
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
                          blastDirection: pi,
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
                            MobileLayout.gutter(context) + 6,
                            32,
                            MobileLayout.gutter(context) + 6,
                            56,
                          ),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 600),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const SizedBox(height: 16),
                                _buildCongratulationSection(theme, scheme),
                                const SizedBox(height: 48),
                                _buildBentoGrid(
                                  context,
                                  theme,
                                  scheme,
                                  reviewed: reviewed,
                                  wellRemembered: well,
                                  elapsed: elapsed,
                                ),
                                const SizedBox(height: 48),
                                _buildActionsSection(context, theme, scheme),
                                const SizedBox(height: 24),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: MobileLayout.gutter(context),
                  right: MobileLayout.gutter(context),
                  bottom: 10,
                  child: _CloudSyncFooter(
                    phase: _cloudSyncPhase,
                    scheme: scheme,
                    theme: theme,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCongratulationSection(ThemeData theme, ColorScheme scheme) {
    return Column(
      children: [
        ScaleTransition(
          scale: _iconScale,
          child: const Icon(
            Icons.check_circle_rounded,
            size: 80,
            color: _kFluentBlueAccent,
          ),
        ),
        const SizedBox(height: 28),
        Text(
          'Tốt lắm, $_displayName!',
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
        const SizedBox(height: 16),
        Text(
          'Bạn đã hoàn thành mục tiêu ôn tập hôm nay.',
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
    ColorScheme scheme, {
    required int reviewed,
    required int wellRemembered,
    required Duration elapsed,
  }) {
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
      mainAxisSpacing: 14,
      crossAxisSpacing: 14,
      childAspectRatio: 0.92,
      children: [
        _BentoStatCard(
          icon: Icons.menu_book_rounded,
          label: 'Đã ôn',
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
            size: 26,
            color: scheme.primary,
          ),
          label: 'Ghi nhớ',
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
          label: 'Thời gian',
          valueChild: TweenAnimationBuilder<double>(
            duration: const Duration(seconds: 1),
            curve: Curves.easeOutCubic,
            tween: Tween<double>(
              begin: 0,
              end: elapsed.inMilliseconds.toDouble(),
            ),
            builder: (context, ms, _) {
              final clamped = ms.clamp(0, elapsed.inMilliseconds.toDouble());
              final label = formatVietnameseStudyDuration(
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
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton(
          onPressed: () => _goToDashboard(context),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Text(
            'Quay lại Dashboard',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => _showReviewedWordsSheet(context),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          child: Text(
            'Xem danh sách từ vừa ôn',
            style: theme.textTheme.titleSmall?.copyWith(
              color: scheme.primary,
              fontWeight: FontWeight.w500,
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
  });

  final _CloudSyncPhase phase;
  final ColorScheme scheme;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final style = theme.textTheme.bodySmall?.copyWith(
      color: scheme.onSurfaceVariant,
      fontSize: 12,
      height: 1.25,
    );

    switch (phase) {
      case _CloudSyncPhase.syncing:
        return Text(
          'Đang đồng bộ dữ liệu đám mây…',
          textAlign: TextAlign.center,
          style: style,
        );
      case _CloudSyncPhase.success:
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                'Đã đồng bộ thành công',
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: style,
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.check_circle_rounded,
              size: 16,
              color: const Color(0xFF107C10),
            ),
          ],
        );
      case _CloudSyncPhase.error:
        return Text(
          'Không thể đồng bộ đám mây',
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
    return DecoratedBox(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (iconWidget != null)
              iconWidget!
            else
              Icon(icon, size: 26, color: scheme.primary),
            SizedBox(height: compactValue ? 10 : 12),
            valueChild,
            const SizedBox(height: 6),
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
