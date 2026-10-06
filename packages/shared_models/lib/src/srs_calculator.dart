import 'vocab.dart';

enum ReviewGrade { again, hard, good, easy }

class SrsCalculator {
  const SrsCalculator();
  static const String leechTag = 'leech';
  static const Duration relearningFirstStep = Duration(minutes: 1);
  static const Duration relearningSecondStep = Duration(minutes: 10);

  /// Intraday delays before the first day-based interval (Anki-style new steps).
  static const List<Duration> newCardLearningDelays = <Duration>[
    relearningFirstStep,
    relearningSecondStep,
  ];

  static const int _leechReviewThreshold = 8;
  static const double _leechEaseThreshold = 1.6;

  /// `true` when [vocab] uses the new-card minute learning pipeline.
  static bool isInNewLearningPipeline(Vocab vocab) =>
      vocab.newLearningStepIndex >= 0;

  /// Applies a grade while the card is in the new-learning pipeline ([isInNewLearningPipeline]).
  Vocab applyNewCardLearning(Vocab current, ReviewGrade grade, DateTime now) {
    switch (grade) {
      case ReviewGrade.again:
      case ReviewGrade.hard:
        return _newLearningLapse(current, now);
      case ReviewGrade.easy:
        return _newLearningEasy(current, now);
      case ReviewGrade.good:
        final step = current.newLearningStepIndex;
        if (step >= newCardLearningDelays.length) {
          return graduateNewFromLearning(current, ReviewGrade.good, now);
        }
        return current.copyWith(
          nextReviewAt: now.add(newCardLearningDelays[step]),
          newLearningStepIndex: step + 1,
          reviewCount: current.reviewCount + 1,
          updatedAt: now,
        );
    }
  }

  Vocab _newLearningLapse(Vocab current, DateTime now) {
    return current.copyWith(
      nextReviewAt: now.add(relearningFirstStep),
      newLearningStepIndex: 0,
      reviewCount: current.reviewCount + 1,
      updatedAt: now,
    );
  }

  Vocab _newLearningEasy(Vocab current, DateTime now) {
    final step = current.newLearningStepIndex;
    if (step >= newCardLearningDelays.length) {
      return graduateNewFromLearning(current, ReviewGrade.easy, now);
    }
    return graduateNewFromLearning(current, ReviewGrade.easy, now);
  }

  /// First day-based interval after completing intraday new learning.
  Vocab graduateNewFromLearning(
    Vocab current,
    ReviewGrade grade,
    DateTime now,
  ) {
    final nextInterval = switch (grade) {
      ReviewGrade.hard => 1,
      ReviewGrade.good => 1,
      ReviewGrade.easy => 2,
      ReviewGrade.again => 1,
    };
    final nextEase = switch (grade) {
      ReviewGrade.hard => (current.easeFactor - 0.08).clamp(1.3, 2.5),
      ReviewGrade.good => current.easeFactor.clamp(1.3, 2.8),
      ReviewGrade.easy => (current.easeFactor + 0.1).clamp(1.3, 2.9),
      ReviewGrade.again => (current.easeFactor - 0.2).clamp(1.3, 2.5),
    };
    final nextTags = _resolveLeechTags(
      current: current,
      grade: grade,
      nextEase: nextEase,
      nextInterval: nextInterval,
    );
    return current.copyWith(
      intervalDays: nextInterval,
      nextReviewAt: now.add(Duration(days: nextInterval)),
      reviewCount: current.reviewCount + 1,
      easeFactor: nextEase,
      tags: nextTags,
      newLearningStepIndex: -1,
      updatedAt: now,
    );
  }

  Vocab applyReview(Vocab current, ReviewGrade grade, DateTime now) {
    final int nextInterval;
    final double nextEase;

    switch (grade) {
      case ReviewGrade.again:
        nextInterval = 1;
        nextEase = (current.easeFactor - 0.2).clamp(1.3, 2.5);
      case ReviewGrade.hard:
        final goodInterval =
            (current.intervalDays * current.easeFactor).round().clamp(1, 365);
        var hardInterval = (goodInterval * 0.62).round().clamp(1, 365);
        if (hardInterval >= goodInterval && goodInterval > 1) {
          hardInterval = goodInterval - 1;
        }
        nextInterval = hardInterval;
        nextEase = (current.easeFactor - 0.08).clamp(1.3, 2.5);
      case ReviewGrade.good:
        nextInterval = (current.intervalDays * current.easeFactor).round().clamp(1, 365);
        nextEase = (current.easeFactor + 0.05).clamp(1.3, 2.8);
      case ReviewGrade.easy:
        nextInterval =
            (current.intervalDays * (current.easeFactor + 0.3)).round().clamp(1, 365);
        nextEase = (current.easeFactor + 0.1).clamp(1.3, 2.9);
    }

    final nextTags = _resolveLeechTags(
      current: current,
      grade: grade,
      nextEase: nextEase,
      nextInterval: nextInterval,
    );

    return current.copyWith(
      intervalDays: nextInterval,
      nextReviewAt: now.add(Duration(days: nextInterval)),
      reviewCount: current.reviewCount + 1,
      easeFactor: nextEase,
      tags: nextTags,
      updatedAt: now,
    );
  }

  Vocab applyLapseAgain(
    Vocab current,
    DateTime now, {
    Duration step = relearningFirstStep,
  }) {
    final nextInterval = 1;
    final nextEase = (current.easeFactor - 0.2).clamp(1.3, 2.5);
    final nextTags = _resolveLeechTags(
      current: current,
      grade: ReviewGrade.again,
      nextEase: nextEase,
      nextInterval: nextInterval,
    );
    return current.copyWith(
      intervalDays: nextInterval,
      nextReviewAt: now.add(step),
      reviewCount: current.reviewCount + 1,
      easeFactor: nextEase,
      tags: nextTags,
      updatedAt: now,
    );
  }

  Vocab scheduleRelearningStep(Vocab current, DateTime now, Duration step) {
    return current.copyWith(
      nextReviewAt: now.add(step),
      reviewCount: current.reviewCount + 1,
      updatedAt: now,
    );
  }

  Vocab graduateFromRelearning(
    Vocab current,
    ReviewGrade grade,
    DateTime now, {
    required int preLapseIntervalDays,
  }) {
    final baseInterval = preLapseIntervalDays <= 0 ? 1 : 1;
    final nextInterval = switch (grade) {
      ReviewGrade.hard => baseInterval,
      ReviewGrade.good => baseInterval,
      ReviewGrade.easy => (baseInterval * 2).clamp(1, 365),
      ReviewGrade.again => 1,
    };
    final nextEase = switch (grade) {
      ReviewGrade.hard => (current.easeFactor - 0.08).clamp(1.3, 2.5),
      ReviewGrade.good => current.easeFactor.clamp(1.3, 2.8),
      ReviewGrade.easy => (current.easeFactor + 0.1).clamp(1.3, 2.9),
      ReviewGrade.again => (current.easeFactor - 0.2).clamp(1.3, 2.5),
    };
    final nextTags = _resolveLeechTags(
      current: current,
      grade: grade,
      nextEase: nextEase,
      nextInterval: nextInterval,
    );
    return current.copyWith(
      intervalDays: nextInterval,
      nextReviewAt: now.add(Duration(days: nextInterval)),
      reviewCount: current.reviewCount + 1,
      easeFactor: nextEase,
      tags: nextTags,
      updatedAt: now,
    );
  }

  List<String> _resolveLeechTags({
    required Vocab current,
    required ReviewGrade grade,
    required double nextEase,
    required int nextInterval,
  }) {
    final tags = current.tags.toSet();
    final isLikelyLeech =
        grade == ReviewGrade.again &&
        current.reviewCount >= _leechReviewThreshold &&
        nextEase <= _leechEaseThreshold &&
        nextInterval <= 1;
    if (isLikelyLeech) {
      tags.add(leechTag);
    }

    final recovered =
        (grade == ReviewGrade.good || grade == ReviewGrade.easy) &&
        current.tags.contains(leechTag) &&
        nextInterval >= 3;
    if (recovered) {
      tags.remove(leechTag);
    }
    return List<String>.unmodifiable(tags);
  }
}
