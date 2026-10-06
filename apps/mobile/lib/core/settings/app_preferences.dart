import 'package:shared_preferences/shared_preferences.dart';

/// Cross-device preference keys aligned with desktop [SettingsService].
class AppPreferences {
  static const String _keyCloudMediaSync = 'fmc.settings.cloudMediaSync';
  static const String _keyReviewAutoPlayAudio =
      'fmc.settings.reviewAutoPlayAudio';
  static const String _keyReviewTtsRate = 'fmc.settings.reviewTtsRate';
  static const String _keyReviewAudioLoopCount =
      'fmc.settings.reviewAudioLoopCount';

  static Future<bool> loadCloudMediaSyncEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyCloudMediaSync) ?? false;
  }

  static Future<void> setCloudMediaSyncEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyCloudMediaSync, value);
  }

  static Future<bool> loadReviewAutoPlayAudioEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyReviewAutoPlayAudio) ?? false;
  }

  static Future<void> setReviewAutoPlayAudioEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyReviewAutoPlayAudio, value);
  }

  static Future<double> loadReviewTtsRate() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_keyReviewTtsRate) ?? 1.0;
  }

  static Future<void> setReviewTtsRate(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyReviewTtsRate, value);
  }

  static Future<int> loadReviewAudioLoopCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyReviewAudioLoopCount) ?? 1;
  }

  static Future<void> setReviewAudioLoopCount(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyReviewAudioLoopCount, value);
  }
}
