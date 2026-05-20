import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import 'package:my_shop/features/auth/data/services/auth_service.dart';
import 'package:my_shop/core/config/env_config.dart';

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  void _log(String message) {
    if (kDebugMode) {
      debugPrint(message);
    }
  }

  StompClient? _stompClient;
  bool get isConnected => _stompClient?.connected ?? false;

  final ValueNotifier<bool> connectionStatus = ValueNotifier<bool>(false);

  final StreamController<Map<String, dynamic>> _orderUpdateController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get orderUpdates =>
      _orderUpdateController.stream;

  bool _isConnecting = false;
  bool _shouldReconnect = true;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  Timer? _reconnectTimer;

  void connect({bool force = false}) async {
    if (_isConnecting && !force) return;

    if (isConnected && !force) return;

    if (_stompClient != null) {
      if (force) {
        _stompClient?.deactivate();
        _stompClient = null;
      } else {
        _stompClient?.activate();
        return;
      }
    }

    _isConnecting = true;
    _log('⏳ [WS] Connecting to WebSocket...');

    final token = await AuthService.instance.getAccessToken();
    if (token == null || token.isEmpty) {
      _isConnecting = false;
      return;
    }

    _stompClient = StompClient(
      config: StompConfig(
        url: EnvConfig.wsUrl,
        onConnect: onConnect,
        beforeConnect: () async {},
        onWebSocketError: (dynamic error) {
          _isConnecting = false;
          connectionStatus.value = false;
          _log('🚨 [WS] Error: $error');
          _scheduleReconnect();
        },
        onDebugMessage: (String message) => _log('⚙️ [WS] Debug: $message'),
        stompConnectHeaders: {'Authorization': 'Bearer $token'},
        onStompError: (frame) => _log('💥 [WS] Stomp Error: ${frame.body}'),
        onDisconnect: (frame) {
          connectionStatus.value = false;
          _log('🔌 [WS] Disconnected');
          _scheduleReconnect();
        },
        heartbeatOutgoing: const Duration(milliseconds: 10000),
        heartbeatIncoming: const Duration(milliseconds: 10000),
      ),
    );

    _stompClient?.activate();
  }

  void _scheduleReconnect() {
    if (!_shouldReconnect) return;
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      _log('🚫 [WS] Max reconnection attempts reached');
      return;
    }

    _reconnectAttempts++;
    final delay = Duration(seconds: _reconnectAttempts * 2);

    _log(
      '🔄 [WS] Scheduling reconnection in ${delay.inSeconds}s (attempt $_reconnectAttempts/$_maxReconnectAttempts)',
    );

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, () {
      connect(force: true);
    });
  }

  void onConnect(dynamic frame) async {
    _isConnecting = false;
    _reconnectAttempts = 0;
    connectionStatus.value = true;
    _log('✨ [WS] Connected Successfully');

    final token = await AuthService.instance.getAccessToken();
    final headers = {if (token != null) 'Authorization': 'Bearer $token'};

    const destination = '/user/queue/shop-order-updates';

    _stompClient?.subscribe(
      destination: destination,
      headers: {...headers, 'receipt': 'rcpt-shop-order-updates'},
      callback: (StompFrame frame) {
        if (frame.body == null) return;
        try {
          final Map<String, dynamic> raw = json.decode(frame.body!);
          final String type = raw['type'] ?? 'UNKNOWN';

          if (type == 'MENU_ITEM_UPDATE') {
            return; // Shop app currently doesn't need to react to its own menu updates from other instances
          }

          final String orderId = raw['orderId']?.toString() ?? 'unknown';
          final String status =
              raw['order']?['status'] ?? raw['status'] ?? 'unknown';

          _log('📥 [WS] Message: $type | Order: $orderId | Status: $status');
          _orderUpdateController.add(raw);
        } catch (e) {
          _log('⚠️ Error parsing socket message: $e');
        }
      },
    );
  }

  void disconnect() {
    _shouldReconnect = false;
    _reconnectTimer?.cancel();
    _stompClient?.deactivate();
    _stompClient = null;
    connectionStatus.value = false;
  }
}
