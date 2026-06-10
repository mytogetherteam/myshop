import 'dart:io';

import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:my_shop/app.dart';
import 'package:my_shop/core/data/services/storage_service.dart';
import 'package:my_shop/core/network/api_client.dart';
import 'package:my_shop/core/network/api_helper.dart';
import 'package:my_shop/features/notifications/data/repositories/notification_repository.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // Resolved lazily so constructing the singleton on web (where Firebase is
  // not initialized) does not throw. All usages are guarded by `kIsWeb`.
  FirebaseMessaging get _fcm => FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const String _deviceTokensPath = '/api/admin/device-tokens';

  bool _isInitialized = false;
  String? _registeredToken;

  Future<void> initialize() async {
    if (_isInitialized || kIsWeb) return;

    // Initialize local notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings();
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        _handleNotificationClick(null);
      },
    );

    // Create high importance channel for Android
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'shop_important_notifications',
      'Shop Important Notifications',
      description: 'This channel is used for shop orders and alerts.',
      importance: Importance.high,
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        NotificationRepository().incrementCount();
        _showLocalNotification(message);
      } else if (message.data.isNotEmpty) {
        NotificationRepository().getUnreadCount();
        _showLocalNotification(message);
      }
    });

    // Handle background message clicks
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNotificationClick(message);
    });

    // Check if the app was opened from a terminated state via a notification
    try {
      RemoteMessage? initialMessage = await _fcm.getInitialMessage().timeout(
        const Duration(seconds: 2),
      );
      if (initialMessage != null) {
        _handleNotificationClick(initialMessage);
      }
    } catch (_) {}

    // Register token if already logged in
    if (await _isLoggedIn) {
      await registerDevice();
    }

    // Listen for token refreshes
    _fcm.onTokenRefresh.listen((newToken) async {
      if (!await _isLoggedIn) return;
      final previous = _registeredToken;
      if (previous != null && previous != newToken) {
        await _unregisterToken(previous);
      }
      await _sendTokenToServer(newToken);
    });

    _isInitialized = true;
  }

  Future<void> requestSystemPermission() async {
    if (kIsWeb) {
      await StorageService.instance.setNotificationHandled(true);
      return;
    }
    await _fcm.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    await StorageService.instance.setNotificationHandled(true);
    if (await _isLoggedIn) {
      await registerDevice();
    }
  }

  Future<void> registerDevice() async {
    if (kIsWeb) return;
    try {
      String? token = await _fcm.getToken().timeout(const Duration(seconds: 5));
      if (token != null) {
        await _sendTokenToServer(token);
      }
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
    }
  }

  /// Remove this device's FCM token from the backend (call on logout).
  Future<void> unregisterDevice() async {
    if (kIsWeb) return;

    String? token = _registeredToken;
    if (token == null || token.isEmpty) {
      try {
        token = await _fcm.getToken().timeout(const Duration(seconds: 3));
      } catch (_) {}
    }
    if (token == null || token.isEmpty) return;

    await _unregisterToken(token);
    _registeredToken = null;
  }

  Future<bool> _sendTokenToServer(String token) async {
    try {
      final response = await ApiClient().dio.post(
        _deviceTokensPath,
        data: {
          'token': token,
          if (_platform != null) 'platform': _platform,
        },
      );

      final ok = response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300;
      if (ok) {
        _registeredToken = token;
        debugPrint('[NotificationService] FCM token registered');
      }
      return ok;
    } on DioException catch (e) {
      ApiHelper.handleError(e, context: 'NotificationService.registerToken');
      return false;
    } catch (e) {
      ApiHelper.handleError(e, context: 'NotificationService.registerToken');
      return false;
    }
  }

  Future<void> _unregisterToken(String token) async {
    try {
      await ApiClient().dio.delete(
        _deviceTokensPath,
        data: {'token': token},
      );
      debugPrint('[NotificationService] FCM token unregistered');
    } on DioException catch (e) {
      ApiHelper.handleError(e, context: 'NotificationService.unregisterToken');
    } catch (e) {
      ApiHelper.handleError(e, context: 'NotificationService.unregisterToken');
    }
  }

  Future<bool> get _isLoggedIn async {
    final token = await StorageService.instance.getToken();
    return token != null && token.isNotEmpty;
  }

  String? get _platform {
    if (kIsWeb) return 'web';
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    return null;
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final String title = message.notification?.title ?? message.data['title'] ?? 'New Notification';
    final String body = message.notification?.body ?? message.data['body'] ?? 'You have a new update';

    const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'shop_important_notifications',
      'Shop Important Notifications',
      channelDescription: 'This channel is used for shop orders and alerts.',
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);
    await _localNotifications.show(
      message.hashCode,
      title,
      body,
      platformChannelSpecifics,
    );
  }

  void _handleNotificationClick(RemoteMessage? message) {
    // Navigate to notifications screen
    App.navigatorKey.currentState?.pushNamed('/notifications');
  }
}
