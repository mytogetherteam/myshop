import 'package:flutter/foundation.dart';
import 'package:my_shop/core/network/api_client.dart';
import 'package:my_shop/features/notifications/data/models/notification_model.dart';

class NotificationService {
  static const String _basePath = '/api/shop/notifications';

  Future<NotificationListResponse?> getNotifications({int page = 0, int size = 20}) async {
    try {
      final response = await ApiClient().dio.get(
        _basePath,
        queryParameters: {
          'page': page,
          'size': size,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true && data['data'] != null) {
          return NotificationListResponse.fromJson(data['data']);
        }
      }
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
    }
    return null;
  }

  Future<int> getUnreadCount() async {
    try {
      final response = await ApiClient().dio.get('$_basePath/unread-count');
      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true && data['data'] != null) {
          return data['data'] as int;
        }
      }
    } catch (e) {
      debugPrint('Error fetching unread count: $e');
    }
    return 0;
  }

  Future<bool> markAsRead(int id) async {
    try {
      final response = await ApiClient().dio.put('$_basePath/$id/read');
      return response.statusCode == 200 && response.data['success'] == true;
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
      return false;
    }
  }

  Future<bool> markAllAsRead() async {
    try {
      final response = await ApiClient().dio.put('$_basePath/read-all');
      return response.statusCode == 200 && response.data['success'] == true;
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
      return false;
    }
  }

  Future<bool> registerDeviceToken(String token, {String deviceType = 'ANDROID'}) async {
    try {
      final response = await ApiClient().dio.post(
        '$_basePath/register-device',
        data: {
          'token': token,
          'deviceType': deviceType,
        },
      );
      return response.statusCode == 200 && response.data['success'] == true;
    } catch (e) {
      debugPrint('Error registering device token: $e');
      return false;
    }
  }
}
