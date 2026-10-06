import 'package:desktop/features/capture/data/ocr_adapter.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('formycareer/ocr');

  group('OCR adapter', () {
    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test('MockOcrAdapter returns empty text', () async {
      final adapter = MockOcrAdapter();
      final text = await adapter.extractText();
      expect(text, isEmpty);
    });

    test('RustMethodChannelOcrAdapter returns bridge text when available', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'extractText') {
          return 'real ocr text';
        }
        return null;
      });

      final adapter = RustMethodChannelOcrAdapter();
      final text = await adapter.extractText();
      expect(text, 'real ocr text');
    });

    test('RustMethodChannelOcrAdapter returns empty when null/empty response', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async => '   ');

      final adapter = RustMethodChannelOcrAdapter();
      final text = await adapter.extractText();
      expect(text, isEmpty);
    });

    test('RustMethodChannelOcrAdapter returns empty when exception occurs', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        throw PlatformException(code: '500', message: 'bridge failed');
      });

      final adapter = RustMethodChannelOcrAdapter();
      final text = await adapter.extractText();
      expect(text, isEmpty);
    });
  });
}
