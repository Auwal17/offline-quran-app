import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // --- Core Color Palette ---
  static const Color primaryGreen = Color(0xFF0F5B3B); // Deep Islamic Green
  static const Color goldAccent = Color(0xFFD4AF37); // Classic Gold
  static const Color backgroundLight = Color(0xFFF9FAFB);
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceDark = Color(0xFF1E1E1E);

  // --- Light Theme ---
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: primaryGreen,
      scaffoldBackgroundColor: backgroundLight,
      colorScheme: const ColorScheme.light(
        primary: primaryGreen,
        secondary: goldAccent,
        surface: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      // Apply Google Fonts for English, but reserve a custom style for Arabic
      textTheme: GoogleFonts.interTextTheme().copyWith(
        displayLarge: const TextStyle(
          fontFamily: 'Uthmani', // Must match the family name in pubspec.yaml
          color: primaryGreen,
          fontSize: 28,
        ),
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: primaryGreen,
        inactiveTrackColor: Colors.black12,
        thumbColor: goldAccent,
      ),
    );
  }

  // --- Dark Theme ---
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: primaryGreen,
      scaffoldBackgroundColor: backgroundDark,
      colorScheme: const ColorScheme.dark(
        primary: primaryGreen,
        secondary: goldAccent,
        surface: surfaceDark,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundDark,
        foregroundColor: goldAccent,
        centerTitle: true,
        elevation: 0,
      ),
      textTheme:
          GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
        displayLarge: const TextStyle(
          fontFamily: 'Uthmani',
          color: goldAccent,
          fontSize: 28,
        ),
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: goldAccent,
        inactiveTrackColor: Colors.white24,
        thumbColor: primaryGreen,
      ),
    );
  }
}
