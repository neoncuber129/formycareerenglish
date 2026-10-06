import 'package:desktop/features/capture/presentation/interactive_source_field.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('expandWordSelection', () {
    test('expands offset inside ASCII word', () {
      const text = 'hello world';
      final sel = expandWordSelection(text, 2);
      expect(sel.start, 0);
      expect(sel.end, 5);
    });

    test('returns collapsed when offset not in a letter run', () {
      const text = '  !!  ';
      final sel = expandWordSelection(text, 2);
      expect(sel.isCollapsed, isTrue);
      expect(sel.extentOffset, 2);
    });
  });
}
