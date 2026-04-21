import 'package:flutter/foundation.dart';
import 'package:my_shop/core/network/api_client.dart';
import 'package:my_shop/core/data/models/master_data_model.dart';

class MasterDataService {
  Future<List<MasterDataModel>?> getShopCategories() async {
    try {
      final response = await ApiClient().dio.get('/api/shop/master/shop-categories');
      if (response.statusCode == 200) {
        final data = response.data;
        if (data != null && data is List) {
          return data.map((json) => MasterDataModel.fromJson(json)).toList();
        } else if (data['success'] == true && data['data'] != null) {
          final List list = data['data'];
          return list.map((json) => MasterDataModel.fromJson(json)).toList();
        }
      }
    } catch (e) {
      debugPrint('API Error in getShopCategories: $e');
    }
    return null;
  }

  Future<List<MasterDataModel>?> getShopSubcategories() async {
    try {
      final response = await ApiClient().dio.get('/api/shop/master/shop-subcategories');
      if (response.statusCode == 200) {
        final data = response.data;
        if (data != null && data is List) {
          return data.map((json) => MasterDataModel.fromJson(json)).toList();
        } else if (data['success'] == true && data['data'] != null) {
          final List list = data['data'];
          return list.map((json) => MasterDataModel.fromJson(json)).toList();
        }
      }
    } catch (e) {
      debugPrint('API Error in getShopSubcategories: $e');
    }
    return null;
  }

  Future<List<MasterDataModel>?> getCities() async {
    try {
      final response = await ApiClient().dio.get('/api/shop/master/cities');
      if (response.statusCode == 200) {
        final data = response.data;
        if (data != null && data is List) {
          return data.map((json) => MasterDataModel.fromJson(json)).toList();
        } else if (data['success'] == true && data['data'] != null) {
          final List list = data['data'];
          return list.map((json) => MasterDataModel.fromJson(json)).toList();
        }
      }
    } catch (e) {
      debugPrint('API Error in getCities: $e');
    }
    return null;
  }

  Future<List<MasterDataModel>?> getDistricts(int? cityId) async {
    try {
      final response = await ApiClient().dio.get(
        '/api/shop/master/districts',
        queryParameters: cityId != null ? {'cityId': cityId} : null,
      );
      if (response.statusCode == 200) {
        final data = response.data;
        if (data != null && data is List) {
          return data.map((json) => MasterDataModel.fromJson(json)).toList();
        } else if (data['success'] == true && data['data'] != null) {
          final List list = data['data'];
          return list.map((json) => MasterDataModel.fromJson(json)).toList();
        }
      }
    } catch (e) {
      debugPrint('API Error in getDistricts: $e');
    }
    return null;
  }

  Future<List<MasterDataModel>?> getCuisineTypes() async {
    try {
      final response = await ApiClient().dio.get('/api/shop/master/cuisine-types');
      if (response.statusCode == 200) {
        final data = response.data;
        if (data != null && data is List) {
          return data.map((json) => MasterDataModel.fromJson(json)).toList();
        } else if (data['success'] == true && data['data'] != null) {
          final List list = data['data'];
          return list.map((json) => MasterDataModel.fromJson(json)).toList();
        }
      }
    } catch (e) {
      debugPrint('API Error in getCuisineTypes: $e');
    }
    return null;
  }

  Future<List<MasterDataModel>?> getMenuTags() async {
    try {
      final response = await ApiClient().dio.get('/api/shop/master/menu-tags');
      if (response.statusCode == 200) {
        final data = response.data;
        if (data != null && data is List) {
          return data.map((json) => MasterDataModel.fromJson(json)).toList();
        } else if (data['success'] == true && data['data'] != null) {
          final List list = data['data'];
          return list.map((json) => MasterDataModel.fromJson(json)).toList();
        }
      }
    } catch (e) {
      debugPrint('API Error in getMenuTags: $e');
    }
    return null;
  }
}
