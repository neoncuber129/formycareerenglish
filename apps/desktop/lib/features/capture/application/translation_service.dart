import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import 'playwright_process_translation_service.dart';
import '../../settings/application/settings_service.dart';
import 'translation_models.dart';
import 'translation_process_runner.dart';

export 'translation_models.dart';

const String _dictionaryBaseUrl = String.fromEnvironment(
  'FORMYCAREER_DICTIONARY_BASE_URL',
  defaultValue: 'https://api.dictionaryapi.dev/api/v2/entries/en',
);

const String _kTranslationBackend = String.fromEnvironment(
  'FORMYCAREER_TRANSLATION_BACKEND',
  defaultValue: '',
);

/// Optional English dictionary fields for a single token (dictionaryapi.dev).
class DictionaryGloss {
  const DictionaryGloss({
    this.phonetic = '',
    this.audioUrl = '',
    this.partOfSpeech = '',
    this.shortDefinition = '',
    this.example = '',
  });

  static const empty = DictionaryGloss();

  final String phonetic;
  final String audioUrl;
  final String partOfSpeech;

  /// One short English gloss (not the translated target language).
  final String shortDefinition;
  final String example;
}

/// Fetches phonetic + audio pronunciation for English words.
class DictionaryLookupService {
  DictionaryLookupService({
    required http.Client client,
    this.timeout = const Duration(milliseconds: 1200),
  }) : _client = client;

  final http.Client _client;
  final Duration timeout;

  Future<List<dynamic>?> _fetchDictionaryList(String word) async {
    final input = word.trim();
    if (input.isEmpty || RegExp(r'\s').hasMatch(input)) {
      return null;
    }
    final uri = Uri.parse(
      '$_dictionaryBaseUrl/${Uri.encodeComponent(input.toLowerCase())}',
    );
    try {
      final response = await _client.get(uri).timeout(timeout);
      if (response.statusCode != 200) {
        return null;
      }
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (body is! List || body.isEmpty) {
        return null;
      }
      return body;
    } on TimeoutException {
      debugPrint('Dictionary API timeout');
    } catch (error) {
      debugPrint('Dictionary API error: $error');
    }
    return null;
  }

  /// Phonetic, audio, POS, short English definition, and example sentence.
  Future<DictionaryGloss> lookupGloss(String word) async {
    final body = await _fetchDictionaryList(word);
    if (body == null) {
      return DictionaryGloss.empty;
    }
    String phonetic = '';
    String audioUrl = '';
    String partOfSpeech = '';
    String shortDefinition = '';
    String example = '';

    for (final entry in body) {
      if (entry is! Map<String, dynamic>) continue;
      final directPhonetic = entry['phonetic'];
      if (directPhonetic is String && directPhonetic.trim().isNotEmpty) {
        phonetic = directPhonetic.trim();
      }
      final phonetics = entry['phonetics'];
      if (phonetics is List) {
        for (final p in phonetics) {
          if (p is! Map<String, dynamic>) continue;
          final text = p['text'];
          final audio = p['audio'];
          if (phonetic.isEmpty && text is String && text.trim().isNotEmpty) {
            phonetic = text.trim();
          }
          if (audioUrl.isEmpty && audio is String && audio.trim().isNotEmpty) {
            audioUrl = audio.trim();
          }
        }
      }
      final meanings = entry['meanings'];
      if (meanings is List) {
        for (final m in meanings) {
          if (m is! Map<String, dynamic>) continue;
          final pos = m['partOfSpeech'];
          if (partOfSpeech.isEmpty && pos is String && pos.trim().isNotEmpty) {
            partOfSpeech = pos.trim().toLowerCase();
          }
          final defs = m['definitions'];
          if (defs is! List) continue;
          for (final d in defs) {
            if (d is! Map<String, dynamic>) continue;
            if (shortDefinition.isEmpty) {
              final def = d['definition'];
              if (def is String && def.trim().isNotEmpty) {
                shortDefinition = _clip(def.trim(), 140);
              }
            }
            if (example.isEmpty) {
              final ex = d['example'];
              if (ex is String && ex.trim().isNotEmpty) {
                example = _clip(ex.trim(), 180);
              }
            }
            if (shortDefinition.isNotEmpty && example.isNotEmpty) break;
          }
          if (shortDefinition.isNotEmpty) break;
        }
      }
      break;
    }
    return DictionaryGloss(
      phonetic: phonetic,
      audioUrl: audioUrl,
      partOfSpeech: partOfSpeech,
      shortDefinition: shortDefinition,
      example: example,
    );
  }

  String _clip(String s, int maxChars) {
    if (s.length <= maxChars) return s;
    return '${s.substring(0, maxChars - 1)}…';
  }

  Future<TranslationResult> lookup(String word) async {
    final gloss = await lookupGloss(word);
    if (gloss.phonetic.isEmpty && gloss.audioUrl.isEmpty) {
      return TranslationResult.empty;
    }
    return TranslationResult(
      translatedText: '',
      phonetic: gloss.phonetic,
      audioUrl: gloss.audioUrl,
      detectedSourceLanguage: 'en',
    );
  }
}

final translationHttpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
});

/// Non-empty `FORMYCAREER_TRANSLATION_BACKEND` still forces this code path.
TranslationService _translationServiceForCompileTimeBackend() {
  final backend = _kTranslationBackend.trim().toLowerCase();
  return PlaywrightProcessTranslationService(
    runner: const IoTranslationProcessRunner(),
    mode: backend.contains('deepl')
        ? PlaywrightTranslationMode.deeplWeb
        : PlaywrightTranslationMode.googleWeb,
    defaultTargetLanguage: kDefaultTranslationNativeLanguage,
    fallbackSourceWhenAuto: 'autodetect',
  );
}

TranslationService _translationServiceForUserPreference(
  Ref ref, {
  required TranslationBackendPreference user,
}) {
  final googleHttpPrimary = _GoogleHttpTranslationService(
    client: ref.watch(translationHttpClientProvider),
  );
  final playwrightFallback = PlaywrightProcessTranslationService(
    runner: const IoTranslationProcessRunner(),
    mode: switch (user) {
      TranslationBackendPreference.playwrightGoogleTranslate =>
        PlaywrightTranslationMode.googleWeb,
      TranslationBackendPreference.playwrightDeepLTranslate =>
        PlaywrightTranslationMode.deeplWeb,
    },
    defaultTargetLanguage: kDefaultTranslationNativeLanguage,
    fallbackSourceWhenAuto: 'autodetect',
  );
  // UX policy: keep fast HTTP first, but recover automatically with Playwright.
  return _FallbackTranslationService(
    primary: googleHttpPrimary,
    fallback: playwrightFallback,
  );
}

TranslationService _translationServiceForRef(Ref ref) {
  final envBackend = _kTranslationBackend.trim().toLowerCase();
  if (envBackend.isNotEmpty) {
    return _translationServiceForCompileTimeBackend();
  }
  final user = ref.watch(translationBackendPreferenceProvider);
  return _translationServiceForUserPreference(ref, user: user);
}

final translationServiceProvider = Provider<TranslationService>((ref) {
  return _translationServiceForRef(ref);
});

/// One-line hint for temporary debugging (active engine vs settings / build flag).
final translationEngineDebugLineProvider = Provider<String>((ref) {
  final env = _kTranslationBackend.trim();
  final pref = ref.watch(translationBackendPreferenceProvider);
  final svc = ref.watch(translationServiceProvider);
  final impl = switch (svc) {
    PlaywrightProcessTranslationService() => 'Playwright',
    _FallbackTranslationService() => 'Http->PlaywrightFallback',
    _UnavailableTranslationService() => 'Unavailable',
    _ => svc.runtimeType.toString(),
  };
  final prefLabel = switch (pref) {
    TranslationBackendPreference.playwrightGoogleTranslate =>
      'menu=PlaywrightGoogle',
    TranslationBackendPreference.playwrightDeepLTranslate =>
      'menu=PlaywrightDeepL',
  };
  if (env.isNotEmpty) {
    return 'DBG translate: $impl · $prefLabel · build=$env';
  }
  return 'DBG translate: $impl · $prefLabel';
});

final fragmentRefineTranslationServiceProvider = Provider<TranslationService>(
  (ref) => ref.watch(translationServiceProvider),
);

final dictionaryLookupServiceProvider = Provider<DictionaryLookupService>((
  ref,
) {
  return DictionaryLookupService(
    client: ref.watch(translationHttpClientProvider),
  );
});

class _UnavailableTranslationService implements TranslationService {
  const _UnavailableTranslationService();

  @override
  Future<TranslationResult> translate(TranslationRequest request) async {
    debugPrint(
      'google_translate_web_scrape unavailable: missing playwright bundle',
    );
    return TranslationResult.empty;
  }
}

class _FallbackTranslationService implements TranslationService {
  _FallbackTranslationService({
    required TranslationService primary,
    required TranslationService fallback,
  }) : _primary = primary,
       _fallback = fallback;

  final TranslationService _primary;
  final TranslationService _fallback;

  @override
  Future<TranslationResult> translate(TranslationRequest request) async {
    final first = await _primary.translate(request);
    if (first.translatedText.trim().isNotEmpty) {
      return first;
    }
    return _fallback.translate(request);
  }
}

class _GoogleHttpTranslationService implements TranslationService {
  _GoogleHttpTranslationService({
    required http.Client client,
  }) : _client = client;

  final http.Client _client;
  // macOS network stack (or cold DNS/TLS) can exceed 850ms frequently.
  // Keep this responsive but less brittle than the previous hard cutoff.
  static const Duration timeout = Duration(milliseconds: 2800);

  @override
  Future<TranslationResult> translate(TranslationRequest request) async {
    final text = request.text.trim();
    if (text.isEmpty) {
      return TranslationResult.empty;
    }
    final to = _normalizeGoogleLanguage(
      request.targetLanguage ?? kDefaultTranslationNativeLanguage,
      fallback: kDefaultTranslationNativeLanguage,
    );
    final rawFrom = request.sourceLanguage ?? 'autodetect';
    final from = _normalizeGoogleLanguage(rawFrom, fallback: 'auto');
    final uri = Uri.parse(
      'https://translate.googleapis.com/translate_a/single?client=gtx&sl=${Uri.encodeQueryComponent(from)}&tl=${Uri.encodeQueryComponent(to)}&dt=t&q=${Uri.encodeQueryComponent(text)}',
    );
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        final response = await _client.get(uri).timeout(timeout);
        if (response.statusCode != 200) {
          continue;
        }
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded is! List || decoded.length < 3 || decoded[0] is! List) {
          continue;
        }
        final parts = decoded[0] as List<dynamic>;
        final out = StringBuffer();
        for (final part in parts) {
          if (part is List && part.isNotEmpty && part.first is String) {
            out.write(part.first as String);
          }
        }
        final translated = out.toString().trim();
        if (translated.isEmpty) {
          continue;
        }
        final detected = decoded[2] is String ? (decoded[2] as String).trim() : '';
        return TranslationResult(
          translatedText: translated,
          detectedSourceLanguage: detected.isEmpty ? from : detected,
        );
      } catch (_) {
        // Retry once for transient timeout/network hiccups.
      }
    }
    return TranslationResult.empty;
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
}
