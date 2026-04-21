import 'package:flutter/material.dart';
import 'package:my_shop/core/data/services/storage_service.dart';
import 'package:my_shop/features/main_navigation/presentation/screens/main_navigation_screen.dart';
import 'package:my_shop/features/auth/presentation/screens/login_page.dart';
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
    if (shopId == null) {
      try {
        final shops = await ShopService().getShops();
        if (shops.isEmpty) {
          // No shops available, continue to home (create shop flow usually)
        } else if (shops.length == 1) {
          await StorageService.instance.saveSelectedShopId(shops.first.id);
          shopId = shops.first.id;
        } else {
          return const GlobalShopSelectionPage(isInitialFlow: true);
        }
      } catch (e) {
        return const GlobalShopSelectionPage(isInitialFlow: true);
      }
    }

    WebSocketService().connect();
    
    final notiHandled = await StorageService.instance.isNotificationHandled();
    if (!notiHandled) {
      return const NotificationPermissionScreen();
    }
    
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
