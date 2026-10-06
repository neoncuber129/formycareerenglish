import 'package:flutter/material.dart';

/// High-contrast light chrome for [CapturePopup] (white surface, no elevation),
/// independent of system dark mode so translation text stays readable.
ThemeData capturePopupUiThemeData() {
  const surface = Color(0xFFFFFFFF);
  const section = Color(0xFFF2F2F2);
  const onSurface = Color(0xFF121212);
  const muted = Color(0xFF5C5C5C);
  const primary = Color(0xFF0B57D0);
  const outline = Color(0xFFD0D0D0);

  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: surface,
    splashFactory: NoSplash.splashFactory,
    colorScheme: const ColorScheme.light(
      brightness: Brightness.light,
      primary: primary,
      onPrimary: Colors.white,
      surface: surface,
      onSurface: onSurface,
      onSurfaceVariant: muted,
      outline: outline,
      outlineVariant: Color(0xFFE4E4E4),
      surfaceContainerHighest: section,
      surfaceContainer: Color(0xFFEAEAEA),
    ),
  );

  return base.copyWith(
    cardTheme: const CardThemeData(
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        elevation: 0,
        shadowColor: Colors.transparent,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primary,
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: onSurface,
      ),
    ),
  );
}
