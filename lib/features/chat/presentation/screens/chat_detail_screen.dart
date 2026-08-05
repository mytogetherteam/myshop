import 'dart:async';

import 'package:any_link_preview/any_link_preview.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:my_shop/core/network/websocket_service.dart';
import 'package:my_shop/core/utils/app_colors.dart';
import 'package:my_shop/core/localization/app_localizations.dart';
import 'package:my_shop/features/chat/data/models/chat_model.dart';
import 'package:my_shop/features/chat/data/models/chat_window.dart';
import 'package:my_shop/features/chat/data/services/chat_service.dart';
import 'package:my_shop/features/chat/data/services/chat_unread_controller.dart';
import 'package:my_shop/features/chat/data/services/chat_voice_recorder.dart';
import 'package:my_shop/features/chat/presentation/widgets/audio_message_bubble.dart';
import 'package:my_shop/features/chat/presentation/widgets/chat_order_summary_sheet.dart';
import 'package:my_shop/features/chat/presentation/widgets/voice_record_button.dart';
import 'package:my_shop/features/orders/data/models/order_model.dart';
import 'package:my_shop/features/orders/data/services/order_service.dart';
import 'package:my_shop/features/orders/presentation/screens/order_detail_screen.dart';

class ChatDetailScreen extends StatefulWidget {
  final ChatConversation conversation;

  const ChatDetailScreen({super.key, required this.conversation});

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen>
    with WidgetsBindingObserver {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatVoiceRecorder _voiceRecorder = ChatVoiceRecorder();

  /// Messages held in chronological order (oldest first).
  final List<ChatMessage> _messages = [];

  bool _isLoading = true;
  bool _hasError = false;
  bool _isSending = false;
  bool _isLoadingOlder = false;
  int _currentPage = 1;
  int _lastPage = 1;

  StreamSubscription<Map<String, dynamic>>? _chatSub;
  StreamSubscription<Map<String, dynamic>>? _orderSub;
  Timer? _chatWindowTimer;
  Timer? _countdownTicker;

  OrderModel? _order;
  bool _isLoadingOrder = true;

  /// Mutable: a conversation opened from an order may not exist on the server
  /// yet (id 0). It's assigned once the first message creates it.
  late int _conversationId = widget.conversation.id;
  int get _orderId => widget.conversation.orderId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    ChatUnreadController.instance.activeConversationId = widget.conversation.id;
    _scrollController.addListener(_onScroll);
    _messageController.addListener(() {
      if (mounted) setState(() {});
    });
    _chatSub = WebSocketService().chatUpdates.listen(_onChatEvent);
    _orderSub = WebSocketService().orderUpdates.listen(_onOrderEvent);
    _loadMessages();
    _loadOrderInfo();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _scheduleChatWindowClose();
      if (mounted) setState(() {});
      return;
    }
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _voiceRecorder.cancel();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    ChatUnreadController.instance.activeConversationId = null;
    _voiceRecorder.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    _chatSub?.cancel();
    _orderSub?.cancel();
    _chatWindowTimer?.cancel();
    _countdownTicker?.cancel();
    super.dispose();
  }

  Future<void> _loadOrderInfo() async {
    setState(() => _isLoadingOrder = true);

    final order = await OrderService().getOrderDetail(_orderId.toString());

    if (!mounted) return;
    setState(() {
      _isLoadingOrder = false;
      _order = order;
    });
    _scheduleChatWindowClose();
  }

  void _onOrderEvent(Map<String, dynamic> event) {
    if (!mounted) return;
    final orderId = event['orderId']?.toString();
    if (orderId != _orderId.toString()) return;

    if (event['order'] != null) {
      setState(() {
        _order = OrderModel.fromJson(
          Map<String, dynamic>.from(event['order'] as Map),
        );
      });
      _scheduleChatWindowClose();
    } else {
      _loadOrderInfo();
    }
  }

  void _scheduleChatWindowClose() {
    _chatWindowTimer?.cancel();
    _countdownTicker?.cancel();
    final order = _order;
    if (order == null) return;

    final status = order.status.toUpperCase();
    if (status != 'DELIVERED' && status != 'PICKED_UP') return;

    final closesAt = ChatWindow.closesAt(order.status, order.updatedAt);
    if (closesAt == null) return;
    final remaining = closesAt.difference(DateTime.now());
    if (remaining <= Duration.zero) return;

    _countdownTicker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
    _chatWindowTimer = Timer(remaining, () {
      _countdownTicker?.cancel();
      if (mounted) setState(() {});
    });
  }

  Future<void> _openOrderDetails() async {
    if (_order == null) return;

    await Navigator.push(
      context,
      PageRouteBuilder(
        settings: RouteSettings(name: 'order_detail_${_order!.id}'),
        pageBuilder: (context, animation, secondaryAnimation) =>
            OrderDetailScreen(order: _order!),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeOut;
          final tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: curve));
          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
        reverseTransitionDuration: Duration.zero,
      ),
    );

    if (mounted) {
      await _loadOrderInfo();
    }
  }

  Future<void> _loadMessages() async {
    // Fresh conversation started from an order — nothing on the server yet.
    if (_conversationId <= 0) {
      setState(() {
        _isLoading = false;
        _hasError = false;
      });
      return;
    }

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

    final result = await ChatService.instance.getMessages(
      _conversationId,
      page: _currentPage + 1,
    );
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
      _markConversationRead();
    }
  }

  /// Clears the conversation's unread state on the backend and broadcasts the
  /// read so every badge surface (chat list, order-detail chat icon, the Chat
  /// tab) clears immediately — a shop-side read emits no realtime event.
  void _markConversationRead() {
    if (_conversationId <= 0) return;
    ChatService.instance.markAsRead(_conversationId);
    ChatUnreadController.instance.notifyConversationRead(_conversationId);
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

    // The customer read this conversation → flip our sent messages to ✅✅.
    if (type == 'CONVERSATION_READ') {
      setState(() {
        for (var i = 0; i < _messages.length; i++) {
          final m = _messages[i];
          if (m.isMe && !m.isRead) {
            _messages[i] = m.copyWith(isRead: true);
          }
        }
      });
      return;
    }

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
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      }
      // We're viewing the conversation, so clear unread on the server.
      _markConversationRead();
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
        // First message on a brand-new conversation: adopt the server id so
        // realtime events and reads target the right conversation.
        if (_conversationId <= 0 && sent.conversationId != null) {
          _conversationId = sent.conversationId!;
          ChatUnreadController.instance.activeConversationId = _conversationId;
        }
        final index = _messages.indexWhere((m) => m.id == sent.id);
        if (index == -1) {
          _messages.add(sent);
        } else {
          _messages[index] = sent;
        }
      }
    });

    if (sent != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    } else {
      _messageController.text = text;
      _showSnack('Failed to send message. Please try again.');
    }
  }

  Future<void> _sendVoiceMessage(VoiceRecordingResult result) async {
    if (_isSending || _isOrderClosed) {
      await ChatVoiceRecorder.deleteFile(result.path);
      return;
    }

    setState(() => _isSending = true);
    final sent = await ChatService.instance.sendVoiceMessage(
      _orderId,
      result.path,
      durationSeconds: result.durationSeconds,
    );
    await ChatVoiceRecorder.deleteFile(result.path);
    if (!mounted) return;

    setState(() {
      _isSending = false;
      if (sent != null) {
        if (_conversationId <= 0 && sent.conversationId != null) {
          _conversationId = sent.conversationId!;
          ChatUnreadController.instance.activeConversationId = _conversationId;
        }
        final index = _messages.indexWhere((m) => m.id == sent.id);
        if (index == -1) {
          _messages.add(sent);
        } else {
          _messages[index] = sent;
        }
      }
    });

    if (sent != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    } else {
      _showSnack('Failed to send voice message. Please try again.');
    }
  }

  Future<void> _editMessage(ChatMessage message) async {
    final controller = TextEditingController(text: message.content ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Edit message',
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 4,
          minLines: 1,
          style: GoogleFonts.poppins(fontSize: 14),
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            suffixIcon: ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (context, value, child) {
                if (value.text.isEmpty) return const SizedBox.shrink();
                return IconButton(
                  icon: Icon(Icons.clear, color: Colors.grey, size: 20),
                  onPressed: () {
                    controller.clear();
                  },
                );
              },
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(
                color: (Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFFCBD5E1)
                    : const Color(0xFF64748B)),
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: Text(
              'Save',
              style: GoogleFonts.poppins(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (result == null || result.isEmpty || result == message.content) return;

    final updated = await ChatService.instance.editMessage(
      _conversationId,
      message.id,
      result,
    );
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
        title: Text(
          'Delete message',
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        content: Text(
          'This message will be deleted for everyone.',
          style: GoogleFonts.poppins(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(
                color: (Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFFCBD5E1)
                    : const Color(0xFF64748B)),
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Delete',
              style: GoogleFonts.poppins(
                color: const Color(0xFFEF4444),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final ok = await ChatService.instance.deleteMessage(
      _conversationId,
      message.id,
    );
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
    if (message.isDeleted) return;

    final urlRegExp = RegExp(
      r'(?:(?:https?|ftp)://)?[\w/\-?=%.]+\.[\w/\-?=%.]+',
    );
    final matches = urlRegExp.allMatches(message.content ?? '');
    final urls = matches.map((m) => m.group(0)!).toList();
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 8),
            if (message.kind == ChatMessageKind.text)
              ListTile(
                leading: Icon(Icons.copy_rounded, color: Color(0xFF475569)),
                title: Text(
                  'Copy Text',
                  style: GoogleFonts.poppins(fontSize: 15),
                ),
                onTap: () {
                  Clipboard.setData(ClipboardData(text: message.content ?? ''));
                  Navigator.pop(ctx);
                  _showSnack('Copied to clipboard');
                },
              ),
            for (var url in urls)
              ListTile(
                leading: Icon(
                  Icons.open_in_browser_rounded,
                  color: Color(0xFF475569),
                ),
                title: Text(
                  'Open link: $url',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(fontSize: 15),
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                  final uri = Uri.parse(
                    url.startsWith('http') ? url : 'https://$url',
                  );
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri);
                  }
                },
              ),
            if (message.isMe && message.kind == ChatMessageKind.text)
              ListTile(
                leading: Icon(Icons.edit_rounded, color: Color(0xFF475569)),
                title: Text('Edit', style: GoogleFonts.poppins(fontSize: 15)),
                onTap: () {
                  Navigator.pop(ctx);
                  _editMessage(message);
                },
              ),
            if (message.isMe)
              ListTile(
                leading: Icon(
                  Icons.delete_outline_rounded,
                  color: Color(0xFFEF4444),
                ),
                title: Text(
                  'Delete',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    color: const Color(0xFFEF4444),
                  ),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _deleteMessage(message);
                },
              ),
            SizedBox(height: 8),
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
                icon: Icon(Icons.close_rounded, color: Colors.white),
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

  bool _isSameCalendarDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _shouldShowDateSeparator(int index) {
    if (index == 0) return true;
    final current = _messages[index].createdAt;
    final previous = _messages[index - 1].createdAt;
    return !_isSameCalendarDay(current, previous);
  }

  String _formatDateSeparator(DateTime timestamp) {
    final now = DateTime.now();
    final diff = DateTime(
      now.year,
      now.month,
      now.day,
    ).difference(DateTime(timestamp.year, timestamp.month, timestamp.day));

    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
  }

  void _openOrderSummarySheet() {
    ChatOrderSummarySheet.show(
      context,
      order: _order,
      fallbackOrderNo: widget.conversation.orderNo,
      isLoading: _isLoadingOrder,
      onRetry: _loadOrderInfo,
      onViewDetails: _order != null ? _openOrderDetails : null,
    );
  }

  String? _headerSubtitle() {
    final c = widget.conversation;
    if (_order != null) {
      final no = _order!.lastOrderNo.isNotEmpty
          ? _order!.lastOrderNo
          : (c.orderNo ?? _order!.id);
      if (ChatWindow.isCompletedStatus(_order!.status)) {
        final t = AppLocalizations.of(context);
        if (_isOrderClosed) {
          return '$no · ${t?.translate('chat_closed_read_only') ?? 'Closed · Read only'}';
        }
        final closesAt = ChatWindow.closesAt(_order!.status, _order!.updatedAt);
        final timeLeft = ChatWindow.compactTimeLeft(closesAt);
        final status = _order!.status.toUpperCase() == 'PICKED_UP'
            ? (t?.translate('picked_up') ?? 'Picked up')
            : (t?.translate('delivered') ?? 'Delivered');
        return timeLeft.isEmpty
            ? '$no · $status'
            : '$no · $status · $timeLeft ${t?.translate('left') ?? 'left'}';
      }
      return '$no · ${_order!.items.length} items';
    }
    if (c.orderNo != null) return 'Order ${c.orderNo}';
    return c.orderStatus;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(child: _buildBody(t)),
          if (_isOrderClosed)
            _buildClosedOrderAlert(t)
          else
            _buildMessageInput(t),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final c = widget.conversation;
    final subtitle = _headerSubtitle();
    return AppBar(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? Theme.of(context).cardColor
          : Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      leadingWidth: 36,
      leading: Padding(
        padding: const EdgeInsets.only(left: 8),
        child: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: Theme.of(context).textTheme.bodyLarge?.color,
          onPressed: () => Navigator.pop(context),
        ),
      ),
      title: GestureDetector(
        onTap: _openOrderSummarySheet,
        behavior: HitTestBehavior.opaque,
        child: Row(
          children: [
            _buildHeaderAvatar(c),
            SizedBox(width: 12),
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
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  if (subtitle != null && subtitle.isNotEmpty)
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF94A3B8),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          onPressed: _openOrderSummarySheet,
          tooltip:
              AppLocalizations.of(context)?.translate('order_summary') ??
              'Order Summary',
          icon: Icon(
            PhosphorIconsRegular.receipt,
            color: Theme.of(context).textTheme.bodyLarge?.color,
            size: 22,
          ),
        ),
        SizedBox(width: 4),
      ],
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
                child: Text(
                  initial,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            )
          : Center(
              child: Text(
                initial,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
    );
  }

  Widget _buildBody(AppLocalizations? t) {
    if (_isLoading) {
      return Center(
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
            Icon(Icons.cloud_off_rounded, size: 44, color: Color(0xFFCBD5E1)),
            SizedBox(height: 12),
            TextButton(
              onPressed: _loadMessages,
              child: Text(
                t?.translate('retry') ?? 'Retry',
                style: GoogleFonts.poppins(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
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
            fontSize: 14,
            color: (Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF94A3B8)
                : const Color(0xFF64748B)),
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: _messages.length + (_isLoadingOlder ? 1 : 0),
      itemBuilder: (context, index) {
        if (_isLoadingOlder && index == 0) {
          return Padding(
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
            color: Theme.of(context).dividerColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            message.content ?? '',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: (Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFFCBD5E1)
                  : const Color(0xFF64748B)),
            ),
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
          Expanded(
            child: Divider(color: Theme.of(context).dividerColor, height: 1),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              _formatDateSeparator(timestamp),
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: (Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF94A3B8)
                    : const Color(0xFF64748B)),
              ),
            ),
          ),
          Expanded(
            child: Divider(color: Theme.of(context).dividerColor, height: 1),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isMe = message.isMe;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: Theme.of(context).dividerColor,
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
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
              ),
            ),
            SizedBox(width: 8),
          ],
          Flexible(
            child: GestureDetector(
              onLongPress: () => _showMessageActions(message),
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.72,
                ),
                padding:
                    message.kind == ChatMessageKind.image && !message.isDeleted
                    ? const EdgeInsets.all(4)
                    : const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  gradient: isMe && !message.isDeleted
                      ? AppColors.primaryGradient
                      : null,
                  color: message.isDeleted
                      ? Theme.of(context).dividerColor
                      : (isMe
                            ? null
                            : (Theme.of(context).brightness == Brightness.dark
                                  ? const Color(0xFF1E293B)
                                  : Colors.white)),
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
          if (isMe) SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildBubbleContent(ChatMessage message, bool isMe) {
    if (message.isDeleted) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.block_rounded,
            size: 14,
            color: (Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF94A3B8)
                : const Color(0xFF64748B)),
          ),
          SizedBox(width: 6),
          Text(
            'This message was deleted',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontStyle: FontStyle.italic,
              color: (Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF94A3B8)
                  : const Color(0xFF64748B)),
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
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
                  child: Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                errorWidget: (_, _, _) => Container(
                  width: 200,
                  height: 120,
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
                  child: Icon(
                    Icons.broken_image_outlined,
                    color: (Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B)),
                  ),
                ),
              ),
            ),
          ),
          if ((message.content ?? '').isNotEmpty) ...[
            SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                message.content!,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: isMe
                      ? Colors.white
                      : (Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : const Color(0xFF1E293B)),
                ),
              ),
            ),
          ],
          SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            child: _buildMetaRow(message, isMe),
          ),
        ],
      );
    }

    if (message.isVoice &&
        message.voiceUrl != null &&
        message.voiceUrl!.isNotEmpty) {
      final fg = isMe
          ? Colors.white
          : (Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : const Color(0xFF1E293B));
      return Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          AudioMessageBubble(
            url: message.voiceUrl!,
            durationSeconds: message.voiceDurationSeconds,
            isMine: isMe,
            foreground: fg,
            background: Colors.transparent,
          ),
          SizedBox(height: 4),
          _buildMetaRow(message, isMe),
        ],
      );
    }

    final urlRegExp = RegExp(
      r'(?:(?:https?|ftp)://)?[\w/\-?=%.]+\.[\w/\-?=%.]+',
    );
    final urls = urlRegExp
        .allMatches(message.content ?? '')
        .map((m) => m.group(0)!)
        .toList();
    final firstUrl = urls.isNotEmpty ? urls.first : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          message.content ?? '',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: isMe
                ? Colors.white
                : (Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : const Color(0xFF1E293B)),
            height: 1.4,
          ),
        ),
        if (firstUrl != null)
          FutureBuilder(
            future: AnyLinkPreview.getMetadata(
              link: firstUrl.startsWith('http')
                  ? firstUrl
                  : 'https://$firstUrl',
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox.shrink();
              }
              final metadata = snapshot.data;
              if (metadata == null ||
                  metadata.image == null ||
                  metadata.image!.isEmpty) {
                return const SizedBox.shrink();
              }
              return Container(
                margin: const EdgeInsets.only(top: 4),
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.72,
                ),
                child: AnyLinkPreview(
                  link: firstUrl.startsWith('http')
                      ? firstUrl
                      : 'https://$firstUrl',
                  displayDirection: UIDirection.uiDirectionHorizontal,
                  cache: const Duration(hours: 1),
                  backgroundColor: Colors.white,
                  errorWidget: const SizedBox.shrink(),
                  borderRadius: 12,
                ),
              );
            },
          ),
        SizedBox(height: 4),
        _buildMetaRow(message, isMe),
      ],
    );
  }

  Widget _buildMetaRow(ChatMessage message, bool isMe) {
    final mutedColor = isMe
        ? Colors.white.withValues(alpha: 0.7)
        : (Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF94A3B8)
              : const Color(0xFF64748B));
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (message.isEdited) ...[
          Text(
            'edited',
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontStyle: FontStyle.italic,
              color: mutedColor,
            ),
          ),
          SizedBox(width: 4),
        ],
        Text(
          _formatMessageTime(message.createdAt),
          style: GoogleFonts.poppins(
            fontSize: 10,
            fontWeight: FontWeight.w400,
            color: mutedColor,
          ),
        ),
        if (isMe) ...[
          SizedBox(width: 4),
          Icon(
            message.isRead ? Icons.done_all_rounded : Icons.done_rounded,
            size: 14,
            color: message.isRead ? AppColors.primary : mutedColor,
          ),
        ],
      ],
    );
  }

  bool get _isOrderClosed {
    if (_order == null) return false;
    return !ChatWindow.isWritable(_order!.status, _order!.updatedAt);
  }

  Widget _buildClosedOrderAlert(AppLocalizations? t) {
    String statusStr = 'closed';
    final status = _order?.status.toUpperCase();
    if (status == 'DELIVERED') statusStr = 'delivered';
    if (status == 'PICKED_UP') statusStr = 'picked up';
    if (status == 'CANCELED' || status == 'CANCELLED') statusStr = 'canceled';

    final isPostDelivery = status == 'DELIVERED' || status == 'PICKED_UP';
    final title = isPostDelivery
        ? (t?.translate('chat_closed_title') ?? 'Chat closed')
        : 'Chat unavailable';
    final message = isPostDelivery
        ? (t?.translate('chat_closed_body') ??
              'The 4-hour support period ended. You can still review this conversation.')
        : 'This order is $statusStr, so replies are disabled.';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.paddingOf(context).bottom + 16,
      ),
      color: Theme.of(context).cardColor,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF1E293B)
              : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.lock_outline_rounded,
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF94A3B8)
                  : const Color(0xFF64748B),
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFFE2E8F0)
                          : const Color(0xFF334155),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    message,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFFCBD5E1)
                          : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput(AppLocalizations? t) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    final hasText = _messageController.text.trim().isNotEmpty;

    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 8,
        top: 12,
        bottom: bottomInset > 0 ? 12 : safeBottom + 12,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: ValueListenableBuilder<VoiceRecordPhase>(
        valueListenable: _voiceRecorder.phaseNotifier,
        builder: (context, phase, _) {
          final recording = phase != VoiceRecordPhase.idle;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Messenger-style: recording replaces the text box entirely.
              Expanded(
                child: recording
                    ? VoiceRecordingStrip(
                        recorder: _voiceRecorder,
                        isBusy: _isSending,
                        onSend: _sendVoiceMessage,
                      )
                    : Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? const Color(0xFF1E293B)
                              : Theme.of(
                                  context,
                                ).dividerColor.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: TextField(
                          controller: _messageController,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _sendMessage(),
                          maxLines: 4,
                          minLines: 1,
                          decoration: InputDecoration(
                            hintText:
                                t?.translate('type_a_message') ??
                                'Type a message...',
                            hintStyle: GoogleFonts.poppins(
                              fontSize: 14,
                              color:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? const Color(0xFF64748B)
                                  : const Color(0xFF94A3B8),
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 10,
                            ),
                            suffixIcon:
                                ValueListenableBuilder<TextEditingValue>(
                                  valueListenable: _messageController,
                                  builder: (context, value, child) {
                                    if (value.text.isEmpty) {
                                      return const SizedBox.shrink();
                                    }
                                    return IconButton(
                                      icon: Icon(
                                        Icons.clear,
                                        color: Colors.grey,
                                        size: 20,
                                      ),
                                      onPressed: () {
                                        _messageController.clear();
                                      },
                                    );
                                  },
                                ),
                          ),
                        ),
                      ),
              ),
              SizedBox(width: 8),
              if (hasText && !recording)
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
                          ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : PhosphorIcon(
                              PhosphorIconsFill.paperPlaneTilt,
                              size: 20,
                              color: Theme.of(context).cardColor,
                            ),
                    ),
                  ),
                )
              else
                VoiceRecordButton(
                  recorder: _voiceRecorder,
                  enabled: !_isSending && !_isOrderClosed,
                  isBusy: _isSending,
                  onSend: _sendVoiceMessage,
                  onPermissionDenied: () {
                    _showSnack(
                      'Microphone permission is required to send voice messages.',
                    );
                  },
                ),
            ],
          );
        },
      ),
    );
  }
}
