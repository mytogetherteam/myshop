import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final BoxFit fit;

  const AppLogo({
    Key? key,
    this.size = 120,
    this.fit = BoxFit.contain,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Image.asset(
        'assets/images/app_logo.png', // Pointing to the new rebranding logo
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          // If a logo is not found, render a placeholder
          return Icon(Icons.broken_image, size: size, color: Colors.grey);
        },
      ),
    );
  }
}
