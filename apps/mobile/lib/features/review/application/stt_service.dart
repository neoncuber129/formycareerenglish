/// LCS-based similarity between a spoken transcript and the expected term.
///
/// Kept for unit tests; speech-to-text UI and plugin were removed from the app.
int pronunciationSimilarityPercent(String spoken, String expected) {
  final a = _normalize(spoken);
  final b = _normalize(expected);
  if (a.isEmpty || b.isEmpty) {
    return 0;
  }
  final lcs = _lcsLength(a, b);
  final maxLen = a.length > b.length ? a.length : b.length;
  if (maxLen == 0) return 0;
  return ((lcs * 100) / maxLen).round().clamp(0, 100);
}

String _normalize(String value) {
  final lowered = value.trim().toLowerCase();
  final cleaned = lowered.replaceAll(RegExp(r"[^\p{L}\p{N}\s']", unicode: true), '');
  return cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();
}

int _lcsLength(String a, String b) {
  if (a.isEmpty || b.isEmpty) return 0;
  final n = a.length;
  final m = b.length;
  final dp = List<List<int>>.generate(
    n + 1,
    (_) => List<int>.filled(m + 1, 0),
  );
  for (var i = 1; i <= n; i++) {
    for (var j = 1; j <= m; j++) {
      if (a[i - 1] == b[j - 1]) {
        dp[i][j] = dp[i - 1][j - 1] + 1;
      } else {
        dp[i][j] = dp[i - 1][j] >= dp[i][j - 1] ? dp[i - 1][j] : dp[i][j - 1];
      }
    }
  }
  return dp[n][m];
}

/// BCP-47 style locale id (hyphen) for reference/tests only.
String sttLocaleFromLanguageCode(String code) {
  final normalized = code.trim().toLowerCase();
  switch (normalized) {
    case '':
    case 'en':
      return 'en-US';
    case 'vi':
      return 'vi-VN';
    case 'ja':
      return 'ja-JP';
    case 'ko':
      return 'ko-KR';
    case 'zh':
    case 'zh-cn':
    case 'zh_cn':
      return 'zh-CN';
    case 'zh-tw':
    case 'zh_tw':
      return 'zh-TW';
    case 'fr':
      return 'fr-FR';
    case 'de':
      return 'de-DE';
    case 'es':
      return 'es-ES';
    case 'it':
      return 'it-IT';
    case 'pt':
      return 'pt-BR';
    case 'ru':
      return 'ru-RU';
    case 'th':
      return 'th-TH';
    case 'id':
      return 'id-ID';
    default:
      return '$normalized-${normalized.toUpperCase()}';
  }
}
