import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

Future<void> initializeBackgroundService() async {
  if (!Platform.isAndroid) return;

  final service = FlutterBackgroundService();

  // Create the notification channel
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'shop_foreground_service',
    'Foreground Service',
    description: 'Keeps the app alive to listen for orders',
    importance: Importance.low, // low so it doesn't vibrate/sound constantly
  );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: false, // We will start it manually when user logs in or starts app while logged in
      isForegroundMode: true,
      notificationChannelId: 'shop_foreground_service',
      initialNotificationTitle: 'My Shop',
      initialNotificationContent: 'Listening for orders...',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: false,
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
  );
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  // Only available for flutter 3.0.0 and later
  DartPluginRegistrant.ensureInitialized();

  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });
  }

  // The service just needs to be running.
  // The Firebase background handler inside main.dart will still run normally
  // because the flutter engine is kept alive by this foreground service!
  Timer.periodic(const Duration(seconds: 10), (timer) async {
    // We just keep the timer alive to ensure the isolate doesn't die.
    // If we wanted to update the notification time we could use setForegroundNotificationInfo
  });
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  return true;
}
