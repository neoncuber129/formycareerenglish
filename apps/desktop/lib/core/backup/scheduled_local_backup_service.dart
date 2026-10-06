import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:desktop/features/settings/application/settings_service.dart';

import 'local_backup_service.dart';

/// Runs local DB backups on a timer into the app default folder when enabled in settings.
class ScheduledLocalBackupService {
  ScheduledLocalBackupService(this._backup, this._settings);

  final LocalBackupService _backup;
  final SettingsService _settings;

  static const Duration _period = Duration(minutes: 5);

  Timer? _timer;
  bool _started = false;
  bool _busy = false;

  void start() {
    if (_started) {
      return;
    }
    _started = true;
    unawaited(_runCheck());
    _timer = Timer.periodic(_period, (_) {
      unawaited(_runCheck());
    });
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
    _started = false;
  }

  void requestCheck() {
    unawaited(_runCheck());
  }

  Future<void> runBackupNow() async {
    await _backup.createBackup();
    await _settings.setLastAutoLocalBackupMs(
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  Future<void> _runCheck() async {
    if (_busy) {
      return;
    }
    _busy = true;
    try {
      final enabled = await _settings.loadAutoLocalBackupEnabled();
      if (!enabled) {
        return;
      }
      final hours = await _settings.loadAutoLocalBackupIntervalHours();
      final lastMs = await _settings.loadLastAutoLocalBackupMs();
      final now = DateTime.now();
      if (lastMs != null) {
        final last = DateTime.fromMillisecondsSinceEpoch(lastMs);
        if (now.difference(last) < Duration(hours: hours)) {
          return;
        }
      }
      await _backup.createBackup();
      await _settings.setLastAutoLocalBackupMs(now.millisecondsSinceEpoch);
    } catch (e, st) {
      debugPrint('Scheduled local backup failed: $e\n$st');
    } finally {
      _busy = false;
    }
  }
}

final scheduledLocalBackupServiceProvider =
    Provider<ScheduledLocalBackupService>((ref) {
      final backup = ref.watch(localBackupServiceProvider);
      final settings = ref.read(settingsServiceProvider);
      final service = ScheduledLocalBackupService(backup, settings);
      ref.onDispose(service.dispose);
      return service;
    });
