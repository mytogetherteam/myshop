import 'package:dio/dio.dart';
import 'package:my_shop/core/network/api_client.dart';
import 'package:my_shop/core/network/api_helper.dart';
import 'package:my_shop/features/chat/data/models/chat_model.dart';

/// REST client for the backend `shop/chat` endpoints.
///
/// All routes require a valid bearer token and the `X-Shop-Id` header, both of
/// which are injected automatically by the configured Dio interceptors.
class ChatService {
  static const String _basePath = '/api/shop/chat';

  static final ChatService instance = ChatService._();
  ChatService._();

  final Dio _dio = ApiClient().dio;

  bool _isOk(Response response) {
    final code = response.statusCode;
    return code != null && code >= 200 && code < 300;
  }

  Map<String, dynamic>? _body(Response response) {
    if (!_isOk(response) || response.data is! Map) return null;
    return (response.data as Map).cast<String, dynamic>();
  }

  /// Total unread chat messages across all of this shop's conversations.
  ///
  /// Returns `null` on a network/server error so callers can keep the last
  /// known value instead of resetting the badge to zero.
  Future<int?> getUnreadCount() async {
    try {
      final response = await _dio.get('$_basePath/unread-count');
      final body = _body(response);
      if (body != null && body['success'] == true && body['data'] is Map) {
        final data = (body['data'] as Map).cast<String, dynamic>();
        return (data['count'] as num?)?.toInt() ?? 0;
      }
      return null;
    } catch (e) {
      ApiHelper.handleError(e, context: 'ChatService.getUnreadCount');
      return null;
    }
  }

  /// Inbox: conversations for the current shop, newest activity first.
  ///
  /// Returns `null` on a network/server error so callers can distinguish a
  /// genuine failure from a successful-but-empty inbox.
  Future<ChatPaged<ChatConversation>?> getConversations({
    int page = 1,
    int size = 20,
  }) async {
    try {
      final response = await _dio.get(
        '$_basePath/conversations',
        queryParameters: {'page': page, 'size': size},
      );
      final body = _body(response);
      if (body != null && body['success'] == true) {
        return ChatPaged.fromResponse(body, ChatConversation.fromJson);
      }
      return null;
    } catch (e) {
      ApiHelper.handleError(e, context: 'ChatService.getConversations');
      return null;
    }
  }

  /// Fetches the existing conversation for an order, if one has been started.
  ///
  /// Returns `null` when there is no conversation yet (no messages exchanged)
  /// or on a network/server error.
  Future<ChatConversation?> getConversationByOrder(int orderId) async {
    try {
      final response = await _dio.get('$_basePath/orders/$orderId');
      final body = _body(response);
      if (body != null && body['success'] == true && body['data'] is Map) {
        return ChatConversation.fromJson(
          (body['data'] as Map).cast<String, dynamic>(),
        );
      }
      return null;
    } catch (e) {
      ApiHelper.handleError(e, context: 'ChatService.getConversationByOrder');
      return null;
    }
  }

  /// Messages in a conversation, returned newest-first by the backend.
  ///
  /// Returns `null` on a network/server error.
  Future<ChatPaged<ChatMessage>?> getMessages(
    int conversationId, {
    int page = 1,
    int size = 50,
  }) async {
    try {
      final response = await _dio.get(
        '$_basePath/conversations/$conversationId/messages',
        queryParameters: {'page': page, 'size': size},
      );
      final body = _body(response);
      if (body != null && body['success'] == true) {
        return ChatPaged.fromResponse(body, ChatMessage.fromJson);
      }
      return null;
    } catch (e) {
      ApiHelper.handleError(e, context: 'ChatService.getMessages');
      return null;
    }
  }

  /// Send a text message on an order. Creates the conversation on first send.
  Future<ChatMessage?> sendTextMessage(int orderId, String content) async {
    try {
      final response = await _dio.post(
        '$_basePath/orders/$orderId/messages',
        data: {'type': 'TEXT', 'content': content},
      );
      final body = _body(response);
      if (body != null && body['success'] == true && body['data'] is Map) {
        return ChatMessage.fromJson(
          (body['data'] as Map).cast<String, dynamic>(),
        );
      }
      return null;
    } catch (e) {
      ApiHelper.handleError(e, context: 'ChatService.sendTextMessage');
      return null;
    }
  }

  /// Mark all customer messages in a conversation as read.
  Future<bool> markAsRead(int conversationId) async {
    try {
      final response = await _dio.put(
        '$_basePath/conversations/$conversationId/read',
      );
      final body = _body(response);
      return body != null && body['success'] == true;
    } catch (e) {
      ApiHelper.handleError(e, context: 'ChatService.markAsRead');
      return false;
    }
  }

  /// Edit one of this shop's own text messages.
  Future<ChatMessage?> editMessage(
    int conversationId,
    String messageId,
    String content,
  ) async {
    try {
      final response = await _dio.put(
        '$_basePath/conversations/$conversationId/messages/$messageId',
        data: {'content': content},
      );
      final body = _body(response);
      if (body != null && body['success'] == true && body['data'] is Map) {
        return ChatMessage.fromJson(
          (body['data'] as Map).cast<String, dynamic>(),
        );
      }
      return null;
    } catch (e) {
      ApiHelper.handleError(e, context: 'ChatService.editMessage');
      return null;
    }
  }

  /// Soft-delete one of this shop's own messages.
  Future<bool> deleteMessage(int conversationId, String messageId) async {
    try {
      final response = await _dio.delete(
        '$_basePath/conversations/$conversationId/messages/$messageId',
      );
      final body = _body(response);
      return body != null && body['success'] == true;
    } catch (e) {
      ApiHelper.handleError(e, context: 'ChatService.deleteMessage');
      return false;
    }
  }
}
