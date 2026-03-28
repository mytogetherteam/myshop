import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/menu_item_model.dart';
import '../models/menu_category_model.dart';
import '../services/menu_service.dart';

class MenuRepository {
  final MenuService _menuService = MenuService();
  static const String _fallbackPath = 'assets/data/fallback_menu_data.json';

  Future<List<MenuCategoryModel>> getCategories() async {
    try {
      final categories = await _menuService.getCategories();
      if (categories == null || categories.isEmpty) {
        return await _loadFallbackCategories(categories == null ? 'API error (returned null)' : 'API returned empty categories');
      }
      return categories;
    } catch (e) {
      return await _loadFallbackCategories('Repository exception: $e');
    }
  }

  Future<List<MenuItemModel>> getMenuItems({int? categoryId, int page = 1, int limit = 20}) async {
    try {
      final items = await _menuService.getMenuItems(
        categoryId: categoryId,
        page: page,
        limit: limit,
      );
      if (items == null || items.isEmpty) {
        return await _loadFallbackItems(
          items == null ? 'API error (returned null)' : 'API returned empty items',
          page: page,
          limit: limit,
          categoryId: categoryId,
        );
      }
      return items;
    } catch (e) {
      return await _loadFallbackItems(
        'Repository exception: $e',
        page: page,
        limit: limit,
        categoryId: categoryId,
      );
    }
  }

  Future<List<MenuCategoryModel>> _loadFallbackCategories(String reason) async {
    debugPrint('[Menu] Using fallback data — reason: $reason');
    try {
      final String jsonString = await rootBundle.loadString(_fallbackPath);
      final Map<String, dynamic> data = json.decode(jsonString);
      final List list = data['categories'] ?? [];
      return list.map((json) => MenuCategoryModel.fromJson(json)).toList();
    } catch (e) {
      debugPrint('[Menu] Error loading fallback categories: $e');
      return [];
    }
  }

  Future<List<MenuItemModel>> _loadFallbackItems(
    String reason, {
    int page = 1,
    int limit = 20,
    int? categoryId,
  }) async {
    debugPrint('[Menu] Using fallback data — reason: $reason');
    try {
      final String jsonString = await rootBundle.loadString(_fallbackPath);
      final Map<String, dynamic> data = json.decode(jsonString);
      final List list = data['items'] ?? [];
      List<MenuItemModel> allItems = list.map((json) => MenuItemModel.fromJson(json)).toList();

      // Filter by category if requested
      if (categoryId != null && categoryId != 0) {
        allItems = allItems.where((item) => item.categoryId == categoryId).toList();
      }

      // Manual pagination
      final int startIndex = (page - 1) * limit;
      if (startIndex >= allItems.length) {
        return [];
      }

      final int endIndex = startIndex + limit;
      return allItems.sublist(
        startIndex,
        endIndex > allItems.length ? allItems.length : endIndex,
      );
    } catch (e) {
      debugPrint('[Menu] Error loading fallback items: $e');
      return [];
    }
  }

  // Pass-through for other service methods if needed, or keep them in service
  Future<bool> toggleAvailability(int itemId, bool available) async {
    return await _menuService.toggleAvailability(itemId, available);
  }
}
