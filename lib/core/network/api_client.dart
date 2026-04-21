import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:my_shop/core/auth/auth_interceptor.dart';
import 'package:my_shop/core/network/shop_interceptor.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'dart:io';

class ApiClient {
  static const String apiPrefix = '/api/shop';
  
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late final Dio _dio;

  ApiClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: 'https://mytogetherapi-production.up.railway.app',
        connectTimeout: const Duration(seconds: 45),
        receiveTimeout: const Duration(seconds: 45),
        headers: {
          'Content-Type': 'application/json',
          'Accept': '*/*',
        },
      ),
    );

    // Auth interceptor: attaches Bearer token and handles 401/403 auto-refresh
    _dio.interceptors.add(AuthInterceptor(_dio));

    // Shop interceptor: attaches X-Shop-Id
    _dio.interceptors.add(ShopInterceptor());

    // Cache interceptor
    _dio.interceptors.add(DioCacheInterceptor(
      options: CacheOptions(
        store: MemCacheStore(),
        policy: CachePolicy.request,
        maxStale: const Duration(days: 7),
        priority: CachePriority.normal,
        keyBuilder: CacheOptions.defaultCacheKeyBuilder,
        allowPostMethod: false,
      ),
    ));

    // Retry logic for transient errors
    _dio.interceptors.add(InterceptorsWrapper(
      onError: (err, handler) async {
        if (_shouldRetry(err)) {
          try {
            final response = await _retry(err.requestOptions);
            return handler.resolve(response);
          } catch (e) {
            return handler.next(err);
          }
        }
        return handler.next(err);
      },
    ));

    // Secured Logging interceptor
    if (kDebugMode) {
      _dio.interceptors.add(LogInterceptor(
        requestHeader: true,
        requestBody: true,
        responseHeader: false,
        responseBody: true,
        logPrint: (object) {
          final logStr = object.toString();
          // Mask Authorization header and large base64 payloads
          if (logStr.contains('Authorization: Bearer')) {
            debugPrint('Authorization: Bearer [MASKED]');
          } else if (logStr.length > 1000 && logStr.contains('data:image')) {
            debugPrint('[Large Base64 Payload Omitted]');
          } else {
            debugPrint(logStr);
          }
        },
      ));
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
