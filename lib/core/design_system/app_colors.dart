import 'package:flutter/material.dart';

/// Colori di sistema per l'app Hatsune Assistant.
/// Ispirati alla palette cibernetica di Hatsune Miku: antracite scuro, cyan/teal e rosa neon.
class AppColors {
  AppColors._();

  // Colori Principali
  static const Color background = Color(0xFF080B11); // Quasi nero cibernetico
  static const Color surface = Color(0xFF10141D); // Colore card/pannelli principali
  static const Color surfaceElevated = Color(0xFF181D2A); // Colore card secondarie o hover

  // Accenti
  static const Color primary = Color(0xFF39C5BB); // Cyan Hatsune Miku
  static const Color primaryLight = Color(0xFF5CE0D8); // Cyan luminoso per hover
  static const Color secondary = Color(0xFFFF6B9D); // Rosa neon d'accento
  static const Color accentBlue = Color(0xFF007BFF); // Blu secondario per link/pulsanti

  // Bordi e Divisori
  static const Color border = Color(0xFF1F293D); // Bordo scuro standard
  static const Color borderGlow = Color(0xFF2C4356); // Bordo illuminato per elementi attivi

  // Testo
  static const Color textPrimary = Color(0xFFF1F5F9); // Bianco sporco per massima leggibilità
  static const Color textSecondary = Color(0xFF94A3B8); // Grigio ardesia per didascalie
  static const Color textMuted = Color(0xFF64748B); // Grigio scuro disattivato

  // Stati
  static const Color success = Color(0xFF10B981); // Verde per stato online/attivo
  static const Color warning = Color(0xFFF59E0B); // Arancione
  static const Color error = Color(0xFFEF4444); // Rosso per errori/disattivato
  static const Color localModel = Color(0xFF8B5CF6); // Viola per modelli locali Ollama
  static const Color cloudModel = Color(0xFF3B82F6); // Blu per modelli Cloud

  // Gradienti
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, Color(0xFF23A198)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cyberGradient = LinearGradient(
    colors: [primary, secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
