import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../local/local_db.dart';
import '../../features/settings/application/settings_service.dart';
import '../../features/vocab/data/vocab_datasource.dart';
import '../../features/vocab/data/vocab_repository_impl.dart';
import '../sync/drive_sync_snapshot.dart';

class LocalBackupService {
  const LocalBackupService(this._dataSource, this._settings);

  final VocabDataSource _dataSource;
  final SettingsService _settings;

  static const String _backupDirName = 'formycareer_backups';
  static const String _backupPrefix = 'vocab_backup_';
  static const String _backupDbSuffix = '.db';
  static const String _backupJsonSuffix = '.json';

  Future<String> backupDirectoryPath() async {
    final dir = await _ensureBackupDirectory();
    return dir.path;
  }

  Future<String> createBackup() async {
    final dir = await _ensureBackupDirectory();
    return createBackupAtDirectory(dir.path);
  }

  Future<String> createBackupAtDirectory(String directoryPath) async {
    final dir = Directory(directoryPath);
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }
    final stamp = DateTime.now().toUtc().toIso8601String().replaceAll(':', '-');
    final file = File(
      '${dir.path}${Platform.pathSeparator}$_backupPrefix$stamp$_backupDbSuffix',
    );
    await LocalDb.exportDatabaseCopy(file.path);
    return file.path;
  }

  Future<String> restoreLatestBackup() async {
    final dir = await _ensureBackupDirectory();
    final dbBackups = dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith(_backupDbSuffix))
        .where((f) => _fileName(f.path).startsWith(_backupPrefix))
        .toList(growable: false);
    if (dbBackups.isNotEmpty) {
      dbBackups.sort(
        (a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()),
      );
      final latest = dbBackups.first;
      await LocalDb.replaceDatabaseFromBackup(latest.path);
      return latest.path;
    }

    final jsonBackups = dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith(_backupJsonSuffix))
        .where((f) => _fileName(f.path).startsWith(_backupPrefix))
        .toList(growable: false);
    if (jsonBackups.isEmpty) {
      throw StateError('No backup file found.');
    }
    jsonBackups.sort(
      (a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()),
    );
    final latestJson = jsonBackups.first;
    final migratedDbPath = await restoreBackupFromPath(latestJson.path);
    return '$migratedDbPath (migrated from JSON)';
  }

  Future<String> restoreBackupFromPath(String backupFilePath) async {
    final file = File(backupFilePath);
    if (!await file.exists()) {
      throw StateError('Backup file not found.');
    }
    if (backupFilePath.endsWith(_backupDbSuffix)) {
      await LocalDb.replaceDatabaseFromBackup(backupFilePath);
      return backupFilePath;
    }
    if (backupFilePath.endsWith(_backupJsonSuffix)) {
      final raw = await file.readAsString();
      final snapshot = DriveSyncSnapshot.fromJsonString(raw);
      await _dataSource.replaceAllFromSnapshot(snapshot.vocabItems);
      final docsDir = await _ensureBackupDirectory();
      return createBackupAtDirectory(docsDir.path);
    }
    throw StateError('Unsupported backup format.');
  }

  Future<Directory> _ensureBackupDirectory() async {
    final custom = await _settings.loadLocalBackupDirectoryPath();
    final String root;
    if (custom != null && custom.isNotEmpty) {
      root = custom;
    } else {
      final docs = await getApplicationDocumentsDirectory();
      root = '${docs.path}${Platform.pathSeparator}$_backupDirName';
    }
    final dir = Directory(root);
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  String _fileName(String path) {
    return path.split(RegExp(r'[\\/]')).last;
  }
}

final localBackupServiceProvider = Provider<LocalBackupService>((ref) {
  final dataSource = ref.watch(vocabDataSourceProvider);
  final settings = ref.watch(settingsServiceProvider);
  return LocalBackupService(dataSource, settings);
});
