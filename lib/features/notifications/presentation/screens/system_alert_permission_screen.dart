import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:my_shop/core/data/services/storage_service.dart';
import 'package:my_shop/core/presentation/widgets/primary_gradient_button.dart';
import 'package:my_shop/core/localization/app_localizations.dart';
import 'package:my_shop/core/utils/app_colors.dart';

class SystemAlertPermissionScreen extends StatelessWidget {
  const SystemAlertPermissionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFED3973);
    final t = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark ? Theme.of(context).cardColor : Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
          child: Column(
            children: [
              const Spacer(),
              // Icon/Illustration placeholder
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: ShaderMask(
                  blendMode: BlendMode.srcIn,
                  shaderCallback: (Rect bounds) => AppColors.primaryGradient.createShader(bounds),
                  child: Icon(
                    PhosphorIconsFill.deviceMobileCamera,
                    size: 80,
                  ),
                ),
              ),
              SizedBox(height: 48),
              Text(
                t?.translate('display_over_apps') ?? "Display Over Apps",
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              Text(
                t?.translate('display_over_apps_desc') ?? 'Required to wake up the screen and show new orders like a phone call.',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              // Action Buttons
              SizedBox(
                width: double.infinity,
                child: PrimaryGradientButton(
                  onPressed: () async {
                    final status = await Permission.systemAlertWindow.request();
                    if (status.isPermanentlyDenied) {
                      await openAppSettings();
                    }
                    await StorageService.instance.setSystemAlertHandled(true);
                    if (context.mounted) {
                      Navigator.pushReplacementNamed(context, '/navigation');
                    }
                  },
                  text: t?.translate('allow_access') ?? 'Allow Access',
                  height: 56,
                  borderRadius: 16,
                ),
              ),
              SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () async {
                    await StorageService.instance.setSystemAlertHandled(true);
                    if (context.mounted) {
                      Navigator.pushReplacementNamed(context, '/navigation');
                    }
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    t?.translate('maybe_later') ?? 'Maybe Later',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: (Theme.of(context).brightness == Brightness.dark ? Theme.of(context).dividerColor : (Theme.of(context).brightness == Brightness.dark ? Theme.of(context).dividerColor : const Color(0xFF94A3B8))),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
