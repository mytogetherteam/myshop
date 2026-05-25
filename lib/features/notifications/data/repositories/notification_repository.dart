import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:my_shop/core/network/api_client.dart';
import 'package:my_shop/core/network/api_helper.dart';
import '../models/notification_model.dart';

class NotificationRepository {
  static final NotificationRepository _instance =
      NotificationRepository._internal();
  factory NotificationRepository() => _instance;
  NotificationRepository._internal();

  final Dio _dio = ApiClient().dio;

  final ValueNotifier<int> unreadCount = ValueNotifier<int>(0);

  Future<NotificationListResponse?> getNotifications({
    int page = 0,
    int size = 20,
  }) async {
    try {
      final response = await _dio.get(
        '/api/notifications',
        queryParameters: {'page': page, 'size': size},
      );

      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300 &&
          response.data != null) {
        final data = response.data;
        if (data['success'] == true && data['data'] != null) {
          return NotificationListResponse.fromJson(data['data']);
        }
      }
      return null;
    } on DioException catch (e) {
      ApiHelper.handleError(
        e,
        context: 'NotificationRepository.getNotifications',
      );
      return null;
    } catch (e) {
      ApiHelper.handleError(
        e,
        context: 'NotificationRepository.getNotifications',
      );
      return null;
    }
  }

  Future<int> getUnreadCount() async {
    try {
      debugPrint('Fetching unread count from API...');
      final response = await _dio.get('/api/notifications/unread-count');
      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300 &&
          response.data != null) {
        final data = response.data;
        if (data['success'] == true && data['data'] != null) {
          final count = data['data']['count'] as int;
          unreadCount.value = count;
          return count;
        }
      }
      return 0;
    } on DioException catch (e) {
      ApiHelper.handleError(
        e,
        context: 'NotificationRepository.getUnreadCount',
      );
      return 0;
    } catch (e) {
      ApiHelper.handleError(
        e,
        context: 'NotificationRepository.getUnreadCount',
      );
      return 0;
    }
  }

  void incrementCount() {
    unreadCount.value++;
  }

  void decrementCount() {
    if (unreadCount.value > 0) unreadCount.value--;
  }

  void setUnreadCount(int count) {
    unreadCount.value = count;
  }

  Future<bool> markAsRead(int id) async {
    try {
      final response = await _dio.put('/api/notifications/$id/read');
      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300 &&
          response.data['success'] == true) {
        decrementCount();
        return true;
      }
      return false;
    } on DioException catch (e) {
      ApiHelper.handleError(e, context: 'NotificationRepository.markAsRead');
      return false;
    } catch (e) {
      ApiHelper.handleError(e, context: 'NotificationRepository.markAsRead');
      return false;
    }
  }

  Future<bool> markAllAsRead() async {
    try {
      final response = await _dio.put('/api/notifications/read-all');
      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300 &&
          response.data['success'] == true) {
        unreadCount.value = 0;
        return true;
      }
      return false;
    } on DioException catch (e) {
      ApiHelper.handleError(e, context: 'NotificationRepository.markAllAsRead');
      return false;
    } catch (e) {
      ApiHelper.handleError(e, context: 'NotificationRepository.markAllAsRead');
      return false;
    }
  }
}
