import 'package:shared_models/shared_models.dart';

enum SyncStatus { pending, synced }

class VocabLocalMapper {
  const VocabLocalMapper._();

  static const String _vocabKey = 'vocab';
  static const String _syncStatusKey = 'sync_status';
  static const String _lastErrorKey = 'sync_last_error';
  static const String _retryCountKey = 'sync_retry_count';

  static Map<String, dynamic> toRecord(
    Vocab vocab, {
    required SyncStatus syncStatus,
    String? lastError,
    int retryCount = 0,
  }) {
    return <String, dynamic>{
      _vocabKey: vocab.toJson(),
      _syncStatusKey: syncStatus.name,
      _lastErrorKey: lastError,
      _retryCountKey: retryCount,
    };
  }

  static Vocab fromRecord(Map<dynamic, dynamic> record) {
    if (_isLegacyVocabJson(record)) {
      return fromLegacyMap(record);
    }

    final vocabJson = Map<String, dynamic>.from(
      (record[_vocabKey] as Map<dynamic, dynamic>?) ?? <dynamic, dynamic>{},
    );
    return Vocab.fromJson(vocabJson);
  }

  static SyncStatus readSyncStatus(Map<dynamic, dynamic> record) {
    if (_isLegacyVocabJson(record)) {
      return SyncStatus.pending;
    }
    final rawStatus = record[_syncStatusKey] as String?;
    if (rawStatus == SyncStatus.synced.name) {
      return SyncStatus.synced;
    }
    return SyncStatus.pending;
  }

  static Vocab fromLegacyMap(Map<dynamic, dynamic> map) {
    final normalized = Map<String, dynamic>.from(map);
    return Vocab.fromJson(normalized);
  }

  static String? readLastError(Map<dynamic, dynamic> record) {
    if (_isLegacyVocabJson(record)) {
      return null;
    }
    final value = record[_lastErrorKey];
    if (value == null) {
      return null;
    }
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  static int readRetryCount(Map<dynamic, dynamic> record) {
    if (_isLegacyVocabJson(record)) {
      return 0;
    }
    final value = record[_retryCountKey];
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return 0;
  }

  static bool _isLegacyVocabJson(Map<dynamic, dynamic> record) {
    return record.containsKey('source_text') && !record.containsKey(_vocabKey);
  }
}
