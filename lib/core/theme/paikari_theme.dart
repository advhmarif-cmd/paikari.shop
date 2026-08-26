import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PaikariTheme {
  static const String fontFamily = 'Tiro Bangla';
  static const Color primaryColor = Color(0xFF0B1F3A);
  static const Color secondaryColor = Color(0xFFD4A72C);
  static const Color backgroundWhite = Colors.white;
  static const Color inkColor = Color(0xFF0B1F3A);
  static const Color softBorder = Color(0xFFE4E7EC);

  static ThemeData get lightTheme {
    final baseTextTheme = ThemeData.light().textTheme.apply(
      fontFamily: fontFamily,
      bodyColor: inkColor,
      displayColor: inkColor,
    );
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryColor,
      primary: primaryColor,
      secondary: secondaryColor,
      surface: backgroundWhite,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: fontFamily,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: backgroundWhite,
      visualDensity: VisualDensity.standard,
      textTheme: baseTextTheme.copyWith(
        displaySmall: const TextStyle(
          fontFamily: fontFamily,
          fontSize: 28,
          fontWeight: FontWeight.w900,
          color: inkColor,
        ),
        headlineSmall: const TextStyle(
          fontFamily: fontFamily,
          fontSize: 23,
          fontWeight: FontWeight.w900,
          color: inkColor,
        ),
        titleLarge: const TextStyle(
          fontFamily: fontFamily,
          fontSize: 20,
          fontWeight: FontWeight.w900,
          color: inkColor,
        ),
        titleMedium: const TextStyle(
          fontFamily: fontFamily,
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: inkColor,
        ),
        bodyLarge: const TextStyle(
          fontFamily: fontFamily,
          fontSize: 16,
          height: 1.45,
          color: inkColor,
        ),
        bodyMedium: const TextStyle(
          fontFamily: fontFamily,
          fontSize: 14,
          height: 1.45,
          color: inkColor,
        ),
        labelLarge: const TextStyle(
          fontFamily: fontFamily,
          fontSize: 14,
          fontWeight: FontWeight.w800,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 20,
          fontWeight: FontWeight.w900,
          color: Colors.white,
        ),
        iconTheme: IconThemeData(color: Colors.white),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        hintStyle: TextStyle(color: colorScheme.outline, fontSize: 14),
        labelStyle: TextStyle(
          color: colorScheme.outline,
          fontWeight: FontWeight.w700,
        ),
        floatingLabelStyle: const TextStyle(
          color: primaryColor,
          fontWeight: FontWeight.w800,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: softBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primaryColor, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFD92D20)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFD92D20), width: 1.6),
        ),
        prefixIconColor: primaryColor,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 52),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: secondaryColor,
        foregroundColor: primaryColor,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 48),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          minimumSize: const Size(0, 48),
          side: const BorderSide(color: primaryColor, width: 1.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          minimumSize: const Size(48, 44),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: primaryColor.withValues(alpha: 0.08),
        selectedColor: primaryColor.withValues(alpha: 0.16),
        disabledColor: colorScheme.surfaceContainerHighest,
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        labelStyle: const TextStyle(
          fontFamily: fontFamily,
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: inkColor,
        ),
        secondaryLabelStyle: const TextStyle(
          fontFamily: fontFamily,
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: primaryColor,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
      dividerTheme: const DividerThemeData(
        color: softBorder,
        thickness: 0.8,
        space: 1,
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        minLeadingWidth: 24,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primaryColor,
        linearTrackColor: softBorder,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: inkColor,
        contentTextStyle: const TextStyle(
          fontFamily: fontFamily,
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
