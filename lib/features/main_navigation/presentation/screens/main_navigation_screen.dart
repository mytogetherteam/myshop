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
import 'package:my_shop/core/utils/app_logger.dart';
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
    AppLogger.realtime('MainNavigation: setting up listener');
    _socketSubscription = WebSocketService().orderUpdates.listen((event) {
      AppLogger.realtime(
        'MainNavigation event: ${event['type']}, msg: ${event['message']}',
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

          AppLogger.realtime(
            'MainNavigation logic check -> status: $status, isTwoMin: $isTwoMinWarning',
          );

          if (isTwoMinWarning) {
            AppLogger.realtime('MainNavigation: triggering OrderWarningDialog (2-min)');
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
            AppLogger.realtime('MainNavigation: triggering NewOrderDialog');
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
            AppLogger.realtime('MainNavigation: triggering OrderWarningDialog (generic)');
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
      AppLogger.realtime('Already viewing order ${order.id}, skipping navigation.');
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



  Widget _buildGradientItem(IconData icon, String label) {
    return ShaderMask(
      shaderCallback: (Rect bounds) {
        return AppColors.primaryGradient.createShader(bounds);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PhosphorIcon(icon, size: 28, color: Colors.white),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
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

      bottomNavigationBar: BottomNavigationBar(
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
                _chatKey.currentState?.refresh();
                break;
              case 4:
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
            icon: _buildInactiveItem(PhosphorIconsRegular.cookingPot, t?.translate('order') ?? 'Order'),
            activeIcon: _buildGradientItem(PhosphorIconsFill.cookingPot, t?.translate('order') ?? 'Order'),
            label: t?.translate('order') ?? 'Order',
          ),
          BottomNavigationBarItem(
            icon: _buildInactiveItem(PhosphorIconsRegular.forkKnife, t?.translate('menu') ?? 'Menu'),
            activeIcon: _buildGradientItem(PhosphorIconsFill.forkKnife, t?.translate('menu') ?? 'Menu'),
            label: t?.translate('menu') ?? 'Menu',
          ),
          BottomNavigationBarItem(
            icon: _buildInactiveItem(PhosphorIconsRegular.listHeart, t?.translate('report') ?? 'Report'),
            activeIcon: _buildGradientItem(PhosphorIconsFill.listHeart, t?.translate('report') ?? 'Report'),
            label: t?.translate('report') ?? 'Report',
          ),
          BottomNavigationBarItem(
            icon: _buildInactiveItem(PhosphorIconsRegular.chatCircleDots, t?.translate('chat') ?? 'Chat'),
            activeIcon: _buildGradientItem(PhosphorIconsFill.chatCircleDots, t?.translate('chat') ?? 'Chat'),
            label: t?.translate('chat') ?? 'Chat',
          ),
          BottomNavigationBarItem(
            icon: _buildInactiveItem(PhosphorIconsRegular.storefront, t?.translate('profile') ?? 'Profile'),
            activeIcon: _buildGradientItem(PhosphorIconsFill.storefront, t?.translate('profile') ?? 'Profile'),
            label: t?.translate('profile') ?? 'Profile',
          ),
        ],
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
