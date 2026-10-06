import 'package:shared_models/shared_models.dart';

class SupabaseFetchResult {
  const SupabaseFetchResult({required this.success, required this.items});

  final bool success;
  final List<Vocab> items;
}

class SupabasePushResult {
  const SupabasePushResult({
    required this.syncedIds,
    required this.syncedItems,
    this.errorMessage,
  });

  final List<String> syncedIds;
  final List<Vocab> syncedItems;
  final String? errorMessage;
}

@Deprecated('Supabase removed. This is a compatibility stub.')
class SupabaseVocabRepository {
  const SupabaseVocabRepository({
    required this.client,
    required this.currentUserId,
  });

  final Object? client;
  final String? currentUserId;

  Future<Vocab?> upsertVocab(Vocab vocab) async => null;

  Future<SupabasePushResult> pushPending(List<Vocab> pending) async {
    return const SupabasePushResult(
      syncedIds: <String>[],
      syncedItems: <Vocab>[],
    );
  }

  Future<SupabaseFetchResult> fetchAll() async {
    return const SupabaseFetchResult(success: false, items: <Vocab>[]);
  }

  Future<SupabaseFetchResult> fetchChangesSince(DateTime? since) async {
    return const SupabaseFetchResult(success: false, items: <Vocab>[]);
  }

  Future<List<Vocab>> updateVocabsWhereIds(
    List<String> ids,
    Map<String, dynamic> patch,
  ) async {
    return const <Vocab>[];
  }
}
