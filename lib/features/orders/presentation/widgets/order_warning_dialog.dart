import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:my_shop/features/orders/data/models/order_model.dart';
import 'package:my_shop/core/presentation/widgets/primary_gradient_button.dart';

class OrderWarningDialog extends StatelessWidget {
  final String message;
  final OrderModel order;
  final VoidCallback onTakeAction;

  const OrderWarningDialog({
    super.key,
    required this.message,
    required this.order,
    required this.onTakeAction,
  });

  @override
  Widget build(BuildContext context) {
    final bool isPaymentUploaded = order.status == 'AWAITING_APPROVAL';

    // Theme values
    final Color primaryColor = isPaymentUploaded ? const Color(0xFFED3973) : const Color(0xFFED3973);
    final Color gradientSecondary = isPaymentUploaded ? const Color(0xFFED3973) : const Color(0xFFC2185B);
    final Color backgroundColor = isPaymentUploaded ? const Color(0xFFF9EAEB) : Colors.white;
    final Color alertBoxColor = isPaymentUploaded ? const Color(0xFFF6D8DE) : primaryColor.withValues(alpha: 0.05);
    final Color alertBoxBorderColor = isPaymentUploaded ? const Color(0xFFE5BBC4) : primaryColor.withValues(alpha: 0.1);
    final Color pillColor = isPaymentUploaded ? const Color(0xFFF0BDC8) : primaryColor.withValues(alpha: 0.1);
    final Color textColor = const Color(0xFF1E293B);
    final IconData icon = isPaymentUploaded ? PhosphorIconsBold.exclamationMark : PhosphorIconsFill.warningCircle;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      clipBehavior: Clip.antiAlias,
      insetPadding: const EdgeInsets.all(20),
      backgroundColor: backgroundColor,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 32),
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryColor, gradientSecondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.8),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: primaryColor,
                    size: isPaymentUploaded ? 40 : 56,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'URGENT ALERT',
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text(
                  'Action Needed Immediately!',
                  style: GoogleFonts.poppins(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Alert Box for Message
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: alertBoxColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: alertBoxBorderColor),
                  ),
                  child: Column(
                    children: [
                      Text(
                        message,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: pillColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Order #${order.lastOrderNo}',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                
                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Dismiss',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: PrimaryGradientButton(
                        onPressed: onTakeAction,
                        text: 'VIEW ORDER',
                        height: 56,
                        borderRadius: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
