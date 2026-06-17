import 'dart:io';

import 'package:flutter/material.dart';

Widget buildLocalPathImage(
  String path, {
  BoxFit fit = BoxFit.contain,
  double? width,
  double? height,
}) {
  return Image.file(
    File(path),
    fit: fit,
    width: width,
    height: height,
  );
}
