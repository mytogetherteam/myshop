import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_shop/core/network/api_client.dart';
import '../models/menu_item_model.dart';
import '../models/menu_category_model.dart';

class MenuService {
  static const String _categoriesPath = '/api/shop/menu/categories';
  static const String _menuItemsPath = '/api/shop/menu/items';
  static const String _localMenuItemsKey = 'mock_menu_items';
  static const String _localCategoriesKey = 'mock_categories';
  static const bool _useLocalStorage = true; // Toggle for testing

  Future<List<MenuCategoryModel>?> getCategories() async {
    if (_useLocalStorage) {
      final prefs = await SharedPreferences.getInstance();
      final String? data = prefs.getString(_localCategoriesKey);
      
      if (data != null) {
        final List decoded = json.decode(data);
        return decoded.map((e) => MenuCategoryModel.fromJson(e)).toList();
      }
    }

    // Default mock data if local storage is empty
    final List<MenuCategoryModel> mockCategories = [
      MenuCategoryModel(id: 828,  nameEn: 'Signature Menu',      nameMm: 'Signature Menu',      nameTh: null, itemCount: 0, updatedAt: DateTime.now()),
      MenuCategoryModel(id: 829,  nameEn: 'Drinks Menu',         nameMm: 'Drinks Menu',         nameTh: null, itemCount: 0, updatedAt: DateTime.now().subtract(const Duration(minutes: 1))),
      MenuCategoryModel(id: 830,  nameEn: 'Desserts Menu',       nameMm: 'Desserts Menu',       nameTh: null, itemCount: 0, updatedAt: DateTime.now().subtract(const Duration(minutes: 2))),
      MenuCategoryModel(id: 831,  nameEn: 'Traditional Menu',    nameMm: 'Traditional Menu',    nameTh: null, itemCount: 0, updatedAt: DateTime.now().subtract(const Duration(minutes: 3))),
      MenuCategoryModel(id: 1055, nameEn: 'Snack & Apptizer',   nameMm: 'Snack & Apptizer',   nameTh: null, itemCount: 0, updatedAt: DateTime.now().subtract(const Duration(minutes: 5))),
      MenuCategoryModel(id: 862,  nameEn: 'Dish Menu',           nameMm: 'Dish Menu',           nameTh: null, itemCount: 0, updatedAt: DateTime.now().subtract(const Duration(minutes: 10))),
      MenuCategoryModel(id: 863,  nameEn: 'Fried Menu',          nameMm: 'Fried Menu',          nameTh: null, itemCount: 0, updatedAt: DateTime.now().subtract(const Duration(minutes: 15))),
      MenuCategoryModel(id: 864,  nameEn: 'Grilled Fish',        nameMm: 'Grilled Fish',        nameTh: null, itemCount: 0, updatedAt: DateTime.now().subtract(const Duration(minutes: 20))),
      MenuCategoryModel(id: 865,  nameEn: 'BBQ Menu',            nameMm: 'BBQ Menu',            nameTh: null, itemCount: 0, updatedAt: DateTime.now().subtract(const Duration(minutes: 25))),
      MenuCategoryModel(id: 1056, nameEn: 'Rice & Combo Meals', nameMm: 'Rice & Combo Meals', nameTh: null, itemCount: 0, updatedAt: DateTime.now().subtract(const Duration(minutes: 30))),
      MenuCategoryModel(id: 1057, nameEn: 'New Menu',            nameMm: 'New Menu',            nameTh: null, itemCount: 0, updatedAt: DateTime.now().subtract(const Duration(minutes: 40))),
      MenuCategoryModel(id: 866,  nameEn: 'Pork Stick',          nameMm: 'Pork Stick',          nameTh: null, itemCount: 0, updatedAt: DateTime.now().subtract(const Duration(hours: 1))),
      MenuCategoryModel(id: 867,  nameEn: 'Beverage',            nameMm: 'Beverage',            nameTh: null, itemCount: 0, updatedAt: DateTime.now().subtract(const Duration(hours: 2))),
      MenuCategoryModel(id: 868,  nameEn: 'Breakfast Menu',      nameMm: 'Breakfast Menu',      nameTh: null, itemCount: 0, updatedAt: DateTime.now().subtract(const Duration(hours: 3))),
      MenuCategoryModel(id: 869,  nameEn: 'Rice Menu',           nameMm: 'Rice Menu',           nameTh: null, itemCount: 0, updatedAt: DateTime.now().subtract(const Duration(hours: 4))),
      MenuCategoryModel(id: 841,  nameEn: 'Rice',                nameMm: 'Rice',                nameTh: null, itemCount: 0, updatedAt: DateTime.now().subtract(const Duration(hours: 5))),
      MenuCategoryModel(id: 949,  nameEn: 'Salad',               nameMm: 'Salad',               nameTh: null, itemCount: 0, updatedAt: DateTime.now().subtract(const Duration(hours: 6))),
      MenuCategoryModel(id: 950,  nameEn: 'Dishes',              nameMm: 'Dishes',              nameTh: null, itemCount: 0, updatedAt: DateTime.now().subtract(const Duration(hours: 7))),
      MenuCategoryModel(id: 842,  nameEn: 'Dishes',              nameMm: 'Dishes',              nameTh: null, itemCount: 0, updatedAt: DateTime.now().subtract(const Duration(hours: 8))),
      MenuCategoryModel(id: 845,  nameEn: 'Steamed RIce',        nameMm: 'Steamed RIce',        nameTh: null, itemCount: 0, updatedAt: DateTime.now().subtract(const Duration(hours: 9))),
      MenuCategoryModel(id: 9999, nameEn: 'Other',               nameMm: 'Other',               nameTh: null, itemCount: 0, updatedAt: DateTime.now().subtract(const Duration(hours: 10))),
    ];
    return mockCategories;
  }

  Future<List<Map<String, dynamic>>?> getTags() async {
    // Standard mock tags as requested
    return [
      {'id': 1, 'name': 'Spicy', 'nameEn': 'Spicy'},
      {'id': 2, 'name': 'Best Seller', 'nameEn': 'Best Seller'},
      {'id': 3, 'name': 'New', 'nameEn': 'New'},
      {'id': 4, 'name': 'Chef\'s Choice', 'nameEn': 'Chef\'s Choice'},
      {'id': 5, 'name': 'Healthy', 'nameEn': 'Healthy'},
      {'id': 6, 'name': 'Limited Time', 'nameEn': 'Limited Time'},
    ];
  }

  Future<List<MenuItemModel>?> getMenuItems({int? categoryId, int page = 1, int limit = 20}) async {
    if (_useLocalStorage) {
      return _getMenuItemsLocal(categoryId);
    }

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
    return null;
  }

  Future<bool> createMenuItem(Map<String, dynamic> payload) async {
    if (_useLocalStorage) {
      return _createMenuItemLocal(payload);
    }

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
    return false;
  }

  Future<bool> updateMenuItem(int itemId, Map<String, dynamic> payload) async {
    if (_useLocalStorage) {
      return _updateMenuItemLocal(itemId, payload);
    }

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
    return false;
  }

  Future<bool> deleteMenuItem(int itemId) async {
    if (_useLocalStorage) {
      return _deleteMenuItemLocal(itemId);
    }

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
    return false;
  }

  Future<bool> toggleAvailability(int itemId, bool available) async {
    if (_useLocalStorage) {
      return _updateMenuItemLocal(itemId, {'isAvailable': available});
    }

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
    return false;
  }

  // --- Local Storage Logic ---

  Future<List<MenuItemModel>> _getMenuItemsLocal(int? categoryId) async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString(_localMenuItemsKey);

    if (data == null) {
      // Initialize with dummy data
      final List<MenuItemModel> dummy = [
        MenuItemModel(
          id: 1,
          categoryId: 1,
          nameEn: 'Zinger Burger',
          nameMm: 'ဇင်ဂါ ဘာဂါ',
          nameTh: 'ซิงเกอร์เบอร์เกอร์',
          price: 120.0,
          imageUrl: 'https://images.unsplash.com/photo-1513104890138-7c749659a591?q=80&w=300&auto=format&fit=crop',
          isRecommended: true,
          isPopular: true,
          descriptionEn: 'Crispy spicy chicken burger with fresh lettuce.',
          mealTypes: ['LUNCH', 'DINNER'],
        ),
        MenuItemModel(
          id: 2,
          categoryId: 2,
          nameEn: 'Iced Thai Tea',
          nameMm: 'ထိုင်းလက်ဖက်ရည်အေး',
          nameTh: 'ชาไทยเย็น',
          price: 45.0,
          imageUrl: 'https://images.unsplash.com/photo-1558857563-b371f30bb673?q=80&w=300&auto=format&fit=crop',
          isAvailable: true,
          descriptionEn: 'Authentic Thai tea with condensed milk.',
          mealTypes: ['BREAKFAST', 'LUNCH', 'DINNER'],
        ),
      ];
      await _saveAllLocal(dummy);
      return categoryId == null ? dummy : dummy.where((e) => e.categoryId == categoryId).toList();
    }

    final List decoded = json.decode(data);
    final list = decoded.map((e) => MenuItemModel.fromJson(e)).toList();
    return categoryId == null ? list : list.where((e) => e.categoryId == categoryId).toList();
  }

  Future<bool> _createMenuItemLocal(Map<String, dynamic> payload) async {
    final items = await _getMenuItemsLocal(null);
    final newId = items.isEmpty ? 1 : items.map((e) => e.id).reduce((a, b) => a > b ? a : b) + 1;
    
    final newItem = MenuItemModel.fromJson({
      ...payload,
      'id': newId,
    });

    items.insert(0, newItem);
    return await _saveAllLocal(items);
  }

  Future<bool> _updateMenuItemLocal(int id, Map<String, dynamic> payload) async {
    final items = await _getMenuItemsLocal(null);
    final index = items.indexWhere((e) => e.id == id);
    if (index == -1) return false;

    final existing = items[index].toJson();
    final updatedMap = {...existing, ...payload};
    final updatedItem = MenuItemModel.fromJson(updatedMap);
    items.removeAt(index);
    items.insert(0, updatedItem);
    
    return await _saveAllLocal(items);
  }

  Future<bool> _deleteMenuItemLocal(int id) async {
    final items = await _getMenuItemsLocal(null);
    items.removeWhere((e) => e.id == id);
    return await _saveAllLocal(items);
  }

  Future<bool> _saveAllLocal(List<MenuItemModel> items) async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = json.encode(items.map((e) => e.toJson()).toList());
    return await prefs.setString(_localMenuItemsKey, encoded);
  }
}
