import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum CaptureInputSource {
  selection,
  ocr,
  none,
}

class SmartCaptureResult {
  const SmartCaptureResult({
    required this.detectedText,
    required this.rawText,
    required this.source,
  });

  final String detectedText;
  final String rawText;
  final CaptureInputSource source;
}

abstract class ClipboardReader {
  Future<String?> readText();
}

class FlutterClipboardReader implements ClipboardReader {
  const FlutterClipboardReader();

  @override
  Future<String?> readText() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    return data?.text;
  }
}

typedef OcrExtractor = Future<String> Function();

const Set<String> _defaultStopwords = <String>{
  'a',
  'an',
  'and',
  'are',
  'as',
  'at',
  'be',
  'but',
  'because',
  'by',
  'for',
  'from',
  'had',
  'has',
  'have',
  'he',
  'her',
  'his',
  'i',
  'in',
  'is',
  'it',
  'its',
  'of',
  'on',
  'or',
  'our',
  'she',
  'that',
  'the',
  'their',
  'them',
  'they',
  'this',
  'to',
  'was',
  'we',
  'were',
  'with',
  'you',
  'your',
  'la',
  'là',
  'nhung',
  'nhưng',
  'va',
  'và',
  'cua',
  'của',
  'cho',
  'voi',
  'với',
  'mot',
  'một',
  'những',
  'cac',
  'các',
  'trong',
  'tren',
  'trên',
  'duoc',
  'được',
  'tu',
  'từ',
  'den',
  'đến',
  'tai',
  'tại',
  'nay',
  'này',
  'do',
  'đó',
  'khi',
  'neu',
  'nếu',
  'thi',
  'thì',
  'rat',
  'rất',
  'da',
  'đã',
  'se',
  'sẽ',
  'khong',
  'không',
  'thể',
};

class SmartCaptureHeuristicConfig {
  const SmartCaptureHeuristicConfig({
    this.clipboardMaxLength = 200,
    this.selectionMaxTokenCount = 3,
    this.selectionMaxLength = 32,
    this.minTokenLength = 2,
    this.maxTokenLength = 24,
    this.stopwordPenalty = 4,
    this.acronymBonus = 2,
    this.titleCaseBonus = 1,
    this.asciiWordBonus = 2,
    this.generalLengthBonus = 1,
    this.mediumLengthBonus = 2,
    this.idealLengthBonus = 4,
    this.idealExtendedBonus = 1,
    this.acronymMinLength = 2,
    this.acronymMaxLength = 6,
    this.stopwords = _defaultStopwords,
  });

  final int clipboardMaxLength;
  final int selectionMaxTokenCount;
  final int selectionMaxLength;
  final int minTokenLength;
  final int maxTokenLength;
  final int stopwordPenalty;
  final int acronymBonus;
  final int titleCaseBonus;
  final int asciiWordBonus;
  final int generalLengthBonus;
  final int mediumLengthBonus;
  final int idealLengthBonus;
  final int idealExtendedBonus;
  final int acronymMinLength;
  final int acronymMaxLength;
  final Set<String> stopwords;
}

SmartCaptureHeuristicConfig buildSmartCaptureHeuristicConfigFromEnvironment({
  Map<String, String>? overrides,
}) {
  int resolveInt(String key, int fallback) {
    final override = overrides?[key];
    if (override != null) {
      return int.tryParse(override) ?? fallback;
    }
    final fromEnv = String.fromEnvironment(key);
    if (fromEnv.isEmpty) {
      return fallback;
    }
    return int.tryParse(fromEnv) ?? fallback;
  }

  Set<String> resolveStopwords(Set<String> fallback) {
    const key = 'FORMYCAREER_CAPTURE_STOPWORDS_CSV';
    final override = overrides?[key];
    final source = override ?? String.fromEnvironment(key);
    if (source.trim().isEmpty) {
      return fallback;
    }
    final tokens = source
        .split(',')
        .map((part) => part.trim().toLowerCase())
        .where((part) => part.isNotEmpty)
        .toSet();
    return tokens.isEmpty ? fallback : tokens;
  }

  return SmartCaptureHeuristicConfig(
    clipboardMaxLength: resolveInt(
      'FORMYCAREER_CAPTURE_CLIPBOARD_MAX_LENGTH',
      200,
    ),
    selectionMaxTokenCount: resolveInt(
      'FORMYCAREER_CAPTURE_SELECTION_MAX_TOKENS',
      3,
    ),
    selectionMaxLength: resolveInt(
      'FORMYCAREER_CAPTURE_SELECTION_MAX_LENGTH',
      32,
    ),
    minTokenLength: resolveInt(
      'FORMYCAREER_CAPTURE_MIN_TOKEN_LENGTH',
      2,
    ),
    maxTokenLength: resolveInt(
      'FORMYCAREER_CAPTURE_MAX_TOKEN_LENGTH',
      24,
    ),
    stopwordPenalty: resolveInt(
      'FORMYCAREER_CAPTURE_STOPWORD_PENALTY',
      4,
    ),
    acronymBonus: resolveInt(
      'FORMYCAREER_CAPTURE_ACRONYM_BONUS',
      2,
    ),
    titleCaseBonus: resolveInt(
      'FORMYCAREER_CAPTURE_TITLECASE_BONUS',
      1,
    ),
    asciiWordBonus: resolveInt(
      'FORMYCAREER_CAPTURE_ASCII_BONUS',
      2,
    ),
    generalLengthBonus: resolveInt(
      'FORMYCAREER_CAPTURE_GENERAL_LENGTH_BONUS',
      1,
    ),
    mediumLengthBonus: resolveInt(
      'FORMYCAREER_CAPTURE_MEDIUM_LENGTH_BONUS',
      2,
    ),
    idealLengthBonus: resolveInt(
      'FORMYCAREER_CAPTURE_IDEAL_LENGTH_BONUS',
      4,
    ),
    idealExtendedBonus: resolveInt(
      'FORMYCAREER_CAPTURE_IDEAL_EXTENDED_BONUS',
      1,
    ),
    acronymMinLength: resolveInt(
      'FORMYCAREER_CAPTURE_ACRONYM_MIN_LENGTH',
      2,
    ),
    acronymMaxLength: resolveInt(
      'FORMYCAREER_CAPTURE_ACRONYM_MAX_LENGTH',
      6,
    ),
    stopwords: resolveStopwords(_defaultStopwords),
  );
}

class SmartCaptureService {
  const SmartCaptureService({
    required ClipboardReader clipboardReader,
    SmartCaptureHeuristicConfig config = const SmartCaptureHeuristicConfig(),
  })  : _clipboardReader = clipboardReader,
        _config = config;

  final ClipboardReader _clipboardReader;
  final SmartCaptureHeuristicConfig _config;

  static final RegExp _wordRegex = RegExp(
    r"\p{L}+(?:['-]\p{L}+)?",
    unicode: true,
  );

  Future<SmartCaptureResult> detectBestWord({
    required OcrExtractor ocrExtractor,
  }) async {
    final selectedText = await _safeReadSelection();
    final fromSelection = _pickCandidateFromSelection(selectedText);
    if (fromSelection.isNotEmpty) {
      return SmartCaptureResult(
        detectedText: fromSelection,
        rawText: selectedText ?? '',
        source: CaptureInputSource.selection,
      );
    }

    try {
      final rawOcr = await ocrExtractor();
      final fromOcr = _pickLikelyWord(rawOcr);
      if (fromOcr.isNotEmpty) {
        return SmartCaptureResult(
          detectedText: fromOcr,
          rawText: rawOcr,
          source: CaptureInputSource.ocr,
        );
      }
      return SmartCaptureResult(
        detectedText: '',
        rawText: rawOcr,
        source: CaptureInputSource.none,
      );
    } catch (_) {
      return const SmartCaptureResult(
        detectedText: '',
        rawText: '',
        source: CaptureInputSource.none,
      );
    }
  }

  Future<SmartCaptureResult> detectTextMode({
    required OcrExtractor ocrFallbackExtractor,
  }) async {
    final selectedText = await _safeReadSelection();
    final trimmedSelection = (selectedText ?? '').trim();
    if (trimmedSelection.isNotEmpty) {
      // Full passage from clipboard selection (no single-word picking).
      return SmartCaptureResult(
        detectedText: trimmedSelection,
        rawText: trimmedSelection,
        source: CaptureInputSource.selection,
      );
    }

    try {
      final rawOcr = await ocrFallbackExtractor();
      final trimmed = rawOcr.trim();
      if (trimmed.isNotEmpty) {
        return SmartCaptureResult(
          detectedText: trimmed,
          rawText: trimmed,
          source: CaptureInputSource.ocr,
        );
      }
      return SmartCaptureResult(
        detectedText: '',
        rawText: trimmed,
        source: CaptureInputSource.none,
      );
    } catch (_) {
      return const SmartCaptureResult(
        detectedText: '',
        rawText: '',
        source: CaptureInputSource.none,
      );
    }
  }

  Future<SmartCaptureResult> detectFromOcrOnly({
    required OcrExtractor ocrExtractor,
  }) async {
    try {
      final rawOcr = await ocrExtractor();
      final trimmed = rawOcr.trim();
      if (trimmed.isNotEmpty) {
        return SmartCaptureResult(
          detectedText: trimmed,
          rawText: trimmed,
          source: CaptureInputSource.ocr,
        );
      }
      return SmartCaptureResult(
        detectedText: '',
        rawText: trimmed,
        source: CaptureInputSource.none,
      );
    } catch (_) {
      return const SmartCaptureResult(
        detectedText: '',
        rawText: '',
        source: CaptureInputSource.none,
      );
    }
  }

  Future<String?> _safeReadSelection() async {
    try {
      return await _clipboardReader.readText();
    } catch (_) {
      return null;
    }
  }

  // Kept for backward compatibility in case callers want a single-line form.
  // ignore: unused_element
  String _normalize(String input) {
    return input.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  // ignore: unused_element
  String _pickCandidateFromSelection(String? selectedText) {
    if (selectedText == null || selectedText.trim().isEmpty) {
      return '';
    }
    final normalized = selectedText.trim().replaceAll(RegExp(r'\s+'), ' ');
    final tokenCount = normalized.split(' ').length;
    if (tokenCount <= _config.selectionMaxTokenCount &&
        normalized.length <= _config.selectionMaxLength) {
      return _pickLikelyWord(normalized);
    }
    return '';
  }

  /// Character range `[start, end)` of the heuristic default word for
  /// interactive popup focus (CJK: may be one grapheme cluster per token).
  ///
  /// When the passage is "long" by the same rules as [_pickCandidateFromSelection]
  /// (`selectionMaxTokenCount` / `selectionMaxLength`), returns [null] so callers
  /// default to translating the full passage.
  ({int start, int end})? pickDefaultFocusSpan(String passage) {
    final normalized = passage.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (normalized.isEmpty) {
      return null;
    }
    final tokenCount = normalized.split(' ').length;
    if (tokenCount > _config.selectionMaxTokenCount ||
        normalized.length > _config.selectionMaxLength) {
      return null;
    }
    final candidate = _pickLikelyTokenCandidate(passage);
    if (candidate == null) {
      return null;
    }
    final end = candidate.index + candidate.token.length;
    return (start: candidate.index, end: end);
  }

  _TokenCandidate? _pickLikelyTokenCandidate(
    String rawText, {
    bool allowStopwordFallback = true,
  }) {
    if (rawText.trim().isEmpty) {
      return null;
    }

    final tokens = _wordRegex
        .allMatches(rawText)
        .map(
          (match) => _TokenCandidate(
            token: match.group(0) ?? '',
            index: match.start,
            isSentenceStart: _isSentenceStart(rawText, match.start),
          ),
        )
        .where(
          (token) =>
              token.token.length >= _config.minTokenLength &&
              token.token.length <= _config.maxTokenLength,
        )
        .toList();
    if (tokens.isEmpty) {
      return null;
    }

    final nonStopwordTokens = tokens
        .where((token) => !_config.stopwords.contains(token.normalized))
        .toList();
    if (nonStopwordTokens.isEmpty && !allowStopwordFallback) {
      return null;
    }
    final candidates = nonStopwordTokens.isNotEmpty ? nonStopwordTokens : tokens;
    candidates.sort((a, b) {
      final scoreDelta = _score(b).compareTo(_score(a));
      if (scoreDelta != 0) {
        return scoreDelta;
      }
      return a.index.compareTo(b.index);
    });
    return candidates.first;
  }

  String _pickLikelyWord(
    String rawText, {
    bool allowStopwordFallback = true,
  }) {
    final candidate = _pickLikelyTokenCandidate(
      rawText,
      allowStopwordFallback: allowStopwordFallback,
    );
    return candidate?.token ?? '';
  }

  int _score(_TokenCandidate token) {
    var score = 0;
    final value = token.token;
    final lowercase = token.normalized;
    if (value.length >= 4 && value.length <= 12) {
      score += _config.idealLengthBonus;
    } else if (value.length >= 3 && value.length <= 16) {
      score += _config.mediumLengthBonus;
    }
    if (value.length >= 8 && value.length <= 12) {
      score += _config.idealExtendedBonus;
    }
    if (value.length >= 2) {
      score += _config.generalLengthBonus;
    }
    if (RegExp(r'^[A-Za-z]+$').hasMatch(value)) {
      score += _config.asciiWordBonus;
    }
    if (_config.stopwords.contains(lowercase)) {
      score -= _config.stopwordPenalty;
    }
    final isAcronym = RegExp(
      '^[A-Z]{${_config.acronymMinLength},${_config.acronymMaxLength}}\$',
    ).hasMatch(value);
    if (isAcronym) {
      score += _config.acronymBonus;
    }
    final isTitleCaseWord = value.length >= 4 &&
        RegExp(r'^\p{Lu}\p{L}+$', unicode: true).hasMatch(value) &&
        !token.isSentenceStart &&
        !isAcronym;
    if (isTitleCaseWord) {
      score += _config.titleCaseBonus;
    }
    return score;
  }

  bool _isSentenceStart(String text, int tokenStartIndex) {
    if (tokenStartIndex <= 0) {
      return true;
    }
    for (var i = tokenStartIndex - 1; i >= 0; i--) {
      final char = text[i];
      if (char.trim().isEmpty) {
        continue;
      }
      return char == '.' || char == '!' || char == '?' || char == ':' || char == ';';
    }
    return true;
  }
}

class _TokenCandidate {
  const _TokenCandidate({
    required this.token,
    required this.index,
    this.isSentenceStart = false,
  });

  final String token;
  final int index;
  final bool isSentenceStart;

  String get normalized => token.toLowerCase();
}

final clipboardReaderProvider = Provider<ClipboardReader>((ref) {
  return const FlutterClipboardReader();
});

final smartCaptureHeuristicConfigProvider = Provider<SmartCaptureHeuristicConfig>((ref) {
  return buildSmartCaptureHeuristicConfigFromEnvironment();
});

final smartCaptureServiceProvider = Provider<SmartCaptureService>((ref) {
  return SmartCaptureService(
    clipboardReader: ref.watch(clipboardReaderProvider),
    config: ref.watch(smartCaptureHeuristicConfigProvider),
  );
});
