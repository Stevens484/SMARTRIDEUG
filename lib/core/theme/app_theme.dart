import 'package:flutter/material.dart';

/// SmartRide's shared premium mobility visual language.
/// Navy establishes trust and structure; orange is reserved for action.
class AppTheme {
<<<<<<< HEAD
  // 🎨 NEW COLOR PALETTE — Light Green + White + Grey
  static const Color primary = Color(0xFF10B981); // Light Green
  static const Color primarySoft = Color(0xFFD1FAE5);
  static const Color primaryDark = Color(0xFF059669);
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
        backgroundColor: white,
        foregroundColor: grey900,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: grey900,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: grey700),
=======
  static const navy = Color(0xFF102235);
  static const navyLight = Color(0xFF1C3B5D);
  static const primary = navy;
  static const orange = Color(0xFFFF6B00);
  static const orangeSoft = Color(0xFFFFE8D8);
  static const white = Color(0xFFFFFFFF);
  static const grey50 = Color(0xFFF7F7F5);
  static const grey100 = Color(0xFFF0F1F0);
  static const grey300 = Color(0xFFDCE0E2);
  static const grey500 = Color(0xFF6E7882);
  static const grey700 = Color(0xFF404B55);
  static const grey900 = Color(0xFF1D252C);
  static const success = Color(0xFF16834B);

  // Compatibility names used by existing widgets. They now follow SmartRide.
  static const primaryGreen = navy;
  static const darkGreen = navyLight;
  static const lightGreen = orangeSoft;
  static const accentGreen = orange;

  static ThemeData light() {
    const scheme = ColorScheme.light(
      primary: navy,
      onPrimary: white,
      primaryContainer: Color(0xFFE8EFF5),
      onPrimaryContainer: navy,
      secondary: orange,
      onSecondary: white,
      secondaryContainer: orangeSoft,
      onSecondaryContainer: navy,
      surface: white,
      onSurface: grey900,
      surfaceContainerHighest: grey100,
      onSurfaceVariant: grey500,
      outline: grey300,
      outlineVariant: Color(0xFFE9EBEA),
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
          fontWeight: FontWeight.w800,
          letterSpacing: -.25,
        ),
        iconTheme: IconThemeData(color: white),
      ),
      cardTheme: CardThemeData(
        color: white,
        surfaceTintColor: white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shadowColor: navy.withValues(alpha: .08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFF0F0ED)),
        ),
>>>>>>> 8a93349 (Update SmartRide app features and Firebase integration)
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
<<<<<<< HEAD
          backgroundColor: primary,
          foregroundColor: white,
          elevation: 4,
          shadowColor: primary.withValues(alpha: 0.3),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
=======
          backgroundColor: orange,
          foregroundColor: white,
          elevation: 0,
          minimumSize: const Size(0, 54),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
>>>>>>> 8a93349 (Update SmartRide app features and Firebase integration)
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
<<<<<<< HEAD
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
=======
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: orange,
          foregroundColor: white,
          minimumSize: const Size(0, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
>>>>>>> 8a93349 (Update SmartRide app features and Firebase integration)
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
<<<<<<< HEAD
          foregroundColor: primary,
          side: BorderSide(color: primary, width: 2),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
=======
          foregroundColor: navy,
          minimumSize: const Size(0, 52),
          side: const BorderSide(color: navy, width: 1.2),
>>>>>>> 8a93349 (Update SmartRide app features and Firebase integration)
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
<<<<<<< HEAD
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),

      // 🔥 FIX: CardTheme → CardThemeData
      cardTheme: CardThemeData(
        color: white,
        elevation: 4,
        shadowColor: Colors.black.withValues(alpha: 0.06),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
=======
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: orange,
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
>>>>>>> 8a93349 (Update SmartRide app features and Firebase integration)
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: white,
<<<<<<< HEAD
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: grey300, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        hintStyle: TextStyle(color: grey500),
        labelStyle: TextStyle(color: grey700),
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: white,
        selectedItemColor: primary,
        unselectedItemColor: grey500,
        elevation: 8,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        unselectedLabelStyle: TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 12,
=======
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
>>>>>>> 8a93349 (Update SmartRide app features and Firebase integration)
        ),
        hintStyle: const TextStyle(color: grey500),
        labelStyle: const TextStyle(color: grey700),
        border: _inputBorder(grey300),
        enabledBorder: _inputBorder(grey300),
        focusedBorder: _inputBorder(orange, 1.8),
        errorBorder: _inputBorder(const Color(0xFFB3261E)),
        focusedErrorBorder: _inputBorder(const Color(0xFFB3261E), 1.8),
      ),
<<<<<<< HEAD

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: white,
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: primarySoft,
        labelStyle: TextStyle(color: primaryDark, fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),

      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: grey900,
          fontWeight: FontWeight.w700,
          fontSize: 32,
        ),
        headlineMedium: TextStyle(
          color: grey900,
          fontWeight: FontWeight.w700,
          fontSize: 28,
        ),
        headlineSmall: TextStyle(
          color: grey900,
          fontWeight: FontWeight.w700,
          fontSize: 24,
        ),
        titleLarge: TextStyle(
          color: grey900,
          fontWeight: FontWeight.w700,
          fontSize: 20,
        ),
        titleMedium: TextStyle(
          color: grey900,
=======
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: navy,
        selectedItemColor: orange,
        unselectedItemColor: white,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 11,
>>>>>>> 8a93349 (Update SmartRide app features and Firebase integration)
          fontWeight: FontWeight.w600,
          fontSize: 18,
        ),
        titleSmall: TextStyle(
          color: grey900,
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
        bodyLarge: TextStyle(color: grey700, fontSize: 16),
        bodyMedium: TextStyle(color: grey700, fontSize: 14),
        bodySmall: TextStyle(color: grey500, fontSize: 12),
        labelLarge: TextStyle(
          color: primary,
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
<<<<<<< HEAD
=======
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 74,
        backgroundColor: navy,
        indicatorColor: const Color(0xFF254565),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected) ? orange : white,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            color: states.contains(WidgetState.selected) ? orange : white,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: orange,
        foregroundColor: white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: navy,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? white : grey300,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? orange : grey300,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFE9EBEA),
        thickness: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: navy,
        contentTextStyle: const TextStyle(color: white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: navy,
          fontSize: 32,
          fontWeight: FontWeight.w800,
          letterSpacing: -.8,
        ),
        headlineMedium: TextStyle(
          color: navy,
          fontSize: 28,
          fontWeight: FontWeight.w800,
          letterSpacing: -.6,
        ),
        headlineSmall: TextStyle(
          color: navy,
          fontSize: 24,
          fontWeight: FontWeight.w800,
          letterSpacing: -.4,
        ),
        titleLarge: TextStyle(
          color: navy,
          fontSize: 21,
          fontWeight: FontWeight.w800,
        ),
        titleMedium: TextStyle(
          color: navy,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        titleSmall: TextStyle(
          color: navy,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
        bodyLarge: TextStyle(color: grey700, fontSize: 16, height: 1.45),
        bodyMedium: TextStyle(color: grey700, fontSize: 14, height: 1.4),
        bodySmall: TextStyle(color: grey500, fontSize: 12),
        labelLarge: TextStyle(
          color: orange,
          fontSize: 15,
          fontWeight: FontWeight.w800,
        ),
>>>>>>> 8a93349 (Update SmartRide app features and Firebase integration)
      ),

      dividerTheme: DividerThemeData(color: grey300, thickness: 1),
    );
  }

  static ThemeData dark() {
<<<<<<< HEAD
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: primary,
        secondary: primary,
        surface: const Color(0xFF1F2937),
        background: const Color(0xFF111827),
        onPrimary: white,
        onSurface: white,
        onBackground: white,
        primaryContainer: const Color(0xFF065F46),
      ),
      scaffoldBackgroundColor: const Color(0xFF111827),

      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1F2937),
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

      // 🔥 FIX: CardTheme → CardThemeData
      cardTheme: CardThemeData(
        color: const Color(0xFF1F2937),
        elevation: 4,
        shadowColor: Colors.black.withValues(alpha: 0.4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1F2937),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: const Color(0xFF374151), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primary, width: 2),
=======
    const surface = Color(0xFF132238);
    const surfaceContainer = Color(0xFF1B2E46);
    const onSurface = Color(0xFFF4F7FB);
    const onSurfaceVariant = Color(0xFFC5CCD5);
    const outline = Color(0xFF52657A);
    const scheme = ColorScheme.dark(
      primary: Color(0xFFBFD4EE),
      onPrimary: navy,
      primaryContainer: Color(0xFF254565),
      onPrimaryContainer: Color(0xFFE0ECFA),
      secondary: orange,
      onSecondary: white,
      secondaryContainer: Color(0xFF572A08),
      onSecondaryContainer: Color(0xFFFFD7BB),
      surface: surface,
      onSurface: onSurface,
      surfaceContainerHighest: surfaceContainer,
      onSurfaceVariant: onSurfaceVariant,
      outline: outline,
      outlineVariant: Color(0xFF324861),
      error: Color(0xFFFFB4AB),
    );

    return light().copyWith(
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFF091522),
      cardTheme: CardThemeData(
        color: surface,
        surfaceTintColor: surface,
        elevation: 0,
        shadowColor: Colors.black.withValues(alpha: .22),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFF26384D)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
        hintStyle: const TextStyle(color: onSurfaceVariant),
        labelStyle: const TextStyle(color: onSurfaceVariant),
        border: _inputBorder(outline),
        enabledBorder: _inputBorder(outline),
        focusedBorder: _inputBorder(orange, 1.8),
        errorBorder: _inputBorder(const Color(0xFFFFB4AB)),
        focusedErrorBorder: _inputBorder(const Color(0xFFFFB4AB), 1.8),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.primary,
          minimumSize: const Size(0, 52),
          side: const BorderSide(color: outline, width: 1.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
>>>>>>> 8a93349 (Update SmartRide app features and Firebase integration)
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        hintStyle: TextStyle(color: grey500),
      ),
<<<<<<< HEAD

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
=======
      listTileTheme: const ListTileThemeData(
        iconColor: Color(0xFFBFD4EE),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
>>>>>>> 8a93349 (Update SmartRide app features and Firebase integration)
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF324861),
        thickness: 1,
      ),
      textTheme: light().textTheme
          .apply(bodyColor: onSurface, displayColor: onSurface)
          .copyWith(
            bodyLarge: const TextStyle(
              color: onSurface,
              fontSize: 16,
              height: 1.45,
            ),
            bodyMedium: const TextStyle(
              color: onSurfaceVariant,
              fontSize: 14,
              height: 1.4,
            ),
            bodySmall: const TextStyle(color: onSurfaceVariant, fontSize: 12),
            labelLarge: const TextStyle(
              color: orange,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
    );
  }

  static OutlineInputBorder _inputBorder(Color color, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: color, width: width),
      );
}
