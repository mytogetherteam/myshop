import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:my_shop/core/data/services/storage_service.dart';
import 'package:my_shop/features/auth/data/models/auth_models.dart';
import 'package:my_shop/features/auth/data/services/auth_service.dart';
import 'package:my_shop/core/presentation/widgets/global_modal.dart';
import 'package:my_shop/core/presentation/widgets/confirmation_sheet.dart';
import 'package:my_shop/core/network/websocket_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:my_shop/core/presentation/widgets/primary_gradient_switch.dart';
import 'package:my_shop/core/presentation/widgets/app_dialog.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';
import 'edit_shop_profile_page.dart';
import 'operating_hours_page.dart';
import 'app_permissions_page.dart';
import 'account_settings_page.dart';
import 'reviews_page.dart';
import 'package:my_shop/core/utils/app_colors.dart';
import 'accepted_payment_page.dart';
import 'help_support_page.dart';
import 'feedback_page.dart';
import 'rider_management_page.dart';
import 'shop_story_page.dart';
import 'package:my_shop/features/job_posts/presentation/screens/job_posts_page.dart';

import 'package:my_shop/features/profile/data/services/profile_service.dart';
import 'package:my_shop/features/profile/data/models/shop_profile_model.dart';
import 'package:my_shop/features/profile/data/services/shop_service.dart';
import 'package:my_shop/features/profile/data/models/shop_model.dart';
import 'global_shop_selection_page.dart';
import 'package:my_shop/core/utils/app_version.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:my_shop/core/localization/app_localizations.dart';
import '../widgets/language_selector_sheet.dart';
import '../widgets/theme_selector_sheet.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:in_app_review/in_app_review.dart';

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
    final t = AppLocalizations.of(context);
    
    GlobalModal.show(
      context: context,
      child: ConfirmationSheet(
        title: value 
            ? (t?.translate('enable_delivery') ?? 'Enable Delivery / Pick up?') 
            : (t?.translate('disable_delivery') ?? 'Disable Delivery / Pick up?'),
        message: value 
            ? (t?.translate('enable_delivery_desc') ?? 'Your shop will be open for delivery and pick up orders.') 
            : (t?.translate('disable_delivery_desc') ?? 'Your shop will stop receiving delivery and pick up orders.'),
        confirmLabel: value 
            ? (t?.translate('enable') ?? 'Enable') 
            : (t?.translate('disable') ?? 'Disable'),
        confirmColor: value ? AppColors.primary : AppColors.onSurfaceVariant,
        onConfirm: () async {
          setState(() => _isTogglingDelivery = true);

          try {
            final success = await _profileService.toggleDeliveryStatus(value);

            if (mounted && success) {
              setState(() {
                _deliveryEnabled = value;
                _isTogglingDelivery = false;
              });
              if (value) {
                FlutterBackgroundService().startService();
              } else {
                FlutterBackgroundService().invoke('stopService');
              }
            } else if (mounted) {
              setState(() => _isTogglingDelivery = false);
              AppDialog.showToast(context, t?.translate('failed_update_delivery') ?? 'Failed to Update Delivery Status', isError: true);
            }
          } catch (e) {
            if (mounted) {
              setState(() => _isTogglingDelivery = false);
            }
          }
        },
      ),
    );
  }

  Future<void> _handleLogout() async {
    final t = AppLocalizations.of(context);
    GlobalModal.show(
      context: context,
      child: ConfirmationSheet(
        title: t?.translate('logout_title') ?? 'Logout',
        message: t?.translate('logout_message') ??
            'Are you sure you want to logout? This will revoke your current session.',
        confirmLabel: t?.translate('yes_logout') ?? 'Yes, Logout',
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


  Future<void> _handleContactSupport() async {
    Navigator.push(
      context,
      CupertinoPageRoute(builder: (_) => const HelpSupportPage()),
    );
  }

  Future<void> _handlePrivacyPolicy() async {
    final uri = Uri.parse('https://mytogether.org/privacy-policy/shop');
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && mounted) {
        final t = AppLocalizations.of(context);
        AppDialog.showToast(context, t?.translate('could_not_open_link') ?? 'Could Not Open This Link', isError: true);
      }
    } catch (e) {
      if (mounted) {
        final t = AppLocalizations.of(context);
        AppDialog.showToast(context, t?.translate('could_not_open_link') ?? 'Could Not Open This Link', isError: true);
      }
    }
  }

  Future<void> _handleRateApp() async {
    try {
      final InAppReview inAppReview = InAppReview.instance;
      if (await inAppReview.isAvailable()) {
        await inAppReview.requestReview();
      } else {
        await inAppReview.openStoreListing();
      }
    } catch (e) {
      if (mounted) {
        final t = AppLocalizations.of(context);
        AppDialog.showToast(context, t?.translate('could_not_open_link') ?? 'Could not open store', isError: true);
      }
    }
  }

  Future<void> _testAlertSound() async {
    final t = AppLocalizations.of(context);
    final audioPlayer = AudioPlayer();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Text('🔔', style: TextStyle(fontSize: 28)),
            const SizedBox(width: 8),
            Text(
              'Testing Sound...',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 18),
            ),
          ],
        ),
        content: Text(
          'This is what it sounds like when a new order arrives. Make sure your volume is up!',
          style: GoogleFonts.poppins(fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () {
              audioPlayer.stop();
              audioPlayer.dispose();
              Vibration.cancel();
              Navigator.pop(context);
            },
            child: Text(
              t?.translate('stop') ?? 'Stop',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: AppColors.primary),
            ),
          ),
        ],
      ),
    );

    // Play looping sound and vibrate
    await audioPlayer.setReleaseMode(ReleaseMode.loop);
    await audioPlayer.play(AssetSource('alert/alert.mp3'));
    if ((await Vibration.hasVibrator()) == true) {
      Vibration.vibrate(pattern: [500, 1000, 500, 1000], repeat: 1);
    }
  }

  void _showLanguageSelector() {
    GlobalModal.show(
      context: context,
      child: const LanguageSelectorSheet(),
    );
  }

  void _showThemeSelector() {
    GlobalModal.show(
      context: context,
      child: const ThemeSelectorSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      
      // AppBar removed, handled by global AppBar
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              SizedBox(height: 20),
              _buildProfileHeader(),
              SizedBox(height: 24),
              _buildQuickActionsSection(),
              _buildShopSection(),
              SizedBox(height: 8),
              _buildMenuItems(),
              SizedBox(height: 32),
              Center(
                child: Text(
                  AppVersion.fullVersion,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              SizedBox(height: 40),
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
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.3), width: 1),
        ),
      ),
      child: Row(
        children: [
          PhosphorIcon(
            icon,
            size: 24,
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
          SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
          ),
          if (isLoading)
            SizedBox(
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
    final t = AppLocalizations.of(context);
    final isOpAdmin = _userInfo?.role == 'OperationAdmin';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.transparent : Colors.black.withValues(alpha: 0.04),
              blurRadius: 16,
              spreadRadius: 0,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isOpAdmin ? null : () {
              HapticFeedback.lightImpact();
              Navigator.push(
                context,
                CupertinoPageRoute(builder: (_) => const EditShopProfilePage()),
              ).then((_) => _loadUserInfo());
            },
            borderRadius: BorderRadius.circular(24),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        width: 2,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(3),
                      child: Container(
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
                              ? CachedNetworkImage(
                                  imageUrl: _shopProfile!.logoUrl!,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => const SizedBox(),
                                  errorWidget: (context, url, error) => _buildInitialPlaceholder(),
                                )
                              : _buildInitialPlaceholder(),
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
                          _shopProfile?.displayName.isNotEmpty == true
                              ? _shopProfile!.displayName
                              : (t?.translate('shop_name') ?? 'Shop Name'),
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _userInfo?.email ?? 'admin@shop.com',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _userInfo?.role ?? t?.translate('admin') ?? 'ADMIN',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isOpAdmin)
                    Icon(
                      PhosphorIconsRegular.caretRight,
                      size: 20,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInitialPlaceholder() {
    return Center(
      child: ShaderMask(
        shaderCallback: (bounds) =>
            AppColors.primaryGradient.createShader(bounds),
        child: Text(
          _shopProfile?.displayName.isNotEmpty == true
              ? _shopProfile!.displayName[0].toUpperCase()
              : 'S',
          style: GoogleFonts.poppins(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).cardColor,
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionsSection() {
    final t = AppLocalizations.of(context);
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  icon: PhosphorIconsFill.shoppingBag,
                  title: 'Delivery',
                  subtitle: _deliveryEnabled ? 'Online' : 'Offline',
                  trailing: _isTogglingDelivery
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      : Transform.scale(
                          scale: 0.85,
                          child: PrimaryGradientSwitch(
                            value: _deliveryEnabled,
                            onChanged: _toggleDelivery,
                          ),
                        ),
                  onTap: () => _toggleDelivery(!_deliveryEnabled),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildActionCard(
                  icon: PhosphorIconsFill.clock,
                  title: t?.translate('operating_hours') ?? 'Hours',
                  subtitle: 'Manage times',
                  onTap: () => Navigator.push(
                    context,
                    CupertinoPageRoute(builder: (_) => const OperatingHoursPage()),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  icon: Icons.auto_stories_rounded,
                  title: 'Story',
                  subtitle: 'Share updates',
                  trailing: const AnimatedNewBadge(),
                  onTap: () => Navigator.push(
                    context,
                    CupertinoPageRoute(builder: (_) => const ShopStoryPage()),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildActionCard(
                  icon: PhosphorIconsFill.briefcase,
                  title: t?.translate('job_posts') ?? 'Job Posts',
                  subtitle: 'Find staffs',
                  trailing: const AnimatedNewBadge(),
                  onTap: () => Navigator.push(
                    context,
                    CupertinoPageRoute(builder: (_) => const JobPostsPage()),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.transparent : Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            spreadRadius: 0,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: isDark ? 0.15 : 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ShaderMask(
                        shaderCallback: (bounds) => AppColors.primaryGradient.createShader(bounds),
                        child: Icon(
                          icon,
                          size: 26,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    if (trailing != null) trailing,
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShopSection() {
    final t = AppLocalizations.of(context);
    final isOpAdmin = _userInfo?.role == 'OperationAdmin';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
          child: Text(
            t?.translate('shop') ?? 'Shop',
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).textTheme.bodySmall?.color,
              letterSpacing: 0.8,
            ),
          ),
        ),
        if (!isOpAdmin)
          _buildMenuOption(
            icon: PhosphorIconsRegular.creditCard,
            title: t?.translate('accepted_payment') ?? 'Accepted Payment',
            onTap: () => Navigator.push(
              context,
              CupertinoPageRoute(builder: (_) => const AcceptedPaymentPage()),
            ).then((_) => refresh()),
          ),
        _buildMenuOption(
          icon: PhosphorIconsRegular.star,
          title: t?.translate('reviews') ?? 'Reviews',
          onTap: () => Navigator.push(
            context,
            CupertinoPageRoute(builder: (_) => const ReviewsPage()),
          ),
        ),
        _buildMenuOption(
          icon: PhosphorIconsRegular.motorcycle,
          title: t?.translate('rider_management') ?? 'Rider Management',
          onTap: () => Navigator.push(
            context,
            CupertinoPageRoute(builder: (_) => const RiderManagementPage()),
          ),
        ),
        _buildMenuOption(
          icon: PhosphorIconsRegular.bellRinging,
          title: 'Test Alert Sound',
          onTap: _testAlertSound,
        ),
      ],
    );
  }

  Widget _buildMenuItems() {
    final t = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
          child: Text(
            t?.translate('setting') ?? 'Setting',
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).textTheme.bodySmall?.color,
              letterSpacing: 0.8,
            ),
          ),
        ),
        _buildMenuOption(
          icon: PhosphorIconsRegular.shieldCheck,
          title: t?.translate('app_permissions') ?? 'App Permissions',
          onTap: () => Navigator.push(
            context,
            CupertinoPageRoute(builder: (_) => const AppPermissionsPage()),
          ),
        ),
        _buildMenuOption(
          icon: PhosphorIconsRegular.user,
          title: t?.translate('account_settings') ?? 'Account Settings',
          onTap: () => Navigator.push(
            context,
            CupertinoPageRoute(builder: (_) => const AccountSettingsPage()),
          ),
        ),
        _buildMenuOption(
          icon: PhosphorIconsRegular.translate,
          title: t?.translate('language') ?? 'Language',
          onTap: _showLanguageSelector,
        ),
        _buildMenuOption(
          icon: PhosphorIconsRegular.palette,
          title: t?.translate('app_appearance') ?? 'App Appearance',
          onTap: _showThemeSelector,
        ),
        _buildMenuOption(
          icon: PhosphorIconsRegular.headset,
          title: t?.translate('help_support') ?? 'Help & Support',
          onTap: _handleContactSupport,
        ),
        _buildMenuOption(
          icon: PhosphorIconsRegular.chatCircleText,
          title: t?.translate('feedback') ?? 'Feedback',
          onTap: () => Navigator.push(
            context,
            CupertinoPageRoute(builder: (_) => const FeedbackPage()),
          ),
        ),
        _buildMenuOption(
          icon: PhosphorIconsRegular.starHalf,
          title: t?.translate('rate_app') ?? 'Rate App',
          onTap: _handleRateApp,
        ),
        _buildMenuOption(
          icon: PhosphorIconsRegular.shield,
          title: t?.translate('privacy_policy') ?? 'Privacy Policy',
          onTap: _handlePrivacyPolicy,
        ),
        if (_userShops.length > 1)
          _buildMenuOption(
            icon: PhosphorIconsRegular.arrowsLeftRight,
            title: t?.translate('switch_shop') ?? 'Switch Shop',
            onTap: () => Navigator.push(
              context,
              CupertinoPageRoute(
                builder: (_) => const GlobalShopSelectionPage(),
              ),
            ).then((_) => _loadUserInfo()),
          ),
        SizedBox(height: 24),
        _buildMenuOption(
          icon: PhosphorIconsRegular.signOut,
          title: t?.translate('logout') ?? 'Logout',
          isDestructive: true,
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
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          border: Border(
            bottom: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.3), width: 1),
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
                color: titleColor ?? Theme.of(context).iconTheme.color,
              ),
            SizedBox(width: 16),
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
                        color: titleColor ?? Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
            ),
            if (showArrow)
              PhosphorIcon(
                PhosphorIconsRegular.caretRight,
                size: 18,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
          ],
        ),
      ),
    );
  }
}

class AnimatedNewBadge extends StatefulWidget {
  const AnimatedNewBadge({super.key});

  @override
  State<AnimatedNewBadge> createState() => _AnimatedNewBadgeState();
}

class _AnimatedNewBadgeState extends State<AnimatedNewBadge> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFEF4444), Color(0xFFF97316)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFEF4444).withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          'NEW',
          style: GoogleFonts.poppins(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}
