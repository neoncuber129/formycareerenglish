import 'package:desktop/features/capture/application/capture_controller.dart';
import 'package:desktop/features/capture/application/focus_meaning_controller.dart';
import 'package:desktop/features/capture/presentation/focus_context_strip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _TestCaptureController extends CaptureController {
  _TestCaptureController(this._source);
  final String _source;

  @override
  CaptureState build() => CaptureState(sourceText: _source);
}

class _TestFocusMeaningController extends FocusMeaningController {
  _TestFocusMeaningController(this._initial);
  final FocusMeaningState _initial;

  @override
  FocusMeaningState build() => _initial;
}

void main() {
  group('FocusContextStrip.shouldShow', () {
    const long = 'abcdefghijklmnopqrstuvwxyz0123456789abcdefghijklmnopqr'
        'stuvwxyz0123456789abcdefghijklmn';

    test('false when passage shorter than threshold', () {
      expect(
        FocusContextStrip.shouldShow(
          passage: 'short',
          focusStart: 0,
          focusEnd: 5,
          minPassageLength: 72,
        ),
        isFalse,
      );
    });

    test('false when focus covers full passage', () {
      expect(
        FocusContextStrip.shouldShow(
          passage: long,
          focusStart: 0,
          focusEnd: long.length,
          minPassageLength: 72,
        ),
        isFalse,
      );
    });

    test('true when long passage and strict subset focus', () {
      expect(
        FocusContextStrip.shouldShow(
          passage: long,
          focusStart: 10,
          focusEnd: 20,
          minPassageLength: 72,
        ),
        isTrue,
      );
    });
  });

  group('FocusContextStrip.buildExcerpt', () {
    test('adds ellipses when window is clipped', () {
      final passage = '${'a' * 100}TARGET${'b' * 100}';
      final targetIndex = passage.indexOf('TARGET');
      final end = targetIndex + 'TARGET'.length;
      final r = FocusContextStrip.buildExcerpt(
        passage: passage,
        focusStart: targetIndex,
        focusEnd: end,
        contextRadiusChars: 8,
      );
      expect(r.text.startsWith('…'), isTrue);
      expect(r.text.endsWith('…'), isTrue);
      expect(r.text, contains('TARGET'));
      expect(r.hlStart, lessThan(r.hlEnd));
      expect(r.text.substring(r.hlStart, r.hlEnd), 'TARGET');
    });
  });

  group('FocusContextStrip widget', () {
    testWidgets('hides In context when focus is full passage', (tester) async {
      const long = 'abcdefghijklmnopqrstuvwxyz0123456789abcdefghijklmnopqr'
          'stuvwxyz0123456789abcdefghijklmn';
      final container = ProviderContainer(
        overrides: [
          captureControllerProvider
              .overrideWith(() => _TestCaptureController(long)),
          focusMeaningProvider.overrideWith(
            () => _TestFocusMeaningController(
              const FocusMeaningState(
                focusStart: 0,
                focusEnd: long.length,
              ),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: FocusContextStrip(),
            ),
          ),
        ),
      );

      expect(find.text('In context'), findsNothing);
    });

    testWidgets('shows excerpt when long passage and partial focus',
        (tester) async {
      const long = 'abcdefghijklmnopqrstuvwxyz0123456789abcdefghijklmnopqr'
          'stuvwxyz0123456789abcdefghijklmn';
      final container = ProviderContainer(
        overrides: [
          captureControllerProvider
              .overrideWith(() => _TestCaptureController(long)),
          focusMeaningProvider.overrideWith(
            () => _TestFocusMeaningController(
              const FocusMeaningState(
                focusStart: 36,
                focusEnd: 40,
              ),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: FocusContextStrip(),
            ),
          ),
        ),
      );

      expect(find.text('In context'), findsOneWidget);
      expect(find.byType(SelectableText), findsOneWidget);
    });
  });
}
