import 'package:desktop/features/capture/application/focus_meaning_controller.dart';
import 'package:desktop/features/capture/presentation/capture_popup.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('resolvePopupSaveSource', () {
    test('returns focused subset when selection is strict subset', () {
      const passage = 'The quick brown fox jumps';
      const focus = FocusMeaningState(
        focusedText: 'brown fox',
        focusStart: 10,
        focusEnd: 19,
      );

      final source = resolvePopupSaveSource(
        passage: passage,
        focus: focus,
      );

      expect(source, 'brown fox');
    });

    test('returns full passage when focus covers all text', () {
      const passage = 'The quick brown fox jumps';
      const focus = FocusMeaningState(
        focusedText: passage,
        focusStart: 0,
        focusEnd: passage.length,
      );

      final source = resolvePopupSaveSource(
        passage: passage,
        focus: focus,
      );

      expect(source, passage);
    });
  });
}

