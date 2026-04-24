import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:my_shop/core/network/api_client.dart';
import 'package:my_shop/features/auth/data/services/auth_service.dart';
import 'package:my_shop/app.dart';
import 'package:my_shop/features/notifications/data/repositories/notification_repository.dart';
import 'package:my_shop/core/data/services/storage_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  FirebaseMessaging? _fcm;
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    // Only skip messaging on web if Firebase is not properly initialized
    final bool isFirebaseAvailable = Firebase.apps.isNotEmpty;
    if (kIsWeb && !isFirebaseAvailable) {
      debugPrint('⚠️ Skipping NotificationService initialization on web: Firebase not configured.');
      _isInitialized = true;
      return;
    }

    if (isFirebaseAvailable) {
      _fcm = FirebaseMessaging.instance;
    }

    if (!kIsWeb) {
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
    }

    // Handle foreground messages
    if (isFirebaseAvailable) {
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        if (message.notification != null) {
          NotificationRepository().incrementCount();
          if (!kIsWeb) _showLocalNotification(message);
        } else if (message.data.isNotEmpty) {
          NotificationRepository().getUnreadCount();
          if (!kIsWeb) _showLocalNotification(message);
        }
      });

      // Handle background message clicks
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        _handleNotificationClick(message);
      });

      // Check if the app was opened from a terminated state via a notification
      try {
        RemoteMessage? initialMessage = await _fcm?.getInitialMessage().timeout(
          const Duration(seconds: 2),
        );
        if (initialMessage != null) {
          _handleNotificationClick(initialMessage);
        }
      } catch (_) {}
    }

    // Register token if already logged in
    if (isFirebaseAvailable && await AuthService.instance.isLoggedIn) {
      await registerDevice();
    }

    // Listen for token refreshes
    if (isFirebaseAvailable) {
      _fcm?.onTokenRefresh.listen((newToken) async {
        if (await AuthService.instance.isLoggedIn) {
          _sendTokenToServer(newToken);
        }
      });
    }

    _isInitialized = true;
  }

  Future<void> requestSystemPermission() async {
    if (_fcm == null) return;
    await _fcm!.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    await StorageService.instance.setNotificationHandled(true);
    if (await AuthService.instance.isLoggedIn) {
      await registerDevice();
    }
  }

  Future<void> registerDevice() async {
    if (_fcm == null) return;
    try {
      String? token = await _fcm!.getToken().timeout(const Duration(seconds: 5));
      if (token != null) {
        await _sendTokenToServer(token);
      }
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
    }
  }

  Future<void> _sendTokenToServer(String token) async {
    try {
      String deviceId = await _getDeviceId();
      await ApiClient().dio.post(
        '/api/shop/notifications/register-device',
        data: {
          'token': token,
          'deviceType': kIsWeb ? 'WEB' : (defaultTargetPlatform == TargetPlatform.android ? 'ANDROID' : 'IOS'),
          'deviceId': deviceId,
        },
      );
    } catch (e) {
      debugPrint('Error registering device token: $e');
    }
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

  Future<String> _getDeviceId() async {
    if (kIsWeb) {
      WebBrowserInfo webInfo = await _deviceInfo.webBrowserInfo;
      return webInfo.userAgent ?? 'web_device';
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      AndroidDeviceInfo androidInfo = await _deviceInfo.androidInfo;
      return androidInfo.id;
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      IosDeviceInfo iosInfo = await _deviceInfo.iosInfo;
      return iosInfo.identifierForVendor ?? 'unknown_ios_device';
    }
    return 'unknown_device';
  }

  void _handleNotificationClick(RemoteMessage? message) {
    // Navigate to notifications screen
    App.navigatorKey.currentState?.pushNamed('/notifications');
  }
}
