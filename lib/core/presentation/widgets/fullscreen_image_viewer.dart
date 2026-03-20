import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class FullscreenImageViewer extends StatelessWidget {
  final String? imageUrl;
  final String? imagePath;
  final String title;

  const FullscreenImageViewer({
    super.key,
    this.imageUrl,
    this.imagePath,
    this.title = 'View Image',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          title,
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: _buildImage(),
        ),
      ),
    );
  }

  Widget _buildImage() {
    if (imagePath != null) {
      return kIsWeb ? Image.network(imagePath!) : Image.file(File(imagePath!));
    } else if (imageUrl != null && imageUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: imageUrl!,
        placeholder: (_, _) => const Center(child: CircularProgressIndicator(color: Colors.white)),
        errorWidget: (_, _, _) => const Icon(Icons.error, color: Colors.white),
      );
    }
    return const Icon(Icons.image, color: Colors.white, size: 100);
  }
}
