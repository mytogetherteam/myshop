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
      
      // Initialize with expanded list for search demonstration
      final List<MenuCategoryModel> dummy = [
        MenuCategoryModel(id: 1, nameEn: 'Appetizer & Toast', nameMm: 'အမြည်းနှင့် တိုစ်', nameTh: 'อาหารว่างและขนมปังปิ้ง', itemCount: 0),
        MenuCategoryModel(id: 2, nameEn: 'Salad', nameMm: 'သုပ်/အသုပ်', nameTh: 'สลัด', itemCount: 0),
        MenuCategoryModel(id: 3, nameEn: 'BBQ', nameMm: 'ကင်/အကင်', nameTh: 'บาร์บีคิว', itemCount: 0),
        MenuCategoryModel(id: 4, nameEn: 'Fried', nameMm: 'ကြော်/အကြော်', nameTh: 'ของทอด', itemCount: 0),
        MenuCategoryModel(id: 5, nameEn: 'Roti & Nann', nameMm: 'ရိုတီနှင့် နံပြား', nameTh: 'โรตีและนาน', itemCount: 0),
        MenuCategoryModel(id: 6, nameEn: 'Noodle', nameMm: 'ခေါက်ဆွဲ', nameTh: 'ก๋วยเตี๋ยว', itemCount: 0),
        MenuCategoryModel(id: 7, nameEn: 'Salad Menu', nameMm: 'အသုပ်မျိုးစုံ', nameTh: 'เมนูสลัด', itemCount: 0),
        MenuCategoryModel(id: 8, nameEn: 'Signature Foods', nameMm: 'အထူးဟင်းလျာများ', nameTh: 'อาหารซิกเนเจอร์', itemCount: 0),
        MenuCategoryModel(id: 9, nameEn: 'Desserts', nameMm: 'အချိုပွဲ', nameTh: 'ของหวาน', itemCount: 0),
        MenuCategoryModel(id: 10, nameEn: 'Drinks', nameMm: 'ဖျော်ရည်', nameTh: 'เครื่องดื่ม', itemCount: 0),
        MenuCategoryModel(id: 11, nameEn: 'Rice Menu', nameMm: 'ထမင်းဟင်းများ', nameTh: 'เมนูข้าว', itemCount: 0),
        MenuCategoryModel(id: 12, nameEn: 'Snacks', nameMm: 'မုန့်မျိုးစုံ', nameTh: 'อาหารว่าง', itemCount: 0),
      ];
      await SharedPreferences.getInstance().then((p) => p.setString(_localCategoriesKey, json.encode(dummy.map((e) => e.toJson()).toList())));
      return dummy;
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
          imageUrl: 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?q=80&w=300&auto=format&fit=crop',
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

    items.add(newItem);
    return await _saveAllLocal(items);
  }

  Future<bool> _updateMenuItemLocal(int id, Map<String, dynamic> payload) async {
    final items = await _getMenuItemsLocal(null);
    final index = items.indexWhere((e) => e.id == id);
    if (index == -1) return false;

    final existing = items[index].toJson();
    final updatedMap = {...existing, ...payload};
    items[index] = MenuItemModel.fromJson(updatedMap);
    
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
