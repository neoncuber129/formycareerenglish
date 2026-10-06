import 'dart:math' as math;

import 'package:app_l10n/app_l10n.dart';
import 'package:flutter/material.dart';

import '../application/focus_meaning_controller.dart';
import 'meaning_panel.dart';

/// Horizontal inset inside the source tinted panel ([InteractiveSourceField]).
double capturePopupSourceInnerHorizontalPadding(double tf) =>
    (8 * tf).clamp(5.0, 14.0);

double capturePopupInnerColumnWidth(double popupWidth, double outerPad) =>
    math.max(0.0, popupWidth - outerPad * 2);

double capturePopupSourceFieldWidth(double popupWidth, double outerPad, double tf) {
  final inner = capturePopupInnerColumnWidth(popupWidth, outerPad);
  final h = capturePopupSourceInnerHorizontalPadding(tf);
  return math.max(48.0, inner - 2 * h).clamp(48.0, inner);
}

/// Minimum inner column width so the source toolbar row does not clip.
double capturePopupMinInnerColumnWidthForToolbar({
  required ThemeData theme,
  required TextScaler textScaler,
  required AppLocalizations l10n,
  required double tf,
  required bool hasWholeLineButton,
  required bool showPassageListen,
}) {
  final iconS = (15 * tf).clamp(13.0, 24.0);
  final gapSmall = (4 * tf.clamp(0.85, 1.35));
  final playOuter =
      ((18 * tf).clamp(16.0, 32.0) + 8).clamp(22.0, 44.0);
  final closeOuter = (iconS + 24).clamp(36.0, 52.0);

  var trailing = gapSmall + closeOuter;
  if (showPassageListen) {
    trailing += gapSmall + playOuter;
  }
  if (hasWholeLineButton) {
    final labelStyle =
        theme.textTheme.labelLarge ?? theme.textTheme.bodyMedium!;
    final tp = TextPainter(
      text: TextSpan(text: l10n.captureWholeLine, style: labelStyle),
      textDirection: TextDirection.ltr,
      textScaler: textScaler,
    )..layout();
    final buttonBody = iconS + 8 + tp.width;
    trailing += buttonBody + gapSmall;
  }
  return trailing.ceilToDouble().clamp(158.0, 620.0);
}

/// Minimum inner column width so the save button, tag field (with trailing icons),
/// and auto-tag switch row fit without horizontal overflow (all locales / text scale).
double capturePopupMinInnerColumnWidthForFooterChrome({
  required ThemeData theme,
  required TextScaler textScaler,
  required AppLocalizations l10n,
  required double tf,
}) {
  final iconS = (16 * tf).clamp(14.0, 28.0);
  final labelStyle = (theme.textTheme.labelLarge ?? theme.textTheme.bodyMedium!)
      .copyWith(fontWeight: FontWeight.w500);
  double saveWidthFor(String label) {
    final tp = TextPainter(
      text: TextSpan(text: label, style: labelStyle),
      textDirection: TextDirection.ltr,
      textScaler: textScaler,
      maxLines: 1,
    )..layout(maxWidth: double.infinity);
    // FilledButton.icon (M3): generous horizontal insets + icon + gap + label.
    return (32 + iconS + 12 + tp.width + 32).ceilToDouble();
  }

  final saveLinePhrase = math.max(
    saveWidthFor(l10n.captureSaveLine),
    saveWidthFor(l10n.captureSavePhrase),
  );
  final saveFloor = (248 * tf).clamp(236.0, 392.0);
  final saveW = math.max(saveLinePhrase, saveFloor);

  final tagLabelTp = TextPainter(
    text: TextSpan(
      text: l10n.captureAddTagLabel,
      style: theme.textTheme.bodyMedium,
    ),
    textDirection: TextDirection.ltr,
    textScaler: textScaler,
    maxLines: 1,
  )..layout(maxWidth: double.infinity);

  final tfC = tf.clamp(0.9, 1.2);
  final suffixIcons =
      (142 * tfC).clamp(132.0, 164.0);
  final fieldPadding = (48 * tfC).clamp(40.0, 60.0);
  final tagRow = tagLabelTp.width + suffixIcons + fieldPadding;

  final subtleStyle = theme.textTheme.bodySmall?.copyWith(
    fontSize: (theme.textTheme.bodySmall?.fontSize ?? 12) * 0.94,
    height: 1.2,
  );
  final autoTp = TextPainter(
    text: TextSpan(
      text: l10n.captureAutoRecentTag,
      style: subtleStyle,
    ),
    textDirection: TextDirection.ltr,
    textScaler: textScaler,
    maxLines: 1,
  )..layout(maxWidth: double.infinity);
  final switchReserve = (60 * tfC).clamp(54.0, 74.0);
  final switchRow = autoTp.width + switchReserve;

  return math
      .max(saveW, math.max(tagRow, switchRow))
      .ceilToDouble()
      .clamp(304.0, 620.0);
}

/// Extra inner width when the meaning panel already shows gloss / examples /
/// loading — avoids a too-narrow column on the first frame with cached translations.
double capturePopupMeaningPanelComfortInnerWidth({
  required double tf,
  required FocusMeaningState focus,
}) {
  final busy =
      focus.translatedText.trim().isNotEmpty ||
      focus.microExplanation.trim().isNotEmpty ||
      focus.exampleSentence.trim().isNotEmpty ||
      focus.languagePair.trim().isNotEmpty ||
      focus.isLoading ||
      focus.translateDailyQuotaExceeded;
  if (!busy) {
    return 0;
  }
  return (308 * tf).clamp(292.0, 452.0);
}

double capturePopupMeaningHeadMinInnerWidth({
  required ThemeData theme,
  required TextScaler textScaler,
  required AppLocalizations l10n,
  required FocusMeaningState focus,
  required String sourceText,
}) {
  final hasSpecificSelection =
      sourceText.isNotEmpty &&
      focus.focusStart >= 0 &&
      focus.focusEnd <= sourceText.length &&
      focus.focusStart < focus.focusEnd &&
      (focus.focusEnd - focus.focusStart) < sourceText.length;
  final wordLine =
      hasSpecificSelection ? MeaningPanel.wordOrPhraseLabel(focus, l10n) : '';
  if (wordLine.isEmpty) {
    return 0;
  }
  final tt = theme.textTheme;
  final cs = theme.colorScheme;
  final tp = TextPainter(
    text: TextSpan(
      text: wordLine,
      style: tt.titleSmall?.copyWith(
        letterSpacing: 0.2,
        color: cs.onSurface,
      ),
    ),
    textDirection: TextDirection.ltr,
    textScaler: textScaler,
    maxLines: MeaningPanel.isPhrase(focus.focusedText) ? 4 : 2,
  )..layout(maxWidth: double.infinity);

  // Reserve play affordance while translating too — UI hides the button until
  // [!isLoading] but width must not shrink vs the steady state (cached meaning).
  final playReserve =
      focus.focusedText.trim().isNotEmpty ? 52.0 : 0.0;
  final ipaRaw = focus.pronunciation.trim();
  var ipaReserve = 0.0;
  if (ipaRaw.isNotEmpty) {
    final ipaText =
        ipaRaw.startsWith('/') && ipaRaw.endsWith('/') ? ipaRaw : '/$ipaRaw/';
    final ipaTp = TextPainter(
      text: TextSpan(
        text: ipaText,
        style: tt.bodySmall?.copyWith(
          fontStyle: FontStyle.italic,
          color: cs.onSurfaceVariant,
        ),
      ),
      textDirection: TextDirection.ltr,
      textScaler: textScaler,
    )..layout(maxWidth: double.infinity);
    ipaReserve = 8 + ipaTp.width;
  }
  return (tp.width + playReserve + ipaReserve).clamp(0.0, 4000.0);
}

/// Width the source passage would take on a single line (uncapped).
double capturePopupSourceUncappedSingleLineWidth({
  required ThemeData theme,
  required TextScaler textScaler,
  required AppLocalizations l10n,
  required String passage,
}) {
  final tt = theme.textTheme;
  final cs = theme.colorScheme;
  if (passage.trim().isEmpty) {
    final tp = TextPainter(
      text: TextSpan(
        text: l10n.captureNoTextDetected,
        style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
      ),
      textDirection: TextDirection.ltr,
      textScaler: textScaler,
      maxLines: 4,
    )..layout(maxWidth: double.infinity);
    return tp.width.ceilToDouble().clamp(48.0, 1200.0);
  }
  final sourceStyle = (tt.bodyLarge ?? tt.bodyMedium)?.copyWith(
    fontWeight: FontWeight.w500,
    height: 1.45,
    color: cs.onSurface,
  );
  final tp = TextPainter(
    text: TextSpan(text: passage, style: sourceStyle),
    textDirection: TextDirection.ltr,
    textScaler: textScaler,
  )..layout(maxWidth: double.infinity);
  return tp.width.ceilToDouble().clamp(48.0, 12000.0);
}

/// Minimum [InteractiveSourceField] inner width so one comfortable source line fits,
/// even when the captured span is a single short word (intrinsic width would collapse).
double capturePopupSourceFieldMinWidthOneLine(double tf, double maxField) {
  final floor = (312 * tf).clamp(292.0, 420.0);
  return math.min(floor, maxField).clamp(48.0, maxField);
}

/// Popup width from source toolbar + intrinsic source line width + meaning header row,
/// clamped to [lowerBound]–[upperBound]. Meaning column matches this width (≥ source field).
double capturePopupResolvePreferredWidth({
  required ThemeData theme,
  required TextScaler textScaler,
  required AppLocalizations l10n,
  required double outerPad,
  required double tf,
  required String passage,
  required FocusMeaningState focus,
  required String sourceText,
  required bool hasWholeLineButton,
  required bool showPassageListen,
  double lowerBound = 428,
  double upperBound = 580,
}) {
  final hPad = capturePopupSourceInnerHorizontalPadding(tf);
  final maxInner = capturePopupInnerColumnWidth(upperBound, outerPad);
  final footerChromeInner = capturePopupMinInnerColumnWidthForFooterChrome(
    theme: theme,
    textScaler: textScaler,
    l10n: l10n,
    tf: tf,
  );
  // Whole-line capture shows listen after [!isLoading]; reserve space whenever we
  // are not in phrase-selection mode so first paint matches post-translate chrome.
  final toolbarListenChrome =
      showPassageListen ||
      (sourceText.isNotEmpty && !hasWholeLineButton);
  final toolbarInner = capturePopupMinInnerColumnWidthForToolbar(
    theme: theme,
    textScaler: textScaler,
    l10n: l10n,
    tf: tf,
    hasWholeLineButton: hasWholeLineButton,
    showPassageListen: toolbarListenChrome,
  );
  final rawLine =
      capturePopupSourceUncappedSingleLineWidth(
        theme: theme,
        textScaler: textScaler,
        l10n: l10n,
        passage: passage,
      );
  final maxField =
      math.max(48.0, maxInner - 2 * hPad).clamp(48.0, maxInner);
  final intrinsicField =
      math.min(rawLine, maxField).clamp(48.0, maxField);
  final oneLineFloor = capturePopupSourceFieldMinWidthOneLine(tf, maxField);
  final desiredField = math.max(intrinsicField, oneLineFloor);
  final meaningHead = capturePopupMeaningHeadMinInnerWidth(
    theme: theme,
    textScaler: textScaler,
    l10n: l10n,
    focus: focus,
    sourceText: sourceText,
  );
  final meaningComfort = capturePopupMeaningPanelComfortInnerWidth(
    tf: tf,
    focus: focus,
  );
  final desiredInner = math
      .max(
        toolbarInner,
        math.max(
          desiredField + 2 * hPad,
          math.max(
            math.max(meaningHead, meaningComfort),
            footerChromeInner,
          ),
        ),
      )
      .clamp(160.0, maxInner);
  final popupW = desiredInner + outerPad * 2;
  final chromeFloorPopup = footerChromeInner + outerPad * 2;
  final comfortFloorPopup =
      meaningComfort > 0 ? meaningComfort + outerPad * 2 : 0.0;
  final boundLo = math.max(lowerBound, math.max(chromeFloorPopup, comfortFloorPopup));
  return popupW.clamp(boundLo, upperBound);
}

/// Lays out [text] with [style] and returns painted height (up to [maxLines]).
double capturePopupMeasureTextHeight(
  TextScaler textScaler, {
  required String text,
  required double maxWidth,
  TextStyle? style,
  int maxLines = 32,
  TextDirection textDirection = TextDirection.ltr,
}) {
  final t = text.trim();
  if (t.isEmpty) {
    return 0;
  }
  final painter = TextPainter(
    text: TextSpan(text: t, style: style),
    textDirection: textDirection,
    maxLines: maxLines,
    textScaler: textScaler,
  )..layout(maxWidth: maxWidth);
  return painter.size.height;
}

/// Mirrors [MeaningPanel] vertical stacking for scroll viewport height.
double capturePopupEstimateMeaningScrollHeight(
  ThemeData theme,
  TextScaler textScaler,
  AppLocalizations l10n, {
  required FocusMeaningState focus,
  required String sourceText,
  required String captureTranslatedText,
  required double maxInnerWidth,
  required bool hasSelectionAction,
}) {
  final cs = theme.colorScheme;
  final tt = theme.textTheme;
  var h = 0.0;

  if (focus.isLoading) {
    // Progress + translating text + spacing.
    h += 68;
  }

  final hasSpecificSelection =
      sourceText.isNotEmpty &&
      focus.focusStart >= 0 &&
      focus.focusEnd <= sourceText.length &&
      focus.focusStart < focus.focusEnd &&
      (focus.focusEnd - focus.focusStart) < sourceText.length;
  final wordLine = hasSpecificSelection
      ? MeaningPanel.wordOrPhraseLabel(focus, l10n)
      : '';

  if (wordLine.isNotEmpty) {
    final rowBudget = (maxInnerWidth - 100).clamp(88.0, maxInnerWidth);
    final rowH = capturePopupMeasureTextHeight(
      textScaler,
      text: wordLine,
      maxWidth: rowBudget,
      style: tt.bodyMedium?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.15,
        height: 1.3,
        color: cs.onSurface,
      ),
      maxLines: MeaningPanel.isPhrase(focus.focusedText) ? 4 : 2,
    ).clamp(22.0, 180.0);
    h += rowH.clamp(36.0, 190.0);
    h += 6;
  }

  final effective = MeaningPanel.effectiveTranslatedMeaning(
    focus: focus,
    sourceText: sourceText,
    captureTranslatedText: captureTranslatedText,
  );
  final isEmptyMeaningLine = !focus.isLoading && effective.trim().isEmpty;
  final micro = focus.microExplanation.trim();
  final echoHasDict =
      !isEmptyMeaningLine &&
      MeaningPanel.isEchoTranslation(effective, focus.focusedText) &&
      micro.isNotEmpty;

  if (echoHasDict) {
    h += capturePopupMeasureTextHeight(
      textScaler,
      text: l10n.meaningDictHeading,
      maxWidth: maxInnerWidth,
      style: tt.labelSmall?.copyWith(
        color: cs.onSurfaceVariant,
        letterSpacing: 0.15,
      ),
      maxLines: 1,
    );
    h += 4;
    h += capturePopupMeasureTextHeight(
      textScaler,
      text: micro,
      maxWidth: maxInnerWidth,
      style: (tt.bodyLarge ?? tt.bodyMedium ?? const TextStyle()).copyWith(
        fontWeight: FontWeight.w500,
        height: 1.4,
        color: cs.onSurface,
      ),
      maxLines: 120,
    );
  } else {
    final translated =
        isEmptyMeaningLine ? l10n.meaningNoTranslationYet : effective;
    final meaningLineColor = isEmptyMeaningLine
        ? cs.onSurfaceVariant
        : cs.onSurface;
    h += capturePopupMeasureTextHeight(
      textScaler,
      text: translated,
      maxWidth: maxInnerWidth,
      style: (tt.bodyLarge ?? tt.bodyMedium ?? const TextStyle()).copyWith(
        fontWeight: isEmptyMeaningLine ? FontWeight.w400 : FontWeight.w500,
        height: 1.4,
        color: meaningLineColor,
      ),
      maxLines: 120,
    );
  }

  if (hasSelectionAction) {
    h += 10 + 48;
  }

  if (micro.isNotEmpty && !echoHasDict) {
    h += 8;
    h += capturePopupMeasureTextHeight(
      textScaler,
      text: micro,
      maxWidth: maxInnerWidth,
      style: tt.bodySmall?.copyWith(height: 1.3, color: cs.onSurfaceVariant),
      maxLines: 120,
    );
  }

  final ex = focus.exampleSentence.trim();
  if (ex.isNotEmpty) {
    h += 6;
    h += capturePopupMeasureTextHeight(
      textScaler,
      text: '"$ex"',
      maxWidth: maxInnerWidth,
      style: tt.bodySmall?.copyWith(
        fontStyle: FontStyle.italic,
        height: 1.3,
        color: cs.onSurface,
      ),
      maxLines: 120,
    );
  }

  if (focus.languagePair.trim().isNotEmpty) {
    h += 8;
    h += capturePopupMeasureTextHeight(
      textScaler,
      text: focus.languagePair.trim(),
      maxWidth: maxInnerWidth,
      style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
      maxLines: 1,
    );
  }

  // Material typography / progress bar can exceed TextPainter estimates slightly.
  return h + 24.0;
}
