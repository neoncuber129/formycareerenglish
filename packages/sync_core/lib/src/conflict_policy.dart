/// How to resolve divergent changes at the same [syncVersion].
enum ConflictPolicy {
  /// Newer [Vocab.updatedAt] wins; ties broken by [Vocab.id] lexicographic order
  /// (stable, deterministic).
  lastWriteWinsByUpdatedAt,

  /// Do not auto-resolve: surface [MergeConflict] for each clashing id.
  manual,
}
