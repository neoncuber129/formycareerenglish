import 'dart:math';

import 'custom_study_options.dart';
import 'srs_calculator.dart';
import 'vocab.dart';

/// One graded answer recorded during a review session (after persistence).
class ReviewSessionEntry {
  const ReviewSessionEntry({
    required this.vocabAfterReview,
    required this.grade,
    required this.answeredAt,
  });

  final Vocab vocabAfterReview;
  final ReviewGrade grade;
  final DateTime answeredAt;
}

/// Sort key for SRS queue: harder cards (lower ease) first, then most overdue.
int compareVocabReviewPriority(Vocab a, Vocab b) {
  final easeCmp = a.easeFactor.compareTo(b.easeFactor);
  if (easeCmp != 0) {
    return easeCmp;
  }
  return a.nextReviewAt.compareTo(b.nextReviewAt);
}

/// Active vocabs due at [now], ordered for review (see [compareVocabReviewPriority]).
///
/// Matches the due filter used by [HybridVocabRepository.getDueCards]:
/// `!nextReviewAt.isAfter(now)` and not archived.
List<Vocab> selectDueVocabsSorted(Iterable<Vocab> items, DateTime now) {
  final due = items
      .where(
        (v) => !v.isArchived && !v.nextReviewAt.isAfter(now),
      )
      .toList(growable: false);
  due.sort(compareVocabReviewPriority);
  return due;
}

/// New / learning / mature buckets for the current queue (Anki-style labels).
class StudySessionQueueCounts {
  const StudySessionQueueCounts({
    required this.newCount,
    required this.learningCount,
    required this.reviewCount,
  });

  final int newCount;
  final int learningCount;
  final int reviewCount;
}

StudySessionQueueCounts countStudySessionBuckets(Iterable<Vocab> cards) {
  var newCount = 0;
  var learningCount = 0;
  var reviewCount = 0;
  for (final v in cards) {
    if (v.newLearningStepIndex < 0) {
      reviewCount++;
    } else if (v.newLearningStepIndex == 0 && v.reviewCount == 0) {
      newCount++;
    } else {
      learningCount++;
    }
  }
  return StudySessionQueueCounts(
    newCount: newCount,
    learningCount: learningCount,
    reviewCount: reviewCount,
  );
}

({List<Vocab> mature, List<Vocab> newLearning}) splitMatureAndNewLearningDue(
  List<Vocab> dueSorted,
) {
  final mature = <Vocab>[];
  final newLearning = <Vocab>[];
  for (final v in dueSorted) {
    if (SrsCalculator.isInNewLearningPipeline(v)) {
      newLearning.add(v);
    } else {
      mature.add(v);
    }
  }
  return (mature: mature, newLearning: newLearning);
}

List<Vocab> interleaveMatureAndNewLearning(
  List<Vocab> matureDue,
  List<Vocab> newLearningDue, {
  int maxNewLearning = 20,
  int reviewsBeforeNew = 10,
  CustomStudyOrder order = CustomStudyOrder.dueOrder,
}) {
  final rng = Random();
  var mature = List<Vocab>.from(matureDue);
  var fresh = List<Vocab>.from(newLearningDue);
  if (order == CustomStudyOrder.random) {
    mature.shuffle(rng);
    fresh.shuffle(rng);
  }
  if (fresh.length > maxNewLearning) {
    fresh = fresh.sublist(0, maxNewLearning);
  }
  final out = <Vocab>[];
  var ri = 0;
  var ni = 0;
  var sinceNew = reviewsBeforeNew;
  while (ri < mature.length || ni < fresh.length) {
    final needNew = ni < fresh.length &&
        (ri >= mature.length || sinceNew >= reviewsBeforeNew);
    if (needNew) {
      out.add(fresh[ni++]);
      sinceNew = 0;
    } else if (ri < mature.length) {
      out.add(mature[ri++]);
      sinceNew++;
    } else if (ni < fresh.length) {
      out.add(fresh[ni++]);
      sinceNew = 0;
    }
  }
  return out;
}

List<Vocab> buildStudyQueueFromDue({
  required List<Vocab> dueSorted,
  CustomStudyOptions options = CustomStudyOptions.defaults,
}) {
  final split = splitMatureAndNewLearningDue(dueSorted);
  var merged = interleaveMatureAndNewLearning(
    split.mature,
    split.newLearning,
    maxNewLearning: options.maxNewCardsPerSession,
    reviewsBeforeNew: options.reviewsBeforeInsertNew,
    order: options.order,
  );
  final cap = options.maxCards;
  if (cap != null && merged.length > cap) {
    merged = merged.sublist(0, cap);
  }
  return merged;
}
