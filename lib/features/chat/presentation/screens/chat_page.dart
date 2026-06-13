import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_shop/core/network/websocket_service.dart';
import 'package:my_shop/core/utils/app_colors.dart';
import 'package:my_shop/core/localization/app_localizations.dart';
import 'package:my_shop/features/chat/data/models/chat_model.dart';
import 'package:my_shop/features/chat/data/services/chat_service.dart';
import 'package:my_shop/features/chat/data/services/chat_unread_controller.dart';
import 'package:my_shop/features/chat/presentation/chat_navigation.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => ChatPageState();
}

class ChatPageState extends State<ChatPage> with AutomaticKeepAliveClientMixin {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<ChatConversation> _conversations = [];
  List<ChatConversation> _filteredConversations = [];

  bool _isLoading = true;
  bool _hasError = false;
  bool _isLoadingMore = false;
  int _currentPage = 1;
  int _lastPage = 1;

  StreamSubscription<Map<String, dynamic>>? _chatSub;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_onScroll);
    _chatSub = WebSocketService().chatUpdates.listen(_onChatEvent);
    _loadConversations();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _chatSub?.cancel();
    super.dispose();
  }

  Future<void> _loadConversations() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    final result = await ChatService.instance.getConversations(page: 1);
    if (!mounted) return;

    setState(() {
      _isLoading = false;
      if (result == null) {
        _hasError = true;
      } else {
        _hasError = false;
        _conversations = result.items;
        _currentPage = result.currentPage;
        _lastPage = result.lastPage;
      }
      _applyFilter();
    });
  }

  Future<void> _refresh() async {
    final result = await ChatService.instance.getConversations(page: 1);
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (result != null) {
        _hasError = false;
        _conversations = result.items;
        _currentPage = result.currentPage;
        _lastPage = result.lastPage;
      }
      _applyFilter();
    });
  }

  /// Called by the parent navigation when the chat tab is re-tapped.
  void refresh() {
    _refresh();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _currentPage < _lastPage &&
        _searchController.text.trim().isEmpty) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    setState(() => _isLoadingMore = true);
    final result =
        await ChatService.instance.getConversations(page: _currentPage + 1);
    if (!mounted) return;
    setState(() {
      _isLoadingMore = false;
      if (result != null) {
        _conversations = [..._conversations, ...result.items];
        _currentPage = result.currentPage;
        _lastPage = result.lastPage;
      }
      _applyFilter();
    });
  }

  void _onChatEvent(Map<String, dynamic> event) {
    final conversationId = (event['conversationId'] as num?)?.toInt();
    if (conversationId == null || !mounted) return;

    final index = _conversations.indexWhere((c) => c.id == conversationId);
    final message = (event['message'] as Map?)?.cast<String, dynamic>();
    final preview = ChatConversation.previewFor(message);
    final unread = (event['shopUnreadCount'] as num?)?.toInt();

    if (index == -1) {
      // New conversation we don't know about yet — reload the inbox.
      _refresh();
      return;
    }

    final existing = _conversations[index];
    final updated = existing.copyWith(
      lastMessage: preview.isNotEmpty ? preview : existing.lastMessage,
      timestamp: DateTime.now(),
      unreadCount: unread ?? existing.unreadCount,
    );

    setState(() {
      _conversations
        ..removeAt(index)
        ..insert(0, updated);
      _applyFilter();
    });
  }

  void _markConversationRead(int conversationId) {
    final index = _conversations.indexWhere((c) => c.id == conversationId);
    if (index == -1) return;
    setState(() {
      _conversations[index] = _conversations[index].copyWith(unreadCount: 0);
      _applyFilter();
    });
    // The detail screen marked the thread read on the backend; sync the badge.
    ChatUnreadController.instance.refresh();
  }

  void _onSearchChanged() => setState(_applyFilter);

  void _applyFilter() {
    final query = _searchController.text.toLowerCase().trim();
    if (query.isEmpty) {
      _filteredConversations = _conversations;
    } else {
      _filteredConversations = _conversations
          .where((c) =>
              c.name.toLowerCase().contains(query) ||
              c.lastMessage.toLowerCase().contains(query) ||
              (c.orderNo?.toLowerCase().contains(query) ?? false))
          .toList();
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inMinutes < 1) return 'Now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${timestamp.day}/${timestamp.month}';
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final t = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          // Search bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _searchController,
                style: GoogleFonts.poppins(
                    fontSize: 14, color: const Color(0xFF1E293B)),
                decoration: InputDecoration(
                  hintText: t?.translate('search_hint') ?? 'Search...',
                  hintStyle: GoogleFonts.poppins(
                    fontSize: 14,
                    color: const Color(0xFF94A3B8),
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: Color(0xFF94A3B8),
                    size: 20,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),

          Expanded(child: _buildBody(t)),
        ],
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
      return _buildErrorState(t);
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _refresh,
      child: _filteredConversations.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                    height: MediaQuery.of(context).size.height * 0.6,
                    child: _buildEmptyState(t)),
              ],
            )
          : ListView.builder(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(top: 8, bottom: 20),
              itemCount: _filteredConversations.length + (_isLoadingMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= _filteredConversations.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  );
                }
                return _buildConversationTile(_filteredConversations[index]);
              },
            ),
    );
  }

  Widget _buildErrorState(AppLocalizations? t) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_off_rounded, size: 44, color: Color(0xFFCBD5E1)),
          const SizedBox(height: 12),
          Text(
            t?.translate('something_went_wrong') ?? 'Something went wrong',
            style: GoogleFonts.poppins(
              color: const Color(0xFF475569),
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _loadConversations,
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

  Widget _buildEmptyState(AppLocalizations? t) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.getFadedColor(AppColors.primary, 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.chat_bubble_outline_rounded,
              size: 36,
              color: Color(0xFFCBD5E1),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            t?.translate('no_chats_yet') ?? 'No Chats Yet',
            style: GoogleFonts.poppins(
              color: const Color(0xFF475569),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              t?.translate('no_chats_yet_subtitle') ??
                  'When customers message you, their conversations will appear here.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: const Color(0xFF94A3B8),
                fontSize: 13,
                fontWeight: FontWeight.w400,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationTile(ChatConversation conversation) {
    final hasUnread = conversation.unreadCount > 0;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          await ChatNavigation.open(context, conversation);
          // Detail screen marks the conversation as read on open.
          _markConversationRead(conversation.id);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1),
            ),
          ),
          child: Row(
            children: [
              _buildAvatar(conversation, hasUnread),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            conversation.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight:
                                  hasUnread ? FontWeight.w600 : FontWeight.w500,
                              color: const Color(0xFF1E293B),
                            ),
                          ),
                        ),
                        if (conversation.orderNo != null)
                          Text(
                            conversation.orderNo!,
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF94A3B8),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      conversation.lastMessage,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight:
                            hasUnread ? FontWeight.w500 : FontWeight.w400,
                        color: hasUnread
                            ? const Color(0xFF475569)
                            : const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatTimestamp(conversation.timestamp),
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight:
                          hasUnread ? FontWeight.w600 : FontWeight.w400,
                      color: hasUnread
                          ? AppColors.primary
                          : const Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (hasUnread)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${conversation.unreadCount}',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    )
                  else
                    const SizedBox(height: 20),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(ChatConversation conversation, bool hasUnread) {
    final url = conversation.avatarUrl;
    final initial =
        conversation.name.isNotEmpty ? conversation.name[0].toUpperCase() : '?';
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        gradient: hasUnread && (url == null || url.isEmpty)
            ? AppColors.primaryGradient
            : null,
        color: (url == null || url.isEmpty) && !hasUnread
            ? const Color(0xFFE2E8F0)
            : null,
        shape: BoxShape.circle,
      ),
      clipBehavior: Clip.antiAlias,
      child: (url != null && url.isNotEmpty)
          ? CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.cover,
              placeholder: (_, _) => const ColoredBox(color: Color(0xFFE2E8F0)),
              errorWidget: (_, _, _) => _avatarInitial(initial, hasUnread),
            )
          : _avatarInitial(initial, hasUnread),
    );
  }

  Widget _avatarInitial(String initial, bool hasUnread) {
    return Center(
      child: Text(
        initial,
        style: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: hasUnread ? Colors.white : const Color(0xFF64748B),
        ),
      ),
    );
  }
}
