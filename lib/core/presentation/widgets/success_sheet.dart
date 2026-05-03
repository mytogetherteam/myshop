import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SuccessSheet extends StatefulWidget {
  final VoidCallback? onDone;
  const SuccessSheet({super.key, this.onDone});

  @override
  State<SuccessSheet> createState() => _SuccessSheetState();
}

class _SuccessSheetState extends State<SuccessSheet> {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 32),
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFF22C55E),
              width: 3,
            ),
          ),
          child: const Center(
            child: Icon(
              Icons.check_rounded,
              color: Color(0xFF22C55E),
              size: 40,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Successfully requested',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'Your request has been submitted successfully. We\u2019ll notify you once it\u2019s approved by the admin.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: const Color(0xFF64748B),
              height: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () {
              if (widget.onDone != null) {
                widget.onDone!();
              } else {
                // Default behavior: close this sheet AND the parent screen
                // Important: pass true to signal that a refresh is needed
                final nav = Navigator.of(context);
                nav.pop(); // Close sheet
                nav.pop(true); // Go back with refresh signal
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFED3973),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Text(
              'Got it',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
