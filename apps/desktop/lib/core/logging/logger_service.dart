import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

enum LogLevel { info, warning, error }

class LogEntry {
  const LogEntry({
    required this.level,
    required this.category,
    required this.message,
    required this.timestamp,
    this.attributes = const <String, Object?>{},
  });

  final LogLevel level;
  final String category;
  final String message;
  final DateTime timestamp;
  final Map<String, Object?> attributes;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'level': level.name,
      'category': category,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'attributes': attributes,
    };
  }
}

typedef LogSink = void Function(LogEntry entry);

class LoggerService {
  const LoggerService._();

  static final List<LogSink> _customSinks = <LogSink>[];
  static final List<LogEntry> _recentEntries = <LogEntry>[];
  static const int _maxRecentEntries = 200;

  static List<LogEntry> recentEntries() {
    return List<LogEntry>.from(_recentEntries);
  }

  static void clearRecentEntries() {
    _recentEntries.clear();
  }

  static void registerSink(LogSink sink) {
    _customSinks.add(sink);
  }

  static void clearCustomSinks() {
    _customSinks.clear();
  }

  static void logOcrResult(String source, String text) {
    _emit(
      LogEntry(
        level: LogLevel.info,
        category: 'ocr',
        message: 'OCR result captured',
        timestamp: DateTime.now(),
        attributes: <String, Object?>{
          'source': source,
          'text': text,
        },
      ),
    );
  }

  static void logSaveAction({
    required String source,
    required String vocabId,
    required bool success,
  }) {
    _emit(
      LogEntry(
        level: success ? LogLevel.info : LogLevel.warning,
        category: 'save',
        message: 'Save action',
        timestamp: DateTime.now(),
        attributes: <String, Object?>{
          'source': source,
          'vocab_id': vocabId,
          'success': success,
        },
      ),
    );
  }

  static void logSync({
    required String source,
    required String stage,
    required bool success,
    int? count,
  }) {
    _emit(
      LogEntry(
        level: success ? LogLevel.info : LogLevel.warning,
        category: 'sync',
        message: 'Sync stage update',
        timestamp: DateTime.now(),
        attributes: <String, Object?>{
          'source': source,
          'stage': stage,
          'success': success,
          'count': count,
        },
      ),
    );
  }

  static void logError({
    required String source,
    required String action,
    required Object error,
  }) {
    _emit(
      LogEntry(
        level: LogLevel.error,
        category: 'error',
        message: 'Error captured',
        timestamp: DateTime.now(),
        attributes: <String, Object?>{
          'source': source,
          'action': action,
          'error': error.toString(),
        },
      ),
    );
  }

  static Future<File?> exportRecentLogsToJson({
    String fileName = 'app_logs.json',
  }) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$fileName');
      final payload = _recentEntries.map((entry) => entry.toJson()).toList();
      await file.writeAsString(const JsonEncoder.withIndent('  ').convert(payload));
      return file;
    } catch (error) {
      debugPrint('Failed to export logs (desktop): $error');
      return null;
    }
  }

  static void _emit(LogEntry entry) {
    _recentEntries.add(entry);
    if (_recentEntries.length > _maxRecentEntries) {
      _recentEntries.removeAt(0);
    }

    final attrs = entry.attributes.entries
        .where((item) => item.value != null)
        .map((item) => '${item.key}=${item.value}')
        .join(' ');

    debugPrint(
      '[${entry.level.name.toUpperCase()}][${entry.category}] '
      '${entry.message} $attrs',
    );

    for (final sink in _customSinks) {
      sink(entry);
    }
  }
}
