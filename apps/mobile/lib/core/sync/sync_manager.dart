import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import '../../features/vocab/data/vocab_datasource.dart';
import 'drive_sync_snapshot.dart';
import 'google_drive_service.dart';
import '../auth/auth_service.dart';

class SyncManager {
  SyncManager(
    this._localStore,
    this._driveService,
    this._authService,
  );

  final VocabDataSource _localStore;
  final GoogleDriveService _driveService;
  final AuthService _authService;
  final Connectivity _connectivity = Connectivity();

  Timer? _debounce;
  bool _pendingSync = false;
  bool _isSyncing = false;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  void start() {
    _connectivitySub ??= _connectivity.onConnectivityChanged.listen((results) {
      if (_hasNetwork(results) && _pendingSync) {
        unawaited(syncNow());
      }
    });
  }

  Future<void> startupSync() async {
    await syncNow();
  }

  void triggerSync() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(seconds: 5), () {
      unawaited(syncNow());
    });
  }

  Future<void> syncNow() async {
    if (_isSyncing) {
      return;
    }
    final state = await _connectivity.checkConnectivity();
    if (!_hasNetwork(state)) {
      _pendingSync = true;
      return;
    }
    _isSyncing = true;
    try {
      await _syncPullThenPush();
      _pendingSync = false;
    } catch (error) {
      debugPrint('SyncManager syncNow failed: $error');
      _pendingSync = true;
      rethrow;
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _syncPullThenPush() async {
    final session = await _authService.ensureAuthenticated();
    if (session == null) {
      return;
    }

    final remote = await _driveService.fetchSnapshot();
    if (remote != null) {
      final localTs = await _localStore.latestUpdatedAt();
      final remoteTs = remote.lastModifiedTimestamp;
      if (remoteTs.isAfter(localTs)) {
        await _localStore.replaceAllFromSnapshot(remote.snapshot.vocabItems);
      }
    }

    final all = await _localStore.exportAllForSnapshot();
    final localUpdatedAt = await _localStore.latestUpdatedAt();
    final snapshot = DriveSyncSnapshot(
      schemaVersion: DriveSyncSnapshot.currentSchemaVersion,
      deviceId: session.deviceId,
      updatedAt: localUpdatedAt,
      checksum: DriveSyncSnapshot.computeChecksum(
        vocabItems: all,
        schemaVersion: DriveSyncSnapshot.currentSchemaVersion,
        deviceId: session.deviceId,
        updatedAt: localUpdatedAt,
      ),
      vocabItems: all,
    );
    await _driveService.uploadSnapshot(snapshot);
  }

  bool get hasPendingSync => _pendingSync;

  void dispose() {
    _debounce?.cancel();
    _connectivitySub?.cancel();
    unawaited(syncNow());
  }

  bool _hasNetwork(List<ConnectivityResult> results) {
    return results.any((r) => r != ConnectivityResult.none);
  }
}
