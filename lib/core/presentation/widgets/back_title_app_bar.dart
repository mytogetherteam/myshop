import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:my_shop/core/utils/app_colors.dart';

/// Standard secondary-screen app bar: white background, back arrow, Poppins title.
class BackTitleAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Widget? titleWidget;
  final List<Widget>? actions;
  final VoidCallback? onBack;
  final bool centerTitle;
  final bool showBackButton;

  const BackTitleAppBar({
    super.key,
    required this.title,
    this.titleWidget,
    this.actions,
    this.onBack,
    this.centerTitle = false,
    this.showBackButton = true,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: centerTitle,
      automaticallyImplyLeading: showBackButton,
      leading: showBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: onBack ?? () => Navigator.pop(context),
            )
          : null,
      title: titleWidget ??
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurface,
            ),
          ),
      actions: actions,
    );
  }
}

/// Gradient `+` icon for app-bar trailing actions (rider management, feedback, etc.).
class GradientAddIconButton extends StatelessWidget {
  final VoidCallback onPressed;

  const GradientAddIconButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: ShaderMask(
        shaderCallback: (bounds) => AppColors.primaryGradient.createShader(bounds),
        child: const PhosphorIcon(PhosphorIconsRegular.plus, color: Colors.white),
      ),
    );
  }
}
