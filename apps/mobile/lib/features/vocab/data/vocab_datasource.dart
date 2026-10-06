import 'dart:convert';
import 'dart:async';

import 'package:sqflite_common/sqlite_api.dart';
import 'package:shared_models/shared_models.dart';

import '../../../core/local/local_db.dart';
import 'vocab_local_mapper.dart';

class VocabDataSource {
  VocabDataSource({
    this.client,
    required this.profileId,
  });

  final Object? client;
  final String profileId;
  final List<Vocab> _mockStore = <Vocab>[];
  Database? get _db => LocalDb.tryGetDatabase();
  static const String _guestScope = '__guest__';
  static const String _watermarkPrefix = 'sync_watermark:';
  static const String _guestMergePrefix = 'guest_merge_done:';

  String get _pid =>
      profileId.trim().isEmpty ? kDefaultLocalProfileId : profileId.trim();

  Future<List<Vocab>> fetchAll() async {
    final db = _db;
    if (db == null) {
      final active = _mockStore.where((v) => v.deletedAt == null).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return active;
    }

    final localRecords = (await db.query(
      'vocab_records',
      where: 'profile_id = ?',
      whereArgs: <Object?>[_pid],
    ))
        .map(_rowToVocab)
        .where((v) => v.deletedAt == null)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    _mockStore
      ..clear()
      ..addAll(localRecords);
    return localRecords;
  }

  /// Soft-deleted rows (recycle bin), newest [deletedAt] first.
  Future<List<Vocab>> fetchTrashed() async {
    final db = _db;
    if (db == null) {
      return _mockStore
          .where((v) => v.deletedAt != null)
          .toList()
        ..sort(
          (a, b) => b.deletedAt!.compareTo(a.deletedAt!),
        );
    }

    return (await db.query(
      'vocab_records',
      where: 'profile_id = ?',
      whereArgs: <Object?>[_pid],
    ))
        .map(_rowToVocab)
        .where((v) => v.deletedAt != null)
        .toList()
      ..sort(
        (a, b) => b.deletedAt!.compareTo(a.deletedAt!),
      );
  }

  /// Reads by id from local storage (includes trashed rows).
  Future<List<Vocab>> fetchByIds(List<String> ids) async {
    if (ids.isEmpty) {
      return const <Vocab>[];
    }
    final db = _db;
    if (db == null) {
      final out = <Vocab>[];
      for (final id in ids) {
        for (final v in _mockStore) {
          if (v.id == id) {
            out.add(v);
            break;
          }
        }
      }
      return out;
    }

    final out = <Vocab>[];
    for (final id in ids) {
      final row = await db.query(
        'vocab_records',
        where: 'vocab_id = ? AND profile_id = ?',
        whereArgs: <Object?>[id, _pid],
        limit: 1,
      );
      if (row.isNotEmpty) {
        out.add(_rowToVocab(row.first));
      }
    }
    return out;
  }

  Future<void> upsert(Vocab vocab) async {
    _upsertLocal(vocab, syncStatus: SyncStatus.pending);
  }

  Future<List<Vocab>> fetchDue(DateTime now) async {
    final all = await fetchAll();
    return all
        .where(
          (item) =>
              !item.nextReviewAt.isAfter(now) && !item.isArchived,
        )
        .toList();
  }

  Future<void> syncPending() async {
    return;
  }

  void _upsertLocal(
    Vocab vocab, {
    required SyncStatus syncStatus,
    String? lastError,
    int retryCount = 0,
  }) {
    final index = _mockStore.indexWhere((item) => item.id == vocab.id);
    if (index == -1) {
      _mockStore.add(vocab);
    } else {
      _mockStore[index] = vocab;
    }

    final db = _db;
    if (db == null) {
      return;
    }
    unawaited(
      db.insert(
        'vocab_records',
        _vocabRow(
          vocab,
          syncStatus: syncStatus.name,
          lastError: lastError,
          retryCount: retryCount,
        ),
        conflictAlgorithm: ConflictAlgorithm.replace,
      ),
    );
  }

  Future<void> _mergeRemoteIntoMock(List<Vocab> remoteItems) async {
    for (final remote in remoteItems) {
      final localIndex = _mockStore.indexWhere((item) => item.id == remote.id);
      if (localIndex == -1) {
        _mockStore.add(remote);
        _upsertLocal(remote, syncStatus: SyncStatus.synced);
        continue;
      }

      // Keep local unsynced edits until they are pushed successfully.
      if ((await _syncStatusById(remote.id)) == SyncStatus.pending) {
        continue;
      }

      final local = _mockStore[localIndex];
      if (remote.updatedAt.isAfter(local.updatedAt)) {
        _mockStore[localIndex] = remote;
        _upsertLocal(remote, syncStatus: SyncStatus.synced);
      }
    }
  }

  Future<SyncStatus> _syncStatusById(String id) async {
    final db = _db;
    if (db == null) {
      return SyncStatus.pending;
    }
    final rows = await db.query(
      'vocab_records',
      columns: <String>['sync_status'],
      where: 'vocab_id = ? AND profile_id = ?',
      whereArgs: <Object?>[id, _pid],
      limit: 1,
    );
    if (rows.isEmpty) {
      return SyncStatus.pending;
    }
    final syncStatus = (rows.first['sync_status'] as String? ?? '').trim();
    return syncStatus == SyncStatus.synced.name
        ? SyncStatus.synced
        : SyncStatus.pending;
  }

  Future<List<Vocab>> pendingSnapshot() async {
    final db = _db;
    if (db == null) {
      return const <Vocab>[];
    }
    final rows = await db.query(
      'vocab_records',
      where: 'sync_status = ? AND profile_id = ?',
      whereArgs: <Object?>[SyncStatus.pending.name, _pid],
    );
    return rows.map(_rowToVocab).toList(growable: false);
  }

  Future<void> clearPending() async {
    final db = _db;
    if (db == null) {
      return;
    }
    await db.transaction((txn) async {
      await txn.update(
        'vocab_records',
        <String, Object?>{
          'sync_status': SyncStatus.synced.name,
          'retry_count': 0,
          'last_error': null,
        },
        where: 'sync_status = ? AND profile_id = ?',
        whereArgs: <Object?>[SyncStatus.pending.name, _pid],
      );
    });
  }

  Future<void> markSyncedByIds(List<String> ids) async {
    if (ids.isEmpty) {
      return;
    }
    final db = _db;
    if (db == null) {
      return;
    }
    await db.transaction((txn) async {
      for (final id in ids) {
        final row = await txn.query(
          'vocab_records',
          where: 'vocab_id = ? AND profile_id = ?',
          whereArgs: <Object?>[id, _pid],
          limit: 1,
        );
        if (row.isEmpty) {
          continue;
        }
        final current = row.first;
        await txn.update(
          'vocab_records',
          <String, Object?>{
            ...current,
            'sync_status': SyncStatus.synced.name,
            'retry_count': 0,
            'last_error': null,
          },
          where: 'vocab_id = ? AND profile_id = ?',
          whereArgs: <Object?>[id, _pid],
        );
      }
    });
  }

  Future<void> markSyncedVocabs(List<Vocab> vocabs) async {
    if (vocabs.isEmpty) {
      return;
    }
    final db = _db;
    for (final vocab in vocabs) {
      final index = _mockStore.indexWhere((item) => item.id == vocab.id);
      if (index == -1) {
        _mockStore.add(vocab);
      } else {
        _mockStore[index] = vocab;
      }
      if (db == null) {
        continue;
      }
      await db.insert(
        'vocab_records',
        _vocabRow(
          vocab,
          syncStatus: SyncStatus.synced.name,
          retryCount: 0,
          lastError: null,
        ),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<void> markFailedByIds(List<String> ids, String error) async {
    if (ids.isEmpty) {
      return;
    }
    final db = _db;
    if (db == null) {
      return;
    }
    final normalizedError = error.trim().isEmpty ? 'sync_failed' : error.trim();
    await db.transaction((txn) async {
      for (final id in ids) {
        final rows = await txn.query(
          'vocab_records',
          columns: <String>['retry_count'],
          where: 'vocab_id = ? AND profile_id = ?',
          whereArgs: <Object?>[id, _pid],
          limit: 1,
        );
        if (rows.isEmpty) {
          continue;
        }
        final retryCount = (rows.first['retry_count'] as int? ?? 0) + 1;
        await txn.update(
          'vocab_records',
          <String, Object?>{
            'sync_status': SyncStatus.pending.name,
            'last_error': normalizedError,
            'retry_count': retryCount,
          },
          where: 'vocab_id = ? AND profile_id = ?',
          whereArgs: <Object?>[id, _pid],
        );
      }
    });
  }

  String syncScope(String? userId) {
    final t = userId?.trim() ?? '';
    if (t.isEmpty) {
      return _guestScope;
    }
    return t;
  }

  String _watermarkStorageKey(String? userId) =>
      '$_watermarkPrefix${syncScope(userId)}::$_pid';

  Future<DateTime?> readLastSyncedAt(String? userId) async {
    final db = _db;
    if (db == null) {
      return null;
    }
    final key = _watermarkStorageKey(userId);
    final rows = await db.query(
      'app_settings',
      columns: <String>['string_value'],
      where: 'key = ?',
      whereArgs: <Object?>[key],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return DateTime.tryParse((rows.first['string_value'] as String? ?? '').trim());
  }

  Future<void> writeLastSyncedAt(String? userId, DateTime timestamp) async {
    final db = _db;
    if (db == null) {
      return;
    }
    final key = _watermarkStorageKey(userId);
    await db.insert(
      'app_settings',
      <String, Object?>{
        'key': key,
        'string_value': timestamp.toUtc().toIso8601String(),
        'bool_value': null,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<bool> hasCompletedGuestMerge(String userId) async {
    final db = _db;
    if (db == null) {
      return false;
    }
    final key = '$_guestMergePrefix$userId::$_pid';
    final rows = await db.query(
      'app_settings',
      columns: <String>['bool_value'],
      where: 'key = ?',
      whereArgs: <Object?>[key],
      limit: 1,
    );
    return rows.isNotEmpty && (rows.first['bool_value'] as int? ?? 0) == 1;
  }

  Future<void> markGuestMergeCompleted(String userId) async {
    final db = _db;
    if (db == null) {
      return;
    }
    final key = '$_guestMergePrefix$userId::$_pid';
    await db.insert(
      'app_settings',
      <String, Object?>{'key': key, 'string_value': null, 'bool_value': 1},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> mergeFromRemote(List<Vocab> remoteItems) async {
    await _mergeRemoteIntoMock(remoteItems);
  }

  Future<void> replaceAllFromSnapshot(List<Vocab> items) async {
    _mockStore
      ..clear()
      ..addAll(items);
    final db = _db;
    if (db == null) {
      return;
    }
    await db.transaction((txn) async {
      await txn.delete(
        'vocab_records',
        where: 'profile_id = ?',
        whereArgs: <Object?>[_pid],
      );
      for (final item in items) {
        await txn.insert(
          'vocab_records',
          _vocabRow(item, syncStatus: SyncStatus.synced.name, retryCount: 0),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  Future<List<Vocab>> exportAllForSnapshot() async {
    final db = _db;
    if (db == null) {
      return List<Vocab>.from(_mockStore, growable: false);
    }
    return (await db.query(
      'vocab_records',
      where: 'profile_id = ?',
      whereArgs: <Object?>[_pid],
    ))
        .map(_rowToVocab)
        .toList(growable: false);
  }

  Future<DateTime> latestUpdatedAt() async {
    final all = await exportAllForSnapshot();
    if (all.isEmpty) {
      return DateTime.fromMillisecondsSinceEpoch(0);
    }
    var latest = all.first.updatedAt;
    for (final item in all.skip(1)) {
      if (item.updatedAt.isAfter(latest)) {
        latest = item.updatedAt;
      }
    }
    return latest;
  }

  /// Removes legacy mock/test records accidentally persisted by older builds.
  Future<int> purgeLegacyMockRecords() async {
    final db = _db;
    if (db == null) {
      final before = _mockStore.length;
      _mockStore.removeWhere(_isLegacyMockTestRecord);
      return before - _mockStore.length;
    }

    final all = await db.query(
      'vocab_records',
      columns: <String>['vocab_id', 'payload_json'],
      where: 'profile_id = ?',
      whereArgs: <Object?>[_pid],
    );
    final toDelete = <String>[];
    for (final row in all) {
      final vocab = _rowToVocab(row);
      if (_isLegacyMockTestRecord(vocab)) {
        toDelete.add(vocab.id);
      }
    }
    if (toDelete.isEmpty) {
      return 0;
    }
    await db.transaction((txn) async {
      for (final id in toDelete) {
        await txn.delete(
          'vocab_records',
          where: 'vocab_id = ? AND profile_id = ?',
          whereArgs: <Object?>[id, _pid],
        );
      }
    });
    _mockStore.removeWhere(_isLegacyMockTestRecord);
    return toDelete.length;
  }

  Vocab _rowToVocab(Map<String, Object?> row) {
    final decoded = jsonDecode((row['payload_json'] as String? ?? '{}'));
    if (decoded is Map<String, dynamic>) {
      return Vocab.fromJson(decoded);
    }
    return Vocab.fromJson(const <String, dynamic>{});
  }

  Map<String, Object?> _vocabRow(
    Vocab vocab, {
    required String syncStatus,
    String? lastError,
    int retryCount = 0,
  }) {
    return <String, Object?>{
      'vocab_id': vocab.id,
      'payload_json': jsonEncode(vocab.toJson()),
      'created_at': vocab.createdAt.toUtc().toIso8601String(),
      'updated_at': vocab.updatedAt.toUtc().toIso8601String(),
      'deleted_at': vocab.deletedAt?.toUtc().toIso8601String(),
      'next_review_at': vocab.nextReviewAt.toUtc().toIso8601String(),
      'is_archived': vocab.isArchived ? 1 : 0,
      'sync_status': syncStatus,
      'last_error': lastError,
      'retry_count': retryCount,
      'profile_id': _pid,
    };
  }

  bool _isLegacyMockTestRecord(Vocab item) {
    final source = item.sourceText.trim().toLowerCase();
    final translated = item.translatedText.trim().toLowerCase();
    final sourceApp = item.sourceApp.trim().toLowerCase();
    final tags = item.tags.map((tag) => tag.trim().toLowerCase()).toSet();
    if (source == 'hello from mock ocr') {
      return true;
    }
    if (translated == 'nghia: hello from mock ocr') {
      return true;
    }
    if (sourceApp.contains('mock ocr')) {
      return true;
    }
    return tags.contains('mock') || tags.contains('test') || tags.contains('fixture');
  }
}
