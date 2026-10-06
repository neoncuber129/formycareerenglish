import 'package:flutter_test/flutter_test.dart';

import 'package:shared_models/shared_models.dart';

void main() {
  test('vocab initial has expected defaults', () {
    final vocab = Vocab.initial(
      id: '1',
      sourceText: 'hello',
      translatedText: 'xin chao',
      languagePair: 'en-vi',
    );

    expect(vocab.intervalDays, 1);
    expect(vocab.reviewCount, 0);
    expect(vocab.easeFactor, 2.5);
  });
}
