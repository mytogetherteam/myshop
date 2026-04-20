import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_shop/core/network/api_client.dart';
import '../models/shop_profile_model.dart';

class ProfileService {
  static const String _profilePath = '/api/shop/profile';
  static const String _statusPath = '/api/shop/operating-hours/status';
  static const String _operatingHoursPath = '/api/shop/operating-hours';
  static const String _changePasswordPath = '/api/shop/profile/change-password';
  
  static const bool _useLocalStorage = true;
  static const String _storageKey = 'mock_shop_profile';

  Future<ShopProfileModel?> getShopProfile() async {
    if (_useLocalStorage) {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_storageKey);
      if (data != null) {
        try {
          final decoded = jsonDecode(data) as Map<String, dynamic>;
          return ShopProfileModel.fromJson(decoded);
        } catch (e) {
          // Stale / corrupted JSON — wipe it and fall back to fresh mock
          debugPrint('ProfileService: corrupted cache detected, resetting. Error: $e');
          await prefs.remove(_storageKey);
        }
      }
      // Write and return a fresh mock profile
      final mock = _getMockProfile();
      await prefs.setString(_storageKey, jsonEncode(mock.toJson()));
      debugPrint('ProfileService: wrote fresh mock profile to cache');
      return mock;
    }

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
    if (_useLocalStorage) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final data = prefs.getString(_storageKey);
        Map<String, dynamic> currentData = {};

        if (data != null) {
          try {
            currentData = jsonDecode(data) as Map<String, dynamic>;
          } catch (_) {
            // Corrupted cache — start from mock
            debugPrint('ProfileService.updateShopProfile: bad cache, resetting to mock');
            currentData = _getMockProfile().toJson();
          }
        } else {
          currentData = _getMockProfile().toJson();
        }

        final updatedData = {...currentData, ...payload};

        // Preserve isOpen if the payload doesn't touch it
        if (!payload.containsKey('isOpen') && currentData.containsKey('isOpen')) {
          updatedData['isOpen'] = currentData['isOpen'];
        }

        await prefs.setString(_storageKey, jsonEncode(updatedData));
        debugPrint('ProfileService: saved profile. Keys updated: ${payload.keys.toList()}');
        return true;
      } catch (e) {
        debugPrint('ProfileService.updateShopProfile error: $e');
        return false;
      }
    }

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
    if (_useLocalStorage) {
      return await updateShopProfile({'isOpen': isOpen});
    }

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
    if (_useLocalStorage) {
      return await updateShopProfile({'operatingHours': payload['activeHours']});
    }

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

  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    if (_useLocalStorage) {
      await Future.delayed(const Duration(seconds: 1));
      return {
        'success': true,
        'message': 'Password changed successfully',
      };
    }

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

  ShopProfileModel _getMockProfile() {
    return ShopProfileModel(
      id: 1,
      nameEn: 'Together Shop Demo',
      nameMm: 'အတူတူ ဆိုင်',
      nameTh: 'ร้านทูเก็ตเตอร์',
      slug: 'together-shop-demo',
      logoUrl: 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?q=80&w=300&auto=format&fit=crop',
      coverUrl: 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?q=80&w=1200&auto=format&fit=crop',
      phone: '+95 9 123 456 789',
      email: 'demo@mytogether.com',
      addressEn: '123 Main St, Sanchaung, Yangon',
      districtEn: 'Sanchaung',
      cityEn: 'Yangon',
      latitude: 16.8409,
      longitude: 96.1735,
      hasParking: true,
      hasWifi: true,
      hasDelivery: true,
      isOpen: true,
      pricePreference: 'MEDIUM',
      maxItemQuantityPerOrder: 20,
      minOrderAmount: 5000,
      baseDeliveryFee: 1500,
      ratingAvg: 4.5,
      ratingCount: 120,
      isHalal: false,
      isVegetarian: false,
      operatingHours: [],
    );
  }
}
