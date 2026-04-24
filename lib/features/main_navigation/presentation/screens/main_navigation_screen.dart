import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_shop/features/menu/presentation/screens/menu_page.dart';
import 'package:my_shop/features/orders/presentation/screens/orders_screen.dart';

import 'package:my_shop/features/profile/presentation/screens/profile_page.dart';
import 'package:my_shop/features/reports/presentation/screens/report_page.dart';
import 'package:my_shop/features/orders/data/models/order_model.dart';
import 'package:my_shop/features/orders/presentation/widgets/new_order_dialog.dart';
import 'package:my_shop/features/orders/presentation/widgets/order_warning_dialog.dart';
import 'package:my_shop/features/orders/presentation/screens/order_detail_screen.dart';
import 'package:my_shop/core/network/websocket_service.dart';
import 'package:my_shop/features/notifications/presentation/widgets/notification_badge_icon.dart';
import 'package:flutter/services.dart';
import 'package:my_shop/core/presentation/widgets/app_bar_title_with_logo.dart';
import 'dart:async';

class MainNavigationScreen extends StatefulWidget {
  final int initialIndex;
  const MainNavigationScreen({super.key, this.initialIndex = 0});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late int _currentIndex;
  StreamSubscription? _socketSubscription;
  final GlobalKey<OrdersScreenState> _ordersKey =
      GlobalKey<OrdersScreenState>();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
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

      if (rawOrder != null) {
        final orderData = OrderModel.fromJson(rawOrder);

        if (mounted) {
          final String status = orderData.status.toUpperCase();
          final String? lowerMsg = msg?.toLowerCase();
          final bool isTwoMinWarning =
              lowerMsg != null &&
              (lowerMsg.contains('2 min') || lowerMsg.contains('2 မိနစ်'));

          debugPrint(
            '🧪 [MainNavigation] LOGIC CHECK -> Status: $status, isTwoMin: $isTwoMinWarning, Msg: $msg',
          );

          if (isTwoMinWarning) {
            debugPrint(
              '⚠️ [MainNavigation] TRIGGERING OrderWarningDialog (2-min alert)',
            );
            HapticFeedback.vibrate();
            showDialog(
              context: context,
              barrierDismissible: true,
              builder: (context) => OrderWarningDialog(
                message: msg!,
                order: orderData,
                onTakeAction: () {
                  Navigator.pop(context);
                  _navigateToOrderDetail(orderData);
                },
              ),
            );
          } else if (status == 'PENDING' ||
              status == 'NEW' ||
              event['type'] == 'NEW_ORDER') {
            debugPrint('📦 [MainNavigation] TRIGGERING NewOrderDialog');
            HapticFeedback.heavyImpact();
            showDialog(
              context: context,
              barrierDismissible: true,
              builder: (context) => NewOrderDialog(
                order: orderData,
                onViewOrder: () {
                  Navigator.pop(context);
                  _navigateToOrderDetail(orderData);
                },
              ),
            );
          } else if (msg != null && msg.trim().isNotEmpty) {
            // Generic warning for other status updates with messages
            debugPrint(
              '⚠️ [MainNavigation] TRIGGERING OrderWarningDialog (Generic message)',
            );
            HapticFeedback.vibrate();
            showDialog(
              context: context,
              barrierDismissible: true,
              builder: (context) => OrderWarningDialog(
                message: msg,
                order: orderData,
                onTakeAction: () {
                  Navigator.pop(context);
                  _navigateToOrderDetail(orderData);
                },
              ),
            );
          }
        }
      }
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

  List<Widget> get _pages => [
    OrdersScreen(key: _ordersKey),
    const MenuPage(),
    const ReportPage(),
    const ProfilePage(),
  ];

  final List<String> _titles = ['Order', 'Menu', 'Report', 'Profile'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        title: AppBarTitleWithLogo(title: _titles[_currentIndex]),
        actions: [const NotificationBadgeIcon(), const SizedBox(width: 8)],
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ClipRRect(
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            backgroundColor: Colors.white,
            selectedItemColor: const Color(0xFFED3A72),
            unselectedItemColor: const Color(
              0xFF94A3B8,
            ), // slate-400 equivalent for generic grey
            selectedLabelStyle: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            unselectedLabelStyle: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            type: BottomNavigationBarType.fixed,
            elevation: 0,
            items: [
              BottomNavigationBarItem(
                icon: PhosphorIcon(PhosphorIconsRegular.cookingPot, size: 28),
                activeIcon: PhosphorIcon(
                  PhosphorIconsFill.cookingPot,
                  size: 28,
                ),
                label: 'Order',
              ),
              BottomNavigationBarItem(
                icon: PhosphorIcon(PhosphorIconsRegular.forkKnife, size: 28),
                activeIcon: PhosphorIcon(PhosphorIconsFill.forkKnife, size: 28),
                label: 'Menu',
              ),
              BottomNavigationBarItem(
                icon: PhosphorIcon(PhosphorIconsRegular.listHeart, size: 28),
                activeIcon: PhosphorIcon(PhosphorIconsFill.listHeart, size: 28),
                label: 'Report',
              ),
              BottomNavigationBarItem(
                icon: PhosphorIcon(PhosphorIconsRegular.storefront, size: 28),
                activeIcon: PhosphorIcon(
                  PhosphorIconsFill.storefront,
                  size: 28,
                ),
                label: 'Profile',
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
          gradient: const LinearGradient(
            colors: [Color(0xFFED3A72), Color(0xFFFB923C)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
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
                color: Color(0xFFED3A72),
              ),
              const SizedBox(width: 4),
              Text(
                "Analytics",
                style: GoogleFonts.poppins(
                  color: const Color(0xFFED3A72),
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
