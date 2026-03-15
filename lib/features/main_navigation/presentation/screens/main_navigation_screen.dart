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
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'dart:async';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0; // Set to Order tab as default based on request
  StreamSubscription? _socketSubscription;

  @override
  void initState() {
    super.initState();
    _setupWebSocketListener();
  }

  @override
  void dispose() {
    _socketSubscription?.cancel();
    super.dispose();
  }

  void _setupWebSocketListener() {
    print('🚀 [MainNavigation] SETTING UP LISTENER...');
    _socketSubscription = WebSocketService().orderUpdates.listen((event) {
      print('🔔 [MainNavigation] EVENT: ${event['type']}, MSG: ${event['message']}');
      
      final dynamic rawOrder = event['order'];
      final dynamic rawMsg = event['message'];
      final String? msg = rawMsg?.toString();
      
      if (rawOrder != null) {
        final orderData = OrderModel.fromJson(rawOrder);
        
        if (mounted) {
          final String status = orderData.status.toUpperCase();
          final String? lowerMsg = msg?.toLowerCase();
          final bool isTwoMinWarning = lowerMsg != null && (lowerMsg.contains('2 min') || lowerMsg.contains('2 မိနစ်'));
          
          debugPrint('🧪 [MainNavigation] LOGIC CHECK -> Status: $status, isTwoMin: $isTwoMinWarning, Msg: $msg');

          if (isTwoMinWarning) {
            debugPrint('⚠️ [MainNavigation] TRIGGERING OrderWarningDialog (2-min alert)');
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
          } else if (status == 'PENDING' || status == 'NEW' || event['type'] == 'NEW_ORDER') {
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
            debugPrint('⚠️ [MainNavigation] TRIGGERING OrderWarningDialog (Generic message)');
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

  void _navigateToOrderDetail(OrderModel order) {
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

    Navigator.push(
      context,
      CupertinoPageRoute(
        settings: RouteSettings(name: routeName),
        builder: (_) => OrderDetailScreen(order: order),
      ),
    );
  }

  final List<Widget> _pages = const [
    OrdersScreen(),
    MenuPage(),
    ReportPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            unselectedItemColor: const Color(0xFF94A3B8), // slate-400 equivalent for generic grey
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
                activeIcon: PhosphorIcon(PhosphorIconsFill.cookingPot, size: 28),
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
                activeIcon: PhosphorIcon(PhosphorIconsFill.storefront, size: 28),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
