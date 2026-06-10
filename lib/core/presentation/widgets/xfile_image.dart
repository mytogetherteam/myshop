import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'xfile_image_io.dart' if (dart.library.html) 'xfile_image_web.dart' as impl;

/// Displays a locally picked [XFile] on web and native platforms.
Widget xFileImage(
  XFile file, {
  BoxFit fit = BoxFit.cover,
  double? width,
  double? height,
}) {
  return impl.buildXFileImage(
    file,
    fit: fit,
    width: width,
    height: height,
  );
}
