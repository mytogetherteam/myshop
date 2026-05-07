import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:my_shop/core/presentation/widgets/primary_gradient_button.dart';

class AppPermissionsPage extends StatefulWidget {
  const AppPermissionsPage({super.key});

  @override
  State<AppPermissionsPage> createState() => _AppPermissionsPageState();
}

class _AppPermissionsPageState extends State<AppPermissionsPage> with WidgetsBindingObserver {
  PermissionStatus _notificationStatus = PermissionStatus.denied;
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
    
    if (mounted) {
      setState(() {
        _notificationStatus = status;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'App Permissions',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1E293B),
          ),
        ),
        centerTitle: false,
      ),
      body: _isLoading 
        ? const Center(child: CupertinoActivityIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Manage Access',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
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
                  title: 'Notifications',
                  description: 'Receive real-time alerts for new orders, order statuses, and shop updates.',
                  status: _notificationStatus,
                  onActionPressed: _requestNotificationPermission,
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
  }) {
    final bool isGranted = status.isGranted;
    
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
                  color: isGranted ? const Color(0xFFFFF1F2) : const Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                ),
                child: PhosphorIcon(
                  icon,
                  size: 24,
                  color: isGranted ? const Color(0xFFED3973) : const Color(0xFF94A3B8),
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
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isGranted ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isGranted ? PhosphorIconsFill.checkCircle : PhosphorIconsFill.xCircle,
                            size: 14,
                            color: isGranted ? const Color(0xFF15803D) : const Color(0xFF64748B),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isGranted ? 'Allowed' : 'Not Allowed',
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
          SizedBox(
            width: double.infinity,
            child: PrimaryGradientButton(
              onPressed: onActionPressed,
              text: isGranted ? 'Open Settings' : 'Allow Access',
              height: 48,
              borderRadius: 12,
            ),
          ),
        ],
      ),
    );
  }
}
