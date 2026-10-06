import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_models/shared_models.dart';

/// Runtime choice for capture / popup translation (ignored when
/// `FORMYCAREER_TRANSLATION_BACKEND` compile-time define is non-empty).
enum TranslationBackendPreference {
  /// Node + Playwright sidecar that automates Google Translate web.
  playwrightGoogleTranslate,

  /// Node + Playwright sidecar that automates DeepL web.
  playwrightDeepLTranslate,
}

TranslationBackendPreference translationBackendPreferenceFromStorage(
  String? raw,
) {
  switch (raw?.trim().toLowerCase()) {
    case 'playwright':
    case 'google':
    case 'google_translate':
    case 'playwright_google':
    case 'playwright_google_translate':
      return TranslationBackendPreference.playwrightGoogleTranslate;
    case 'deepl':
    case 'deepl_translate':
    case 'playwright_deepl':
    case 'playwright_deepl_translate':
      return TranslationBackendPreference.playwrightDeepLTranslate;
    default:
      return TranslationBackendPreference.playwrightGoogleTranslate;
  }
}

extension TranslationBackendPreferenceStorage on TranslationBackendPreference {
  String get storageValue => switch (this) {
    TranslationBackendPreference.playwrightGoogleTranslate =>
      'playwright_google_translate',
    TranslationBackendPreference.playwrightDeepLTranslate =>
      'playwright_deepl_translate',
  };
}

/// Device-local learner profile. Each profile keeps a separate vocabulary library.
class LocalProfile {
  const LocalProfile({
    required this.id,
    required this.displayName,
  });

  final String id;
  final String displayName;

  static const String defaultId = kDefaultLocalProfileId;

  static const LocalProfile defaultProfile = LocalProfile(
    id: defaultId,
    displayName: 'Default',
  );

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'displayName': displayName,
  };

  factory LocalProfile.fromJson(Map<String, dynamic> json) {
    final id = (json['id'] as String?)?.trim() ?? '';
    final name = (json['displayName'] as String?)?.trim() ?? '';
    return LocalProfile(
      id: id.isEmpty ? defaultId : id,
      displayName: name.isEmpty ? 'Profile' : name,
    );
  }

  LocalProfile copyWith({
    String? id,
    String? displayName,
  }) {
    return LocalProfile(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
    );
  }
}

/// Language code (ISO-639-1 style) preferences for the translator.
class LanguageSettings {
  const LanguageSettings({
    required this.nativeLanguage,
    required this.sourceLanguages,
  });

  final String nativeLanguage;
  final List<String> sourceLanguages;

  static const LanguageSettings fallback = LanguageSettings(
    nativeLanguage: 'vi',
    sourceLanguages: <String>['en'],
  );

  LanguageSettings copyWith({
    String? nativeLanguage,
    List<String>? sourceLanguages,
  }) {
    return LanguageSettings(
      nativeLanguage: nativeLanguage ?? this.nativeLanguage,
      sourceLanguages: sourceLanguages ?? this.sourceLanguages,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'nativeLanguage': nativeLanguage,
    'sourceLanguages': sourceLanguages,
  };
}

class LanguageOption {
  const LanguageOption({
    required this.code,
    required this.label,
    required this.tesseractCode,
    this.visionLocaleHints = const <String>[],
  });

  final String code;
  final String label;

  /// Corresponds to a `*.traineddata` filename in Tesseract's tessdata dir.
  final String tesseractCode;
  final List<String> visionLocaleHints;
}

/// Curated list of languages the user can pick as native / source.
const List<LanguageOption> kSupportedLanguages = <LanguageOption>[
  LanguageOption(
    code: 'en',
    label: 'English',
    tesseractCode: 'eng',
    visionLocaleHints: <String>['en'],
  ),
  LanguageOption(
    code: 'vi',
    label: 'Tiếng Việt',
    tesseractCode: 'vie',
    visionLocaleHints: <String>['vi'],
  ),
  LanguageOption(
    code: 'zh',
    label: '中文 (简体)',
    tesseractCode: 'chi_sim',
    visionLocaleHints: <String>['zh-hans', 'zh-cn'],
  ),
  LanguageOption(
    code: 'zt',
    label: '中文 (繁體)',
    tesseractCode: 'chi_tra',
    visionLocaleHints: <String>['zh-hant', 'zh-tw', 'zh-hk'],
  ),
  LanguageOption(
    code: 'ja',
    label: '日本語',
    tesseractCode: 'jpn',
    visionLocaleHints: <String>['ja'],
  ),
  LanguageOption(
    code: 'ko',
    label: '한국어',
    tesseractCode: 'kor',
    visionLocaleHints: <String>['ko'],
  ),
  LanguageOption(
    code: 'fr',
    label: 'Français',
    tesseractCode: 'fra',
    visionLocaleHints: <String>['fr'],
  ),
  LanguageOption(
    code: 'de',
    label: 'Deutsch',
    tesseractCode: 'deu',
    visionLocaleHints: <String>['de'],
  ),
  LanguageOption(
    code: 'es',
    label: 'Español',
    tesseractCode: 'spa',
    visionLocaleHints: <String>['es'],
  ),
  LanguageOption(
    code: 'pt',
    label: 'Português',
    tesseractCode: 'por',
    visionLocaleHints: <String>['pt'],
  ),
  LanguageOption(
    code: 'it',
    label: 'Italiano',
    tesseractCode: 'ita',
    visionLocaleHints: <String>['it'],
  ),
  LanguageOption(
    code: 'ru',
    label: 'Русский',
    tesseractCode: 'rus',
    visionLocaleHints: <String>['ru'],
  ),
  LanguageOption(
    code: 'th',
    label: 'ไทย',
    tesseractCode: 'tha',
    visionLocaleHints: <String>['th'],
  ),
  LanguageOption(
    code: 'id',
    label: 'Bahasa Indonesia',
    tesseractCode: 'ind',
    visionLocaleHints: <String>['id'],
  ),
];

LanguageOption? findLanguageOption(String code) {
  final normalized = code.trim().toLowerCase();
  for (final option in kSupportedLanguages) {
    if (option.code == normalized) return option;
  }
  return null;
}

const MethodChannel _ocrChannel = MethodChannel('formycareer/ocr');

Future<List<LanguageOption>> loadOcrSupportedLanguages() async {
  if (!Platform.isMacOS) {
    return kSupportedLanguages;
  }
  try {
    final response = await _ocrChannel.invokeMethod<Object>(
      'getSupportedLanguages',
    );
    final locales = <String>[];
    if (response is List) {
      for (final value in response) {
        if (value is String && value.trim().isNotEmpty) {
          locales.add(value.trim().toLowerCase());
        }
      }
    }
    if (locales.isEmpty) {
      return kSupportedLanguages;
    }
    final filtered = kSupportedLanguages.where((option) {
      for (final hint in option.visionLocaleHints) {
        final normalizedHint = hint.toLowerCase();
        for (final locale in locales) {
          if (locale == normalizedHint ||
              locale.startsWith('$normalizedHint-') ||
              normalizedHint.startsWith('$locale-')) {
            return true;
          }
        }
      }
      return false;
    }).toList(growable: false);
    return filtered.isEmpty ? kSupportedLanguages : filtered;
  } catch (_) {
    return kSupportedLanguages;
  }
}

final ocrSupportedLanguagesProvider = FutureProvider<List<LanguageOption>>((
  ref,
) async {
  return loadOcrSupportedLanguages();
});

class SettingsService {
  SettingsService({Future<SharedPreferences>? prefsOverride})
    : _prefsFuture = prefsOverride ?? SharedPreferences.getInstance();

  static const String _keyNativeLanguage = 'fmc.settings.nativeLanguage';
  static const String _keyUiLocale = 'fmc.settings.uiLocale';
  static const String _keyUiTextScale = 'fmc.settings.uiTextScale';
  static const String _keySourceLanguages = 'fmc.settings.sourceLanguages';
  static const String _keyCloudMediaSync = 'fmc.settings.cloudMediaSync';
  static const String _keyOpenCaptureOnTextSelection =
      'fmc.settings.openCaptureOnTextSelection';
  static const String _keyStrictAutoCaptureFilter =
      'fmc.settings.strictAutoCaptureFilter';
  static const String _keyTranslationBackend =
      'fmc.settings.translationBackend';
  static const String _keyReviewAutoPlayAudio = 'fmc.settings.reviewAutoPlayAudio';
  static const String _keyReviewTtsRate = 'fmc.settings.reviewTtsRate';
  static const String _keyReviewAudioLoopCount =
      'fmc.settings.reviewAudioLoopCount';
  static const String _keyCapturePopupAutoRecentTag =
      'fmc.settings.capturePopupAutoRecentTag';
  static const String _keyAutoCaptureToggleHotkeyKey =
      'fmc.settings.autoCaptureToggleHotkeyKey';
  static const String _keyAutoLocalBackupEnabled =
      'fmc.settings.autoLocalBackupEnabled';
  static const String _keyAutoLocalBackupIntervalHours =
      'fmc.settings.autoLocalBackupIntervalHours';
  static const String _keyLastAutoLocalBackupMs =
      'fmc.settings.lastAutoLocalBackupMs';
  static const String _keyLocalBackupDirectoryPath =
      'fmc.settings.localBackupDirectoryPath';
  static const String _keyCustomStudyMaxCards =
      'fmc.settings.customStudyMaxCards';
  static const String _keyCustomStudyOrderRandom =
      'fmc.settings.customStudyOrderRandom';
  static const String _keyCustomStudyCram = 'fmc.settings.customStudyCram';
  static const String _keyLocalProfilesJson = 'fmc.settings.localProfilesV1';
  static const String _keyActiveLocalProfileId =
      'fmc.settings.activeLocalProfileId';

  final Future<SharedPreferences> _prefsFuture;

  Future<LanguageSettings> load() async {
    try {
      final prefs = await _prefsFuture;
      final native = prefs.getString(_keyNativeLanguage);
      final sources = prefs.getStringList(_keySourceLanguages);
      return LanguageSettings(
        nativeLanguage: (native == null || native.trim().isEmpty)
            ? LanguageSettings.fallback.nativeLanguage
            : native.trim().toLowerCase(),
        sourceLanguages: (sources == null || sources.isEmpty)
            ? LanguageSettings.fallback.sourceLanguages
            : sources
                  .map((s) => s.trim().toLowerCase())
                  .where((s) => s.isNotEmpty)
                  .toList(growable: false),
      );
    } catch (error) {
      debugPrint('SettingsService load failed: $error');
      return LanguageSettings.fallback;
    }
  }

  Future<void> save(LanguageSettings settings) async {
    try {
      final prefs = await _prefsFuture;
      await prefs.setString(
        _keyNativeLanguage,
        settings.nativeLanguage.trim().toLowerCase(),
      );
      await prefs.setStringList(
        _keySourceLanguages,
        settings.sourceLanguages
            .map((s) => s.trim().toLowerCase())
            .where((s) => s.isNotEmpty)
            .toList(),
      );
    } catch (error) {
      debugPrint('SettingsService save failed: $error');
    }
  }

  /// Stored UI locale tag (`en`, `vi`, ...). `null` means follow system locale.
  Future<String?> loadUiLocale() async {
    try {
      final prefs = await _prefsFuture;
      final raw = prefs.getString(_keyUiLocale);
      if (raw == null || raw.trim().isEmpty) {
        return null;
      }
      final t = raw.trim().toLowerCase();
      const allowed = {'en', 'vi', 'ja', 'zh', 'ko'};
      if (!allowed.contains(t)) {
        return null;
      }
      return t;
    } catch (error) {
      debugPrint('SettingsService ui locale load failed: $error');
      return null;
    }
  }

  Future<void> saveUiLocale(String? tag) async {
    try {
      final prefs = await _prefsFuture;
      if (tag == null || tag.trim().isEmpty) {
        await prefs.remove(_keyUiLocale);
        return;
      }
      await prefs.setString(_keyUiLocale, tag.trim().toLowerCase());
    } catch (error) {
      debugPrint('SettingsService ui locale save failed: $error');
    }
  }

  Future<double> loadUiTextScale() async {
    try {
      final prefs = await _prefsFuture;
      final raw = prefs.getDouble(_keyUiTextScale);
      return clampUiTextScale(raw ?? 1.0);
    } catch (error) {
      debugPrint('SettingsService ui text scale load failed: $error');
      return 1.0;
    }
  }

  Future<void> saveUiTextScale(double value) async {
    try {
      final prefs = await _prefsFuture;
      await prefs.setDouble(_keyUiTextScale, clampUiTextScale(value));
    } catch (error) {
      debugPrint('SettingsService ui text scale save failed: $error');
    }
  }

  Future<bool> loadCloudMediaSyncEnabled() async {
    try {
      final prefs = await _prefsFuture;
      return prefs.getBool(_keyCloudMediaSync) ?? false;
    } catch (error) {
      debugPrint('SettingsService cloud media load failed: $error');
      return false;
    }
  }

  Future<void> setCloudMediaSyncEnabled(bool value) async {
    try {
      final prefs = await _prefsFuture;
      await prefs.setBool(_keyCloudMediaSync, value);
    } catch (error) {
      debugPrint('SettingsService cloud media save failed: $error');
    }
  }

  Future<bool> loadOpenCaptureOnTextSelection() async {
    try {
      final prefs = await _prefsFuture;
      return prefs.getBool(_keyOpenCaptureOnTextSelection) ?? false;
    } catch (error) {
      debugPrint(
        'SettingsService open capture on selection load failed: $error',
      );
      return false;
    }
  }

  Future<void> setOpenCaptureOnTextSelection(bool value) async {
    try {
      final prefs = await _prefsFuture;
      await prefs.setBool(_keyOpenCaptureOnTextSelection, value);
    } catch (error) {
      debugPrint(
        'SettingsService open capture on selection save failed: $error',
      );
    }
  }

  Future<bool> loadStrictAutoCaptureFilter() async {
    try {
      final prefs = await _prefsFuture;
      return prefs.getBool(_keyStrictAutoCaptureFilter) ?? true;
    } catch (error) {
      debugPrint('SettingsService strict auto-capture load failed: $error');
      return true;
    }
  }

  Future<void> setStrictAutoCaptureFilter(bool value) async {
    try {
      final prefs = await _prefsFuture;
      await prefs.setBool(_keyStrictAutoCaptureFilter, value);
    } catch (error) {
      debugPrint('SettingsService strict auto-capture save failed: $error');
    }
  }

  Future<TranslationBackendPreference> loadTranslationBackend() async {
    try {
      final prefs = await _prefsFuture;
      return translationBackendPreferenceFromStorage(
        prefs.getString(_keyTranslationBackend),
      );
    } catch (error) {
      debugPrint('SettingsService translation backend load failed: $error');
      return TranslationBackendPreference.playwrightGoogleTranslate;
    }
  }

  Future<void> saveTranslationBackend(
    TranslationBackendPreference value,
  ) async {
    try {
      final prefs = await _prefsFuture;
      await prefs.setString(_keyTranslationBackend, value.storageValue);
    } catch (error) {
      debugPrint('SettingsService translation backend save failed: $error');
    }
  }

  Future<bool> loadReviewAutoPlayAudioEnabled() async {
    try {
      final prefs = await _prefsFuture;
      return prefs.getBool(_keyReviewAutoPlayAudio) ?? false;
    } catch (error) {
      debugPrint('SettingsService review autoplay load failed: $error');
      return false;
    }
  }

  Future<void> setReviewAutoPlayAudioEnabled(bool value) async {
    try {
      final prefs = await _prefsFuture;
      await prefs.setBool(_keyReviewAutoPlayAudio, value);
    } catch (error) {
      debugPrint('SettingsService review autoplay save failed: $error');
    }
  }

  Future<double> loadReviewTtsRate() async {
    try {
      final prefs = await _prefsFuture;
      final raw = prefs.getDouble(_keyReviewTtsRate);
      return clampReviewTtsRate(raw ?? 1.0);
    } catch (error) {
      debugPrint('SettingsService review tts rate load failed: $error');
      return 1.0;
    }
  }

  Future<void> setReviewTtsRate(double value) async {
    try {
      final prefs = await _prefsFuture;
      await prefs.setDouble(_keyReviewTtsRate, clampReviewTtsRate(value));
    } catch (error) {
      debugPrint('SettingsService review tts rate save failed: $error');
    }
  }

  Future<int> loadReviewAudioLoopCount() async {
    try {
      final prefs = await _prefsFuture;
      final raw = prefs.getInt(_keyReviewAudioLoopCount);
      return clampReviewAudioLoopCount(raw ?? 1);
    } catch (error) {
      debugPrint('SettingsService review audio loop load failed: $error');
      return 1;
    }
  }

  Future<void> setReviewAudioLoopCount(int value) async {
    try {
      final prefs = await _prefsFuture;
      await prefs.setInt(
        _keyReviewAudioLoopCount,
        clampReviewAudioLoopCount(value),
      );
    } catch (error) {
      debugPrint('SettingsService review audio loop save failed: $error');
    }
  }

  Future<bool> loadCapturePopupAutoRecentTag() async {
    try {
      final prefs = await _prefsFuture;
      return prefs.getBool(_keyCapturePopupAutoRecentTag) ?? false;
    } catch (error) {
      debugPrint(
        'SettingsService capture popup auto-recent tag load failed: $error',
      );
      return false;
    }
  }

  Future<void> setCapturePopupAutoRecentTag(bool value) async {
    try {
      final prefs = await _prefsFuture;
      await prefs.setBool(_keyCapturePopupAutoRecentTag, value);
    } catch (error) {
      debugPrint(
        'SettingsService capture popup auto-recent tag save failed: $error',
      );
    }
  }

  Future<String> loadAutoCaptureToggleHotkeyKey() async {
    try {
      final prefs = await _prefsFuture;
      final raw = prefs.getString(_keyAutoCaptureToggleHotkeyKey);
      final normalized = _normalizeHotkeyKey(raw);
      if (normalized == null) {
        return AutoCaptureToggleHotkeyPreference.defaultKey;
      }
      // Migrate old default from A to U.
      if (normalized == 'A') {
        await prefs.setString(
          _keyAutoCaptureToggleHotkeyKey,
          AutoCaptureToggleHotkeyPreference.defaultKey,
        );
        return AutoCaptureToggleHotkeyPreference.defaultKey;
      }
      return normalized;
    } catch (error) {
      debugPrint('SettingsService auto-capture hotkey load failed: $error');
      return AutoCaptureToggleHotkeyPreference.defaultKey;
    }
  }

  Future<void> saveAutoCaptureToggleHotkeyKey(String key) async {
    final normalized = _normalizeHotkeyKey(key);
    if (normalized == null) {
      return;
    }
    try {
      final prefs = await _prefsFuture;
      await prefs.setString(_keyAutoCaptureToggleHotkeyKey, normalized);
    } catch (error) {
      debugPrint('SettingsService auto-capture hotkey save failed: $error');
    }
  }

  String? _normalizeHotkeyKey(String? raw) {
    final key = (raw ?? '').trim().toUpperCase();
    if (key.length != 1) {
      return null;
    }
    final unit = key.codeUnitAt(0);
    final isLetter = unit >= 0x41 && unit <= 0x5A;
    final isDigit = unit >= 0x30 && unit <= 0x39;
    if (!isLetter && !isDigit) {
      return null;
    }
    return key;
  }

  Future<bool> loadAutoLocalBackupEnabled() async {
    try {
      final prefs = await _prefsFuture;
      return prefs.getBool(_keyAutoLocalBackupEnabled) ?? false;
    } catch (error) {
      debugPrint('SettingsService auto local backup enabled load failed: $error');
      return false;
    }
  }

  Future<void> setAutoLocalBackupEnabled(bool value) async {
    try {
      final prefs = await _prefsFuture;
      await prefs.setBool(_keyAutoLocalBackupEnabled, value);
    } catch (error) {
      debugPrint('SettingsService auto local backup enabled save failed: $error');
    }
  }

  Future<int> loadAutoLocalBackupIntervalHours() async {
    try {
      final prefs = await _prefsFuture;
      return clampAutoLocalBackupIntervalHours(
        prefs.getInt(_keyAutoLocalBackupIntervalHours),
      );
    } catch (error) {
      debugPrint('SettingsService auto local backup interval load failed: $error');
      return 24;
    }
  }

  Future<void> setAutoLocalBackupIntervalHours(int value) async {
    try {
      final prefs = await _prefsFuture;
      await prefs.setInt(
        _keyAutoLocalBackupIntervalHours,
        clampAutoLocalBackupIntervalHours(value),
      );
    } catch (error) {
      debugPrint('SettingsService auto local backup interval save failed: $error');
    }
  }

  Future<int?> loadLastAutoLocalBackupMs() async {
    try {
      final prefs = await _prefsFuture;
      if (!prefs.containsKey(_keyLastAutoLocalBackupMs)) {
        return null;
      }
      return prefs.getInt(_keyLastAutoLocalBackupMs);
    } catch (error) {
      debugPrint('SettingsService last auto local backup load failed: $error');
      return null;
    }
  }

  Future<void> setLastAutoLocalBackupMs(int ms) async {
    try {
      final prefs = await _prefsFuture;
      await prefs.setInt(_keyLastAutoLocalBackupMs, ms);
    } catch (error) {
      debugPrint('SettingsService last auto local backup save failed: $error');
    }
  }

  /// Custom root for local backups. `null` or empty means app default
  /// (Documents/formycareer_backups).
  Future<String?> loadLocalBackupDirectoryPath() async {
    try {
      final prefs = await _prefsFuture;
      final raw = prefs.getString(_keyLocalBackupDirectoryPath);
      if (raw == null) {
        return null;
      }
      final t = raw.trim();
      return t.isEmpty ? null : t;
    } catch (error) {
      debugPrint('SettingsService local backup directory load failed: $error');
      return null;
    }
  }

  Future<void> setLocalBackupDirectoryPath(String? path) async {
    try {
      final prefs = await _prefsFuture;
      final t = path?.trim();
      if (t == null || t.isEmpty) {
        await prefs.remove(_keyLocalBackupDirectoryPath);
      } else {
        await prefs.setString(_keyLocalBackupDirectoryPath, t);
      }
    } catch (error) {
      debugPrint('SettingsService local backup directory save failed: $error');
    }
  }

  /// Last-used custom study session options (max cards, order, cram).
  Future<CustomStudyOptions> loadCustomStudyDefaults() async {
    try {
      final prefs = await _prefsFuture;
      final maxRaw = prefs.getInt(_keyCustomStudyMaxCards);
      final maxCards = maxRaw == null || maxRaw <= 0 ? null : maxRaw;
      final random = prefs.getBool(_keyCustomStudyOrderRandom) ?? false;
      final cram = prefs.getBool(_keyCustomStudyCram) ?? false;
      return CustomStudyOptions(
        maxCards: maxCards,
        order: random ? CustomStudyOrder.random : CustomStudyOrder.dueOrder,
        respectScheduling: !cram,
      );
    } catch (error) {
      debugPrint('SettingsService custom study defaults load failed: $error');
      return CustomStudyOptions.defaults;
    }
  }

  Future<void> saveCustomStudyDefaults(CustomStudyOptions options) async {
    try {
      final prefs = await _prefsFuture;
      if (options.maxCards == null || options.maxCards! <= 0) {
        await prefs.remove(_keyCustomStudyMaxCards);
      } else {
        await prefs.setInt(_keyCustomStudyMaxCards, options.maxCards!);
      }
      await prefs.setBool(
        _keyCustomStudyOrderRandom,
        options.order == CustomStudyOrder.random,
      );
      await prefs.setBool(
        _keyCustomStudyCram,
        !options.respectScheduling,
      );
    } catch (error) {
      debugPrint('SettingsService custom study defaults save failed: $error');
    }
  }

  Future<List<LocalProfile>> loadLocalProfiles() async {
    try {
      final prefs = await _prefsFuture;
      final raw = prefs.getString(_keyLocalProfilesJson);
      if (raw == null || raw.trim().isEmpty) {
        return const <LocalProfile>[LocalProfile.defaultProfile];
      }
      final decoded = jsonDecode(raw);
      if (decoded is! List<Object?>) {
        return const <LocalProfile>[LocalProfile.defaultProfile];
      }
      final out = <LocalProfile>[];
      final seen = <String>{};
      for (final item in decoded) {
        if (item is Map) {
          final profile = LocalProfile.fromJson(
            Map<String, dynamic>.from(item),
          );
          if (profile.id.isNotEmpty && seen.add(profile.id)) {
            out.add(profile);
          }
        }
      }
      if (out.isEmpty) {
        return const <LocalProfile>[LocalProfile.defaultProfile];
      }
      if (!out.any((p) => p.id == kDefaultLocalProfileId)) {
        out.insert(0, LocalProfile.defaultProfile);
      }
      return out;
    } catch (error) {
      debugPrint('SettingsService local profiles load failed: $error');
      return const <LocalProfile>[LocalProfile.defaultProfile];
    }
  }

  Future<void> saveLocalProfiles(List<LocalProfile> profiles) async {
    try {
      final prefs = await _prefsFuture;
      await prefs.setString(
        _keyLocalProfilesJson,
        jsonEncode(profiles.map((p) => p.toJson()).toList()),
      );
    } catch (error) {
      debugPrint('SettingsService local profiles save failed: $error');
    }
  }

  Future<String> loadActiveLocalProfileId() async {
    try {
      final prefs = await _prefsFuture;
      final raw = prefs.getString(_keyActiveLocalProfileId)?.trim();
      if (raw == null || raw.isEmpty) {
        return kDefaultLocalProfileId;
      }
      return raw;
    } catch (error) {
      debugPrint('SettingsService active local profile load failed: $error');
      return kDefaultLocalProfileId;
    }
  }

  Future<void> saveActiveLocalProfileId(String id) async {
    try {
      final prefs = await _prefsFuture;
      final t = id.trim();
      if (t.isEmpty) {
        await prefs.remove(_keyActiveLocalProfileId);
        return;
      }
      await prefs.setString(_keyActiveLocalProfileId, t);
    } catch (error) {
      debugPrint('SettingsService active local profile save failed: $error');
    }
  }
}

/// Allowed intervals for scheduled local backups (hours).
const List<int> kAutoLocalBackupIntervalHoursOptions = <int>[1, 6, 12, 24, 48, 168];

int clampAutoLocalBackupIntervalHours(int? raw) {
  final v = raw ?? 24;
  if (kAutoLocalBackupIntervalHoursOptions.contains(v)) {
    return v;
  }
  var best = kAutoLocalBackupIntervalHoursOptions.first;
  var bestDelta = (v - best).abs();
  for (final option in kAutoLocalBackupIntervalHoursOptions) {
    final delta = (v - option).abs();
    if (delta < bestDelta) {
      best = option;
      bestDelta = delta;
    }
  }
  return best;
}

final settingsServiceProvider = Provider<SettingsService>((ref) {
  return SettingsService();
});

class UiLocalePreferenceController extends Notifier<String> {
  bool _hydrationSuperseded = false;

  @override
  String build() {
    Future<void>.microtask(() async {
      final raw = await ref.read(settingsServiceProvider).loadUiLocale();
      if (!ref.mounted || _hydrationSuperseded) {
        return;
      }
      state = raw ?? '';
    });
    return '';
  }

  Future<void> setTag(String tag) async {
    _hydrationSuperseded = true;
    final t = tag.trim().toLowerCase();
    final next = (t.isEmpty || t == 'system') ? '' : t;
    state = next;
    await ref.read(settingsServiceProvider).saveUiLocale(
          next.isEmpty ? null : next,
        );
  }
}

final uiLocalePreferenceProvider =
    NotifierProvider<UiLocalePreferenceController, String>(
      UiLocalePreferenceController.new,
    );

/// Discrete UI text scale factors (multiplied with OS / view text scaling).
const List<double> kUiTextScaleOptions = <double>[
  0.85,
  0.92,
  1.0,
  1.08,
  1.15,
  1.25,
];

double clampUiTextScale(double value) {
  if (value.isNaN || value <= 0) {
    return 1.0;
  }
  var best = kUiTextScaleOptions.first;
  var bestDelta = (value - best).abs();
  for (final option in kUiTextScaleOptions) {
    final delta = (value - option).abs();
    if (delta < bestDelta) {
      best = option;
      bestDelta = delta;
    }
  }
  return best;
}

class UiTextScalePreferenceController extends Notifier<double> {
  bool _hydrationSuperseded = false;

  @override
  double build() {
    Future<void>.microtask(() async {
      final v = await ref.read(settingsServiceProvider).loadUiTextScale();
      if (!ref.mounted || _hydrationSuperseded) {
        return;
      }
      state = v;
    });
    return 1.0;
  }

  Future<void> setScale(double value) async {
    final clamped = clampUiTextScale(value);
    _hydrationSuperseded = true;
    state = clamped;
    await ref.read(settingsServiceProvider).saveUiTextScale(clamped);
  }
}

final uiTextScalePreferenceProvider =
    NotifierProvider<UiTextScalePreferenceController, double>(
      UiTextScalePreferenceController.new,
    );

class LanguageSettingsController extends AsyncNotifier<LanguageSettings> {
  @override
  Future<LanguageSettings> build() async {
    final service = ref.read(settingsServiceProvider);
    final loaded = await service.load();
    final sanitized = await _sanitizeAgainstOcrSupport(loaded);
    if (_settingsDifferent(loaded, sanitized)) {
      await service.save(sanitized);
    }
    return sanitized;
  }

  Future<void> setNativeLanguage(String code) async {
    final current = state.value ?? LanguageSettings.fallback;
    final updated = current.copyWith(nativeLanguage: code);
    state = AsyncData(updated);
    await ref.read(settingsServiceProvider).save(updated);
  }

  Future<void> setSourceLanguages(List<String> codes) async {
    final current = state.value ?? LanguageSettings.fallback;
    final cleaned = codes
        .map((c) => c.trim().toLowerCase())
        .where((c) => c.isNotEmpty)
        .toSet()
        .toList(growable: false);
    if (cleaned.isEmpty) return;
    final updated = await _sanitizeAgainstOcrSupport(
      current.copyWith(sourceLanguages: cleaned),
    );
    state = AsyncData(updated);
    await ref.read(settingsServiceProvider).save(updated);
  }

  Future<void> applySettings(LanguageSettings next) async {
    final cleaned = next.copyWith(
      nativeLanguage: next.nativeLanguage.trim().toLowerCase(),
      sourceLanguages: next.sourceLanguages
          .map((c) => c.trim().toLowerCase())
          .where((c) => c.isNotEmpty)
          .toSet()
          .toList(growable: false),
    );
    final sanitized = await _sanitizeAgainstOcrSupport(cleaned);
    state = AsyncData(sanitized);
    await ref.read(settingsServiceProvider).save(sanitized);
  }

  Future<LanguageSettings> _sanitizeAgainstOcrSupport(
    LanguageSettings input,
  ) async {
    final supported = await loadOcrSupportedLanguages();
    final allSupported = supported
        .map((e) => e.code.trim().toLowerCase())
        .where((c) => c.isNotEmpty)
        .toSet()
        .toList(growable: false);
    if (allSupported.isEmpty) {
      return input.copyWith(
        sourceLanguages: List<String>.from(LanguageSettings.fallback.sourceLanguages),
      );
    }
    final requested = input.sourceLanguages
        .map((e) => e.trim().toLowerCase())
        .where((e) => e.isNotEmpty)
        .toSet();
    final filtered = allSupported.where(requested.contains).toList(growable: false);
    if (filtered.isEmpty) {
      final fallback = LanguageSettings.fallback.sourceLanguages
          .where(allSupported.contains)
          .toList(growable: false);
      return input.copyWith(
        sourceLanguages: fallback.isEmpty ? <String>[allSupported.first] : fallback,
      );
    }
    return input.copyWith(sourceLanguages: filtered);
  }

  bool _settingsDifferent(LanguageSettings a, LanguageSettings b) {
    if (a.nativeLanguage != b.nativeLanguage) {
      return true;
    }
    final as = a.sourceLanguages.toList()..sort();
    final bs = b.sourceLanguages.toList()..sort();
    if (as.length != bs.length) {
      return true;
    }
    for (var i = 0; i < as.length; i++) {
      if (as[i] != bs[i]) {
        return true;
      }
    }
    return false;
  }
}

final languageSettingsProvider =
    AsyncNotifierProvider<LanguageSettingsController, LanguageSettings>(
      LanguageSettingsController.new,
    );

class CloudMediaSyncController extends Notifier<bool> {
  @override
  bool build() {
    Future<void>.microtask(() async {
      final v = await ref
          .read(settingsServiceProvider)
          .loadCloudMediaSyncEnabled();
      if (!ref.mounted) {
        return;
      }
      state = v;
    });
    return false;
  }

  Future<void> setEnabled(bool value) async {
    state = value;
    await ref.read(settingsServiceProvider).setCloudMediaSyncEnabled(value);
  }
}

final cloudMediaSyncProvider = NotifierProvider<CloudMediaSyncController, bool>(
  CloudMediaSyncController.new,
);

class OpenCaptureOnTextSelectionController extends Notifier<bool> {
  @override
  bool build() {
    Future<void>.microtask(() async {
      final v = await ref
          .read(settingsServiceProvider)
          .loadOpenCaptureOnTextSelection();
      if (ref.mounted) {
        state = v;
      }
    });
    return false;
  }

  Future<void> setEnabled(bool value) async {
    state = value;
    await ref
        .read(settingsServiceProvider)
        .setOpenCaptureOnTextSelection(value);
  }
}

final openCaptureOnTextSelectionProvider =
    NotifierProvider<OpenCaptureOnTextSelectionController, bool>(
      OpenCaptureOnTextSelectionController.new,
    );

class StrictAutoCaptureFilterController extends Notifier<bool> {
  @override
  bool build() {
    Future<void>.microtask(() async {
      final v = await ref
          .read(settingsServiceProvider)
          .loadStrictAutoCaptureFilter();
      if (ref.mounted) {
        state = v;
      }
    });
    return true;
  }

  Future<void> setEnabled(bool value) async {
    state = value;
    await ref.read(settingsServiceProvider).setStrictAutoCaptureFilter(value);
  }
}

final strictAutoCaptureFilterProvider =
    NotifierProvider<StrictAutoCaptureFilterController, bool>(
      StrictAutoCaptureFilterController.new,
    );

class AutoCaptureToggleHotkeyPreference {
  const AutoCaptureToggleHotkeyPreference(this.key);

  static const String defaultKey = 'U';
  static const List<String> availableKeys = <String>[
    'A',
    'B',
    'C',
    'E',
    'F',
    'G',
    'H',
    'I',
    'J',
    'K',
    'L',
    'M',
    'N',
    'O',
    'P',
    'Q',
    'R',
    'S',
    'T',
    'U',
    'V',
    'W',
    'Y',
    'Z',
    '0',
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
  ];

  final String key;

  String get displayLabel => 'Ctrl+Shift+$key';
}

class AutoCaptureToggleHotkeyController
    extends Notifier<AutoCaptureToggleHotkeyPreference> {
  @override
  AutoCaptureToggleHotkeyPreference build() {
    Future<void>.microtask(() async {
      final key = await ref
          .read(settingsServiceProvider)
          .loadAutoCaptureToggleHotkeyKey();
      if (!ref.mounted) {
        return;
      }
      state = AutoCaptureToggleHotkeyPreference(key);
    });
    return const AutoCaptureToggleHotkeyPreference(
      AutoCaptureToggleHotkeyPreference.defaultKey,
    );
  }

  Future<void> setKey(String key) async {
    final normalized = key.trim().toUpperCase();
    if (!AutoCaptureToggleHotkeyPreference.availableKeys.contains(normalized)) {
      return;
    }
    state = AutoCaptureToggleHotkeyPreference(normalized);
    await ref
        .read(settingsServiceProvider)
        .saveAutoCaptureToggleHotkeyKey(normalized);
  }
}

final autoCaptureToggleHotkeyProvider =
    NotifierProvider<
      AutoCaptureToggleHotkeyController,
      AutoCaptureToggleHotkeyPreference
    >(AutoCaptureToggleHotkeyController.new);

class TranslationBackendPreferenceController
    extends Notifier<TranslationBackendPreference> {
  @override
  TranslationBackendPreference build() {
    Future<void>.microtask(() async {
      final v = await ref
          .read(settingsServiceProvider)
          .loadTranslationBackend();
      if (ref.mounted) {
        state = v;
      }
    });
    return TranslationBackendPreference.playwrightGoogleTranslate;
  }

  Future<void> setPreference(TranslationBackendPreference value) async {
    state = value;
    await ref.read(settingsServiceProvider).saveTranslationBackend(value);
  }
}

final translationBackendPreferenceProvider =
    NotifierProvider<
      TranslationBackendPreferenceController,
      TranslationBackendPreference
    >(TranslationBackendPreferenceController.new);

class ReviewAutoPlayAudioController extends Notifier<bool> {
  /// When true, a late async prefs read must not overwrite [state] (user already
  /// toggled while hydration was still in flight).
  bool _hydrationSuperseded = false;

  @override
  bool build() {
    Future<void>.microtask(() async {
      final enabled = await ref
          .read(settingsServiceProvider)
          .loadReviewAutoPlayAudioEnabled();
      if (!ref.mounted || _hydrationSuperseded) {
        return;
      }
      state = enabled;
    });
    return false;
  }

  Future<void> setEnabled(bool value) async {
    _hydrationSuperseded = true;
    state = value;
    await ref.read(settingsServiceProvider).setReviewAutoPlayAudioEnabled(value);
  }
}

final reviewAutoPlayAudioProvider =
    NotifierProvider<ReviewAutoPlayAudioController, bool>(
      ReviewAutoPlayAudioController.new,
    );

/// Allowed playback rates for review TTS (slowest to fastest).
const List<double> kReviewTtsRateOptions = <double>[0.5, 0.75, 1.0];

/// Clamps an arbitrary rate to the nearest supported [kReviewTtsRateOptions].
double clampReviewTtsRate(double value) {
  if (value.isNaN || value <= 0) {
    return 1.0;
  }
  var best = kReviewTtsRateOptions.first;
  var bestDelta = (value - best).abs();
  for (final option in kReviewTtsRateOptions) {
    final delta = (value - option).abs();
    if (delta < bestDelta) {
      best = option;
      bestDelta = delta;
    }
  }
  return best;
}

/// Allowed loop counts for the listen-and-type review mode.
const List<int> kReviewAudioLoopCountOptions = <int>[1, 2, 3];

int clampReviewAudioLoopCount(int value) {
  if (value < kReviewAudioLoopCountOptions.first) {
    return kReviewAudioLoopCountOptions.first;
  }
  if (value > kReviewAudioLoopCountOptions.last) {
    return kReviewAudioLoopCountOptions.last;
  }
  return value;
}

class ReviewTtsRateController extends Notifier<double> {
  /// When true, a late async prefs read must not overwrite [state] (user chose
  /// a rate while hydration was still in flight — avoids snapping back to 1.0x).
  bool _hydrationSuperseded = false;

  @override
  double build() {
    Future<void>.microtask(() async {
      final rate = await ref.read(settingsServiceProvider).loadReviewTtsRate();
      if (!ref.mounted || _hydrationSuperseded) {
        return;
      }
      state = rate;
    });
    return 1.0;
  }

  Future<void> setRate(double value) async {
    final clamped = clampReviewTtsRate(value);
    _hydrationSuperseded = true;
    state = clamped;
    await ref.read(settingsServiceProvider).setReviewTtsRate(clamped);
  }
}

final reviewTtsRateProvider =
    NotifierProvider<ReviewTtsRateController, double>(
      ReviewTtsRateController.new,
    );

class ReviewAudioLoopCountController extends Notifier<int> {
  bool _hydrationSuperseded = false;

  @override
  int build() {
    Future<void>.microtask(() async {
      final count = await ref
          .read(settingsServiceProvider)
          .loadReviewAudioLoopCount();
      if (!ref.mounted || _hydrationSuperseded) {
        return;
      }
      state = count;
    });
    return 1;
  }

  Future<void> setCount(int value) async {
    final clamped = clampReviewAudioLoopCount(value);
    _hydrationSuperseded = true;
    state = clamped;
    await ref.read(settingsServiceProvider).setReviewAudioLoopCount(clamped);
  }
}

final reviewAudioLoopCountProvider =
    NotifierProvider<ReviewAudioLoopCountController, int>(
      ReviewAudioLoopCountController.new,
    );

class CapturePopupAutoRecentTagController extends Notifier<bool> {
  @override
  bool build() {
    Future<void>.microtask(() async {
      final v = await ref
          .read(settingsServiceProvider)
          .loadCapturePopupAutoRecentTag();
      if (ref.mounted) {
        state = v;
      }
    });
    return false;
  }

  Future<void> setEnabled(bool value) async {
    state = value;
    await ref.read(settingsServiceProvider).setCapturePopupAutoRecentTag(value);
  }
}

final capturePopupAutoRecentTagProvider =
    NotifierProvider<CapturePopupAutoRecentTagController, bool>(
      CapturePopupAutoRecentTagController.new,
    );

class AutoLocalBackupEnabledController extends Notifier<bool> {
  @override
  bool build() {
    Future<void>.microtask(() async {
      final v = await ref
          .read(settingsServiceProvider)
          .loadAutoLocalBackupEnabled();
      if (ref.mounted) {
        state = v;
      }
    });
    return false;
  }

  Future<void> setEnabled(bool value) async {
    state = value;
    await ref.read(settingsServiceProvider).setAutoLocalBackupEnabled(value);
  }
}

final autoLocalBackupEnabledProvider =
    NotifierProvider<AutoLocalBackupEnabledController, bool>(
      AutoLocalBackupEnabledController.new,
    );

class AutoLocalBackupIntervalHoursController extends Notifier<int> {
  bool _hydrationSuperseded = false;

  @override
  int build() {
    Future<void>.microtask(() async {
      final hours = await ref
          .read(settingsServiceProvider)
          .loadAutoLocalBackupIntervalHours();
      if (!ref.mounted || _hydrationSuperseded) {
        return;
      }
      state = hours;
    });
    return 24;
  }

  Future<void> setHours(int value) async {
    final clamped = clampAutoLocalBackupIntervalHours(value);
    _hydrationSuperseded = true;
    state = clamped;
    await ref
        .read(settingsServiceProvider)
        .setAutoLocalBackupIntervalHours(clamped);
  }
}

final autoLocalBackupIntervalHoursProvider =
    NotifierProvider<AutoLocalBackupIntervalHoursController, int>(
      AutoLocalBackupIntervalHoursController.new,
    );

/// Stored override path only; `null` means use app default folder.
class LocalBackupDirectoryController extends Notifier<String?> {
  @override
  String? build() {
    Future<void>.microtask(() async {
      final p =
          await ref.read(settingsServiceProvider).loadLocalBackupDirectoryPath();
      if (ref.mounted) {
        state = p;
      }
    });
    return null;
  }

  Future<void> setDirectory(String? absolutePath) async {
    final trimmed = absolutePath?.trim();
    final next = (trimmed == null || trimmed.isEmpty) ? null : trimmed;
    state = next;
    await ref.read(settingsServiceProvider).setLocalBackupDirectoryPath(next);
  }
}

final localBackupCustomDirectoryProvider =
    NotifierProvider<LocalBackupDirectoryController, String?>(
      LocalBackupDirectoryController.new,
    );

/// Device-local vocabulary profiles (each profile has its own word library).
class LocalProfilesState {
  const LocalProfilesState({
    required this.profiles,
    required this.activeProfileId,
  });

  final List<LocalProfile> profiles;
  final String activeProfileId;

  LocalProfile? get activeProfile {
    for (final p in profiles) {
      if (p.id == activeProfileId) {
        return p;
      }
    }
    return profiles.isEmpty ? null : profiles.first;
  }
}

class LocalProfilesNotifier extends Notifier<LocalProfilesState> {
  bool _hydrationSuperseded = false;

  @override
  LocalProfilesState build() {
    Future<void>.microtask(() async {
      await _hydrate();
    });
    return LocalProfilesState(
      profiles: const <LocalProfile>[LocalProfile.defaultProfile],
      activeProfileId: kDefaultLocalProfileId,
    );
  }

  Future<void> _hydrate() async {
    final service = ref.read(settingsServiceProvider);
    final profiles = await service.loadLocalProfiles();
    var activeId = await service.loadActiveLocalProfileId();
    if (!profiles.any((p) => p.id == activeId)) {
      activeId = profiles.first.id;
      await service.saveActiveLocalProfileId(activeId);
    }
    if (!ref.mounted || _hydrationSuperseded) {
      return;
    }
    state = LocalProfilesState(profiles: profiles, activeProfileId: activeId);
  }

  Future<void> setActiveProfile(String profileId) async {
    final id = profileId.trim();
    if (id.isEmpty || !state.profiles.any((p) => p.id == id)) {
      return;
    }
    _hydrationSuperseded = true;
    state = LocalProfilesState(profiles: state.profiles, activeProfileId: id);
    await ref.read(settingsServiceProvider).saveActiveLocalProfileId(id);
  }

  Future<void> addProfile(String displayName) async {
    final name = displayName.trim();
    if (name.isEmpty) {
      return;
    }
    final id = 'local_${DateTime.now().toUtc().microsecondsSinceEpoch}';
    final next = LocalProfile(id: id, displayName: name);
    final profiles = List<LocalProfile>.from(state.profiles)..add(next);
    _hydrationSuperseded = true;
    state = LocalProfilesState(profiles: profiles, activeProfileId: id);
    final service = ref.read(settingsServiceProvider);
    await service.saveLocalProfiles(profiles);
    await service.saveActiveLocalProfileId(id);
  }

  Future<void> renameProfile(String profileId, String displayName) async {
    final id = profileId.trim();
    final name = displayName.trim();
    if (id.isEmpty || name.isEmpty) {
      return;
    }
    final profiles = state.profiles
        .map((p) => p.id == id ? p.copyWith(displayName: name) : p)
        .toList(growable: false);
    _hydrationSuperseded = true;
    state = LocalProfilesState(
      profiles: profiles,
      activeProfileId: state.activeProfileId,
    );
    await ref.read(settingsServiceProvider).saveLocalProfiles(profiles);
  }

  /// Removes a profile. The built-in default profile cannot be removed.
  Future<void> removeProfile(String profileId) async {
    final id = profileId.trim();
    if (id.isEmpty || state.profiles.length <= 1) {
      return;
    }
    if (id == kDefaultLocalProfileId) {
      return;
    }
    final profiles =
        state.profiles.where((p) => p.id != id).toList(growable: false);
    if (profiles.isEmpty) {
      return;
    }
    var activeId = state.activeProfileId;
    if (activeId == id) {
      activeId = profiles.first.id;
    }
    _hydrationSuperseded = true;
    state = LocalProfilesState(profiles: profiles, activeProfileId: activeId);
    final service = ref.read(settingsServiceProvider);
    await service.saveLocalProfiles(profiles);
    await service.saveActiveLocalProfileId(activeId);
  }
}

final localProfilesProvider =
    NotifierProvider<LocalProfilesNotifier, LocalProfilesState>(
      LocalProfilesNotifier.new,
    );
