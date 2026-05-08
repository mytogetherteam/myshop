import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppBarTitleWithLogo extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Color titleColor;
  final double fontSize;
  final Color? subtitleColor;

  final Widget? trailing;

  const AppBarTitleWithLogo({
    super.key,
    required this.title,
    this.subtitle,
    this.titleColor = const Color(0xFF1E293B),
    this.fontSize = 20,
    this.subtitleColor,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/app_logo.png', // Main shop logo
      height: 36,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => const Icon(
        Icons.store_rounded,
        color: Color(0xFF1E293B),
        size: 32,
      ),
    );
  }
}
