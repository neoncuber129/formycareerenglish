import 'package:desktop/core/logging/logger_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LoggerService', () {
    test('keeps recent entries and clears them', () {
      LoggerService.clearRecentEntries();

      LoggerService.logSync(
        source: 'test_source',
        stage: 'stage_a',
        success: true,
      );
      expect(LoggerService.recentEntries(), isNotEmpty);

      LoggerService.clearRecentEntries();
      expect(LoggerService.recentEntries(), isEmpty);
    });

    test('log entry contains structured attributes', () {
      LoggerService.clearRecentEntries();

      LoggerService.logSaveAction(
        source: 'test_source',
        vocabId: 'abc',
        success: false,
      );

      final entry = LoggerService.recentEntries().last;
      expect(entry.category, 'save');
      expect(entry.attributes['source'], 'test_source');
      expect(entry.attributes['vocab_id'], 'abc');
      expect(entry.attributes['success'], false);
    });
  });
}
