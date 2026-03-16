import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import 'package:my_shop/features/auth/data/services/auth_service.dart';

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  StompClient? _stompClient;
  bool get isConnected => _stompClient?.connected ?? false;
  
  final ValueNotifier<bool> connectionStatus = ValueNotifier<bool>(false);

  final StreamController<Map<String, dynamic>> _orderUpdateController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get orderUpdates => _orderUpdateController.stream;

  bool _isConnecting = false;

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
    debugPrint('⏳ [WS] Connecting to WebSocket...');

    final token = await AuthService.instance.getAccessToken();
    if (token == null || token.isEmpty) {
      _isConnecting = false;
      return;
    }

    _stompClient = StompClient(
      config: StompConfig(
        url: 'wss://mytogetherapi-production.up.railway.app/ws/websocket',
        onConnect: onConnect,
        beforeConnect: () async {},
        onWebSocketError: (dynamic error) {
          _isConnecting = false;
          connectionStatus.value = false;
          debugPrint('🚨 [WS] Error: $error');
        },
        onDebugMessage: (String message) => debugPrint('⚙️ [WS] Debug: $message'),
        stompConnectHeaders: {
          'Authorization': 'Bearer $token',
        },
        onStompError: (frame) => debugPrint('💥 [WS] Stomp Error: ${frame.body}'),
        onDisconnect: (frame) {
          connectionStatus.value = false;
          debugPrint('🔌 [WS] Disconnected');
        },
        heartbeatOutgoing: const Duration(milliseconds: 10000),
        heartbeatIncoming: const Duration(milliseconds: 10000),
      ),
    );

    _stompClient?.activate();
  }

  void onConnect(dynamic frame) async {
    _isConnecting = false;
    connectionStatus.value = true;
    debugPrint('✨ [WS] Connected Successfully');

    final token = await AuthService.instance.getAccessToken();
    final headers = {
      if (token != null) 'Authorization': 'Bearer $token',
    };

    // Canonical shop order-update topic
    const destination = '/user/queue/shop-order-updates';

    _stompClient?.subscribe(
      destination: destination,
      headers: {
        ...headers,
        'receipt': 'rcpt-shop-order-updates',
      },
      callback: (StompFrame frame) {
        if (frame.body == null) return;
        try {
          final Map<String, dynamic> raw = json.decode(frame.body!);
          final String type = raw['type'] ?? 'UNKNOWN';
          final String orderId = raw['orderId']?.toString() ?? 'unknown';
          final String status = raw['order']?['status'] ?? raw['status'] ?? 'unknown';
          
          debugPrint('📥 [WS] Message: $type | Order: $orderId | Status: $status');
          _orderUpdateController.add(raw);
        } catch (e) {
          debugPrint('⚠️ Error parsing socket message: $e');
        }
      },
    );
  }

  void disconnect() {
    _stompClient?.deactivate();
    _stompClient = null;
    connectionStatus.value = false;
  }
}
