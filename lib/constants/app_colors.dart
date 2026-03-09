import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color primaryBlue = Color(0xFF0E3A66);
  static const Color secondaryBlue = Color(0xFF1F5A93);
  static const Color accentBlue = Color(0xFF3A78B8);
  static const Color softBlue = Color(0xFFE7F1FA);

  static const Color leatherWhite = Color(0xFFF7F8FA);
  static const Color offWhite = Color(0xFFECEFF3);
  static const Color canvasWhite = Color(0xFFFFFFFF);

  static const Color background = leatherWhite;
  static const Color surface = canvasWhite;
  static const Color card = offWhite;
  static const Color border = Color(0xFFCCDAE8);

  static const Color textPrimary = Color(0xFF0F2236);
  static const Color textSecondary = Color(0xFF4D647A);
  static const Color textOnPrimary = Colors.white;

  static const Color success = Color(0xFF1F8A5C);
  static const Color warning = Color(0xFFE39A2E);
  static const Color error = Color(0xFFC24444);
}

class AppGradients {
  AppGradients._();

  static const LinearGradient blueLeather = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[Color(0xFF0E3A66), Color(0xFF1F5A93), Color(0xFFE7F1FA)],
  );
}
