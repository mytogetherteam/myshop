import 'package:dio/dio.dart';
import 'package:my_shop/core/data/services/storage_service.dart';

class ShopInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // Avoid adding X-Shop-Id for auth flow or the initial shops fetch.
    final isAuthPath = options.path.contains('/auth/');
    final isFetchShopsPath = options.path.contains('/api/shop/account/shops');
    final isGalleryPath = options.path.contains('/api/shop/menu/categories/gallery');

    if (!isAuthPath && !isFetchShopsPath && !isGalleryPath) {
      final shopId = await StorageService.instance.getSelectedShopId();
      if (shopId != null && !options.headers.containsKey('X-Shop-Id')) {
        options.headers['X-Shop-Id'] = shopId.toString();
      }
    }
    
    handler.next(options);
  }
}
