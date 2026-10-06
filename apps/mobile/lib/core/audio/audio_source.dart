/// Helpers for building Google Translate TTS audio URLs and chunking text.
///
/// `translate.google.com/translate_tts` (client=tw-ob) returns an MP3 stream
/// for many languages, but enforces a soft per-request limit and only accepts
/// browser-like User-Agent headers. Splitting long text into ~180 character
/// chunks at sentence/word boundaries keeps every request below the limit and
/// produces natural sounding playback when the chunk MP3s are concatenated in
/// order.
library;

const String googleTtsUserAgent =
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
    '(KHTML, like Gecko) Chrome/124.0 Safari/537.36';

const String _googleTtsBase = 'https://translate.google.com/translate_tts';

/// Maximum characters per TTS request before quality/quotas degrade.
const int kGoogleTtsMaxChunk = 180;

/// Normalises a language code so it matches one of Google's TTS language tags.
///
/// Returns the empty string when the input cannot be mapped (the caller should
/// then fall back to OS TTS). `auto`/`autodetect` map to the empty string
/// because Google's translate_tts endpoint does not accept `auto`.
String normalizeGoogleTtsLanguage(String? raw, {String fallback = 'en'}) {
  final code = (raw ?? '').trim().toLowerCase();
  if (code.isEmpty || code == 'auto' || code == 'autodetect') {
    return fallback;
  }
  final base = code.split(RegExp('[-_]')).first;
  switch (base) {
    case 'zt':
      return 'zh-TW';
    case 'zh':
      // Distinguish between traditional and simplified when explicitly tagged.
      if (code == 'zh-tw' || code == 'zh_tw' || code == 'zh-hant') {
        return 'zh-TW';
      }
      return 'zh-CN';
    case 'iw':
      return 'he';
    case 'jw':
      return 'jv';
    default:
      return base;
  }
}

/// Splits [text] into chunks of at most [maxChunk] characters without breaking
/// words. Tries sentence boundaries first, then falls back to word and finally
/// hard character splits for pathologically long fragments.
List<String> chunkTextForGoogleTts(
  String text, {
  int maxChunk = kGoogleTtsMaxChunk,
}) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) {
    return const [];
  }
  if (trimmed.length <= maxChunk) {
    return [trimmed];
  }

  final result = <String>[];
  final sentences = _splitSentences(trimmed);
  final buffer = StringBuffer();

  void flush() {
    final value = buffer.toString().trim();
    if (value.isNotEmpty) {
      result.add(value);
    }
    buffer.clear();
  }

  for (final sentence in sentences) {
    if (sentence.length > maxChunk) {
      flush();
      result.addAll(_splitByWords(sentence, maxChunk));
      continue;
    }
    if (buffer.length + sentence.length + 1 > maxChunk) {
      flush();
    }
    if (buffer.isNotEmpty) {
      buffer.write(' ');
    }
    buffer.write(sentence);
  }
  flush();
  return result;
}

/// Builds a list of `translate_tts` URLs ready to be downloaded sequentially.
List<String> buildGoogleTtsUrls(
  String text,
  String? language, {
  int maxChunk = kGoogleTtsMaxChunk,
}) {
  final chunks = chunkTextForGoogleTts(text, maxChunk: maxChunk);
  if (chunks.isEmpty) {
    return const [];
  }
  final lang = normalizeGoogleTtsLanguage(language);
  if (lang.isEmpty) {
    return const [];
  }
  final total = chunks.length;
  return [
    for (var i = 0; i < total; i++)
      _buildGoogleTtsUrl(chunks[i], lang, index: i, total: total),
  ];
}

String _buildGoogleTtsUrl(
  String chunk,
  String language, {
  required int index,
  required int total,
}) {
  final params = <String, String>{
    'ie': 'UTF-8',
    'client': 'tw-ob',
    'tl': language,
    'q': chunk,
    'total': total.toString(),
    'idx': index.toString(),
    'textlen': chunk.length.toString(),
  };
  final query = params.entries
      .map((entry) =>
          '${Uri.encodeQueryComponent(entry.key)}=${Uri.encodeQueryComponent(entry.value)}')
      .join('&');
  return '$_googleTtsBase?$query';
}

List<String> _splitSentences(String text) {
  final pattern = RegExp(r'[^.!?\n\r]+[.!?]?');
  final matches = pattern
      .allMatches(text)
      .map((match) => match.group(0)?.trim() ?? '')
      .where((part) => part.isNotEmpty)
      .toList(growable: false);
  if (matches.isEmpty) {
    return [text];
  }
  return matches;
}

List<String> _splitByWords(String sentence, int maxChunk) {
  final words = sentence.split(RegExp(r'\s+'));
  final out = <String>[];
  final buffer = StringBuffer();
  for (final word in words) {
    if (word.isEmpty) continue;
    if (word.length > maxChunk) {
      if (buffer.isNotEmpty) {
        out.add(buffer.toString().trim());
        buffer.clear();
      }
      var start = 0;
      while (start < word.length) {
        final end = (start + maxChunk).clamp(0, word.length);
        out.add(word.substring(start, end));
        start = end;
      }
      continue;
    }
    if (buffer.length + word.length + 1 > maxChunk) {
      out.add(buffer.toString().trim());
      buffer.clear();
    }
    if (buffer.isNotEmpty) {
      buffer.write(' ');
    }
    buffer.write(word);
  }
  if (buffer.isNotEmpty) {
    out.add(buffer.toString().trim());
  }
  return out;
}

/// Backend selection for TTS. `auto` lets the resolver decide based on the
/// available URL sources; `google` forces translate_tts; `os` skips the
/// network resolver entirely.
enum TtsBackendChoice { auto, google, os }

TtsBackendChoice ttsBackendFromString(String? raw) {
  switch ((raw ?? '').trim().toLowerCase()) {
    case 'google':
    case 'gtrans':
    case 'translate':
      return TtsBackendChoice.google;
    case 'os':
    case 'native':
    case 'sapi':
    case 'say':
    case 'flutter_tts':
      return TtsBackendChoice.os;
    default:
      return TtsBackendChoice.auto;
  }
}
