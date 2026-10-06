import 'package:app_l10n/app_l10n.dart';
import 'package:desktop/core/monetization/app_state.dart';
import 'package:desktop/core/theme/desktop_pane_layout.dart';
import 'package:desktop/core/theme/desktop_text_scale.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Builds the overview pane; callbacks jump to Capture / Review / Vocabulary / Settings / About panes.
typedef FluentDashboardPaneBuilder =
    Widget Function(
      VoidCallback openCapture,
      VoidCallback openReview,
      VoidCallback openVocabulary,
      VoidCallback openSettings,
      VoidCallback openAbout,
    );

/// Top-level dashboard shell using Fluent navigation.
class FluentDashboardShell extends ConsumerStatefulWidget {
  const FluentDashboardShell({
    required this.dashboardPaneBuilder,
    required this.capturePage,
    required this.reviewPage,
    required this.vocabPage,
    required this.guidesPage,
    required this.settingsPage,
    required this.aboutPage,
    super.key,
  });

  final FluentDashboardPaneBuilder dashboardPaneBuilder;
  final Widget capturePage;
  final Widget reviewPage;
  final Widget vocabPage;
  final Widget guidesPage;
  final Widget settingsPage;
  final Widget aboutPage;

  static const int paneDashboard = 0;
  static const int paneCapture = 1;
  static const int paneReview = 2;
  static const int paneVocabulary = 3;
  static const int paneGuides = 4;
  static const int paneSettings = 5;
  static const int paneAbout = 6;

  @override
  ConsumerState<FluentDashboardShell> createState() =>
      _FluentDashboardShellState();
}

class _FluentDashboardShellState extends ConsumerState<FluentDashboardShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final appState = ref.watch(appStateProvider);
    final tf = desktopOsTextLayoutFactor(context).clamp(0.85, 1.55);
    final hPad = (10 * tf).clamp(6.0, 18.0);
    final vTop = (6 * tf).clamp(4.0, 14.0);
    final vBot = (4 * tf).clamp(2.0, 10.0);
    final iconSize = (20 * tf).clamp(18.0, 30.0);
    final theme = FluentTheme.of(context);

    return IconTheme(
      data: IconThemeData(size: iconSize),
      child: NavigationView(
        pane: NavigationPane(
          selected: _selectedIndex,
          onChanged: (index) => setState(() => _selectedIndex = index),
          displayMode: PaneDisplayMode.auto,
          header: Padding(
            padding: EdgeInsets.fromLTRB(hPad, vTop, hPad, vBot),
            child: Text(
              l10n.appTitle,
              style: theme.typography.bodyStrong?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          footerItems: [
            PaneItemHeader(
              header: Padding(
                padding: EdgeInsets.symmetric(horizontal: hPad),
                child: Text(l10n.navDesktop, style: theme.typography.caption),
              ),
            ),
            if (!appState.isPro)
              PaneItemAction(
                icon: Icon(FluentIcons.starburst_solid),
                title: Text(l10n.aboutActivatePro),
                onTap: () =>
                    setState(() => _selectedIndex = FluentDashboardShell.paneAbout),
              ),
          ],
          items: [
            PaneItem(
              icon: Icon(FluentIcons.view_dashboard),
              title: Text(l10n.navDashboard),
              body: widget.dashboardPaneBuilder(
                () => setState(() => _selectedIndex = FluentDashboardShell.paneCapture),
                () => setState(() => _selectedIndex = FluentDashboardShell.paneReview),
                () =>
                    setState(() => _selectedIndex = FluentDashboardShell.paneVocabulary),
                () => setState(() => _selectedIndex = FluentDashboardShell.paneSettings),
                () => setState(() => _selectedIndex = FluentDashboardShell.paneAbout),
              ),
            ),
            PaneItem(
              key: const ValueKey<String>('pane_capture'),
              icon: const Icon(FluentIcons.desktop_screenshot),
              title: Text(l10n.navCapture),
              body: widget.capturePage,
            ),
            PaneItem(
              icon: Icon(FluentIcons.education),
              title: Text(l10n.navReview),
              body: widget.reviewPage,
            ),
            PaneItem(
              icon: Icon(FluentIcons.library),
              title: Text(l10n.navVocabulary),
              body: widget.vocabPage,
            ),
            PaneItem(
              key: const ValueKey<String>('pane_guides'),
              icon: Icon(FluentIcons.reading_mode),
              title: Text(l10n.navGuides),
              body: widget.guidesPage,
            ),
            PaneItem(
              icon: Icon(FluentIcons.settings),
              title: Text(l10n.navSettings),
              body: widget.settingsPage,
            ),
            PaneItem(
              icon: Icon(FluentIcons.info),
              title: Text(l10n.navAbout),
              body: widget.aboutPage,
            ),
          ],
        ),
        paneBodyBuilder: (item, child) => ColoredBox(
          color: theme.resources.layerFillColorDefault,
          child: material.Theme(
            data: desktopPaneMaterialTheme(theme),
            child: material.Material(
              type: material.MaterialType.transparency,
              child: child ?? const SizedBox.shrink(),
            ),
          ),
        ),
      ),
    );
  }
}
