import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF6750A4);
  static const Color primaryContainer = Color(0xFFEADDFF);
  static const Color secondary = Color(0xFF625B71);
  static const Color secondaryContainer = Color(0xFFE8DEF8);
  static const Color surface = Color(0xFFFFFBFE);
  static const Color background = Color(0xFFF6F5F7);
  static const Color error = Color(0xFFB3261E);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color onSurface = Color(0xFF1C1B1F);
  static const Color onBackground = Color(0xFF1C1B1F);
  static const Color onError = Color(0xFFFFFFFF);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF6750A4), Color(0xFF8B6FC0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
