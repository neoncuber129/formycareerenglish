import 'review_session_queue.dart';
import 'vocab.dart';

/// Aggregated vocab/SRS counts for dashboard/overview UI.
///
/// [libraryRows] should match [VocabRepository.getAllVocab]: non-trashed rows only
/// (may include archived cards).
class VocabDashboardSnapshot {
  const VocabDashboardSnapshot({
    required this.activeLearningCount,
    required this.archivedCount,
    required this.dueNowCount,
    required this.newCardsCount,
  });

  /// Non-archived rows (still in the active SRS deck).
  final int activeLearningCount;

  /// Archived-only rows (hidden from primary review).
  final int archivedCount;

  /// Cards due at [now], same ordering/filter as SRS queue ([selectDueVocabsSorted]).
  final int dueNowCount;

  /// Active rows never reviewed (`reviewCount == 0`).
  final int newCardsCount;

  /// Builds counts from the full library list returned by [getAllVocab].
  factory VocabDashboardSnapshot.compute(
    Iterable<Vocab> libraryRows,
    DateTime now,
  ) {
    final rows = libraryRows.toList(growable: false);
    var archived = 0;
    var active = 0;
    var fresh = 0;
    for (final v in rows) {
      if (v.isArchived) {
        archived++;
      } else {
        active++;
        if (v.reviewCount == 0) {
          fresh++;
        }
      }
    }
    final dueNow = selectDueVocabsSorted(rows, now).length;
    return VocabDashboardSnapshot(
      activeLearningCount: active,
      archivedCount: archived,
      dueNowCount: dueNow,
      newCardsCount: fresh,
    );
  }
}
