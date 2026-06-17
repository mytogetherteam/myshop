import 'package:flutter/material.dart';

Widget buildLocalPathImage(
  String path, {
  BoxFit fit = BoxFit.contain,
  double? width,
  double? height,
}) {
  return Image.network(
    path,
    fit: fit,
    width: width,
    height: height,
  );
}
