import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists the optional Google Cloud TTS API key on device.
///
/// Build-time define [GOOGLE_CLOUD_TTS_API_KEY] overrides stored keys when set.
class GoogleCloudTtsCredentialsStore {
  GoogleCloudTtsCredentialsStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const String _secureKey = 'fmc.google_cloud_tts.api_key';

  static const String envApiKey = String.fromEnvironment(
    'GOOGLE_CLOUD_TTS_API_KEY',
  );

  final FlutterSecureStorage _storage;

  bool get hasBuildTimeApiKey => envApiKey.trim().isNotEmpty;

  Future<String?> loadApiKey() async {
    if (hasBuildTimeApiKey) {
      return envApiKey.trim();
    }
    try {
      final raw = await _storage.read(key: _secureKey);
      final t = raw?.trim();
      return (t == null || t.isEmpty) ? null : t;
    } catch (_) {
      return null;
    }
  }

  Future<void> saveApiKey(String key) async {
    final t = key.trim();
    if (t.isEmpty) {
      await clearStoredApiKey();
      return;
    }
    if (hasBuildTimeApiKey) {
      return;
    }
    await _storage.write(key: _secureKey, value: t);
  }

  Future<void> clearStoredApiKey() async {
    if (hasBuildTimeApiKey) {
      return;
    }
    try {
      await _storage.delete(key: _secureKey);
    } catch (_) {
      // ignore
    }
  }
}
