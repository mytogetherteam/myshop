import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_shop/core/presentation/widgets/gradient_widgets.dart';
import 'package:my_shop/core/localization/app_localizations.dart';

class ImageActionSheet extends StatelessWidget {
  final String title;
  final VoidCallback onView;
  final VoidCallback onChange;

  const ImageActionSheet({
    super.key,
    required this.title,
    required this.onView,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Text(
              title,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 17,
                color: const Color(0xFF1E293B),
              ),
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const GradientWidget(
              child: Icon(
                Icons.visibility_outlined,
              ),
            ),
            title: Text(
              t?.translate('view_image') ?? 'View Image',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
            ),
            onTap: onView,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 4,
            ),
          ),
          const Divider(height: 1, indent: 64),
          ListTile(
            leading: const GradientWidget(
              child: Icon(
                Icons.camera_alt_outlined,
              ),
            ),
            title: Text(
              t?.translate('change_image') ?? 'Change Image',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
            ),
            onTap: onChange,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 4,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  t?.translate('cancel') ?? 'Cancel',
                  style: GoogleFonts.poppins(color: const Color(0xFF64748B)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
