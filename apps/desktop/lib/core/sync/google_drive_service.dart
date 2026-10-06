import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;

import '../auth/auth_service.dart';
import 'drive_sync_snapshot.dart';
import 'drive_sync_preferences.dart';

class DriveSnapshotEnvelope {
  const DriveSnapshotEnvelope({
    required this.snapshot,
    required this.lastModifiedTimestamp,
  });

  final DriveSyncSnapshot snapshot;
  final DateTime lastModifiedTimestamp;
}

class GoogleDriveService {
  GoogleDriveService(this._authService, this._preferences);

  final AuthService _authService;
  final DriveSyncPreferences _preferences;
  static const String _syncFileName = 'sync_data_v1.json';
  static const String _appVersion = String.fromEnvironment(
    'APP_VERSION',
    defaultValue: 'dev',
  );

  Future<DriveSnapshotEnvelope?> fetchSnapshot() async {
    final (api, _) = await _driveApi();
    final file = await _findSyncFile(api);
    if (file == null || file.id == null || file.id!.isEmpty) {
      return null;
    }
    drive.Media media;
    try {
      media = await api.files.get(
            file.id!,
            downloadOptions: drive.DownloadOptions.fullMedia,
          )
          as drive.Media;
    } catch (error) {
      throw _mapDriveError(error);
    }
    final bytes = <int>[];
    await for (final chunk in media.stream) {
      bytes.addAll(chunk);
    }
    final content = utf8.decode(bytes);
    final snapshot = DriveSyncSnapshot.fromJsonString(content);
    final tsRaw = (file.appProperties?['last_modified_timestamp'] ?? '').trim();
    final lastModified =
        DateTime.tryParse(tsRaw) ?? file.modifiedTime ?? snapshot.updatedAt;
    return DriveSnapshotEnvelope(
      snapshot: snapshot,
      lastModifiedTimestamp: lastModified.toUtc(),
    );
  }

  Future<void> uploadSnapshot(DriveSyncSnapshot snapshot) async {
    final (api, session) = await _driveApi();
    final existing = await _findSyncFile(api);
    final metadata = drive.File()
      ..name = _syncFileName
      ..appProperties = <String, String>{
        'device_id': session.deviceId,
        'app_version': _appVersion,
        'last_modified_timestamp': snapshot.updatedAt.toUtc().toIso8601String(),
      };
    final media = drive.Media(
      Stream<List<int>>.value(utf8.encode(snapshot.toJsonString())),
      utf8.encode(snapshot.toJsonString()).length,
    );
    if (existing?.id != null && existing!.id!.isNotEmpty) {
      try {
        await api.files.update(metadata, existing.id!, uploadMedia: media);
      } catch (error) {
        throw _mapDriveError(error);
      }
      await _preferences.writeSnapshotFileId(existing.id!);
    } else {
      drive.File created;
      metadata.parents = <String>['appDataFolder'];
      try {
        created = await api.files.create(metadata, uploadMedia: media);
      } catch (error) {
        throw _mapDriveError(error);
      }
      if (created.id != null && created.id!.isNotEmpty) {
        await _preferences.writeSnapshotFileId(created.id!);
      }
    }
    await _preferences.writeLastSyncAt(DateTime.now().toUtc());
  }

  Future<drive.File?> _findSyncFile(drive.DriveApi api) async {
    drive.FileList listing;
    try {
      listing = await api.files.list(
        spaces: 'appDataFolder',
        q: "name='$_syncFileName' and trashed=false and 'appDataFolder' in parents",
        $fields: 'files(id,name,modifiedTime,appProperties)',
        pageSize: 1,
      );
    } catch (error) {
      throw _mapDriveError(error);
    }
    final files = listing.files;
    if (files == null || files.isEmpty) {
      return null;
    }
    return files.first;
  }

  Future<(drive.DriveApi, AuthSession)> _driveApi() async {
    final session = await _authService.ensureAuthenticated();
    if (session == null) {
      throw const SyncException(
        code: SyncErrorCode.tokenRevoked,
        message: 'Token revoked or unavailable. Please sign in again.',
      );
    }
    final client = _BearerClient(session.accessToken);
    return (drive.DriveApi(client), session);
  }
}

SyncException _mapDriveError(Object error) {
  final text = error.toString().toLowerCase();
  if (text.contains('401') ||
      text.contains('invalid_grant') ||
      text.contains('invalid credentials')) {
    return const SyncException(
      code: SyncErrorCode.tokenRevoked,
      message: 'Token revoked or expired. Please sign in again.',
    );
  }
  if (text.contains('storagequotaexceeded') ||
      (text.contains('403') && text.contains('quota'))) {
    return const SyncException(
      code: SyncErrorCode.driveFull,
      message: 'Google Drive storage is full.',
    );
  }
  if (text.contains('insufficient authentication scopes')) {
    return const SyncException(
      code: SyncErrorCode.insufficientScope,
      message:
          'Drive permission is missing (drive.appdata). Please sign in again and grant access.',
    );
  }
  if (text.contains('500') || text.contains('502') || text.contains('503')) {
    return const SyncException(
      code: SyncErrorCode.network,
      message: 'Drive service is temporarily unavailable.',
    );
  }
  return SyncException(
    code: SyncErrorCode.unknown,
    message: error.toString(),
  );
}

enum SyncErrorCode { tokenRevoked, insufficientScope, driveFull, network, unknown }

class SyncException implements Exception {
  const SyncException({required this.code, required this.message});
  final SyncErrorCode code;
  final String message;

  @override
  String toString() => message;
}

class _BearerClient extends http.BaseClient {
  _BearerClient(this._token);
  final String _token;
  final http.Client _inner = http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers['Authorization'] = 'Bearer $_token';
    request.headers['Accept'] = 'application/json';
    return _inner.send(request);
  }
}

final googleDriveServiceProvider = Provider<GoogleDriveService>((ref) {
  final auth = ref.watch(authServiceProvider);
  final preferences = ref.watch(driveSyncPreferencesProvider);
  return GoogleDriveService(auth, preferences);
});
