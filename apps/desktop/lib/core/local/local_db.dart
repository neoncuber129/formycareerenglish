import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:isar/isar.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_models/shared_models.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'isar_models.dart';

class LocalDb {
  static const String vocabBoxName = 'vocab_box';
  static const String settingsBoxName = 'settings_box';
  static const String _migrationDoneKey = 'isar_migration_done_v1';
  static const String _sqliteMigrationDoneKey = 'sqlite_migration_done_v1';
  static const String _dbName = 'formycareer_offline_v2.db';

  static bool _initialized = false;
  static Database? _db;
  static String? _dbPath;
  static Isar? _isar;
  static Box<Map<dynamic, dynamic>>? _legacyVocabBox;
  static Box<dynamic>? _legacySettingsBox;

  static Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    try {
      final directory = await getApplicationDocumentsDirectory();
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      _dbPath = p.join(directory.path, _dbName);
      _db = await databaseFactory.openDatabase(
        _dbPath!,
        options: OpenDatabaseOptions(
          version: 2,
          onCreate: (db, version) async {
            await _createSchema(db);
          },
          onUpgrade: (db, oldVersion, newVersion) async {
            if (oldVersion < 2) {
              await db.execute(
                "ALTER TABLE vocab_records ADD COLUMN profile_id TEXT NOT NULL DEFAULT '$kDefaultLocalProfileId'",
              );
              await db.execute(
                'CREATE INDEX IF NOT EXISTS idx_vocab_profile_id ON vocab_records(profile_id)',
              );
            }
          },
          onOpen: (db) async {
            await _createSchema(db);
          },
        ),
      );
      Hive.init(directory.path);
      _legacyVocabBox = await Hive.openBox<Map<dynamic, dynamic>>(vocabBoxName);
      _legacySettingsBox = await Hive.openBox<dynamic>(settingsBoxName);
      _isar = await Isar.open(
        <CollectionSchema>[VocabRecordEntitySchema, AppSettingEntitySchema],
        directory: directory.path,
        name: 'formycareer_isar',
      );
      await _migrateHiveToIsarIfNeeded();
      await _migrateLegacyStoresToSqliteIfNeeded();
      _initialized = true;
    } catch (error) {
      _initialized = false;
      debugPrint('LocalDb init failed (desktop): $error');
    }
  }

  static Database? tryGetDatabase() {
    if (!_initialized) {
      return null;
    }
    return _db;
  }

  static String? tryGetDatabasePath() {
    if (!_initialized) {
      return null;
    }
    return _dbPath;
  }

  static Future<void> exportDatabaseCopy(String destinationPath) async {
    final source = _dbPath;
    if (source == null || source.trim().isEmpty) {
      throw StateError('Local database is not initialized.');
    }
    final sourceFile = File(source);
    if (!await sourceFile.exists()) {
      throw StateError('Local database file not found.');
    }
    final destFile = File(destinationPath);
    await destFile.parent.create(recursive: true);
    await sourceFile.copy(destFile.path);
  }

  static Future<void> replaceDatabaseFromBackup(String sourcePath) async {
    final currentPath = _dbPath;
    if (currentPath == null || currentPath.trim().isEmpty) {
      throw StateError('Local database is not initialized.');
    }
    final sourceFile = File(sourcePath);
    if (!await sourceFile.exists()) {
      throw StateError('Backup database file not found.');
    }
    await _db?.close();
    _db = null;
    final targetFile = File(currentPath);
    await targetFile.parent.create(recursive: true);
    if (await targetFile.exists()) {
      await targetFile.delete();
    }
    await sourceFile.copy(targetFile.path);
    _db = await databaseFactory.openDatabase(
      currentPath,
      options: OpenDatabaseOptions(
        version: 2,
        onCreate: (db, version) async {
          await _createSchema(db);
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < 2) {
            await db.execute(
              "ALTER TABLE vocab_records ADD COLUMN profile_id TEXT NOT NULL DEFAULT '$kDefaultLocalProfileId'",
            );
            await db.execute(
              'CREATE INDEX IF NOT EXISTS idx_vocab_profile_id ON vocab_records(profile_id)',
            );
          }
        },
        onOpen: (db) async {
          await _createSchema(db);
        },
      ),
    );
  }

  static Isar? tryGetIsar() {
    if (!_initialized) {
      return null;
    }
    return _isar;
  }

  static Box<Map<dynamic, dynamic>>? tryGetVocabBox() {
    return _legacyVocabBox;
  }

  static Box<dynamic>? tryGetSettingsBox() {
    return _legacySettingsBox;
  }

  static Future<void> _createSchema(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS vocab_records (
        vocab_id TEXT PRIMARY KEY,
        payload_json TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        deleted_at TEXT,
        next_review_at TEXT NOT NULL,
        is_archived INTEGER NOT NULL DEFAULT 0,
        sync_status TEXT NOT NULL,
        last_error TEXT,
        retry_count INTEGER NOT NULL DEFAULT 0,
        profile_id TEXT NOT NULL DEFAULT '$kDefaultLocalProfileId'
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_vocab_updated_at ON vocab_records(updated_at)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_vocab_next_review_at ON vocab_records(next_review_at)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_vocab_is_archived ON vocab_records(is_archived)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_vocab_sync_status ON vocab_records(sync_status)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_vocab_profile_id ON vocab_records(profile_id)',
    );
    await db.execute('''
      CREATE TABLE IF NOT EXISTS app_settings (
        key TEXT PRIMARY KEY,
        string_value TEXT,
        bool_value INTEGER
      )
    ''');
  }

  static Future<void> _migrateLegacyStoresToSqliteIfNeeded() async {
    final db = _db;
    if (db == null) {
      return;
    }
    final marker = await db.query(
      'app_settings',
      columns: <String>['bool_value'],
      where: 'key = ?',
      whereArgs: <Object?>[_sqliteMigrationDoneKey],
      limit: 1,
    );
    if (marker.isNotEmpty && (marker.first['bool_value'] as int? ?? 0) == 1) {
      return;
    }

    final imported = <Map<String, Object?>>[];
    final importedSettings = <Map<String, Object?>>[];

    final isar = _isar;
    if (isar != null) {
      final isarRows = await isar.vocabRecordEntitys.where().findAll();
      for (final row in isarRows) {
        final createdAt = _parseDateFromPayload(row.payloadJson, 'created_at') ??
            row.updatedAt.toUtc();
        imported.add(<String, Object?>{
          'vocab_id': row.vocabId,
          'payload_json': row.payloadJson,
          'created_at': createdAt.toUtc().toIso8601String(),
          'updated_at': row.updatedAt.toUtc().toIso8601String(),
          'deleted_at': row.deletedAt?.toUtc().toIso8601String(),
          'next_review_at': row.nextReviewAt.toUtc().toIso8601String(),
          'is_archived': row.isArchived ? 1 : 0,
          'sync_status': row.syncStatus,
          'last_error': row.lastError,
          'retry_count': row.retryCount,
          'profile_id': kDefaultLocalProfileId,
        });
      }
      final isarSettings = await isar.appSettingEntitys.where().findAll();
      for (final setting in isarSettings) {
        importedSettings.add(<String, Object?>{
          'key': setting.key,
          'string_value': setting.stringValue,
          'bool_value': setting.boolValue == null ? null : (setting.boolValue! ? 1 : 0),
        });
      }
    }

    if (imported.isEmpty) {
      final vocabBox = _legacyVocabBox;
      if (vocabBox != null) {
        for (final entry in vocabBox.toMap().entries) {
          final raw = entry.value;
          final vocabJson = _extractVocabJson(raw);
          if (vocabJson == null) {
            continue;
          }
          final vocabId = (vocabJson['id'] as String? ?? entry.key.toString()).trim();
          if (vocabId.isEmpty) {
            continue;
          }
          final payload = _encode(vocabJson);
          final updatedAt = _parseDate(vocabJson['updated_at']) ??
              DateTime.fromMillisecondsSinceEpoch(0);
          final createdAt = _parseDate(vocabJson['created_at']) ?? updatedAt;
          imported.add(<String, Object?>{
            'vocab_id': vocabId,
            'payload_json': payload,
            'created_at': createdAt.toUtc().toIso8601String(),
            'updated_at': updatedAt.toUtc().toIso8601String(),
            'deleted_at': _parseDate(vocabJson['deleted_at'])?.toUtc().toIso8601String(),
            'next_review_at': (_parseDate(vocabJson['next_review_at']) ?? DateTime.now().toUtc())
                .toIso8601String(),
            'is_archived': vocabJson['is_archived'] == true ? 1 : 0,
            'sync_status': (raw['sync_status'] as String? ?? 'pending'),
            'last_error': (raw['sync_last_error'] as String?)?.trim(),
            'retry_count': _toInt(raw['sync_retry_count']),
            'profile_id': kDefaultLocalProfileId,
          });
        }
      }
      final settingsBox = _legacySettingsBox;
      if (settingsBox != null) {
        for (final entry in settingsBox.toMap().entries) {
          final value = entry.value;
          importedSettings.add(<String, Object?>{
            'key': entry.key.toString(),
            'string_value': value is bool || value == null ? null : value.toString(),
            'bool_value': value is bool ? (value ? 1 : 0) : null,
          });
        }
      }
    }

    await db.transaction((txn) async {
      for (final row in imported) {
        await txn.insert(
          'vocab_records',
          row,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      for (final row in importedSettings) {
        await txn.insert(
          'app_settings',
          row,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await txn.insert(
        'app_settings',
        <String, Object?>{
          'key': _sqliteMigrationDoneKey,
          'string_value': null,
          'bool_value': 1,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }

  static DateTime? _parseDateFromPayload(String payloadJson, String key) {
    try {
      final decoded = jsonDecode(payloadJson);
      if (decoded is Map<String, dynamic>) {
        return _parseDate(decoded[key]);
      }
    } catch (_) {}
    return null;
  }

  static Future<void> _migrateHiveToIsarIfNeeded() async {
    final isar = _isar;
    final vocabBox = _legacyVocabBox;
    final settingsBox = _legacySettingsBox;
    if (isar == null || vocabBox == null || settingsBox == null) {
      return;
    }
    final marker = await isar.appSettingEntitys
        .filter()
        .keyEqualTo(_migrationDoneKey)
        .findFirst();
    if (marker?.boolValue == true) {
      return;
    }

    final vocabEntities = <VocabRecordEntity>[];
    for (final entry in vocabBox.toMap().entries) {
      final raw = entry.value;
      final vocabJson = _extractVocabJson(raw);
      if (vocabJson == null) {
        continue;
      }
      final entity = VocabRecordEntity()
        ..vocabId = (vocabJson['id'] as String? ?? entry.key.toString()).trim()
        ..payloadJson = _encode(vocabJson)
        ..updatedAt = _parseDate(vocabJson['updated_at']) ??
            DateTime.fromMillisecondsSinceEpoch(0)
        ..deletedAt = _parseDate(vocabJson['deleted_at'])
        ..nextReviewAt = _parseDate(vocabJson['next_review_at']) ?? DateTime.now().toUtc()
        ..isArchived = vocabJson['is_archived'] == true
        ..syncStatus = (raw['sync_status'] as String? ?? 'pending')
        ..lastError = (raw['sync_last_error'] as String?)?.trim()
        ..retryCount = _toInt(raw['sync_retry_count']);
      vocabEntities.add(entity);
    }

    final settingEntities = <AppSettingEntity>[];
    for (final entry in settingsBox.toMap().entries) {
      final key = entry.key.toString();
      final value = entry.value;
      final entity = AppSettingEntity()..key = key;
      if (value is bool) {
        entity.boolValue = value;
      } else if (value != null) {
        entity.stringValue = value.toString();
      }
      settingEntities.add(entity);
    }
    settingEntities.add(
      AppSettingEntity()
        ..key = _migrationDoneKey
        ..boolValue = true,
    );
    await isar.writeTxn(() async {
      await isar.vocabRecordEntitys.putAll(vocabEntities);
      await isar.appSettingEntitys.putAll(settingEntities);
    });
  }

  static Map<String, dynamic>? _extractVocabJson(Map<dynamic, dynamic> raw) {
    final nested = raw['vocab'];
    if (nested is Map) {
      return Map<String, dynamic>.from(nested);
    }
    if (raw.containsKey('source_text')) {
      return Map<String, dynamic>.from(raw);
    }
    return null;
  }

  static DateTime? _parseDate(Object? raw) {
    final text = raw?.toString().trim() ?? '';
    if (text.isEmpty) {
      return null;
    }
    return DateTime.tryParse(text)?.toUtc();
  }

  static int _toInt(Object? raw) {
    if (raw is int) {
      return raw;
    }
    if (raw is num) {
      return raw.toInt();
    }
    return 0;
  }

  static String _encode(Map<String, dynamic> json) {
    try {
      return _jsonEncode(json);
    } catch (_) {
      return '{}';
    }
  }

  static String _jsonEncode(Map<String, dynamic> json) {
    return const JsonEncoder().convert(json);
  }
}
