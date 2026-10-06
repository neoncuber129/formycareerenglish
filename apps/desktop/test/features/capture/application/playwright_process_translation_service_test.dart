import 'dart:io';

import 'package:desktop/features/capture/application/playwright_process_translation_service.dart';
import 'package:desktop/features/capture/application/playwright_runtime_paths.dart';
import 'package:desktop/features/capture/application/translation_models.dart';
import 'package:desktop/features/capture/application/translation_process_runner.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRunner implements TranslationProcessRunner {
  ProcessRunResult result = const ProcessRunResult(
    exitCode: 0,
    stdout: '',
    stderr: '',
  );
  int calls = 0;
  String? lastStdin;
  String? lastExecutable;
  List<String>? lastArguments;

  @override
  Future<ProcessRunResult> run({
    required String executable,
    required List<String> arguments,
    String? stdinText,
    String? workingDirectory,
    required Duration timeout,
  }) async {
    calls += 1;
    lastStdin = stdinText;
    lastExecutable = executable;
    lastArguments = arguments;
    return result;
  }
}

void main() {
  test('maps zh/zt/autodetect codes for Google mode', () async {
    final runner = _FakeRunner()
      ..result = const ProcessRunResult(exitCode: 0, stdout: 'ok', stderr: '');
    final root = Directory.systemTemp.createTempSync('fmc_pw_test_map');
    addTearDown(() {
      if (root.existsSync()) {
        root.deleteSync(recursive: true);
      }
    });
    File('${root.path}/run_playwright_translate.mjs').writeAsStringSync('//');
    Directory(
      '${root.path}/node_modules/playwright',
    ).createSync(recursive: true);
    File(
      '${root.path}/node_modules/playwright/package.json',
    ).writeAsStringSync('{}');
    final svc = PlaywrightProcessTranslationService(
      runner: runner,
      pathsResolver: ({Map<String, String>? environment}) => root,
    );
    await svc.translate(
      const TranslationRequest(
        text: 'hello',
        sourceLanguage: 'autodetect',
        targetLanguage: 'zt',
      ),
    );
    expect(runner.lastStdin, contains('"from":"en"'));
    expect(runner.lastStdin, contains('"to":"zh-TW"'));
  });

  test('returns empty when bundle is missing', () async {
    final runner = _FakeRunner();
    final svc = PlaywrightProcessTranslationService(
      runner: runner,
      pathsResolver: ({Map<String, String>? environment}) => null,
    );
    final r = await svc.translate(
      const TranslationRequest(text: 'hello', sourceLanguage: 'en'),
    );
    expect(r.translatedText, isEmpty);
    expect(runner.calls, 0);
  });

  test('sends JSON on stdin and returns stdout', () async {
    final runner = _FakeRunner()
      ..result = const ProcessRunResult(
        exitCode: 0,
        stdout: 'xin chào',
        stderr: '',
      );
    final root = Directory.systemTemp.createTempSync('fmc_pw_test');
    addTearDown(() {
      if (root.existsSync()) {
        root.deleteSync(recursive: true);
      }
    });
    File('${root.path}/run_playwright_translate.mjs').writeAsStringSync('//');
    Directory(
      '${root.path}/node_modules/playwright',
    ).createSync(recursive: true);
    File(
      '${root.path}/node_modules/playwright/package.json',
    ).writeAsStringSync('{}');

    final svc = PlaywrightProcessTranslationService(
      runner: runner,
      pathsResolver: ({Map<String, String>? environment}) => root,
    );
    final r = await svc.translate(
      const TranslationRequest(text: 'hello', sourceLanguage: 'en'),
    );
    expect(r.translatedText, 'xin chào');
    expect(runner.calls, 1);
    expect(runner.lastExecutable, PlaywrightRuntimePaths.nodeExecutableLabel());
    expect(runner.lastStdin, contains('"mode":"google_web"'));
    expect(runner.lastStdin, contains('"text":"hello"'));
  });
}
