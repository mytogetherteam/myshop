import 'package:flutter/material.dart';
import 'package:my_shop/core/localization/app_localizations.dart';
import 'package:my_shop/core/presentation/widgets/image_source_sheet.dart';

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
    return ImageSourceSheet(
      title: t?.translate('update_shop_logo') ?? 'Update Shop Logo',
      onGallery: onGallery,
      onCamera: onCamera,
    );
  }
}
