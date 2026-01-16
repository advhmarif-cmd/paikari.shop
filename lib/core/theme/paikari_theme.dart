import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PaikariTheme {
  // New Brand Palette based on logo
  static const Color primaryColor = Color(0xFF4B39EF);
  static const Color secondaryColor = Color(0xFFEE4492);
  static const Color backgroundWhite = Color(0xFFFBFBFF);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: secondaryColor,
        surface: backgroundWhite,
      ),
      textTheme: GoogleFonts.tiroBanglaTextTheme().copyWith(
        bodyLarge: GoogleFonts.tiroBangla(),
        bodyMedium: GoogleFonts.tiroBangla(),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          textStyle: GoogleFonts.tiroBangla(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
