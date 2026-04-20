import 'package:flutter/material.dart';
import 'package:my_shop/core/data/services/storage_service.dart';
import 'package:my_shop/features/main_navigation/presentation/screens/main_navigation_screen.dart';
import 'package:my_shop/features/auth/presentation/screens/login_page.dart';
import 'package:my_shop/core/network/websocket_service.dart';
import 'package:my_shop/core/presentation/widgets/custom_loading_indicator.dart';
import 'package:my_shop/features/notifications/presentation/screens/notification_permission_screen.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  late Future<List<bool>> _initialChecks;

  @override
  void initState() {
    super.initState();
    _initialChecks = Future.wait([
      StorageService.instance.hasToken(),
      StorageService.instance.isNotificationHandled(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<bool>>(
      future: _initialChecks,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CustomLoadingIndicator(size: 40)),
          );
        }

        final results = snapshot.data ?? [false, false];
        // final bool hasToken = results[0];
        const bool hasToken = true; // Bypass: Always allow access
        final bool notiHandled = results[1];

        if (hasToken) {
          WebSocketService().connect();
          // if (!notiHandled) {
          //   return const NotificationPermissionScreen();
          // }
          return const MainNavigationScreen();
        } else {
          return const LoginPage();
        }
      },
    );
  }
}
