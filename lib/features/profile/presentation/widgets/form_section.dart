import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FormSection extends StatelessWidget {
  final String label;
  final Widget child;
  final EdgeInsets? padding;
  final bool required;

  const FormSection({
    super.key,
    required this.label,
    required this.child,
    this.padding,
    this.required = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: label,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF475569),
                  ),
                ),
                if (required)
                  const TextSpan(
                    text: ' *',
                    style: TextStyle(
                      color: Color(0xFFED3973),
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
