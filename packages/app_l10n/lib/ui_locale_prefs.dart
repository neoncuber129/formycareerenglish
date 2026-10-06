import 'package:flutter/material.dart';

import 'gen_l10n/app_localizations.dart';

/// Maps persisted UI locale tag to [Locale]. Empty tag follows system locale.
Locale? localeFromUiPreferenceTag(String tag) {
  final t = tag.trim().toLowerCase();
  if (t.isEmpty) {
    return null;
  }
  switch (t) {
    case 'en':
      return const Locale('en');
    case 'vi':
      return const Locale('vi');
    case 'ja':
      return const Locale('ja');
    case 'zh':
      return const Locale('zh');
    case 'ko':
      return const Locale('ko');
    default:
      return null;
  }
}

/// Stored combo values for UI locale preference (`''` = system).
const List<String> kUiLocalePreferenceComboTags = <String>[
  '',
  'en',
  'vi',
  'ja',
  'zh',
  'ko',
];

String labelForUiLocaleTag(AppLocalizations l10n, String tag) {
  switch (tag.trim().toLowerCase()) {
    case '':
      return l10n.uiLocaleSystem;
    case 'en':
      return l10n.uiLocaleEnglish;
    case 'vi':
      return l10n.uiLocaleVietnamese;
    case 'ja':
      return l10n.uiLocaleJapanese;
    case 'zh':
      return l10n.uiLocaleChinese;
    case 'ko':
      return l10n.uiLocaleKorean;
    default:
      return l10n.uiLocaleSystem;
  }
}
