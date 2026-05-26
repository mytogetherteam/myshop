import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_shop/core/presentation/widgets/primary_gradient_button.dart';
import 'package:my_shop/core/utils/app_colors.dart';

/// Error placeholder with message and retry button.
class ErrorRetryState extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;
  final IconData icon;
  final Color iconColor;
  final String retryLabel;
  final bool scrollable;

  const ErrorRetryState({
    super.key,
    required this.message,
    required this.onRetry,
    this.icon = Icons.error_outline,
    this.iconColor = AppColors.error,
    this.retryLabel = 'Retry',
    this.scrollable = false,
  });

  @override
  Widget build(BuildContext context) {
    final body = Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: iconColor),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: AppColors.onSurface),
            ),
            const SizedBox(height: 24),
            PrimaryGradientButton(
              onPressed: () => onRetry(),
              text: retryLabel,
              height: 48,
              borderRadius: 12,
            ),
          ],
        ),
      ),
    );

    if (!scrollable) return body;

    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: body,
        ),
      ),
    );
  }
}
