import 'dart:collection';

import 'package:flutter_riverpod/flutter_riverpod.dart';

typedef TranslationBuilder = String Function();

class TranslationCache {
  TranslationCache({this.maxEntries = 200});

  final int maxEntries;
  final LinkedHashMap<String, String> _cache = LinkedHashMap<String, String>();
  int _hitCount = 0;
  int _missCount = 0;

  String resolve(
    String sourceText, {
    required TranslationBuilder onMiss,
  }) {
    final key = normalizeKey(sourceText);
    if (key.isEmpty) {
      return '';
    }

    final cached = _cache.remove(key);
    if (cached != null) {
      // Reinsert to keep recency ordering.
      _cache[key] = cached;
      _hitCount += 1;
      return cached;
    }

    _missCount += 1;
    final translated = onMiss();
    _cache[key] = translated;
    _trimIfNeeded();
    return translated;
  }

  int get size => _cache.length;
  int get hitCount => _hitCount;
  int get missCount => _missCount;
  int get lookupCount => _hitCount + _missCount;
  double get hitRatio => lookupCount == 0 ? 0 : _hitCount / lookupCount;

  String? getCached(String sourceText) {
    final key = normalizeKey(sourceText);
    if (key.isEmpty) {
      return null;
    }
    final cached = _cache.remove(key);
    if (cached == null) {
      _missCount += 1;
      return null;
    }
    _cache[key] = cached;
    _hitCount += 1;
    return cached;
  }

  void save(String sourceText, String translatedText) {
    final key = normalizeKey(sourceText);
    if (key.isEmpty) {
      return;
    }
    _cache[key] = translatedText;
    _trimIfNeeded();
  }

  bool contains(String sourceText) {
    return _cache.containsKey(normalizeKey(sourceText));
  }

  static String normalizeKey(String sourceText) {
    final trimmed = sourceText.trim();
    if (trimmed.isEmpty) {
      return '';
    }
    return trimmed.replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
  }

  void _trimIfNeeded() {
    while (_cache.length > maxEntries) {
      _cache.remove(_cache.keys.first);
    }
  }
}

final translationCacheProvider = Provider<TranslationCache>((ref) {
  return TranslationCache(maxEntries: 200);
});
