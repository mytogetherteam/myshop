import 'package:dio/dio.dart';
import 'package:my_shop/core/network/api_client.dart';

import '../models/shop_post.dart';

class ShopPostsPageResult {
  final List<ShopPost> items;
  final int totalPages;

  const ShopPostsPageResult({required this.items, required this.totalPages});
}

class ShopPostsService {
  static const _path = '${ApiClient.apiPrefix}/posts';

  Future<ShopPostsPageResult> listOwn({int page = 1, int size = 20}) async {
    final response = await ApiClient().dio.get(
      _path,
      queryParameters: {'page': page, 'size': size},
    );
    final data = response.data;
    final payload = data is Map && data['data'] is Map
        ? Map<String, dynamic>.from(data['data'] as Map)
        : data is Map
            ? Map<String, dynamic>.from(data)
            : <String, dynamic>{};
    final content = payload['content'];
    final items = content is List
        ? content
            .whereType<Map>()
            .map((item) => ShopPost.fromJson(Map<String, dynamic>.from(item)))
            .toList()
        : <ShopPost>[];
    final totalPages = (payload['totalPages'] as num?)?.toInt() ?? 1;
    return ShopPostsPageResult(items: items, totalPages: totalPages);
  }

  Future<void> create({
    String? content,
    required List<String> mediaPaths,
  }) async {
    final caption = content?.trim() ?? '';
    final form = FormData();
    if (caption.isNotEmpty) {
      form.fields.add(MapEntry('content', caption));
    }
    for (final path in mediaPaths) {
      final name = path.split('/').last;
      final filename = name.trim().isEmpty
          ? 'media_${DateTime.now().millisecondsSinceEpoch}.jpg'
          : name;
      form.files.add(
        MapEntry(
          'media',
          await MultipartFile.fromFile(
            path,
            filename: filename,
            contentType: _contentTypeFor(filename),
          ),
        ),
      );
    }
    await ApiClient().dio.post(_path, data: form);
  }

  Future<void> delete(int id) async {
    await ApiClient().dio.delete('$_path/$id');
  }
}

/// The API rejects anything that is not `image/*` or `video/*`.
/// Camera files sometimes arrive without a type Dio can guess.
DioMediaType? _contentTypeFor(String filename) {
  final ext = filename.contains('.')
      ? filename.split('.').last.toLowerCase()
      : '';
  switch (ext) {
    case 'png':
      return DioMediaType('image', 'png');
    case 'gif':
      return DioMediaType('image', 'gif');
    case 'webp':
      return DioMediaType('image', 'webp');
    case 'heic':
      return DioMediaType('image', 'heic');
    case 'heif':
      return DioMediaType('image', 'heif');
    case 'mp4':
      return DioMediaType('video', 'mp4');
    case 'mov':
      return DioMediaType('video', 'quicktime');
    case 'm4v':
      return DioMediaType('video', 'x-m4v');
    case 'webm':
      return DioMediaType('video', 'webm');
    case 'jpg':
    case 'jpeg':
      return DioMediaType('image', 'jpeg');
    default:
      return null;
  }
}
