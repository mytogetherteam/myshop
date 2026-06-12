import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import 'package:my_shop/features/auth/data/services/auth_service.dart';
import 'package:my_shop/core/config/env_config.dart';
import 'package:my_shop/core/data/services/storage_service.dart';
import 'package:my_shop/core/utils/app_logger.dart';

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  StompClient? _stompClient;
  bool get isConnected => _stompClient?.connected ?? false;

  final ValueNotifier<bool> connectionStatus = ValueNotifier<bool>(false);

  final StreamController<Map<String, dynamic>> _orderUpdateController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get orderUpdates =>
      _orderUpdateController.stream;

  final StreamController<Map<String, dynamic>> _chatUpdateController =
      StreamController<Map<String, dynamic>>.broadcast();

  /// Realtime chat events for the current shop: `CHAT_MESSAGE`,
  /// `CHAT_MESSAGE_EDIT`, `CHAT_MESSAGE_DELETE`.
  Stream<Map<String, dynamic>> get chatUpdates =>
      _chatUpdateController.stream;

  final StreamController<Map<String, dynamic>> _menuUpdateController =
      StreamController<Map<String, dynamic>>.broadcast();

  /// Public menu structure / availability / publish updates for shops.
  Stream<Map<String, dynamic>> get menuUpdates =>
      _menuUpdateController.stream;

  bool _isConnecting = false;
  bool _shouldReconnect = true;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  Timer? _reconnectTimer;
  int? _subscribedShopId;

  /// Normalises a STOMP frame body: strips the `\0` terminator and trims, so
  /// `json.decode` never chokes on the trailing null some brokers append.
  String? _frameBody(StompFrame frame) {
    final raw = frame.body;
    if (raw == null || raw.isEmpty) return null;
    final cleaned = raw.replaceAll('\u0000', '').trim();
    return cleaned.isEmpty ? null : cleaned;
  }

  Future<void> connect({bool force = false}) async {
    if (_isConnecting && !force) return;
    if (isConnected && !force) return;

    // We've decided to (re)connect — re-enable auto-reconnect and cancel any
    // pending retry so a stale timer can't tear down the fresh connection.
    _shouldReconnect = true;
    _reconnectTimer?.cancel();

    if (_stompClient != null) {
      if (force || !isConnected) {
        try {
          _stompClient?.deactivate();
        } catch (_) {}
        _stompClient = null;
        _subscribedShopId = null;
        // deactivate() above may have fired onDisconnect → _scheduleReconnect;
        // drop that timer since we're about to connect immediately.
        _reconnectTimer?.cancel();
      } else {
        _stompClient?.activate();
        return;
      }
    }

    _isConnecting = true;
    AppLogger.realtime('[WS] Connecting to ${EnvConfig.wsUrl}');

    final token = await AuthService.instance.getAccessToken();
    if (token == null || token.isEmpty) {
      _isConnecting = false;
      AppLogger.realtime('[WS] Connection aborted: no access token');
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
          AppLogger.realtime('[WS] WebSocket error: $error');
          _scheduleReconnect();
        },
        onWebSocketDone: () {
          _isConnecting = false;
          connectionStatus.value = false;
          AppLogger.realtime('[WS] WebSocket connection closed');
          _scheduleReconnect();
        },
        onDebugMessage: (String message) {
          if (kDebugMode) {
            AppLogger.realtime('[WS] $message');
          }
        },
        stompConnectHeaders: {'Authorization': 'Bearer $token'},
        onStompError: (frame) =>
            AppLogger.realtime('[WS] STOMP error: ${frame.body}'),
        onDisconnect: (frame) {
          connectionStatus.value = false;
          AppLogger.realtime('[WS] Disconnected');
          _scheduleReconnect();
        },
        heartbeatOutgoing: const Duration(milliseconds: 10000),
        heartbeatIncoming: const Duration(milliseconds: 10000),
        reconnectDelay: const Duration(seconds: 3),
      ),
    );

    _stompClient?.activate();
  }

  void _scheduleReconnect() {
    if (!_shouldReconnect) return;
    if (_isConnecting) return; // Already trying to connect
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      AppLogger.realtime('[WS] Max reconnection attempts reached');
      return;
    }

    _reconnectAttempts++;
    final delay = Duration(seconds: _reconnectAttempts * 2);

    AppLogger.realtime(
      '[WS] Scheduling reconnection in ${delay.inSeconds}s '
      '(attempt $_reconnectAttempts/$_maxReconnectAttempts)',
    );

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, () {
      if (_shouldReconnect && !_isConnecting) {
        connect(force: true);
      }
    });
  }

  Future<void> onConnect(dynamic frame) async {
    _isConnecting = false;
    _reconnectAttempts = 0;
    connectionStatus.value = true;
    AppLogger.realtime('[WS] Connected successfully');

    final token = await AuthService.instance.getAccessToken();
    final headers = {if (token != null) 'Authorization': 'Bearer $token'};

    _stompClient?.subscribe(
      destination: '/topic/shop-menu-updates',
      headers: {...headers, 'receipt': 'rcpt-shop-menu-updates'},
      callback: (StompFrame frame) {
        final body = _frameBody(frame);
        if (body == null) return;
        try {
          final Map<String, dynamic> raw = json.decode(body);
          final String type = raw['type'] ?? 'UNKNOWN';
          if (type != 'MENU_UPDATE') return;

          AppLogger.realtime(
            '[WS] MENU_UPDATE shopId=${raw['shopId']} '
            'reason=${raw['reason']} item=${raw['menuItemId']}',
          );
          _menuUpdateController.add(raw);
        } catch (e) {
          AppLogger.realtime('[WS] Error parsing menu update: $e');
        }
      },
    );
    AppLogger.realtime('[WS] Subscribed to /topic/shop-menu-updates');

    final shopId = await StorageService.instance.getSelectedShopId();
    if (shopId == null) {
      AppLogger.realtime('[WS] No shop selected — skipping shop topic subscriptions');
      return;
    }

    _subscribedShopId = shopId;
    final orderDestination = '/topic/shop/$shopId/orders';

    _stompClient?.subscribe(
      destination: orderDestination,
      headers: {...headers, 'receipt': 'rcpt-shop-orders'},
      callback: (StompFrame frame) {
        final body = _frameBody(frame);
        if (body == null) return;
        try {
          final Map<String, dynamic> raw = json.decode(body);
          final String type = raw['type'] ?? 'UNKNOWN';

          if (type == 'NEW_ORDER' ||
              type == 'ORDER_UPDATE' ||
              type == 'PAYMENT_REMINDER') {
            final String orderId = raw['orderId']?.toString() ?? 'unknown';
            final String status =
                raw['order']?['status'] ?? raw['status'] ?? 'unknown';

            AppLogger.realtime('[WS] $type | order=$orderId | status=$status');
            _orderUpdateController.add(raw);
          }
        } catch (e) {
          AppLogger.realtime('[WS] Error parsing order update: $e');
        }
      },
    );

    AppLogger.realtime('[WS] Subscribed to $orderDestination');

    final chatDestination = '/topic/shop/$shopId/chat';

    _stompClient?.subscribe(
      destination: chatDestination,
      headers: {...headers, 'receipt': 'rcpt-shop-chat'},
      callback: (StompFrame frame) {
        final body = _frameBody(frame);
        if (body == null) return;
        try {
          final Map<String, dynamic> raw = json.decode(body);
          final String type = raw['type'] ?? 'UNKNOWN';

          if (type == 'CHAT_MESSAGE' ||
              type == 'CHAT_MESSAGE_EDIT' ||
              type == 'CHAT_MESSAGE_DELETE') {
            AppLogger.realtime(
              '[WS] $type | conversation=${raw['conversationId']}',
            );
            _chatUpdateController.add(raw);
          }
        } catch (e) {
          AppLogger.realtime('[WS] Error parsing chat update: $e');
        }
      },
    );

    AppLogger.realtime('[WS] Subscribed to $chatDestination');
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
