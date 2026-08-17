import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:my_shop/core/network/api_client.dart';
import 'package:my_shop/core/network/websocket_service.dart';

/// Manages a WebRTC voice call from the SHOP side.
/// Supports two directions:
///   - Answerer (user-to-shop): user calls shop, shop answers (existing).
///   - Caller (shop-to-user): shop calls user, user answers (new).
class ShopCallSession {
  ShopCallSession._();
  static final ShopCallSession _instance = ShopCallSession._();
  factory ShopCallSession() => _instance;

  static const List<Map<String, dynamic>> _iceServers = [
    {
      'urls': 'stun:stun.relay.metered.ca:80',
    },
    {
      'urls': 'turn:sg.relay.metered.ca:80',
      'username': '1d85318ad9c95e3aa7c2a929',
      'credential': 'NSOr459yCOf4CMap',
    },
    {
      'urls': 'turn:sg.relay.metered.ca:80?transport=tcp',
      'username': '1d85318ad9c95e3aa7c2a929',
      'credential': 'NSOr459yCOf4CMap',
    },
    {
      'urls': 'turn:sg.relay.metered.ca:443',
      'username': '1d85318ad9c95e3aa7c2a929',
      'credential': 'NSOr459yCOf4CMap',
    },
    {
      'urls': 'turns:sg.relay.metered.ca:443?transport=tcp',
      'username': '1d85318ad9c95e3aa7c2a929',
      'credential': 'NSOr459yCOf4CMap',
    },
  ];

  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _remoteStream;
  StreamSubscription<Map<String, dynamic>>? _callSub;

  // Notifiers for UI
  final ValueNotifier<ShopCallState> state = ValueNotifier(ShopCallState.idle);
  final ValueNotifier<bool> isMuted = ValueNotifier(false);
  final ValueNotifier<bool> isSpeakerOn = ValueNotifier(false);

  // Call info
  String? _currentCallId;
  String? _callerName;       // Name of incoming caller (user-to-shop)
  String? _customerName;     // Name of customer being called (shop-to-user)
  String? _direction;        // 'incoming' | 'outgoing'
  Timer? _ringTimeout;

  // Callback when an incoming call arrives (to show the incoming call screen)
  void Function(String callId, String callerName)? onIncomingCall;
  // Callback when shop-to-user call is accepted by user (to navigate to active call)
  void Function(String callId, String customerName)? onOutgoingCallAccepted;
  // Callback when outgoing call was rejected/timed-out
  void Function()? onOutgoingCallEnded;

  final Dio _dio = ApiClient().dio;

  /// Call this once when the shop app starts to listen for call events.
  void startListening() {
    _callSub?.cancel();
    _callSub = WebSocketService().callUpdates.listen(_handleCallEvent);
  }

  void stopListening() {
    _callSub?.cancel();
    _callSub = null;
  }

  // ──────────────────────────────────────────────
  // SHOP ANSWERS (user-to-shop, existing)
  // ──────────────────────────────────────────────

  /// Shop accepts the incoming call.
  Future<void> acceptCall() async {
    if (_currentCallId == null) return;
    state.value = ShopCallState.connected;

    try {
      await _dio.post('/api/call/accept/$_currentCallId');
    } catch (e) {
      debugPrint('[ShopCallSession] acceptCall error: $e');
    }

    await _startWebRTCAsAnswerer();
  }

  /// Shop rejects the incoming call.
  Future<void> rejectCall() async {
    if (_currentCallId == null) return;
    try {
      await _dio.post('/api/call/reject/$_currentCallId');
    } catch (_) {}
    _cleanup();
    state.value = ShopCallState.idle;
  }

  // ──────────────────────────────────────────────
  // SHOP CALLS OUT (shop-to-user, new)
  // ──────────────────────────────────────────────

  /// Shop initiates a call to [userId]. Returns false if call fails to start.
  Future<bool> initiateCallToUser({required int userId, required String customerName}) async {
    if (state.value != ShopCallState.idle) return false;

    _customerName = customerName;
    _direction = 'outgoing';
    state.value = ShopCallState.calling;

    try {
      final resp = await _dio.post('/api/call/initiate-to-user/$userId');
      _currentCallId = resp.data['data']['callId'] as String?;
      if (_currentCallId == null) {
        state.value = ShopCallState.idle;
        return false;
      }

      // Timeout: user doesn't answer in 31s
      _ringTimeout = Timer(const Duration(seconds: 31), () {
        if (state.value == ShopCallState.calling) {
          state.value = ShopCallState.idle;
          onOutgoingCallEnded?.call();
          _cleanup();
        }
      });

      return true;
    } catch (e) {
      debugPrint('[ShopCallSession] initiateCallToUser error: $e');
      state.value = ShopCallState.idle;
      return false;
    }
  }

  // ──────────────────────────────────────────────
  // Shared
  // ──────────────────────────────────────────────

  /// Shop ends the active call.
  Future<void> endCall() async {
    if (_currentCallId == null) return;
    try {
      await _dio.post('/api/call/end/$_currentCallId');
    } catch (_) {}
    _cleanup();
    state.value = ShopCallState.idle;
  }

  void toggleMute() {
    final audioTracks = _localStream?.getAudioTracks() ?? [];
    for (final track in audioTracks) {
      track.enabled = !track.enabled;
    }
    isMuted.value = !isMuted.value;
  }

  Future<void> _handleCallEvent(Map<String, dynamic> event) async {
    final type = event['type'] as String?;
    final callId = event['callId'] as String?;

    switch (type) {
      // ── Incoming call from user ──
      case 'CALL_INCOMING':
        if (callId == null || state.value != ShopCallState.idle) return;
        _currentCallId = callId;
        _callerName = event['callerName'] as String? ?? 'Customer';
        _direction = 'incoming';
        state.value = ShopCallState.ringing;
        onIncomingCall?.call(callId, _callerName!);
        break;

      // ── User accepted shop's call (shop-to-user) ──
      case 'CALL_ACCEPTED':
        if (callId != _currentCallId || _direction != 'outgoing') return;
        _ringTimeout?.cancel();
        state.value = ShopCallState.connected;
        // Shop is now the offerer — start WebRTC and send offer
        await _startWebRTCAsOfferer();
        onOutgoingCallAccepted?.call(_currentCallId!, _customerName ?? 'Customer');
        break;

      // ── User rejected shop's call ──
      case 'CALL_REJECTED':
        if (callId != _currentCallId) return;
        _ringTimeout?.cancel();
        state.value = ShopCallState.idle;
        onOutgoingCallEnded?.call();
        _cleanup();
        break;

      // ── Timeout (no answer) ──
      case 'CALL_TIMEOUT':
        if (callId != _currentCallId) return;
        _ringTimeout?.cancel();
        state.value = ShopCallState.idle;
        onOutgoingCallEnded?.call();
        _cleanup();
        break;

      // ── SDP Offer from user (user-to-shop, shop is answerer) ──
      case 'CALL_OFFER':
        if (callId != _currentCallId) return;
        final sdp = event['sdp'] as String?;
        if (sdp == null) return;
        await _handleOffer(sdp);
        break;

      // ── SDP Answer from user (shop-to-user, shop is offerer) ──
      case 'CALL_ANSWER':
        if (callId != _currentCallId) return;
        final sdp = event['sdp'] as String?;
        if (sdp != null && _peerConnection != null) {
          await _peerConnection!.setRemoteDescription(
            RTCSessionDescription(sdp, 'answer'),
          );
        }
        break;

      // ── ICE candidate from either side ──
      case 'CALL_ICE':
        if (callId != _currentCallId) return;
        final candidateJson = event['candidate'] as String?;
        if (candidateJson != null && _peerConnection != null) {
          final c = json.decode(candidateJson) as Map<String, dynamic>;
          await _peerConnection!.addCandidate(RTCIceCandidate(
            c['candidate'] as String,
            c['sdpMid'] as String?,
            c['sdpMLineIndex'] as int?,
          ));
        }
        break;

      // ── Either side ended call ──
      case 'CALL_END':
        if (callId != _currentCallId) return;
        _ringTimeout?.cancel();
        if (_direction == 'outgoing') {
          onOutgoingCallEnded?.call();
        }
        _cleanup();
        state.value = ShopCallState.idle;
        break;
    }
  }

  /// Shop is Answerer (user-to-shop): sets up PC ready to receive offer.
  Future<void> _startWebRTCAsAnswerer() async {
    _peerConnection = await createPeerConnection({
      'iceServers': _iceServers,
      'sdpSemantics': 'unified-plan',
    });

    _localStream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': false,
    });

    for (final track in _localStream!.getTracks()) {
      await _peerConnection!.addTrack(track, _localStream!);
    }

    _peerConnection!.onTrack = (RTCTrackEvent event) {
      if (event.track.kind == 'audio' && event.streams.isNotEmpty) {
        _remoteStream = event.streams.first;
      }
    };

    _peerConnection!.onIceCandidate = (RTCIceCandidate candidate) async {
      if (_currentCallId == null) return;
      try {
        await _dio.post('/api/call/ice/$_currentCallId', data: {
          'candidate': json.encode({
            'candidate': candidate.candidate,
            'sdpMid': candidate.sdpMid,
            'sdpMLineIndex': candidate.sdpMLineIndex,
          }),
        });
      } catch (_) {}
    };
    // Offer will arrive via CALL_OFFER event — handled in _handleOffer
  }

  /// Shop is Offerer (shop-to-user): creates SDP offer and sends to user.
  Future<void> _startWebRTCAsOfferer() async {
    _peerConnection = await createPeerConnection({
      'iceServers': _iceServers,
      'sdpSemantics': 'unified-plan',
    });

    _localStream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': false,
    });

    for (final track in _localStream!.getTracks()) {
      await _peerConnection!.addTrack(track, _localStream!);
    }

    _peerConnection!.onTrack = (RTCTrackEvent event) {
      if (event.track.kind == 'audio' && event.streams.isNotEmpty) {
        _remoteStream = event.streams.first;
      }
    };

    _peerConnection!.onIceCandidate = (RTCIceCandidate candidate) async {
      if (_currentCallId == null) return;
      try {
        await _dio.post('/api/call/ice/$_currentCallId', data: {
          'candidate': json.encode({
            'candidate': candidate.candidate,
            'sdpMid': candidate.sdpMid,
            'sdpMLineIndex': candidate.sdpMLineIndex,
          }),
        });
      } catch (_) {}
    };

    final offer = await _peerConnection!.createOffer({'offerToReceiveAudio': true});
    await _peerConnection!.setLocalDescription(offer);

    try {
      await _dio.post('/api/call/offer/$_currentCallId', data: {
        'sdp': offer.sdp,
      });
    } catch (e) {
      debugPrint('[ShopCallSession] offer error: $e');
    }
  }

  Future<void> _handleOffer(String sdp) async {
    if (_peerConnection == null) return;
    await _peerConnection!.setRemoteDescription(
      RTCSessionDescription(sdp, 'offer'),
    );

    final answer = await _peerConnection!.createAnswer();
    await _peerConnection!.setLocalDescription(answer);

    try {
      await _dio.post('/api/call/answer/$_currentCallId', data: {
        'sdp': answer.sdp,
      });
    } catch (e) {
      debugPrint('[ShopCallSession] answer error: $e');
    }
  }

  void _cleanup() {
    _ringTimeout?.cancel();
    _ringTimeout = null;
    _peerConnection?.close();
    _peerConnection = null;
    _localStream?.getTracks().forEach((t) => t.stop());
    _localStream?.dispose();
    _localStream = null;

    _remoteStream?.getTracks().forEach((t) => t.stop());
    _remoteStream?.dispose();
    _remoteStream = null;

    _currentCallId = null;
    _callerName = null;
    _customerName = null;
    _direction = null;
    isMuted.value = false;
    // Re-start listening for next call
    startListening();
  }

  String? get currentCallerName => _callerName;
  String? get currentCustomerName => _customerName;
  String? get currentCallId => _currentCallId;
  bool get isOutgoing => _direction == 'outgoing';
}

enum ShopCallState { idle, ringing, calling, connected }
