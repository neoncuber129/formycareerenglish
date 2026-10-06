import 'dart:math' as math;

import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/material.dart';

/// Linear text-size factor for the current embedder view (OS text scaling,
/// accessibility). Matches how [Text] scales a reference font size.
///
/// Use for **layout** (padding, icon sizes, popup max height). Do not multiply
/// into [TextStyle.fontSize] for widgets that already inherit
/// [MediaQuery.textScaler] (e.g. [Text], Fluent [TextBox] with default scaler).
double desktopOsTextLayoutFactor(BuildContext context) {
  const ref = 14.0;
  return MediaQuery.textScalerOf(context).scale(ref) / ref;
}

/// Tighter layout factor for capture popup (padding, icons, max shell).
double capturePopupLayoutFactor(BuildContext context) {
  return desktopOsTextLayoutFactor(context).clamp(0.92, 1.18);
}

fluent.FluentThemeData? _capturePopupFluentTheme(BuildContext context) {
  return fluent.FluentTheme.maybeOf(context);
}

/// Neutral backdrop for flattening semi-transparent Fluent surfaces so the
/// Win32 color-key (magenta) scaffold does not bleed through.
Color capturePopupNeutralBackdrop(BuildContext context) {
  final f = _capturePopupFluentTheme(context);
  if (f != null) {
    return f.brightness == fluent.Brightness.dark
        ? const Color(0xFF1C1C1C)
        : const Color(0xFFF5F5F5);
  }
  return Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFF121212)
      : const Color(0xFFF5F5F5);
}

/// Blends [layer] over [blendOnto] so the result is visually opaque when the
/// OS text scale / acrylic tokens use translucent fills.
Color capturePopupOpaqueSurface(Color layer, Color blendOnto) {
  return Color.alphaBlend(layer, blendOnto);
}

Color capturePopupShellBackground(BuildContext context) {
  final f = _capturePopupFluentTheme(context);
  if (f != null) {
    final res = f.resources;
    return capturePopupOpaqueSurface(
      res.cardBackgroundFillColorDefault,
      capturePopupNeutralBackdrop(context),
    );
  }
  return Theme.of(context).colorScheme.surface;
}

Color capturePopupSectionBackground(BuildContext context) {
  final f = _capturePopupFluentTheme(context);
  if (f != null) {
    final res = f.resources;
    return capturePopupOpaqueSurface(
      res.cardBackgroundFillColorSecondary,
      capturePopupShellBackground(context),
    );
  }
  final cs = Theme.of(context).colorScheme;
  return Color.alphaBlend(
    cs.surfaceContainerHighest.withValues(alpha: 0.92),
    cs.surface,
  );
}

/// Selection fill for read-only source field (Material [TextField] selection).
Color capturePopupSourceSelectionFill(BuildContext context) {
  return const Color(0xFFFFEB3B).withValues(alpha: 0.62);
}

Color capturePopupSourceSelectionHandle(BuildContext context) {
  return const Color(0xFFFBC02D);
}

Color capturePopupEditorTrayBackground(BuildContext context) {
  final f = _capturePopupFluentTheme(context);
  if (f != null) {
    final res = f.resources;
    return capturePopupOpaqueSurface(
      res.controlFillColorSecondary,
      capturePopupSectionBackground(context),
    );
  }
  final cs = Theme.of(context).colorScheme;
  return Color.alphaBlend(
    cs.surfaceContainer.withValues(alpha: 0.9),
    capturePopupSectionBackground(context),
  );
}

/// Max shell size + padding for [CapturePopup], aligned with OS text scale and
/// logical screen size (DPI / display zoom already reflected in [MediaQuery.size]).
class CapturePopupShellLayout {
  const CapturePopupShellLayout({
    required this.outerPad,
    required this.maxW,
    required this.maxH,
  });

  final double outerPad;
  final double maxW;
  final double maxH;
}

CapturePopupShellLayout capturePopupShellLayout(BuildContext context) {
  final mqSize = MediaQuery.sizeOf(context);
  final tf = capturePopupLayoutFactor(context);
  // Portrait shell: narrow width, taller height. Area = ½ × (1080×1440) ref caps.
  const maxCapW = 640.0;
  const maxCapH = 1215.0;
  final outerPad = (12.0 * tf).clamp(8.0, 24.0);
  final widthBudget = math.max(0.0, mqSize.width - outerPad * 2);
  final heightBudget = math.max(0.0, mqSize.height - outerPad * 2);
  final capW = maxCapW * math.min(tf, 1.12);
  final capH = maxCapH * math.min(tf, 1.12);
  // Allow a slimmer column on small displays; keep a sensible reading width cap.
  var maxW = math.min(capW, widthBudget).clamp(220.0, capW);
  var maxH = math.min(capH, heightBudget).clamp(240.0, capH);
  // Portrait shell: width must stay clearly below height (host window can be wide
  // and short — without this, maxW stays large while maxH shrinks → "landscape").
  const portraitWidthOverHeight = 0.56;
  maxW = math.min(maxW, (maxH * portraitWidthOverHeight).clamp(200.0, capW));
  return CapturePopupShellLayout(outerPad: outerPad, maxW: maxW, maxH: maxH);
}

/// [FluentApp]/[MaterialApp] builder hook: keeps [MediaQuery.textScaler] aligned
/// with the active [FlutterView] so desktop zoom / system text size track the OS.
Widget attachDesktopViewTextScaler(BuildContext context, Widget? child) {
  return attachDesktopCombinedTextScaler(context, child);
}

/// OS/view text scaler multiplied by [userTextScaleMultiplier] (Settings → Text size).
Widget attachDesktopCombinedTextScaler(
  BuildContext context,
  Widget? child, {
  double userTextScaleMultiplier = 1.0,
}) {
  if (child == null) {
    return const SizedBox.shrink();
  }
  final view = View.maybeOf(context);
  final mq = MediaQuery.maybeOf(context);
  if (view == null || mq == null) {
    return child;
  }
  final fromView = MediaQueryData.fromView(view);
  const refFont = 14.0;
  final osFactor = fromView.textScaler.scale(refFont) / refFont;
  final user = userTextScaleMultiplier.clamp(0.75, 1.35);
  final combined = TextScaler.linear(osFactor * user);
  return MediaQuery(
    data: mq.copyWith(textScaler: combined),
    child: child,
  );
}
