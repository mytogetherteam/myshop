import 'package:dio/dio.dart';
import 'package:my_shop/core/config/env_config.dart';
import 'package:my_shop/core/data/services/storage_service.dart';

class ShopInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // Avoid adding X-Shop-Id for auth flow or the initial shops fetch.
    final isAuthPath = options.path.contains('/auth/');
    final isFetchShopsPath = options.path.contains('/api/shop/account/shops');
    final isGalleryPath = options.path.contains('/api/shop/menu/categories/gallery');

    if (!isAuthPath && !isFetchShopsPath && !isGalleryPath) {
      int? shopId = await StorageService.instance.getSelectedShopId();
      shopId ??= await _resolveAndPersistShopId();

      if (shopId != null && !options.headers.containsKey('X-Shop-Id')) {
        options.headers['X-Shop-Id'] = shopId.toString();
      }
    }

    handler.next(options);
  }

  Future<int?> _resolveAndPersistShopId() async {
    try {
      final token = await StorageService.instance.getToken();
      if (token == null || token.isEmpty) return null;

      final dio = Dio(BaseOptions(baseUrl: EnvConfig.apiBaseUrl));
      final response = await dio.get(
        '/api/shop/account/shops',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      final body = response.data;
      final dynamic data = body is Map<String, dynamic> ? body['data'] : null;
      if (data is List && data.isNotEmpty) {
        final first = data.first;
        if (first is Map<String, dynamic>) {
          final rawId = first['id'];
          if (rawId is int) {
            await StorageService.instance.saveSelectedShopId(rawId);
            return rawId;
          }
          if (rawId is String) {
            final parsed = int.tryParse(rawId);
            if (parsed != null) {
              await StorageService.instance.saveSelectedShopId(parsed);
              return parsed;
            }
          }
        }
      }
    } catch (_) {
      // Keep request flowing without forcing failure here.
    }
    return null;
  }
}
