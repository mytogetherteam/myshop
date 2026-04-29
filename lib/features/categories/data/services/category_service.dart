import 'package:dio/dio.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:flutter/foundation.dart';
import 'package:my_shop/core/network/api_client.dart';
import 'package:my_shop/core/network/api_helper.dart';
import 'package:my_shop/features/menu/data/models/menu_category_model.dart';

class CategoryService {
  static const String _categoriesPath = '/api/shop/menu/categories';
  static const String _masterCategoriesPath =
      '/api/shop/menu/master/categories';

  // Static cache variables
  static List<MenuCategoryModel>? _categoriesCache;
  static List<Map<String, dynamic>>? _masterCategoriesCache;
  static List<Map<String, dynamic>>? _galleryCache;

  /// Clears all cached category data
  static void clearCache() {
    _categoriesCache = null;
    _masterCategoriesCache = null;
    _galleryCache = null;
  }

  Future<List<MenuCategoryModel>?> getCategories({bool forceRefresh = false}) async {
    if (!forceRefresh && _categoriesCache != null) {
      debugPrint('CACHE HIT: $_categoriesPath');
      return _categoriesCache;
    }

    try {
      debugPrint('GET REQUEST: $_categoriesPath, forceRefresh: $forceRefresh');
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
          final List list = data['data'] ?? [];
          _categoriesCache = list.map((json) => MenuCategoryModel.fromJson(json)).toList();
          return _categoriesCache;
        }
      }
    } on DioException catch (e) {
      ApiHelper.handleError(e, context: 'CategoryService.getCategories');
    } catch (e) {
      ApiHelper.handleError(e, context: 'CategoryService.getCategories');
    }
    return forceRefresh ? null : _categoriesCache;
  }

  Future<MenuCategoryModel?> getCategoryDetail(int categoryId) async {
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
      ApiHelper.handleError(e, context: 'CategoryService.getCategoryDetail');
    } catch (e) {
      ApiHelper.handleError(e, context: 'CategoryService.getCategoryDetail');
    }
    return null;
  }

  Future<List<Map<String, dynamic>>?> getMasterCategories({bool forceRefresh = false}) async {
    if (!forceRefresh && _masterCategoriesCache != null) {
      debugPrint('CACHE HIT: $_masterCategoriesPath');
      return _masterCategoriesCache;
    }

    try {
      debugPrint('GET REQUEST: $_masterCategoriesPath');
      final response = await ApiClient().dio.get(_masterCategoriesPath);

      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        final Map<String, dynamic> data = response.data;
        if (data['success'] == true && data['data'] != null) {
          final List list = data['data'] ?? [];
          _masterCategoriesCache = list.map((e) => e as Map<String, dynamic>).toList();
          return _masterCategoriesCache;
        }
      }
    } on DioException catch (e) {
      ApiHelper.handleError(e, context: 'CategoryService.getMasterCategories');
    } catch (e) {
      ApiHelper.handleError(e, context: 'CategoryService.getMasterCategories');
    }
    return forceRefresh ? null : _masterCategoriesCache;
  }

  Future<List<Map<String, dynamic>>?> getCategoryGallery({bool forceRefresh = false}) async {
    if (!forceRefresh && _galleryCache != null) {
      debugPrint('CACHE HIT: $_categoriesPath/gallery');
      return _galleryCache;
    }

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
          _galleryCache = list.map((e) => e as Map<String, dynamic>).toList();
          return _galleryCache;
        }
      }
    } on DioException catch (e) {
      ApiHelper.handleError(e, context: 'CategoryService.getCategoryGallery');
    } catch (e) {
      ApiHelper.handleError(e, context: 'CategoryService.getCategoryGallery');
    }
    return forceRefresh ? null : _galleryCache;
  }


  Future<bool> createCategory(Map<String, dynamic> payload) async {
    try {
      debugPrint('POST REQUEST: $_categoriesPath, Data: $payload');
      final response = await ApiClient().dio.post(
        _categoriesPath,
        data: payload,
      );

      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        final Map<String, dynamic> data = response.data;
        return data['success'] == true;
      }
    } on DioException catch (e) {
      ApiHelper.handleError(e, context: 'CategoryService.createCategory');
    } catch (e) {
      ApiHelper.handleError(e, context: 'CategoryService.createCategory');
    }
    return false;
  }

  Future<bool> updateCategory(
    int categoryId,
    Map<String, dynamic> payload,
  ) async {
    try {
      final url = '$_categoriesPath/$categoryId';
      debugPrint('PUT REQUEST: $url, Data: $payload');
      final response = await ApiClient().dio.put(url, data: payload);

      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        final Map<String, dynamic> data = response.data;
        return data['success'] == true;
      }
    } on DioException catch (e) {
      ApiHelper.handleError(e, context: 'CategoryService.updateCategory');
    } catch (e) {
      ApiHelper.handleError(e, context: 'CategoryService.updateCategory');
    }
    return false;
  }

  Future<bool> deleteCategory(int categoryId) async {
    try {
      final url = '$_categoriesPath/$categoryId';
      debugPrint('DELETE REQUEST: $url');
      final response = await ApiClient().dio.delete(url);

      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        final Map<String, dynamic> data = response.data;
        return data['success'] == true;
      }
    } on DioException catch (e) {
      ApiHelper.handleError(e, context: 'CategoryService.deleteCategory');
    } catch (e) {
      ApiHelper.handleError(e, context: 'CategoryService.deleteCategory');
    }
    return false;
  }

  Future<bool> reorderCategories(List<int> orderedIds) async {
    try {
      final url = '$_categoriesPath/reorder';
      final payload = {'categoryIds': orderedIds};
      debugPrint('POST REQUEST: $url, Data: $payload');
      final response = await ApiClient().dio.post(url, data: payload);

      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        final Map<String, dynamic> data = response.data;
        return data['success'] == true;
      }
    } on DioException catch (e) {
      ApiHelper.handleError(e, context: 'CategoryService.reorderCategories');
    } catch (e) {
      ApiHelper.handleError(e, context: 'CategoryService.reorderCategories');
    }
    return false;
  }

  Future<bool> toggleCategoryPublishStatus(int categoryId, String status) async {
    try {
      final url = '$_categoriesPath/$categoryId/publish';
      debugPrint('PATCH REQUEST: $url, Query: {status: $status}');
      final response = await ApiClient().dio.patch(
            url,
            queryParameters: {'publishStatus': status},
          );

      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        final Map<String, dynamic> data = response.data;
        return data['success'] == true;
      }
    } on DioException catch (e) {
      ApiHelper.handleError(e, context: 'CategoryService.toggleCategoryPublishStatus');
    } catch (e) {
      ApiHelper.handleError(e, context: 'CategoryService.toggleCategoryPublishStatus');
    }
    return false;
  }
}

