import 'dart:math' as math;

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' as material;

import 'desktop_text_scale.dart';

/// Shared scroll insets and content width for main [NavigationPane] bodies.
class DesktopPaneScrollMetrics {
  const DesktopPaneScrollMetrics._();

  static double layoutTf(BuildContext context) =>
      desktopOsTextLayoutFactor(context).clamp(0.85, 1.55);

  static EdgeInsets scrollPadding(BuildContext context) {
    final tf = layoutTf(context);
    final hPad = (24 * tf).clamp(14.0, 40.0);
    final topPad = (8 * tf).clamp(6.0, 18.0);
    final bottomPad = (32 * tf).clamp(18.0, 52.0);
    return EdgeInsets.fromLTRB(hPad, topPad, hPad, bottomPad);
  }

  static double maxBodyWidth(BuildContext context) {
    final tf = layoutTf(context);
    return ((920 * math.min(tf, 1.08)).clamp(560.0, 1040.0)).toDouble();
  }
}

/// Fluent card + icon header row shared by Settings, Capture, and similar pane pages.
class DesktopPaneSectionCard extends StatelessWidget {
  const DesktopPaneSectionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final tf = DesktopPaneScrollMetrics.layoutTf(context);
    final pad = (20 * tf).clamp(12.0, 32.0);
    final iconS = (22 * tf).clamp(18.0, 30.0);
    return Card(
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: EdgeInsets.all(pad),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, size: iconS, color: theme.accentColor),
                SizedBox(width: 10 * tf.clamp(0.85, 1.35)),
                Text(
                  title,
                  style: theme.typography.subtitle?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16 * tf.clamp(0.9, 1.25)),
            child,
          ],
        ),
      ),
    );
  }
}

/// Material theme for widgets inside Fluent panes so [Theme.of] tracks Fluent typography.
material.ThemeData desktopPaneMaterialTheme(FluentThemeData fluent) {
  final typo = fluent.typography;
  final brightness =
      fluent.brightness == Brightness.dark
          ? material.Brightness.dark
          : material.Brightness.light;

  final body = typo.body ?? const TextStyle();
  final caption = typo.caption ?? body;
  final title = typo.title ?? body;
  final subtitle = typo.subtitle ?? title;
  final titleLarge = typo.titleLarge ?? title;
  final bodyStrong = typo.bodyStrong ?? body;

  final textTheme = material.TextTheme(
    headlineMedium: titleLarge,
    titleLarge: titleLarge,
    titleMedium: title,
    titleSmall: subtitle,
    bodyLarge: body,
    bodyMedium: body,
    bodySmall: caption,
    labelLarge: bodyStrong,
    labelMedium: caption,
    labelSmall: caption,
  );

  return material.ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: material.ColorScheme.fromSeed(
      seedColor: fluent.accentColor,
      brightness: brightness,
    ),
    textTheme: textTheme,
    scaffoldBackgroundColor: material.Colors.transparent,
    canvasColor: material.Colors.transparent,
  );
}
