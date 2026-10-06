import 'package:app_l10n/app_l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:settings_core/settings_core.dart';
import 'package:shared_models/shared_models.dart';

import '../../../core/presentation/mobile_layout.dart';
import '../../settings/presentation/local_profiles_settings_card.dart';
import '../../vocab/data/vocab_repository_impl.dart';
import 'mobile_shell_tab_provider.dart';

/// Overview stats and shortcuts into Words and Review tabs.
class DashboardHomePage extends ConsumerWidget {
  const DashboardHomePage({super.key});

  static const int tabWords = 1;
  static const int tabReview = 2;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final asyncList = ref.watch(vocabListProvider);

    return asyncList.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            l10n.mobileDashLoadFailed('$error'),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: scheme.error,
            ),
          ),
        ),
      ),
      data: (items) {
        final snapshot = VocabDashboardSnapshot.compute(items, DateTime.now());
        final g = MobileLayout.gutter(context);
        final learnerProfiles = ref.watch(localProfilesProvider);
        final learnerNotifier = ref.read(localProfilesProvider.notifier);
        return CustomScrollView(
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(g, 16, g, 8),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.navDashboard,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.mobileDashSubtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownMenu<String>(
                      key: ValueKey<String>(
                        '${learnerProfiles.activeProfileId}_${learnerProfiles.profiles.length}',
                      ),
                      initialSelection: learnerProfiles.activeProfileId,
                      width: MediaQuery.sizeOf(context).width - 2 * g,
                      label: Text(l10n.dashLearnerPickerLabel),
                      dropdownMenuEntries: learnerProfiles.profiles
                          .map(
                            (p) => DropdownMenuEntry<String>(
                              value: p.id,
                              label: mobileLabelLocalProfile(l10n, p),
                            ),
                          )
                          .toList(growable: false),
                      onSelected: (id) {
                        if (id != null) {
                          learnerNotifier.setActiveProfile(id);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: g, vertical: 8),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.35,
                ),
                delegate: SliverChildListDelegate.fixed([
                  _StatTile(
                    title: 'Due now',
                    value: '${snapshot.dueNowCount}',
                    subtitle: 'SRS queue',
                    color: scheme.primaryContainer,
                    onSurface: scheme.onPrimaryContainer,
                  ),
                  _StatTile(
                    title: l10n.dashStatActiveTitle,
                    value: '${snapshot.activeLearningCount}',
                    subtitle: l10n.mobileStatActiveSubtitle,
                    color: scheme.secondaryContainer,
                    onSurface: scheme.onSecondaryContainer,
                  ),
                  _StatTile(
                    title: l10n.dashStatNewTitle,
                    value: '${snapshot.newCardsCount}',
                    subtitle: l10n.mobileStatNewSubtitle,
                    color: scheme.tertiaryContainer,
                    onSurface: scheme.onTertiaryContainer,
                  ),
                  _StatTile(
                    title: l10n.dashStatArchivedTitle,
                    value: '${snapshot.archivedCount}',
                    subtitle: l10n.mobileStatArchivedSubtitle,
                    color: scheme.surfaceContainerHighest,
                    onSurface: scheme.onSurfaceVariant,
                  ),
                ]),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(g, 20, g, 24),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.dashQuickActions,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: () {
                        ref
                            .read(mobileShellTabIndexProvider.notifier)
                            .setIndex(tabReview);
                      },
                      icon: const Icon(Icons.school_rounded),
                      label: Text(l10n.mobileGoReview),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: () {
                        ref
                            .read(mobileShellTabIndexProvider.notifier)
                            .setIndex(tabWords);
                      },
                      icon: const Icon(Icons.book_rounded),
                      label: Text(l10n.mobileGoWords),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
    required this.onSurface,
  });

  final String title;
  final String value;
  final String subtitle;
  final Color color;
  final Color onSurface;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: color,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: theme.textTheme.labelMedium?.copyWith(
                color: onSurface.withValues(alpha: 0.85),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: onSurface.withValues(alpha: 0.75),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
