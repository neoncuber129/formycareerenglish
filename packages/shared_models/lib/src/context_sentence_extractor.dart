/// Extracts the sentence (clause) in [passage] that contains the substring
/// defined by [[termStart], [termEnd]) or the first occurrence of [term].
class ContextSentenceExtractor {
  const ContextSentenceExtractor._();

  /// Returns a trimmed sentence containing the span, or [passage] trimmed if
  /// indices are invalid. Uses `.?!` and newlines as soft boundaries.
  static String sentenceContaining({
    required String passage,
    required String term,
    int? termStart,
    int? termEnd,
  }) {
    final p = passage;
    if (p.isEmpty) {
      return '';
    }
    final t = term;
    int start;
    int end;
    if (termStart != null &&
        termEnd != null &&
        termStart >= 0 &&
        termEnd <= p.length &&
        termStart < termEnd) {
      start = termStart;
      end = termEnd;
    } else if (t.isEmpty) {
      return p.trim();
    } else {
      final idx = p.toLowerCase().indexOf(t.toLowerCase());
      if (idx < 0) {
        return p.trim();
      }
      start = idx;
      end = idx + t.length;
    }

    final left = _scanLeftBoundary(p, start);
    final right = _scanRightBoundary(p, end);
    return p.substring(left, right).trim();
  }

  static int _scanLeftBoundary(String text, int from) {
    if (from <= 0) {
      return 0;
    }
    for (var i = from - 1; i >= 0; i--) {
      final c = text[i];
      if (c == '\n' || c == '\r') {
        return i + 1;
      }
      if (c == '.' || c == '!' || c == '?') {
        return i + 1;
      }
    }
    return 0;
  }

  static int _scanRightBoundary(String text, int from) {
    if (from >= text.length) {
      return text.length;
    }
    for (var i = from; i < text.length; i++) {
      final c = text[i];
      if (c == '\n' || c == '\r') {
        return i;
      }
      if (c == '.' || c == '!' || c == '?') {
        return i + 1;
      }
    }
    return text.length;
  }
}
