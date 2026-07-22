import 'package:flutter/material.dart';

class ThemeNotifier extends ValueNotifier<ThemeMode> {
  // 🔥 CHANGE: Default to LIGHT mode (our beautiful new theme)
  ThemeNotifier() : super(ThemeMode.light);

  void toggleTheme(bool useDark) {
    value = useDark ? ThemeMode.dark : ThemeMode.light;
  }
}

final themeNotifier = ThemeNotifier();
