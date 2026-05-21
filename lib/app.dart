import 'package:flutter/material.dart';
import 'core/utils/app_colors.dart';
import 'features/auth/presentation/screens/login_page.dart';
import 'features/auth/presentation/widgets/auth_wrapper.dart';
import 'features/notifications/presentation/screens/notification_permission_screen.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/localization/app_localizations.dart';

class App extends StatelessWidget {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: LocalizationService.instance.localeNotifier,
      builder: (context, locale, child) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          title: 'My Shop',
          theme: ThemeData(
            useMaterial3: true,
            colorSchemeSeed: AppColors.primary,
          ),
          debugShowCheckedModeBanner: false,
          locale: locale,
          supportedLocales: const [
            Locale('en', ''),
            Locale('my', ''),
            Locale('th', ''),
          ],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const AuthWrapper(),
          routes: {
            '/home': (context) => const AuthWrapper(),
            '/login': (context) => const LoginPage(),
            '/navigation': (context) => const AuthWrapper(),
            '/notification-permission': (context) =>
                const NotificationPermissionScreen(),
          },
        );
      },
    );
  }
}
