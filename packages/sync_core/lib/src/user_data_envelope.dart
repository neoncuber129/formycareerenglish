import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:shared_models/shared_models.dart';

/// Root JSON document stored in GitHub (one file per user on the backend).
class UserDataEnvelope {
  const UserDataEnvelope({
    required this.schemaVersion,
    required this.userId,
    required this.deviceId,
    required this.lastSyncAt,
    required this.items,
  });

  static const int currentSchemaVersion = 1;

  final int schemaVersion;
  final String userId;
  /// Device that wrote this snapshot (last writer).
  final String deviceId;
  final DateTime lastSyncAt;
  final List<Vocab> items;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'schema_version': schemaVersion,
      'user_id': userId,
      'device_id': deviceId,
      'last_sync_at': lastSyncAt.toUtc().toIso8601String(),
      'items': items.map((e) => e.toJson()).toList(),
    };
  }

  String toJsonString() => jsonEncode(toJson());

  static UserDataEnvelope fromJson(Map<String, dynamic> json) {
    final rawItems = (json['items'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .toList(growable: false);
    final items = rawItems.map(Vocab.fromJson).toList(growable: false);
    return UserDataEnvelope(
      schemaVersion: (json['schema_version'] as num?)?.toInt() ?? currentSchemaVersion,
      userId: (json['user_id'] as String? ?? '').trim(),
      deviceId: (json['device_id'] as String? ?? '').trim(),
      lastSyncAt: DateTime.tryParse(
            (json['last_sync_at'] as String? ?? '').trim(),
          ) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      items: items,
    );
  }

  static UserDataEnvelope fromJsonString(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Invalid user data envelope');
    }
    return UserDataEnvelope.fromJson(decoded);
  }

  /// Full snapshot checksum (optional wire integrity).
  static String computeSnapshotChecksum(UserDataEnvelope envelope) {
    final normalized = <String, dynamic>{
      'schema_version': envelope.schemaVersion,
      'user_id': envelope.userId,
      'device_id': envelope.deviceId,
      'last_sync_at': envelope.lastSyncAt.toUtc().toIso8601String(),
      'items': envelope.items.map((e) => e.toJson()).toList(),
    };
    final bytes = utf8.encode(jsonEncode(normalized));
    return sha256.convert(bytes).toString();
  }
}
