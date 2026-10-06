import 'package:desktop/features/capture/application/translation_cache.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TranslationCache', () {
    test('returns cached translation for repeated text', () {
      final cache = TranslationCache(maxEntries: 5);
      var missCount = 0;

      final first = cache.resolve(
        'Obscure',
        onMiss: () {
          missCount += 1;
          return 'Nghia: Obscure';
        },
      );
      final second = cache.resolve(
        'obscure',
        onMiss: () {
          missCount += 1;
          return 'Nghia khác';
        },
      );

      expect(first, 'Nghia: Obscure');
      expect(second, 'Nghia: Obscure');
      expect(missCount, 1);
    });

    test('evicts oldest entries when max size exceeded', () {
      final cache = TranslationCache(maxEntries: 2);

      cache.resolve('one', onMiss: () => '1');
      cache.resolve('two', onMiss: () => '2');
      cache.resolve('three', onMiss: () => '3');

      expect(cache.size, 2);
      expect(cache.contains('one'), isFalse);
      expect(cache.contains('two'), isTrue);
      expect(cache.contains('three'), isTrue);
    });
  });
}
