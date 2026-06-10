import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:my_shop/features/notifications/data/models/notification_model.dart';
import 'package:my_shop/features/notifications/data/repositories/notification_repository.dart';
import 'package:my_shop/features/orders/presentation/screens/order_detail_screen.dart';
import 'package:my_shop/features/orders/data/services/order_service.dart';
import 'package:my_shop/core/presentation/widgets/custom_loading_indicator.dart';
import 'package:my_shop/core/presentation/widgets/back_title_app_bar.dart';
import 'package:my_shop/core/presentation/widgets/empty_state.dart';
import 'package:my_shop/core/presentation/widgets/skeleton.dart';
import 'package:my_shop/core/presentation/widgets/skeleton_list.dart';
import 'package:my_shop/core/utils/app_colors.dart';
import 'package:my_shop/core/presentation/widgets/app_dialog.dart';
import 'package:my_shop/core/localization/app_localizations.dart';

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
          _hasMore = !response.isEmpty && response.page < response.totalPages - 1;
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
              message: noti.message,
              mainType: noti.mainType,
              subType: noti.subType,
              orderId: noti.orderId,
              data: noti.data,
              createdAt: noti.createdAt,
              isRead: true,
            );
          }
        });
      }
    }

    // Deep Navigation Logic
    if (mounted && noti.orderId != null) {
      if (noti.subType.isOrderRelated || noti.mainType == NotificationMainType.order) {
        _navigateToOrder(noti.orderId!);
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
        await Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => OrderDetailScreen(order: order),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              const begin = Offset(1.0, 0.0);
              const end = Offset.zero;
              const curve = Curves.easeOut;
              var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
              return SlideTransition(position: animation.drive(tween), child: child);
            },
            reverseTransitionDuration: Duration.zero,
          ),
        );

        // If we popped with a status, we might want to tell the main screen
        // But NotificationPage is a separate page. 
        // We can't easily find MainNavigationScreen here without a GlobalKey or similar.
        // However, if the user returns to the list later, the status might have changed.
      } else {
        AppDialog.showToast(context, AppLocalizations.of(context)?.translate('could_not_find_order_details') ?? 'Could not find order details.', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: BackTitleAppBar(
        title: t?.translate('notifications') ?? 'Notifications',
        onBack: () => Navigator.pop(context, true),
      ),
      body: RefreshIndicator(
        onRefresh: () => _fetchNotifications(refresh: true),
        color: AppColors.primary,
        child: (_isLoading && _showLoadingThreshold)
            ? SkeletonList(
                itemCount: 8,
                padding: const EdgeInsets.symmetric(vertical: 12),
                itemBuilder: (_, _) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(bottom: BorderSide(color: AppColors.surfaceVariant, width: 1)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Skeleton.circle(width: 40, height: 40),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(child: Skeleton(height: 14, width: 160)),
                                SizedBox(width: 12),
                                Skeleton(height: 10, width: 40),
                              ],
                            ),
                            SizedBox(height: 8),
                            Skeleton(height: 12, width: double.infinity),
                            SizedBox(height: 6),
                            Skeleton(height: 12, width: 200),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : _notifications.isEmpty
                ? EmptyState(
                    circleBackground: true,
                    icon: const Icon(PhosphorIconsRegular.bellSlash, size: 48, color: AppColors.outline),
                    title: t?.translate('no_notifications_yet') ?? 'No Notifications Yet',
                  )
                : ListView.builder(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
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

  Widget _buildNotificationItem(NotificationModel noti) {
    return InkWell(
      onTap: () => _handleNotificationClick(noti),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: noti.isRead ? Colors.white : const Color(0xFFED3973).withValues(alpha: 0.04),
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
                  if (noti.displayBody.isNotEmpty && 
                      noti.displayBody.toLowerCase() != noti.displayTitle.toLowerCase()) ...[
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
                ],
              ),
            ),
            if (!noti.isRead)
              Container(
                margin: const EdgeInsets.only(left: 12, top: 4),
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFFED3973),
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
      return PhosphorIconsFill.moped;
    }
    if (lowerTitle.contains('complete') || lowerBody.contains('completed') || lowerTitle.contains('ပြီးဆုံး')) {
      return PhosphorIconsFill.checkCircle;
    }
    if (lowerTitle.contains('refund') || lowerBody.contains('refunded')) {
      return PhosphorIconsFill.receipt;
    }

    switch (noti.type) {
      case NotificationType.orderStatus:
        return PhosphorIconsFill.bicycle;
      default:
        return PhosphorIconsFill.bell;
    }
  }

  Color _getIconColor(NotificationModel noti) {
    if (_isCancelMessage(noti.title, noti.body)) {
      return const Color(0xFFEF4444);
    }
    return const Color(0xFFED3973); // Primary for all other status icons
  }

  Color _getIconBgColor(NotificationModel noti) {
    return _getIconColor(noti).withValues(alpha: 0.1);
  }
}
