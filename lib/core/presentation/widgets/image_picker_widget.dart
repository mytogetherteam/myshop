import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:my_shop/core/data/services/image_upload_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:my_shop/core/presentation/widgets/app_dialog.dart';

/// Shape of the image picker preview area.
enum ImagePickerShape {
  /// Circular — great for avatars and profile photos.
  circle,

  /// Rectangular — great for product/menu images and banners.
  rectangle,
}

/// A plug-and-play image picker widget.
///
/// Displays a preview of either a remote [imageUrl] or a locally picked file.
/// Tapping the widget opens a bottom sheet with **Gallery** and **Camera**
/// options. When the user picks an image, [onImageSelected] is called with
/// the chosen [XFile].
///
/// ### Minimal usage (rectangle)
/// ```dart
/// ImagePickerWidget(
///   onImageSelected: (xFile) {
///     setState(() => _pickedFile = xFile);
///   },
/// )
/// ```
///
/// ### Circle avatar
/// ```dart
/// ImagePickerWidget(
///   imageUrl: user.profileUrl,
///   shape: ImagePickerShape.circle,
///   width: 100,
///   height: 100,
///   onImageSelected: (xFile) { ... },
/// )
/// ```
class ImagePickerWidget extends StatefulWidget {
  /// Existing remote image to display before a new one is picked.
  final String? imageUrl;

  /// An already-picked local file to display (e.g. coming from parent state).
  final XFile? pickedFile;

  /// Called whenever the user successfully picks an image.
  final ValueChanged<XFile> onImageSelected;

  /// Shape of the preview container.
  final ImagePickerShape shape;

  /// Width of the preview container. Ignored when [shape] is [ImagePickerShape.circle]
  /// (use [size] instead via [width] == [height]).
  final double width;

  /// Height of the preview container.
  final double height;

  /// Corner radius for [ImagePickerShape.rectangle]. Defaults to 12.
  final double borderRadius;

  /// Border color of the container. Defaults to theme's outline color.
  final Color? borderColor;

  /// Whether to show a camera-icon badge on the bottom-right. Defaults to true.
  final bool showEditBadge;

  /// Custom placeholder widget shown when no image is set.
  final Widget? placeholder;

  /// Max width to compress the image to before returning it. Default 1920.
  final double? maxWidth;

  /// Max height to compress the image to before returning it. Default 1920.
  final double? maxHeight;

  /// JPEG compression quality (0–100). Default 85.
  final int imageQuality;

  const ImagePickerWidget({
    super.key,
    this.imageUrl,
    this.pickedFile,
    required this.onImageSelected,
    this.shape = ImagePickerShape.rectangle,
    this.width = 120,
    this.height = 120,
    this.borderRadius = 12,
    this.borderColor,
    this.showEditBadge = true,
    this.placeholder,
    this.maxWidth = 1920,
    this.maxHeight = 1920,
    this.imageQuality = 85,
  });

  @override
  State<ImagePickerWidget> createState() => _ImagePickerWidgetState();
}

class _ImagePickerWidgetState extends State<ImagePickerWidget> {
  XFile? _localFile;

  @override
  void initState() {
    super.initState();
    _localFile = widget.pickedFile;
  }

  @override
  void didUpdateWidget(covariant ImagePickerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pickedFile != oldWidget.pickedFile) {
      setState(() => _localFile = widget.pickedFile);
    }
  }

  // ── Pick flow ─────────────────────────────────────────────────────────────

  Future<void> _showPickerSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _PickerSheet(onTap: _pickImage),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    if (!mounted) return;
    Navigator.of(context).pop(); // close sheet first

    final service = ImageUploadService();
    final result = source == ImageSource.gallery
        ? await service.pickFromGallery(
            maxWidth: widget.maxWidth,
            maxHeight: widget.maxHeight,
            imageQuality: widget.imageQuality,
          )
        : await service.pickFromCamera(
            maxWidth: widget.maxWidth,
            maxHeight: widget.maxHeight,
            imageQuality: widget.imageQuality,
          );

    if (!mounted) return;

    if (result.permanentlyDenied) {
      _showPermissionDialog();
      return;
    }

    if (result.permissionDenied) {
      AppDialog.showToast(context, 'Permission denied. Please allow access in Settings.', isError: true);
      return;
    }
    
    if (result.isTooLarge) {
      AppDialog.showToast(context, 'Image size must be less than 1MB', isError: true);
      return;
    }

    if (result.file != null) {
      setState(() => _localFile = result.file);
      widget.onImageSelected(result.file!);
    }
  }

  void _showPermissionDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Image.asset('assets/images/app_logo.png', width: 24, height: 24),
            const SizedBox(width: 8),
            Text('Permission Required', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
          ],
        ),
        content: const Text(
          'Camera and photo library access is required to upload images. '
          'Please enable it in your device Settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  // ── Image content ─────────────────────────────────────────────────────────

  Widget _buildImage() {
    final borderRadius = widget.shape == ImagePickerShape.circle
        ? BorderRadius.circular(widget.width / 2)
        : BorderRadius.circular(widget.borderRadius);

    Widget image;

    if (_localFile != null) {
      image = Image.file(
        File(_localFile!.path),
        fit: BoxFit.cover,
        width: widget.width,
        height: widget.height,
      );
    } else if (widget.imageUrl != null && widget.imageUrl!.isNotEmpty) {
      image = CachedNetworkImage(
        imageUrl: widget.imageUrl!,
        fit: BoxFit.cover,
        width: widget.width,
        height: widget.height,
        placeholder: (_, _) => _buildPlaceholder(),
        errorWidget: (_, _, _) => _buildPlaceholder(),
      );
    } else {
      image = _buildPlaceholder();
    }

    return ClipRRect(borderRadius: borderRadius, child: image);
  }

  Widget _buildPlaceholder() {
    if (widget.placeholder != null) return widget.placeholder!;
    return Container(
      width: widget.width,
      height: widget.height,
      color: Colors.grey.shade100,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_a_photo_outlined, size: 32, color: Colors.grey.shade400),
          const SizedBox(height: 6),
          Text(
            'Add Photo',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildEditBadge() {
    return Positioned(
      bottom: 0,
      right: 0,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final borderColor = widget.borderColor ??
        Theme.of(context).colorScheme.outlineVariant;

    final isCircle = widget.shape == ImagePickerShape.circle;
    final decoration = isCircle
        ? BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: borderColor, width: 1.5),
          )
        : BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: Border.all(color: borderColor, width: 1.5),
          );

    return GestureDetector(
      onTap: _showPickerSheet,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: widget.width,
            height: widget.height,
            decoration: decoration,
            clipBehavior: Clip.hardEdge,
            child: _buildImage(),
          ),
          if (widget.showEditBadge) _buildEditBadge(),
        ],
      ),
    );
  }
}

// ── Bottom Sheet ─────────────────────────────────────────────────────────────

class _PickerSheet extends StatelessWidget {
  final void Function(ImageSource) onTap;

  const _PickerSheet({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text(
              'Select Image',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          const Divider(height: 1),

          _SheetOption(
            icon: Icons.photo_library_outlined,
            label: 'Choose from Gallery',
            onTap: () => onTap(ImageSource.gallery),
          ),

          const Divider(height: 1, indent: 56),

          _SheetOption(
            icon: Icons.camera_alt_outlined,
            label: 'Take a Photo',
            onTap: () => onTap(ImageSource.camera),
          ),

          const SizedBox(height: 8),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SheetOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon, color: theme.colorScheme.primary),
      title: Text(label, style: theme.textTheme.bodyLarge),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
    );
  }
}
