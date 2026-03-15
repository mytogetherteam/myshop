import 'package:dio/dio.dart';
import 'package:my_shop/features/auth/data/services/auth_service.dart';
import 'package:my_shop/core/auth/jwt_utils.dart';

class AuthInterceptor extends Interceptor {
  final Dio dio;
  bool _isRefreshing = false;

  AuthInterceptor(this.dio);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final authService = AuthService.instance;
    final isAuthPath = options.path.contains('/auth/');

    final token = await authService.getAccessToken();
    
    // Auto-logout if token is expired (and not an auth request)
    if (token != null && !isAuthPath && JwtUtils.isExpired(token, offsetSeconds: 5)) {
      await authService.logoutWithRedirect();
      handler.reject(
        DioException(
            requestOptions: options,
            error: 'Session expired',
            type: DioExceptionType.cancel),
      );
      return;
    }

    // PROACTIVE REFRESH
    if (token != null && !isAuthPath && JwtUtils.isExpired(token, offsetSeconds: 60)) {
      try {
        final newToken = await authService.performRefresh(dio);
        if (newToken != null) {
          options.headers['Authorization'] = 'Bearer $newToken';
        }
      } catch (e) {}
    }

    final currentToken = await authService.getAccessToken();
    if (currentToken != null && currentToken.isNotEmpty && !options.headers.containsKey('Authorization')) {
      options.headers['Authorization'] = 'Bearer $currentToken';
    }
    
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final statusCode = err.response?.statusCode;
    final path = err.requestOptions.path;
    final isAuthPath = path.contains('/auth/');

    // REFRESH LOGIC
    if ((statusCode == 401 || statusCode == 403) && !isAuthPath && !_isRefreshing) {
      _isRefreshing = true;
      try {
        final newToken = await AuthService.instance.performRefresh(dio);
        if (newToken != null && newToken.isNotEmpty) {
          final retryOptions = err.requestOptions;
          retryOptions.headers['Authorization'] = 'Bearer $newToken';
          final retryResponse = await dio.fetch(retryOptions);
          handler.resolve(retryResponse);
          return;
        } else {
          await AuthService.instance.logoutWithRedirect();
          handler.next(err);
          return;
        }
      } catch (e) {
        if (e is DioException) {
          final refreshStatus = e.response?.statusCode;
          if (refreshStatus == 401 || refreshStatus == 403) {
            await AuthService.instance.logoutWithRedirect();
          }
        }
        handler.next(err);
        return;
      } finally {
        _isRefreshing = false;
      }
    }

    // Auto-logout on 401/403 for non-auth endpoints if refresh failed or was already in progress
    if ((statusCode == 401 || statusCode == 403) && !isAuthPath) {
      await AuthService.instance.logoutWithRedirect();
      handler.next(err);
      return;
    }
    handler.next(err);
  }
}
