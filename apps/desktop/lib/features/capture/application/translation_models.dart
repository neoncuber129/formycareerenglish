/// Shared translation request/result types for translation adapters.
class TranslationRequest {
  const TranslationRequest({
    required this.text,
    this.sourceLanguage,
    this.targetLanguage,
  });

  final String text;

  /// Nullable => app default source when not specified.
  final String? sourceLanguage;

  /// Falls back to the app's default native language.
  final String? targetLanguage;
}

class TranslationResult {
  const TranslationResult({
    required this.translatedText,
    this.detectedSourceLanguage = '',
    this.phonetic = '',
    this.audioUrl = '',
  });

  final String translatedText;
  final String detectedSourceLanguage;
  final String phonetic;
  final String audioUrl;

  static const empty = TranslationResult(translatedText: '');

  TranslationResult copyWith({
    String? translatedText,
    String? detectedSourceLanguage,
    String? phonetic,
    String? audioUrl,
  }) {
    return TranslationResult(
      translatedText: translatedText ?? this.translatedText,
      detectedSourceLanguage:
          detectedSourceLanguage ?? this.detectedSourceLanguage,
      phonetic: phonetic ?? this.phonetic,
      audioUrl: audioUrl ?? this.audioUrl,
    );
  }
}

abstract class TranslationService {
  Future<TranslationResult> translate(TranslationRequest request);
}

/// Default native (target) language for translation when request omits target.
const String kDefaultTranslationNativeLanguage = String.fromEnvironment(
  'FORMYCAREER_NATIVE_LANGUAGE',
  defaultValue: 'vi',
);
