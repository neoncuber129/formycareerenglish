import 'package:flutter/painting.dart';

/// Case-insensitive token match: [needle] is not immediately preceded or followed
/// by a Unicode letter or number (punctuation and boundaries allowed).
///
/// This avoids matching `cat` inside `catalog` while still matching
/// `Implementation,` when [needle] is `implementation`.
RegExp _clozeTermPattern(String needle) {
  final escaped = RegExp.escape(needle);
  return RegExp(
    "(?<![\\p{L}\\p{N}'’\\-])$escaped(?![\\p{L}\\p{N}'’\\-])",
    caseSensitive: false,
    unicode: true,
  );
}

/// Counts non-overlapping occurrences of [term] in [sentence] using the same
/// rules as [formatClozeSentence].
int countClozeMatches(String sentence, String term) {
  final needle = term.trim();
  if (needle.isEmpty) {
    return 0;
  }
  final re = _clozeTermPattern(needle);
  return re.allMatches(sentence).length;
}

/// Builds a [TextSpan] tree for a cloze-style question: every case-insensitive
/// occurrence of [term] in [sentence] is replaced by [placeholder] using
/// [clozeStyle] (accent + underline when [clozeStyle] is omitted, underline +
/// bold on top of [baseStyle]).
///
/// Original casing and punctuation outside the matched substring are preserved
/// (e.g. `Implementation,` → `[...]`, with the comma kept).
///
/// When [term] is empty after trim, returns a single span with the full
/// [sentence]. When there is no match, returns one span with [sentence].
TextSpan formatClozeSentence({
  required String sentence,
  required String term,
  required TextStyle baseStyle,
  TextStyle? clozeStyle,
  String placeholder = '[...]',
}) {
  final needle = term.trim();
  if (needle.isEmpty) {
    return TextSpan(text: sentence, style: baseStyle);
  }

  final resolvedCloze = clozeStyle ??
      baseStyle.copyWith(
        decoration: TextDecoration.underline,
        fontWeight: FontWeight.w700,
      );

  final re = _clozeTermPattern(needle);
  final children = <InlineSpan>[];
  var from = 0;
  for (final m in re.allMatches(sentence)) {
    final i = m.start;
    final end = m.end;
    if (i > from) {
      children.add(TextSpan(text: sentence.substring(from, i), style: baseStyle));
    }
    children.add(TextSpan(text: placeholder, style: resolvedCloze));
    from = end;
  }
  if (from < sentence.length) {
    children.add(TextSpan(text: sentence.substring(from), style: baseStyle));
  }

  if (children.isEmpty) {
    return TextSpan(text: sentence, style: baseStyle);
  }
  return TextSpan(children: children);
}
