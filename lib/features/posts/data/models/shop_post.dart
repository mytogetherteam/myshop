enum ShopPostMediaType { image, video }

class ShopPostMedia {
  final int id;
  final ShopPostMediaType type;
  final String url;
  final String? thumbnailUrl;

  const ShopPostMedia({
    required this.id,
    required this.type,
    required this.url,
    this.thumbnailUrl,
  });

  bool get isVideo => type == ShopPostMediaType.video;

  String get previewUrl {
    if (isVideo) {
      final thumb = thumbnailUrl?.trim() ?? '';
      if (thumb.isNotEmpty) return thumb;
    }
    return url;
  }

  factory ShopPostMedia.fromJson(Map<String, dynamic> json) {
    final typeRaw = (json['type']?.toString() ?? 'IMAGE').toUpperCase();
    return ShopPostMedia(
      id: (json['id'] as num?)?.toInt() ?? 0,
      type: typeRaw == 'VIDEO'
          ? ShopPostMediaType.video
          : ShopPostMediaType.image,
      url: json['url']?.toString() ?? '',
      thumbnailUrl: json['thumbnailUrl']?.toString(),
    );
  }
}

class ShopPost {
  final int id;
  final String? content;
  final bool isActive;
  final DateTime createdAt;
  final List<ShopPostMedia> media;

  const ShopPost({
    required this.id,
    required this.content,
    required this.isActive,
    required this.createdAt,
    required this.media,
  });

  ShopPostMedia? get primary => media.isEmpty ? null : media.first;

  bool get hasVideo => media.any((item) => item.isVideo);

  factory ShopPost.fromJson(Map<String, dynamic> json) {
    final raw = json['media'];
    final media = raw is List
        ? raw
            .whereType<Map>()
            .map((item) =>
                ShopPostMedia.fromJson(Map<String, dynamic>.from(item)))
            .toList()
        : <ShopPostMedia>[];
    return ShopPost(
      id: (json['id'] as num).toInt(),
      content: json['content']?.toString(),
      isActive: json['isActive'] != false,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      media: media,
    );
  }
}
