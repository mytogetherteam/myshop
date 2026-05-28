import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:my_shop/core/notifications/notification_service.dart';
import 'package:my_shop/core/data/services/storage_service.dart';
import 'package:my_shop/core/presentation/widgets/primary_gradient_button.dart';
import 'package:my_shop/core/localization/app_localizations.dart';

class NotificationPermissionScreen extends StatelessWidget {
  const NotificationPermissionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFED3973);
    final t = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
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
                  color: primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  PhosphorIconsFill.bellRinging,
                  size: 80,
                  color: primaryColor,
                ),
              ),
              const SizedBox(height: 48),
              Text(
                t?.translate('dont_miss_out') ?? "Don't Miss Out!",
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E293B),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                t?.translate('notification_permission_desc') ?? 'Turn on notifications to get real-time updates on your orders, special offers, and new arrivals tailored for you.',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: const Color(0xFF64748B),
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
              await NotificationService().requestSystemPermission();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/navigation');
              }
            },
            text: t?.translate('allow_notifications') ?? 'Allow Notifications',
            height: 56,
            borderRadius: 16,
          ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () async {
                    await StorageService.instance.setNotificationHandled(true);
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
                      color: const Color(0xFF94A3B8),
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
