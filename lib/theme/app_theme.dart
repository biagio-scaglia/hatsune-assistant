import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ---------------------------------------------------------------------------
// Palette — ispirata a Hatsune Miku: cyan/teal + antracite + accenti rosa
// ---------------------------------------------------------------------------

class MikuColors {
  MikuColors._();

  /// Cyan primario Miku
  static const Color cyan = Color(0xFF39C5BB);

  /// Cyan più luminoso per hover/accenti
  static const Color cyanLight = Color(0xFF5CE0D8);

  /// Rosa accento
  static const Color pink = Color(0xFFFF6B9D);

  /// Sfondo principale (quasi nero, blu-scuro)
  static const Color background = Color(0xFF0A0E1A);

  /// Superficie card/pannelli
  static const Color surface = Color(0xFF111827);

  /// Superficie elevata (card secondarie, header)
  static const Color surfaceElevated = Color(0xFF1A2236);

  /// Bordo sottile per card
  static const Color border = Color(0xFF2A3550);

  /// Testo primario
  static const Color textPrimary = Color(0xFFF0F4FF);

  /// Testo secondario
  static const Color textSecondary = Color(0xFF8B95B0);

  /// Bubble utente nella chat
  static const Color userBubble = Color(0xFF1E3A5F);

  /// Bubble assistant nella chat
  static const Color assistantBubble = Color(0xFF162235);
}

// ---------------------------------------------------------------------------
// Breakpoints responsive
// ---------------------------------------------------------------------------

class Breakpoints {
  Breakpoints._();

  /// Sotto questa soglia → layout mobile (colonna)
  static const double mobile = 600;

  /// Sopra questa soglia → layout desktop/tablet (riga)
  static const double tablet = 900;
}

// ---------------------------------------------------------------------------
// Spacing e radius costanti
// ---------------------------------------------------------------------------

class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

class AppRadius {
  AppRadius._();

  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
}

// ---------------------------------------------------------------------------
// ThemeData factory — tema dark premium
// ---------------------------------------------------------------------------

class AppTheme {
  AppTheme._();

  static ThemeData get dark {
    final baseTextTheme = GoogleFonts.interTextTheme(
      ThemeData.dark().textTheme,
    );

    // Titoli con font futuristico
    final headlineStyle = GoogleFonts.rajdhani(
      fontWeight: FontWeight.w700,
      color: MikuColors.textPrimary,
    );

    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: MikuColors.background,
      colorScheme: const ColorScheme.dark(
        primary: MikuColors.cyan,
        secondary: MikuColors.pink,
        surface: MikuColors.surface,
        onPrimary: MikuColors.background,
        onSecondary: MikuColors.textPrimary,
        onSurface: MikuColors.textPrimary,
      ),
      textTheme: baseTextTheme.copyWith(
        headlineLarge: headlineStyle.copyWith(fontSize: 28),
        headlineMedium: headlineStyle.copyWith(fontSize: 22),
        headlineSmall: headlineStyle.copyWith(fontSize: 18),
        titleLarge: headlineStyle.copyWith(fontSize: 20),
        titleMedium: headlineStyle.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(
          color: MikuColors.textPrimary,
        ),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(
          color: MikuColors.textSecondary,
        ),
        bodySmall: baseTextTheme.bodySmall?.copyWith(
          color: MikuColors.textSecondary,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: MikuColors.surfaceElevated,
        selectedColor: MikuColors.cyan,
        labelStyle: baseTextTheme.bodyMedium?.copyWith(
          color: MikuColors.textPrimary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
      ),
      cardTheme: CardThemeData(
        color: MikuColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: const BorderSide(color: MikuColors.border, width: 1),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
    );
  }
}
