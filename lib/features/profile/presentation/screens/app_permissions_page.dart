import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:my_shop/core/presentation/widgets/primary_gradient_button.dart';
import 'package:my_shop/core/presentation/widgets/back_title_app_bar.dart';
import 'package:my_shop/core/localization/app_localizations.dart';
import 'package:my_shop/core/utils/app_colors.dart';

class AppPermissionsPage extends StatefulWidget {
  const AppPermissionsPage({super.key});

  @override
  State<AppPermissionsPage> createState() => _AppPermissionsPageState();
}

class _AppPermissionsPageState extends State<AppPermissionsPage> with WidgetsBindingObserver {
  PermissionStatus _notificationStatus = PermissionStatus.denied;
  PermissionStatus _batteryStatus = PermissionStatus.denied;
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
    final status = await Permission.notification.status;
    final batteryStatus = Platform.isAndroid 
        ? await Permission.ignoreBatteryOptimizations.status 
        : PermissionStatus.granted;
    
    if (mounted) {
      setState(() {
        _notificationStatus = status;
        _batteryStatus = batteryStatus;
        _isLoading = false;
      });
    }
  }

  Future<void> _requestNotificationPermission() async {
    // If it's already granted, or permanently denied, route to OS settings.
    if (_notificationStatus.isGranted || _notificationStatus.isPermanentlyDenied) {
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

  Future<void> _requestBatteryPermission() async {
    if (Platform.isIOS) return;
    if (_batteryStatus.isGranted) {
      await openAppSettings();
    } else {
      final status = await Permission.ignoreBatteryOptimizations.request();
      if (mounted) {
        setState(() => _batteryStatus = status);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      
      appBar: BackTitleAppBar(
        title: t?.translate('app_permissions') ?? 'App Permissions',
      ),
      body: _isLoading 
        ? Center(child: CupertinoActivityIndicator())
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
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  t?.translate('control_permissions_desc') ?? 'Control what features this app has access to. You can easily enable or disable them in your device settings.',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                    height: 1.5,
                  ),
                ),
                SizedBox(height: 24),
                
                // Notifications Permission Card
                _buildPermissionCard(
                  icon: PhosphorIconsRegular.bellRinging,
                  title: t?.translate('notifications') ?? 'Notifications',
                  description: t?.translate('notifications_desc') ?? 'Receive real-time alerts for new orders, order statuses, and shop updates.',
                  status: _notificationStatus,
                  onActionPressed: _requestNotificationPermission,
                ),
                
                SizedBox(height: 16),
                
                // Battery Optimization Permission Card (Android Only)
                if (Platform.isAndroid)
                  _buildPermissionCard(
                    icon: PhosphorIconsRegular.batteryCharging,
                    title: t?.translate('battery_optimization') ?? 'Background Execution',
                    description: t?.translate('battery_optimization_desc') ?? 'Allow the app to run in the background to ensure you never miss incoming orders or notifications.',
                    status: _batteryStatus,
                    onActionPressed: _requestBatteryPermission,
                  ),
                  
                if (Platform.isAndroid)
                  SizedBox(height: 16),
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
  }) {
    final bool isGranted = status.isGranted;
    final t = AppLocalizations.of(context);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
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
                      ? AppColors.primary.withValues(alpha: 0.15) 
                      : (Theme.of(context).brightness == Brightness.dark 
                          ? Theme.of(context).dividerColor.withValues(alpha: 0.1) 
                          : const Color(0xFFF1F5F9)),
                  shape: BoxShape.circle,
                ),
                child: PhosphorIcon(
                  icon,
                  size: 24,
                  color: isGranted 
                      ? AppColors.primary 
                      : (Theme.of(context).brightness == Brightness.dark 
                          ? const Color(0xFF94A3B8) 
                          : const Color(0xFF94A3B8)),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isGranted ? const Color(0xFFDCFCE7) : (Theme.of(context).brightness == Brightness.dark ? Theme.of(context).cardColor : (Theme.of(context).brightness == Brightness.dark ? Theme.of(context).cardColor : const Color(0xFFF1F5F9))),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isGranted ? PhosphorIconsFill.checkCircle : PhosphorIconsFill.xCircle,
                            size: 14,
                            color: isGranted ? const Color(0xFF15803D) : (Theme.of(context).brightness == Brightness.dark ? const Color(0xFFCBD5E1) : const Color(0xFF64748B)),
                          ),
                          SizedBox(width: 6),
                          Text(
                            isGranted ? (t?.translate('allowed') ?? 'Allowed') : (t?.translate('not_allowed') ?? 'Not Allowed'),
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: isGranted ? const Color(0xFF15803D) : const Color(0xFF475569),
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
          SizedBox(height: 16),
          Text(
            description,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Theme.of(context).textTheme.bodySmall?.color,
              height: 1.5,
            ),
          ),
          SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: PrimaryGradientButton(
              onPressed: onActionPressed,
              text: isGranted ? (t?.translate('open_settings') ?? 'Open Settings') : (t?.translate('allow_access') ?? 'Allow Access'),
              height: 48,
              borderRadius: 12,
            ),
          ),
        ],
      ),
    );
  }
}
