import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Coordinates looping new-order alert audio across WebSocket, FCM, and taps.
class OrderAlertSound {
  OrderAlertSound._();

  static const _assetPath = 'alert/alert.mp3';

  static AudioPlayer? _player;
  static String? _activeOrderId;
  static bool _webPrepared = false;

  static bool get isPlaying => _player != null;

  static Future<void> prepareForUserInteraction() async {
    if (!kIsWeb || _webPrepared) return;

    try {
      final warmUp = AudioPlayer();
      await warmUp.setVolume(1);
      await warmUp.play(AssetSource(_assetPath));
      await warmUp.stop();
      await warmUp.dispose();
      _webPrepared = true;
    } catch (e) {
      debugPrint('[OrderAlertSound] web prepare failed: $e');
    }
  }

  static Future<void> playLoopingAlert({String? orderId}) async {
    if (orderId != null &&
        orderId == _activeOrderId &&
        _player != null &&
        isPlaying) {
      return;
    }

    await stopAlert();
    _activeOrderId = orderId;

    try {
      if (kIsWeb && !_webPrepared) {
        await prepareForUserInteraction();
      }

      _player = AudioPlayer();
      await _player!.setReleaseMode(ReleaseMode.loop);
      await _player!.setVolume(1);
      await _player!.play(AssetSource(_assetPath));
    } catch (e) {
      debugPrint('[OrderAlertSound] play error: $e');
      await stopAlert();
    }
  }

  static Future<void> stopAlert() async {
    await _player?.stop();
    await _player?.dispose();
    _player = null;
    _activeOrderId = null;
  }

  static void setupBackgroundAlertResume() {}

  static Future<void> handleServiceWorkerAlert({String? orderId}) async {
    await playLoopingAlert(orderId: orderId);
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
