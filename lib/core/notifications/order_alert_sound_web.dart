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
      await stopAlert();
    }
  }

  static Future<void> stopAlert() async {
    final audio = _audio;
    if (audio == null) return;

    audio.pause();
    audio.currentTime = 0;
    _activeOrderId = null;
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
