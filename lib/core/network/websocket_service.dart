import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import 'package:my_shop/features/auth/data/services/auth_service.dart';
import 'package:my_shop/core/config/env_config.dart';
import 'package:my_shop/core/data/services/storage_service.dart';

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
  int? _subscribedShopId;

  void connect({bool force = false}) async {
    if (_isConnecting && !force) return;
    if (isConnected && !force) return;

    if (_stompClient != null) {
      if (force) {
        _stompClient?.deactivate();
        _stompClient = null;
        _subscribedShopId = null;
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

  Future<void> onConnect(dynamic frame) async {
    _isConnecting = false;
    _reconnectAttempts = 0;
    connectionStatus.value = true;
    _log('✨ [WS] Connected Successfully');

    final token = await AuthService.instance.getAccessToken();
    final headers = {if (token != null) 'Authorization': 'Bearer $token'};

    final shopId = await StorageService.instance.getSelectedShopId();
    if (shopId == null) {
      _log('⚠️ [WS] No shop selected — skipping order topic subscription');
      return;
    }

    _subscribedShopId = shopId;
    final destination = '/topic/shop/$shopId/orders';

    _stompClient?.subscribe(
      destination: destination,
      headers: {...headers, 'receipt': 'rcpt-shop-orders'},
      callback: (StompFrame frame) {
        if (frame.body == null) return;
        try {
          final Map<String, dynamic> raw = json.decode(frame.body!);
          final String type = raw['type'] ?? 'UNKNOWN';

          if (type == 'MENU_ITEM_UPDATE' || type == 'MENU_UPDATE') {
            return;
          }

          if (type == 'NEW_ORDER' || type == 'ORDER_UPDATE') {
            final String orderId = raw['orderId']?.toString() ?? 'unknown';
            final String status =
                raw['order']?['status'] ?? raw['status'] ?? 'unknown';

            _log('📥 [WS] $type | Order: $orderId | Status: $status');
            _orderUpdateController.add(raw);
          }
        } catch (e) {
          _log('⚠️ Error parsing socket message: $e');
        }
      },
    );

    _log('📡 [WS] Subscribed to $destination');
  }

  /// Re-subscribe when the user switches shops.
  Future<void> resubscribeForShop() async {
    if (!isConnected) {
      await connect(force: true);
      return;
    }
    final shopId = await StorageService.instance.getSelectedShopId();
    if (shopId != null && shopId != _subscribedShopId) {
      disconnect();
      await Future.delayed(const Duration(milliseconds: 300));
      connect(force: true);
    }
  }

  void disconnect() {
    _shouldReconnect = false;
    _reconnectTimer?.cancel();
    _stompClient?.deactivate();
    _stompClient = null;
    _subscribedShopId = null;
    connectionStatus.value = false;
  }

  void enableReconnect() {
    _shouldReconnect = true;
  }
}
