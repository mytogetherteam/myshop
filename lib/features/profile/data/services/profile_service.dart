import 'package:flutter/foundation.dart';
import 'package:my_shop/core/network/api_client.dart';
import '../models/shop_profile_model.dart';
import '../models/operating_hours_model.dart';

class ProfileService {
  static const String _profilePath = '/api/shop/profile';
  static const String _statusPath = '/api/shop/operating-hours/status';
  static const String _operatingHoursPath = '/api/shop/operating-hours';
  static const String _changePasswordPath = '/api/shop/profile/change-password';

  /// GET /api/shop/operating-hours
  /// X-Shop-Id is injected automatically by ShopInterceptor from global_shop_selection.
  Future<List<OperatingHoursModel>> getOperatingHours() async {
    try {
      debugPrint('GET REQUEST: $_operatingHoursPath');
      final response = await ApiClient().dio.get(_operatingHoursPath);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = response.data;
        if (data['success'] == true && data['data'] != null) {
          final List<dynamic> activeHours = data['data']['activeHours'] ?? [];
          return activeHours
              .map((e) => OperatingHoursModel.fromActiveHoursJson(e as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('API Error in getOperatingHours: $e');
    }
    return [];
  }

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

  Future<Map<String, dynamic>> updateOperatingHours(Map<String, dynamic> payload) async {
    try {
      debugPrint('PUT REQUEST: $_operatingHoursPath, Data: $payload');
      final response = await ApiClient().dio.put(
        _operatingHoursPath,
        data: payload,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> data = response.data;
        debugPrint('PUT RESPONSE: $data');
        return data;
      }
    } catch (e) {
      if (e is DioException) {
        debugPrint('API Error in updateOperatingHours: ${e.response?.statusCode}');
        debugPrint('Error Body: ${e.response?.data}');
        if (e.response?.data is Map) {
          return e.response?.data;
        }
      } else {
        debugPrint('Error in updateOperatingHours: $e');
      }
    }
    return {'success': false, 'message': 'Unknown error occurred'};
  }

  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      final payload = {
        'current_password': currentPassword,
        'new_password': newPassword,
        'new_password_confirmation': confirmPassword,
      };

      debugPrint('POST REQUEST: $_changePasswordPath, Data: $payload');
      final response = await ApiClient().dio.post(
        _changePasswordPath,
        data: payload,
      );

      if (response.statusCode == 200) {
        return response.data;
      }
      return {
        'success': false,
        'message': 'Failed to change password: ${response.statusCode}',
      };
    } catch (e) {
      debugPrint('API Error in changePassword: $e');
      return {
        'success': false,
        'message': 'Error: ${e.toString()}',
      };
    }
  }
}
