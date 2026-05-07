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
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Image.asset(
          'assets/images/app_logo.png',
          height: 28,
          fit: BoxFit.contain,
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w600,
                  color: titleColor,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: subtitleColor ?? const Color(0xFFED3973),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 12),
          trailing!,
        ],
      ],
    );
  }
}
