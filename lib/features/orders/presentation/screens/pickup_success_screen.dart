import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_shop/core/localization/app_localizations.dart';
import 'package:my_shop/core/presentation/widgets/primary_gradient_button.dart';
import 'package:my_shop/features/main_navigation/presentation/screens/main_navigation_screen.dart';

class PickupSuccessScreen extends StatelessWidget {
  final String orderNo;
  final String customerName;

  const PickupSuccessScreen({
    super.key,
    required this.orderNo,
    required this.customerName,
  });

  void _finish(BuildContext context) {
    HapticFeedback.lightImpact();
    Navigator.of(context).popUntil((route) => route.isFirst);
    OrdersTabNavigation.returnToOrdersTab?.call('PICKED_UP');
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _finish(context);
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).brightness == Brightness.dark ? Theme.of(context).cardColor : Colors.white,
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
                  child: Icon(
                    Icons.check_rounded,
                    color: Color(0xFF22C55E),
                    size: 48,
                  ),
                ),
                SizedBox(height: 28),
                Text(
                  t?.translate('pickup_success_title') ?? 'Pickup Complete',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  t?.translate('pickup_success_desc') ??
                      'Order MT-$orderNo for $customerName has been marked as picked up.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                    height: 1.5,
                  ),
                ),
                const Spacer(),
                PrimaryGradientButton(
                  onPressed: () => _finish(context),
                  text: t?.translate('done') ?? 'Done',
                  height: 56,
                  borderRadius: 14,
                ),
                SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
