import 'dart:js_interop';

import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

class WebPushHelper {
  static const _serviceWorkerFile = 'firebase-messaging-sw.js';
  static const _serviceWorkerScope = '/firebase-cloud-messaging-push-scope';

  static Future<void> registerMessagingServiceWorker() async {
    final swContainer = web.window.navigator.serviceWorker;

    final swUrl = Uri.base.resolve(_serviceWorkerFile).toString();
    final options = web.RegistrationOptions(scope: _serviceWorkerScope);

    try {
      await swContainer.register(swUrl.toJS, options).toDart;
      debugPrint('[WebPushHelper] Registered $swUrl (scope: $_serviceWorkerScope)');
    } catch (e) {
      debugPrint('[WebPushHelper] SW registration failed: $e');
    }
  }

  /// Waits until the Firebase messaging service worker is active before FCM
  /// token registration. Required for background push on Android/iOS PWAs.
  static Future<void> ensureMessagingServiceWorkerReady() async {
    await registerMessagingServiceWorker();
    try {
      await web.window.navigator.serviceWorker.ready.toDart;
      debugPrint('[WebPushHelper] Messaging service worker ready');
    } catch (e) {
      debugPrint('[WebPushHelper] SW ready wait failed: $e');
    }
  }

  static Future<bool> isPermissionGranted() async {
    return web.Notification.permission == 'granted';
  }
}
