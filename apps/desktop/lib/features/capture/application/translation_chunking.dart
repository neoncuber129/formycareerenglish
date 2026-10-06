import 'translation_models.dart';

/// Sentence packing + overlap context for long inputs.
class TranslationChunking {
  TranslationChunking._();

  static const int softLimit = 560;
  static const int hardMinSegment = 240;
  static const int hardMaxSegment = 440;

  /// Local translators: avoid huge single segments (memory + latency).
  static bool needsChunkingForLocal(String input) {
    return normalizeWhitespace(input).length > softLimit;
  }

  static String normalizeWhitespace(String input) {
    return input.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  static List<String> splitIntoSentences(String input) {
    final normalized = input.replaceAll('\r\n', '\n');
    final matches = RegExp(
      r'[^.!?;\n]+(?:[.!?;]+|\n+)?',
      multiLine: true,
    ).allMatches(normalized);
    final out = <String>[];
    for (final m in matches) {
      final token = (m.group(0) ?? '').trim();
      if (token.isNotEmpty) {
        out.add(token);
      }
    }
    if (out.isEmpty) {
      return <String>[normalized.trim()];
    }
    return out;
  }

  static List<List<String>> buildChunks(List<String> sentences) {
    final chunks = <List<String>>[];
    var current = <String>[];
    var currentLen = 0;
    for (final sentence in sentences) {
      final nextLen = current.isEmpty
          ? sentence.length
          : currentLen + 1 + sentence.length;
      if (current.isNotEmpty && nextLen > softLimit) {
        chunks.add(current);
        current = <String>[sentence];
        currentLen = sentence.length;
        continue;
      }
      current.add(sentence);
      currentLen = nextLen;
    }
    if (current.isNotEmpty) {
      chunks.add(current);
    }
    return chunks;
  }

  static List<List<String>> coerceHardChunks(String input, int maxChars) {
    final s = normalizeWhitespace(input);
    if (s.isEmpty) {
      return const [];
    }
    final cap = maxChars.clamp(hardMinSegment, hardMaxSegment);
    final parts = <String>[];
    var start = 0;
    while (start < s.length) {
      var end = (start + cap).clamp(start, s.length);
      if (end < s.length) {
        final slice = s.substring(start, end);
        final lastSpace = slice.lastIndexOf(' ');
        if (lastSpace > cap * 2 ~/ 5) {
          end = start + lastSpace + 1;
        }
      }
      final piece = s.substring(start, end).trim();
      if (piece.isNotEmpty) {
        parts.add(piece);
      }
      if (end <= start) {
        end = (start + 1).clamp(0, s.length);
      }
      start = end;
    }
    if (parts.isEmpty) {
      return <List<String>>[
        <String>[s],
      ];
    }
    return parts.map((p) => <String>[p]).toList();
  }

  static String trimContextPrefix({
    required String translated,
    required String translatedContext,
  }) {
    var output = translated.trim();
    final context = translatedContext.trim();
    if (context.isEmpty || output.isEmpty) {
      return output;
    }
    final loweredOut = output.toLowerCase();
    final loweredCtx = context.toLowerCase();
    if (loweredOut.startsWith(loweredCtx)) {
      output = output.substring(context.length).trimLeft();
      if (output.startsWith(RegExp(r'^[-:;,.\n]'))) {
        output = output.substring(1).trimLeft();
      }
    }
    return output;
  }

  /// Chunks [input], calls [translateSegment] per payload, merges pieces.
  static Future<TranslationResult> translateWithChunks({
    required String input,
    required Future<TranslationResult> Function(String text) translateSegment,
    bool monolithicCoerce = true,
  }) async {
    final sentences = splitIntoSentences(input);
    var chunks = buildChunks(sentences);
    if (monolithicCoerce && chunks.length <= 1) {
      final maxSeg = (softLimit * 4 ~/ 5).clamp(hardMinSegment, hardMaxSegment);
      final hardened = coerceHardChunks(input, maxSeg);
      if (hardened.length > 1) {
        chunks = hardened;
      }
    }
    if (chunks.length <= 1) {
      return translateSegment(input.trim());
    }

    final translated = <String>[];
    final contextCache = <String, String>{};
    var detectedSource = '';
    for (var i = 0; i < chunks.length; i += 1) {
      final mainChunk = chunks[i];
      final hasContext = i > 0 && chunks[i - 1].isNotEmpty;
      final context = hasContext ? chunks[i - 1].last.trim() : '';
      final payload = hasContext
          ? '$context\n${mainChunk.join(' ')}'
          : mainChunk.join(' ');
      final result = await translateSegment(payload);
      if (result.translatedText.isEmpty) {
        translated.add(mainChunk.join(' '));
        continue;
      }
      if (detectedSource.isEmpty && result.detectedSourceLanguage.isNotEmpty) {
        detectedSource = result.detectedSourceLanguage;
      }
      var piece = result.translatedText;
      if (hasContext) {
        final translatedContext = await _translatedContextLine(
          context: context,
          cache: contextCache,
          translateSegment: translateSegment,
        );
        piece = trimContextPrefix(
          translated: piece,
          translatedContext: translatedContext,
        );
      }
      translated.add(piece);
    }

    return TranslationResult(
      translatedText: translated
          .join(' ')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim(),
      detectedSourceLanguage: detectedSource,
    );
  }

  static Future<String> _translatedContextLine({
    required String context,
    required Map<String, String> cache,
    required Future<TranslationResult> Function(String text) translateSegment,
  }) async {
    if (context.isEmpty) {
      return '';
    }
    final cached = cache[context];
    if (cached != null) {
      return cached;
    }
    final result = await translateSegment(context);
    final text = result.translatedText.trim();
    cache[context] = text;
    return text;
  }
}
