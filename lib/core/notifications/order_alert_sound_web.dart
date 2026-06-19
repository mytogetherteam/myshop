import 'dart:async';
import 'dart:js_interop';

import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

/// Web/PWA alert audio via HTMLAudioElement — more reliable than audioplayers
/// on Safari and other mobile browsers.
class OrderAlertSound {
  OrderAlertSound._();

  static web.HTMLAudioElement? _audio;
  static String? _activeOrderId;
  static bool _webPrepared = false;
  static bool _visibilityHookInstalled = false;

  static const _pendingStorageKey = 'myshop_pending_order_alert';

  static bool get isPlaying =>
      _audio != null && !_audio!.paused && _audio!.currentTime > 0;

  static String get _alertSrc =>
      Uri.base.resolve('assets/assets/alert/alert.mp3').toString();

  static web.HTMLAudioElement _getOrCreateAudio() {
    _audio ??= web.HTMLAudioElement()
      ..src = _alertSrc
      ..loop = true
      ..preload = 'auto';
    return _audio!;
  }

  /// Must run during a user gesture (login tap, button press, etc.).
  static Future<void> prepareForUserInteraction() async {
    if (_webPrepared) return;

    try {
      final audio = _getOrCreateAudio();
      audio.volume = 0.01;
      await audio.play().toDart;
      audio.pause();
      audio.currentTime = 0;
      audio.volume = 1;
      _webPrepared = true;
      debugPrint('[OrderAlertSound] web audio unlocked');
    } catch (e) {
      debugPrint('[OrderAlertSound] web prepare failed: $e');
    }
  }

  /// Resume queued alerts when the user returns to the PWA tab/app.
  static void setupBackgroundAlertResume() {
    if (_visibilityHookInstalled) return;
    _visibilityHookInstalled = true;

    web.document.onvisibilitychange = (web.Event _) {
      if (web.document.visibilityState == 'visible') {
        unawaited(_playPendingAlertIfAny());
      }
    }.toJS;

    web.window.onfocus = (web.Event _) {
      unawaited(_playPendingAlertIfAny());
    }.toJS;

    unawaited(_playPendingAlertIfAny());
  }

  static void _queuePendingAlert(String? orderId) {
    final storage = web.window.sessionStorage;
    storage.setItem(_pendingStorageKey, orderId ?? 'new');
    debugPrint('[OrderAlertSound] queued pending alert: $orderId');
  }

  static String? _takePendingAlert() {
    final storage = web.window.sessionStorage;
    final pending = storage.getItem(_pendingStorageKey);
    if (pending == null || pending.isEmpty) return null;
    storage.removeItem(_pendingStorageKey);
    return pending == 'new' ? null : pending;
  }

  static bool get _hasPendingAlert {
    final pending = web.window.sessionStorage.getItem(_pendingStorageKey);
    return pending != null && pending.isNotEmpty;
  }

  static Future<void> _playPendingAlertIfAny() async {
    if (web.document.visibilityState != 'visible') return;
    if (!_hasPendingAlert) return;

    final orderId = _takePendingAlert();
    await playLoopingAlert(orderId: orderId);
  }

  /// Called when the service worker posts a new-order alert while the app may
  /// be in the background.
  static Future<void> handleServiceWorkerAlert({String? orderId}) async {
    if (web.document.visibilityState == 'visible' && !web.document.hidden) {
      await playLoopingAlert(orderId: orderId);
      return;
    }

    _queuePendingAlert(orderId);
  }

  static Future<void> playLoopingAlert({String? orderId}) async {
    if (orderId != null && orderId == _activeOrderId && isPlaying) {
      return;
    }

    _activeOrderId = orderId;

    try {
      final audio = _getOrCreateAudio();
      audio.loop = true;
      audio.volume = 1;
      audio.currentTime = 0;

      if (!_webPrepared) {
        await prepareForUserInteraction();
      }

      await audio.play().toDart;
      debugPrint('[OrderAlertSound] web alert playing');
    } catch (e) {
      debugPrint('[OrderAlertSound] web play error: $e');
      _queuePendingAlert(orderId);
      await stopAlert();
    }
  }

  static Future<void> stopAlert() async {
    final audio = _audio;
    if (audio == null) return;

    audio.pause();
    audio.currentTime = 0;
    _activeOrderId = null;
    web.window.sessionStorage.removeItem(_pendingStorageKey);
  }
}

/// Prevents duplicate dialogs when WebSocket and FCM fire for the same order.
class OrderAlertCoordinator {
  OrderAlertCoordinator._();

  static final Set<String> _claimedOrderIds = {};

  static bool tryClaimOrderAlert(String orderId) {
    if (_claimedOrderIds.contains(orderId)) return false;
    _claimedOrderIds.add(orderId);
    Future.delayed(const Duration(seconds: 45), () {
      _claimedOrderIds.remove(orderId);
    });
    return true;
  }
}
