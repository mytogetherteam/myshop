import 'package:flutter/material.dart';
import 'package:my_shop/core/data/services/storage_service.dart';
import 'package:my_shop/features/main_navigation/presentation/screens/main_navigation_screen.dart';
import 'package:my_shop/features/auth/presentation/screens/login_page.dart';
import 'package:my_shop/core/network/websocket_service.dart';
import 'package:my_shop/core/presentation/widgets/custom_loading_indicator.dart';
import 'package:my_shop/features/notifications/presentation/screens/notification_permission_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: StorageService.instance.hasToken(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CustomLoadingIndicator(size: 40)),
          );
        }

        if (snapshot.data == true) {
          WebSocketService().connect();
          return FutureBuilder<bool>(
            future: StorageService.instance.isNotificationHandled(),
            builder: (context, notiSnapshot) {
              if (notiSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CustomLoadingIndicator(size: 40)),
                );
              }
              if (notiSnapshot.data == false) {
                return const NotificationPermissionScreen();
              }
              return const MainNavigationScreen();
            },
          );
        } else {
          return const LoginPage();
        }
      },
    );
  }
}
