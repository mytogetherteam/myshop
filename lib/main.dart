import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:my_shop/core/notifications/notification_service.dart';
import 'package:my_shop/core/utils/app_version.dart';
import 'package:my_shop/core/localization/app_localizations.dart';
import 'package:my_shop/core/theme/theme_service.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'app.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // Initialize NotificationService to create channels
  await NotificationService().initialize();
  
  final String? type = message.data['type'];
  if (type == 'ORDER_ACKNOWLEDGED') {
    final String? orderIdStr = message.data['orderId']?.toString() ?? message.data['order_id']?.toString();
    if (orderIdStr != null) {
      await NotificationService().cancelNotification(orderIdStr.hashCode);
    }
    return; // Do not show anything
  }

  // Manually show local notification to ensure sound plays even if data-only
  await NotificationService().showLocalNotification(message);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Enable Wakelock to keep the screen awake for this merchant app
  WakelockPlus.enable();

  // Firebase & FCM push notifications are not configured for web (no web
  // Firebase options / flutter_local_notifications has no web support), so we
  // skip them on web to allow the app to boot in the browser.
  if (!kIsWeb) {
    await Firebase.initializeApp();

    // Initialize notification service
    NotificationService().initialize();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  await AppVersion.init();

  await LocalizationService.instance.init();
  await ThemeService.instance.initialize();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Disable Google Fonts CDN — use locally bundled Poppins from assets/fonts/
  GoogleFonts.config.allowRuntimeFetching = false;

  runApp(const App());
}
