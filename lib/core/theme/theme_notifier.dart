import 'package:flutter/material.dart';

class ThemeNotifier extends ValueNotifier<ThemeMode> {
<<<<<<< HEAD
  // 🔥 CHANGE: Default to LIGHT mode (our beautiful new theme)
=======
  // The app always starts light. Dark mode is an explicit user preference.
>>>>>>> 8a93349 (Update SmartRide app features and Firebase integration)
  ThemeNotifier() : super(ThemeMode.light);

  void toggleTheme(bool useDark) {
    value = useDark ? ThemeMode.dark : ThemeMode.light;
  }
}

final themeNotifier = ThemeNotifier();
