import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/vocab/data/hybrid_vocab_repository.dart';
import 'package:mobile/features/vocab/data/supabase_vocab_repository.dart';
import 'package:mobile/features/vocab/data/vocab_datasource.dart';
import 'package:shared_models/shared_models.dart';

class FakeLocalStore extends VocabDataSource {
  FakeLocalStore({
    required this.seed,
    required this.pendingIds,
    this.duplicatePendingSnapshot = false,
  }) : super(client: null, profileId: kDefaultLocalProfileId);

  final Map<String, Vocab> seed;
  final Set<String> pendingIds;
  final bool duplicatePendingSnapshot;
  DateTime? watermark;
  final Set<String> mergedUsers = <String>{};

  @override
  Future<List<Vocab>> fetchAll() async {
    return seed.values.where((v) => v.deletedAt == null).toList();
  }

  @override
  Future<List<Vocab>> fetchTrashed() async {
    return seed.values
        .where((v) => v.deletedAt != null)
        .toList()
      ..sort((a, b) => b.deletedAt!.compareTo(a.deletedAt!));
  }

  @override
  Future<List<Vocab>> fetchByIds(List<String> ids) async {
    return ids.map((id) => seed[id]).whereType<Vocab>().toList();
  }

  @override
  Future<void> upsert(Vocab vocab) async {
    seed[vocab.id] = vocab;
    pendingIds.add(vocab.id);
  }

  @override
  Future<List<Vocab>> pendingSnapshot() async {
    final pending = pendingIds.map((id) => seed[id]!).toList();
    if (!duplicatePendingSnapshot || pending.isEmpty) {
      return pending;
    }
    return <Vocab>[pending.first, pending.first];
  }

  @override
  Future<void> markSyncedByIds(List<String> ids) async {
    pendingIds.removeAll(ids);
  }

  @override
  Future<void> markSyncedVocabs(List<Vocab> vocabs) async {
    for (final vocab in vocabs) {
      seed[vocab.id] = vocab;
      pendingIds.remove(vocab.id);
    }
  }

  @override
  Future<void> mergeFromRemote(List<Vocab> remoteItems) async {
    for (final remote in remoteItems) {
      if (pendingIds.contains(remote.id)) {
        continue;
      }
      final local = seed[remote.id];
      if (local == null || remote.updatedAt.isAfter(local.updatedAt)) {
        seed[remote.id] = remote;
      }
    }
  }

  @override
  Future<DateTime?> readLastSyncedAt(String? userId) async => watermark;

  @override
  Future<void> writeLastSyncedAt(String? userId, DateTime timestamp) async {
    watermark = timestamp;
  }

  @override
  Future<bool> hasCompletedGuestMerge(String userId) async =>
      mergedUsers.contains(userId);

  @override
  Future<void> markGuestMergeCompleted(String userId) async {
    mergedUsers.add(userId);
  }
}

class FakeRemoteStore extends SupabaseVocabRepository {
  FakeRemoteStore({
    required this.remoteItems,
  }) : super(client: null, currentUserId: null);

  final Map<String, Vocab> remoteItems;
  int pushedCount = 0;
  int pushedUniqueCount = 0;
  int fetchChangesSinceCalls = 0;
  DateTime? lastFetchSince;

  @override
  Future<SupabasePushResult> pushPending(List<Vocab> pending) async {
    pushedCount = pending.length;
    final ids = <String>[];
    for (final item in pending) {
      remoteItems[item.id] = item;
      ids.add(item.id);
    }
    pushedUniqueCount = ids.toSet().length;
    return SupabasePushResult(
      syncedIds: ids.toSet().toList(),
      syncedItems: ids.toSet().map((id) => remoteItems[id]!).toList(),
    );
  }

  @override
  Future<SupabaseFetchResult> fetchAll() async {
    return SupabaseFetchResult(
      success: true,
      items: remoteItems.values.toList(),
    );
  }

  @override
  Future<SupabaseFetchResult> fetchChangesSince(DateTime? since) async {
    fetchChangesSinceCalls += 1;
    lastFetchSince = since;
    return fetchAll();
  }

  @override
  Future<Vocab?> upsertVocab(Vocab vocab) async {
    remoteItems[vocab.id] = vocab;
    return vocab;
  }

  @override
  Future<List<Vocab>> updateVocabsWhereIds(
    List<String> ids,
    Map<String, dynamic> patch,
  ) async {
    return ids.map((id) => remoteItems[id]).whereType<Vocab>().toList();
  }
}

void main() {
  group('Hybrid conflict handling', () {
    test('keeps newer local pending record over older remote', () async {
      final now = DateTime(2026, 4, 17, 12, 0);
      final id = '123e4567-e89b-12d3-a456-426614174000';
      final localNewer = Vocab.initial(
        id: id,
        sourceText: 'hello local',
        translatedText: 'xin chao local',
        languagePair: 'en-vi',
      ).copyWith(updatedAt: now.add(const Duration(minutes: 5)));
      final remoteOlder = localNewer.copyWith(
        sourceText: 'hello remote old',
        updatedAt: now,
      );

      final localStore = FakeLocalStore(
        seed: <String, Vocab>{id: localNewer},
        pendingIds: <String>{id},
      );
      final remoteStore = FakeRemoteStore(
        remoteItems: <String, Vocab>{id: remoteOlder},
      );

      final repo = HybridVocabRepository(
        localStore: localStore,
        remoteStore: remoteStore,
        readStrategy: ReadStrategy.remoteFirst,
      );

      await repo.syncPending();
      final all = await repo.getAllVocab();

      expect(all.single.sourceText, 'hello local');
      expect(localStore.pendingIds, isEmpty);
    });

    test('applies newer remote when local is already synced', () async {
      final now = DateTime(2026, 4, 17, 12, 0);
      final id = '223e4567-e89b-12d3-a456-426614174001';
      final localOlder = Vocab.initial(
        id: id,
        sourceText: 'local old',
        translatedText: 'old',
        languagePair: 'en-vi',
      ).copyWith(updatedAt: now);
      final remoteNewer = localOlder.copyWith(
        sourceText: 'remote new',
        updatedAt: now.add(const Duration(minutes: 10)),
      );

      final localStore = FakeLocalStore(
        seed: <String, Vocab>{id: localOlder},
        pendingIds: <String>{},
      );
      final remoteStore = FakeRemoteStore(
        remoteItems: <String, Vocab>{id: remoteNewer},
      );

      final repo = HybridVocabRepository(
        localStore: localStore,
        remoteStore: remoteStore,
        readStrategy: ReadStrategy.remoteFirst,
      );

      final all = await repo.getAllVocab();
      expect(all.single.sourceText, 'remote new');
    });

    test('dedupes same id before push', () async {
      final now = DateTime(2026, 4, 17, 12, 0);
      final id = '323e4567-e89b-12d3-a456-426614174002';
      final item = Vocab.initial(
        id: id,
        sourceText: 'dup',
        translatedText: 'dup',
        languagePair: 'en-vi',
      ).copyWith(updatedAt: now);

      final localStore = FakeLocalStore(
        seed: <String, Vocab>{id: item},
        pendingIds: <String>{id},
        duplicatePendingSnapshot: true,
      );
      final remoteStore = FakeRemoteStore(remoteItems: <String, Vocab>{});

      final repo = HybridVocabRepository(
        localStore: localStore,
        remoteStore: remoteStore,
        readStrategy: ReadStrategy.remoteFirst,
      );

      await repo.syncPending();
      expect(remoteStore.pushedCount, 1);
      expect(remoteStore.pushedUniqueCount, 1);
    });

    test('advances watermark after successful pull', () async {
      final now = DateTime(2026, 4, 17, 12, 0);
      final id = '423e4567-e89b-12d3-a456-426614174003';
      final remoteItem = Vocab.initial(
        id: id,
        sourceText: 'remote',
        translatedText: 'remote',
        languagePair: 'en-vi',
      ).copyWith(updatedAt: now.add(const Duration(minutes: 15)));

      final localStore = FakeLocalStore(
        seed: <String, Vocab>{},
        pendingIds: <String>{},
      )..watermark = now;
      final remoteStore = FakeRemoteStore(
        remoteItems: <String, Vocab>{id: remoteItem},
      );

      final repo = HybridVocabRepository(
        localStore: localStore,
        remoteStore: remoteStore,
        readStrategy: ReadStrategy.remoteFirst,
      );

      await repo.syncPending();
      expect(remoteStore.lastFetchSince, now);
      expect(localStore.watermark, remoteItem.updatedAt);
    });

    test('guest merge on login runs once per user', () async {
      final now = DateTime(2026, 4, 17, 12, 0);
      final id = '523e4567-e89b-12d3-a456-426614174004';
      final guestItem = Vocab.initial(
        id: id,
        sourceText: 'guest',
        translatedText: 'guest',
        languagePair: 'en-vi',
      ).copyWith(updatedAt: now);

      final localStore = FakeLocalStore(
        seed: <String, Vocab>{id: guestItem},
        pendingIds: <String>{id},
      );
      final remoteStore = FakeRemoteStore(remoteItems: <String, Vocab>{});
      final repo = HybridVocabRepository(
        localStore: localStore,
        remoteStore: remoteStore,
        readStrategy: ReadStrategy.remoteFirst,
      );

      await repo.handleAuthTransition(
        previousUserId: null,
        nextUserId: 'user_1',
      );
      expect(remoteStore.remoteItems.containsKey(id), isTrue);
      expect(localStore.mergedUsers.contains('user_1'), isTrue);
      final pushedAfterFirstMerge = remoteStore.pushedCount;

      await repo.handleAuthTransition(
        previousUserId: null,
        nextUserId: 'user_1',
      );
      expect(remoteStore.pushedCount, pushedAfterFirstMerge);
    });
  });
}
