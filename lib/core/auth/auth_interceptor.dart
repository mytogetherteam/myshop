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
  final Dio dio;
  bool _isRefreshing = false;
  final List<QueuedRequest> _pendingRequests = [];
  bool _refreshLock = false;

  AuthInterceptor(this.dio);

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final authService = AuthService.instance;
    final isAuthPath = options.path.contains('/auth/');

    final token = await authService.getAccessToken();

    if (token != null && !isAuthPath) {
      if (JwtUtils.isExpired(token, offsetSeconds: 5)) {
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
      }

      if (JwtUtils.isExpired(token, offsetSeconds: 60)) {
        try {
          if (!_isRefreshing) {
            _isRefreshing = true;
            final newToken = await authService.performRefresh(dio);
            _isRefreshing = false;
            if (newToken != null) {
              options.headers['Authorization'] = 'Bearer $newToken';
              _processPendingRequests(newToken);
            } else {
              _processPendingRequests(null);
            }
          } else {
            _pendingRequests.add(QueuedRequest(requestOptions: options, handler: handler));
            return;
          }
        } catch (e) {
          _isRefreshing = false;
          _processPendingRequests(null);
        }
      }
    }

    final currentToken = await authService.getAccessToken();
    if (currentToken != null &&
        currentToken.isNotEmpty &&
        !options.headers.containsKey('Authorization')) {
      options.headers['Authorization'] = 'Bearer $currentToken';
    }

    handler.next(options);
  }

  void _processPendingRequests(String? newToken) {
    for (final queued in _pendingRequests) {
      if (newToken != null) {
        queued.requestOptions.headers['Authorization'] = 'Bearer $newToken';
        if (queued.handler != null) {
          queued.handler!.next(queued.requestOptions);
        } else if (queued.errorHandler != null) {
          dio.fetch(queued.requestOptions).then(
            (response) => queued.errorHandler!.resolve(response),
            onError: (e) => queued.errorHandler!.next(e is DioException ? e : DioException(requestOptions: queued.requestOptions, error: e)),
          );
        }
      } else {
         final error = DioException(requestOptions: queued.requestOptions, error: 'Token refresh failed');
         if (queued.handler != null) {
            queued.handler!.reject(error);
         } else if (queued.errorHandler != null) {
            queued.errorHandler!.next(error);
         }
      }
    }
    _pendingRequests.clear();
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final statusCode = err.response?.statusCode;
    final path = err.requestOptions.path;
    final isAuthPath = path.contains('/auth/');

    if ((statusCode == 401 || statusCode == 403) &&
        !isAuthPath &&
        !_refreshLock) {
      _refreshLock = true;
      _isRefreshing = true;
      try {
        final newToken = await AuthService.instance.performRefresh(dio);
        if (newToken != null && newToken.isNotEmpty) {
          final retryOptions = err.requestOptions;
          retryOptions.headers['Authorization'] = 'Bearer $newToken';
          final retryResponse = await dio.fetch(retryOptions);
          _refreshLock = false;
          _isRefreshing = false;
          _processPendingRequests(newToken);
          handler.resolve(retryResponse);
          return;
        } else {
          _refreshLock = false;
          _isRefreshing = false;
          await AuthService.instance.logoutWithRedirect();
          handler.next(err);
          return;
        }
      } catch (e) {
        _refreshLock = false;
        _isRefreshing = false;
        if (e is DioException) {
          final refreshStatus = e.response?.statusCode;
          if (refreshStatus == 401 || refreshStatus == 403) {
            await AuthService.instance.logoutWithRedirect();
          }
        }
        handler.next(err);
        return;
      }
    }

    if (_isRefreshing) {
      _pendingRequests.add(QueuedRequest(requestOptions: err.requestOptions, errorHandler: handler));
      return;
    }

    if ((statusCode == 401 || statusCode == 403) && !isAuthPath) {
      _refreshLock = false;
      await AuthService.instance.logoutWithRedirect();
      handler.next(err);
      return;
    }
    handler.next(err);
  }
}
