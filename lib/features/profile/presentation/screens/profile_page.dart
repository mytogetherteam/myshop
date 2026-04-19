import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:my_shop/core/data/services/storage_service.dart';
import 'package:my_shop/features/auth/data/models/auth_models.dart';
import 'package:my_shop/features/auth/data/services/auth_service.dart';
import 'package:my_shop/core/presentation/widgets/global_modal.dart';
import 'package:my_shop/core/presentation/widgets/confirmation_sheet.dart';
import 'package:my_shop/core/network/websocket_service.dart';
import 'package:flutter/cupertino.dart';
import 'edit_shop_profile_page.dart';
import 'operating_hours_page.dart';
import 'app_permissions_page.dart';
import 'change_password_page.dart';
import 'reviews_page.dart';
import 'accepted_payment_page.dart';
import 'shop_selection_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with AutomaticKeepAliveClientMixin {
  UserInfo? _userInfo;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _handleRefresh() async {
    await _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final info = await StorageService.instance.getUserInfo();
    setState(() { _userInfo = info; });
  }

  Future<void> _handleLogout() async {
    GlobalModal.show(
      context: context,
      child: ConfirmationSheet(
        title: 'Logout',
        message: 'Are you sure you want to logout? This will revoke your current session.',
        confirmLabel: 'Yes, Logout',
        onConfirm: () async {
          WebSocketService().disconnect();
          await AuthService.instance.logout();
          if (!mounted) return;
          Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      // AppBar removed, handled by global AppBar
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: const Color(0xFFED3973),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              const SizedBox(height: 20),
              _buildProfileHeader(),
              const SizedBox(height: 24),
              _buildShopSection(),
              const SizedBox(height: 8),
              _buildMenuItems(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border.symmetric(
          horizontal: BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFFED3973).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                (_userInfo?.fullName.isNotEmpty == true) ? _userInfo!.fullName[0].toUpperCase() : 'A',
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFED3973),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _userInfo?.fullName ?? 'Shop Admin',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                Text(
                  _userInfo?.email ?? 'admin@shop.com',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _userInfo?.role ?? 'ADMIN',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF475569),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShopSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
          child: Text(
            'Shop',
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF94A3B8),
              letterSpacing: 0.8,
            ),
          ),
        ),
        _buildMenuOption(
          icon: PhosphorIconsRegular.storefront,
          title: 'Edit shop profile',
          onTap: () => Navigator.push(
            context,
            CupertinoPageRoute(builder: (_) => const EditShopProfilePage()),
          ).then((_) => _loadUserInfo()),
        ),
        _buildMenuOption(
          icon: PhosphorIconsRegular.clock,
          title: 'Operating hours',
          onTap: () => Navigator.push(
            context,
            CupertinoPageRoute(builder: (_) => const OperatingHoursPage()),
          ),
        ),
        _buildMenuOption(
          icon: PhosphorIconsRegular.creditCard,
          title: 'Accepted payment',
          onTap: () => Navigator.push(
            context,
            CupertinoPageRoute(builder: (_) => const ShopSelectionPage()),
          ),
        ),
        _buildMenuOption(
          icon: PhosphorIconsRegular.star,
          title: 'Reviews',
          onTap: () => Navigator.push(
            context,
            CupertinoPageRoute(builder: (_) => const ReviewsPage()),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItems() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
          child: Text(
            'Account',
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF94A3B8),
              letterSpacing: 0.8,
            ),
          ),
        ),
        _buildMenuOption(
          icon: PhosphorIconsRegular.user,
          title: 'Account Settings',
          onTap: () {},
        ),
        _buildMenuOption(
          icon: PhosphorIconsRegular.shieldCheck,
          title: 'App Permissions',
          onTap: () => Navigator.push(
            context,
            CupertinoPageRoute(builder: (_) => const AppPermissionsPage()),
          ),
        ),
        _buildMenuOption(
          icon: PhosphorIconsRegular.lock,
          title: 'Change Password',
          onTap: () => Navigator.push(
            context,
            CupertinoPageRoute(builder: (_) => const ChangePasswordPage()),
          ),
        ),
        const SizedBox(height: 24),
        _buildMenuOption(
          icon: PhosphorIconsRegular.signOut,
          title: 'Logout',
          titleColor: const Color(0xFFED3973),
          onTap: _handleLogout,
          showArrow: false,
        ),
      ],
    );
  }

  Widget _buildMenuOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? titleColor,
    bool showArrow = true,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1),
          ),
        ),
        child: Row(
          children: [
            PhosphorIcon(icon, size: 24, color: titleColor ?? const Color(0xFF475569)),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: titleColor ?? const Color(0xFF1E293B),
                ),
              ),
            ),
            if (showArrow)
              const PhosphorIcon(PhosphorIconsRegular.caretRight, size: 18, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }
}
