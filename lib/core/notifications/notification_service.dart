import 'dart:io';
import 'package:flutter/material.dart';

import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:my_shop/app.dart';
import 'package:my_shop/core/data/services/storage_service.dart';
import 'package:my_shop/core/network/api_client.dart';
import 'package:my_shop/core/network/api_helper.dart';
import 'package:my_shop/features/notifications/data/repositories/notification_repository.dart';
import 'package:my_shop/features/orders/data/services/order_service.dart';
import 'package:my_shop/features/orders/presentation/widgets/new_order_dialog.dart';
import 'package:my_shop/features/orders/presentation/screens/order_detail_screen.dart';
import 'package:audioplayers/audioplayers.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static AudioPlayer? globalAlertAudioPlayer;

  static void stopGlobalAlert() {
    globalAlertAudioPlayer?.stop();
    globalAlertAudioPlayer?.dispose();
    globalAlertAudioPlayer = null;
  }

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
        AndroidInitializationSettings('@drawable/ic_notification');
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

    // Create high importance channel for Android (New Orders)
    const AndroidNotificationChannel orderChannel = AndroidNotificationChannel(
      'shop_order_alerts_channel_v2',
      'Shop Important Notifications',
      description: 'This channel is used for shop orders and alerts.',
      importance: Importance.max,
      sound: RawResourceAndroidNotificationSound('alert'),
      playSound: true,
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(orderChannel);

    // Create a normal importance channel for Android (Other Updates)
    const AndroidNotificationChannel normalChannel = AndroidNotificationChannel(
      'shop_normal_alerts_channel_v1',
      'Shop Normal Notifications',
      description: 'This channel is used for normal shop updates.',
      importance: Importance.max,
      sound: RawResourceAndroidNotificationSound('normal_noti'),
      playSound: true,
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(normalChannel);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final String? type = message.data['type'];
      final String? subType = message.data['subType'];
      final bool isNewOrder = type == 'NEW_ORDER' || subType == 'PENDING_ORDER';

      // Skip showing system banner for new orders in the foreground, 
      // because MainNavigationScreen's WebSocket listener will show the NewOrderDialog
      // and play the alert sound. This prevents overlapping looping sounds.
      if (isNewOrder) {
        NotificationRepository().incrementCount();
        return;
      }

      if (message.notification != null) {
        NotificationRepository().incrementCount();
        showLocalNotification(message);
      } else if (message.data.isNotEmpty) {
        NotificationRepository().getUnreadCount();
        showLocalNotification(message);
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

  Future<void> showLocalNotification(RemoteMessage message) async {
    final String title = message.notification?.title ?? message.data['title'] ?? 'New Notification';
    final String body = message.notification?.body ?? message.data['body'] ?? 'You have a new update';

    final String? type = message.data['type'];
    final String? subType = message.data['subType'];
    final bool isNewOrder = type == 'NEW_ORDER' || subType == 'PENDING_ORDER';

    // Int32List.fromList([4]) sets FLAG_INSISTENT, which loops the sound until dismissed
    final AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      isNewOrder ? 'shop_order_alerts_channel_v2' : 'shop_normal_alerts_channel_v1',
      isNewOrder ? 'Shop Important Notifications' : 'Shop Normal Notifications',
      channelDescription: isNewOrder ? 'This channel is used for shop orders and alerts.' : 'This channel is used for normal shop updates.',
      importance: Importance.max,
      priority: Priority.high,
      sound: RawResourceAndroidNotificationSound(isNewOrder ? 'alert' : 'normal_noti'),
      playSound: true,
      additionalFlags: isNewOrder ? Int32List.fromList([4]) : null,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.call,
    );
    final DarwinNotificationDetails iosPlatformChannelSpecifics = DarwinNotificationDetails(
      sound: isNewOrder ? 'alert.mp3' : 'normal_noti.mp3',
      presentSound: true,
    );
    final NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iosPlatformChannelSpecifics,
    );
    await _localNotifications.show(
      message.hashCode,
      title,
      body,
      platformChannelSpecifics,
    );
  }

  void _handleNotificationClick(RemoteMessage? message) async {
    if (message == null) return;

    final String? type = message.data['type'];
    final String? subType = message.data['subType'];
    final bool isNewOrder = type == 'NEW_ORDER' || subType == 'PENDING_ORDER';

    if (isNewOrder) {
      final String? orderIdStr = message.data['orderId']?.toString() ?? message.data['order_id']?.toString();
      if (orderIdStr != null) {
        // Wait until navigator context is available using post-frame callback
        BuildContext? context = App.navigatorKey.currentContext;
        
        if (context == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _processOrderNotification(orderIdStr);
          });
        } else {
          _processOrderNotification(orderIdStr);
        }
      }
    } else {
      // Default: Navigate to notifications screen
      App.navigatorKey.currentState?.pushNamed('/notifications');
    }
  }

  void _processOrderNotification(String orderIdStr) async {
    final context = App.navigatorKey.currentContext;
    if (context == null) return;
    
    try {
      final orderData = await OrderService().getOrderDetail(orderIdStr);
      if (orderData != null) {
        // Play loop alert if needed since the notification sound might only play once
        NotificationService.globalAlertAudioPlayer = AudioPlayer();
        NotificationService.globalAlertAudioPlayer!.setReleaseMode(ReleaseMode.loop);
        NotificationService.globalAlertAudioPlayer!.play(AssetSource('alert/alert.mp3'));

        showDialog(
          context: context,
          barrierDismissible: true,
          builder: (context) => NewOrderDialog(
            order: orderData,
            onViewOrder: () {
              NotificationService.stopGlobalAlert();
              Navigator.pop(context);
              Navigator.push(
                context,
                PageRouteBuilder(
                  settings: RouteSettings(name: 'order_detail_$orderIdStr'),
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      OrderDetailScreen(order: orderData),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                    const begin = Offset(1.0, 0.0);
                    const end = Offset.zero;
                    const curve = Curves.easeOut;
                    var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                    return SlideTransition(position: animation.drive(tween), child: child);
                  },
                ),
              );
            },
          ),
        ).then((_) {
          NotificationService.stopGlobalAlert();
        });
      }
    } catch (e) {
      debugPrint('Failed to load order from notification: $e');
    }
  }
}
