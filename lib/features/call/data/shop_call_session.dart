import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:my_shop/core/network/api_client.dart';
import 'package:my_shop/core/network/websocket_service.dart';

/// Manages a WebRTC voice call from the SHOP side.
/// Listens to STOMP call events and handles WebRTC as the answerer.
class ShopCallSession {
  ShopCallSession._();
  static final ShopCallSession _instance = ShopCallSession._();
  factory ShopCallSession() => _instance;

  static const List<Map<String, dynamic>> _iceServers = [
    {'urls': 'stun:stun.l.google.com:19302'},
    {'urls': 'stun:stun1.l.google.com:19302'},
    // Add Coturn TURN server here after AWS setup:
    // {
    //   'urls': 'turn:api.mytogether.org:3478',
    //   'username': 'mytogether',
    //   'credential': 'strongpassword123',
    // },
  ];

  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  StreamSubscription<Map<String, dynamic>>? _callSub;

  // Notifiers for UI
  final ValueNotifier<ShopCallState> state = ValueNotifier(ShopCallState.idle);
  final ValueNotifier<bool> isMuted = ValueNotifier(false);

  // Incoming call info
  String? _currentCallId;
  String? _callerName;

  // Callback when an incoming call arrives (to show the incoming call screen)
  void Function(String callId, String callerName)? onIncomingCall;

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

  /// Shop accepts the incoming call.
  Future<void> acceptCall() async {
    if (_currentCallId == null) return;
    state.value = ShopCallState.connected;

    try {
      await _dio.post('/api/call/accept/$_currentCallId');
    } catch (e) {
      debugPrint('[ShopCallSession] acceptCall error: $e');
    }

    await _startWebRTC();
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
      case 'CALL_INCOMING':
        if (callId == null) return;
        _currentCallId = callId;
        _callerName = event['callerName'] as String? ?? 'Customer';
        state.value = ShopCallState.ringing;
        onIncomingCall?.call(callId, _callerName!);
        break;

      case 'CALL_OFFER':
        if (callId != _currentCallId) return;
        final sdp = event['sdp'] as String?;
        if (sdp == null) return;
        await _handleOffer(sdp);
        break;

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

      case 'CALL_END':
        if (callId != _currentCallId) return;
        _cleanup();
        state.value = ShopCallState.idle;
        break;
    }
  }

  Future<void> _startWebRTC() async {
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

    // ICE candidates
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
    _callSub?.cancel();
    _callSub = null;
    _peerConnection?.close();
    _peerConnection = null;
    _localStream?.getTracks().forEach((t) => t.stop());
    _localStream?.dispose();
    _localStream = null;
    _currentCallId = null;
    _callerName = null;
    isMuted.value = false;
    // Re-start listening for next call
    startListening();
  }

  String? get currentCallerName => _callerName;
  String? get currentCallId => _currentCallId;
}

enum ShopCallState { idle, ringing, connected }
