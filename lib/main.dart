import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:my_shop/core/notifications/notification_service.dart';
import 'package:my_shop/core/splash/branded_splash.dart';
import 'package:my_shop/core/utils/app_version.dart';
import 'package:my_shop/core/localization/app_localizations.dart';
import 'package:my_shop/core/theme/theme_service.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:my_shop/core/services/background_service.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:my_shop/features/auth/data/services/auth_service.dart';
import 'dart:io';
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
      await NotificationService().cancelNotification(99999);
    }
    return; // Do not show anything
  }

  if (type == 'CALL_INCOMING') {
    // Show a high priority local notification for incoming call
    await NotificationService().showLocalNotification(message);
    return;
  }

  // Manually show local notification to ensure sound plays even if data-only
  if (message.notification == null) {
    await NotificationService().showLocalNotification(message);
  }
}

void main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  
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
    
    // Initialize Foreground background service
    await initializeBackgroundService();
    if (await AuthService.instance.isLoggedIn) {
      FlutterBackgroundService().startService();
    }
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

  bool isJailbroken = false;
  if (!kIsWeb && Platform.isAndroid) {
    try {
      // Pure-Dart root detection — no native .so needed.
      // Checks for common root binaries / Magisk markers.
      const rootPaths = [
        '/system/app/Superuser.apk',
        '/sbin/su',
        '/system/bin/su',
        '/system/xbin/su',
        '/data/local/xbin/su',
        '/data/local/bin/su',
        '/system/sd/xbin/su',
        '/system/bin/failsafe/su',
        '/data/local/su',
        '/su/bin/su',
        '/data/adb/magisk',
        '/sbin/.magisk',
      ];
      for (final path in rootPaths) {
        if (await File(path).exists()) {
          isJailbroken = true;
          break;
        }
      }
    } catch (_) {}
  }

  if (isJailbroken) {
    FlutterNativeSplash.remove();
    runApp(
      const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Text(
                'Security Violation: This app cannot run on jailbroken or rooted devices for your security.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Colors.red, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ),
    );
    return;
  }

  // Disable Google Fonts CDN — use locally bundled Poppins from assets/fonts/
  GoogleFonts.config.allowRuntimeFetching = false;

  debugPrint('[BOOT] Prefetching Splash banner...');
  try {
    await BrandedSplash.prefetch().timeout(const Duration(seconds: 6));
  } catch (e) {
    debugPrint('[BOOT] Splash banner prefetch timed out/failed: $e');
  }

  // If no remote splash, drop native splash before first frame of App.
  if (!BrandedSplash.hasSplash) {
    FlutterNativeSplash.remove();
  }

  runApp(const App());
}
