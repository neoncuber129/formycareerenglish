import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';

void main() {
  group('ContextSentenceExtractor', () {
    test('extracts clause between punctuation', () {
      const passage =
          'First sentence. The new implementation of this policy will take place. Last bit.';
      final s = ContextSentenceExtractor.sentenceContaining(
        passage: passage,
        term: 'implementation',
        termStart: passage.indexOf('implementation'),
        termEnd: passage.indexOf('implementation') + 'implementation'.length,
      );
      expect(
        s,
        'The new implementation of this policy will take place.',
      );
    });

    test('falls back to full passage when term not found', () {
      const passage = 'alpha beta gamma';
      final s = ContextSentenceExtractor.sentenceContaining(
        passage: passage,
        term: 'missing',
      );
      expect(s, passage);
    });

    test('matches term with case-insensitive fallback', () {
      const passage = 'alpha Beta gamma.';
      final s = ContextSentenceExtractor.sentenceContaining(
        passage: passage,
        term: 'beta',
      );
      expect(s, 'alpha Beta gamma.');
    });
  });
}
