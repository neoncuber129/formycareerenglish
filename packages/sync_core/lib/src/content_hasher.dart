import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:shared_models/shared_models.dart';

/// SHA-256 of a canonical JSON payload of business fields only (excludes
/// sync metadata: `sync_version`, `last_modified_by`, `content_hash`).
class ContentHasher {
  const ContentHasher._();

  static String hashVocabPayload(Vocab v) {
    final bytes = utf8.encode(jsonEncode(_payloadMap(v)));
    return sha256.convert(bytes).toString();
  }

  static Map<String, dynamic> _payloadMap(Vocab v) {
    final m = Map<String, dynamic>.from(v.toJson())
      ..remove('sync_version')
      ..remove('last_modified_by')
      ..remove('content_hash');
    return _sortedDeep(m);
  }

  static dynamic _sortedDeep(dynamic value) {
    if (value is Map<String, dynamic>) {
      final keys = value.keys.toList()..sort();
      return <String, dynamic>{
        for (final k in keys) k: _sortedDeep(value[k]),
      };
    }
    if (value is List) {
      return value.map(_sortedDeep).toList();
    }
    return value;
  }
}
