/// A substring of the source passage together with its character range.
class FocusedSpan {
  const FocusedSpan({
    required this.text,
    required this.start,
    required this.end,
  });

  final String text;
  final int start;
  final int end;

  String get trimmed => text.trim();

  bool get isValidRange =>
      start >= 0 && end >= start && end <= 1 << 30; // loose upper bound
}
