import 'package:flutter/material.dart';
import 'package:my_shop/core/presentation/widgets/app_dialog.dart';
import 'package:flutter/foundation.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

/// Result returned after picking an image.
class ImagePickResult {
  /// The picked file. Null if the user cancelled.
  final XFile? file;

  /// True when the user denied permission and cannot proceed.
  final bool permissionDenied;

  /// True when the user permanently denied permission (needs Settings).
  final bool permanentlyDenied;

  /// True when the picked file is too large (e.g. > 1MB).
  final bool isTooLarge;

  const ImagePickResult({
    this.file,
    this.permissionDenied = false,
    this.permanentlyDenied = false,
    this.isTooLarge = false,
  });

  /// Helper to show a SnackBar if the file is too large.
  /// Returns true if an error was shown, false otherwise.
  bool handleSizeError(BuildContext context) {
    if (isTooLarge) {
      AppDialog.showToast(context, 'Image size must be less than 1MB', isError: true);
      return true;
    }
    return false;
  }
}

/// Global service for picking images from gallery or camera.
///
/// Usage:
/// ```dart
/// final result = await ImageUploadService().pickFromGallery();
/// if (result.file != null) { /* use result.file */ }
/// ```
class ImageUploadService {
  static final ImageUploadService _instance = ImageUploadService._internal();
  factory ImageUploadService() => _instance;
  ImageUploadService._internal();

  final ImagePicker _picker = ImagePicker();

  // ── Public API ────────────────────────────────────────────────────────────

  /// Pick a single image from the device gallery.
  ///
  /// When [crop] is true (default) the user is shown a lightweight, native
  /// crop screen after picking so they can frame the image before upload.
  Future<ImagePickResult> pickFromGallery({
    double? maxWidth = 1920,
    double? maxHeight = 1920,
    int imageQuality = 85,
    bool crop = true,
    int maxFileSizeMB = 1,
  }) async {
    final granted = await _requestGalleryPermission();
    if (!granted.isGranted) {
      return ImagePickResult(
        permissionDenied: true,
        permanentlyDenied: granted.isPermanentlyDenied,
      );
    }

    return _pick(
      ImageSource.gallery,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      imageQuality: imageQuality,
      crop: crop,
      maxFileSizeMB: maxFileSizeMB,
    );
  }

  /// Capture a new image using the device camera.
  ///
  /// When [crop] is true (default) the user is shown a lightweight, native
  /// crop screen after capture so they can frame the image before upload.
  Future<ImagePickResult> pickFromCamera({
    double? maxWidth = 1920,
    double? maxHeight = 1920,
    int imageQuality = 85,
    bool crop = true,
    int maxFileSizeMB = 1,
  }) async {
    final granted = await _requestCameraPermission();
    if (!granted.isGranted) {
      return ImagePickResult(
        permissionDenied: true,
        permanentlyDenied: granted.isPermanentlyDenied,
      );
    }

    return _pick(
      ImageSource.camera,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      imageQuality: imageQuality,
      crop: crop,
      maxFileSizeMB: maxFileSizeMB,
    );
  }

  /// Returns the [File] for a given [XFile].
  File toFile(XFile xFile) => File(xFile.path);

  /// Validates if the file size is within the allowed limit (default 1MB).
  /// Returns true if valid, false if too large.
  static Future<bool> isSizeValid(XFile file, {int maxMB = 1}) async {
    final bytes = await file.length();
    return bytes <= maxMB * 1024 * 1024;
  }

  // ── Internals ─────────────────────────────────────────────────────────────

  Future<PermissionStatus> _requestGalleryPermission() async {
    if (kIsWeb) return PermissionStatus.granted;
    if (Platform.isAndroid) {
      // Android uses the system Photo Picker which does not require permissions.
      return PermissionStatus.granted;
    }
    // iOS
    return Permission.photos.request();
  }

  Future<PermissionStatus> _requestCameraPermission() async {
    if (kIsWeb) return PermissionStatus.granted;
    return Permission.camera.request();
  }



  Future<ImagePickResult> _pick(
    ImageSource source, {
    double? maxWidth,
    double? maxHeight,
    int imageQuality = 85,
    bool crop = true,
    int maxFileSizeMB = 1,
  }) async {
    try {
      final xFile = await _picker.pickImage(
        source: source,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        imageQuality: imageQuality,
      );

      // User cancelled the picker.
      if (xFile == null) return const ImagePickResult();

      XFile resultFile = xFile;
      if (crop && !kIsWeb) {
        final cropped = await _cropImage(xFile);
        // Backing out of the crop screen cancels the whole selection.
        if (cropped == null) return const ImagePickResult();
        resultFile = cropped;
      }

      final isValid = await isSizeValid(resultFile, maxMB: maxFileSizeMB);
      if (!isValid) {
        return const ImagePickResult(isTooLarge: true);
      }
      return ImagePickResult(file: resultFile);
    } catch (e) {
      debugPrint('ImageUploadService._pick error: $e');
      return const ImagePickResult();
    }
  }

  /// Opens a native crop screen for the picked [file]. Returns the cropped
  /// file, or null if the user backed out. Free-form aspect ratio so it works
  /// for avatars, banners, menu photos and payment slips alike.
  Future<XFile?> _cropImage(XFile file) async {
    try {
      final cropped = await ImageCropper().cropImage(
        sourcePath: file.path,
        compressFormat: ImageCompressFormat.jpg,
        compressQuality: 90,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Image',
            toolbarColor: Colors.black,
            toolbarWidgetColor: Colors.white,
            backgroundColor: Colors.black,
            activeControlsWidgetColor: const Color(0xFF6C63FF),
            lockAspectRatio: false,
            hideBottomControls: false,
          ),
          IOSUiSettings(
            title: 'Crop Image',
            aspectRatioLockEnabled: false,
            resetAspectRatioEnabled: true,
          ),
        ],
      );
      return cropped == null ? null : XFile(cropped.path);
    } catch (e) {
      debugPrint('ImageUploadService._cropImage error: $e');
      // If cropping fails for any reason, fall back to the original file so
      // the upload flow is never blocked by the optional crop step.
      return file;
    }
  }
}
