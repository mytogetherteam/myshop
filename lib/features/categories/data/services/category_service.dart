import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_shop/core/network/api_client.dart';
import 'package:my_shop/features/menu/data/models/menu_category_model.dart';

class CategoryService {
  static const String _categoriesPath = '/api/shop/menu/categories';
  static const String _localCategoriesKey = 'mock_categories';
  static const bool _useLocalStorage = true; // Toggle for testing

  Future<List<MenuCategoryModel>?> getCategories() async {
    if (_useLocalStorage) {
      return _getCategoriesLocal();
    }

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
    if (_useLocalStorage) {
      return _createCategoryLocal(payload);
    }

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
    if (_useLocalStorage) {
      return _updateCategoryLocal(categoryId, payload);
    }

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
    if (_useLocalStorage) {
      return _deleteCategoryLocal(categoryId);
    }

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
    if (_useLocalStorage) {
      return _reorderCategoriesLocal(orderedIds);
    }

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

  // --- Local Storage Logic ---

  Future<List<MenuCategoryModel>> _getCategoriesLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString(_localCategoriesKey);
    
    if (data == null) {
      // Initialize with dummy data
      final List<MenuCategoryModel> dummy = [
        MenuCategoryModel(
          id: 1,
          nameEn: 'Food',
          nameMm: 'အစားအစာ',
          nameTh: 'อาหาร',
          imageUrl: 'assets/images/food_3d.png',
          displayOrder: 0,
          itemCount: 15,
        ),
        MenuCategoryModel(
          id: 2,
          nameEn: 'Drinks',
          nameMm: 'သောက်စရာ',
          nameTh: 'เครื่องดื่ม',
          imageUrl: 'assets/images/drinks_3d.png',
          displayOrder: 1,
          itemCount: 24,
        ),
        MenuCategoryModel(
          id: 3,
          nameEn: 'Snacks',
          nameMm: 'မုန့်ပဲသရေစာ',
          nameTh: 'ขนมขบเคี้ยว',
          imageUrl: 'assets/images/snacks_3d.png',
          displayOrder: 2,
          itemCount: 12,
        ),
      ];
      await _saveAllLocal(dummy);
      return dummy;
    }

    final List decoded = json.decode(data);
    return decoded.map((e) => MenuCategoryModel.fromJson(e)).toList();
  }

  Future<bool> _createCategoryLocal(Map<String, dynamic> payload) async {
    final categories = await _getCategoriesLocal();
    final newId = categories.isEmpty ? 1 : categories.map((e) => e.id).reduce((a, b) => a > b ? a : b) + 1;
    
    final newCategory = MenuCategoryModel(
      id: newId,
      nameEn: payload['nameEn'],
      nameMm: payload['nameMm'],
      nameTh: payload['nameTh'],
      imageUrl: payload['imageUrl'],
      displayOrder: categories.length,
      itemCount: 0,
      updatedAt: DateTime.now(),
    );

    categories.insert(0, newCategory);
    return await _saveAllLocal(categories);
  }

  Future<bool> _updateCategoryLocal(int id, Map<String, dynamic> payload) async {
    final categories = await _getCategoriesLocal();
    final index = categories.indexWhere((e) => e.id == id);
    if (index == -1) return false;

    final existing = categories[index];
    final updated = MenuCategoryModel(
      id: id,
      nameEn: payload['nameEn'] ?? existing.nameEn,
      nameMm: payload['nameMm'] ?? existing.nameMm,
      nameTh: payload['nameTh'] ?? existing.nameTh,
      imageUrl: payload['imageUrl'] ?? existing.imageUrl,
      displayOrder: existing.displayOrder,
      itemCount: existing.itemCount,
      updatedAt: DateTime.now(),
    );

    categories.removeAt(index);
    categories.insert(0, updated);
    return await _saveAllLocal(categories);
  }

  Future<bool> _deleteCategoryLocal(int id) async {
    final categories = await _getCategoriesLocal();
    categories.removeWhere((e) => e.id == id);
    return await _saveAllLocal(categories);
  }

  Future<bool> _reorderCategoriesLocal(List<int> orderedIds) async {
    final categories = await _getCategoriesLocal();
    final List<MenuCategoryModel> reordered = [];
    
    for (var id in orderedIds) {
      final cat = categories.firstWhere((e) => e.id == id);
      reordered.add(cat);
    }

    return await _saveAllLocal(reordered);
  }

  Future<bool> _saveAllLocal(List<MenuCategoryModel> categories) async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = json.encode(categories.map((e) => e.toJson()).toList());
    return await prefs.setString(_localCategoriesKey, encoded);
  }
}
