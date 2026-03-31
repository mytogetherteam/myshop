import 'package:dio/dio.dart';
import 'package:my_shop/app.dart';
import 'package:my_shop/core/data/services/storage_service.dart';
import 'package:my_shop/features/auth/data/models/auth_models.dart';
import 'package:my_shop/core/network/api_client.dart';

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
        data: {
          'emailOrUsername': usernameOrEmail,
          'password': password,
        },
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
    } catch (e) {
      if (e is DioException && e.response?.data != null) {
        try {
          return AuthResponse.fromJson(e.response!.data);
        } catch (_) {}
      }
      return AuthResponse(success: false, message: 'Connection error: $e');
    }
  }


  Future<void> logout() async {
    try {
      final refreshToken = await StorageService.instance.getRefreshToken();
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await ApiClient().dio.post(
          '$_authPath/logout',
          data: {'refreshToken': refreshToken},
        );
      }
    } catch (e) {
      // Silently fail if API logout fails, still need to clear local data
    } finally {
      await StorageService.instance.clearAll();
    }
  }

  Future<void> logoutWithRedirect() async {
    await logout();
    // Use the global navigator key to redirect to login
    App.navigatorKey.currentState?.pushNamedAndRemoveUntil('/login', (route) => false);
  }

  Future<String?> performRefresh(Dio dio) async {
    final refreshToken = await StorageService.instance.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      return null;
    }

    try {
      final response = await dio.post(
        '$_authPath/refresh',
        data: {'refreshToken': refreshToken},
        options: Options(headers: {'Authorization': ''}), // Clear auth header for refresh call
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'];
        final newToken = data['token'] as String? ?? data['accessToken'] as String? ?? '';
        final newRefreshToken = data['refreshToken'] as String?;
        
        if (newToken.isNotEmpty) {
          await StorageService.instance.saveTokens(
            token: newToken,
            refreshToken: newRefreshToken ?? refreshToken,
          );
          return newToken;
        }
      }
    } catch (e) {
      // Refresh failed
    }
    return null;
  }
}
