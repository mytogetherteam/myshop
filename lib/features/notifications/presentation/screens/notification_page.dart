import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:my_shop/features/notifications/data/models/notification_model.dart';
import 'package:my_shop/features/notifications/data/repositories/notification_repository.dart';
import 'package:my_shop/features/orders/presentation/screens/order_detail_screen.dart';
import 'package:my_shop/features/orders/data/services/order_service.dart';
import 'package:my_shop/core/presentation/widgets/custom_loading_indicator.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final NotificationRepository _notificationRepository = NotificationRepository();
  final ScrollController _scrollController = ScrollController();
  
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;
  bool _showLoadingThreshold = false;
  Timer? _loadingTimer;
  bool _isMoreLoading = false;
  int _currentPage = 0;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _startLoadingTimer();
    _fetchNotifications();
    _scrollController.addListener(_onScroll);
  }

  void _startLoadingTimer() {
    _loadingTimer?.cancel();
    _loadingTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _showLoadingThreshold = true);
    });
  }

  @override
  void dispose() {
    _loadingTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.8 &&
        !_isMoreLoading &&
        _hasMore) {
      _loadMore();
    }
  }

  Future<void> _fetchNotifications({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _currentPage = 0;
        _isLoading = true;
        _showLoadingThreshold = false;
        _hasMore = true;
      });
      _startLoadingTimer();
    }

    final response = await _notificationRepository.getNotifications(page: _currentPage);
    if (mounted) {
      setState(() {
        if (response != null) {
          if (refresh) {
            _notifications = response.content;
          } else {
            _notifications.addAll(response.content);
          }
          _hasMore = !response.isEmpty && response.number < response.totalPages - 1;
        }
        _isLoading = false;
        _isMoreLoading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    setState(() => _isMoreLoading = true);
    _currentPage++;
    await _fetchNotifications();
  }

  Future<void> _markAllRead() async {
    final success = await _notificationRepository.markAllAsRead();
    if (success && mounted) {
      _fetchNotifications(refresh: true);
    }
  }

  Future<void> _handleNotificationClick(NotificationModel noti) async {
    if (!noti.isRead) {
      await _notificationRepository.markAsRead(noti.id);
      if (mounted) {
        setState(() {
          final index = _notifications.indexWhere((n) => n.id == noti.id);
          if (index != -1) {
            _notifications[index] = NotificationModel(
              id: noti.id,
              title: noti.title,
              body: noti.body,
              titleMm: noti.titleMm,
              bodyMm: noti.bodyMm,
              type: noti.type,
              referenceId: noti.referenceId,
              imageUrl: noti.imageUrl,
              sentAt: noti.sentAt,
              readAt: DateTime.now(),
              isRead: true,
            );
          }
        });
      }
    }

    // Deep Navigation Logic
    if (mounted && noti.referenceId != null) {
      if (noti.type == NotificationType.orderStatus || noti.type == NotificationType.newOrder) {
        _navigateToOrder(noti.referenceId!);
      }
    }
  }

  Future<void> _navigateToOrder(int orderId) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CustomLoadingIndicator(size: 40, color: Colors.white),
      ),
    );

    final order = await OrderService().getOrderDetail(orderId.toString());
    
    if (mounted) {
      Navigator.pop(context); // Close loading
      if (order != null) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => OrderDetailScreen(order: order)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not find order details.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context, true), // Return true to refresh parent count
        ),
        title: Text(
          'Notifications',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1E293B),
          ),
        ),
        actions: [
          if (_notifications.any((n) => !n.isRead))
            TextButton(
              onPressed: _markAllRead,
              child: Text(
                'Mark all read',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFED3A72),
                ),
              ),
            ),
        ],
      ),
      body: (_isLoading && _showLoadingThreshold)
          ? const Center(child: CustomLoadingIndicator(color: Colors.white))
          : RefreshIndicator(
              onRefresh: () => _fetchNotifications(refresh: true),
              child: _notifications.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      controller: _scrollController,
                      itemCount: _notifications.length + (_isMoreLoading ? 1 : 0),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      itemBuilder: (context, index) {
                        if (index == _notifications.length) {
                          return const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Center(
                              child: CustomLoadingIndicator(size: 20, color: Colors.white),
                            ),
                          );
                        }
                        return _buildNotificationItem(_notifications[index]);
                      },
                    ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: const Icon(PhosphorIconsRegular.bellSlash, size: 48, color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 16),
          Text(
            'No notifications yet',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(NotificationModel noti) {
    return InkWell(
      onTap: () => _handleNotificationClick(noti),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: noti.isRead ? Colors.white : const Color(0xFFED3A72).withValues(alpha: 0.04),
          border: const Border(
            bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _getIconBgColor(noti),
                shape: BoxShape.circle,
              ),
              child: Icon(_getIcon(noti), size: 20, color: _getIconColor(noti)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          noti.displayTitle,
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: noti.isRead ? FontWeight.w600 : FontWeight.w700,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                      ),
                      Text(
                        noti.timeAgo,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    noti.displayBody,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: _isCancelMessage(noti.displayTitle, noti.displayBody) 
                          ? const Color(0xFFEF4444) 
                          : const Color(0xFF64748B),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            if (!noti.isRead)
              Container(
                margin: const EdgeInsets.only(left: 12, top: 4),
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFFED3A72),
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  bool _isCancelMessage(String title, String body) {
    final lowerTitle = title.toLowerCase();
    final lowerBody = body.toLowerCase();
    return lowerTitle.contains('cancel') || 
           lowerBody.contains('cancel') || 
           lowerTitle.contains('ပယ်ဖျက်') || 
           lowerBody.contains('ပယ်ဖျက်');
  }

  IconData _getIcon(NotificationModel noti) {
    if (_isCancelMessage(noti.title, noti.body)) {
      return PhosphorIconsFill.xCircle;
    }

    final lowerTitle = noti.title.toLowerCase();
    final lowerBody = noti.body.toLowerCase();

    if (noti.type == NotificationType.newOrder || lowerTitle.contains('new order') || lowerTitle.contains('အော်ဒါအသစ်')) {
      return PhosphorIconsFill.shoppingBagOpen;
    }

    if (noti.type == NotificationType.urgentPending) {
      return PhosphorIconsFill.warning;
    }

    // Payment/Slip Requested
    if (lowerTitle.contains('slip') || lowerBody.contains('slip') || lowerTitle.contains('payment') || lowerBody.contains('payment')) {
      return PhosphorIconsFill.creditCard;
    }

    // Status specific detections
    if (lowerTitle.contains('pending') || lowerBody.contains('pending')) {
      return PhosphorIconsFill.clock;
    }
    if (lowerTitle.contains('accept') || lowerTitle.contains('confirm') || lowerBody.contains('accepted') || lowerBody.contains('confirmed')) {
      return PhosphorIconsFill.checkCircle;
    }
    if (lowerTitle.contains('cook') || lowerBody.contains('cook') || lowerTitle.contains('preparing') || lowerTitle.contains('ချက်ပြုတ်')) {
      return PhosphorIconsFill.cookingPot;
    }
    if (lowerTitle.contains('ready') || lowerBody.contains('ready') || lowerTitle.contains('pickup')) {
      return PhosphorIconsFill.package;
    }
    if (lowerTitle.contains('delivery') || lowerTitle.contains('out for delivery') || lowerBody.contains('delivering')) {
      return PhosphorIconsFill.bicycle;
    }
    if (lowerTitle.contains('complete') || lowerBody.contains('completed') || lowerTitle.contains('ပြီးဆုံး')) {
      return PhosphorIconsFill.checkCircle;
    }
    if (lowerTitle.contains('refund') || lowerBody.contains('refunded')) {
      return PhosphorIconsFill.receipt;
    }

    switch (noti.type) {
      case NotificationType.orderStatus:
        return PhosphorIconsFill.truck;
      default:
        return PhosphorIconsFill.bell;
    }
  }

  Color _getIconColor(NotificationModel noti) {
    if (_isCancelMessage(noti.title, noti.body)) {
      return const Color(0xFFEF4444);
    }
    return const Color(0xFFED3A72); // Primary for all other status icons
  }

  Color _getIconBgColor(NotificationModel noti) {
    return _getIconColor(noti).withValues(alpha: 0.1);
  }
}
