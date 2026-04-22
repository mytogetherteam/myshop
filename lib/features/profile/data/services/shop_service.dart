import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:my_shop/core/network/api_client.dart';
import 'package:my_shop/core/network/api_helper.dart';
import '../models/shop_model.dart';

class ShopService {
  static const String _shopsPath = '/api/shop/account/shops';

  Future<List<Shop>> getShops() async {
    try {
      debugPrint('GET REQUEST: $_shopsPath');
      final response = await ApiClient().dio.get(_shopsPath);

      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        final Map<String, dynamic> data = response.data;
        if (data['success'] == true && data['data'] != null) {
          final List<dynamic> shopsJson = data['data'];
          return shopsJson.map((e) => Shop.fromJson(e)).toList();
        }
      }
    } on DioException catch (e) {
      final error = ApiHelper.handleError(e, context: 'ShopService.getShops');
      debugPrint('${error.message} - Returning Mock Data');
    } catch (e) {
      final error = ApiHelper.handleError(e, context: 'ShopService.getShops');
      debugPrint('${error.message} - Returning Mock Data');
    }
    return _getMockShops();
  }

  List<Shop> _getMockShops() {
    return [
      Shop(
        id: 1,
        name: 'Together Coffee',
        logoUrl:
            'https://images.unsplash.com/photo-1554118811-1e0d58224f24?q=80&w=200&auto=format&fit=crop',
        address: '123 Coffee St, Bangkok',
      ),
      Shop(
        id: 2,
        name: 'The Bakery',
        logoUrl:
            'https://images.unsplash.com/photo-1509440159596-0249088772ff?q=80&w=200&auto=format&fit=crop',
        address: '456 Sweet Ave, Bangkok',
      ),
    ];
  }

  Future<Shop?> getShopById(int id) async {
    try {
      final String path = '$_shopsPath/$id';
      debugPrint('GET REQUEST: $path');
      final response = await ApiClient().dio.get(path);

      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        final Map<String, dynamic> data = response.data;
        if (data['success'] == true && data['data'] != null) {
          return Shop.fromJson(data['data']);
        }
      }
    } on DioException catch (e) {
      ApiHelper.handleError(e, context: 'ShopService.getShopById');
    } catch (e) {
      ApiHelper.handleError(e, context: 'ShopService.getShopById');
    }
    return null;
  }
}
