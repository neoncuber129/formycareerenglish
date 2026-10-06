import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:settings_core/settings_core.dart';
import 'package:shared_models/shared_models.dart';

import '../domain/vocab_repository.dart';
import 'vocab_datasource.dart';

class VocabRepositoryImpl implements VocabRepository {
  const VocabRepositoryImpl(this._dataSource);

  final VocabDataSource _dataSource;

  @override
  Future<List<Vocab>> getAllVocab() {
    return _dataSource.fetchAll();
  }

  @override
  Future<List<Vocab>> getDueCards(DateTime now) {
    return _dataSource.fetchDue(now);
  }

  @override
  Future<void> saveVocab(Vocab vocab) {
    return _dataSource.upsert(vocab);
  }

  @override
  Future<void> updateReviewProgress(Vocab vocab) {
    return _dataSource.upsert(vocab);
  }

  @override
  Future<void> syncPending() {
    return _dataSource.syncPending();
  }

  @override
  Future<List<Vocab>> getTrashedVocab() {
    return _dataSource.fetchTrashed();
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
    final found = await _dataSource.fetchByIds(ids);
    for (final v in found) {
      await _dataSource.upsert(applyVocabBulkUpdates(v, updates, now));
    }
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
    final found = await _dataSource.fetchByIds(ids);
    for (final v in found) {
      await _dataSource.upsert(
        v.copyWith(
          intervalDays: 1,
          easeFactor: 2.5,
          reviewCount: 0,
          nextReviewAt: now,
          updatedAt: now,
          newLearningStepIndex: 0,
        ),
      );
    }
  }

  @override
  Future<void> renameTagAcrossVocabs(String oldTag, String newTag) async {
    final oldNorm = oldTag.trim().toLowerCase();
    final newValue = newTag.trim();
    if (oldNorm.isEmpty || newValue.isEmpty) {
      return;
    }
    final now = DateTime.now();
    final all = await _dataSource.fetchAll();
    for (final vocab in all) {
      var touched = false;
      final tags = <String>[];
      for (final tag in vocab.tags) {
        if (tag.trim().toLowerCase() == oldNorm) {
          touched = true;
          if (!tags.any((t) => t.toLowerCase() == newValue.toLowerCase())) {
            tags.add(newValue);
          }
        } else if (!tags.any((t) => t.toLowerCase() == tag.toLowerCase())) {
          tags.add(tag);
        }
      }
      if (!touched) {
        continue;
      }
      await _dataSource.upsert(vocab.copyWith(tags: tags, updatedAt: now));
    }
  }

  @override
  Future<void> deleteTagAcrossVocabs(String tag) async {
    final normalized = tag.trim().toLowerCase();
    if (normalized.isEmpty) {
      return;
    }
    final now = DateTime.now();
    final all = await _dataSource.fetchAll();
    for (final vocab in all) {
      final next = vocab.tags
          .where((t) => t.trim().toLowerCase() != normalized)
          .toList(growable: false);
      if (next.length == vocab.tags.length) {
        continue;
      }
      await _dataSource.upsert(vocab.copyWith(tags: next, updatedAt: now));
    }
  }
}

final vocabDataSourceProvider = Provider<VocabDataSource>((ref) {
  final profileId =
      ref.watch(localProfilesProvider.select((s) => s.activeProfileId));
  return VocabDataSource(profileId: profileId);
});

final vocabRepositoryProvider = Provider<VocabRepository>((ref) {
  final localStore = ref.watch(vocabDataSourceProvider);
  return VocabRepositoryImpl(localStore);
});
