import 'package:desktop/core/supabase/capture_storage_uploader.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('shouldAttemptLocalCaptureUpload', () {
    test('empty or remote URL returns false', () {
      expect(shouldAttemptLocalCaptureUpload(''), isFalse);
      expect(shouldAttemptLocalCaptureUpload('   '), isFalse);
      expect(
        shouldAttemptLocalCaptureUpload('https://cdn.example/x.png'),
        isFalse,
      );
      expect(shouldAttemptLocalCaptureUpload('http://x/y'), isFalse);
    });

    test('non-http path returns true', () {
      expect(shouldAttemptLocalCaptureUpload(r'C:\app\captures\a.png'), isTrue);
      expect(shouldAttemptLocalCaptureUpload('/tmp/foo.png'), isTrue);
    });
  });
}
