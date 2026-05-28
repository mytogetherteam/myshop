import 'package:dio/dio.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:flutter/foundation.dart';
import 'package:my_shop/core/network/api_client.dart';
import 'package:my_shop/core/network/api_helper.dart';
import 'package:my_shop/core/utils/app_logger.dart';
import '../models/menu_item_model.dart';
import '../models/menu_category_model.dart';
import 'package:my_shop/core/data/models/master_data_model.dart';

List<MenuCategoryModel> _parseMenuCategories(List<dynamic> jsonList) {
  return jsonList.map((json) => MenuCategoryModel.fromJson(json)).toList();
}

List<MenuItemModel> _parseMenuItems(List<dynamic> jsonList) {
  return jsonList.map((json) => MenuItemModel.fromJson(json)).toList();
}

List<MasterDataModel> _parseMasterDataModels(List<dynamic> jsonList) {
  return jsonList.map((json) => MasterDataModel.fromJson(json)).toList();
}

class MenuService {
  static const String _categoriesPath = '/api/shop/menu-categories';
  static const String _menuItemsPath = '/api/shop/menu-items';
  static const String _masterCategoriesPath =
      '/api/menu/master/categories';
  static const String _masterTagsPath = '/api/master/menu-tags';

  /// Retained for callers that previously invalidated the in-memory cache.
  /// Real HTTP caching is now handled by `ApiClient.cacheOptions` (Dio), so
  /// this is a no-op kept for source compatibility.
  static void clearCache() {}

  Future<List<MenuCategoryModel>?> getCategories({bool forceRefresh = false}) async {
    try {
      AppLogger.network('GET $_categoriesPath, forceRefresh: $forceRefresh');
      final response = await ApiClient().dio.get(
        _categoriesPath,
        options: forceRefresh
            ? ApiClient.cacheOptions.copyWith(policy: CachePolicy.refresh).toOptions()
            : null,
      );

      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        final Map<String, dynamic> data = response.data;
        if (data['success'] == true && data['data'] != null) {
          final dynamic rawData = data['data'];
          List list;
          if (rawData is List) {
            list = rawData;
          } else if (rawData is Map && rawData['content'] is List) {
            list = rawData['content'];
          } else {
            list = [];
          }
          return await compute(_parseMenuCategories, list);
        }
      }
    } on DioException catch (e) {
      ApiHelper.handleError(e, context: 'MenuService.getCategories');
    } catch (e) {
      ApiHelper.handleError(e, context: 'MenuService.getCategories');
    }
    return null;
  }

  Future<List<MenuCategoryModel>?> searchCategories(String query) async {
    try {
      AppLogger.network('GET $_categoriesPath, Query: {q: $query}');
      final response = await ApiClient().dio.get(
        _categoriesPath,
        queryParameters: {'q': query},
      );

      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        final Map<String, dynamic> data = response.data;
        if (data['success'] == true && data['data'] != null) {
          final dynamic rawData = data['data'];
          List list;
          if (rawData is List) {
            list = rawData;
          } else if (rawData is Map && rawData['content'] is List) {
            list = rawData['content'];
          } else {
            list = [];
          }
          return await compute(_parseMenuCategories, list);
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
      AppLogger.network('GET $url');
      final response = await ApiClient().dio.get(url);

      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        final Map<String, dynamic> data = response.data;
        if (data['success'] == true && data['data'] != null) {
          final dynamic rawData = data['data'];
          List list;
          if (rawData is List) {
            list = rawData;
          } else if (rawData is Map && rawData['content'] is List) {
            list = rawData['content'];
          } else {
            list = [];
          }
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
      AppLogger.network('GET $url');
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
    bool forceRefresh = false,
  }) async {
    try {
      final queryParams = <String, dynamic>{'page': page, 'limit': limit};
      if (categoryId != null) {
        queryParams['categoryId'] = categoryId;
      }
      AppLogger.network('GET $_menuItemsPath, Params: $queryParams, forceRefresh: $forceRefresh');
      
      final response = await ApiClient().dio.get(
        _menuItemsPath,
        queryParameters: queryParams,
        options: forceRefresh
            ? ApiClient.cacheOptions.copyWith(policy: CachePolicy.refresh).toOptions()
            : null,
      );

      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        final Map<String, dynamic> data = response.data;
        if (data['success'] == true && data['data'] != null) {
          final dynamic rawData = data['data'];
          List list;
          if (rawData is List) {
            list = rawData;
          } else if (rawData is Map && rawData['content'] is List) {
            list = rawData['content'];
          } else {
            list = [];
          }
          return await compute(_parseMenuItems, list);
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
      AppLogger.network('GET $_menuItemsPath, Query: {q: $query}');
      final response = await ApiClient().dio.get(
        _menuItemsPath,
        queryParameters: {'q': query},
      );

      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        final Map<String, dynamic> data = response.data;
        if (data['success'] == true && data['data'] != null) {
          final dynamic rawData = data['data'];
          List list;
          if (rawData is List) {
            list = rawData;
          } else if (rawData is Map && rawData['content'] is List) {
            list = rawData['content'];
          } else {
            list = [];
          }
          return await compute(_parseMenuItems, list);
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
      AppLogger.network('GET $url');
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

  Future<List<MasterDataModel>?> getMasterCategories({bool forceRefresh = false}) async {
    try {
      AppLogger.network('GET $_masterCategoriesPath');
      final response = await ApiClient().dio.get(_masterCategoriesPath);
      return await _parseMasterDataList(response);
    } on DioException catch (e) {
      ApiHelper.handleError(e, context: 'MenuService.getMasterCategories');
    } catch (e) {
      ApiHelper.handleError(e, context: 'MenuService.getMasterCategories');
    }
    return null;
  }

  Future<MenuCategoryModel?> getMasterCategoryDetail(int id) async {
    try {
      final url = '$_masterCategoriesPath/$id';
      AppLogger.network('GET $url');
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
    try {
      AppLogger.network('GET $_masterTagsPath');
      final response = await ApiClient().dio.get(_masterTagsPath);
      return await _parseMasterDataList(response);
    } on DioException catch (e) {
      ApiHelper.handleError(e, context: 'MenuService.getMenuTags');
    } catch (e) {
      ApiHelper.handleError(e, context: 'MenuService.getMenuTags');
    }
    return null;
  }

  Future<MasterDataModel?> getMenuTagDetail(int id) async {
    try {
      final url = '$_masterTagsPath/$id';
      AppLogger.network('GET $url');
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

  Future<List<MasterDataModel>?> _parseMasterDataList(dynamic response) async {
    if (response.statusCode != null &&
        response.statusCode! >= 200 &&
        response.statusCode! < 300) {
      final Map<String, dynamic> data = response.data;
      if (data['success'] == true && data['data'] != null) {
        final dynamic rawData = data['data'];
        List list;
        if (rawData is List) {
          list = rawData;
        } else if (rawData is Map && rawData['content'] is List) {
          list = rawData['content'];
        } else {
          list = [];
        }
        return await compute(_parseMasterDataModels, list);
      }
    }
    return null;
  }


  Future<bool> createMenuItem(Map<String, dynamic> payload) async {
    try {
      AppLogger.network('POST $_menuItemsPath, Data: $payload');

      final response = await ApiClient().dio.post(
        _menuItemsPath,
        data: payload,
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

  Future<bool> updateMenuItem(int itemId, Map<String, dynamic> payload) async {
    try {
      final url = '$_menuItemsPath/$itemId';
      AppLogger.network('PUT $url, Data: $payload');

      final response = await ApiClient().dio.put(
        url,
        data: payload,
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
      AppLogger.network('DELETE $url');
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
      AppLogger.network('PUT $url, Query: {available: $available}');
      final response = await ApiClient().dio.put(
        url,
        queryParameters: {'available': available},
      );

      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        return true;
      }
    } on DioException catch (e) {
      ApiHelper.handleError(e, context: 'MenuService.toggleAvailability');
    } catch (e) {
      ApiHelper.handleError(e, context: 'MenuService.toggleAvailability');
    }
    return false;
  }

  /// PATCH /api/shop/menu-items/{id}/publish — body `{ status }` (DRAFT | PUBLISHED | …).
  Future<bool> toggleMenuItemPublishStatus(int itemId, String status) async {
    try {
      final url = '$_menuItemsPath/$itemId/publish';
      AppLogger.network('PATCH $url, Data: {status: $status}');
      final response = await ApiClient().dio.patch(
        url,
        data: {'status': status},
      );

      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        return true;
      }
    } on DioException catch (e) {
      ApiHelper.handleError(e, context: 'MenuService.toggleMenuItemPublishStatus');
    } catch (e) {
      ApiHelper.handleError(e, context: 'MenuService.toggleMenuItemPublishStatus');
    }
    return false;
  }

  /// PUT /api/shop/menu-items/{id}/recommended?enabled=true|false
  Future<bool> toggleRecommended(int itemId, bool enabled) async {
    try {
      final url = '$_menuItemsPath/$itemId/recommended';
      AppLogger.network('PUT $url, Query: {enabled: $enabled}');
      final response = await ApiClient().dio.put(
        url,
        queryParameters: {'enabled': enabled},
      );
      return response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300;
    } on DioException catch (e) {
      ApiHelper.handleError(e, context: 'MenuService.toggleRecommended');
    } catch (e) {
      ApiHelper.handleError(e, context: 'MenuService.toggleRecommended');
    }
    return false;
  }

  /// PUT /api/shop/menu-items/{id}/hot-deal?enabled=true|false
  Future<bool> toggleHotDeal(int itemId, bool enabled) async {
    try {
      final url = '$_menuItemsPath/$itemId/hot-deal';
      AppLogger.network('PUT $url, Query: {enabled: $enabled}');
      final response = await ApiClient().dio.put(
        url,
        queryParameters: {'enabled': enabled},
      );
      return response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300;
    } on DioException catch (e) {
      ApiHelper.handleError(e, context: 'MenuService.toggleHotDeal');
    } catch (e) {
      ApiHelper.handleError(e, context: 'MenuService.toggleHotDeal');
    }
    return false;
  }
}

