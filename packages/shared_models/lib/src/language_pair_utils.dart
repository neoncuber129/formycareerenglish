/// Utilities for parsing `Vocab.languagePair` strings (e.g. `en-vi`).
///
/// The pair encodes `<source>-<target>` where each side is an ISO 639-1
/// language code. Helpers below extract each side and accept a [fallback]
/// override so callers can pick between defaulting to a usable code (TTS) or
/// returning an empty string (filter / option list dedup).
library;

/// Returns the source language code from [pair] (`en-vi` -> `en`).
///
/// When [pair] is empty or malformed (no dash), returns [fallback].
/// Pass `fallback: ''` to keep the legacy "filter-friendly" behaviour where
/// empty pairs are excluded from option lists.
String sourceLanguageFromPair(String pair, {String fallback = 'en'}) {
  final trimmed = pair.trim().toLowerCase();
  if (trimmed.isEmpty) {
    return fallback;
  }
  final dash = trimmed.indexOf('-');
  if (dash < 0) {
    return trimmed;
  }
  if (dash == 0) {
    return fallback;
  }
  final source = trimmed.substring(0, dash);
  return source.isEmpty ? fallback : source;
}

/// Returns the target language code from [pair] (`en-vi` -> `vi`).
///
/// When [pair] is empty / has no dash / has empty target side, returns
/// [fallback] (defaults to `vi`).
String targetLanguageFromPair(String pair, {String fallback = 'vi'}) {
  final trimmed = pair.trim().toLowerCase();
  if (trimmed.isEmpty) {
    return fallback;
  }
  final dash = trimmed.indexOf('-');
  if (dash < 0 || dash >= trimmed.length - 1) {
    return fallback;
  }
  final target = trimmed.substring(dash + 1);
  return target.isEmpty ? fallback : target;
}
