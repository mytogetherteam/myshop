import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_shop/core/utils/app_colors.dart';
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
  late List<Widget> _pages;
  StreamSubscription? _socketSubscription;

  final GlobalKey<OrdersScreenState> _ordersKey =
      GlobalKey<OrdersScreenState>();
  final GlobalKey<MenuPageState> _menuKey = GlobalKey<MenuPageState>();
  final GlobalKey<ReportPageState> _reportKey = GlobalKey<ReportPageState>();
  final GlobalKey<ProfilePageState> _profileKey = GlobalKey<ProfilePageState>();
  final List<bool> _visited = [false, false, false, false];


  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _visited[_currentIndex] = true;
    _pages = [
      OrdersScreen(key: _ordersKey),
      MenuPage(key: _menuKey),
      ReportPage(key: _reportKey),
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

  final List<String> _titles = ['Order', 'Menu', 'Report', 'Profile'];

  Widget _buildGradientItem(IconData icon, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        PhosphorIcon(
          icon,
          size: 28,
          color: const Color(0xFFED3973), // Use primary color directly
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: const Color(0xFFED3973),
          ),
        ),
      ],
    );
  }

  Widget _buildInactiveItem(IconData icon, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        PhosphorIcon(icon, size: 28, color: const Color(0xFF94A3B8)),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF94A3B8),
          ),
        ),
      ],
    );
  }



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
      body: IndexedStack(
        index: _currentIndex,
        children: _pages.asMap().entries.map((entry) {
          final int idx = entry.key;
          final Widget page = entry.value;
          return _visited[idx] ? page : const SizedBox.shrink();
        }).toList(),
      ),

      bottomNavigationBar: SafeArea(
        top: false,
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            if (_currentIndex == index) {
              switch (index) {
                case 0:
                  _ordersKey.currentState?.refresh();
                  break;
                case 1:
                  _menuKey.currentState?.refresh();
                  break;
                case 2:
                  _reportKey.currentState?.refresh();
                  break;
                case 3:
                  _profileKey.currentState?.refresh();
                  break;
              }
            }
            setState(() {
              _currentIndex = index;
              _visited[index] = true;
            });
          },
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFFED3973),
          unselectedItemColor: const Color(0xFF94A3B8),
          showSelectedLabels: false,
          showUnselectedLabels: false,
          selectedFontSize: 0,
          unselectedFontSize: 0,
          type: BottomNavigationBarType.fixed,
          elevation: 8,
          items: [
            BottomNavigationBarItem(
              icon: _buildInactiveItem(PhosphorIconsRegular.cookingPot, 'Order'),
              activeIcon: _buildGradientItem(PhosphorIconsFill.cookingPot, 'Order'),
              label: 'Order',
            ),
            BottomNavigationBarItem(
              icon: _buildInactiveItem(PhosphorIconsRegular.forkKnife, 'Menu'),
              activeIcon: _buildGradientItem(PhosphorIconsFill.forkKnife, 'Menu'),
              label: 'Menu',
            ),
            BottomNavigationBarItem(
              icon: _buildInactiveItem(PhosphorIconsRegular.listHeart, 'Report'),
              activeIcon: _buildGradientItem(PhosphorIconsFill.listHeart, 'Report'),
              label: 'Report',
            ),
            BottomNavigationBarItem(
              icon: _buildInactiveItem(PhosphorIconsRegular.storefront, 'Profile'),
              activeIcon: _buildGradientItem(PhosphorIconsFill.storefront, 'Profile'),
              label: 'Profile',
            ),
          ],
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
