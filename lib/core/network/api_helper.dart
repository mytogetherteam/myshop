import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

enum ApiErrorType {
  network,
  server,
  validation,
  unauthorized,
  notFound,
  unknown,
}

class ApiException implements Exception {
  final String message;
  final String? details;
  final int? statusCode;
  final ApiErrorType type;

  ApiException({
    required this.message,
    this.details,
    this.statusCode,
    this.type = ApiErrorType.unknown,
  });

  factory ApiException.fromDioException(DioException e) {
    String message = 'An error occurred';
    String? details;
    int? statusCode = e.response?.statusCode;
    ApiErrorType type = ApiErrorType.unknown;

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        message = 'Connection timeout';
        type = ApiErrorType.network;
        break;
      case DioExceptionType.connectionError:
        message = 'No internet connection';
        type = ApiErrorType.network;
        break;
      case DioExceptionType.badResponse:
        statusCode = e.response?.statusCode;
        final msg = e.response?.data?['message'];
        details = msg is List ? msg.join('; ') : (msg ?? e.response?.data?['details']);
        switch (statusCode) {
          case 400:
            message = 'Bad request';
            type = ApiErrorType.validation;
            break;
          case 401:
            message = 'Unauthorized';
            type = ApiErrorType.unauthorized;
            break;
          case 403:
            message = 'Forbidden';
            type = ApiErrorType.unauthorized;
            break;
          case 404:
            message = 'Not found';
            type = ApiErrorType.notFound;
            break;
          case 500:
          case 502:
          case 503:
            message = 'Server error';
            type = ApiErrorType.server;
            break;
          default:
            message = details ?? 'Request failed';
        }
        break;
      case DioExceptionType.cancel:
        message = 'Request cancelled';
        break;
      default:
        message = e.message ?? 'Unknown error';
    }

    return ApiException(
      message: message,
      details: details,
      statusCode: statusCode,
      type: type,
    );
  }

  @override
  String toString() =>
      'ApiException: $message${details != null ? ' ($details)' : ''}';
}

class ApiResult<T> {
  final T? data;
  final ApiException? error;
  final bool success;

  const ApiResult.success(this.data) : success = true, error = null;

  const ApiResult.failure(this.error) : success = false, data = null;

  R when<R>({
    required R Function(T data) success,
    required R Function(ApiException error) failure,
  }) {
    if (data != null) {
      return success(data as T);
    } else if (error != null) {
      return failure(error!);
    }
    return failure(ApiException(message: 'Unknown error'));
  }
}

class ApiHelper {
  static ApiException handleError(Object error, {String? context}) {
    if (error is DioException) {
      final exception = ApiException.fromDioException(error);
      debugPrint(
        '[API Error${context != null ? ' - $context' : ''}] ${exception.message}${exception.details != null ? ': ${exception.details}' : ''} (Status: ${exception.statusCode})',
      );
      return exception;
    }
    final message = error.toString();
    debugPrint('[API Error${context != null ? ' - $context' : ''}] $message');
    return ApiException(message: message);
  }

  static bool isSuccess(dynamic response) {
    if (response == null) return false;
    if (response is Map) {
      return response['success'] == true && response['data'] != null;
    }
    return false;
  }

  static Map<String, dynamic>? extractData(dynamic response) {
    if (response is Map<String, dynamic>) {
      if (response['success'] == true && response['data'] != null) {
        return response['data'] as Map<String, dynamic>;
      }
    }
    return null;
  }

  static List<T>? extractList<T>(
    dynamic response,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    if (response is Map &&
        response['success'] == true &&
        response['data'] != null) {
      final data = response['data'];
      if (data is List) {
        return data.map((e) => fromJson(e as Map<String, dynamic>)).toList();
      } else if (data is Map && data['content'] != null) {
        return (data['content'] as List)
            .map((e) => fromJson(e as Map<String, dynamic>))
            .toList();
      }
    }
    return null;
  }
}
