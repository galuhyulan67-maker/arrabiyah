import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color emeraldPrimary = Color(0xFF0F766E);
  static const Color emeraldContainer = Color(0xFFCCFBF1);
  static const Color surfaceSoft = Color(0xFFF8FAFC);

  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: emeraldPrimary,
      primary: emeraldPrimary,
      primaryContainer: emeraldContainer,
      surface: surfaceSoft,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: surfaceSoft,
      textTheme: GoogleFonts.poppinsTextTheme(),
      appBarTheme: AppBarTheme(
        backgroundColor: emeraldPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }

  static TextStyle arabicTextStyle({double fontSize = 26, FontWeight weight = FontWeight.bold}) {
    return GoogleFonts.amiri(
      fontSize: fontSize,
      fontWeight: weight,
      height: 1.7,
    );
  }

  static TextStyle transliterationStyle({double fontSize = 14}) {
    return GoogleFonts.poppins(
      fontSize: fontSize,
      fontStyle: FontStyle.italic,
      color: const Color(0xFF334155),
    );
  }
}
