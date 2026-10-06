import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import 'audio_source.dart';

/// Downloads remote TTS audio (single URL or chunked Google list) into temp /
/// cache directories, with optional disk cache keyed by `(language, text)`.
///
/// Mirrors the desktop `_TtsAudioFetcher` so mobile can reuse cached chunks
/// across sessions and avoid re-downloading the same words on every review.
class MobileTtsCache {
  MobileTtsCache({http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;
  static const Duration _fetchTimeout = Duration(seconds: 6);
  static const String _cacheDirName = 'fmc_tts_cache';
  static const String _indexFileName = 'index.txt';

  static final Map<String, String> _headers = <String, String>{
    'User-Agent': googleTtsUserAgent,
    'Accept': '*/*',
    'Accept-Language': 'en-US,en;q=0.9',
    'Referer': 'https://translate.google.com/',
  };

  Directory? _cacheRoot;

  Future<Directory> _ensureCacheRoot() async {
    if (_cacheRoot != null) {
      return _cacheRoot!;
    }
    final base = await getTemporaryDirectory();
    final dir = Directory('${base.path}${Platform.pathSeparator}$_cacheDirName');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    _cacheRoot = dir;
    return dir;
  }

  static String makeCacheKey(String text, String? language) {
    final material =
        '${(language ?? '').trim().toLowerCase()}|${text.trim().toLowerCase()}';
    return sha1.convert(utf8.encode(material)).toString().substring(0, 24);
  }

  /// Returns previously cached chunk files for [key] if all referenced files
  /// are present and non-empty.
  Future<List<File>?> cacheGet(String key) async {
    if (key.isEmpty) return null;
    try {
      final root = await _ensureCacheRoot();
      final dir = Directory('${root.path}${Platform.pathSeparator}$key');
      if (!await dir.exists()) {
        return null;
      }
      final indexFile = File(
        '${dir.path}${Platform.pathSeparator}$_indexFileName',
      );
      if (!await indexFile.exists()) {
        return null;
      }
      final names = (await indexFile.readAsString())
          .split('\n')
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .toList(growable: false);
      if (names.isEmpty) {
        return null;
      }
      final files = <File>[];
      for (final name in names) {
        final f = File('${dir.path}${Platform.pathSeparator}$name');
        if (!await f.exists() || (await f.length()) == 0) {
          return null;
        }
        files.add(f);
      }
      return files;
    } catch (_) {
      return null;
    }
  }

  /// Persists [files] under [key]; silent on failure (cache is best-effort).
  Future<void> cachePut(String key, List<File> files) async {
    if (key.isEmpty || files.isEmpty) return;
    try {
      final root = await _ensureCacheRoot();
      final dir = Directory('${root.path}${Platform.pathSeparator}$key');
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
      await dir.create(recursive: true);
      final names = <String>[];
      for (var i = 0; i < files.length; i++) {
        final src = files[i];
        final ext = _guessExtension(src.path);
        final name = 'chunk_$i$ext';
        await src.copy('${dir.path}${Platform.pathSeparator}$name');
        names.add(name);
      }
      final indexFile = File(
        '${dir.path}${Platform.pathSeparator}$_indexFileName',
      );
      await indexFile.writeAsString(names.join('\n'), flush: true);
    } catch (_) {
      // Cache writes are best-effort.
    }
  }

  /// Downloads each URL into a fresh temp directory; returns null on failure.
  Future<List<File>?> fetchAll(List<String> urls) async {
    if (urls.isEmpty) return null;
    final tempDir = await Directory.systemTemp.createTemp('fmc_tts_');
    final files = <File>[];
    try {
      for (var i = 0; i < urls.length; i++) {
        final raw = urls[i].trim();
        if (raw.isEmpty) {
          return null;
        }
        final uri = raw.startsWith('//')
            ? Uri.parse('https:$raw')
            : Uri.parse(raw);
        final response = await _httpClient
            .get(uri, headers: _headers)
            .timeout(_fetchTimeout);
        if (response.statusCode != 200 || response.bodyBytes.isEmpty) {
          return null;
        }
        final ext = _guessExtension(uri.path);
        final file = File(
          '${tempDir.path}${Platform.pathSeparator}chunk_$i$ext',
        );
        await file.writeAsBytes(response.bodyBytes, flush: true);
        files.add(file);
      }
      return files;
    } catch (_) {
      return null;
    }
  }

  String _guessExtension(String path) {
    final clean = path.split('?').first;
    final dot = clean.lastIndexOf('.');
    if (dot < 0) return '.mp3';
    final ext = clean.substring(dot).toLowerCase();
    if (const {'.mp3', '.wav', '.ogg', '.aac', '.m4a'}.contains(ext)) {
      return ext;
    }
    return '.mp3';
  }
}
