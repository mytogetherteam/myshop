import 'package:my_shop/core/utils/file_url_util.dart';

class ShopMyDay {
  final int id;
  final int shopId;
  final String imageUrl;
  final DateTime createdAt;
  final DateTime expiresAt;

  const ShopMyDay({
    required this.id,
    required this.shopId,
    required this.imageUrl,
    required this.createdAt,
    required this.expiresAt,
  });

  bool get isActive => expiresAt.isAfter(DateTime.now());

  Duration get timeRemaining {
    final remaining = expiresAt.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  factory ShopMyDay.fromJson(Map<String, dynamic> json) {
    return ShopMyDay(
      id: (json['id'] as num).toInt(),
      shopId: (json['shopId'] as num).toInt(),
      imageUrl: FileUrlUtil.resolve(json['imageUrl']) ?? '',
      createdAt: DateTime.parse(json['createdAt'].toString()).toLocal(),
      expiresAt: DateTime.parse(json['expiresAt'].toString()).toLocal(),
    );
  }
}
