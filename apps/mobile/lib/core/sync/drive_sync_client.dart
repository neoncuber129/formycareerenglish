import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import 'drive_sync_preferences.dart';
import 'drive_sync_snapshot.dart';

class DriveRemoteMetadata {
  const DriveRemoteMetadata({
    required this.fileId,
    required this.modifiedTime,
  });

  final String fileId;
  final DateTime modifiedTime;
}

class DriveSyncClient {
  DriveSyncClient(this._preferences, {http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  final DriveSyncPreferences _preferences;
  final http.Client _httpClient;

  static const _baseApi = 'https://www.googleapis.com/drive/v3/files';
  static const _uploadApi =
      'https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart';
  static const _snapshotName = 'formycareer_vocab_snapshot.json';

  Future<bool> signInIfNeeded() async {
    final token = await _preferences.readAccessToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> saveAccessToken(String token) async {
    await _preferences.writeAccessToken(token);
  }

  Future<String?> readAccessToken() async {
    return _preferences.readAccessToken();
  }

  Future<void> clearAccessToken() async {
    await _preferences.clearAccessToken();
  }

  Future<DriveRemoteMetadata?> getRemoteMetadata() async {
    final token = await _preferences.readAccessToken();
    if (token == null || token.isEmpty) {
      return null;
    }
    final uri = Uri.parse(_baseApi).replace(
      queryParameters: <String, String>{
        'spaces': 'appDataFolder',
        'q': "name='$_snapshotName' and 'appDataFolder' in parents and trashed=false",
        'fields': 'files(id,modifiedTime)',
        'pageSize': '1',
      },
    );
    final response = await _withRetry(
      () => _httpClient.get(
        uri,
        headers: _headers(token),
      ),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Drive metadata request failed: ${response.body}');
    }
    final jsonMap = jsonDecode(response.body) as Map<String, dynamic>;
    final files = (jsonMap['files'] as List<dynamic>? ?? const <dynamic>[]);
    if (files.isEmpty) {
      return null;
    }
    final first = files.first as Map<String, dynamic>;
    final fileId = (first['id'] as String? ?? '').trim();
    if (fileId.isEmpty) {
      return null;
    }
    final modified = DateTime.tryParse(first['modifiedTime'] as String? ?? '');
    if (modified == null) {
      return null;
    }
    await _preferences.writeSnapshotFileId(fileId);
    return DriveRemoteMetadata(fileId: fileId, modifiedTime: modified);
  }

  Future<DriveSyncSnapshot?> downloadSnapshot() async {
    final token = await _preferences.readAccessToken();
    if (token == null || token.isEmpty) {
      return null;
    }
    var fileId = await _preferences.readSnapshotFileId();
    fileId ??= (await getRemoteMetadata())?.fileId;
    if (fileId == null || fileId.isEmpty) {
      return null;
    }
    final uri = Uri.parse('$_baseApi/$fileId').replace(
      queryParameters: const <String, String>{'alt': 'media'},
    );
    final response = await _withRetry(
      () => _httpClient.get(uri, headers: _headers(token)),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Drive download failed: ${response.body}');
    }
    return DriveSyncSnapshot.fromJsonString(response.body);
  }

  Future<void> uploadSnapshot(DriveSyncSnapshot snapshot) async {
    final token = await _preferences.readAccessToken();
    if (token == null || token.isEmpty) {
      throw Exception('Drive access token is missing');
    }
    final existingFileId = await _preferences.readSnapshotFileId();
    final metadata = <String, dynamic>{
      'name': _snapshotName,
      'parents': <String>['appDataFolder'],
    };
    final snapshotJson = snapshot.toJsonString();
    await _persistTempSnapshot(snapshotJson);
    final multipartBody = _multipartBody(metadata, snapshotJson);

    final uri = existingFileId == null || existingFileId.isEmpty
        ? Uri.parse(_uploadApi)
        : Uri.parse(
            'https://www.googleapis.com/upload/drive/v3/files/$existingFileId?uploadType=multipart',
          );
    final response = existingFileId == null || existingFileId.isEmpty
        ? await _withRetry(
            () => _httpClient.post(
              uri,
              headers: _multipartHeaders(token, multipartBody.boundary),
              body: multipartBody.payload,
            ),
          )
        : await _withRetry(
            () => _httpClient.patch(
              uri,
              headers: _multipartHeaders(token, multipartBody.boundary),
              body: multipartBody.payload,
            ),
          );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Drive upload failed: ${response.body}');
    }
    final responseJson = jsonDecode(response.body) as Map<String, dynamic>;
    final uploadedId = (responseJson['id'] as String? ?? '').trim();
    if (uploadedId.isNotEmpty) {
      await _preferences.writeSnapshotFileId(uploadedId);
    }
    await _preferences.writeLastSyncAt(DateTime.now().toUtc());
  }

  Map<String, String> _headers(String token) => <String, String>{
    'Authorization': 'Bearer $token',
    'Accept': 'application/json',
  };

  Map<String, String> _multipartHeaders(String token, String boundary) {
    return <String, String>{
      ..._headers(token),
      'Content-Type': 'multipart/related; boundary=$boundary',
    };
  }

  _MultipartPayload _multipartBody(
    Map<String, dynamic> metadata,
    String jsonContent,
  ) {
    final boundary =
        'fmc_boundary_${DateTime.now().millisecondsSinceEpoch.toString()}';
    final payload = StringBuffer()
      ..write('--$boundary\r\n')
      ..write('Content-Type: application/json; charset=UTF-8\r\n\r\n')
      ..write('${jsonEncode(metadata)}\r\n')
      ..write('--$boundary\r\n')
      ..write('Content-Type: application/json; charset=UTF-8\r\n\r\n')
      ..write('$jsonContent\r\n')
      ..write('--$boundary--');
    return _MultipartPayload(boundary: boundary, payload: payload.toString());
  }

  Future<http.Response> _withRetry(
    Future<http.Response> Function() request, {
    int attempts = 3,
  }) async {
    Object? lastError;
    for (var i = 0; i < attempts; i++) {
      try {
        final response = await request();
        if (response.statusCode >= 500 && i < attempts - 1) {
          await Future<void>.delayed(Duration(milliseconds: 300 * (i + 1)));
          continue;
        }
        return response;
      } catch (error) {
        lastError = error;
        if (i < attempts - 1) {
          await Future<void>.delayed(Duration(milliseconds: 300 * (i + 1)));
          continue;
        }
      }
    }
    throw Exception('Drive request failed after retry: $lastError');
  }

  Future<void> _persistTempSnapshot(String payload) async {
    try {
      final tempDir = Directory.systemTemp;
      final tempFile = File(
        '${tempDir.path}${Platform.pathSeparator}formycareer_drive_snapshot_tmp.json',
      );
      await tempFile.writeAsString(payload, flush: true);
    } catch (_) {
      // Temp persistence is best-effort only.
    }
  }
}

class _MultipartPayload {
  const _MultipartPayload({required this.boundary, required this.payload});
  final String boundary;
  final String payload;
}

final driveSyncClientProvider = Provider<DriveSyncClient>((ref) {
  final preferences = ref.watch(driveSyncPreferencesProvider);
  return DriveSyncClient(preferences);
});

final driveAccessTokenProvider = FutureProvider<String?>((ref) async {
  final preferences = ref.watch(driveSyncPreferencesProvider);
  return preferences.readAccessToken();
});

final driveLastSyncAtProvider = FutureProvider<DateTime?>((ref) async {
  final preferences = ref.watch(driveSyncPreferencesProvider);
  return preferences.readLastSyncAt();
});
