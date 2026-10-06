import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:shared_models/shared_models.dart';

class DriveSyncSnapshot {
  const DriveSyncSnapshot({
    required this.schemaVersion,
    required this.deviceId,
    required this.updatedAt,
    required this.checksum,
    required this.vocabItems,
  });

  final int schemaVersion;
  final String deviceId;
  final DateTime updatedAt;
  final String checksum;
  final List<Vocab> vocabItems;

  static const int currentSchemaVersion = 1;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'schema_version': schemaVersion,
      'device_id': deviceId,
      'updated_at': updatedAt.toUtc().toIso8601String(),
      'checksum': checksum,
      'vocab_items': vocabItems.map((item) => item.toJson()).toList(),
    };
  }

  String toJsonString() => jsonEncode(toJson());

  static DriveSyncSnapshot fromJson(Map<String, dynamic> json) {
    final rawItems = (json['vocab_items'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .toList(growable: false);
    final items = rawItems.map(Vocab.fromJson).toList(growable: false);
    return DriveSyncSnapshot(
      schemaVersion: (json['schema_version'] as num?)?.toInt() ?? 1,
      deviceId: (json['device_id'] as String? ?? '').trim(),
      updatedAt:
          DateTime.tryParse((json['updated_at'] as String? ?? '').trim()) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      checksum: (json['checksum'] as String? ?? '').trim(),
      vocabItems: items,
    );
  }

  static DriveSyncSnapshot fromJsonString(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Invalid drive snapshot payload');
    }
    final snapshot = DriveSyncSnapshot.fromJson(decoded);
    if (!snapshot.hasValidChecksum()) {
      throw const FormatException('Snapshot checksum mismatch');
    }
    return snapshot;
  }

  bool hasValidChecksum() {
    final expected = computeChecksum(
      vocabItems: vocabItems,
      schemaVersion: schemaVersion,
      deviceId: deviceId,
      updatedAt: updatedAt,
    );
    return expected == checksum;
  }

  static String computeChecksum({
    required List<Vocab> vocabItems,
    required int schemaVersion,
    required String deviceId,
    required DateTime updatedAt,
  }) {
    final normalized = <String, dynamic>{
      'schema_version': schemaVersion,
      'device_id': deviceId,
      'updated_at': updatedAt.toUtc().toIso8601String(),
      'vocab_items': vocabItems
          .map((item) => item.toJson())
          .toList(growable: false),
    };
    final bytes = utf8.encode(jsonEncode(normalized));
    return sha256.convert(bytes).toString();
  }
}
