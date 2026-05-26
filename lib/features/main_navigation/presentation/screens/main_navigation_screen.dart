import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_shop/core/utils/app_colors.dart';
import 'package:my_shop/features/menu/presentation/screens/menu_page.dart';
import 'package:my_shop/features/orders/presentation/screens/orders_screen.dart';

import 'package:my_shop/features/profile/presentation/screens/profile_page.dart';
import 'package:my_shop/features/reports/presentation/screens/report_page.dart';
import 'package:my_shop/features/chat/presentation/screens/chat_page.dart';
import 'package:my_shop/features/orders/data/models/order_model.dart';
import 'package:my_shop/features/orders/presentation/widgets/new_order_dialog.dart';
import 'package:my_shop/features/orders/presentation/widgets/order_warning_dialog.dart';
import 'package:my_shop/features/orders/presentation/screens/order_detail_screen.dart';
import 'package:my_shop/core/network/websocket_service.dart';
import 'package:my_shop/features/notifications/presentation/widgets/notification_badge_icon.dart';
import 'package:flutter/services.dart';
import 'package:my_shop/core/presentation/widgets/app_bar_title_with_logo.dart';
import 'dart:async';
import 'package:my_shop/core/localization/app_localizations.dart';

class MainNavigationScreen extends StatefulWidget {
  final int initialIndex;
  const MainNavigationScreen({super.key, this.initialIndex = 0});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late int _currentIndex;
  late List<Widget> _pages;
  StreamSubscription? _socketSubscription;

  final GlobalKey<OrdersScreenState> _ordersKey =
      GlobalKey<OrdersScreenState>();
  final GlobalKey<MenuPageState> _menuKey = GlobalKey<MenuPageState>();
  final GlobalKey<ReportPageState> _reportKey = GlobalKey<ReportPageState>();
  final GlobalKey<ChatPageState> _chatKey = GlobalKey<ChatPageState>();
  final GlobalKey<ProfilePageState> _profileKey = GlobalKey<ProfilePageState>();
  final List<bool> _visited = [false, false, false, false, false];

  // Tracks order IDs that have already triggered a popup in this session, so
  // WebSocket reconnect replays do not spawn duplicate dialogs (which on web
  // can stack invisible modal barriers and block all taps).
  final Set<String> _alertedOrderIds = <String>{};
  bool _isDialogOpen = false;


  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _visited[_currentIndex] = true;
    _pages = [
      OrdersScreen(key: _ordersKey),
      MenuPage(key: _menuKey),
      ReportPage(key: _reportKey),
      ChatPage(key: _chatKey),
      ProfilePage(key: _profileKey),
    ];
    _setupWebSocketListener();


  }

  @override
  void dispose() {
    _socketSubscription?.cancel();
    super.dispose();
  }

  void _setupWebSocketListener() {
    debugPrint('🚀 [MainNavigation] SETTING UP LISTENER...');
    _socketSubscription = WebSocketService().orderUpdates.listen((event) {
      debugPrint(
        '🔔 [MainNavigation] EVENT: ${event['type']}, MSG: ${event['message']}',
      );

      final dynamic rawOrder = event['order'];
      final dynamic rawMsg = event['message'];
      final String? msg = rawMsg?.toString();
      final String eventType = (event['type'] ?? '').toString().toUpperCase();

      // Only treat true push events as alert-worthy; ignore REPLAY/SYNC/initial
      // state that the server resends every WebSocket reconnect.
      final bool isPushEvent =
          eventType == 'NEW_ORDER' ||
          eventType == 'ORDER_UPDATE' ||
          eventType == 'ORDER_WARNING';

      if (!isPushEvent) {
        debugPrint('⏭️ [MainNavigation] Ignoring non-push event: $eventType');
        return;
      }

      if (rawOrder == null) return;

      OrderModel orderData;
      try {
        orderData = OrderModel.fromJson(rawOrder);
      } catch (e) {
        debugPrint('⚠️ [MainNavigation] Failed to parse order: $e');
        return;
      }

      if (!mounted) return;

      // Deduplicate: never show two dialogs for the same order id.
      if (_alertedOrderIds.contains(orderData.id)) {
        debugPrint('⏭️ [MainNavigation] Order ${orderData.id} already alerted');
        return;
      }

      // Never stack dialogs — one at a time only.
      if (_isDialogOpen) {
        debugPrint('⏭️ [MainNavigation] Dialog already open, skipping');
        return;
      }

      final String status = orderData.status.toUpperCase();
      final String? lowerMsg = msg?.toLowerCase();
      final bool isTwoMinWarning = lowerMsg != null &&
          (lowerMsg.contains('2 min') || lowerMsg.contains('2 မိနစ်'));

      Widget? dialog;
      if (isTwoMinWarning) {
        HapticFeedback.vibrate();
        dialog = OrderWarningDialog(
          message: msg!,
          order: orderData,
          onTakeAction: () {
            Navigator.pop(context);
            _navigateToOrderDetail(orderData);
          },
        );
      } else if (eventType == 'NEW_ORDER' || status == 'PENDING' || status == 'NEW') {
        HapticFeedback.heavyImpact();
        dialog = NewOrderDialog(
          order: orderData,
          onViewOrder: () {
            Navigator.pop(context);
            _navigateToOrderDetail(orderData);
          },
        );
      } else if (msg != null && msg.trim().isNotEmpty) {
        HapticFeedback.vibrate();
        dialog = OrderWarningDialog(
          message: msg,
          order: orderData,
          onTakeAction: () {
            Navigator.pop(context);
            _navigateToOrderDetail(orderData);
          },
        );
      }

      if (dialog == null) return;

      _alertedOrderIds.add(orderData.id);
      _isDialogOpen = true;
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (context) => dialog!,
      ).whenComplete(() {
        if (mounted) _isDialogOpen = false;
      });
    });
  }

  Future<void> _navigateToOrderDetail(OrderModel order) async {
    final routeName = 'order_detail_${order.id}';

    // Check if we are already viewing this order
    bool isAlreadyOnThisOrder = false;
    Navigator.popUntil(context, (route) {
      if (route.settings.name == routeName) {
        isAlreadyOnThisOrder = true;
      }
      return true; // Don't actually pop anything
    });

    if (isAlreadyOnThisOrder) {
      debugPrint('Already viewing order ${order.id}, skipping navigation.');
      return;
    }

    final result = await Navigator.push(
      context,
      PageRouteBuilder(
        settings: RouteSettings(name: routeName),
        pageBuilder: (context, animation, secondaryAnimation) =>
            OrderDetailScreen(order: order),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeOut;
          var tween = Tween(
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

    if (result != null && result is String) {
      if (_currentIndex != 0) {
        setState(() => _currentIndex = 0);
      }
      // Wait for build if we just switched tab
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _ordersKey.currentState?.switchToStatus(result);
      });
    }
  }






  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final localizedTitles = [
      t?.translate('order') ?? 'Order',
      t?.translate('menu') ?? 'Menu',
      t?.translate('report') ?? 'Report',
      t?.translate('chat') ?? 'Chat',
      t?.translate('profile') ?? 'Profile',
    ];
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        title: AppBarTitleWithLogo(title: localizedTitles[_currentIndex]),
        actions: [const NotificationBadgeIcon(), const SizedBox(width: 8)],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _pages.asMap().entries.map((entry) {
          final int idx = entry.key;
          final Widget page = entry.value;
          return _visited[idx] ? page : const SizedBox.shrink();
        }).toList(),
      ),

      bottomNavigationBar: _buildBottomNav(t),
    );
  }

  Widget _buildBottomNav(AppLocalizations? t) {
    final items = <_NavItem>[
      _NavItem(
        label: t?.translate('order') ?? 'Order',
        icon: PhosphorIconsRegular.cookingPot,
        activeIcon: PhosphorIconsFill.cookingPot,
        onRefresh: () => _ordersKey.currentState?.refresh(),
      ),
      _NavItem(
        label: t?.translate('menu') ?? 'Menu',
        icon: PhosphorIconsRegular.forkKnife,
        activeIcon: PhosphorIconsFill.forkKnife,
        onRefresh: () => _menuKey.currentState?.refresh(),
      ),
      _NavItem(
        label: t?.translate('report') ?? 'Report',
        icon: PhosphorIconsRegular.listHeart,
        activeIcon: PhosphorIconsFill.listHeart,
        onRefresh: () => _reportKey.currentState?.refresh(),
      ),
      _NavItem(
        label: t?.translate('chat') ?? 'Chat',
        icon: PhosphorIconsRegular.chatCircleDots,
        activeIcon: PhosphorIconsFill.chatCircleDots,
        onRefresh: () => _chatKey.currentState?.refresh(),
      ),
      _NavItem(
        label: t?.translate('profile') ?? 'Profile',
        icon: PhosphorIconsRegular.storefront,
        activeIcon: PhosphorIconsFill.storefront,
        onRefresh: () => _profileKey.currentState?.refresh(),
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.shade100, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: 8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (index) {
              return _buildNavItem(items[index], index);
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(_NavItem item, int index) {
    final bool isSelected = _currentIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () {
          if (isSelected) {
            item.onRefresh();
          } else {
            setState(() {
              _currentIndex = index;
              _visited[index] = true;
            });
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              PhosphorIcon(
                isSelected ? item.activeIcon : item.icon,
                size: 26,
                color: isSelected
                    ? const Color(0xFFED3973)
                    : const Color(0xFF94A3B8),
              ),
              const SizedBox(height: 4),
              Text(
                item.label,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? const Color(0xFFED3973)
                      : const Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /*
  Widget _buildAnalyticsButton() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AnalyticsPage()),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.all(1.2),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const PhosphorIcon(
                PhosphorIconsFill.chartPieSlice,
                size: 14,
                color: Color(0xFFED3973),
              ),
              const SizedBox(width: 4),
              Text(
                "Analytics",
                style: GoogleFonts.poppins(
                  color: const Color(0xFFED3973),
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  */
}

class _NavItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final VoidCallback onRefresh;

  const _NavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.onRefresh,
  });
}
