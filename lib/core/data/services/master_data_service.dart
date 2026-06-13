import 'package:dio/dio.dart';
import 'package:my_shop/core/network/api_client.dart';
import 'package:my_shop/core/network/api_helper.dart';
import 'package:my_shop/core/data/models/master_data_model.dart';

class MasterDataService {
  List<MasterDataModel>? _parseResponse(dynamic data) {
    if (data == null) return null;

    if (data is List) {
      return data.map((json) => MasterDataModel.fromJson(json)).toList();
    } else if (data is Map && data['success'] == true && data['data'] != null) {
      final payload = data['data'];
      if (payload is List) {
        return payload.map((json) => MasterDataModel.fromJson(json)).toList();
      } else if (payload is Map && payload.containsKey('content')) {
        final List list = payload['content'];
        return list.map((json) => MasterDataModel.fromJson(json)).toList();
      } else if (payload is Map && payload.containsKey('items')) {
        final List list = payload['items'];
        return list.map((json) => MasterDataModel.fromJson(json)).toList();
      }
    }
    return null;
  }

  Future<List<MasterDataModel>?> getShopCategories() async {
    try {
      final response = await ApiClient().dio.get(
        '/api/shop/shop-categories',
      );
      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        return _parseResponse(response.data);
      }
    } on DioException catch (e) {
      ApiHelper.handleError(e, context: 'MasterDataService.getShopCategories');
    } catch (e) {
      ApiHelper.handleError(e, context: 'MasterDataService.getShopCategories');
    }
    return null;
  }

  Future<List<MasterDataModel>?> getShopSubcategories({int? categoryId}) async {
    try {
      final response = await ApiClient().dio.get(
        categoryId != null
            ? '/api/shop/shop-categories/$categoryId/sub-categories'
            : '/api/shop/shop-sub-categories',
      );
      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        return _parseResponse(response.data);
      }
    } on DioException catch (e) {
      ApiHelper.handleError(
        e,
        context: 'MasterDataService.getShopSubcategories',
      );
    } catch (e) {
      ApiHelper.handleError(
        e,
        context: 'MasterDataService.getShopSubcategories',
      );
    }
    return null;
  }

  Future<List<MasterDataModel>?> getCities() async {
    try {
      final response = await ApiClient().dio.get('/api/master/cities');
      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        return _parseResponse(response.data);
      }
    } on DioException catch (e) {
      ApiHelper.handleError(e, context: 'MasterDataService.getCities');
    } catch (e) {
      ApiHelper.handleError(e, context: 'MasterDataService.getCities');
    }
    return null;
  }

  Future<List<MasterDataModel>?> getDistricts(int? cityId) async {
    try {
      final response = await ApiClient().dio.get(
        '/api/master/districts',
        queryParameters: cityId != null ? {'cityId': cityId} : null,
      );
      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        return _parseResponse(response.data);
      }
    } on DioException catch (e) {
      ApiHelper.handleError(e, context: 'MasterDataService.getDistricts');
    } catch (e) {
      ApiHelper.handleError(e, context: 'MasterDataService.getDistricts');
    }
    return null;
  }

  Future<List<MasterDataModel>?> getCuisineTypes() async {
    try {
      final response = await ApiClient().dio.get(
        '/api/master/cuisine-types',
      );
      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        return _parseResponse(response.data);
      }
    } on DioException catch (e) {
      ApiHelper.handleError(e, context: 'MasterDataService.getCuisineTypes');
    } catch (e) {
      ApiHelper.handleError(e, context: 'MasterDataService.getCuisineTypes');
    }
    return null;
  }

  Future<List<MasterDataModel>?> getMenuTags() async {
    try {
      final response = await ApiClient().dio.get('/api/master/menu-tags');
      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        return _parseResponse(response.data);
      }
    } on DioException catch (e) {
      ApiHelper.handleError(e, context: 'MasterDataService.getMenuTags');
    } catch (e) {
      ApiHelper.handleError(e, context: 'MasterDataService.getMenuTags');
    }
    return null;
  }
}
