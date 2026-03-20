import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../models/notification_model.dart';

class NotificationRepository {
  static final NotificationRepository _instance = NotificationRepository._internal();
  factory NotificationRepository() => _instance;
  NotificationRepository._internal();

  final Dio _dio = ApiClient().dio;
  
  /// Reactive unread count for real-time UI updates
  final ValueNotifier<int> unreadCount = ValueNotifier<int>(0);

  Future<NotificationListResponse?> getNotifications({int page = 0, int size = 20}) async {
    try {
      final response = await _dio.get(
        '/api/shop/notifications',
        queryParameters: {
          'page': page,
          'size': size,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data['success'] == true && data['data'] != null) {
          return NotificationListResponse.fromJson(data['data']);
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
      return null;
    }
  }

  Future<int> getUnreadCount() async {
    try {
      debugPrint('🔍 [DEBUG] FETCHING UNREAD COUNT FROM NotificationRepository...');
      final response = await _dio.get('/api/shop/notifications/unread-count');
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data['success'] == true && data['data'] != null) {
          final count = data['data']['count'] as int;
          unreadCount.value = count;
          return count;
        }
      }
      return 0;
    } catch (e) {
      debugPrint('Error fetching unread count: $e');
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
      final response = await _dio.put('/api/shop/notifications/$id/read');
      if (response.statusCode == 200 && response.data['success'] == true) {
        decrementCount();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
      return false;
    }
  }

  Future<bool> markAllAsRead() async {
    try {
      final response = await _dio.put('/api/shop/notifications/read-all');
      if (response.statusCode == 200 && response.data['success'] == true) {
        unreadCount.value = 0;
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
      return false;
    }
  }
}
