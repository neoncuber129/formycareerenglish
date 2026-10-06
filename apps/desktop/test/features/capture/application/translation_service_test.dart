import 'package:desktop/features/settings/application/settings_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('translationBackendPreferenceFromStorage', () {
    test('null and unknown map to Google web (default)', () {
      expect(
        translationBackendPreferenceFromStorage(null),
        TranslationBackendPreference.playwrightGoogleTranslate,
      );
      expect(
        translationBackendPreferenceFromStorage(''),
        TranslationBackendPreference.playwrightGoogleTranslate,
      );
    });

    test('google/playwright codes', () {
      expect(
        translationBackendPreferenceFromStorage('playwright'),
        TranslationBackendPreference.playwrightGoogleTranslate,
      );
      expect(
        translationBackendPreferenceFromStorage('playwright_google_translate'),
        TranslationBackendPreference.playwrightGoogleTranslate,
      );
      expect(
        translationBackendPreferenceFromStorage('google_translate'),
        TranslationBackendPreference.playwrightGoogleTranslate,
      );
    });

    test('storageValue round-trip for Google backend', () {
      expect(
        TranslationBackendPreference.playwrightGoogleTranslate.storageValue,
        'playwright_google_translate',
      );
      expect(
        translationBackendPreferenceFromStorage(
          TranslationBackendPreference.playwrightGoogleTranslate.storageValue,
        ),
        TranslationBackendPreference.playwrightGoogleTranslate,
      );
    });
  });
}
