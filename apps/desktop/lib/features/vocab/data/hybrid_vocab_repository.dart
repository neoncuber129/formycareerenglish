import 'dart:async';

import 'package:shared_models/shared_models.dart';

import '../../../core/logging/logger_service.dart';
import '../domain/vocab_repository.dart';
import 'supabase_vocab_repository.dart';
import 'vocab_datasource.dart';

enum ReadStrategy { localOnly, remoteFirst }

class HybridVocabRepository implements VocabRepository {
  const HybridVocabRepository({
    required this.localStore,
    required this.remoteStore,
    required this.readStrategy,
  });

  final VocabDataSource localStore;
  final SupabaseVocabRepository remoteStore;
  final ReadStrategy readStrategy;
  String? get _currentUserId => remoteStore.currentUserId;

  @override
  Future<List<Vocab>> getAllVocab() async {
    if (readStrategy == ReadStrategy.localOnly) {
      return localStore.fetchAll();
    }

    final lastSyncedAt = await localStore.readLastSyncedAt(_currentUserId);
    final remote = await remoteStore.fetchChangesSince(
      lastSyncedAt,
    );
    if (remote.success) {
      await localStore.mergeFromRemote(remote.items);
      _advanceWatermarkFrom(remote.items);
      return localStore.fetchAll();
    }

    return localStore.fetchAll();
  }

  @override
  Future<List<Vocab>> getDueCards(DateTime now) async {
    final all = await getAllVocab();
    return all
        .where((item) => !item.nextReviewAt.isAfter(now) && !item.isArchived)
        .toList();
  }

  @override
  Future<List<Vocab>> getTrashedVocab() async {
    if (readStrategy == ReadStrategy.localOnly) {
      return localStore.fetchTrashed();
    }

    final lastSyncedAt = await localStore.readLastSyncedAt(_currentUserId);
    final remote = await remoteStore.fetchChangesSince(
      lastSyncedAt,
    );
    if (remote.success) {
      await localStore.mergeFromRemote(remote.items);
      _advanceWatermarkFrom(remote.items);
    }
    return localStore.fetchTrashed();
  }

  @override
  Future<void> updateVocabsBulk(
    List<String> ids,
    Map<String, dynamic> updates,
  ) async {
    if (ids.isEmpty) {
      return;
    }
    final now = DateTime.now();
    final found = await localStore.fetchByIds(ids);
    if (found.isEmpty) {
      return;
    }

    final syncedIds = <String>[];
    for (final v in found) {
      final next = applyVocabBulkUpdates(v, updates, now);
      syncedIds.add(next.id);
      await localStore.upsert(next);
    }

    final patch = _remoteBulkPatch(updates, now);
    unawaited(_tryBulkRemoteSync(syncedIds, patch));
  }

  @override
  Future<void> deleteVocabsBulk(List<String> ids) async {
    await updateVocabsBulk(ids, <String, dynamic>{'deletedAt': DateTime.now()});
  }

  @override
  Future<void> resetSrsBulk(List<String> ids) async {
    if (ids.isEmpty) {
      return;
    }
    final now = DateTime.now();
    final found = await localStore.fetchByIds(ids);
    if (found.isEmpty) {
      return;
    }

    final syncedIds = <String>[];
    for (final v in found) {
      final reset = v.copyWith(
        intervalDays: 1,
        easeFactor: 2.5,
        reviewCount: 0,
        nextReviewAt: now,
        updatedAt: now,
        newLearningStepIndex: 0,
      );
      syncedIds.add(reset.id);
      await localStore.upsert(reset);
    }

    final patch = <String, dynamic>{
      'updated_at': now.toIso8601String(),
      'interval_days': 1,
      'ease_factor': 2.5,
      'review_count': 0,
      'next_review_at': now.toIso8601String(),
    };
    unawaited(_tryBulkRemoteSync(syncedIds, patch));
  }

  @override
  Future<void> renameTagAcrossVocabs(String oldTag, String newTag) async {
    final oldNorm = oldTag.trim().toLowerCase();
    final newValue = newTag.trim();
    if (oldNorm.isEmpty || newValue.isEmpty) {
      return;
    }
    final all = await localStore.fetchAll();
    final now = DateTime.now();
    final updated = <Vocab>[];
    for (final vocab in all) {
      var touched = false;
      final tags = <String>[];
      for (final tag in vocab.tags) {
        if (tag.trim().toLowerCase() == oldNorm) {
          touched = true;
          if (!_containsTagIgnoreCase(tags, newValue)) {
            tags.add(newValue);
          }
        } else if (!_containsTagIgnoreCase(tags, tag)) {
          tags.add(tag);
        }
      }
      if (!touched) {
        continue;
      }
      final next = vocab.copyWith(tags: tags, updatedAt: now);
      await localStore.upsert(next);
      updated.add(next);
    }
    if (updated.isNotEmpty) {
      unawaited(_trySyncVocabsIndividually(updated));
    }
  }

  @override
  Future<void> deleteTagAcrossVocabs(String tag) async {
    final normalized = tag.trim().toLowerCase();
    if (normalized.isEmpty) {
      return;
    }
    final all = await localStore.fetchAll();
    final now = DateTime.now();
    final updated = <Vocab>[];
    for (final vocab in all) {
      final nextTags = vocab.tags
          .where((value) => value.trim().toLowerCase() != normalized)
          .toList(growable: false);
      if (nextTags.length == vocab.tags.length) {
        continue;
      }
      final next = vocab.copyWith(tags: nextTags, updatedAt: now);
      await localStore.upsert(next);
      updated.add(next);
    }
    if (updated.isNotEmpty) {
      unawaited(_trySyncVocabsIndividually(updated));
    }
  }

  Map<String, dynamic> _remoteBulkPatch(
    Map<String, dynamic> updates,
    DateTime now,
  ) {
    final p = <String, dynamic>{'updated_at': now.toIso8601String()};
    if (updates.containsKey('isArchived') && updates['isArchived'] is bool) {
      p['is_archived'] = updates['isArchived'];
    }
    if (updates.containsKey('is_archived') && updates['is_archived'] is bool) {
      p['is_archived'] = updates['is_archived'];
    }
    if (updates.containsKey('deletedAt')) {
      final v = updates['deletedAt'];
      if (v == null) {
        p['deleted_at'] = null;
      } else if (v is DateTime) {
        p['deleted_at'] = v.toIso8601String();
      } else if (v is String && v.isNotEmpty) {
        p['deleted_at'] = v;
      }
    }
    if (updates.containsKey('deleted_at')) {
      final v = updates['deleted_at'];
      if (v == null) {
        p['deleted_at'] = null;
      } else if (v is DateTime) {
        p['deleted_at'] = v.toIso8601String();
      } else if (v is String && v.isNotEmpty) {
        p['deleted_at'] = v;
      }
    }
    return p;
  }

  Future<void> _tryBulkRemoteSync(
    List<String> ids,
    Map<String, dynamic> patch,
  ) async {
    final syncedItems = await remoteStore.updateVocabsWhereIds(ids, patch);
    if (syncedItems.isNotEmpty) {
      await localStore.markSyncedVocabs(syncedItems);
      _advanceWatermarkFrom(syncedItems);
      LoggerService.logSync(
        source: 'desktop_hybrid_repo',
        stage: 'bulk_push',
        success: true,
        count: syncedItems.length,
      );
    } else {
      await localStore.markFailedByIds(ids, 'bulk_remote_sync_failed');
      LoggerService.logSync(
        source: 'desktop_hybrid_repo',
        stage: 'bulk_push',
        success: false,
        count: ids.length,
      );
    }
  }

  @override
  Future<void> saveVocab(Vocab vocab) async {
    await localStore.upsert(vocab);
    LoggerService.logSaveAction(
      source: 'desktop_hybrid_repo',
      vocabId: vocab.id,
      success: true,
    );
    unawaited(_trySyncSingle(vocab));
  }

  @override
  Future<void> updateReviewProgress(Vocab vocab) async {
    await localStore.upsert(vocab);
    unawaited(_trySyncSingle(vocab));
  }

  @override
  Future<void> syncPending() async {
    final pending = _dedupeById(await localStore.pendingSnapshot());
    LoggerService.logSync(
      source: 'desktop_hybrid_repo',
      stage: 'push_start',
      success: true,
      count: pending.length,
    );
    final pushed = await remoteStore.pushPending(pending);
    if (pushed.syncedIds.isNotEmpty) {
      await localStore.markSyncedVocabs(pushed.syncedItems);
      _advanceWatermarkFrom(pushed.syncedItems);
    }
    final failedIds = pending
        .map((item) => item.id)
        .where((id) => !pushed.syncedIds.contains(id))
        .toList(growable: false);
    if (failedIds.isNotEmpty) {
      await localStore.markFailedByIds(failedIds, 'pending_push_failed');
    }
    LoggerService.logSync(
      source: 'desktop_hybrid_repo',
      stage: 'push_done',
      success: true,
      count: pushed.syncedIds.length,
    );

    final lastSyncedAt = await localStore.readLastSyncedAt(_currentUserId);
    final remote = await remoteStore.fetchChangesSince(
      lastSyncedAt,
    );
    if (remote.success) {
      await localStore.mergeFromRemote(remote.items);
      _advanceWatermarkFrom(remote.items);
      LoggerService.logSync(
        source: 'desktop_hybrid_repo',
        stage: 'pull_done',
        success: true,
        count: remote.items.length,
      );
    } else {
      LoggerService.logSync(
        source: 'desktop_hybrid_repo',
        stage: 'pull_done',
        success: false,
      );
    }
  }

  Future<void> _trySyncSingle(Vocab vocab) async {
    final synced = await remoteStore.upsertVocab(vocab);
    if (synced != null) {
      await localStore.markSyncedVocabs(<Vocab>[synced]);
      _advanceWatermarkFrom(<Vocab>[synced]);
      LoggerService.logSync(
        source: 'desktop_hybrid_repo',
        stage: 'single_push',
        success: true,
      );
    } else {
      await localStore.markFailedByIds(<String>[vocab.id], 'single_push_failed');
      LoggerService.logSync(
        source: 'desktop_hybrid_repo',
        stage: 'single_push',
        success: false,
      );
    }
  }

  Future<void> _trySyncVocabsIndividually(List<Vocab> vocabs) async {
    final syncedIds = <String>[];
    final syncedItems = <Vocab>[];
    for (final vocab in vocabs) {
      final synced = await remoteStore.upsertVocab(vocab);
      if (synced != null) {
        syncedIds.add(vocab.id);
        syncedItems.add(synced);
      }
    }
    if (syncedIds.isNotEmpty) {
      await localStore.markSyncedVocabs(syncedItems);
      _advanceWatermarkFrom(syncedItems);
    }
    final failedIds = vocabs
        .map((v) => v.id)
        .where((id) => !syncedIds.contains(id))
        .toList(growable: false);
    if (failedIds.isNotEmpty) {
      await localStore.markFailedByIds(failedIds, 'bulk_item_push_failed');
    }
    LoggerService.logSync(
      source: 'desktop_hybrid_repo',
      stage: 'bulk_tag_push',
      success: syncedIds.length == vocabs.length,
      count: syncedIds.length,
    );
  }

  bool _containsTagIgnoreCase(List<String> tags, String target) {
    return tags.any((item) => item.toLowerCase() == target.toLowerCase());
  }

  List<Vocab> _dedupeById(List<Vocab> items) {
    final map = <String, Vocab>{};
    for (final item in items) {
      map[item.id] = item;
    }
    return map.values.toList();
  }

  Future<void> handleAuthTransition({
    required String? previousUserId,
    required String? nextUserId,
  }) async {
    if (previousUserId == nextUserId) {
      return;
    }
    if (nextUserId == null || nextUserId.trim().isEmpty) {
      return;
    }
    await _mergeGuestDataIfNeeded(nextUserId.trim());
  }

  Future<void> _mergeGuestDataIfNeeded(String userId) async {
    if (await localStore.hasCompletedGuestMerge(userId)) {
      return;
    }
    final guestPending = _dedupeById(await localStore.pendingSnapshot());
    if (guestPending.isNotEmpty) {
      final pushed = await remoteStore.pushPending(guestPending);
      if (pushed.syncedItems.isNotEmpty) {
        await localStore.markSyncedVocabs(pushed.syncedItems);
        _advanceWatermarkFrom(pushed.syncedItems);
      }
    }
    final remote = await remoteStore.fetchAll();
    if (remote.success) {
      await localStore.mergeFromRemote(remote.items);
      _advanceWatermarkFrom(remote.items);
    }
    await localStore.markGuestMergeCompleted(userId);
  }

  void _advanceWatermarkFrom(List<Vocab> items) {
    if (items.isEmpty) {
      return;
    }
    var latest = items.first.updatedAt;
    for (final item in items.skip(1)) {
      if (item.updatedAt.isAfter(latest)) {
        latest = item.updatedAt;
      }
    }
    unawaited(localStore.writeLastSyncedAt(_currentUserId, latest));
  }
}
