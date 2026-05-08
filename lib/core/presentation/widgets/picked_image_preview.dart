import 'package:flutter/widgets.dart';
import 'package:image_picker/image_picker.dart';
import 'picked_image_preview_io.dart'
    if (dart.library.html) 'picked_image_preview_web.dart' as impl;

Widget buildPickedImagePreview(
  XFile file, {
  double? width,
  double? height,
  BoxFit fit = BoxFit.cover,
}) {
  return impl.buildPickedImagePreview(
    file,
    width: width,
    height: height,
    fit: fit,
  );
}
