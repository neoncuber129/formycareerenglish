import 'package:app_l10n/app_l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:settings_core/settings_core.dart';

import '../../../core/sync/sync_service.dart';
import '../../../core/presentation/mobile_layout.dart';
import '../../about/presentation/about_page.dart';
import '../../review/application/review_controller.dart';
import '../../review/presentation/srs_review_screen.dart';
import '../../settings/presentation/settings_page.dart';
import '../../vocab/data/vocab_repository_impl.dart';
import '../../vocab/presentation/vocab_library_page.dart';
import 'dashboard_home_page.dart';
import 'mobile_shell_tab_provider.dart';

/// Bottom navigation: dashboard overview, vocabulary, review, then system screens.
class MobileShell extends ConsumerWidget {
  const MobileShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(mobileShellTabIndexProvider);
    final l10n = AppLocalizations.of(context)!;

    ref.listen<String>(
      localProfilesProvider.select((s) => s.activeProfileId),
      (previous, next) {
        Future<void>(() {
          if (previous != null && previous != next) {
            ref.invalidate(reviewControllerProvider);
            ref.invalidate(vocabListProvider);
          }
          ref.read(syncServiceProvider).startBackgroundRetry();
        });
      },
    );

    return Scaffold(
      body: IndexedStack(
        index: index,
        children: const [
          DashboardHomePage(),
          VocabLibraryPage(),
          SrsReviewScreen(),
          SettingsPage(),
          AboutPage(),
        ],
      ),
      bottomNavigationBar: NavigationBarTheme(
        data: Theme.of(context).navigationBarTheme.copyWith(
              labelBehavior: MobileLayout.bottomNavLabels(context),
              height: MobileLayout.bottomNavHeight(context),
            ),
        child: NavigationBar(
          selectedIndex: index,
          onDestinationSelected: (i) =>
              ref.read(mobileShellTabIndexProvider.notifier).setIndex(i),
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.dashboard_outlined),
              selectedIcon: const Icon(Icons.dashboard_rounded),
              label: l10n.navDashboard,
            ),
            NavigationDestination(
              icon: const Icon(Icons.book_outlined),
              selectedIcon: const Icon(Icons.book_rounded),
              label: l10n.navWords,
            ),
            NavigationDestination(
              icon: const Icon(Icons.school_outlined),
              selectedIcon: const Icon(Icons.school_rounded),
              label: l10n.navReview,
            ),
            NavigationDestination(
              icon: const Icon(Icons.settings_outlined),
              selectedIcon: const Icon(Icons.settings_rounded),
              label: l10n.navSettings,
            ),
            NavigationDestination(
              icon: const Icon(Icons.info_outline_rounded),
              selectedIcon: const Icon(Icons.info_rounded),
              label: l10n.navAbout,
            ),
          ],
        ),
      ),
    );
  }
}
