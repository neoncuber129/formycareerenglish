import 'dart:async';

import 'package:app_l10n/app_l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:settings_core/settings_core.dart';

import 'core/local/local_db.dart';
import 'core/sync/sync_service.dart';
import 'features/dashboard/presentation/mobile_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalDb.initialize();

  final container = ProviderContainer();
  container.read(syncServiceProvider).startBackgroundRetry();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const MobileApp(),
    ),
  );

  WidgetsBinding.instance.addPostFrameCallback((_) {
    unawaited(
      container.read(syncServiceProvider).syncNow().catchError((_) {}),
    );
  });
}

ThemeData _buildMobileTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF4B5FE3),
    brightness: Brightness.light,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    appBarTheme: AppBarTheme(
      centerTitle: true,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      backgroundColor: colorScheme.surface,
      foregroundColor: colorScheme.onSurface,
      surfaceTintColor: colorScheme.surfaceTint,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: colorScheme.surfaceContainerLow,
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 72,
      elevation: 2,
      backgroundColor: colorScheme.surface,
      indicatorColor: colorScheme.secondaryContainer,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
    ),
  );
}

class MobileApp extends ConsumerWidget {
  const MobileApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uiTag = ref.watch(uiLocalePreferenceProvider);
    final locale = localeFromUiPreferenceTag(uiTag);
    return MaterialApp(
      title: 'FormyCareer',
      theme: _buildMobileTheme(),
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      // Avoid PrimaryScrollController + default Scrollbar clashes with IndexedStack tabs.
      scrollBehavior: const MaterialScrollBehavior().copyWith(scrollbars: false),
      home: const MobileShell(),
    );
  }
}
