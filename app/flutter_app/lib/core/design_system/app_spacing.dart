import 'package:flutter/material.dart';

/// Spacing, Padding e Radius coerenti e riutilizzabili nell'app.
class AppSpacing {
  AppSpacing._();

  // Padding e Margini
  static const double xxs = 2.0;
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;

  // Scorciatoie EdgeInsets
  static const EdgeInsets edgeInsetsAllNone = EdgeInsets.zero;
  static const EdgeInsets edgeInsetsAllXs = EdgeInsets.all(xs);
  static const EdgeInsets edgeInsetsAllSm = EdgeInsets.all(sm);
  static const EdgeInsets edgeInsetsAllMd = EdgeInsets.all(md);
  static const EdgeInsets edgeInsetsAllLg = EdgeInsets.all(lg);

  static const EdgeInsets edgeInsetsHorizontalMd = EdgeInsets.symmetric(horizontal: md);
  static const EdgeInsets edgeInsetsVerticalSm = EdgeInsets.symmetric(vertical: sm);
  static const EdgeInsets edgeInsetsVerticalMd = EdgeInsets.symmetric(vertical: md);
}

class AppRadius {
  AppRadius._();

  // Raggi per bordi e angoli
  static const double sm = 6.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double circular = 999.0;

  // Scorciatoie BorderRadius
  static final BorderRadius borderRadiusSm = BorderRadius.circular(sm);
  static final BorderRadius borderRadiusMd = BorderRadius.circular(md);
  static final BorderRadius borderRadiusLg = BorderRadius.circular(lg);
  static final BorderRadius borderRadiusXl = BorderRadius.circular(xl);
  static final BorderRadius borderRadiusCircular = BorderRadius.circular(circular);
}

class AppDurations {
  AppDurations._();

  // Durate animazioni di sistema
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration medium = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
}
