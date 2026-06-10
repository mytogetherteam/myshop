import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:my_shop/core/network/websocket_service.dart';
import 'package:my_shop/core/utils/app_colors.dart';
import 'package:my_shop/core/localization/app_localizations.dart';
import 'package:my_shop/features/chat/data/models/chat_model.dart';
import 'package:my_shop/features/chat/data/services/chat_service.dart';

class ChatDetailScreen extends StatefulWidget {
  final ChatConversation conversation;

  const ChatDetailScreen({super.key, required this.conversation});

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  /// Messages held in chronological order (oldest first).
  final List<ChatMessage> _messages = [];

  bool _isLoading = true;
  bool _hasError = false;
  bool _isSending = false;
  bool _isLoadingOlder = false;
  int _currentPage = 1;
  int _lastPage = 1;

  StreamSubscription<Map<String, dynamic>>? _chatSub;

  int get _conversationId => widget.conversation.id;
  int get _orderId => widget.conversation.orderId;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _chatSub = WebSocketService().chatUpdates.listen(_onChatEvent);
    _loadMessages();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _chatSub?.cancel();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    final result = await ChatService.instance.getMessages(_conversationId);
    if (!mounted) return;

    setState(() {
      _isLoading = false;
      if (result == null) {
        _hasError = true;
      } else {
        _hasError = false;
        // Backend returns newest-first; reverse for chronological display.
        _messages
          ..clear()
          ..addAll(result.items.reversed);
        _currentPage = result.currentPage;
        _lastPage = result.lastPage;
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    _markAsRead();
  }

  Future<void> _loadOlder() async {
    if (_isLoadingOlder || _currentPage >= _lastPage) return;
    setState(() => _isLoadingOlder = true);

    final result = await ChatService.instance
        .getMessages(_conversationId, page: _currentPage + 1);
    if (!mounted) return;

    setState(() {
      _isLoadingOlder = false;
      if (result != null) {
        // Older page (still newest-first) → reverse and prepend.
        _messages.insertAll(0, result.items.reversed);
        _currentPage = result.currentPage;
        _lastPage = result.lastPage;
      }
    });
  }

  void _markAsRead() {
    if (widget.conversation.unreadCount > 0 || _hasUnreadCustomerMessages()) {
      ChatService.instance.markAsRead(_conversationId);
    }
  }

  bool _hasUnreadCustomerMessages() {
    return _messages.any((m) => !m.isMe && !m.isRead && !m.isDeleted);
  }

  void _onScroll() {
    if (_scrollController.position.pixels <= 80 &&
        !_isLoadingOlder &&
        _currentPage < _lastPage) {
      _loadOlder();
    }
  }

  void _scrollToBottom({bool animate = true}) {
    if (!_scrollController.hasClients) return;
    final target = _scrollController.position.maxScrollExtent;
    if (animate) {
      _scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      _scrollController.jumpTo(target);
    }
  }

  bool get _isNearBottom {
    if (!_scrollController.hasClients) return true;
    return _scrollController.position.maxScrollExtent -
            _scrollController.position.pixels <
        120;
  }

  void _onChatEvent(Map<String, dynamic> event) {
    if (!mounted) return;
    final conversationId = (event['conversationId'] as num?)?.toInt();
    if (conversationId != _conversationId) return;

    final type = event['type'] as String?;
    final raw = (event['message'] as Map?)?.cast<String, dynamic>();
    if (raw == null) return;
    final incoming = ChatMessage.fromJson(raw);

    setState(() {
      final index = _messages.indexWhere((m) => m.id == incoming.id);
      switch (type) {
        case 'CHAT_MESSAGE':
          if (index == -1) {
            _messages.add(incoming);
          } else {
            _messages[index] = incoming;
          }
          break;
        case 'CHAT_MESSAGE_EDIT':
        case 'CHAT_MESSAGE_DELETE':
          if (index != -1) {
            _messages[index] = incoming;
          }
          break;
      }
    });

    if (type == 'CHAT_MESSAGE') {
      final wasNearBottom = _isNearBottom;
      if (wasNearBottom) {
        WidgetsBinding.instance
            .addPostFrameCallback((_) => _scrollToBottom());
      }
      // We're viewing the conversation, so clear unread on the server.
      ChatService.instance.markAsRead(_conversationId);
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    _messageController.clear();
    setState(() => _isSending = true);

    final sent = await ChatService.instance.sendTextMessage(_orderId, text);
    if (!mounted) return;

    setState(() {
      _isSending = false;
      if (sent != null) {
        _messages.add(sent);
      }
    });

    if (sent != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    } else {
      _messageController.text = text;
      _showSnack('Failed to send message. Please try again.');
    }
  }

  Future<void> _editMessage(ChatMessage message) async {
    final controller = TextEditingController(text: message.content ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit message',
            style: GoogleFonts.poppins(
                fontSize: 16, fontWeight: FontWeight.w600)),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 4,
          minLines: 1,
          style: GoogleFonts.poppins(fontSize: 14),
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: GoogleFonts.poppins(color: const Color(0xFF64748B))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: Text('Save',
                style: GoogleFonts.poppins(
                    color: AppColors.primary, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (result == null || result.isEmpty || result == message.content) return;

    final updated = await ChatService.instance
        .editMessage(_conversationId, message.id, result);
    if (!mounted) return;
    if (updated != null) {
      setState(() {
        final index = _messages.indexWhere((m) => m.id == message.id);
        if (index != -1) _messages[index] = updated;
      });
    } else {
      _showSnack('Failed to edit message.');
    }
  }

  Future<void> _deleteMessage(ChatMessage message) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete message',
            style: GoogleFonts.poppins(
                fontSize: 16, fontWeight: FontWeight.w600)),
        content: Text('This message will be deleted for everyone.',
            style: GoogleFonts.poppins(fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel',
                style: GoogleFonts.poppins(color: const Color(0xFF64748B))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Delete',
                style: GoogleFonts.poppins(
                    color: const Color(0xFFEF4444),
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final ok =
        await ChatService.instance.deleteMessage(_conversationId, message.id);
    if (!mounted) return;
    if (ok) {
      setState(() {
        final index = _messages.indexWhere((m) => m.id == message.id);
        if (index != -1) {
          _messages[index] = message.copyWith(
            isDeleted: true,
            content: '',
            attachmentUrl: '',
          );
        }
      });
    } else {
      _showSnack('Failed to delete message.');
    }
  }

  void _showMessageActions(ChatMessage message) {
    // Only the shop's own, non-deleted messages can be edited/deleted.
    if (!message.isMe || message.isDeleted) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            if (message.kind == ChatMessageKind.text)
              ListTile(
                leading: const Icon(Icons.edit_rounded,
                    color: Color(0xFF475569)),
                title: Text('Edit', style: GoogleFonts.poppins(fontSize: 15)),
                onTap: () {
                  Navigator.pop(ctx);
                  _editMessage(message);
                },
              ),
            ListTile(
              leading:
                  const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444)),
              title: Text('Delete',
                  style: GoogleFonts.poppins(
                      fontSize: 15, color: const Color(0xFFEF4444))),
              onTap: () {
                Navigator.pop(ctx);
                _deleteMessage(message);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message, style: GoogleFonts.poppins())),
    );
  }

  void _openImage(String url) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          children: [
            InteractiveViewer(
              child: CachedNetworkImage(imageUrl: url, fit: BoxFit.contain),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatMessageTime(DateTime timestamp) {
    final hour = timestamp.hour.toString().padLeft(2, '0');
    final minute = timestamp.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  bool _shouldShowDateSeparator(int index) {
    if (index == 0) return true;
    final current = _messages[index].createdAt;
    final previous = _messages[index - 1].createdAt;
    return current.difference(previous).inMinutes > 30 ||
        current.day != previous.day;
  }

  String _formatDateSeparator(DateTime timestamp) {
    final now = DateTime.now();
    final diff =
        DateTime(now.year, now.month, now.day).difference(
            DateTime(timestamp.year, timestamp.month, timestamp.day));

    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(child: _buildBody(t)),
          _buildMessageInput(t),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final c = widget.conversation;
    final subtitle = c.orderNo != null
        ? 'Order ${c.orderNo}'
        : (c.orderStatus ?? '');
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      leadingWidth: 36,
      leading: Padding(
        padding: const EdgeInsets.only(left: 8),
        child: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: const Color(0xFF1E293B),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      title: Row(
        children: [
          _buildHeaderAvatar(c),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderAvatar(ChatConversation c) {
    final url = c.avatarUrl;
    final initial = c.name.isNotEmpty ? c.name[0].toUpperCase() : '?';
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        gradient: (url == null || url.isEmpty)
            ? AppColors.primaryGradient
            : null,
        shape: BoxShape.circle,
      ),
      clipBehavior: Clip.antiAlias,
      child: (url != null && url.isNotEmpty)
          ? CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.cover,
              errorWidget: (_, _, _) => Center(
                child: Text(initial,
                    style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white)),
              ),
            )
          : Center(
              child: Text(initial,
                  style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white)),
            ),
    );
  }

  Widget _buildBody(AppLocalizations? t) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
      );
    }

    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_rounded,
                size: 44, color: Color(0xFFCBD5E1)),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _loadMessages,
              child: Text(t?.translate('retry') ?? 'Retry',
                  style: GoogleFonts.poppins(
                      color: AppColors.primary, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );
    }

    if (_messages.isEmpty) {
      return Center(
        child: Text(
          'Say hello 👋',
          style: GoogleFonts.poppins(
              fontSize: 14, color: const Color(0xFF94A3B8)),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: _messages.length + (_isLoadingOlder ? 1 : 0),
      itemBuilder: (context, index) {
        if (_isLoadingOlder && index == 0) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }
        final msgIndex = _isLoadingOlder ? index - 1 : index;
        final message = _messages[msgIndex];

        if (message.kind == ChatMessageKind.system) {
          return _buildSystemMessage(message);
        }

        return Column(
          children: [
            if (_shouldShowDateSeparator(msgIndex))
              _buildDateSeparator(message.createdAt),
            _buildMessageBubble(message),
          ],
        );
      },
    );
  }

  Widget _buildSystemMessage(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFE2E8F0),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            message.content ?? '',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
                fontSize: 12, color: const Color(0xFF64748B)),
          ),
        ),
      ),
    );
  }

  Widget _buildDateSeparator(DateTime timestamp) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          const Expanded(child: Divider(color: Color(0xFFE2E8F0), height: 1)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              _formatDateSeparator(timestamp),
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF94A3B8),
              ),
            ),
          ),
          const Expanded(child: Divider(color: Color(0xFFE2E8F0), height: 1)),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isMe = message.isMe;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                color: Color(0xFFE2E8F0),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  widget.conversation.name.isNotEmpty
                      ? widget.conversation.name[0].toUpperCase()
                      : '?',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: GestureDetector(
              onLongPress: () => _showMessageActions(message),
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.72,
                ),
                padding: message.kind == ChatMessageKind.image &&
                        !message.isDeleted
                    ? const EdgeInsets.all(4)
                    : const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  gradient: isMe && !message.isDeleted
                      ? AppColors.primaryGradient
                      : null,
                  color: message.isDeleted
                      ? const Color(0xFFE2E8F0)
                      : (isMe ? null : Colors.white),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(isMe ? 18 : 4),
                    bottomRight: Radius.circular(isMe ? 4 : 18),
                  ),
                  boxShadow: message.isDeleted
                      ? null
                      : [
                          BoxShadow(
                            color: isMe
                                ? AppColors.primary.withValues(alpha: 0.15)
                                : Colors.black.withValues(alpha: 0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                ),
                child: _buildBubbleContent(message, isMe),
              ),
            ),
          ),
          if (isMe) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildBubbleContent(ChatMessage message, bool isMe) {
    if (message.isDeleted) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.block_rounded, size: 14, color: Color(0xFF94A3B8)),
          const SizedBox(width: 6),
          Text(
            'This message was deleted',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontStyle: FontStyle.italic,
              color: const Color(0xFF94A3B8),
            ),
          ),
        ],
      );
    }

    if (message.kind == ChatMessageKind.image &&
        message.attachmentUrl != null &&
        message.attachmentUrl!.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          GestureDetector(
            onTap: () => _openImage(message.attachmentUrl!),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: CachedNetworkImage(
                imageUrl: message.attachmentUrl!,
                width: 200,
                fit: BoxFit.cover,
                placeholder: (_, _) => Container(
                  width: 200,
                  height: 200,
                  color: const Color(0xFFF1F5F9),
                  child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2)),
                ),
                errorWidget: (_, _, _) => Container(
                  width: 200,
                  height: 120,
                  color: const Color(0xFFF1F5F9),
                  child: const Icon(Icons.broken_image_outlined,
                      color: Color(0xFF94A3B8)),
                ),
              ),
            ),
          ),
          if ((message.content ?? '').isNotEmpty) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                message.content!,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: isMe ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
            ),
          ],
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            child: _buildMetaRow(message, isMe),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          message.content ?? '',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: isMe ? Colors.white : const Color(0xFF1E293B),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 4),
        _buildMetaRow(message, isMe),
      ],
    );
  }

  Widget _buildMetaRow(ChatMessage message, bool isMe) {
    final mutedColor =
        isMe ? Colors.white.withValues(alpha: 0.7) : const Color(0xFF94A3B8);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (message.isEdited) ...[
          Text(
            'edited',
            style: GoogleFonts.poppins(
                fontSize: 10, fontStyle: FontStyle.italic, color: mutedColor),
          ),
          const SizedBox(width: 4),
        ],
        Text(
          _formatMessageTime(message.createdAt),
          style: GoogleFonts.poppins(
              fontSize: 10, fontWeight: FontWeight.w400, color: mutedColor),
        ),
        if (isMe) ...[
          const SizedBox(width: 4),
          Icon(
            message.isRead ? Icons.done_all_rounded : Icons.done_rounded,
            size: 14,
            color: mutedColor,
          ),
        ],
      ],
    );
  }

  Widget _buildMessageInput(AppLocalizations? t) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 8,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _messageController,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: const Color(0xFF1E293B),
                ),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                maxLines: 4,
                minLines: 1,
                decoration: InputDecoration(
                  hintText:
                      t?.translate('type_a_message') ?? 'Type a message...',
                  hintStyle: GoogleFonts.poppins(
                    fontSize: 14,
                    color: const Color(0xFF94A3B8),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: _isSending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const PhosphorIcon(
                        PhosphorIconsFill.paperPlaneTilt,
                        size: 20,
                        color: Colors.white,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
