import 'package:flutter/material.dart';
import 'package:my_shop/core/data/services/storage_service.dart';
import 'package:my_shop/features/main_navigation/presentation/screens/main_navigation_screen.dart';
import 'package:my_shop/features/auth/presentation/screens/login_page.dart';
import 'package:my_shop/features/auth/data/services/auth_service.dart';
import 'package:my_shop/core/network/websocket_service.dart';
import 'package:my_shop/core/presentation/widgets/custom_loading_indicator.dart';
import 'package:my_shop/features/notifications/presentation/screens/notification_permission_screen.dart';
import 'package:my_shop/features/profile/data/services/shop_service.dart';
import 'package:my_shop/features/profile/presentation/screens/global_shop_selection_page.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  late Future<Widget> _initialRouteFuture;

  @override
  void initState() {
    super.initState();
    _initialRouteFuture = _determineInitialRoute();
  }

  Future<Widget> _determineInitialRoute() async {
    final hasToken = await StorageService.instance.hasToken();
    if (!hasToken) return const LoginPage();

    var shopId = await StorageService.instance.getSelectedShopId();
    debugPrint('📍 [AuthWrapper] Current shopId in storage: $shopId');

    try {
      final shops = await ShopService().getShops();
      debugPrint('📍 [AuthWrapper] Found ${shops.length} shops for user');

      if (shops.isNotEmpty) {
        final hasMatchingShop = shopId != null &&
            shops.any((shop) => shop.id == shopId);
        if (!hasMatchingShop) {
          final firstShop = shops.first;
          await StorageService.instance.saveSelectedShopId(firstShop.id);
          shopId = firstShop.id;
          debugPrint(
            '📍 [AuthWrapper] Stored selected shopId: ${firstShop.id}',
          );
        }
      } else {
        await StorageService.instance.removeSelectedShopId();
        shopId = null;
      }
    } catch (e) {
      debugPrint('📍 [AuthWrapper] Error validating shopId: $e');
      return const GlobalShopSelectionPage(isInitialFlow: true);
    }

    if (shopId == null) {
      try {
        final shops = await ShopService().getShops();
        if (shops.isEmpty) {
          debugPrint('📍 [AuthWrapper] No shops found, proceeding to home');
          // No shops available, continue to home
        } else {
          final firstShop = shops.first;
          debugPrint(
            '📍 [AuthWrapper] Auto-selecting first shop: ${firstShop.name}',
          );
          await StorageService.instance.saveSelectedShopId(firstShop.id);
          shopId = firstShop.id;
        }
      } catch (e) {
        debugPrint('📍 [AuthWrapper] Error fetching shops: $e');
        return const GlobalShopSelectionPage(isInitialFlow: true);
      }
    }

    WebSocketService().connect();
    
    // Verify the token by fetching the user profile
    try {
      await AuthService.instance.getAccessToken(); // Simple check for now
    } catch (e) {
      await StorageService.instance.clearAll();
      return const LoginPage();
    }
    
    /*
    final notiHandled = await StorageService.instance.isNotificationHandled();
    if (!notiHandled) {
      return const NotificationPermissionScreen();
    }
    */
    
    return const MainNavigationScreen();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _initialRouteFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CustomLoadingIndicator(size: 40)),
          );
        }

        if (snapshot.hasError) {
          return const LoginPage(); 
        }

        return snapshot.data ?? const LoginPage();
      },
    );
  }
}
