import 'package:flutter/widgets.dart';
import 'package:image_picker/image_picker.dart';

Widget buildPickedImagePreview(
  XFile file, {
  double? width,
  double? height,
  BoxFit fit = BoxFit.cover,
}) {
  return Image.network(
    file.path,
    width: width,
    height: height,
    fit: fit,
  );
}
