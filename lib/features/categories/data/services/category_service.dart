import 'package:flutter/foundation.dart';
import 'package:my_shop/core/network/api_client.dart';
import 'package:my_shop/features/menu/data/models/menu_category_model.dart';

class CategoryService {
  static const String _categoriesPath = '/api/shop/menu/categories';

  Future<List<MenuCategoryModel>?> getCategories() async {
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
    return null;
  }

  Future<bool> createCategory(Map<String, dynamic> payload) async {
    try {
      debugPrint('POST REQUEST: $_categoriesPath, Data: $payload');
      final response = await ApiClient().dio.post(
        _categoriesPath,
        data: payload,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = response.data;
        return data['success'] == true;
      }
    } catch (e) {
      debugPrint('API Error in createCategory: $e');
    }
    return false;
  }

  Future<bool> updateCategory(int categoryId, Map<String, dynamic> payload) async {
    try {
      final url = '$_categoriesPath/$categoryId';
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
      debugPrint('API Error in updateCategory: $e');
    }
    return false;
  }

  Future<bool> deleteCategory(int categoryId) async {
    try {
      final url = '$_categoriesPath/$categoryId';
      debugPrint('DELETE REQUEST: $url');
      final response = await ApiClient().dio.delete(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = response.data;
        return data['success'] == true;
      }
    } catch (e) {
      debugPrint('API Error in deleteCategory: $e');
    }
    return false;
  }

  Future<bool> reorderCategories(List<int> orderedIds) async {
    try {
      const url = '$_categoriesPath/reorder';
      final payload = {'categoryIds': orderedIds};
      debugPrint('POST REQUEST: $url, Data: $payload');
      final response = await ApiClient().dio.post(
        url,
        data: payload,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = response.data;
        return data['success'] == true;
      }
    } catch (e) {
      debugPrint('API Error in reorderCategories: $e');
    }
    return false;
  }
}
