import 'package:flutter/material.dart';

/// Phone-first layout helpers (~320dp–430dp+ widths, portrait).
abstract final class MobileLayout {
  /// Horizontal inset from screen edges: scales gently with width, clamped.
  static double gutter(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return (w * 0.045).clamp(12.0, 22.0);
  }

  /// Narrow phones: fewer simultaneous labels in [NavigationBar].
  static bool useDenseBottomNav(BuildContext context) =>
      MediaQuery.sizeOf(context).width < 412;

  static NavigationDestinationLabelBehavior bottomNavLabels(
    BuildContext context,
  ) =>
      useDenseBottomNav(context)
          ? NavigationDestinationLabelBehavior.onlyShowSelected
          : NavigationDestinationLabelBehavior.alwaysShow;

  /// Matches [ThemeData.navigationBarTheme]; shorter bar when labels are denser.
  static double bottomNavHeight(BuildContext context) =>
      useDenseBottomNav(context) ? 68 : 72;
}
