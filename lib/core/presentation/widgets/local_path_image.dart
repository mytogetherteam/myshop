import 'package:flutter/material.dart';

import 'local_path_image_io.dart'
    if (dart.library.html) 'local_path_image_web.dart' as impl;

/// Displays a local filesystem path on native, or a blob/data URL on web.
Widget localPathImage(
  String path, {
  BoxFit fit = BoxFit.contain,
  double? width,
  double? height,
}) {
  return impl.buildLocalPathImage(
    path,
    fit: fit,
    width: width,
    height: height,
  );
}
