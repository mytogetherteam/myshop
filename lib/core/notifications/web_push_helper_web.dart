import 'dart:js_interop';

import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

class WebPushHelper {
  static Future<void> registerMessagingServiceWorker() async {
    final swContainer = web.window.navigator.serviceWorker;
    if (swContainer == null) {
      debugPrint('[WebPushHelper] Service workers not supported');
      return;
    }

    final swUrl = Uri.base.resolve('firebase-messaging-sw.js').toString();

    try {
      await swContainer.register(swUrl.toJS).toDart;
      debugPrint('[WebPushHelper] Registered $swUrl');
    } catch (e) {
      debugPrint('[WebPushHelper] SW registration failed: $e');
    }
  }

  static Future<bool> isPermissionGranted() async {
    return web.Notification.permission == 'granted';
  }
}
