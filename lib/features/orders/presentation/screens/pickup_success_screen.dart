import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_shop/core/localization/app_localizations.dart';
import 'package:my_shop/core/presentation/widgets/primary_gradient_button.dart';

class PickupSuccessScreen extends StatelessWidget {
  final String orderNo;
  final String customerName;

  const PickupSuccessScreen({
    super.key,
    required this.orderNo,
    required this.customerName,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF22C55E), width: 3),
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Color(0xFF22C55E),
                  size: 48,
                ),
              ),
              const SizedBox(height: 28),
              Text(
                t?.translate('pickup_success_title') ?? 'Pickup Complete',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                t?.translate('pickup_success_desc') ??
                    'Order MT-$orderNo for $customerName has been marked as picked up.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: const Color(0xFF64748B),
                  height: 1.5,
                ),
              ),
              const Spacer(),
              PrimaryGradientButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.pop(context, 'PICKED_UP');
                },
                text: t?.translate('done') ?? 'Done',
                height: 56,
                borderRadius: 14,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
