import 'dart:convert';

import 'package:http/http.dart' as http;

/// Outcome of a GTX translate call: rendered text plus optional detected source.
class GtxTranslateResult {
  const GtxTranslateResult({
    required this.translatedText,
    this.detectedSource,
  });

  final String translatedText;
  /// Google-detected source language code, when present (e.g. `en`, `ja`, `zh-cn`).
  final String? detectedSource;
}

/// Lightweight Google Translate HTTP client (`translate.googleapis.com` gtx).
class GtxTranslation {
  GtxTranslation({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static const Duration _timeout = Duration(milliseconds: 1200);

  Future<String> translateLine({
    required String text,
    required String sourceLanguage,
    required String targetLanguage,
  }) async {
    final r = await translateLineDetailed(
      text: text,
      sourceLanguage: sourceLanguage,
      targetLanguage: targetLanguage,
    );
    return r.translatedText;
  }

  Future<GtxTranslateResult> translateLineDetailed({
    required String text,
    required String sourceLanguage,
    required String targetLanguage,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return const GtxTranslateResult(translatedText: '');
    }
    final to = _normalizeGoogleLanguage(targetLanguage, fallback: 'en');
    final from = _normalizeGoogleLanguage(sourceLanguage, fallback: 'auto');
    final uri = Uri.parse(
      'https://translate.googleapis.com/translate_a/single?client=gtx&sl=${Uri.encodeQueryComponent(from)}&tl=${Uri.encodeQueryComponent(to)}&dt=t&q=${Uri.encodeQueryComponent(trimmed)}',
    );
    try {
      final response = await _client.get(uri).timeout(_timeout);
      if (response.statusCode != 200) {
        return const GtxTranslateResult(translatedText: '');
      }
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! List || decoded.length < 3 || decoded[0] is! List) {
        return const GtxTranslateResult(translatedText: '');
      }
      final parts = decoded[0] as List<dynamic>;
      final out = StringBuffer();
      for (final part in parts) {
        if (part is List && part.isNotEmpty && part.first is String) {
          out.write(part.first as String);
        }
      }
      final detected = _parseDetectedSource(decoded);
      return GtxTranslateResult(
        translatedText: out.toString().trim(),
        detectedSource: detected,
      );
    } catch (_) {
      return const GtxTranslateResult(translatedText: '');
    }
  }

  static String? _parseDetectedSource(List<dynamic> decoded) {
    if (decoded.length <= 2) {
      return null;
    }
    final raw = decoded[2];
    if (raw is String && raw.trim().isNotEmpty) {
      return raw.trim().toLowerCase();
    }
    if (raw is List && raw.isNotEmpty) {
      final first = raw.first;
      if (first is String && first.trim().isNotEmpty) {
        return first.trim().toLowerCase();
      }
      if (first is List && first.isNotEmpty && first.first is String) {
        return (first.first as String).trim().toLowerCase();
      }
    }
    return null;
  }

  String _normalizeGoogleLanguage(String raw, {required String fallback}) {
    final code = raw.trim().toLowerCase();
    if (code.isEmpty) {
      return fallback;
    }
    if (code == 'autodetect' || code == 'auto') {
      return 'auto';
    }
    final base = code.split('-').first;
    switch (base) {
      case 'zt':
        return 'zh-TW';
      case 'zh':
        return 'zh-CN';
      default:
        return base;
    }
  }

  void dispose() {
    _client.close();
  }
}

/// Maps Google detected `sl` to the source segment used in [Vocab.languagePair] (`en-vi`, `ja-vi`, …).
String pairSourceCodeFromGoogleDetect(String? detected) {
  if (detected == null || detected.isEmpty) {
    return 'en';
  }
  final c = detected.trim().toLowerCase().replaceAll('_', '-');
  if (c == 'auto') {
    return 'en';
  }
  if (c == 'zt' ||
      c.contains('zh-tw') ||
      c.contains('hant') ||
      c.contains('-tw') ||
      c.contains('hk') ||
      c.contains('mo')) {
    return 'zt';
  }
  if (c.startsWith('zh')) {
    return 'zh';
  }
  final base = c.split('-').first;
  return base.isEmpty ? 'en' : base;
}
