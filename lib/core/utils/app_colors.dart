import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFFED3973);
  static const Color secondary = Color(0xFFEFA240);
  
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, secondary],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient verticalGradient = LinearGradient(
    colors: [primary, secondary],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Semantic Colors
  static const Color error = Color(0xFFEF4444);
  static const Color errorContainer = Color(0xFFFFF1F2);
  static const Color errorLight = Color(0xFFFECDD3);
  
  static const Color surfaceVariant = Color(0xFFF1F5F9);
  static const Color onSurface = Color(0xFF1E293B);
  static const Color onSurfaceVariant = Color(0xFF64748B);
  
  static const Color outline = Color(0xFF94A3B8);
  static const Color outlineVariant = Color(0xFFE2E8F0);

  static const Color warningContainer = Color(0xFFFFF7ED);
  static const Color warningLight = Color(0xFFFED7AA);

  static Color getFadedColor(Color color, [double opacity = 0.1]) {
    return color.withValues(alpha: opacity);
  }
}
