import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_shop/core/utils/app_colors.dart';

class PrimaryGradientButton extends StatelessWidget {
  final String? text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool muted;
  final Widget? child;
  final double height;
  final double borderRadius;
  final LinearGradient? gradient;

  const PrimaryGradientButton({
    super.key,
    this.text,
    this.onPressed,
    this.isLoading = false,
    this.muted = false,
    this.child,
    this.height = 54,
    this.borderRadius = 14,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final isInteractive = onPressed != null && !isLoading;
    final useMutedStyle = muted || !isInteractive;

    return SizedBox(
      width: double.infinity,
      height: height,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isInteractive ? onPressed : null,
          borderRadius: BorderRadius.circular(borderRadius),
          splashColor: Colors.white.withValues(alpha: 0.2),
          highlightColor: Colors.white.withValues(alpha: 0.1),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(borderRadius),
              color: useMutedStyle ? const Color(0xFFE2E8F0) : null,
              gradient: useMutedStyle
                  ? null
                  : (gradient ?? AppColors.primaryGradient),
            ),
            child: Center(
              child: isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : (child ??
                      Text(
                        text ?? '',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                          color: useMutedStyle
                              ? const Color(0xFF94A3B8)
                              : Colors.white,
                        ),
                      )),
            ),
          ),
        ),
      ),
    );
  }
}
