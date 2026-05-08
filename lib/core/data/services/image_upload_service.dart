import 'package:flutter/material.dart';
import 'package:my_shop/core/presentation/widgets/app_dialog.dart';
import 'package:flutter/foundation.dart';
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
  Future<ImagePickResult> pickFromGallery({
    double? maxWidth = 1920,
    double? maxHeight = 1920,
    int imageQuality = 85,
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
    );
  }

  /// Capture a new image using the device camera.
  Future<ImagePickResult> pickFromCamera({
    double? maxWidth = 1920,
    double? maxHeight = 1920,
    int imageQuality = 85,
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
      // Android 13+ uses READ_MEDIA_IMAGES
      if (await _isAndroid13OrAbove()) {
        return Permission.photos.request();
      }
      return Permission.storage.request();
    }
    // iOS
    return Permission.photos.request();
  }

  Future<PermissionStatus> _requestCameraPermission() async {
    if (kIsWeb) return PermissionStatus.granted;
    return Permission.camera.request();
  }

  Future<bool> _isAndroid13OrAbove() async {
    if (kIsWeb) return false;
    if (!Platform.isAndroid) return false;
    try {
      // AndroidSdkVersion 33 == Android 13
      final info = await _getAndroidSdkVersion();
      return info >= 33;
    } catch (_) {
      // Fallback: use READ_MEDIA_IMAGES (safe default)
      return true;
    }
  }

  Future<int> _getAndroidSdkVersion() async {
    if (kIsWeb) return 0;
    try {
      final result = await Process.run('getprop', ['ro.build.version.sdk']);
      return int.tryParse(result.stdout.toString().trim()) ?? 33;
    } catch (_) {
      return 33;
    }
  }

  Future<ImagePickResult> _pick(
    ImageSource source, {
    double? maxWidth,
    double? maxHeight,
    int imageQuality = 85,
  }) async {
    try {
      final xFile = await _picker.pickImage(
        source: source,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        imageQuality: imageQuality,
      );
      
      if (xFile != null) {
        final isValid = await isSizeValid(xFile);
        if (!isValid) {
          return const ImagePickResult(isTooLarge: true);
        }
      }
      return ImagePickResult(file: xFile);
    } catch (e) {
      debugPrint('ImageUploadService._pick error: $e');
      return const ImagePickResult();
    }
  }
}
