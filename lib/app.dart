import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'core/utils/app_colors.dart';
import 'core/notifications/order_alert_sound.dart';
import 'features/auth/presentation/screens/login_page.dart';
import 'features/auth/presentation/widgets/auth_wrapper.dart';
import 'features/notifications/presentation/screens/notification_permission_screen.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/localization/app_localizations.dart';
import 'core/presentation/widgets/connectivity_wrapper.dart';

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
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                disabledBackgroundColor: const Color(0xFFE2E8F0),
                disabledForegroundColor: const Color(0xFF94A3B8),
              ),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                disabledForegroundColor: const Color(0xFF94A3B8),
              ),
            ),
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
          builder: (context, child) {
            return ConnectivityWrapper(
              child: GestureDetector(
                onTap: () {
                  if (kIsWeb) {
                    OrderAlertSound.prepareForUserInteraction();
                  }
                  FocusManager.instance.primaryFocus?.unfocus();
                },
                child: child,
              ),
            );
          },
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
