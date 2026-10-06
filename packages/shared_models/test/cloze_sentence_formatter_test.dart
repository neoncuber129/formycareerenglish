import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';

List<String> _collectTexts(InlineSpan span) {
  final out = <String>[];
  void walk(InlineSpan s) {
    if (s is TextSpan) {
      if (s.text != null && s.text!.isNotEmpty) {
        out.add(s.text!);
      }
      if (s.children != null) {
        for (final c in s.children!) {
          walk(c);
        }
      }
    }
  }

  walk(span);
  return out;
}

void main() {
  const base = TextStyle(fontSize: 16, color: Color(0xFF000000));
  const cloze = TextStyle(
    fontSize: 16,
    color: Color(0xFFFF0000),
    decoration: TextDecoration.underline,
  );

  group('formatClozeSentence', () {
    test('case-insensitive, preserves surrounding punctuation', () {
      final span = formatClozeSentence(
        sentence: 'The Implementation, and implementation.',
        term: 'implementation',
        baseStyle: base,
        clozeStyle: cloze,
      );
      expect(
        _collectTexts(span),
        ['The ', '[...]', ', and ', '[...]', '.'],
      );
    });

    test('replaces all token occurrences (not inside larger words)', () {
      final span = formatClozeSentence(
        sentence: 'cat catalog cat',
        term: 'cat',
        baseStyle: base,
        clozeStyle: cloze,
      );
      expect(_collectTexts(span), ['[...]', ' catalog ', '[...]']);
    });

    test('no match returns full sentence as one segment', () {
      final span = formatClozeSentence(
        sentence: 'No match here',
        term: 'xyz',
        baseStyle: base,
      );
      expect(_collectTexts(span), ['No match here']);
    });

    test('empty term returns full sentence', () {
      final span = formatClozeSentence(
        sentence: 'Hello',
        term: '   ',
        baseStyle: base,
      );
      expect(_collectTexts(span), ['Hello']);
    });
  });

  group('countClozeMatches', () {
    test('counts case-insensitive token matches', () {
      expect(
        countClozeMatches('The Implementation, and implementation.', 'implementation'),
        2,
      );
      expect(countClozeMatches('aa x aa', 'aa'), 2);
      expect(countClozeMatches('no', 'yes'), 0);
    });

    test('does not match inside apostrophe or hyphen compounds', () {
      expect(countClozeMatches("don't do it", 'do'), 1);
      expect(countClozeMatches('state-of-the-art', 'art'), 0);
      expect(countClozeMatches("mother-in-law", 'law'), 0);
    });
  });
}
