import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:my_shop/core/localization/app_localizations.dart';

class OrderHistoryItem extends StatelessWidget {
  final String orderId;
  final String time;
  final String status;
  final String amount;
  final Color statusColor;

  const OrderHistoryItem({
    super.key,
    required this.orderId,
    required this.time,
    required this.status,
    required this.amount,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final displayStatus = t?.translate(status.toLowerCase()) ?? status;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      orderId,
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF1E293B),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        displayStatus,
                        style: GoogleFonts.poppins(
                          color: statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  time,
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF94A3B8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            "฿ $amount",
            style: GoogleFonts.poppins(
              color: const Color(0xFF1E293B),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 4),
          const PhosphorIcon(
            PhosphorIconsRegular.caretRight,
            size: 16,
            color: Color(0xFF94A3B8),
          ),
        ],
      ),
    );
  }
}
