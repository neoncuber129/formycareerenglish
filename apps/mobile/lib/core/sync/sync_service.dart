import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/vocab/data/vocab_repository_impl.dart';
import '../../features/vocab/data/vocab_datasource.dart';
import '../../features/vocab/domain/vocab_repository.dart';
import '../auth/auth_service.dart';
import 'google_drive_service.dart';
import 'sync_manager.dart';

class SyncService {
  SyncService(
    this._repository, [
    this._localStore,
    this._driveService,
    this._authService,
  ]);

  final VocabRepository _repository;
  final VocabDataSource? _localStore;
  final GoogleDriveService? _driveService;
  final AuthService? _authService;
  SyncManager? _manager;
  bool _started = false;
  int _consecutiveFailures = 0;
  DateTime? _nextAllowedAttemptAt; // compatibility
  String? _lastErrorMessage;
  SyncErrorCode? _lastErrorCode;

  void startBackgroundRetry() {
    if (_started) {
      return;
    }
    _started = true;
    if (_localStore != null && _driveService != null && _authService != null) {
      final localStore = _localStore;
      final driveService = _driveService;
      final authService = _authService;
      _manager = SyncManager(localStore, driveService, authService)..start();
    }
  }

  Future<void> syncNow() async {
    try {
      await _runSyncCore();
      _consecutiveFailures = 0;
      _nextAllowedAttemptAt = null;
      _lastErrorMessage = null;
      _lastErrorCode = null;
    } catch (error) {
      if (_shouldRetryAfterSilentReauth(error)) {
        final recovered = await _trySilentReauthAndRetry();
        if (recovered) {
          _consecutiveFailures = 0;
          _nextAllowedAttemptAt = null;
          _lastErrorMessage = null;
          _lastErrorCode = null;
          return;
        }
      }
      _consecutiveFailures += 1;
      _nextAllowedAttemptAt = DateTime.now().add(const Duration(seconds: 5));
      _lastErrorMessage = _friendlySyncError(error);
      _lastErrorCode = _errorCode(error);
      rethrow;
    }
  }

  DateTime? get nextAllowedAttemptAt => _nextAllowedAttemptAt;
  int get consecutiveFailures => _consecutiveFailures;
  String? get lastErrorMessage => _lastErrorMessage;
  bool get needsReauth =>
      _lastErrorCode == SyncErrorCode.tokenRevoked ||
      _lastErrorCode == SyncErrorCode.insufficientScope;

  /// Uploads pending local changes (SRS updates, captures, …) to Supabase.
  ///
  /// Same behaviour as [syncNow] (connectivity guard, single-flight lock).
  /// Call with `unawaited(...)` after a review session so the summary UI
  /// stays responsive while sync runs.
  Future<void> pushPending() async {
    await _manager?.syncNow();
  }

  void dispose() {
    _manager?.dispose();
    _started = false;
  }

  void triggerSync() {
    _manager?.triggerSync();
  }

  String _friendlySyncError(Object error) {
    if (error is SyncException) {
      return error.message;
    }
    return 'Sync failed. Check network and Google auth.';
  }

  SyncErrorCode _errorCode(Object error) {
    if (error is SyncException) {
      return error.code;
    }
    return SyncErrorCode.unknown;
  }

  Future<void> _runSyncCore() async {
    await _repository.syncPending();
    await _repository.getAllVocab();
    await _manager?.syncNow();
  }

  bool _shouldRetryAfterSilentReauth(Object error) {
    return _errorCode(error) == SyncErrorCode.tokenRevoked && _authService != null;
  }

  Future<bool> _trySilentReauthAndRetry() async {
    try {
      final recoveredSession = await _authService!.trySilentReauthenticate();
      if (recoveredSession == null) {
        return false;
      }
      await _runSyncCore();
      return true;
    } catch (_) {
      return false;
    }
  }
}

final syncServiceProvider = Provider<SyncService>((ref) {
  final repository = ref.watch(vocabRepositoryProvider);
  final localStore = ref.watch(vocabDataSourceProvider);
  if (!AuthService.oauthEnabled) {
    final service = SyncService(repository, localStore, null, null);
    ref.onDispose(service.dispose);
    return service;
  }
  final driveService = ref.watch(googleDriveServiceProvider);
  final authService = ref.watch(authServiceProvider);
  final service = SyncService(repository, localStore, driveService, authService);
  ref.onDispose(service.dispose);
  return service;
});
