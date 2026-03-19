import 'package:flutter/foundation.dart';
import 'package:my_shop/core/network/api_client.dart';
import '../models/shop_profile_model.dart';

class ProfileService {
  static const String _profilePath = '/api/shop/profile';
  static const String _statusPath = '/api/shop/profile/status';
  static const String _operatingHoursPath = '/api/shop/profile/operating-hours';

  Future<ShopProfileModel?> getShopProfile() async {
    try {
      debugPrint('GET REQUEST: $_profilePath');
      final response = await ApiClient().dio.get(_profilePath);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = response.data;
        if (data['success'] == true && data['data'] != null) {
          return ShopProfileModel.fromJson(data['data']);
        }
      }
    } catch (e) {
      debugPrint('API Error in getShopProfile: $e');
    }
    return null;
  }

  Future<bool> updateShopProfile(Map<String, dynamic> payload) async {
    try {
      debugPrint('PUT REQUEST: $_profilePath, Data: $payload');
      final response = await ApiClient().dio.put(
        _profilePath,
        data: payload,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = response.data;
        return data['success'] == true;
      }
    } catch (e) {
      debugPrint('API Error in updateShopProfile: $e');
    }
    return false;
  }

  Future<bool> toggleShopStatus(bool isOpen) async {
    try {
      debugPrint('PUT REQUEST: $_statusPath, Query: {open: $isOpen}');
      final response = await ApiClient().dio.put(
        _statusPath,
        queryParameters: {'open': isOpen},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = response.data;
        return data['success'] == true;
      }
    } catch (e) {
      debugPrint('API Error in toggleShopStatus: $e');
    }
    return false;
  }

  Future<bool> updateOperatingHours(Map<String, dynamic> payload) async {
    try {
      debugPrint('PUT REQUEST: $_operatingHoursPath, Data: $payload');
      final response = await ApiClient().dio.put(
        _operatingHoursPath,
        data: payload,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = response.data;
        return data['success'] == true;
      }
    } catch (e) {
      debugPrint('API Error in updateOperatingHours: $e');
    }
    return false;
  }
}
