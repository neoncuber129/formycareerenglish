import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_models/shared_models.dart';

import '../data/vocab_repository_impl.dart';

/// Active vocabulary rows for the desktop library table.
final vocabListProvider = FutureProvider.autoDispose<List<Vocab>>((ref) async {
  return ref.watch(vocabRepositoryProvider).getAllVocab();
});
