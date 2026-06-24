import 'package:flutter/material.dart';
import 'package:my_shop/core/utils/app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorSchemeSeed: AppColors.primary,
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      cardColor: Colors.white,
      dividerColor: const Color(0xFFE2E8F0),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Color(0xFF1E293B),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Color(0xFF1E293B)),
        bodyMedium: TextStyle(color: Color(0xFF475569)),
        bodySmall: TextStyle(color: Color(0xFF64748B)),
      ),
      iconTheme: const IconThemeData(
        color: Color(0xFF475569),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorSchemeSeed: AppColors.primary,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF121212), // Deep dark background
      cardColor: const Color(0xFF1E1E1E), // Slightly lighter for cards/containers
      dividerColor: const Color(0xFF2C2C2C),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1E1E1E),
        foregroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Colors.white),
        bodyMedium: TextStyle(color: Color(0xFFE2E8F0)),
        bodySmall: TextStyle(color: Color(0xFF94A3B8)),
      ),
      iconTheme: const IconThemeData(
        color: Color(0xFFE2E8F0),
      ),
    );
  }
}