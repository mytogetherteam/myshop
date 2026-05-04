import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:my_shop/core/auth/auth_interceptor.dart';
import 'package:my_shop/core/config/env_config.dart';
import 'package:my_shop/core/network/certificate_pinning_interceptor.dart';
import 'package:my_shop/core/network/shop_interceptor.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'dart:io';

class ApiClient {
  static const String apiPrefix = '/api/shop';

  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  static final MemCacheStore cacheStore = MemCacheStore();
  static final CacheOptions cacheOptions = CacheOptions(
    store: cacheStore,
    policy: CachePolicy.request,
    maxStale: const Duration(hours: 1),
    priority: CachePriority.normal,
    keyBuilder: CacheOptions.defaultCacheKeyBuilder,
    allowPostMethod: false,
  );

  late final Dio _dio;
  int _retryCount = 0;
  static const int _maxRetries = 3;

  ApiClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: EnvConfig.apiBaseUrl,
        connectTimeout: EnvConfig.connectTimeout,
        receiveTimeout: EnvConfig.receiveTimeout,
        headers: {'Content-Type': 'application/json', 'Accept': '*/*'},
      ),
    );

    _dio.interceptors.add(AuthInterceptor(_dio));

    _dio.interceptors.add(CertificatePinningInterceptor());

    _dio.interceptors.add(ShopInterceptor());

    // _dio.interceptors.add(
    //   DioCacheInterceptor(options: cacheOptions),
    // );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onError: (err, handler) async {
          if (_shouldRetry(err)) {
            try {
              _retryCount++;
              if (_retryCount <= _maxRetries) {
                await Future.delayed(Duration(seconds: _retryCount));
                final response = await _retry(err.requestOptions);
                _retryCount = 0;
                return handler.resolve(response);
              }
            } catch (e) {
              _retryCount = 0;
            }
          }
          _retryCount = 0;
          return handler.next(err);
        },
      ),
    );

    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(
          requestHeader: true,
          requestBody: true,
          responseHeader: false,
          responseBody: true,
          logPrint: (object) {
            final logStr = object.toString();
            if (logStr.contains('Authorization: Bearer')) {
              debugPrint('Authorization: Bearer [MASKED]');
            } else if (logStr.length > 1000 && logStr.contains('data:image')) {
              debugPrint('[Large Base64 Payload Omitted]');
            } else {
              debugPrint(logStr);
            }
          },
        ),
      );
    }
  }

  bool _shouldRetry(DioException err) {
    return err.type != DioExceptionType.cancel &&
        err.type != DioExceptionType.badResponse &&
        (err.error is SocketException ||
            err.type == DioExceptionType.connectionTimeout ||
            err.type == DioExceptionType.sendTimeout ||
            err.type == DioExceptionType.receiveTimeout);
  }

  Future<Response> _retry(RequestOptions requestOptions) {
    final options = Options(
      method: requestOptions.method,
      headers: requestOptions.headers,
    );
    return _dio.request(
      requestOptions.path,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      options: options,
    );
  }

  Dio get dio => _dio;
}
