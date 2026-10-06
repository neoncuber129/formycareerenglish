import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_models/shared_models.dart';
import 'package:sqflite/sqflite.dart';

import '../../features/vocab/data/vocab_datasource.dart';
import '../../features/vocab/data/vocab_repository_impl.dart';
import '../sync/drive_sync_preferences.dart';
import '../sync/drive_sync_snapshot.dart';

class BackupImportResult {
  const BackupImportResult({
    required this.itemCount,
    required this.sourceKind,
  });

  final int itemCount;
  final String sourceKind;
}

/// Imports / exports vocabulary backups (SQLite `.db`, signed `.json`).
class MobileBackupImportService {
  const MobileBackupImportService(this._dataSource, this._drivePrefs);

  final VocabDataSource _dataSource;
  final DriveSyncPreferences _drivePrefs;

  /// Writes a signed JSON snapshot for backup / restore.
  Future<String?> exportSignedJsonWithPicker() async {
    final items = await _dataSource.exportAllForSnapshot();
    final deviceId = await _drivePrefs.getOrCreateDeviceId();
    final updatedAt = await _dataSource.latestUpdatedAt();
    final snapshot = DriveSyncSnapshot(
      schemaVersion: DriveSyncSnapshot.currentSchemaVersion,
      deviceId: deviceId,
      updatedAt: updatedAt,
      checksum: DriveSyncSnapshot.computeChecksum(
        vocabItems: items,
        schemaVersion: DriveSyncSnapshot.currentSchemaVersion,
        deviceId: deviceId,
        updatedAt: updatedAt,
      ),
      vocabItems: items,
    );
    final stamp = DateTime.now().toUtc().toIso8601String().replaceAll(':', '-');
    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'Save vocabulary backup',
      fileName: 'vocab_backup_$stamp.json',
      type: FileType.custom,
      allowedExtensions: const <String>['json'],
    );
    if (path == null) {
      return null;
    }
    await File(path).writeAsString(snapshot.toJsonString());
    return path;
  }

  Future<BackupImportResult> importFromPickerFile(PlatformFile picked) async {
    final resolved = await _materializePickedFile(picked);
    try {
      return await importFromResolvedPath(resolved.path);
    } finally {
      if (resolved.deleteAfter) {
        try {
          await File(resolved.path).delete();
        } catch (_) {}
      }
    }
  }

  Future<BackupImportResult> importFromResolvedPath(String filePath) async {
    final lower = filePath.toLowerCase();
    if (lower.endsWith('.json')) {
      final raw = await File(filePath).readAsString();
      final snapshot = DriveSyncSnapshot.fromJsonString(raw);
      await _dataSource.replaceAllFromSnapshot(snapshot.vocabItems);
      return BackupImportResult(
        itemCount: snapshot.vocabItems.length,
        sourceKind: 'JSON snapshot',
      );
    }
    if (lower.endsWith('.db')) {
      final items = await readVocabsFromDesktopSqliteFile(filePath);
      await _dataSource.replaceAllFromSnapshot(items);
      return BackupImportResult(
        itemCount: items.length,
        sourceKind: 'Desktop SQLite',
      );
    }
    throw StateError('Unsupported backup format.');
  }

  static Future<List<Vocab>> readVocabsFromDesktopSqliteFile(String path) async {
    Database? db;
    try {
      db = await openDatabase(
        path,
        readOnly: true,
        singleInstance: false,
      );
    } catch (error, stack) {
      debugPrint('openDatabase backup failed: $error\n$stack');
      throw StateError('Cannot open SQLite backup file.');
    }
    try {
      final rows = await db.query('vocab_records');
      return rows.map(_rowMapToVocab).toList(growable: false);
    } on DatabaseException catch (error, stack) {
      debugPrint('query vocab_records failed: $error\n$stack');
      throw StateError(
        'This file does not look like a FormyCareer vocabulary backup (missing vocab data).',
      );
    } finally {
      await db.close();
    }
  }

  static Vocab _rowMapToVocab(Map<String, Object?> row) {
    final decoded = jsonDecode((row['payload_json'] as String? ?? '{}'));
    if (decoded is Map<String, dynamic>) {
      return Vocab.fromJson(decoded);
    }
    return Vocab.fromJson(const <String, dynamic>{});
  }
}

class _ResolvedPick {
  const _ResolvedPick({required this.path, required this.deleteAfter});

  final String path;
  final bool deleteAfter;
}

Future<_ResolvedPick> _materializePickedFile(PlatformFile picked) async {
  final p = picked.path?.trim() ?? '';
  if (p.isNotEmpty) {
    return _ResolvedPick(path: p, deleteAfter: false);
  }
  final bytes = picked.bytes;
  if (bytes == null) {
    throw StateError('Could not read the selected file.');
  }
  final dir = await getTemporaryDirectory();
  final name = picked.name.trim().toLowerCase();
  final ext = name.endsWith('.json') ? '.json' : '.db';
  final file = File(
    '${dir.path}/fmc_import_${DateTime.now().microsecondsSinceEpoch}$ext',
  );
  await file.writeAsBytes(bytes, flush: true);
  return _ResolvedPick(path: file.path, deleteAfter: true);
}

String friendlyBackupImportError(Object error) {
  final raw = error.toString().toLowerCase();
  if (raw.contains('unsupported backup format')) {
    return 'Unsupported format. Choose a .db or .json file from desktop backup.';
  }
  if (raw.contains('checksum mismatch') || raw.contains('invalid drive snapshot')) {
    return 'Invalid or corrupted JSON backup.';
  }
  if (raw.contains('cannot open sqlite')) {
    return 'Could not open the database file.';
  }
  if (raw.contains('missing vocab data')) {
    return 'Not a valid FormyCareer vocabulary backup.';
  }
  if (raw.contains('could not read the selected file')) {
    return 'Could not read the selected file.';
  }
  return 'Import failed: $error';
}

final mobileBackupImportServiceProvider = Provider<MobileBackupImportService>((ref) {
  return MobileBackupImportService(
    ref.watch(vocabDataSourceProvider),
    ref.watch(driveSyncPreferencesProvider),
  );
});
