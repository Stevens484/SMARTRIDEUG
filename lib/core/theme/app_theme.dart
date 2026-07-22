import 'package:flutter/material.dart';

class AppTheme {
  // 🎨 NEW COLOR PALETTE — Light Green + White + Grey
  static const Color primary = Color(0xFF10B981); // Light Green
  static const Color primarySoft = Color(0xFFD1FAE5);
  static const Color primaryDark = Color(0xFF059669);
  static const Color white = Color(0xFFFFFFFF);
  static const Color grey50 = Color(0xFFF9FAFB);
  static const Color grey100 = Color(0xFFF3F4F6);
  static const Color grey300 = Color(0xFFD1D5DB);
  static const Color grey500 = Color(0xFF6B7280);
  static const Color grey700 = Color(0xFF374151);
  static const Color grey900 = Color(0xFF111827);

  // 🔥 BACKWARD COMPATIBILITY — for old files still using primaryGreen
  static const Color primaryGreen = primary;
  static const Color darkGreen = primaryDark;
  static const Color lightGreen = primarySoft;
  static const Color accentGreen = primary;

  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: primary,
        secondary: primary,
        surface: white,
        background: grey50,
        onPrimary: white,
        onSurface: grey900,
        onBackground: grey900,
        primaryContainer: primarySoft,
      ),
      scaffoldBackgroundColor: grey50,

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
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: white,
          elevation: 4,
          shadowColor: primary.withValues(alpha: 0.3),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: BorderSide(color: primary, width: 2),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
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
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: white,
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
        ),
      ),

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
      ),

      dividerTheme: DividerThemeData(color: grey300, thickness: 1),
    );
  }

  static ThemeData dark() {
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
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: white),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: white,
          elevation: 4,
          shadowColor: primary.withValues(alpha: 0.3),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: BorderSide(color: primary, width: 2),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
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
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        hintStyle: TextStyle(color: grey500),
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF1F2937),
        selectedItemColor: primary,
        unselectedItemColor: grey500,
        elevation: 8,
        type: BottomNavigationBarType.fixed,
      ),

      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: white,
          fontWeight: FontWeight.w700,
          fontSize: 32,
        ),
        headlineMedium: TextStyle(
          color: white,
          fontWeight: FontWeight.w700,
          fontSize: 28,
        ),
        headlineSmall: TextStyle(
          color: white,
          fontWeight: FontWeight.w700,
          fontSize: 24,
        ),
        titleLarge: TextStyle(
          color: white,
          fontWeight: FontWeight.w700,
          fontSize: 20,
        ),
        titleMedium: TextStyle(
          color: white,
          fontWeight: FontWeight.w600,
          fontSize: 18,
        ),
        titleSmall: TextStyle(
          color: white,
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
        bodyLarge: TextStyle(color: white, fontSize: 16),
        bodyMedium: TextStyle(color: white, fontSize: 14),
        bodySmall: TextStyle(color: grey500, fontSize: 12),
        labelLarge: TextStyle(
          color: primary,
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
    );
  }
}
