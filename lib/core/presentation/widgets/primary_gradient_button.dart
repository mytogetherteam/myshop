import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_shop/core/utils/app_colors.dart';

class PrimaryGradientButton extends StatelessWidget {
  final String? text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Widget? child;
  final double height;
  final double borderRadius;
  final LinearGradient? gradient;

  const PrimaryGradientButton({
    super.key,
    this.text,
    this.onPressed,
    this.isLoading = false,
    this.child,
    this.height = 54,
    this.borderRadius = 14,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = onPressed == null || isLoading;

    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: isDisabled
            ? AppColors.getFadedGradient(AppColors.primaryGradient, 0.4)
            : (gradient ?? AppColors.primaryGradient),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isDisabled ? null : onPressed,
          borderRadius: BorderRadius.circular(borderRadius),
          splashColor: Colors.white.withValues(alpha: 0.2),
          highlightColor: Colors.white.withValues(alpha: 0.1),
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
                        color: Colors.white,
                      ),
                    )),
          ),
        ),
      ),
    );
  }
}
