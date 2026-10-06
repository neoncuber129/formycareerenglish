import '../../../core/hotkey/hotkey_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'smart_capture_service.dart';

class CaptureResult {
  const CaptureResult({
    required this.rawText,
    required this.detectedWord,
    required this.mode,
  });

  final String rawText;
  final String detectedWord;
  final CaptureMode mode;
}

class CapturePipeline {
  const CapturePipeline({required SmartCaptureService smartCaptureService})
    : _smartCaptureService = smartCaptureService;

  final SmartCaptureService _smartCaptureService;

  Future<CaptureResult> captureText({
    required OcrExtractor ocrFallbackExtractor,
  }) async {
    final result = await _smartCaptureService.detectTextMode(
      ocrFallbackExtractor: ocrFallbackExtractor,
    );
    return _mapToCaptureResult(result, CaptureMode.text);
  }

  Future<CaptureResult> captureImage({
    required OcrExtractor ocrExtractor,
  }) async {
    final result = await _smartCaptureService.detectFromOcrOnly(
      ocrExtractor: ocrExtractor,
    );
    return _mapToCaptureResult(result, CaptureMode.image);
  }

  CaptureResult _mapToCaptureResult(
    SmartCaptureResult result,
    CaptureMode mode,
  ) {
    final normalizedRaw = _normalizePassage(result.rawText);
    // Return the full passage as the captured text (not a single word).
    // The raw text always reflects what was selected or OCR'd.
    final effective = normalizedRaw.isNotEmpty
        ? normalizedRaw
        : _normalizePassage(result.detectedText);
    return CaptureResult(
      rawText: normalizedRaw,
      detectedWord: effective,
      mode: mode,
    );
  }

  // Joins hard-wrapped OCR lines into flowing paragraphs while preserving
  // intentional paragraph breaks (blank lines).
  String _normalizePassage(String input) {
    if (input.isEmpty) {
      return '';
    }
    final lines = input.replaceAll('\r\n', '\n').split('\n');
    final paragraphs = <String>[];
    final current = StringBuffer();
    for (final line in lines) {
      final trimmed = line.trim().replaceAll(RegExp(r'[ \t]+'), ' ');
      if (trimmed.isEmpty) {
        if (current.isNotEmpty) {
          paragraphs.add(current.toString().trim());
          current.clear();
        }
        continue;
      }
      if (current.isNotEmpty) {
        current.write(' ');
      }
      current.write(trimmed);
    }
    if (current.isNotEmpty) {
      paragraphs.add(current.toString().trim());
    }
    return paragraphs.join('\n\n').trim();
  }
}

final capturePipelineProvider = Provider<CapturePipeline>((ref) {
  return CapturePipeline(
    smartCaptureService: ref.watch(smartCaptureServiceProvider),
  );
});
