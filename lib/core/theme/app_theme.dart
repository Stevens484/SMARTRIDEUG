import 'package:flutter/material.dart';

/// The visual language shared by every SmartRide surface.
/// Orange is reserved for moments that invite action; navy carries the brand.
class AppTheme {
  static const Color navy = Color(0xFF0B1F3A);
  static const Color navyLight = Color(0xFF16365F);
  static const Color primary = Color(0xFFF26A21);
  static const Color primarySoft = Color(0xFFFFE7D8);
  static const Color primaryDark = Color(0xFFC94D10);
  static const Color white = Color(0xFFFFFFFF);
  static const Color grey50 = Color(0xFFF8F7F4);
  static const Color grey100 = Color(0xFFF0EFEC);
  static const Color grey300 = Color(0xFFDCDAD5);
  static const Color grey500 = Color(0xFF777A80);
  static const Color grey700 = Color(0xFF44464B);
  static const Color grey900 = Color(0xFF181B20);
  static const Color success = Color(0xFF198754);

  // Kept so existing widgets retain their behavior while inheriting branding.
  static const Color primaryGreen = primary;
  static const Color darkGreen = primaryDark;
  static const Color lightGreen = primarySoft;
  static const Color accentGreen = primary;

  static final RoundedRectangleBorder _buttonShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(14),
  );

  static ThemeData light() {
    final scheme = const ColorScheme.light(
      primary: primary,
      onPrimary: white,
      primaryContainer: primarySoft,
      onPrimaryContainer: navy,
      secondary: navy,
      onSecondary: white,
      secondaryContainer: Color(0xFFE8EEF6),
      onSecondaryContainer: navy,
      surface: white,
      onSurface: grey900,
      surfaceContainerHighest: grey100,
      onSurfaceVariant: grey500,
      outline: grey300,
      outlineVariant: Color(0xFFE8E6E2),
      error: Color(0xFFB3261E),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: 'Roboto',
      colorScheme: scheme,
      scaffoldBackgroundColor: grey50,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: const AppBarTheme(
        backgroundColor: navy,
        foregroundColor: white,
        surfaceTintColor: navy,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: white,
          fontSize: 19,
          fontWeight: FontWeight.w700,
          letterSpacing: -.2,
        ),
        iconTheme: IconThemeData(color: white),
      ),
      cardTheme: CardThemeData(
        color: white,
        surfaceTintColor: white,
        elevation: 0,
        shadowColor: navy.withValues(alpha: .08),
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFF0EEEA)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: white,
          elevation: 0,
          minimumSize: const Size(0, 54),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: _buttonShape,
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: white,
          minimumSize: const Size(0, 52),
          shape: _buttonShape,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: navy,
          minimumSize: const Size(0, 52),
          side: const BorderSide(color: navy, width: 1.2),
          shape: _buttonShape,
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
        hintStyle: const TextStyle(color: grey500),
        labelStyle: const TextStyle(color: grey700),
        border: _inputBorder(grey300),
        enabledBorder: _inputBorder(grey300),
        focusedBorder: _inputBorder(primary, 1.8),
        errorBorder: _inputBorder(const Color(0xFFB3261E)),
        focusedErrorBorder: _inputBorder(const Color(0xFFB3261E), 1.8),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 74,
        backgroundColor: navy,
        indicatorColor: Color(0xFF233D60),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected) ? primary : white,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            color: states.contains(WidgetState.selected) ? primary : white,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: navy,
        selectedItemColor: primary,
        unselectedItemColor: white,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: primarySoft,
        labelStyle: const TextStyle(color: navy, fontWeight: FontWeight.w700),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFEAE8E4),
        thickness: 1,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: navy,
          fontWeight: FontWeight.w800,
          fontSize: 32,
          letterSpacing: -.8,
        ),
        headlineMedium: TextStyle(
          color: navy,
          fontWeight: FontWeight.w800,
          fontSize: 28,
          letterSpacing: -.6,
        ),
        headlineSmall: TextStyle(
          color: navy,
          fontWeight: FontWeight.w800,
          fontSize: 24,
          letterSpacing: -.4,
        ),
        titleLarge: TextStyle(
          color: navy,
          fontWeight: FontWeight.w800,
          fontSize: 21,
        ),
        titleMedium: TextStyle(
          color: navy,
          fontWeight: FontWeight.w700,
          fontSize: 18,
        ),
        titleSmall: TextStyle(
          color: navy,
          fontWeight: FontWeight.w700,
          fontSize: 16,
        ),
        bodyLarge: TextStyle(color: grey700, fontSize: 16, height: 1.45),
        bodyMedium: TextStyle(color: grey700, fontSize: 14, height: 1.4),
        bodySmall: TextStyle(color: grey500, fontSize: 12),
        labelLarge: TextStyle(
          color: primary,
          fontWeight: FontWeight.w700,
          fontSize: 15,
        ),
      ),
    );
  }

  static ThemeData dark() => light().copyWith(
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: primary,
      onPrimary: white,
      primaryContainer: Color(0xFF582A15),
      secondary: Color(0xFFB6CCED),
      surface: Color(0xFF142238),
      onSurface: white,
      onSurfaceVariant: Color(0xFFC2C6CC),
      outline: Color(0xFF667083),
    ),
    scaffoldBackgroundColor: const Color(0xFF0A1423),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF142238),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      hintStyle: const TextStyle(color: Color(0xFFC2C6CC)),
      labelStyle: const TextStyle(color: Color(0xFFC2C6CC)),
      border: _inputBorder(const Color(0xFF43526A)),
      enabledBorder: _inputBorder(const Color(0xFF43526A)),
      focusedBorder: _inputBorder(primary, 1.8),
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFF142238),
      surfaceTintColor: const Color(0xFF142238),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFF26364C)),
      ),
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(color: white, fontWeight: FontWeight.w800, fontSize: 32),
      headlineMedium: TextStyle(color: white, fontWeight: FontWeight.w800, fontSize: 28),
      headlineSmall: TextStyle(color: white, fontWeight: FontWeight.w800, fontSize: 24),
      titleLarge: TextStyle(color: white, fontWeight: FontWeight.w800, fontSize: 21),
      titleMedium: TextStyle(color: white, fontWeight: FontWeight.w700, fontSize: 18),
      titleSmall: TextStyle(color: white, fontWeight: FontWeight.w700, fontSize: 16),
      bodyLarge: TextStyle(color: Color(0xFFD8DEE8), fontSize: 16),
      bodyMedium: TextStyle(color: Color(0xFFD8DEE8), fontSize: 14),
      bodySmall: TextStyle(color: Color(0xFFC2C6CC), fontSize: 12),
    ),
  );

  static OutlineInputBorder _inputBorder(Color color, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: color, width: width),
      );
}
