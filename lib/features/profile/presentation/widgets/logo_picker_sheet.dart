import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_shop/core/presentation/widgets/gradient_widgets.dart';
import 'package:my_shop/core/localization/app_localizations.dart';

class LogoPickerSheet extends StatelessWidget {
  final VoidCallback onGallery;
  final VoidCallback onCamera;

  const LogoPickerSheet({
    super.key,
    required this.onGallery,
    required this.onCamera,
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
              t?.translate('update_shop_logo') ?? 'Update Shop Logo',
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
                Icons.photo_library_outlined,
              ),
            ),
            title: Text(
              t?.translate('choose_from_gallery') ?? 'Choose from Gallery',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
            ),
            onTap: onGallery,
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
              t?.translate('take_photo') ?? 'Take a Photo',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
            ),
            onTap: onCamera,
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
