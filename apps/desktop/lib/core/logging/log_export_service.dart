import 'package:flutter/foundation.dart';

import 'logger_service.dart';

class LogExportService {
  const LogExportService._();

  static Future<String?> exportToDefaultLocation() async {
    final file = await LoggerService.exportRecentLogsToJson();
    if (file == null) {
      LoggerService.logError(
        source: 'desktop_log_export',
        action: 'exportToDefaultLocation',
        error: 'export_failed',
      );
      return null;
    }
    final path = file.path;
    LoggerService.logSync(
      source: 'desktop_log_export',
      stage: 'export_done',
      success: true,
      count: LoggerService.recentEntries().length,
    );
    debugPrint('[LOG_EXPORT][desktop] $path');
    return path;
  }
}
