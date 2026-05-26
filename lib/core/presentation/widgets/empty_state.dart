import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_shop/core/utils/app_colors.dart';

/// Centered empty-list placeholder. Set [scrollable] when used inside
/// [RefreshIndicator] so pull-to-refresh works on an empty list.
class EmptyState extends StatelessWidget {
  final Widget icon;
  final String title;
  final String? subtitle;
  final bool scrollable;
  final bool circleBackground;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.scrollable = true,
    this.circleBackground = false,
  });

  @override
  Widget build(BuildContext context) {
    final content = Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (circleBackground)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: AppColors.surfaceVariant,
                shape: BoxShape.circle,
              ),
              child: icon,
            )
          else
            icon,
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppColors.outline,
              ),
            ),
          ],
        ],
      ),
    );

    if (!scrollable) return content;

    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: content,
        ),
      ),
    );
  }
}
