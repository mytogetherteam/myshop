import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:my_shop/app.dart';
import 'package:my_shop/core/data/services/storage_service.dart';
import 'package:my_shop/core/network/api_helper.dart';
import 'package:my_shop/features/auth/data/models/auth_models.dart';
import 'package:my_shop/core/network/api_client.dart';
import 'package:my_shop/core/notifications/notification_service.dart';

class AuthService {
  static const String _authPath = '/api/shop/auth';

  static final AuthService instance = AuthService._();
  AuthService._();

  Future<String?> getAccessToken() async {
    return await StorageService.instance.getToken();
  }

  Future<bool> get isLoggedIn async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  Future<AuthResponse> login({
    required String usernameOrEmail,
    required String password,
  }) async {
    try {
      final response = await ApiClient().dio.post(
        '$_authPath/login',
        data: {'emailOrUsername': usernameOrEmail, 'password': password},
      );

      final authResponse = AuthResponse.fromJson(response.data);

      if (authResponse.success && authResponse.token != null) {
        await StorageService.instance.saveTokens(
          token: authResponse.token!,
          refreshToken: authResponse.refreshToken ?? '',
        );
        if (authResponse.userInfo != null) {
          await StorageService.instance.saveUserInfo(authResponse.userInfo!);
        }
      }

      return authResponse;
    } on DioException catch (e) {
      final error = ApiHelper.handleError(e, context: 'AuthService.login');
      if (e.response?.data != null) {
        try {
          return AuthResponse.fromJson(e.response!.data);
        } catch (_) {}
      }
      return AuthResponse(success: false, message: error.message);
    } catch (e) {
      final error = ApiHelper.handleError(e, context: 'AuthService.login');
      return AuthResponse(success: false, message: error.message);
    }
  }

  Future<AuthResponse> registerShop({
    required String shopName,
    required String ownerName,
    required String phone,
    String? email,
  }) async {
    try {
      final response = await ApiClient().dio.post(
        '/api/shop-register',
        data: {
          'shopName': shopName,
          'ownerName': ownerName,
          'phone': phone,
          if (email != null && email.isNotEmpty) 'email': email,
        },
      );

      return AuthResponse(
        success: response.data['success'] == true,
        message: response.data['message'] ?? 'Application submitted',
      );
    } on DioException catch (e) {
      final error = ApiHelper.handleError(e, context: 'AuthService.registerShop');
      return AuthResponse(success: false, message: error.message);
    } catch (e) {
      final error = ApiHelper.handleError(e, context: 'AuthService.registerShop');
      return AuthResponse(success: false, message: error.message);
    }
  }


  Future<void> logout() async {
    try {
      await NotificationService().unregisterDevice();
      final refreshToken = await StorageService.instance.getRefreshToken();
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await ApiClient().dio.post(
          '$_authPath/logout',
          data: {'refreshToken': refreshToken},
        );
      }
    } catch (e) {
      debugPrint('[AuthService.logout] API error (ignored): $e');
    } finally {
      await StorageService.instance.clearAll();
    }
  }

  Future<bool> deleteAccount() async {
    try {
      await ApiClient().dio.delete('$_authPath/delete-account');
      await NotificationService().unregisterDevice();
      await StorageService.instance.clearAll();
      return true;
    } on DioException catch (e) {
      debugPrint('[AuthService.deleteAccount] API error: ${ApiHelper.handleError(e).message}');
      return false;
    } catch (e) {
      debugPrint('[AuthService.deleteAccount] Error: $e');
      return false;
    }
  }

  Future<void> logoutWithRedirect() async {
    await logout();
    App.navigatorKey.currentState?.pushNamedAndRemoveUntil(
      '/login',
      (route) => false,
    );
  }

  Future<String?> performRefresh(Dio dio) async {
    final refreshToken = await StorageService.instance.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      debugPrint('[AuthService.performRefresh] No refresh token stored - logging out');
      return null;
    }

    try {
      final response = await dio.post(
        '$_authPath/refresh',
        data: {'refreshToken': refreshToken},
        options: Options(headers: {'Authorization': ''}),
      );

      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300 &&
          response.data != null) {
        final data = response.data['data'];
        if (data == null) return null;

        final newToken =
            data['token'] as String? ?? data['accessToken'] as String? ?? '';
        final newRefreshToken = data['refreshToken'] as String?;

        if (newToken.isNotEmpty) {
          await StorageService.instance.saveTokens(
            token: newToken,
            refreshToken: newRefreshToken ?? refreshToken,
          );
          debugPrint('[AuthService.performRefresh] Token refreshed successfully');
          return newToken;
        }
      }
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      debugPrint('[AuthService.performRefresh] API error (status=$statusCode): ${ApiHelper.handleError(e).message}');

      // Refresh token ကုန်သွားတာ သို့မဟုတ် invalid ဖြစ်နေတာ - storage ကို clear လုပ်ပါ
      if (statusCode == 401 || statusCode == 403) {
        debugPrint('[AuthService.performRefresh] Refresh token expired/invalid - clearing storage');
        await StorageService.instance.clearAll();
      }
    } catch (e) {
      debugPrint('[AuthService.performRefresh] Unexpected error: $e');
    }
    return null;
  }
}
