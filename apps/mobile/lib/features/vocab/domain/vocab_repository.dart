import 'package:shared_models/shared_models.dart';

abstract class VocabRepository {
  Future<List<Vocab>> getAllVocab();

  Future<void> saveVocab(Vocab vocab);

  Future<List<Vocab>> getDueCards(DateTime now);

  Future<void> updateReviewProgress(Vocab vocab);

  Future<void> syncPending();

  /// Bulk patch (allowed keys: `isArchived` / `is_archived`, `deletedAt` / `deleted_at`).
  Future<void> updateVocabsBulk(List<String> ids, Map<String, dynamic> updates);

  /// Soft delete: sets [Vocab.deletedAt] on all matching rows.
  Future<void> deleteVocabsBulk(List<String> ids);

  Future<List<Vocab>> getTrashedVocab();

  /// Bulk reset SRS fields to defaults for the given ids.
  Future<void> resetSrsBulk(List<String> ids);

  /// Rename a tag on all vocabulary rows (case-insensitive exact match).
  Future<void> renameTagAcrossVocabs(String oldTag, String newTag);

  /// Remove a tag from all vocabulary rows (case-insensitive exact match).
  Future<void> deleteTagAcrossVocabs(String tag);
}
