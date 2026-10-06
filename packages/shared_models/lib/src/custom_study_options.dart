/// Options for a targeted review session (library custom study / cram).
class CustomStudyOptions {
  const CustomStudyOptions({
    this.maxCards,
    this.order = CustomStudyOrder.dueOrder,
    this.respectScheduling = true,
    this.maxNewCardsPerSession = 20,
    this.reviewsBeforeInsertNew = 10,
  });

  /// When non-null, caps the session queue length after filtering/interleaving.
  final int? maxCards;

  final CustomStudyOrder order;

  /// When false, grades do not persist to storage (cram / preview scheduling).
  final bool respectScheduling;

  /// Caps how many new/learning cards enter an interleaved session.
  final int maxNewCardsPerSession;

  /// After this many mature reviews, insert one new/learning card when both sides exist.
  final int reviewsBeforeInsertNew;

  static const CustomStudyOptions defaults = CustomStudyOptions();
}

enum CustomStudyOrder {
  dueOrder,
  random,
}
