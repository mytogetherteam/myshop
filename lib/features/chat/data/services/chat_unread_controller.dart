import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:my_shop/core/network/websocket_service.dart';
import 'package:my_shop/features/chat/data/services/chat_service.dart';

/// App-wide source of truth for the shop's total unread chat count.
///
/// The value drives the badge on the Chat tab in the bottom navigation. It is
/// refreshed from the backend on start, whenever a realtime chat event arrives,
/// and after the shop opens (reads) a conversation.
class ChatUnreadController {
  ChatUnreadController._();
  static final ChatUnreadController instance = ChatUnreadController._();

  /// Total unread messages for the current shop.
  final ValueNotifier<int> unread = ValueNotifier<int>(0);

  /// Emits a conversation id whenever the shop reads (opens) that conversation.
  ///
  /// Unlike new-message events, a shop-side read produces no realtime WebSocket
  /// event that other screens can consume, so each badge surface (chat list,
  /// order-detail chat icon, etc.) would otherwise keep showing a stale count.
  /// Listen to this to clear the badge for the read conversation everywhere.
  Stream<int> get conversationRead => _conversationRead.stream;
  final StreamController<int> _conversationRead =
      StreamController<int>.broadcast();

  StreamSubscription<Map<String, dynamic>>? _chatSub;
  bool _started = false;

  /// Begins tracking the unread count. Safe to call multiple times.
  void start() {
    if (_started) return;
    _started = true;
    refresh();
    _chatSub = WebSocketService().chatUpdates.listen((_) => refresh());
  }

  /// Pulls the authoritative unread total from the backend.
  Future<void> refresh() async {
    final count = await ChatService.instance.getUnreadCount();
    if (count != null) {
      unread.value = count;
    }
  }

  /// Broadcasts that [conversationId] was read by the shop and re-syncs the
  /// total. Call this from any screen that marks a conversation as read.
  void notifyConversationRead(int conversationId) {
    if (conversationId > 0) {
      _conversationRead.add(conversationId);
    }
    refresh();
  }

  void dispose() {
    _chatSub?.cancel();
    _chatSub = null;
    _conversationRead.close();
    _started = false;
  }
}
