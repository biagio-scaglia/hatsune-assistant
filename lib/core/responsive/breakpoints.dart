import 'package:flutter/material.dart';

/// Breakpoint di riferimento per il responsive layout.
class Breakpoints {
  Breakpoints._();

  /// Sotto i 640px lo schermo è considerato Mobile Small/Large.
  static const double mobile = 640.0;

  /// Da 640px a 1024px lo schermo è considerato Tablet (Portrait/Landscape).
  static const double tablet = 1024.0;

  /// Metodi helper per rilevamento rapido del breakpoint attivo.
  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < mobile;

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= mobile && width < tablet;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= tablet;
}
