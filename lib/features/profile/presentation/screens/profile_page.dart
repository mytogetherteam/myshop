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
import 'package:my_shop/core/presentation/widgets/primary_gradient_switch.dart';
import 'package:my_shop/core/presentation/widgets/app_dialog.dart';
import 'edit_shop_profile_page.dart';
import 'operating_hours_page.dart';
import 'app_permissions_page.dart';
import 'change_password_page.dart';
import 'reviews_page.dart';
import 'package:my_shop/core/utils/app_colors.dart';
import 'accepted_payment_page.dart';
import 'package:my_shop/features/orders/presentation/screens/orders_screen.dart';
import 'help_support_page.dart';

import 'package:my_shop/features/profile/data/services/profile_service.dart';
import 'package:my_shop/features/profile/data/models/shop_profile_model.dart';
import 'package:my_shop/features/profile/data/services/shop_service.dart';
import 'package:my_shop/features/profile/data/models/shop_model.dart';
import 'global_shop_selection_page.dart';
import 'package:my_shop/core/utils/app_version.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => ProfilePageState();
}

class ProfilePageState extends State<ProfilePage>
    with AutomaticKeepAliveClientMixin {
  final ProfileService _profileService = ProfileService();
  final ShopService _shopService = ShopService();
  UserInfo? _userInfo;
  bool _deliveryEnabled = false;
  bool _isDeletingAccount = false;
  bool _isTogglingDelivery = false;
  List<Shop> _userShops = [];
  ShopProfileModel? _shopProfile;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> refresh() async {
    await _handleRefresh();
  }

  Future<void> _handleRefresh() async {
    await _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final results = await Future.wait([
      StorageService.instance.getUserInfo(),
      _profileService.getShopProfile(),
      _shopService.getShops(),
    ]);

    final info = results[0] as UserInfo?;
    final profile = results[1] as ShopProfileModel?;
    final shops = results[2] as List<Shop>;

    if (mounted) {
      setState(() {
        _userInfo = info;
        _shopProfile = profile;
        _deliveryEnabled = profile?.deliveryEnabled ?? false;
        _userShops = shops;
      });
    }
  }

  Future<void> _toggleDelivery(bool value) async {
    setState(() => _isTogglingDelivery = true);

    try {
      final success = await _profileService.toggleDeliveryStatus(value);

      if (mounted && success) {
        setState(() {
          _deliveryEnabled = value;
          _isTogglingDelivery = false;
        });
      } else if (mounted) {
        setState(() => _isTogglingDelivery = false);
        AppDialog.showToast(context, 'Failed to update delivery status', isError: true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isTogglingDelivery = false);
      }
    }
  }

  Future<void> _handleLogout() async {
    GlobalModal.show(
      context: context,
      child: ConfirmationSheet(
        title: 'Logout',
        message:
            'Are you sure you want to logout? This will revoke your current session.',
        confirmLabel: 'Yes, Logout',
        onConfirm: () async {
          WebSocketService().disconnect();
          await AuthService.instance.logout();
          if (!mounted) return;
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil('/login', (route) => false);
        },
      ),
    );
  }

  Future<void> _handleDeleteAccount() async {
    GlobalModal.show(
      context: context,
      child: ConfirmationSheet(
        title: 'Delete Account',
        message:
            'Are you sure you want to permanently delete your account? This action cannot be undone and all your shop data will be removed.',
        confirmLabel: 'Yes, Delete Account',
        cancelLabel: 'Cancel',
        onConfirm: () async {
          setState(() => _isDeletingAccount = true);
          try {
            final success = await AuthService.instance.deleteAccount();
            if (!mounted) return;
            if (success) {
              WebSocketService().disconnect();
              Navigator.of(
                context,
              ).pushNamedAndRemoveUntil('/login', (route) => false);
            } else {
              setState(() => _isDeletingAccount = false);
              AppDialog.showToast(
                context,
                'Failed to delete account. Please try again or contact support.',
                isError: true,
              );
            }
          } catch (e) {
            if (mounted) setState(() => _isDeletingAccount = false);
          }
        },
      ),
    );
  }

  Future<void> _handleContactSupport() async {
    Navigator.push(
      context,
      CupertinoPageRoute(builder: (_) => const HelpSupportPage()),
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
        color: AppColors.primary,
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
              const SizedBox(height: 32),
              Center(
                child: Text(
                  AppVersion.fullVersion,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: const Color(0xFF94A3B8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToggleOption({
    required IconData icon,
    required String title,
    required bool value,
    required bool isLoading,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1),
        ),
      ),
      child: Row(
        children: [
          PhosphorIcon(
            icon,
            size: 24,
            color: const Color(0xFF475569),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF1E293B),
              ),
            ),
          ),
          if (isLoading)
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            )
          else
            PrimaryGradientSwitch(
              value: value,
              onChanged: onChanged,
            ),
        ],
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
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.primary.withValues(alpha: 0.1),
                  const Color(0xFFFB923C).withValues(alpha: 0.1),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: ClipOval(
              child: (_shopProfile?.logoUrl != null && _shopProfile!.logoUrl!.isNotEmpty)
                  ? Image.network(
                      _shopProfile!.logoUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => _buildInitialPlaceholder(),
                    )
                  : _buildInitialPlaceholder(),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _shopProfile?.nameEn ?? 'Shop Name',
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
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

  Widget _buildInitialPlaceholder() {
    return Center(
      child: ShaderMask(
        shaderCallback: (bounds) =>
            AppColors.primaryGradient.createShader(bounds),
        child: Text(
          (_shopProfile?.nameEn != null && _shopProfile!.nameEn!.isNotEmpty)
              ? _shopProfile!.nameEn![0].toUpperCase()
              : 'S',
          style: GoogleFonts.poppins(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
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
        _buildToggleOption(
          icon: PhosphorIconsRegular.truck,
          title: 'Delivery Enabled',
          value: _deliveryEnabled,
          isLoading: _isTogglingDelivery,
          onChanged: _toggleDelivery,
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
            CupertinoPageRoute(builder: (_) => const AcceptedPaymentPage()),
          ).then((_) => refresh()),
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
        _buildMenuOption(
          icon: PhosphorIconsRegular.headset,
          title: 'Help & Support',
          onTap: _handleContactSupport,
        ),
        if (_userShops.length > 1)
          _buildMenuOption(
            icon: PhosphorIconsRegular.arrowsLeftRight,
            title: 'Switch Shop',
            onTap: () => Navigator.push(
              context,
              CupertinoPageRoute(
                builder: (_) => const GlobalShopSelectionPage(),
              ),
            ).then((_) => _loadUserInfo()),
          ),
        const SizedBox(height: 24),
        _buildMenuOption(
          icon: PhosphorIconsRegular.signOut,
          title: 'Logout',
          isDestructive: true,
          onTap: _handleLogout,
          showArrow: false,
        ),
        const SizedBox(height: 12),
        _buildDeleteAccountOption(),
      ],
    );
  }

  Widget _buildDeleteAccountOption() {
    return InkWell(
      onTap: _isDeletingAccount ? null : _handleDeleteAccount,
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
            Icon(
              PhosphorIconsRegular.trash,
              size: 24,
              color: Colors.red.shade400,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                'Delete Account',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.red.shade400,
                ),
              ),
            ),
            if (_isDeletingAccount)
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.red.shade400),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? titleColor,
    bool showArrow = true,
    bool isDestructive = false,
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
            if (isDestructive)
              ShaderMask(
                shaderCallback: (bounds) => AppColors.primaryGradient.createShader(bounds),
                child: PhosphorIcon(
                  icon,
                  size: 24,
                  color: Colors.white,
                ),
              )
            else
              PhosphorIcon(
                icon,
                size: 24,
                color: titleColor ?? const Color(0xFF475569),
              ),
            const SizedBox(width: 16),
            Expanded(
              child: isDestructive
                  ? ShaderMask(
                      shaderCallback: (bounds) => AppColors.primaryGradient.createShader(bounds),
                      child: Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    )
                  : Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: titleColor ?? const Color(0xFF1E293B),
                      ),
                    ),
            ),
            if (showArrow)
              const PhosphorIcon(
                PhosphorIconsRegular.caretRight,
                size: 18,
                color: Color(0xFF94A3B8),
              ),
          ],
        ),
      ),
    );
  }
}
