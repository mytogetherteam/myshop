import 'dart:io';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:my_shop/core/network/api_client.dart';
import 'package:my_shop/core/network/api_helper.dart';
import '../models/menu_item_model.dart';
import '../models/menu_category_model.dart';
import 'package:my_shop/core/data/models/master_data_model.dart';

class MenuService {
  static const String _categoriesPath = '/api/shop/menu/categories';
  static const String _menuItemsPath = '/api/shop/menu/items';
  static const String _masterItemsPath = '/api/shop/menu/master/items';
  static const String _masterCategoriesPath =
      '/api/shop/menu/master/categories';
  static const String _masterTagsPath = '/api/shop/master/menu-tags';

  // Static cache variables to store data across the app session
  static List<MenuCategoryModel>? _categoriesCache;
  static List<MasterDataModel>? _masterCategoriesCache;
  static List<MasterDataModel>? _masterItemsCache;
  static List<MasterDataModel>? _menuTagsCache;

  /// Clears all cached menu data
  static void clearCache() {
    _categoriesCache = null;
    _masterCategoriesCache = null;
    _masterItemsCache = null;
    _menuTagsCache = null;
  }

  Future<List<MenuCategoryModel>?> getCategories({bool forceRefresh = false}) async {
    if (!forceRefresh && _categoriesCache != null) {
      debugPrint('CACHE HIT: $_categoriesPath');
      return _categoriesCache;
    }

    try {
      debugPrint('GET REQUEST: $_categoriesPath');
      final response = await ApiClient().dio.get(_categoriesPath);

      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        final Map<String, dynamic> data = response.data;
        if (data['success'] == true && data['data'] != null) {
          final List list = data['data'] ?? [];
          _categoriesCache = list.map((json) => MenuCategoryModel.fromJson(json)).toList();
          return _categoriesCache;
        }
      }
    } on DioException catch (e) {
      ApiHelper.handleError(e, context: 'MenuService.getCategories');
    } catch (e) {
      ApiHelper.handleError(e, context: 'MenuService.getCategories');
    }
    return forceRefresh ? null : _categoriesCache;
  }

  Future<List<MenuCategoryModel>?> searchCategories(String query) async {
    try {
      final url = '$_categoriesPath/search';
      debugPrint('GET REQUEST: $url, Query: {q: $query}');
      final response = await ApiClient().dio.get(url, queryParameters: {'q': query});

      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        final Map<String, dynamic> data = response.data;
        if (data['success'] == true && data['data'] != null) {
          final List list = data['data'] ?? [];
          return list.map((json) => MenuCategoryModel.fromJson(json)).toList();
        }
      }
    } on DioException catch (e) {
      ApiHelper.handleError(e, context: 'MenuService.searchCategories');
    } catch (e) {
      ApiHelper.handleError(e, context: 'MenuService.searchCategories');
    }
    return null;
  }

  Future<List<Map<String, dynamic>>?> getCategoryGallery() async {
    try {
      final url = '$_categoriesPath/gallery';
      debugPrint('GET REQUEST: $url');
      final response = await ApiClient().dio.get(url);

      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        final Map<String, dynamic> data = response.data;
        if (data['success'] == true && data['data'] != null) {
          final List list = data['data'] ?? [];
          return list.map((e) => Map<String, dynamic>.from(e)).toList();
        }
      }
    } on DioException catch (e) {
      ApiHelper.handleError(e, context: 'MenuService.getCategoryGallery');
    } catch (e) {
      ApiHelper.handleError(e, context: 'MenuService.getCategoryGallery');
    }
    return null;
  }

  Future<MenuCategoryModel?> getMenuCategoryDetail(int categoryId) async {
    try {
      final url = '$_categoriesPath/$categoryId';
      debugPrint('GET REQUEST: $url');
      final response = await ApiClient().dio.get(url);

      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        final Map<String, dynamic> data = response.data;
        if (data['success'] == true && data['data'] != null) {
          return MenuCategoryModel.fromJson(data['data']);
        }
      }
    } on DioException catch (e) {
      ApiHelper.handleError(e, context: 'MenuService.getMenuCategoryDetail');
    } catch (e) {
      ApiHelper.handleError(e, context: 'MenuService.getMenuCategoryDetail');
    }
    return null;
  }

  Future<List<MenuItemModel>?> getMenuItems({
    int? categoryId,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{'page': page, 'limit': limit};
      if (categoryId != null) {
        queryParams['categoryId'] = categoryId;
      }
      debugPrint('GET REQUEST: $_menuItemsPath, Params: $queryParams');
      final response = await ApiClient().dio.get(
        _menuItemsPath,
        queryParameters: queryParams,
      );

      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        final Map<String, dynamic> data = response.data;
        if (data['success'] == true && data['data'] != null) {
          final List list = data['data'] ?? [];
          return list.map((json) => MenuItemModel.fromJson(json)).toList();
        }
      }
    } on DioException catch (e) {
      ApiHelper.handleError(e, context: 'MenuService.getMenuItems');
    } catch (e) {
      ApiHelper.handleError(e, context: 'MenuService.getMenuItems');
    }
    return null;
  }

  Future<List<MenuItemModel>?> searchMenuItems(String query) async {
    try {
      final url = '$_menuItemsPath/search';
      debugPrint('GET REQUEST: $url, Query: {q: $query}');
      final response = await ApiClient().dio.get(url, queryParameters: {'q': query});

      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        final Map<String, dynamic> data = response.data;
        if (data['success'] == true && data['data'] != null) {
          final List list = data['data'] ?? [];
          return list.map((json) => MenuItemModel.fromJson(json)).toList();
        }
      }
    } on DioException catch (e) {
      ApiHelper.handleError(e, context: 'MenuService.searchMenuItems');
    } catch (e) {
      ApiHelper.handleError(e, context: 'MenuService.searchMenuItems');
    }
    return null;
  }

  Future<MenuItemModel?> getMenuItemDetail(int itemId) async {
    try {
      final url = '$_menuItemsPath/$itemId';
      debugPrint('GET REQUEST: $url');
      final response = await ApiClient().dio.get(url);

      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        final Map<String, dynamic> data = response.data;
        if (data['success'] == true && data['data'] != null) {
          return MenuItemModel.fromJson(data['data']);
        }
      }
    } on DioException catch (e) {
      ApiHelper.handleError(e, context: 'MenuService.getMenuItemDetail');
    } catch (e) {
      ApiHelper.handleError(e, context: 'MenuService.getMenuItemDetail');
    }
    return null;
  }

  Future<List<MasterDataModel>?> getMasterMenuItems({bool forceRefresh = false}) async {
    if (!forceRefresh && _masterItemsCache != null) {
      debugPrint('CACHE HIT: $_masterItemsPath');
      return _masterItemsCache;
    }

    try {
      debugPrint('GET REQUEST: $_masterItemsPath');
      final response = await ApiClient().dio.get(_masterItemsPath);
      _masterItemsCache = _parseMasterDataList(response);
      return _masterItemsCache;
    } on DioException catch (e) {
      ApiHelper.handleError(e, context: 'MenuService.getMasterMenuItems');
    } catch (e) {
      ApiHelper.handleError(e, context: 'MenuService.getMasterMenuItems');
    }
    return forceRefresh ? null : _masterItemsCache;
  }

  Future<MenuItemModel?> getMasterMenuItemDetail(int id) async {
    try {
      final url = '$_masterItemsPath/$id';
      debugPrint('GET REQUEST: $url');
      final response = await ApiClient().dio.get(url);
      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300 &&
          response.data['success'] == true) {
        return MenuItemModel.fromJson(response.data['data']);
      }
    } on DioException catch (e) {
      ApiHelper.handleError(e, context: 'MenuService.getMasterMenuItemDetail');
    } catch (e) {
      ApiHelper.handleError(e, context: 'MenuService.getMasterMenuItemDetail');
    }
    return null;
  }

  Future<List<MasterDataModel>?> getMasterCategories({bool forceRefresh = false}) async {
    if (!forceRefresh && _masterCategoriesCache != null) {
      debugPrint('CACHE HIT: $_masterCategoriesPath');
      return _masterCategoriesCache;
    }

    try {
      debugPrint('GET REQUEST: $_masterCategoriesPath');
      final response = await ApiClient().dio.get(_masterCategoriesPath);
      _masterCategoriesCache = _parseMasterDataList(response);
      return _masterCategoriesCache;
    } on DioException catch (e) {
      ApiHelper.handleError(e, context: 'MenuService.getMasterCategories');
    } catch (e) {
      ApiHelper.handleError(e, context: 'MenuService.getMasterCategories');
    }
    return forceRefresh ? null : _masterCategoriesCache;
  }

  Future<MenuCategoryModel?> getMasterCategoryDetail(int id) async {
    try {
      final url = '$_masterCategoriesPath/$id';
      debugPrint('GET REQUEST: $url');
      final response = await ApiClient().dio.get(url);
      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300 &&
          response.data['success'] == true) {
        return MenuCategoryModel.fromJson(response.data['data']);
      }
    } on DioException catch (e) {
      ApiHelper.handleError(e, context: 'MenuService.getMasterCategoryDetail');
    } catch (e) {
      ApiHelper.handleError(e, context: 'MenuService.getMasterCategoryDetail');
    }
    return null;
  }

  Future<List<MasterDataModel>?> getMenuTags({bool forceRefresh = false}) async {
    if (!forceRefresh && _menuTagsCache != null) {
      debugPrint('CACHE HIT: $_masterTagsPath');
      return _menuTagsCache;
    }

    try {
      debugPrint('GET REQUEST: $_masterTagsPath');
      final response = await ApiClient().dio.get(_masterTagsPath);
      _menuTagsCache = _parseMasterDataList(response);
      return _menuTagsCache;
    } on DioException catch (e) {
      ApiHelper.handleError(e, context: 'MenuService.getMenuTags');
    } catch (e) {
      ApiHelper.handleError(e, context: 'MenuService.getMenuTags');
    }
    return forceRefresh ? null : _menuTagsCache;
  }

  Future<MasterDataModel?> getMenuTagDetail(int id) async {
    try {
      final url = '$_masterTagsPath/$id';
      debugPrint('GET REQUEST: $url');
      final response = await ApiClient().dio.get(url);
      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300 &&
          response.data['success'] == true) {
        return MasterDataModel.fromJson(response.data['data']);
      }
    } on DioException catch (e) {
      ApiHelper.handleError(e, context: 'MenuService.getMenuTagDetail');
    } catch (e) {
      ApiHelper.handleError(e, context: 'MenuService.getMenuTagDetail');
    }
    return null;
  }

  List<MasterDataModel>? _parseMasterDataList(dynamic response) {
    if (response.statusCode != null &&
        response.statusCode! >= 200 &&
        response.statusCode! < 300) {
      final Map<String, dynamic> data = response.data;
      if (data['success'] == true && data['data'] != null) {
        final List list = data['data'] ?? [];
        return list.map((json) => MasterDataModel.fromJson(json)).toList();
      }
    }
    return null;
  }


  Future<bool> createMenuItem(Map<String, dynamic> payload, {File? image}) async {
    try {
      debugPrint('POST REQUEST: $_menuItemsPath, Data: $payload');
      
      final formDataMap = {
        'data': MultipartFile.fromString(
          jsonEncode(payload),
          contentType: DioMediaType.parse('application/json'),
        ),
      };

      if (image != null) {
        formDataMap['image'] = await MultipartFile.fromFile(
          image.path,
          filename: image.path.split('/').last,
        );
      }

      final response = await ApiClient().dio.post(
        _menuItemsPath,
        data: FormData.fromMap(formDataMap),
      );

      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        final Map<String, dynamic> data = response.data;
        return data['success'] == true;
      }
    } on DioException catch (e) {
      ApiHelper.handleError(e, context: 'MenuService.createMenuItem');
    } catch (e) {
      ApiHelper.handleError(e, context: 'MenuService.createMenuItem');
    }
    return false;
  }

  Future<bool> updateMenuItem(int itemId, Map<String, dynamic> payload, {File? image}) async {
    try {
      final url = '$_menuItemsPath/$itemId';
      debugPrint('PUT REQUEST: $url, Data: $payload');
      
      final formDataMap = {
        'data': MultipartFile.fromString(
          jsonEncode(payload),
          contentType: DioMediaType.parse('application/json'),
        ),
      };

      if (image != null) {
        formDataMap['image'] = await MultipartFile.fromFile(
          image.path,
          filename: image.path.split('/').last,
        );
      }

      final response = await ApiClient().dio.put(
        url,
        data: FormData.fromMap(formDataMap),
      );

      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        final Map<String, dynamic> data = response.data;
        return data['success'] == true;
      }
    } on DioException catch (e) {
      ApiHelper.handleError(e, context: 'MenuService.updateMenuItem');
    } catch (e) {
      ApiHelper.handleError(e, context: 'MenuService.updateMenuItem');
    }
    return false;
  }

  Future<bool> deleteMenuItem(int itemId) async {
    try {
      final url = '$_menuItemsPath/$itemId';
      debugPrint('DELETE REQUEST: $url');
      final response = await ApiClient().dio.delete(url);

      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        final Map<String, dynamic> data = response.data;
        return data['success'] == true;
      }
    } on DioException catch (e) {
      ApiHelper.handleError(e, context: 'MenuService.deleteMenuItem');
    } catch (e) {
      ApiHelper.handleError(e, context: 'MenuService.deleteMenuItem');
    }
    return false;
  }

  Future<bool> toggleAvailability(int itemId, bool available) async {
    try {
      final url = '$_menuItemsPath/$itemId/availability';
      debugPrint('PUT REQUEST: $url, Query: {available: $available}');
      final response = await ApiClient().dio.put(
        url,
        queryParameters: {'available': available},
      );

      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        final Map<String, dynamic> data = response.data;
        return data['success'] == true;
      }
    } on DioException catch (e) {
      ApiHelper.handleError(e, context: 'MenuService.toggleAvailability');
    } catch (e) {
      ApiHelper.handleError(e, context: 'MenuService.toggleAvailability');
    }
    return false;
  }
}
