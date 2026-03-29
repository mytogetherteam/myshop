import 'package:flutter/foundation.dart';
// import 'package:my_shop/core/network/api_client.dart';
import '../models/menu_item_model.dart';
import '../models/menu_category_model.dart';

class MenuService {
  // static const String _categoriesPath = '/api/shop/menu/categories';
  // static const String _menuItemsPath = '/api/shop/menu/items';

  Future<List<MenuCategoryModel>?> getCategories() async {
    // Commenting out API call as requested
    /*
    try {
      debugPrint('GET REQUEST: $_categoriesPath');
      final response = await ApiClient().dio.get(_categoriesPath);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = response.data;
        if (data['success'] == true && data['data'] != null) {
          final List list = data['data'] ?? [];
          return list.map((json) => MenuCategoryModel.fromJson(json)).toList();
        }
      }
    } catch (e) {
      debugPrint('API Error in getCategories: $e');
    }
    */
    return null; // MenuRepository handles fallback when null is returned
  }

  Future<List<MenuItemModel>?> getMenuItems({int? categoryId, int page = 1, int limit = 20}) async {
    // Commenting out API call as requested
    /*
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };
      if (categoryId != null) {
        queryParams['categoryId'] = categoryId;
      }
      debugPrint('GET REQUEST: $_menuItemsPath, Params: $queryParams');
      final response = await ApiClient().dio.get(
        _menuItemsPath,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = response.data;
        if (data['success'] == true && data['data'] != null) {
          final List list = data['data'] ?? [];
          return list.map((json) => MenuItemModel.fromJson(json)).toList();
        }
      }
    } catch (e) {
      debugPrint('API Error in getMenuItems: $e');
    }
    */
    return null; // MenuRepository handles fallback when null is returned
  }

  Future<bool> createMenuItem(Map<String, dynamic> payload) async {
    // Commenting out API call as requested
    /*
    try {
      debugPrint('POST REQUEST: $_menuItemsPath, Data: $payload');
      final response = await ApiClient().dio.post(
        _menuItemsPath,
        data: payload,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = response.data;
        return data['success'] == true;
      }
    } catch (e) {
      debugPrint('API Error in createMenuItem: $e');
    }
    */
    debugPrint('[Menu] API disabled — createMenuItem simulated success');
    return true; // Simulate success
  }

  Future<bool> updateMenuItem(int itemId, Map<String, dynamic> payload) async {
    // Commenting out API call as requested
    /*
    try {
      final url = '$_menuItemsPath/$itemId';
      debugPrint('PUT REQUEST: $url, Data: $payload');
      final response = await ApiClient().dio.put(
        url,
        data: payload,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = response.data;
        return data['success'] == true;
      }
    } catch (e) {
      debugPrint('API Error in updateMenuItem: $e');
    }
    */
    debugPrint('[Menu] API disabled — updateMenuItem simulated success');
    return true; // Simulate success
  }

  Future<bool> deleteMenuItem(int itemId) async {
    // Commenting out API call as requested
    /*
    try {
      final url = '$_menuItemsPath/$itemId';
      debugPrint('DELETE REQUEST: $url');
      final response = await ApiClient().dio.delete(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = response.data;
        return data['success'] == true;
      }
    } catch (e) {
      debugPrint('API Error in deleteMenuItem: $e');
    }
    */
    debugPrint('[Menu] API disabled — deleteMenuItem simulated success');
    return true; // Simulate success
  }

  Future<bool> toggleAvailability(int itemId, bool available) async {
    // Commenting out API call as requested
    /*
    try {
      final url = '$_menuItemsPath/$itemId/availability';
      debugPrint('PUT REQUEST: $url, Query: {available: $available}');
      final response = await ApiClient().dio.put(
        url,
        queryParameters: {'available': available},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = response.data;
        return data['success'] == true;
      }
    } catch (e) {
      debugPrint('API Error in toggleAvailability: $e');
    }
    */
    debugPrint('[Menu] API disabled — toggleAvailability simulated success');
    return true; // Simulate success
  }
}
