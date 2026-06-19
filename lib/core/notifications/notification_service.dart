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
import 'package:my_shop/core/notifications/order_alert_sound.dart';
import 'package:my_shop/core/notifications/web_browser_notification.dart';
import 'package:my_shop/core/notifications/web_sw_message_listener.dart';
import 'package:my_shop/core/notifications/web_push_helper.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static void stopGlobalAlert() {
    OrderAlertSound.stopAlert();
  }

  static bool tryClaimOrderAlert(String orderId) {
    return OrderAlertCoordinator.tryClaimOrderAlert(orderId);
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
    if (_isInitialized) return;

    if (!kIsWeb) {
      // Initialize local notifications
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@drawable/ic_notification');
      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings();
      const InitializationSettings initializationSettings =
          InitializationSettings(
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
      const AndroidNotificationChannel orderChannel =
          AndroidNotificationChannel(
        'shop_order_alerts_channel_v2',
        'Shop Important Notifications',
        description: 'This channel is used for shop orders and alerts.',
        importance: Importance.max,
        sound: RawResourceAndroidNotificationSound('alert'),
        playSound: true,
      );
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(orderChannel);

      // Create a normal importance channel for Android (Other Updates)
      const AndroidNotificationChannel normalChannel =
          AndroidNotificationChannel(
        'shop_normal_alerts_channel_v1',
        'Shop Normal Notifications',
        description: 'This channel is used for normal shop updates.',
        importance: Importance.max,
        sound: RawResourceAndroidNotificationSound('normal_noti'),
        playSound: true,
      );
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(normalChannel);
    }

    if (kIsWeb) {
      await WebPushHelper.ensureMessagingServiceWorkerReady();
      OrderAlertSound.setupBackgroundAlertResume();

      WebServiceWorkerMessageListener.start((data) async {
        final type = data['type']?.toString();
        if (type != 'NEW_ORDER_ALERT') return;

        final orderId = data['orderId']?.toString();
        final title = data['title']?.toString();
        final body = data['body']?.toString();
        if (title != null && body != null) {
          await WebBrowserNotification.show(
            title: title,
            body: body,
            tag: orderId != null ? 'order-$orderId' : 'new-order',
            requireInteraction: true,
          );
        }
        await OrderAlertSound.handleServiceWorkerAlert(orderId: orderId);
      });
    }

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final String? type = message.data['type'];
      final String? subType = message.data['subType'];
      final bool isNewOrder = type == 'NEW_ORDER' || subType == 'PENDING_ORDER';

      if (isNewOrder) {
        NotificationRepository().incrementCount();
        if (kIsWeb) {
          _handleWebForegroundOrderAlert(message);
        }
        return;
      }

      if (message.notification != null) {
        NotificationRepository().incrementCount();
        if (kIsWeb) {
          _showWebNotification(message);
        } else {
          showLocalNotification(message);
        }
      } else if (message.data.isNotEmpty) {
        NotificationRepository().getUnreadCount();
        if (kIsWeb) {
          _showWebNotification(message);
        } else {
          showLocalNotification(message);
        }
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
    await ensurePushRegistration();

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

  /// Ensures the FCM service worker is active and the device token is registered.
  Future<void> ensurePushRegistration() async {
    if (!kIsWeb) {
      if (await _isLoggedIn) {
        await registerDevice();
      }
      return;
    }

    await WebPushHelper.ensureMessagingServiceWorkerReady();

    final settings = await _fcm.getNotificationSettings();
    final granted = settings.authorizationStatus ==
            AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;

    if (!granted) {
      debugPrint(
        '[NotificationService] Web push permission: ${settings.authorizationStatus}',
      );
      return;
    }

    if (await _isLoggedIn) {
      await registerDevice();
    }
  }

  Future<void> requestSystemPermission() async {
    if (kIsWeb) {
      await OrderAlertSound.prepareForUserInteraction();
      await _fcm.requestPermission();
      await StorageService.instance.setNotificationHandled(true);
      await ensurePushRegistration();
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
    try {
      if (kIsWeb) {
        await WebPushHelper.ensureMessagingServiceWorkerReady();
      }

      String? token;
      if (kIsWeb) {
        token = await _fcm.getToken(
          vapidKey: 'BC-crzKl9sm4dwrObVQhpICmgtx7l9MmuP8OG-8AZW-RvxGOUszZx8hKzWOy5ZuDOCcO_La4UbPNkDl9tsAX3RQ',
        ).timeout(const Duration(seconds: 10));
      } else {
        token = await _fcm.getToken().timeout(const Duration(seconds: 5));
      }
      if (token != null) {
        debugPrint('[NotificationService] FCM token obtained (${kIsWeb ? 'web' : 'native'})');
        await _sendTokenToServer(token);
      } else {
        debugPrint('[NotificationService] FCM token is null');
      }
    } catch (e) {
      debugPrint('[NotificationService] Error getting FCM token: $e');
    }
  }

  /// Remove this device's FCM token from the backend (call on logout).
  Future<void> unregisterDevice() async {

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
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      default:
        return null;
    }
  }

  Future<void> showLocalNotification(RemoteMessage message) async {
    if (kIsWeb) return;

    final String title =
        message.notification?.title ?? message.data['title'] ?? 'New Notification';
    final String body =
        message.notification?.body ?? message.data['body'] ?? 'You have a new update';

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
    try {
      await _localNotifications.show(
        message.hashCode,
        title,
        body,
        platformChannelSpecifics,
      );
    } catch (e) {
      debugPrint('Error showing local notification: $e');
    }
  }

  void _handleNotificationClick(RemoteMessage? message) async {
    if (message == null) return;

    final String? type = message.data['type'];
    final String? subType = message.data['subType'];
    final bool isNewOrder = type == 'NEW_ORDER' || subType == 'PENDING_ORDER';

    if (isNewOrder) {
      final orderIdStr = message.data['orderId']?.toString() ??
          message.data['order_id']?.toString();
      if (orderIdStr != null) {
        await _presentNewOrderAlert(orderIdStr);
      }
      return;
    }

    App.navigatorKey.currentState?.pushNamed('/notifications');
  }

  Future<void> _handleWebForegroundOrderAlert(RemoteMessage message) async {
    final orderId = message.data['orderId']?.toString() ??
        message.data['order_id']?.toString();
    final title =
        message.notification?.title ?? message.data['title'] ?? 'New Order';
    final body = message.notification?.body ??
        message.data['body'] ??
        'You have a new order waiting.';

    await WebBrowserNotification.show(
      title: title,
      body: body,
      tag: orderId != null ? 'order-$orderId' : 'new-order',
      requireInteraction: true,
    );

    await OrderAlertSound.playLoopingAlert(orderId: orderId);

    if (orderId != null) {
      await _presentNewOrderAlert(orderId);
    }
  }

  Future<void> _showWebNotification(RemoteMessage message) async {
    final title =
        message.notification?.title ?? message.data['title'] ?? 'New Notification';
    final body = message.notification?.body ??
        message.data['body'] ??
        'You have a new update.';

    await WebBrowserNotification.show(
      title: title,
      body: body,
      tag: message.messageId,
    );
  }

  Future<void> _presentNewOrderAlert(String orderIdStr) async {
    if (!tryClaimOrderAlert(orderIdStr)) {
      await OrderAlertSound.playLoopingAlert(orderId: orderIdStr);
      return;
    }

    BuildContext? context = App.navigatorKey.currentContext;
    var retries = 0;
    while (context == null && retries < 10) {
      await Future.delayed(const Duration(milliseconds: 500));
      context = App.navigatorKey.currentContext;
      retries++;
    }

    if (context == null) {
      await OrderAlertSound.playLoopingAlert(orderId: orderIdStr);
      return;
    }

    try {
      final orderData = await OrderService().getOrderDetail(orderIdStr);
      if (orderData == null) {
        await OrderAlertSound.playLoopingAlert(orderId: orderIdStr);
        return;
      }

      await OrderAlertSound.playLoopingAlert(orderId: orderIdStr);

      if (!context.mounted) return;

      await showDialog(
        context: context,
        barrierDismissible: true,
        builder: (dialogContext) => NewOrderDialog(
          order: orderData,
          onViewOrder: () {
            NotificationService.stopGlobalAlert();
            Navigator.pop(dialogContext);
            Navigator.push(
              dialogContext,
              PageRouteBuilder(
                settings: RouteSettings(name: 'order_detail_$orderIdStr'),
                pageBuilder: (context, animation, secondaryAnimation) =>
                    OrderDetailScreen(order: orderData),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                  const begin = Offset(1.0, 0.0);
                  const end = Offset.zero;
                  const curve = Curves.easeOut;
                  final tween = Tween(begin: begin, end: end)
                      .chain(CurveTween(curve: curve));
                  return SlideTransition(
                    position: animation.drive(tween),
                    child: child,
                  );
                },
              ),
            );
          },
        ),
      );
      NotificationService.stopGlobalAlert();
    } catch (e) {
      debugPrint('Failed to load order from notification: $e');
      await OrderAlertSound.playLoopingAlert(orderId: orderIdStr);
    }
  }
}
