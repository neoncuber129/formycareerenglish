import 'language_pair_utils.dart';
import 'vocab.dart';

/// Label + count for dashboard histograms (languages, tags, …).
class DashboardHistogramEntry {
  const DashboardHistogramEntry(this.label, this.count);

  final String label;
  final int count;
}

/// Extra aggregates for richer dashboard charts (desktop/mobile).
///
/// Computed from the same list as [VocabDashboardSnapshot].
class VocabDashboardInsights {
  const VocabDashboardInsights({
    required this.topLanguages,
    required this.topTags,
    required this.deckNewCount,
    required this.deckLearningCount,
    required this.deckReviewCount,
    required this.dueNextSevenDaysCount,
    required this.dueLaterCount,
  });

  /// Top source languages among active (non-archived) cards.
  final List<DashboardHistogramEntry> topLanguages;

  /// Most frequent tags among active cards.
  final List<DashboardHistogramEntry> topTags;

  /// Active cards with `reviewCount == 0`.
  final int deckNewCount;

  /// Active cards with some reviews but still early SRS (`1 <= reviewCount <= 6`).
  final int deckLearningCount;

  /// Active cards with deeper SRS history (`reviewCount > 6`).
  final int deckReviewCount;

  /// Active cards due strictly after [now] within the next 7 days.
  final int dueNextSevenDaysCount;

  /// Active cards due after [now] + 7 days.
  final int dueLaterCount;

  factory VocabDashboardInsights.compute(
    Iterable<Vocab> libraryRows,
    DateTime now,
  ) {
    final rows = libraryRows.toList(growable: false);
    final langMap = <String, int>{};
    final tagMap = <String, String>{};
    final tagCounts = <String, int>{};
    var deckNew = 0;
    var deckLearning = 0;
    var deckReview = 0;
    var dueWeek = 0;
    var dueLater = 0;

    final weekEnd = now.add(const Duration(days: 7));

    for (final v in rows) {
      if (v.isArchived) {
        continue;
      }

      final src = sourceLanguageFromPair(v.languagePair, fallback: '')
          .trim()
          .toLowerCase();
      if (src.isNotEmpty) {
        langMap.update(src, (c) => c + 1, ifAbsent: () => 1);
      }

      for (final raw in v.tags) {
        final t = raw.trim();
        if (t.isEmpty) {
          continue;
        }
        final key = t.toLowerCase();
        tagMap.putIfAbsent(key, () => t);
        tagCounts.update(key, (c) => c + 1, ifAbsent: () => 1);
      }

      final rc = v.reviewCount;
      if (rc == 0) {
        deckNew++;
      } else if (rc <= 6) {
        deckLearning++;
      } else {
        deckReview++;
      }

      final nr = v.nextReviewAt;
      if (nr.isAfter(now)) {
        if (!nr.isAfter(weekEnd)) {
          dueWeek++;
        } else {
          dueLater++;
        }
      }
    }

    List<DashboardHistogramEntry> sortedLangs(Map<String, int> m, int maxN) {
      final list =
          m.entries
              .map(
                (e) => DashboardHistogramEntry(e.key.toUpperCase(), e.value),
              )
              .toList(growable: false)
            ..sort((a, b) => b.count.compareTo(a.count));
      if (list.length <= maxN) {
        return list;
      }
      return list.take(maxN).toList(growable: false);
    }

    List<DashboardHistogramEntry> sortedTags(int maxN) {
      final list =
          tagCounts.entries
              .map(
                (e) => DashboardHistogramEntry(
                  tagMap[e.key] ?? e.key,
                  e.value,
                ),
              )
              .toList(growable: false)
            ..sort((a, b) => b.count.compareTo(a.count));
      if (list.length <= maxN) {
        return list;
      }
      return list.take(maxN).toList(growable: false);
    }

    return VocabDashboardInsights(
      topLanguages: sortedLangs(langMap, 6),
      topTags: sortedTags(8),
      deckNewCount: deckNew,
      deckLearningCount: deckLearning,
      deckReviewCount: deckReview,
      dueNextSevenDaysCount: dueWeek,
      dueLaterCount: dueLater,
    );
  }
}
