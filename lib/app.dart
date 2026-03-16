import 'package:flutter/material.dart';
import 'features/auth/presentation/screens/login_page.dart';
import 'features/auth/presentation/widgets/auth_wrapper.dart';
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
      home: const AuthWrapper(),
      routes: {
        '/home': (context) => const AuthWrapper(),
        '/login': (context) => const LoginPage(),
        '/navigation': (context) => const AuthWrapper(),
        '/notification-permission': (context) => const NotificationPermissionScreen(),
      },
    );
  }
}
