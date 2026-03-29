import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
// import 'package:my_shop/core/network/api_client.dart';
import 'package:my_shop/features/menu/data/models/menu_category_model.dart';

class CategoryService {
  // static const String _categoriesPath = '/api/shop/menu/categories';

  static const String _fallbackPath = 'assets/data/fallback_menu_data.json';
  
  Future<List<MenuCategoryModel>?> getCategories() async {
    // Commenting out API call
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
    debugPrint('[CategoryService] API disabled — loading fallback data');
    return await _loadFallbackCategories('API disabled');
  }

  Future<List<MenuCategoryModel>> _loadFallbackCategories(String reason) async {
    try {
      final String jsonString = await rootBundle.loadString(_fallbackPath);
      final Map<String, dynamic> data = json.decode(jsonString);
      final List list = data['categories'] ?? [];
      return list.map((json) => MenuCategoryModel.fromJson(json)).toList();
    } catch (e) {
      debugPrint('[CategoryService] Error loading fallback categories: $e');
      return [];
    }
  }

  Future<bool> createCategory(Map<String, dynamic> payload) async {
    // Commenting out API call
    /*
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
    */
    debugPrint('[CategoryService] API disabled — createCategory simulated success');
    return true;
  }

  Future<bool> updateCategory(int categoryId, Map<String, dynamic> payload) async {
    // Commenting out API call
    /*
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
    */
    debugPrint('[CategoryService] API disabled — updateCategory simulated success');
    return true;
  }

  Future<bool> deleteCategory(int categoryId) async {
    // Commenting out API call
    /*
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
    */
    debugPrint('[CategoryService] API disabled — deleteCategory simulated success');
    return true;
  }

  Future<bool> reorderCategories(List<int> orderedIds) async {
    // Commenting out API call
    /*
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
    */
    debugPrint('[CategoryService] API disabled — reorderCategories simulated success');
    return true;
  }
}
