import 'dart:async';

import 'package:desktop/features/capture/application/capture_controller.dart';
import 'package:desktop/features/capture/application/focus_meaning_controller.dart';
import 'package:desktop/features/capture/application/tts_service.dart';
import 'package:app_l10n/app_l10n.dart';
import 'package:desktop/features/capture/presentation/meaning_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _meaningTestApp(Widget body) {
  return MaterialApp(
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
    ),
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: body),
  );
}

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

class _RecordingTts implements TtsService {
  String? lastText;
  String? lastLanguage;
  String? lastAudioUrl;
  double? lastRate;
  int? lastLoopCount;

  @override
  Future<bool> speak({
    required String text,
    String? language,
    String? audioUrl,
    double rate = 1.0,
    int loopCount = 1,
  }) async {
    lastText = text;
    lastLanguage = language;
    lastAudioUrl = audioUrl;
    lastRate = rate;
    lastLoopCount = loopCount;
    return true;
  }

  @override
  Future<void> stop() async {}
}

/// [speak] waits until [stop] is called (simulates in-flight playback).
class _BlockingTts implements TtsService {
  Completer<void>? _active;
  int stopCalls = 0;

  @override
  Future<bool> speak({
    required String text,
    String? language,
    String? audioUrl,
    double rate = 1.0,
    int loopCount = 1,
  }) async {
    _active = Completer<void>();
    await _active!.future;
    return true;
  }

  @override
  Future<void> stop() async {
    stopCalls++;
    _active?.complete();
  }
}

void main() {
  group('MeaningPanel', () {
    testWidgets('header shows WORD (POS), play, and slashed IPA', (tester) async {
      final recording = _RecordingTts();
      final passage = '0123456789' * 8;
      final container = ProviderContainer(
        overrides: [
          captureControllerProvider
              .overrideWith(() => _TestCaptureController(passage)),
          focusMeaningProvider.overrideWith(
            () => _TestFocusMeaningController(
              const FocusMeaningState(
                focusedText: 'alpha',
                translatedText: 'bản dịch',
                phonetic: 'ˈælfə',
                pronunciation: 'ˈælfə',
                audioUrl: 'https://example.com/a.mp3',
                sourceLanguage: 'en',
                targetLanguage: 'vi',
                partOfSpeech: 'noun',
                languagePair: 'en-vi',
                focusStart: 10,
                focusEnd: 15,
              ),
            ),
          ),
          ttsServiceProvider.overrideWithValue(recording),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: _meaningTestApp(const MeaningPanel()),
        ),
      );

      expect(find.textContaining('(noun)'), findsOneWidget);
      expect(find.textContaining('/ˈælfə/'), findsOneWidget);

      await tester.tap(find.byTooltip('Play pronunciation'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(recording.lastText, 'alpha');
      expect(recording.lastLanguage, 'en');
      expect(recording.lastAudioUrl, 'https://example.com/a.mp3');
    });

    testWidgets('no IPA segment when pronunciation empty', (tester) async {
      final passage = '0123456789' * 8;
      final container = ProviderContainer(
        overrides: [
          captureControllerProvider
              .overrideWith(() => _TestCaptureController(passage)),
          focusMeaningProvider.overrideWith(
            () => _TestFocusMeaningController(
              const FocusMeaningState(
                focusedText: 'beta',
                translatedText: 'b',
                phonetic: '',
                pronunciation: '',
                sourceLanguage: 'en',
                targetLanguage: 'vi',
                partOfSpeech: 'verb',
                languagePair: 'en-vi',
                focusStart: 0,
                focusEnd: 4,
              ),
            ),
          ),
          ttsServiceProvider.overrideWithValue(_RecordingTts()),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: _meaningTestApp(const MeaningPanel()),
        ),
      );

      expect(find.textContaining('/'), findsNothing);
      expect(find.byTooltip('Play pronunciation'), findsOneWidget);
    });

    testWidgets('full passage focus has no play control in meaning panel',
        (tester) async {
      const passage = 'short';
      final container = ProviderContainer(
        overrides: [
          captureControllerProvider
              .overrideWith(() => _TestCaptureController(passage)),
          focusMeaningProvider.overrideWith(
            () => _TestFocusMeaningController(
              const FocusMeaningState(
                focusedText: passage,
                translatedText: 'dịch cả đoạn',
                phonetic: 'ipa',
                pronunciation: 'ipa',
                sourceLanguage: 'en',
                targetLanguage: 'vi',
                languagePair: 'en-vi',
                focusStart: 0,
                focusEnd: passage.length,
              ),
            ),
          ),
          ttsServiceProvider.overrideWithValue(_RecordingTts()),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: _meaningTestApp(const MeaningPanel()),
        ),
      );

      expect(find.textContaining('(noun)'), findsNothing);
      expect(find.byTooltip('Play pronunciation'), findsNothing);
      expect(find.textContaining('dịch cả đoạn'), findsOneWidget);
    });

    testWidgets(
        'when translation echoes English headword, dictionary gloss is primary',
        (tester) async {
      final passage = '0123456789' * 8;
      const dict =
          'A primary election; a preliminary election to select a candidate.';
      final container = ProviderContainer(
        overrides: [
          captureControllerProvider
              .overrideWith(() => _TestCaptureController(passage)),
          focusMeaningProvider.overrideWith(
            () => _TestFocusMeaningController(
              const FocusMeaningState(
                focusedText: 'primary',
                translatedText: 'primary',
                phonetic: '',
                pronunciation: '',
                sourceLanguage: 'en',
                targetLanguage: 'vi',
                partOfSpeech: 'noun',
                languagePair: 'en-vi',
                microExplanation: dict,
                focusStart: 10,
                focusEnd: 17,
              ),
            ),
          ),
          ttsServiceProvider.overrideWithValue(_RecordingTts()),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: _meaningTestApp(const MeaningPanel()),
        ),
      );

      expect(find.text('Definition (English)'), findsOneWidget);
      expect(find.textContaining('primary election'), findsOneWidget);
    });

    testWidgets('play then pause invokes TTS stop', (tester) async {
      final blocking = _BlockingTts();
      final passage = '0123456789' * 8;
      final container = ProviderContainer(
        overrides: [
          captureControllerProvider
              .overrideWith(() => _TestCaptureController(passage)),
          focusMeaningProvider.overrideWith(
            () => _TestFocusMeaningController(
              const FocusMeaningState(
                focusedText: 'alpha',
                translatedText: 'bản dịch',
                phonetic: 'ˈælfə',
                pronunciation: 'ˈælfə',
                audioUrl: '',
                sourceLanguage: 'en',
                targetLanguage: 'vi',
                partOfSpeech: 'noun',
                languagePair: 'en-vi',
                focusStart: 10,
                focusEnd: 15,
              ),
            ),
          ),
          ttsServiceProvider.overrideWithValue(blocking),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: _meaningTestApp(const MeaningPanel()),
        ),
      );

      await tester.tap(find.byTooltip('Play pronunciation'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 120));
      expect(find.byTooltip('Pause'), findsOneWidget);

      await tester.tap(find.byTooltip('Pause'));
      await tester.pump();
      expect(blocking.stopCalls, 1);
      await tester.pump(const Duration(milliseconds: 250));
    });
  });
}
