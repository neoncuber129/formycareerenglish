import 'package:app_l10n/app_l10n.dart';
import 'package:desktop/core/theme/desktop_pane_layout.dart';
import 'package:desktop/features/capture/presentation/capture_visual_guides_widgets.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// In-app user guides (navigation, capture, SRS, settings, Pro overview).
class GuidesScreen extends ConsumerWidget {
  const GuidesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = fluent.FluentTheme.of(context);

    Widget sectionCard(String title, String body) {
      return fluent.Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.typography.subtitle?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              Text(body, style: theme.typography.body),
            ],
          ),
        ),
      );
    }

    Widget sectionCardWithChild(String title, Widget child) {
      return fluent.Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.typography.subtitle?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              child,
            ],
          ),
        ),
      );
    }

    final captureVisualCard = sectionCardWithChild(
      l10n.captureVisualGuidesCardTitle,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CaptureVisualGuidesSection(
            theme: theme,
            l10n: l10n,
            showDetailLinks: false,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              fluent.HyperlinkButton(
                onPressed: () => showAutoCaptureVisualGuideDialog(context),
                child: Text(l10n.captureAutoVisualGuideLink),
              ),
              fluent.HyperlinkButton(
                onPressed: () => showOcrVisualGuideDialog(context),
                child: Text(l10n.captureOcrVisualGuideLink),
              ),
            ],
          ),
        ],
      ),
    );

    final trailingSections = <(String title, String body)>[
      (l10n.guidesReviewTitle, l10n.guidesReviewBody),
      (l10n.guidesVocabTitle, l10n.guidesVocabBody),
      (l10n.guidesSettingsTitle, l10n.guidesSettingsBody),
      (l10n.guidesProTitle, l10n.guidesProBody),
    ];

    return fluent.ScaffoldPage(
      padding: EdgeInsets.zero,
      header: fluent.PageHeader(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.navGuides),
            const SizedBox(height: 4),
            Text(
              l10n.guidesPageSubtitle,
              style: theme.typography.caption,
            ),
          ],
        ),
      ),
      content: SingleChildScrollView(
        padding: DesktopPaneScrollMetrics.scrollPadding(context),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: DesktopPaneScrollMetrics.maxBodyWidth(context),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                sectionCard(l10n.guidesIntroTitle, l10n.guidesIntroBody),
                const SizedBox(height: 12),
                sectionCard(l10n.guidesCaptureTitle, l10n.guidesCaptureBody),
                const SizedBox(height: 12),
                captureVisualCard,
                for (var i = 0; i < trailingSections.length; i++) ...[
                  const SizedBox(height: 12),
                  sectionCard(trailingSections[i].$1, trailingSections[i].$2),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
