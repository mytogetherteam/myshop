import 'package:flutter/material.dart';
import 'features/auth/presentation/screens/login_page.dart';
import 'features/auth/presentation/widgets/auth_wrapper.dart';
import 'features/notifications/presentation/screens/notification_permission_screen.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/localization/app_localizations.dart';
import 'core/presentation/widgets/connectivity_wrapper.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_service.dart';
import 'package:upgrader/upgrader.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:my_shop/features/auth/data/services/auth_service.dart';

class App extends StatefulWidget {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // If the app comes to foreground, ensure the background service notification is brought back if swiped away
      AuthService.instance.isLoggedIn.then((isLoggedIn) {
        if (isLoggedIn) {
          FlutterBackgroundService().startService();
          FlutterBackgroundService().invoke('setAsForeground');
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeService.instance.themeModeNotifier,
      builder: (context, themeMode, _) {
        return ValueListenableBuilder<Locale>(
          valueListenable: LocalizationService.instance.localeNotifier,
          builder: (context, locale, child) {
            return MaterialApp(
              navigatorKey: App.navigatorKey,
              title: 'My Shop',
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: themeMode,
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
            return UpgradeAlert(
              navigatorKey: App.navigatorKey,
              showIgnore: false,
              showLater: false,
              upgrader: Upgrader(
                // debugDisplayAlways: true, // Uncomment to test UI locally
              ),
              child: ConnectivityWrapper(
                child: GestureDetector(
                  onTap: () {
                    FocusManager.instance.primaryFocus?.unfocus();
                  },
                  child: child,
                ),
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
  },
);
  }
}
