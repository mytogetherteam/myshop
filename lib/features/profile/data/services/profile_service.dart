import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:my_shop/core/network/api_client.dart';
import '../models/shop_profile_model.dart';

class ProfileService {
  // static const String _profilePath = '/api/shop/profile';
  // static const String _statusPath = '/api/shop/profile/status';
  // static const String _operatingHoursPath = '/api/shop/profile/operating-hours';
  static const String _changePasswordPath = '/api/shop/profile/change-password';

  static const String _fallbackPath = 'assets/data/fallback_menu_data.json';

  Future<ShopProfileModel?> getShopProfile() async {
    // Commenting out API call as requested
    /*
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
    */
    
    // Return fallback data
    return await _loadFallbackProfile('API disabled/commented out');
  }

  Future<ShopProfileModel?> _loadFallbackProfile(String reason) async {
    debugPrint('[Profile] Using fallback data — reason: $reason');
    try {
      final String jsonString = await rootBundle.loadString(_fallbackPath);
      debugPrint('[Profile] JSON string loaded, length: ${jsonString.length}');
      
      final Map<String, dynamic> data = json.decode(jsonString);
      final List shops = data['shopProfiles'] ?? [];
      debugPrint('[Profile] Found ${shops.length} shop profiles in JSON');
      
      if (shops.isNotEmpty) {
        final firstShop = shops[0];
        debugPrint('[Profile] Parsing first shop: ${firstShop['nameEn']}');
        final model = ShopProfileModel.fromJson(firstShop);
        debugPrint('[Profile] Successfully parsed ShopProfileModel: ${model.nameEn}');
        return model;
      } else {
        debugPrint('[Profile] WARNING: No shop profiles found in data["shopProfiles"] or list is empty');
      }
    } catch (e, stack) {
      debugPrint('[Profile] CRITICAL ERROR loading fallback profile: $e');
      debugPrint('[Profile] Stack trace: $stack');
    }
    debugPrint('[Profile] Returning NULL for fallback profile');
    return null;
  }

  Future<bool> updateShopProfile(Map<String, dynamic> payload) async {
    // Commenting out API call as requested
    /*
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
    */
    debugPrint('[Profile] API disabled — updateShopProfile simulated success');
    return true; // Simulate success for UI
  }

  Future<bool> toggleShopStatus(bool isOpen) async {
    // Commenting out API call as requested
    /*
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
    */
    debugPrint('[Profile] API disabled — toggleShopStatus simulated success');
    return true; // Simulate success for UI
  }

  Future<bool> updateOperatingHours(Map<String, dynamic> payload) async {
    // Commenting out API call as requested
    /*
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
    */
    debugPrint('[Profile] API disabled — updateOperatingHours simulated success');
    return true; // Simulate success for UI
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
