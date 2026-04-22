import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:my_shop/core/network/api_client.dart';
import 'package:my_shop/core/network/api_helper.dart';
import '../models/shop_profile_model.dart';
import '../models/operating_hours_model.dart';

class ProfileService {
  static const String _profilePath = '/api/shop/profile';
  static const String _operatingHoursPath = '/api/shop/operating-hours';
  static const String _changePasswordPath = '/api/shop/profile/password';

  Future<List<OperatingHoursModel>> getOperatingHours() async {
    try {
      debugPrint('GET REQUEST: $_operatingHoursPath');
      final response = await ApiClient().dio.get(_operatingHoursPath);

      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        final Map<String, dynamic> data = response.data;
        if (data['success'] == true && data['data'] != null) {
          final List<dynamic> activeHours = data['data']['activeHours'] ?? [];
          return activeHours
              .map(
                (e) => OperatingHoursModel.fromActiveHoursJson(
                  e as Map<String, dynamic>,
                ),
              )
              .toList();
        }
      }
    } on DioException catch (e) {
      ApiHelper.handleError(e, context: 'ProfileService.getOperatingHours');
    } catch (e) {
      ApiHelper.handleError(e, context: 'ProfileService.getOperatingHours');
    }
    return [];
  }

  Future<ShopProfileModel?> getShopProfile() async {
    try {
      debugPrint('GET REQUEST: $_profilePath');
      final response = await ApiClient().dio.get(_profilePath);

      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        final Map<String, dynamic> data = response.data;
        if (data['success'] == true && data['data'] != null) {
          return ShopProfileModel.fromJson(data['data']);
        }
      }
    } on DioException catch (e) {
      ApiHelper.handleError(e, context: 'ProfileService.getShopProfile');
    } catch (e) {
      ApiHelper.handleError(e, context: 'ProfileService.getShopProfile');
    }
    return null;
  }

  Future<bool> updateShopProfile(Map<String, dynamic> payload) async {
    try {
      debugPrint('PUT REQUEST: $_profilePath, Data: $payload');
      final response = await ApiClient().dio.put(_profilePath, data: payload);

      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        final Map<String, dynamic> data = response.data;
        return data['success'] == true;
      }
    } on DioException catch (e) {
      ApiHelper.handleError(e, context: 'ProfileService.updateShopProfile');
    } catch (e) {
      ApiHelper.handleError(e, context: 'ProfileService.updateShopProfile');
    }
    return false;
  }


  Future<Map<String, dynamic>> updateOperatingHours(
    Map<String, dynamic> payload,
  ) async {
    try {
      debugPrint('PUT REQUEST: $_operatingHoursPath, Data: $payload');
      final response = await ApiClient().dio.put(
        _operatingHoursPath,
        data: payload,
      );

      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        final Map<String, dynamic> data = response.data;
        debugPrint('PUT RESPONSE: $data');
        return data;
      }
    } on DioException catch (e) {
      final error = ApiHelper.handleError(
        e,
        context: 'ProfileService.updateOperatingHours',
      );
      if (e.response?.data is Map) {
        return Map<String, dynamic>.from(e.response!.data);
      }
      return {'success': false, 'message': error.message};
    } catch (e) {
      final error = ApiHelper.handleError(
        e,
        context: 'ProfileService.updateOperatingHours',
      );
      return {'success': false, 'message': error.message};
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
        'currentPassword': currentPassword,
        'newPassword': newPassword,
        'confirmPassword': confirmPassword,
      };

      debugPrint('PUT REQUEST: $_changePasswordPath, Data: $payload');
      final response = await ApiClient().dio.put(
            _changePasswordPath,
            data: payload,
          );

      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        return Map<String, dynamic>.from(response.data);
      }
      return {
        'success': false,
        'message': 'Failed to change password: ${response.statusCode}',
      };
    } on DioException catch (e) {
      final error = ApiHelper.handleError(
        e,
        context: 'ProfileService.changePassword',
      );
      return {'success': false, 'message': error.message};
    } catch (e) {
      final error = ApiHelper.handleError(
        e,
        context: 'ProfileService.changePassword',
      );
      return {'success': false, 'message': error.message};
    }
  }
}
