import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

/// Builds a [MultipartFile] from an [XFile] on web and native platforms.
Future<MultipartFile> multipartFileFromXFile(XFile file) async {
  return MultipartFile.fromBytes(
    await file.readAsBytes(),
    filename: file.name.isNotEmpty ? file.name : 'image.jpg',
  );
}
