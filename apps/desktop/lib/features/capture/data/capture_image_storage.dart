import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'ocr_adapter.dart';

/// Persists a screen region PNG under app support `captures/`.
class CaptureImageStorage {
  const CaptureImageStorage._();

  static Future<String> persistRegionPng(
    Rect region, {
    required String fileBaseName,
  }) async {
    if (!Platform.isWindows && !Platform.isMacOS) {
      return '';
    }
    final tempPath = await captureRegionToPng(region);
    if (tempPath.isEmpty) {
      return '';
    }
    final tempFile = File(tempPath);
    if (!await tempFile.exists()) {
      return '';
    }
    final support = await getApplicationSupportDirectory();
    final dir = Directory('${support.path}/captures');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    final cleaned = fileBaseName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final safeName = cleaned.length > 80 ? cleaned.substring(0, 80) : cleaned;
    final dest = File('${dir.path}/$safeName.png');
    await tempFile.copy(dest.path);
    try {
      await tempFile.delete();
    } catch (_) {}
    return dest.path;
  }
}
