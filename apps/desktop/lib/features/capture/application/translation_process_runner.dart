import 'dart:async';
import 'dart:convert';
import 'dart:io';

const Duration _kTranslationProcessStreamDrainTimeout = Duration(seconds: 8);
const Duration _kTranslationProcessKillGrace = Duration(seconds: 8);

/// Runs a child process with optional stdin for translation sidecars (testable).
abstract class TranslationProcessRunner {
  Future<ProcessRunResult> run({
    required String executable,
    required List<String> arguments,
    String? stdinText,
    String? workingDirectory,
    required Duration timeout,
  });
}

class ProcessRunResult {
  const ProcessRunResult({
    required this.exitCode,
    required this.stdout,
    required this.stderr,
  });

  final int exitCode;
  final String stdout;
  final String stderr;
}

/// Default [Process] implementation.
class IoTranslationProcessRunner implements TranslationProcessRunner {
  const IoTranslationProcessRunner();

  @override
  Future<ProcessRunResult> run({
    required String executable,
    required List<String> arguments,
    String? stdinText,
    String? workingDirectory,
    required Duration timeout,
  }) async {
    final proc = await Process.start(
      executable,
      arguments,
      workingDirectory: workingDirectory,
      runInShell: false,
    );
    if (stdinText != null) {
      proc.stdin.add(utf8.encode(stdinText));
    }
    await proc.stdin.close();

    final outFuture = proc.stdout.transform(utf8.decoder).join();
    final errFuture = proc.stderr.transform(utf8.decoder).join();
    final exitFuture = proc.exitCode;

    // Drain stdout/stderr while waiting for exit. If we await [exitCode] first,
    // the child can deadlock once a stderr pipe buffer fills.
    try {
      final results = await Future.wait<dynamic>([
        exitFuture,
        outFuture,
        errFuture,
      ]).timeout(timeout);
      return ProcessRunResult(
        exitCode: results[0] as int,
        stdout: results[1] as String,
        stderr: results[2] as String,
      );
    } on TimeoutException {
      proc.kill();
      int exitCode;
      try {
        exitCode = await exitFuture.timeout(_kTranslationProcessKillGrace);
      } on TimeoutException {
        exitCode = -1;
      }
      final stdout = await outFuture.timeout(
        _kTranslationProcessStreamDrainTimeout,
        onTimeout: () => '',
      );
      final stderr = await errFuture.timeout(
        _kTranslationProcessStreamDrainTimeout,
        onTimeout: () => '',
      );
      return ProcessRunResult(
        exitCode: exitCode,
        stdout: stdout,
        stderr: stderr,
      );
    }
  }
}
