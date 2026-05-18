import 'package:flutter/material.dart';

class AppColors {
  // Brand Colors
  static const Color primary = Color(0xFF00ADB5); 
  static const Color secondary = Color(0xFFFFD700); 
  static const Color accent = Color(0xFF393E46);

  // Premium Game Palette
  static const Color backgroundDark = Color(0xFF0B0E11); // Daha derin siyah/lacivert
  static const Color surfaceDark = Color(0xFF1F262E);
  static const Color glowGreen = Color(0xFF00FF88); // Doğru cevaplar için parlama
  static const Color neonBlue = Color(0xFF00D2FF);

  // Text Colors
  static const Color textPrimaryDark = Color(0xFFEEEEEE);
  static const Color textSecondaryDark = Color(0xFFB0B0B0);

  // Light Theme Colors
  static const Color backgroundLight = Color(0xFFF9F9F9);
  static const Color surfaceLight = Colors.white;
  static const Color textPrimaryLight = Color(0xFF222831);
  static const Color textSecondaryLight = Color(0xFF393E46);

  // Status Colors
  static const Color error = Color(0xFFFF4B2B);
  static const Color success = Color(0xFF00FF88);
  static const Color warning = Color(0xFFFFA500);

  // Decorations
  static List<BoxShadow> get premiumGlow => [
    BoxShadow(
      color: primary.withValues(alpha: 0.3),
      blurRadius: 10,
      spreadRadius: 2,
    ),
  ];
}
