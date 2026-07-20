import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

// ─── Channel IDs (must match NotificationService) ───────────────────────────
const String _kOrderChannelId = 'shop_order_alerts_channel_v10';
const String _kFgChannelId    = 'shop_foreground_service';
const int    _kOrderNotiId    = 99999;
const int    _kFgNotiId       = 888;

// ─── Keys stored in SharedPreferences ────────────────────────────────────────
const String _kPrefToken    = 'auth_token';    // adjust if your key differs
const String _kPrefBaseUrl  = 'base_url';      // optional: set at login time
const String _kPrefAlerted  = 'bg_alerted_orders'; // JSON list of alerted IDs

// ─── Default API base — override via SharedPreferences['base_url'] ───────────
const String _kDefaultBase = 'https://api.mytogether.org';

Future<void> initializeBackgroundService() async {
  if (!Platform.isAndroid) return;

  final service = FlutterBackgroundService();

  final FlutterLocalNotificationsPlugin plugin =
      FlutterLocalNotificationsPlugin();

  // Foreground-service status bar channel (silent)
  await plugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(const AndroidNotificationChannel(
        _kFgChannelId,
        'Foreground Service',
        description: 'Keeps the app alive to listen for orders',
        importance: Importance.low,
      ));

  // Order alert channel (loud + looping) — mirrors NotificationService
  await plugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(AndroidNotificationChannel(
        _kOrderChannelId,
        'Shop Important Notifications',
        description: 'New order alerts',
        importance: Importance.max,
        sound: const RawResourceAndroidNotificationSound('alert'),
        playSound: true,
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 1000, 1000]),
      ));

  // Call channel
  await plugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(const AndroidNotificationChannel(
        'shop_call_channel_v1',
        'Incoming Calls',
        description: 'This channel is used for incoming calls.',
        importance: Importance.max,
        sound: RawResourceAndroidNotificationSound('ringtone'),
        playSound: true,
        enableVibration: true,
      ));

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: false,
      isForegroundMode: true,
      notificationChannelId: _kFgChannelId,
      initialNotificationTitle: 'My Shop',
      initialNotificationContent: '🟢 Listening for orders...',
      foregroundServiceNotificationId: _kFgNotiId,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: false,
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
  );
}

// ─── Background isolate entry point ──────────────────────────────────────────
@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  service.on('stopService').listen((_) => service.stopSelf());

  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((_) => service.setAsForegroundService());
    service.on('setAsBackground').listen((_) => service.setAsBackgroundService());
  }

  final FlutterLocalNotificationsPlugin plugin =
      FlutterLocalNotificationsPlugin();
  await plugin.initialize(const InitializationSettings(
    android: AndroidInitializationSettings('@drawable/ic_notification'),
  ));

  // ── Heartbeat: update status-bar notification every minute ────────────────
  Timer.periodic(const Duration(minutes: 1), (_) async {
    if (service is AndroidServiceInstance &&
        await service.isForegroundService()) {
      service.setForegroundNotificationInfo(
        title: 'My Shop',
        content: '🟢 Online – ${_timestamp()}',
      );
    }
  });

  // ── Polling: check pending orders every 30 seconds ────────────────────────
  // This is the SAFETY NET when FCM is killed by battery optimisation on
  // Xiaomi / OPPO / Vivo / Samsung phones.
  Timer.periodic(const Duration(seconds: 30), (_) async {
    await _pollPendingOrders(plugin, service);
  });
}

// ─── Poll the API for un-acknowledged PENDING orders ─────────────────────────
Future<void> _pollPendingOrders(FlutterLocalNotificationsPlugin plugin, ServiceInstance service) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_kPrefToken);
    if (token == null || token.isEmpty) return; // not logged in

    final base = prefs.getString(_kPrefBaseUrl) ?? _kDefaultBase;
    final shopId = prefs.getInt('bg_shop_id');
    final shopIdStr = shopId?.toString() ?? '';
    
    // First, verify if the shop is still open/online
    final profileUri = Uri.parse('$base/api/shop/shop-profile');
    final profileRes = await http.get(profileUri, headers: {
      'Authorization': 'Bearer $token',
      if (shopIdStr.isNotEmpty) 'x-shop-id': shopIdStr,
    }).timeout(const Duration(seconds: 5));

    if (profileRes.statusCode == 200) {
      final profileBody = jsonDecode(profileRes.body);
      if (profileBody['success'] == true && profileBody['data'] != null) {
        final bool isOpen = profileBody['data']['isOpen'] == true;
        if (!isOpen) {
          // Shop has been auto-paused (or manually paused). Stop the background service!
          service.stopSelf();
          return;
        }
      }
    }

    final uri  = Uri.parse('$base/api/shop/orders?status=PENDING&size=5&page=1');

    final res = await http.get(uri, headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
      if (shopIdStr.isNotEmpty) 'x-shop-id': shopIdStr,
    }).timeout(const Duration(seconds: 10));


    if (res.statusCode != 200) return;

    final body    = jsonDecode(res.body);
    // Support both { data: [...] } and plain list
    final List<dynamic> orders =
        body is List ? body : (body['data'] ?? body['content'] ?? []);

    if (orders.isEmpty) return;

    // Load already-alerted IDs to avoid duplicate rings
    final alertedRaw = prefs.getString(_kPrefAlerted) ?? '[]';
    final List<String> alerted =
        List<String>.from(jsonDecode(alertedRaw));

    for (final order in orders) {
      final String id = order['id']?.toString() ?? '';
      if (id.isEmpty || alerted.contains(id)) continue;

      // New unacknowledged order found — ring the alert!
      await _showOrderAlert(plugin, id, order);
      alerted.add(id);
    }

    // Persist (keep last 50 to prevent unbounded growth)
    final trimmed = alerted.length > 50
        ? alerted.sublist(alerted.length - 50)
        : alerted;
    await prefs.setString(_kPrefAlerted, jsonEncode(trimmed));
  } catch (_) {
    // Silently ignore — network may be unavailable
  }
}

// ─── Show the loud looping order-alert notification ──────────────────────────
Future<void> _showOrderAlert(
  FlutterLocalNotificationsPlugin plugin,
  String orderId,
  Map<String, dynamic> order,
) async {
  final shopName  = order['shopName']  ?? order['shop_name']  ?? 'New Order';
  final totalStr  = order['totalPrice']?.toString() ??
                    order['total_price']?.toString() ?? '';
  final body      = totalStr.isNotEmpty ? 'Total: $totalStr' : 'Tap to view';

  final details = AndroidNotificationDetails(
    _kOrderChannelId,
    'Shop Important Notifications',
    channelDescription: 'New order alerts',
    importance: Importance.max,
    priority: Priority.high,
    sound: const RawResourceAndroidNotificationSound('alert'),
    playSound: true,
    enableVibration: true,
    vibrationPattern: Int64List.fromList([0, 1000, 1000]),
    additionalFlags: Int32List.fromList([4]), // FLAG_INSISTENT = loops sound
    fullScreenIntent: true,
    category: AndroidNotificationCategory.call,
    onlyAlertOnce: true,
  );

  await plugin.show(
    _kOrderNotiId,
    '🔔 $shopName',
    body,
    NotificationDetails(android: details),
    payload: orderId,
  );
}

String _timestamp() {
  final now = DateTime.now();
  return '${now.hour.toString().padLeft(2, '0')}:'
      '${now.minute.toString().padLeft(2, '0')}';
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  return true;
}


