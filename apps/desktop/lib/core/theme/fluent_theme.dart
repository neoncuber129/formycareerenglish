import 'package:fluent_ui/fluent_ui.dart';

FluentThemeData buildDesktopFluentLightTheme() {
  return FluentThemeData(
    brightness: Brightness.light,
    accentColor: Colors.blue,
    visualDensity: VisualDensity.standard,
  );
}

FluentThemeData buildDesktopFluentDarkTheme() {
  return FluentThemeData(
    brightness: Brightness.dark,
    accentColor: Colors.blue,
    visualDensity: VisualDensity.standard,
  );
}
