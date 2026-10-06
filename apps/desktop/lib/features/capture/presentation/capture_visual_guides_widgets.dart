import 'package:app_l10n/app_l10n.dart';
import 'package:desktop/core/theme/desktop_pane_layout.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/material.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';

/// Wider than [fluent.kDefaultContentDialogConstraints] so schematic guides read comfortably.
const BoxConstraints _kVisualGuideDialogConstraints = BoxConstraints(
  maxWidth: 560,
  maxHeight: 800,
);

/// Opens the multi-step auto-capture schematic dialog (same as Capture tab).
Future<void> showAutoCaptureVisualGuideDialog(BuildContext context) {
  final l10n = context.l10n;
  final theme = fluent.FluentTheme.of(context);
  final res = theme.resources;
  final pane = res.controlFillColorSecondary;
  final stroke = res.cardStrokeColorDefault;
  final line = theme.typography.body?.color ?? const Color(0xFF808080);

  return fluent.showDialog<void>(
    context: context,
    builder: (ctx) => fluent.ContentDialog(
      constraints: _kVisualGuideDialogConstraints,
      title: Text(l10n.captureDlgAutoCaptureTitle),
      content: SingleChildScrollView(
        child: AutoCaptureVisualGuideDetailColumn(
          pane: pane,
          stroke: stroke,
          lineColor: line,
          accent: theme.accentColor,
        ),
      ),
      actions: [
        fluent.Button(
          onPressed: () => Navigator.pop(ctx),
          child: Text(l10n.commonClose),
        ),
      ],
    ),
  );
}

/// Opens the region OCR schematic dialog (same as Capture tab).
Future<void> showOcrVisualGuideDialog(BuildContext context) {
  final l10n = context.l10n;
  final theme = fluent.FluentTheme.of(context);
  final res = theme.resources;
  final pane = res.controlFillColorSecondary;
  final stroke = res.cardStrokeColorDefault;

  return fluent.showDialog<void>(
    context: context,
    builder: (ctx) => fluent.ContentDialog(
      constraints: _kVisualGuideDialogConstraints,
      title: Text(l10n.captureDlgOcrGuideTitle),
      content: SingleChildScrollView(
        child: OcrVisualGuideDetailColumn(
          pane: pane,
          stroke: stroke,
          accent: theme.accentColor,
        ),
      ),
      actions: [
        fluent.Button(
          onPressed: () => Navigator.pop(ctx),
          child: Text(l10n.commonClose),
        ),
      ],
    ),
  );
}

/// Diagram summary + optional “detailed guide” links (Capture dashboard card).
class CaptureVisualGuidesSection extends StatelessWidget {
  const CaptureVisualGuidesSection({
    super.key,
    required this.theme,
    required this.l10n,
    this.showDetailLinks = true,
    this.onAutoGuide,
    this.onOcrGuide,
  });

  final fluent.FluentThemeData theme;
  final AppLocalizations l10n;
  final bool showDetailLinks;
  final VoidCallback? onAutoGuide;
  final VoidCallback? onOcrGuide;

  @override
  Widget build(BuildContext context) {
    final stroke = theme.resources.cardStrokeColorDefault;
    final headingStyle =
        theme.typography.subtitle?.copyWith(fontWeight: FontWeight.w600);
    final tf = DesktopPaneScrollMetrics.layoutTf(context);
    final cellInset = EdgeInsets.all((16 * tf).clamp(10.0, 24.0));
    final rowHeadingGap = 10 * tf.clamp(0.9, 1.25);

    Widget rowBody({
      required String heading,
      required Widget diagram,
      required String linkLabel,
      required VoidCallback onLink,
    }) {
      return Padding(
        padding: cellInset,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(heading, style: headingStyle),
            SizedBox(height: rowHeadingGap),
            diagram,
            const SizedBox(height: 4),
            fluent.HyperlinkButton(
              onPressed: onLink,
              child: Text(linkLabel),
            ),
          ],
        ),
      );
    }

    Widget rowBodyNoLink({
      required String heading,
      required Widget diagram,
    }) {
      return Padding(
        padding: cellInset,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(heading, style: headingStyle),
            SizedBox(height: rowHeadingGap),
            diagram,
          ],
        ),
      );
    }

    final autoDiagram =
        CaptureAutoFlowInlineDiagram(theme: theme, l10n: l10n);
    final ocrDiagram = CaptureOcrFlowInlineDiagram(theme: theme, l10n: l10n);

    final borderedRows = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: stroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showDetailLinks &&
              onAutoGuide != null &&
              onOcrGuide != null) ...[
            rowBody(
              heading: l10n.captureVisualGuidesAutoHeading,
              diagram: autoDiagram,
              linkLabel: l10n.captureAutoVisualGuideLink,
              onLink: onAutoGuide!,
            ),
            Divider(height: 1, thickness: 1, color: stroke),
            rowBody(
              heading: l10n.captureVisualGuidesOcrHeading,
              diagram: ocrDiagram,
              linkLabel: l10n.captureOcrVisualGuideLink,
              onLink: onOcrGuide!,
            ),
          ] else ...[
            rowBodyNoLink(
              heading: l10n.captureVisualGuidesAutoHeading,
              diagram: autoDiagram,
            ),
            Divider(height: 1, thickness: 1, color: stroke),
            rowBodyNoLink(
              heading: l10n.captureVisualGuidesOcrHeading,
              diagram: ocrDiagram,
            ),
          ],
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        borderedRows,
        SizedBox(height: rowHeadingGap),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(top: 2 * tf.clamp(0.85, 1.15)),
              child: Icon(
                FluentIcons.slide_text_24_regular,
                size: (18 * tf).clamp(16.0, 22.0),
                color: theme.accentColor,
              ),
            ),
            SizedBox(width: 10 * tf.clamp(0.85, 1.15)),
            Expanded(
              child: Text(
                l10n.captureVisualGuidesPopupRefineHint,
                style: theme.typography.caption,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Same column as the auto-capture dialog (for inline embedding, e.g. Guides).
class AutoCaptureVisualGuideDetailColumn extends StatelessWidget {
  const AutoCaptureVisualGuideDetailColumn({
    super.key,
    required this.pane,
    required this.stroke,
    required this.lineColor,
    required this.accent,
    this.includeIntro = true,
  });

  final Color pane;
  final Color stroke;
  final Color lineColor;
  final Color accent;
  final bool includeIntro;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = fluent.FluentTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (includeIntro) ...[
          Text(
            l10n.captureDlgAutoCaptureIntro,
            style: theme.typography.body,
          ),
          const SizedBox(height: 16),
        ],
        CaptureGuideStep(
          theme: theme,
          title: l10n.captureDlgAutoCaptureStep1Title,
          body: l10n.captureDlgAutoCaptureStep1Body,
          schemeCaption: l10n.captureDlgAutoCaptureSchemeCaption,
          schematic: SizedBox(
            height: 92,
            width: double.infinity,
            child: CustomPaint(
              painter: FakeDocLinesPainter(
                bg: pane,
                stroke: stroke,
                lineColor: lineColor,
                highlightLineIndex: 1,
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        CaptureGuideStep(
          theme: theme,
          title: l10n.captureDlgAutoCaptureStep2Title,
          body: l10n.captureDlgAutoCaptureStep2Body,
          schemeCaption: l10n.captureDlgAutoCaptureSchemeCaption,
          schematic: SizedBox(
            height: 92,
            width: double.infinity,
            child: CustomPaint(
              painter: FakeDocLinesPainter(
                bg: pane,
                stroke: stroke,
                lineColor: lineColor,
                highlightLineIndex: 1,
                showWaitDots: true,
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        CaptureGuideStep(
          theme: theme,
          title: l10n.captureDlgAutoCaptureStep3Title,
          body: l10n.captureDlgAutoCaptureStep3Body,
          schemeCaption: l10n.captureDlgAutoCaptureSchemeCaption,
          schematic: SizedBox(
            height: 100,
            width: double.infinity,
            child: CustomPaint(
              painter: PopupSchematicPainter(
                bg: pane,
                stroke: stroke,
                accent: accent,
                highlightedSourceLineIndex: 0,
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        CaptureGuideStep(
          theme: theme,
          title: l10n.captureDlgAutoCaptureStep4Title,
          body: l10n.captureDlgAutoCaptureStep4Body,
          schemeCaption: l10n.captureDlgAutoCaptureSchemeCaption,
          schematic: SizedBox(
            height: 100,
            width: double.infinity,
            child: CustomPaint(
              painter: PopupSchematicPainter(
                bg: pane,
                stroke: stroke,
                accent: accent,
                highlightedSourceLineIndex: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Same column as the OCR dialog (for inline embedding, e.g. Guides).
class OcrVisualGuideDetailColumn extends StatelessWidget {
  const OcrVisualGuideDetailColumn({
    super.key,
    required this.pane,
    required this.stroke,
    required this.accent,
    this.includeIntro = true,
  });

  final Color pane;
  final Color stroke;
  final Color accent;
  final bool includeIntro;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = fluent.FluentTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (includeIntro) ...[
          Text(
            l10n.captureDlgOcrGuideIntro,
            style: theme.typography.body,
          ),
          const SizedBox(height: 16),
        ],
        CaptureGuideStep(
          theme: theme,
          title: l10n.captureDlgOcrStep1Title,
          body: l10n.captureDlgOcrStep1Body,
          schemeCaption: l10n.captureDlgOcrSchemeCaption,
          schematic: SizedBox(
            height: 72,
            width: double.infinity,
            child: CustomPaint(
              painter: OcrHotkeyPainter(
                keyBg: pane,
                keyBorder: stroke,
                labelColor: accent,
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        CaptureGuideStep(
          theme: theme,
          title: l10n.captureDlgOcrStep2Title,
          body: l10n.captureDlgOcrStep2Body,
          schemeCaption: l10n.captureDlgOcrSchemeCaption,
          schematic: SizedBox(
            height: 112,
            width: double.infinity,
            child: CustomPaint(
              painter: OcrRegionOverlayPainter(
                dimColor: Colors.black.withValues(alpha: 0.52),
                innerFill: pane,
                stroke: stroke,
                accent: accent,
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        CaptureGuideStep(
          theme: theme,
          title: l10n.captureDlgOcrStep3Title,
          body: l10n.captureDlgOcrStep3Body,
          schemeCaption: l10n.captureDlgOcrSchemeCaption,
          schematic: SizedBox(
            height: 100,
            width: double.infinity,
            child: CustomPaint(
              painter: OcrResultPanelPainter(
                bg: pane,
                stroke: stroke,
                accent: accent,
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        CaptureGuideStep(
          theme: theme,
          title: l10n.captureDlgOcrStep4Title,
          body: l10n.captureDlgOcrStep4Body,
          schemeCaption: l10n.captureDlgOcrSchemeCaption,
          schematic: SizedBox(
            height: 100,
            width: double.infinity,
            child: CustomPaint(
              painter: PopupSchematicPainter(
                bg: pane,
                stroke: stroke,
                accent: accent,
                highlightedSourceLineIndex: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Icons + labels summarizing auto capture flow (dashboard summary row).
class CaptureAutoFlowInlineDiagram extends StatelessWidget {
  const CaptureAutoFlowInlineDiagram({
    super.key,
    required this.theme,
    required this.l10n,
  });

  final fluent.FluentThemeData theme;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final accent = theme.accentColor;
    final captionStyle = theme.typography.caption;
    final subtleIcon = captionStyle?.color?.withValues(alpha: 0.65);

    Widget node(IconData icon, String label) {
      return SizedBox(
        width: 68,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: accent),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: captionStyle?.copyWith(fontSize: 11),
            ),
          ],
        ),
      );
    }

    Widget arrow() {
      return Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: Icon(
          FluentIcons.arrow_right_12_regular,
          size: 14,
          color: subtleIcon,
        ),
      );
    }

    final row = Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        node(
          FluentIcons.cursor_hover_24_regular,
          l10n.captureAutoFlowSelectLabel,
        ),
        arrow(),
        node(FluentIcons.timer_24_regular, l10n.captureAutoFlowPauseLabel),
        arrow(),
        node(
          FluentIcons.translate_24_regular,
          l10n.captureAutoFlowPopupLabel,
        ),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth >= 300) {
              return row;
            }
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: row,
            );
          },
        ),
        const SizedBox(height: 8),
        Text(
          l10n.captureAutoFlowCaption,
          style: captionStyle,
        ),
      ],
    );
  }
}

/// Icons + labels for region OCR hotkey flow (dashboard summary row).
class CaptureOcrFlowInlineDiagram extends StatelessWidget {
  const CaptureOcrFlowInlineDiagram({
    super.key,
    required this.theme,
    required this.l10n,
  });

  final fluent.FluentThemeData theme;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final accent = theme.accentColor;
    final captionStyle = theme.typography.caption;
    final subtleIcon = captionStyle?.color?.withValues(alpha: 0.65);

    Widget node(IconData icon, String label) {
      return SizedBox(
        width: 72,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: accent),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: captionStyle?.copyWith(fontSize: 11),
            ),
          ],
        ),
      );
    }

    Widget arrow() {
      return Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: Icon(
          FluentIcons.arrow_right_12_regular,
          size: 14,
          color: subtleIcon,
        ),
      );
    }

    final row = Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        node(FluentIcons.keyboard_24_regular, l10n.captureOcrFlowHotkeyLabel),
        arrow(),
        node(
          FluentIcons.full_screen_maximize_24_regular,
          l10n.captureOcrFlowRegionLabel,
        ),
        arrow(),
        node(FluentIcons.scan_text_24_regular, l10n.captureOcrFlowResultLabel),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth >= 300) {
              return row;
            }
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: row,
            );
          },
        ),
        const SizedBox(height: 8),
        Text(
          l10n.captureOcrFlowCaption,
          style: captionStyle,
        ),
      ],
    );
  }
}

class CaptureGuideStep extends StatelessWidget {
  const CaptureGuideStep({
    super.key,
    required this.theme,
    required this.title,
    required this.body,
    required this.schemeCaption,
    required this.schematic,
  });

  final fluent.FluentThemeData theme;
  final String title;
  final String body;
  final String schemeCaption;
  final Widget schematic;

  @override
  Widget build(BuildContext context) {
    final stroke = theme.resources.cardStrokeColorDefault;
    final tf = DesktopPaneScrollMetrics.layoutTf(context);
    final schematicInset = (10 * tf).clamp(8.0, 16.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style:
              theme.typography.subtitle?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        Text(body, style: theme.typography.body),
        const SizedBox(height: 8),
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: stroke),
          ),
          child: Padding(
            padding: EdgeInsets.all(schematicInset),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                schematic,
                const SizedBox(height: 6),
                Text(
                  schemeCaption,
                  style: theme.typography.caption,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Stylized “document in another app” with one highlighted line.
class FakeDocLinesPainter extends CustomPainter {
  FakeDocLinesPainter({
    required this.bg,
    required this.stroke,
    required this.lineColor,
    required this.highlightLineIndex,
    this.showWaitDots = false,
  });

  final Color bg;
  final Color stroke;
  final Color lineColor;
  final int highlightLineIndex;
  final bool showWaitDots;

  static const double _inset = 6;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(
      _inset,
      _inset,
      size.width - 2 * _inset,
      size.height - 2 * _inset,
    );
    final rr = RRect.fromRectAndRadius(rect, const Radius.circular(5));
    canvas.drawRRect(rr, Paint()..color = bg);
    canvas.drawRRect(
      rr,
      Paint()
        ..color = stroke
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    final dotY = _inset + 8;
    for (var i = 0; i < 3; i++) {
      canvas.drawCircle(
        Offset(_inset + 9 + i * 13.0, dotY),
        3,
        Paint()..color = lineColor.withValues(alpha: 0.35),
      );
    }

    final lineLeft = _inset + 12;
    final lineRight = size.width - _inset - 12;
    final lineW = lineRight - lineLeft;
    const lineH = 5.0;
    const gap = 7.0;
    var lineY = _inset + 24;

    final widths = <double>[0.42, 0.88, 0.76, 0.52];
    for (var i = 0; i < widths.length; i++) {
      final w = lineW * widths[i];
      final lineRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(lineLeft, lineY, w, lineH),
        const Radius.circular(2),
      );
      if (highlightLineIndex == i) {
        final hl = RRect.fromRectAndRadius(
          Rect.fromLTWH(
            lineLeft + lineW * 0.14,
            lineY - 2,
            lineW * 0.62,
            lineH + 4,
          ),
          const Radius.circular(3),
        );
        canvas.drawRRect(
          hl,
          Paint()..color = const Color(0xFFFFC107).withValues(alpha: 0.42),
        );
      }
      canvas.drawRRect(
        lineRect,
        Paint()..color = lineColor.withValues(alpha: 0.28),
      );
      lineY += lineH + gap;
    }

    if (showWaitDots) {
      final base = Offset(lineRight - 4, size.height - _inset - 8);
      for (var i = 0; i < 3; i++) {
        canvas.drawCircle(
          Offset(base.dx - i * 9.0, base.dy),
          2.5,
          Paint()..color = lineColor.withValues(alpha: 0.55),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant FakeDocLinesPainter oldDelegate) =>
      oldDelegate.bg != bg ||
      oldDelegate.stroke != stroke ||
      oldDelegate.lineColor != lineColor ||
      oldDelegate.highlightLineIndex != highlightLineIndex ||
      oldDelegate.showWaitDots != showWaitDots;
}

/// Ctrl + Shift + X row for OCR step 1 schematic.
class OcrHotkeyPainter extends CustomPainter {
  OcrHotkeyPainter({
    required this.keyBg,
    required this.keyBorder,
    required this.labelColor,
  });

  final Color keyBg;
  final Color keyBorder;
  final Color labelColor;

  @override
  void paint(Canvas canvas, Size size) {
    void drawKey(String text, Rect r) {
      final rr = RRect.fromRectAndRadius(r, const Radius.circular(4));
      canvas.drawRRect(rr, Paint()..color = keyBg);
      canvas.drawRRect(
        rr,
        Paint()
          ..color = keyBorder
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
      final tp = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            color: labelColor,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        Offset(
          r.left + (r.width - tp.width) / 2,
          r.top + (r.height - tp.height) / 2,
        ),
      );
    }

    void drawPlus(double cx, double cy) {
      final plus = TextPainter(
        text: TextSpan(
          text: '+',
          style: TextStyle(
            color: labelColor.withValues(alpha: 0.72),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      plus.paint(
        canvas,
        Offset(cx - plus.width / 2, cy - plus.height / 2),
      );
    }

    final midY = size.height / 2 - 2;
    final keyH = 28.0;
    drawKey('Ctrl', Rect.fromLTWH(size.width * 0.06, midY - keyH / 2, 38, keyH));
    drawPlus(size.width * 0.28, midY);
    drawKey('Shift', Rect.fromLTWH(size.width * 0.32, midY - keyH / 2, 44, keyH));
    drawPlus(size.width * 0.56, midY);
    drawKey('X', Rect.fromLTWH(size.width * 0.60, midY - keyH / 2, 28, keyH));
  }

  @override
  bool shouldRepaint(covariant OcrHotkeyPainter oldDelegate) =>
      oldDelegate.keyBg != keyBg ||
      oldDelegate.keyBorder != keyBorder ||
      oldDelegate.labelColor != labelColor;
}

/// Dimmed fullscreen overlay with a dashed capture rectangle (OCR step 2).
class OcrRegionOverlayPainter extends CustomPainter {
  OcrRegionOverlayPainter({
    required this.dimColor,
    required this.innerFill,
    required this.stroke,
    required this.accent,
  });

  final Color dimColor;
  final Color innerFill;
  final Color stroke;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final inner = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.14,
        size.height * 0.14,
        size.width * 0.62,
        size.height * 0.58,
      ),
      const Radius.circular(4),
    );

    final outer = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final hole = Path()..addRRect(inner);
    final overlay = Path.combine(PathOperation.difference, outer, hole);
    canvas.drawPath(overlay, Paint()..color = dimColor);

    canvas.drawRRect(inner, Paint()..color = innerFill.withValues(alpha: 0.92));
    final dashed = Paint()
      ..color = accent.withValues(alpha: 0.95)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    _strokeDashRRect(canvas, inner, dashed, dashLength: 6, gapLength: 4);

    final hint = TextPainter(
      text: TextSpan(
        text: '⋯',
        style: TextStyle(
          color: accent.withValues(alpha: 0.85),
          fontSize: 22,
          letterSpacing: 2,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    hint.paint(
      canvas,
      Offset(
        inner.outerRect.center.dx - hint.width / 2,
        inner.outerRect.center.dy - hint.height / 2,
      ),
    );
  }

  void _strokeDashRRect(
    Canvas canvas,
    RRect r,
    Paint paint, {
    required double dashLength,
    required double gapLength,
  }) {
    final path = Path()..addRRect(r);
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        final next = (d + dashLength).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(d, next), paint);
        d = next + gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(covariant OcrRegionOverlayPainter oldDelegate) =>
      oldDelegate.dimColor != dimColor ||
      oldDelegate.innerFill != innerFill ||
      oldDelegate.stroke != stroke ||
      oldDelegate.accent != accent;
}

/// Popup silhouette emphasizing OCR-style lines for step 3.
class OcrResultPanelPainter extends CustomPainter {
  OcrResultPanelPainter({
    required this.bg,
    required this.stroke,
    required this.accent,
  });

  final Color bg;
  final Color stroke;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final outer = RRect.fromRectAndRadius(
      Rect.fromLTWH(8, 6, size.width - 16, size.height - 14),
      const Radius.circular(8),
    );
    canvas.drawRRect(outer, Paint()..color = bg);
    canvas.drawRRect(
      outer,
      Paint()
        ..color = stroke
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    final header = Rect.fromLTWH(14, 12, size.width - 28, 10);
    canvas.drawRRect(
      RRect.fromRectAndRadius(header, const Radius.circular(3)),
      Paint()..color = accent.withValues(alpha: 0.35),
    );

    var y = 28.0;
    final linePaint = Paint()..color = stroke.withValues(alpha: 0.45);
    for (var i = 0; i < 3; i++) {
      final w = size.width - 28 - (i == 2 ? 52.0 : 0);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(14, y, w, 6),
          const Radius.circular(2),
        ),
        linePaint,
      );
      y += 12;
    }

    final badge = TextPainter(
      text: TextSpan(
        text: 'OCR',
        style: TextStyle(
          color: accent.withValues(alpha: 0.9),
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    badge.paint(
      canvas,
      Offset(size.width - badge.width - 16, size.height - badge.height - 10),
    );
  }

  @override
  bool shouldRepaint(covariant OcrResultPanelPainter oldDelegate) =>
      oldDelegate.bg != bg ||
      oldDelegate.stroke != stroke ||
      oldDelegate.accent != accent;
}

/// Simple “translation card” silhouette for popup guide steps.
///
/// [highlightedSourceLineIndex] draws an accent tint behind one faux text row
/// (0 = top line), matching the in-popup source selection schematic.
class PopupSchematicPainter extends CustomPainter {
  PopupSchematicPainter({
    required this.bg,
    required this.stroke,
    required this.accent,
    this.highlightedSourceLineIndex,
  });

  final Color bg;
  final Color stroke;
  final Color accent;

  /// 0-based row inside the faux source block; null = no selection highlight.
  final int? highlightedSourceLineIndex;

  @override
  void paint(Canvas canvas, Size size) {
    final outer = RRect.fromRectAndRadius(
      Rect.fromLTWH(8, 6, size.width - 16, size.height - 14),
      const Radius.circular(8),
    );
    canvas.drawRRect(outer, Paint()..color = bg);
    canvas.drawRRect(
      outer,
      Paint()
        ..color = stroke
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    final header = Rect.fromLTWH(14, 12, size.width - 28, 10);
    canvas.drawRRect(
      RRect.fromRectAndRadius(header, const Radius.circular(3)),
      Paint()..color = accent.withValues(alpha: 0.35),
    );

    var y = 28.0;
    for (var i = 0; i < 3; i++) {
      final w = size.width - 28 - (i == 2 ? 40.0 : 0);
      final barRect = Rect.fromLTWH(14, y, w, 6);
      if (highlightedSourceLineIndex == i) {
        final hl = RRect.fromRectAndRadius(
          Rect.fromLTWH(
            barRect.left - 2,
            barRect.top - 4,
            barRect.width + 4,
            barRect.height + 8,
          ),
          const Radius.circular(4),
        );
        canvas.drawRRect(
          hl,
          Paint()..color = accent.withValues(alpha: 0.42),
        );
      }
      canvas.drawRRect(
        RRect.fromRectAndRadius(barRect, const Radius.circular(2)),
        Paint()..color = stroke.withValues(alpha: 0.4),
      );
      y += 12;
    }
  }

  @override
  bool shouldRepaint(covariant PopupSchematicPainter oldDelegate) =>
      oldDelegate.bg != bg ||
      oldDelegate.stroke != stroke ||
      oldDelegate.accent != accent ||
      oldDelegate.highlightedSourceLineIndex != highlightedSourceLineIndex;
}
