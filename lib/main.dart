import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:my_shop/core/notifications/notification_service.dart';
import 'package:my_shop/core/utils/app_version.dart';
import 'package:my_shop/core/localization/app_localizations.dart';
import 'app.dart';
import 'firebase_options.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (_) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
}

void main() async {
  GoogleFonts.config.allowRuntimeFetching = true;
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('[BOOT] Firebase init failed: $e');
  }

  try {
    await AppVersion.init();
  } catch (e) {
    debugPrint('[BOOT] AppVersion init failed: $e');
  }

  // Initialize notification service
  if (!kIsWeb) {
    NotificationService().initialize();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  try {
    await LocalizationService.instance.init();
  } catch (e) {
    debugPrint('[BOOT] LocalizationService init failed: $e');
  }

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const App());

  // Remove splash screen after first frame
  WidgetsBinding.instance.addPostFrameCallback((_) {
    FlutterNativeSplash.remove();
  });

  // Safety net: guarantee splash removal after max 4 seconds
  Future.delayed(const Duration(seconds: 4), () {
    FlutterNativeSplash.remove();
    debugPrint('[BOOT] Safety-net splash removal triggered.');
  });
}
