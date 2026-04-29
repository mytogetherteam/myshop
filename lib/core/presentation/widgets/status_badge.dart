import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class StatusBadge extends StatelessWidget {
  final String? status;

  const StatusBadge({super.key, this.status});

  @override
  Widget build(BuildContext context) {
    if (status == null || status == 'APPROVED') {
      return const SizedBox.shrink();
    }

    Color bgColor;
    Color textColor;
    String label;

    switch (status) {
      case 'PENDING':
      case 'PENDING_APPROVAL':
        bgColor = const Color(0xFFFEF9C3); // Light yellow
        textColor = const Color(0xFFCA8A04); // Dark yellow
        label = 'Waiting for approval';
        break;
      case 'REJECTED':
        bgColor = const Color(0xFFFEF2F2); // Light red
        textColor = const Color(0xFFEF4444); // Red
        label = 'Rejected';
        break;
      default:
        return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}
