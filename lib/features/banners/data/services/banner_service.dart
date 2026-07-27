import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:my_shop/core/network/api_client.dart';
import 'package:my_shop/features/banners/data/models/banner_image_dto.dart';

class BannerService {
  static final BannerService instance = BannerService._();
  BannerService._();

  /// Backend: GET /api/shop/banners?position=Ads|Promotions|Order|Splash
  Future<List<BannerImageDto>> getBanners({String? position}) async {
    try {
      final response = await ApiClient().dio.get(
        '${ApiClient.apiPrefix}/banners',
        queryParameters: position != null ? {'position': position} : null,
        options: Options(
          // Splash/Order must not stick empty responses in cache.
          extra: const {'skip_cache': true},
        ),
      );

      if (response.statusCode != 200) return const [];

      final raw = response.data;
      final List<dynamic> data = raw is Map
          ? (raw['data'] as List<dynamic>? ?? const [])
          : (raw is List ? raw : const []);

      final banners = data
          .whereType<Map>()
          .map((e) => BannerImageDto.fromJson(Map<String, dynamic>.from(e)))
          .where((b) => b.imageUrl.isNotEmpty)
          .toList();

      banners.sort((a, b) {
        final byOrder = a.displayOrder.compareTo(b.displayOrder);
        return byOrder != 0 ? byOrder : a.id.compareTo(b.id);
      });
      return banners;
    } catch (e) {
      debugPrint('[BannerService] getBanners failed: $e');
      rethrow;
    }
  }
}
