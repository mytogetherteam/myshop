import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:my_shop/core/notifications/notification_service.dart';
import 'app.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase (safely)
  try {
    await Firebase.initializeApp();
    // Initialize notification service
    NotificationService().initialize();
  } catch (e) {
    debugPrint('Firebase/Notification initialization failed: $e');
  }
  
  if (!kIsWeb) {
    try {
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    } catch (_) {}
  }

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Disable Google Fonts CDN — use locally bundled Poppins from assets/fonts/
  // GoogleFonts.config.allowRuntimeFetching = false;

  runApp(const App());
}
