import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class DriveSyncPreferences {
  static const String _envDriveAccessToken = String.fromEnvironment(
    'GOOGLE_DRIVE_ACCESS_TOKEN',
  );
  static const _keyAccessToken = 'fmc.drive.accessToken';
  static const _keySnapshotFileId = 'fmc.drive.snapshotFileId';
  static const _keyDeviceId = 'fmc.drive.deviceId';
  static const _keyLastSyncAt = 'fmc.drive.lastSyncAt';

  Future<String> getOrCreateDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_keyDeviceId)?.trim() ?? '';
    if (existing.isNotEmpty) {
      return existing;
    }
    final created = const Uuid().v4();
    await prefs.setString(_keyDeviceId, created);
    return created;
  }

  Future<String?> readAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_keyAccessToken)?.trim();
    if (saved != null && saved.isNotEmpty) {
      return saved;
    }
    final env = _envDriveAccessToken.trim();
    return env.isEmpty ? null : env;
  }

  Future<void> writeAccessToken(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAccessToken, value.trim());
  }

  Future<void> clearAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyAccessToken);
  }

  Future<String?> readSnapshotFileId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keySnapshotFileId)?.trim();
  }

  Future<void> writeSnapshotFileId(String fileId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySnapshotFileId, fileId.trim());
  }

  Future<DateTime?> readLastSyncAt() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyLastSyncAt);
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }
    return DateTime.tryParse(raw);
  }

  Future<void> writeLastSyncAt(DateTime value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLastSyncAt, value.toUtc().toIso8601String());
  }
}

final driveSyncPreferencesProvider = Provider<DriveSyncPreferences>((ref) {
  return DriveSyncPreferences();
});
