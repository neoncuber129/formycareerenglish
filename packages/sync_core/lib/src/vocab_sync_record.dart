import 'package:shared_models/shared_models.dart';

/// One row for merge: [Vocab] plus sync metadata from local DB or wire format.
class VocabSyncRecord {
  const VocabSyncRecord({
    required this.vocab,
    required this.syncVersion,
    required this.lastModifiedBy,
    this.wireContentHash,
  });

  final Vocab vocab;
  final int syncVersion;
  final String lastModifiedBy;
  final String? wireContentHash;

  bool get isDeleted => vocab.deletedAt != null;
}
