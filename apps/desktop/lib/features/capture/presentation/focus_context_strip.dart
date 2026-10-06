import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/capture_controller.dart';
import '../application/focus_meaning_controller.dart';

/// When the passage is long and focus is a **strict subset**, shows a short
/// excerpt around the focused span (avoids duplicating the full source above).
class FocusContextStrip extends ConsumerWidget {
  const FocusContextStrip({
    this.minPassageLength = 72,
    this.contextRadiusChars = 72,
    super.key,
  });

  final int minPassageLength;
  final int contextRadiusChars;

  /// Visible when strip would add value (excerpt mode, not full duplicate).
  @visibleForTesting
  static bool shouldShow({
    required String passage,
    required int focusStart,
    required int focusEnd,
    int minPassageLength = 72,
  }) {
    if (passage.length < minPassageLength) {
      return false;
    }
    if (focusStart < 0 || focusEnd > passage.length || focusStart >= focusEnd) {
      return false;
    }
    if (focusEnd - focusStart >= passage.length) {
      return false;
    }
    return true;
  }

  /// Builds display string and highlight range within it (for tests / clarity).
  @visibleForTesting
  static ({String text, int hlStart, int hlEnd}) buildExcerpt({
    required String passage,
    required int focusStart,
    required int focusEnd,
    int contextRadiusChars = 72,
  }) {
    final excerptStart =
        (focusStart - contextRadiusChars).clamp(0, passage.length);
    final excerptEnd =
        (focusEnd + contextRadiusChars).clamp(0, passage.length);
    final core = passage.substring(excerptStart, excerptEnd);
    final prefix = excerptStart > 0 ? '…' : '';
    final suffix = excerptEnd < passage.length ? '…' : '';
    final full = '$prefix$core$suffix';
    final hlStart = prefix.length + (focusStart - excerptStart);
    final hlEnd = prefix.length + (focusEnd - excerptStart);
    return (text: full, hlStart: hlStart, hlEnd: hlEnd);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final passage =
        ref.watch(captureControllerProvider.select((s) => s.sourceText));
    final start = ref.watch(focusMeaningProvider.select((f) => f.focusStart));
    final end = ref.watch(focusMeaningProvider.select((f) => f.focusEnd));
    if (!shouldShow(
          passage: passage,
          focusStart: start,
          focusEnd: end,
          minPassageLength: minPassageLength,
        )) {
      return const SizedBox.shrink();
    }
    final excerpt = buildExcerpt(
      passage: passage,
      focusStart: start,
      focusEnd: end,
      contextRadiusChars: contextRadiusChars,
    );
    final theme = Theme.of(context);
    final hl = theme.colorScheme.primaryContainer;
    final onHl = theme.colorScheme.onPrimaryContainer;
    final baseStyle = theme.textTheme.bodySmall?.copyWith(height: 1.35);
    final t = excerpt.text;
    final h0 = excerpt.hlStart.clamp(0, t.length);
    final h1 = excerpt.hlEnd.clamp(0, t.length);
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'In context',
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          SelectableText.rich(
            TextSpan(
              style: baseStyle,
              children: <TextSpan>[
                if (h0 > 0) TextSpan(text: t.substring(0, h0)),
                TextSpan(
                  text: t.substring(h0, h1),
                  style: baseStyle?.copyWith(
                    backgroundColor: hl,
                    color: onHl,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (h1 < t.length) TextSpan(text: t.substring(h1)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
