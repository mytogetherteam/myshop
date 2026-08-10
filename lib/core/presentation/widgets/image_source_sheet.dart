import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_shop/core/localization/app_localizations.dart';
import 'package:my_shop/core/presentation/widgets/gradient_widgets.dart';

/// Shared gallery/camera picker matching profile image sheets.
class ImageSourceSheet extends StatelessWidget {
  final String title;
  final VoidCallback onGallery;
  final VoidCallback onCamera;

  const ImageSourceSheet({
    super.key,
    required this.title,
    required this.onGallery,
    required this.onCamera,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final cancelColor = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFFCBD5E1)
        : const Color(0xFF64748B);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      child: Material(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).dividerColor,
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
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const GradientWidget(
                child: Icon(Icons.photo_library_outlined),
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
                child: Icon(Icons.camera_alt_outlined),
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
                    style: GoogleFonts.poppins(color: cancelColor),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
