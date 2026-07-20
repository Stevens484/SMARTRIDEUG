import 'package:flutter/material.dart';

class ThemeNotifier extends ValueNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.dark);

  void toggleTheme(bool useDark) {
    value = useDark ? ThemeMode.dark : ThemeMode.light;
  }
}

final themeNotifier = ThemeNotifier();
