import 'dart:io';

import 'package:path/path.dart' as p;

/// Resolves the Node + Playwright sidecar tree next to [Platform.resolvedExecutable].
///
/// Override: `PLAYWRIGHT_TRANSLATE_ROOT` = absolute directory containing
/// `run_playwright_translate.mjs` and `node_modules/playwright`.
class PlaywrightRuntimePaths {
  PlaywrightRuntimePaths._();

  static const String envRootKey = 'PLAYWRIGHT_TRANSLATE_ROOT';

  static Directory? resolve({Map<String, String>? environment}) {
    final env = environment ?? Platform.environment;
    final override = env[envRootKey]?.trim();
    if (override != null && override.isNotEmpty) {
      final d = Directory(override);
      if (_isBundleRoot(d)) {
        return d;
      }
    }

    final exeDir = File(Platform.resolvedExecutable).parent.path;
    if (Platform.isWindows) {
      for (final rel in <String>[
        'playwright_translate',
        p.join('data', 'playwright_translate'),
      ]) {
        final d = Directory(p.join(exeDir, rel));
        if (_isBundleRoot(d)) {
          return d;
        }
      }
    } else if (Platform.isMacOS) {
      final macosDir = Directory(Platform.resolvedExecutable).parent;
      final contents = macosDir.parent;
      final macExeDir = macosDir.path;
      final candidates = <String>[
        p.join(contents.path, 'Resources', 'playwright_translate'),
        p.join(
          contents.path,
          'Frameworks',
          'App.framework',
          'Resources',
          'playwright_translate',
        ),
        p.join(macExeDir, 'playwright_translate'),
      ];
      for (final path in candidates) {
        final d = Directory(path);
        if (_isBundleRoot(d)) {
          return d;
        }
      }
    } else {
      for (final rel in <String>[
        'playwright_translate',
        p.join('data', 'playwright_translate'),
      ]) {
        final d = Directory(p.join(exeDir, rel));
        if (_isBundleRoot(d)) {
          return d;
        }
      }
    }
    return null;
  }

  static bool isRunnableBundle(Directory? root) {
    if (root == null || !_isBundleRoot(root)) {
      return false;
    }
    return scriptPath(root) != null;
  }

  static bool _isBundleRoot(Directory d) {
    final script = File(p.join(d.path, 'run_playwright_translate.mjs'));
    final pw = File(p.join(d.path, 'node_modules', 'playwright', 'package.json'));
    return script.existsSync() && pw.existsSync();
  }

  /// `node` / `node.exe` on PATH is invoked; return display path for logs.
  static String nodeExecutableLabel() {
    return Platform.isWindows ? 'node.exe' : 'node';
  }

  static String? scriptPath(Directory root) {
    final s = File(p.join(root.path, 'run_playwright_translate.mjs'));
    return s.existsSync() ? s.path : null;
  }
}
