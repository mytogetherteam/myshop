import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:my_shop/core/notifications/notification_service.dart';
import 'package:my_shop/core/presentation/widgets/primary_gradient_button.dart';
import 'package:my_shop/core/presentation/widgets/back_title_app_bar.dart';
import 'package:my_shop/core/localization/app_localizations.dart';

class AppPermissionsPage extends StatefulWidget {
  const AppPermissionsPage({super.key});

  @override
  State<AppPermissionsPage> createState() => _AppPermissionsPageState();
}

class _AppPermissionsPageState extends State<AppPermissionsPage>
    with WidgetsBindingObserver {
  PermissionStatus _notificationStatus = PermissionStatus.denied;
  PermissionStatus _systemAlertWindowStatus = PermissionStatus.denied;
  AuthorizationStatus _webNotificationStatus = AuthorizationStatus.notDetermined;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // When the user returns to the app from OS settings, re-check permissions
    if (state == AppLifecycleState.resumed) {
      _checkPermissions(silent: true);
    }
  }

  Future<void> _checkPermissions({bool silent = false}) async {
    if (!silent) setState(() => _isLoading = true);

    if (kIsWeb) {
      final settings = await FirebaseMessaging.instance.getNotificationSettings();
      if (mounted) {
        setState(() {
          _webNotificationStatus = settings.authorizationStatus;
          _isLoading = false;
        });
      }
      return;
    }

    final status = await Permission.notification.status;
    final alertStatus = await Permission.systemAlertWindow.status;

    if (mounted) {
      setState(() {
        _notificationStatus = status;
        _systemAlertWindowStatus = alertStatus;
        _isLoading = false;
      });
    }
  }

  bool _webNotificationsGranted() {
    return _webNotificationStatus == AuthorizationStatus.authorized ||
        _webNotificationStatus == AuthorizationStatus.provisional;
  }

  Future<void> _requestWebNotificationPermission() async {
    await NotificationService().requestSystemPermission();
    await _checkPermissions(silent: true);
  }

  Future<void> _requestNotificationPermission() async {
    // If it's already granted, or permanently denied, route to OS settings.
    if (_notificationStatus.isGranted ||
        _notificationStatus.isPermanentlyDenied) {
      await openAppSettings();
    } else {
      final status = await Permission.notification.request();
      if (status.isPermanentlyDenied) {
        await openAppSettings();
      }
      if (mounted) {
        setState(() => _notificationStatus = status);
      }
    }
  }

  Future<void> _requestSystemAlertWindowPermission() async {
    if (_systemAlertWindowStatus.isGranted ||
        _systemAlertWindowStatus.isPermanentlyDenied) {
      await openAppSettings();
    } else {
      final status = await Permission.systemAlertWindow.request();
      if (status.isPermanentlyDenied) {
        await openAppSettings();
      }
      if (mounted) {
        setState(() => _systemAlertWindowStatus = status);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    if (kIsWeb) {
      final webGranted = _webNotificationsGranted();

      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: BackTitleAppBar(
          title: t?.translate('app_permissions') ?? 'App Permissions',
        ),
        body: _isLoading
            ? const Center(child: CupertinoActivityIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t?.translate('manage_access') ?? 'Manage Access',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      t?.translate('app_permissions_web_desc') ??
                          'On the web app, permissions are managed by your browser. Enable notifications below to receive new order alerts.',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: const Color(0xFF64748B),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildPermissionCard(
                      icon: PhosphorIconsRegular.bellRinging,
                      title: t?.translate('notifications') ?? 'Notifications',
                      description:
                          t?.translate('notifications_desc') ??
                          'Receive real-time alerts for new orders, order statuses, and shop updates.',
                      status: webGranted
                          ? PermissionStatus.granted
                          : PermissionStatus.denied,
                      onActionPressed: webGranted
                          ? () {}
                          : _requestWebNotificationPermission,
                      actionLabel: webGranted
                          ? (t?.translate('allowed') ?? 'Allowed')
                          : (t?.translate('allow_access') ?? 'Allow Access'),
                      actionEnabled: !webGranted,
                    ),
                  ],
                ),
              ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: BackTitleAppBar(
        title: t?.translate('app_permissions') ?? 'App Permissions',
      ),
      body: _isLoading
          ? const Center(child: CupertinoActivityIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t?.translate('manage_access') ?? 'Manage Access',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    t?.translate('control_permissions_desc') ??
                        'Control what features this app has access to. You can easily enable or disable them in your device settings.',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: const Color(0xFF64748B),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Notifications Permission Card
                  _buildPermissionCard(
                    icon: PhosphorIconsRegular.bellRinging,
                    title: t?.translate('notifications') ?? 'Notifications',
                    description:
                        t?.translate('notifications_desc') ??
                        'Receive real-time alerts for new orders, order statuses, and shop updates.',
                    status: _notificationStatus,
                    onActionPressed: _requestNotificationPermission,
                  ),

                  const SizedBox(height: 16),

                  // System Alert Window Permission Card (For Full Screen Intent / Pop-ups)
                  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android)
                    _buildPermissionCard(
                      icon: PhosphorIconsRegular.deviceMobileCamera,
                      title:
                          t?.translate('display_over_apps') ??
                          'Display Over Apps',
                      description:
                          t?.translate('display_over_apps_desc') ??
                          'Required to wake up the screen and show new orders like a phone call.',
                      status: _systemAlertWindowStatus,
                      onActionPressed: _requestSystemAlertWindowPermission,
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildPermissionCard({
    required IconData icon,
    required String title,
    required String description,
    required PermissionStatus status,
    required VoidCallback onActionPressed,
    String? actionLabel,
    bool actionEnabled = true,
  }) {
    final bool isGranted = status.isGranted;
    final t = AppLocalizations.of(context);
    final buttonLabel = actionLabel ??
        (isGranted
            ? (t?.translate('open_settings') ?? 'Open Settings')
            : (t?.translate('allow_access') ?? 'Allow Access'));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isGranted
                      ? const Color(0xFFFFF1F2)
                      : const Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                ),
                child: PhosphorIcon(
                  icon,
                  size: 24,
                  color: isGranted
                      ? const Color(0xFFED3973)
                      : const Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isGranted
                            ? const Color(0xFFDCFCE7)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isGranted
                                ? PhosphorIconsFill.checkCircle
                                : PhosphorIconsFill.xCircle,
                            size: 14,
                            color: isGranted
                                ? const Color(0xFF15803D)
                                : const Color(0xFF64748B),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isGranted
                                ? (t?.translate('allowed') ?? 'Allowed')
                                : (t?.translate('not_allowed') ??
                                      'Not Allowed'),
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: isGranted
                                  ? const Color(0xFF15803D)
                                  : const Color(0xFF475569),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            description,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: const Color(0xFF64748B),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          if (actionEnabled)
            SizedBox(
              width: double.infinity,
              child: PrimaryGradientButton(
                onPressed: onActionPressed,
                text: buttonLabel,
                height: 48,
                borderRadius: 12,
              ),
            ),
        ],
      ),
    );
  }
}
