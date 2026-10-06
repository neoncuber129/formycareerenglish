import 'dart:async';

import 'package:app_l10n/app_l10n.dart';
import 'package:desktop/core/monetization/app_state.dart';
import 'package:desktop/core/theme/desktop_pane_layout.dart';
import 'package:desktop/features/monetization/presentation/activate_pro_license_flow.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_models/shared_models.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../settings/application/settings_service.dart';
import '../../settings/presentation/local_profiles_settings_section.dart';
import '../../vocab/presentation/vocab_list_provider.dart';

/// Overview stats, charts, and shortcuts into Capture, SRS review, and vocabulary.
class DashboardHomeScreen extends ConsumerWidget {
  const DashboardHomeScreen({
    required this.onOpenCapture,
    required this.onOpenReview,
    required this.onOpenVocabulary,
    required this.onOpenSettings,
    required this.onOpenAbout,
    super.key,
  });

  final VoidCallback onOpenCapture;
  final VoidCallback onOpenReview;
  final VoidCallback onOpenVocabulary;
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenAbout;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = fluent.FluentTheme.of(context);
    final l10n = context.l10n;
    final asyncList = ref.watch(vocabListProvider);
    final appState = ref.watch(appStateProvider);

    return fluent.ScaffoldPage(
      padding: EdgeInsets.zero,
      header: fluent.PageHeader(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.navDashboard),
            const SizedBox(height: 4),
            Text(
              l10n.dashSubtitle,
              style: theme.typography.caption,
            ),
          ],
        ),
      ),
      content: asyncList.when(
        loading: () => const Center(child: fluent.ProgressRing()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: fluent.InfoBar(
              title: Text(l10n.dashCouldNotLoadVocab('$error')),
              severity: fluent.InfoBarSeverity.error,
            ),
          ),
        ),
        data: (items) {
          final now = DateTime.now();
          final snapshot = VocabDashboardSnapshot.compute(items, now);
          final insights = VocabDashboardInsights.compute(items, now);
          return _DashboardBody(
            snapshot: snapshot,
            insights: insights,
            theme: theme,
            isPro: appState.isPro,
            onOpenCapture: onOpenCapture,
            onOpenReview: onOpenReview,
            onOpenVocabulary: onOpenVocabulary,
            onOpenSettings: onOpenSettings,
            onOpenAbout: onOpenAbout,
          );
        },
      ),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({
    required this.snapshot,
    required this.insights,
    required this.theme,
    required this.isPro,
    required this.onOpenCapture,
    required this.onOpenReview,
    required this.onOpenVocabulary,
    required this.onOpenSettings,
    required this.onOpenAbout,
  });

  final VocabDashboardSnapshot snapshot;
  final VocabDashboardInsights insights;
  final fluent.FluentThemeData theme;
  final bool isPro;
  final VoidCallback onOpenCapture;
  final VoidCallback onOpenReview;
  final VoidCallback onOpenVocabulary;
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenAbout;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final pad = DesktopPaneScrollMetrics.scrollPadding(context);
    final maxBody = DesktopPaneScrollMetrics.maxBodyWidth(context);
    final accent = theme.accentColor;

    return SingleChildScrollView(
      padding: pad,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxBody),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _DashboardLearnerPicker(onOpenSettings: onOpenSettings),
              const SizedBox(height: 16),
              _HeroBanner(snapshot: snapshot, theme: theme, accent: accent),
              if (!isPro) ...[
                const SizedBox(height: 16),
                _DashboardProUpsell(
                  accent: accent,
                  onOpenAbout: onOpenAbout,
                ),
              ],
              const SizedBox(height: 20),
              LayoutBuilder(
                builder: (context, c) {
                  final wide = c.maxWidth >= 720;
                  final spacing = 14.0;
                  final cardW = wide
                      ? (c.maxWidth - spacing) / 2
                      : c.maxWidth;
                  return Wrap(
                    spacing: spacing,
                    runSpacing: spacing,
                    children: [
                      SizedBox(
                        width: wide ? cardW : c.maxWidth,
                        child: _StatCard(
                          theme: theme,
                          accent: accent,
                          icon: fluent.FluentIcons.clock,
                          title: l10n.dashStatDueNowTitle,
                          value: '${snapshot.dueNowCount}',
                          subtitle: l10n.dashStatDueNowSubtitle,
                        ),
                      ),
                      SizedBox(
                        width: wide ? cardW : c.maxWidth,
                        child: _StatCard(
                          theme: theme,
                          accent: accent,
                          icon: fluent.FluentIcons.library,
                          title: l10n.dashStatActiveTitle,
                          value: '${snapshot.activeLearningCount}',
                          subtitle: l10n.dashStatActiveSubtitle,
                        ),
                      ),
                      SizedBox(
                        width: wide ? cardW : c.maxWidth,
                        child: _StatCard(
                          theme: theme,
                          accent: accent,
                          icon: fluent.FluentIcons.starburst,
                          title: l10n.dashStatNewTitle,
                          value: '${snapshot.newCardsCount}',
                          subtitle: l10n.dashStatNewSubtitle,
                        ),
                      ),
                      SizedBox(
                        width: wide ? cardW : c.maxWidth,
                        child: _StatCard(
                          theme: theme,
                          accent: accent,
                          icon: fluent.FluentIcons.archive,
                          title: l10n.dashStatArchivedTitle,
                          value: '${snapshot.archivedCount}',
                          subtitle: l10n.dashStatArchivedSubtitle,
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 22),
              _InsightCard(
                theme: theme,
                title: l10n.dashInsightUpcoming,
                icon: fluent.FluentIcons.calendar,
                child: _DueHorizonChart(
                  theme: theme,
                  accent: accent,
                  dueNow: snapshot.dueNowCount,
                  dueWeek: insights.dueNextSevenDaysCount,
                  dueLater: insights.dueLaterCount,
                ),
              ),
              const SizedBox(height: 14),
              _InsightCard(
                theme: theme,
                title: l10n.dashInsightDeckComposition,
                icon: fluent.FluentIcons.bar_chart_vertical,
                child: _DeckCompositionChart(
                  theme: theme,
                  accent: accent,
                  newCount: insights.deckNewCount,
                  learningCount: insights.deckLearningCount,
                  reviewCount: insights.deckReviewCount,
                ),
              ),
              const SizedBox(height: 14),
              LayoutBuilder(
                builder: (context, c) {
                  final stacked = c.maxWidth < 520;
                  if (stacked) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _InsightCard(
                          theme: theme,
                          title: l10n.dashInsightByLanguage,
                          icon: fluent.FluentIcons.globe,
                          child: _HistogramBars(
                            theme: theme,
                            accent: accent,
                            entries: insights.topLanguages,
                            emptyLabel: l10n.dashEmptyLangPairs,
                          ),
                        ),
                        const SizedBox(height: 14),
                        _InsightCard(
                          theme: theme,
                          title: l10n.dashInsightPopularTags,
                          icon: fluent.FluentIcons.tag,
                          child: _HistogramBars(
                            theme: theme,
                            accent: accent,
                            entries: insights.topTags,
                            emptyLabel: l10n.dashEmptyTags,
                          ),
                        ),
                      ],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _InsightCard(
                          theme: theme,
                          title: l10n.dashInsightByLanguage,
                          icon: fluent.FluentIcons.globe,
                          child: _HistogramBars(
                            theme: theme,
                            accent: accent,
                            entries: insights.topLanguages,
                            emptyLabel: l10n.dashEmptyLangPairs,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _InsightCard(
                          theme: theme,
                          title: l10n.dashInsightPopularTags,
                          icon: fluent.FluentIcons.tag,
                          child: _HistogramBars(
                            theme: theme,
                            accent: accent,
                            entries: insights.topTags,
                            emptyLabel: l10n.dashEmptyTags,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 22),
              fluent.Card(
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            fluent.FluentIcons.lightning_bolt,
                            size: 20,
                            color: accent,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            l10n.dashQuickActions,
                            style: theme.typography.subtitle?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          fluent.FilledButton(
                            onPressed: onOpenReview,
                            child: const Text('Start review'),
                          ),
                          fluent.Button(
                            onPressed: onOpenVocabulary,
                            child: const Text('Open vocabulary'),
                          ),
                          fluent.Button(
                            onPressed: onOpenCapture,
                            child: const Text('Capture'),
                          ),
                        ],
                      ),
                      if (snapshot.dueNowCount == 0 &&
                          snapshot.activeLearningCount > 0) ...[
                        const SizedBox(height: 12),
                        Text(
                          l10n.dashNothingDueHint,
                          style: theme.typography.caption,
                        ),
                      ],
                    ],
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

class _DashboardProUpsell extends ConsumerStatefulWidget {
  const _DashboardProUpsell({
    required this.accent,
    required this.onOpenAbout,
  });

  final Color accent;
  final VoidCallback onOpenAbout;

  @override
  ConsumerState<_DashboardProUpsell> createState() =>
      _DashboardProUpsellState();
}

class _DashboardProUpsellState extends ConsumerState<_DashboardProUpsell> {
  bool _busy = false;

  Future<void> _openProWebsite() async {
    final url = ref.read(appStateProvider).proWebsiteUrl.trim();
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) {
      return;
    }
    await launchUrl(uri);
  }

  Future<void> _activate() async {
    if (_busy) {
      return;
    }
    final key = await showProLicenseKeyDialog(context);
    if (!mounted || key == null || key.isEmpty) {
      return;
    }
    setState(() => _busy = true);
    try {
      await activateProWithFeedback(context: context, ref: ref, key: key);
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = fluent.FluentTheme.of(context);

    return fluent.Card(
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  fluent.FluentIcons.starburst_solid,
                  color: widget.accent,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.aboutPlanFree,
                    style: theme.typography.subtitle?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(l10n.aboutProKeyInstructions, style: theme.typography.body),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                fluent.FilledButton(
                  onPressed: _busy ? null : _activate,
                  child: Text(
                    _busy ? l10n.aboutActivating : l10n.aboutActivatePro,
                  ),
                ),
                fluent.Button(
                  onPressed: _busy ? null : widget.onOpenAbout,
                  child: Text(l10n.aboutWhatProUnlocks),
                ),
                fluent.Button(
                  onPressed: _busy ? null : _openProWebsite,
                  child: Text(l10n.aboutVisitProWebsite),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner({
    required this.snapshot,
    required this.theme,
    required this.accent,
  });

  final VocabDashboardSnapshot snapshot;
  final fluent.FluentThemeData theme;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final subtle = theme.resources.controlFillColorSecondary;
    final stroke = theme.resources.controlStrokeColorDefault;
    final ratio = snapshot.activeLearningCount > 0
        ? snapshot.dueNowCount / snapshot.activeLearningCount
        : 0.0;

    return fluent.Card(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              accent.withValues(alpha: 0.20),
              subtle.withValues(alpha: 0.35),
            ],
          ),
          border: Border.all(color: stroke.withValues(alpha: 0.55)),
        ),
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.dashHeroTitle,
                    style: theme.typography.title?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.dashHeroStatsLine(
                      snapshot.dueNowCount,
                      snapshot.activeLearningCount,
                      snapshot.newCardsCount,
                    ),
                    style: theme.typography.caption,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    l10n.dashHeroShareCaption,
                    style: theme.typography.caption?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: ratio.clamp(0.0, 1.0),
                      minHeight: 8,
                      backgroundColor: subtle,
                      color: accent,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.dashHeroPercentDue((ratio * 100).round()),
                    style: theme.typography.caption,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Icon(
              fluent.FluentIcons.trending12,
              size: 56,
              color: accent.withValues(alpha: 0.35),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.theme,
    required this.accent,
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
  });

  final fluent.FluentThemeData theme;
  final Color accent;
  final IconData icon;
  final String title;
  final String value;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return fluent.Card(
      borderRadius: BorderRadius.circular(10),
      child: Stack(
        children: [
          Positioned(
            right: 12,
            top: 12,
            child: Icon(
              icon,
              size: 26,
              color: accent.withValues(alpha: 0.22),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 44, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.typography.caption),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: theme.typography.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: theme.typography.caption?.copyWith(
                    color: theme.typography.caption?.color?.withValues(
                      alpha: 0.88,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({
    required this.theme,
    required this.title,
    required this.icon,
    required this.child,
  });

  final fluent.FluentThemeData theme;
  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return fluent.Card(
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: theme.accentColor),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: theme.typography.bodyStrong?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

class _HistogramBars extends StatelessWidget {
  const _HistogramBars({
    required this.theme,
    required this.accent,
    required this.entries,
    required this.emptyLabel,
  });

  final fluent.FluentThemeData theme;
  final Color accent;
  final List<DashboardHistogramEntry> entries;
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return Text(emptyLabel, style: theme.typography.caption);
    }
    final maxV = entries.map((e) => e.count).reduce((a, b) => a > b ? a : b);
    final track = theme.resources.controlFillColorSecondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final e in entries) ...[
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  e.label,
                  style: theme.typography.body,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${e.count}',
                style: theme.typography.bodyStrong,
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: LinearProgressIndicator(
              value: maxV > 0 ? e.count / maxV : 0,
              minHeight: 7,
              backgroundColor: track,
              color: accent.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _DeckCompositionChart extends StatelessWidget {
  const _DeckCompositionChart({
    required this.theme,
    required this.accent,
    required this.newCount,
    required this.learningCount,
    required this.reviewCount,
  });

  final fluent.FluentThemeData theme;
  final Color accent;
  final int newCount;
  final int learningCount;
  final int reviewCount;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final total = newCount + learningCount + reviewCount;
    if (total == 0) {
      return Text(
        l10n.dashDeckCompositionEmpty,
        style: theme.typography.caption,
      );
    }

    Widget segment(int flex, Color color) {
      if (flex <= 0) {
        return const SizedBox.shrink();
      }
      return Expanded(
        flex: flex,
        child: Container(
          height: 14,
          color: color,
        ),
      );
    }

    final learningColor = accent.withValues(alpha: 0.72);
    final reviewColor = accent.withValues(alpha: 0.42);
    final newColor = theme.resources.controlStrongFillColorDisabled;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(7),
          child: Row(
            children: [
              segment(newCount, newColor),
              segment(learningCount, learningColor),
              segment(reviewCount, reviewColor),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 14,
          runSpacing: 8,
          children: [
            _LegendDot(
              theme: theme,
              color: newColor,
              label: l10n.dashLegendNewCount(newCount),
            ),
            _LegendDot(
              theme: theme,
              color: learningColor,
              label: l10n.dashLegendLearningCount(learningCount),
            ),
            _LegendDot(
              theme: theme,
              color: reviewColor,
              label: l10n.dashLegendEstablishedCount(reviewCount),
            ),
          ],
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({
    required this.theme,
    required this.color,
    required this.label,
  });

  final fluent.FluentThemeData theme;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(label, style: theme.typography.caption),
      ],
    );
  }
}

class _DueHorizonChart extends StatelessWidget {
  const _DueHorizonChart({
    required this.theme,
    required this.accent,
    required this.dueNow,
    required this.dueWeek,
    required this.dueLater,
  });

  final fluent.FluentThemeData theme;
  final Color accent;
  final int dueNow;
  final int dueWeek;
  final int dueLater;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final maxV = [dueNow, dueWeek, dueLater].reduce((a, b) => a > b ? a : b);
    final track = theme.resources.controlFillColorSecondary;

    Widget row(String label, int value, Color barColor) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(label, style: theme.typography.body)),
                Text('$value', style: theme.typography.bodyStrong),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: LinearProgressIndicator(
                value: maxV > 0 ? value / maxV : 0,
                minHeight: 8,
                backgroundColor: track,
                color: barColor,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        row(l10n.dashDueNowRow, dueNow, accent),
        row(l10n.dashDueWeekRow, dueWeek, accent.withValues(alpha: 0.68)),
        row(l10n.dashDueLaterRow, dueLater, accent.withValues(alpha: 0.42)),
      ],
    );
  }
}

class _DashboardLearnerPicker extends ConsumerWidget {
  const _DashboardLearnerPicker({required this.onOpenSettings});

  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final state = ref.watch(localProfilesProvider);
    final notifier = ref.read(localProfilesProvider.notifier);

    return fluent.Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: fluent.InfoLabel(
          label: l10n.dashLearnerPickerLabel,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: fluent.ComboBox<String>(
                  value: state.activeProfileId,
                  isExpanded: true,
                  items: state.profiles
                      .map(
                        (p) => fluent.ComboBoxItem<String>(
                          value: p.id,
                          child: Text(labelLocalProfile(l10n, p)),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (id) {
                    if (id != null) {
                      unawaited(notifier.setActiveProfile(id));
                    }
                  },
                ),
              ),
              const SizedBox(width: 10),
              fluent.Button(
                onPressed: onOpenSettings,
                child: Text(l10n.dashLearnerPickerNewButton),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
