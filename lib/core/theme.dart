import 'package:flutter/material.dart';

class AppTheme {
  // Vidyarth Brand Colors (based on your logo)
  static const Color primaryBlue = Color(0xFF0055B6); // Deep Professional Blue
  static const Color accentCyan = Color(0xFF00B4D8);  // Lighter Cyan/Blue
  static const Color backgroundWhite = Color(0xFFF8F9FA);
  static const Color textDark = Color(0xFF1A1A1A);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      primaryColor: primaryBlue,
      scaffoldBackgroundColor: backgroundWhite,
      fontFamily: 'Poppins', // Assuming you use Google Fonts
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryBlue,
        surface: backgroundWhite,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: textDark
        ),
      ),
    );
  }
}