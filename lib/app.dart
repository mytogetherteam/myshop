import 'package:flutter/material.dart';
import 'features/auth/presentation/screens/login_page.dart';
import 'features/main_navigation/presentation/screens/main_navigation_screen.dart';
import 'features/notifications/presentation/screens/notification_permission_screen.dart';


class App extends StatelessWidget {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'My Shop',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFFED3A72),
      ),
      debugShowCheckedModeBanner: false,
      home: const MainNavigationScreen(),
      routes: {
        '/home': (context) => const MainNavigationScreen(),
        '/login': (context) => const LoginPage(),
        '/navigation': (context) => const MainNavigationScreen(),
        '/notification-permission': (context) => const NotificationPermissionScreen(),

      },
    );
  }
}
