import 'dart:async';
import 'package:dio/dio.dart';
import 'package:my_shop/features/auth/data/services/auth_service.dart';
import 'package:my_shop/core/auth/jwt_utils.dart';

class QueuedRequest {
  final RequestOptions requestOptions;
  final RequestInterceptorHandler? handler;
  final ErrorInterceptorHandler? errorHandler;

  QueuedRequest({required this.requestOptions, this.handler, this.errorHandler});
}

class AuthInterceptor extends Interceptor {
  /// Auth routes that must not send a Bearer token (login, token refresh).
  /// Other `/auth/` routes (change-password, logout, delete-account) require auth.
  static const _publicAuthPaths = {
    '/api/shop/auth/login',
    '/api/shop/auth/refresh',
  };

  final Dio dio;
  bool _isRefreshing = false;
  Completer<String?>? _refreshCompleter;

  AuthInterceptor(this.dio);

  static bool _isPublicAuthPath(String path) {
    final normalized = path.split('?').first;
    return _publicAuthPaths.contains(normalized);
  }

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final authService = AuthService.instance;

    if (_isPublicAuthPath(options.path)) {
      handler.next(options);
      return;
    }

    final token = await authService.getAccessToken();

    if (token == null || token.isEmpty) {
      handler.next(options);
      return;
    }

    // Token မှန်ကန်မှု စစ်ဆေး (integrity check)
    if (!JwtUtils.validateTokenIntegrity(token)) {
      await authService.logoutWithRedirect();
      handler.reject(
        DioException(
          requestOptions: options,
          error: 'Session expired or invalid',
          type: DioExceptionType.cancel,
        ),
      );
      return;
    }

    // Token 60 second မပြည့်ခင် Proactively refresh လုပ်
    if (JwtUtils.isExpired(token, offsetSeconds: 60)) {
      try {
        final newToken = await _refreshToken();
        if (newToken != null) {
          options.headers['Authorization'] = 'Bearer $newToken';
        } else {
          // Refresh ဆိုင်ရာ fail ဖြစ်ရင် (401/403) logoutWithRedirect ကို auth_service ကပဲ handle လုပ်ပြီးသား
          handler.reject(
            DioException(
              requestOptions: options,
              error: 'Session expired or invalid',
              type: DioExceptionType.cancel,
            ),
          );
          return;
        }
      } catch (e) {
        // Network error during proactive refresh, proceed with old token for now
        options.headers['Authorization'] = 'Bearer $token';
      }
    } else {
      options.headers['Authorization'] = 'Bearer $token';
    }

    handler.next(options);
  }

  /// Token refresh ကို centralize လုပ်ထားတဲ့ method
  /// Multiple request တွေ တပြိုင်နက် request ဆိုရင် ပထမတစ်ခုကပဲ refresh လုပ်ပြီး
  /// ကျန်တာတွေ queue မှာ စောင့်ကြည့်တာပါ
  Future<String?> _refreshToken() async {
    if (_isRefreshing) {
      // Refresh လုပ်နေဆဲဆိုရင် completer ကို wait လုပ်ပါ
      return await _refreshCompleter!.future;
    }

    _isRefreshing = true;
    _refreshCompleter = Completer<String?>();

    try {
      final newToken = await AuthService.instance.performRefresh(dio);
      _refreshCompleter!.complete(newToken);
      if (newToken == null) {
        // Refresh token ကုန်သွားတာ - logout လုပ်ပေးပါ
        await AuthService.instance.logoutWithRedirect();
      }
      return newToken;
    } catch (e) {
      _refreshCompleter!.completeError(e);
      // DO NOT logout here, just pass the error (Network issue etc.)
      rethrow;
    } finally {
      _isRefreshing = false;
      _refreshCompleter = null;
    }
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final statusCode = err.response?.statusCode;
    final path = err.requestOptions.path;
    final isRetried = err.requestOptions.extra['is_retried'] == true;

    // 401 / 403 ဆိုရင် refresh ကြိုးစားပါ (တစ်ခါပဲ retry ပါ)
    if ((statusCode == 401 || statusCode == 403) && !_isPublicAuthPath(path) && !isRetried) {
      try {
        final newToken = await _refreshToken();
        if (newToken != null && newToken.isNotEmpty) {
          // Token အသစ်ရပြီ - Request ကို retry လုပ်ပါ
          final retryOptions = err.requestOptions;
          retryOptions.extra['is_retried'] = true;
          retryOptions.headers['Authorization'] = 'Bearer $newToken';
          final retryResponse = await dio.fetch(retryOptions);
          handler.resolve(retryResponse);
          return;
        } else {
          // Refresh မအောင်မြင် - logout ပြီးသားဖြစ်တဲ့အတွက် error ဆက်ပါ
          handler.next(err);
          return;
        }
      } catch (e) {
        handler.next(err);
        return;
      }
    }

    handler.next(err);
  }
}
