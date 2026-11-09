import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:my_shop/core/presentation/widgets/app_dialog.dart';
import 'package:my_shop/core/presentation/widgets/primary_gradient_button.dart';
import 'package:my_shop/core/utils/app_colors.dart';
import 'package:my_shop/features/plans/data/models/subscription_model.dart';
import 'package:my_shop/features/plans/data/services/subscription_service.dart';
import 'package:my_shop/features/profile/presentation/screens/help_support_page.dart';
import 'package:my_shop/features/profile/presentation/screens/shop_story_page.dart';
import 'package:my_shop/features/job_posts/presentation/screens/job_posts_page.dart';
import 'package:my_shop/features/menu/presentation/screens/manage_shop_menu_page.dart';

class BoostingServicesPage extends StatefulWidget {
  final SubscriptionModel? currentSubscription;
  final VoidCallback? onRefresh;
  final VoidCallback? onOpenPlans;

  const BoostingServicesPage({
    super.key,
    this.currentSubscription,
    this.onRefresh,
    this.onOpenPlans,
  });

  @override
  State<BoostingServicesPage> createState() => _BoostingServicesPageState();
}

class _BoostingServicesPageState extends State<BoostingServicesPage> {
  final SubscriptionService _subscriptionService = SubscriptionService();
  SubscriptionModel? _currentSubscription;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentSubscription = widget.currentSubscription;
    if (_currentSubscription == null) {
      _loadSubscription();
    }
  }

  Future<void> _loadSubscription() async {
    setState(() => _isLoading = true);
    final res = await _subscriptionService.getCurrent();
    if (mounted) {
      setState(() {
        _currentSubscription = res.subscription;
        _isLoading = false;
      });
    }
  }

  SubscriptionQuotaModel? _getQuota(String featureKey) {
    if (_currentSubscription == null) return null;
    for (final quota in _currentSubscription!.quotas) {
      if (quota.featureKey == featureKey) return quota;
    }
    return null;
  }

  String _quotaLabel(String featureKey, {required String defaultText}) {
    final quota = _getQuota(featureKey);
    if (quota == null) return defaultText;
    if (quota.isUnlimited) return 'Unlimited';
    if (quota.limit != null) {
      return 'Quota: ${quota.limit} ${quota.period ?? ''}'.trim();
    }
    return defaultText;
  }

  void _triggerInstantBoost() {
    HapticFeedback.mediumImpact();
    AppDialog.showConfirm(
      context,
      title: 'Boost Shop Visibility',
      message:
          'Boosting raises your restaurant’s trending score on the MyTogether consumer app by +10 for 24 hours to maximize customer discovery.\n\nWould you like to activate this boost now?',
      confirmLabel: 'Confirm Boost',
    ).then((confirmed) {
      if (confirmed == true && mounted) {
        HapticFeedback.lightImpact();
        AppDialog.showToast(
          context,
          'Shop Visibility Boost activated! Trending score updated.',
        );
      }
    });
  }

  void _showBoostDetailDialog({
    required String title,
    required String description,
    required String benefit,
    required String featureKey,
    required IconData icon,
    required List<Color> gradientColors,
    VoidCallback? onDirectAction,
    String? directActionLabel,
  }) {
    final quota = _getQuota(featureKey);
    final hasActiveSub =
        _currentSubscription != null && _currentSubscription!.isActive;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.15),
                blurRadius: 24,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          padding: EdgeInsets.fromLTRB(
            24,
            12,
            24,
            24 + MediaQuery.paddingOf(ctx).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).dividerColor.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: gradientColors,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: gradientColors.first.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(icon, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: quota != null
                                ? const Color(0xFF10B981).withValues(alpha: 0.12)
                                : AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            quota != null
                                ? (quota.isUnlimited
                                    ? 'Unlimited Plan Quota'
                                    : 'Limit: ${quota.limit} ${quota.period ?? ''}')
                                : 'Available via Plan',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: quota != null
                                  ? const Color(0xFF10B981)
                                  : AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                description,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  height: 1.5,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      PhosphorIconsFill.sparkle,
                      size: 20,
                      color: Color(0xFFF59E0B),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        benefit,
                        style: GoogleFonts.poppins(
                          fontSize: 12.5,
                          height: 1.4,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              if (onDirectAction != null) ...[
                PrimaryGradientButton(
                  height: 50,
                  text: directActionLabel ?? 'Launch Service',
                  onPressed: () {
                    Navigator.pop(ctx);
                    onDirectAction();
                  },
                ),
                const SizedBox(height: 10),
              ],
              if (!hasActiveSub) ...[
                PrimaryGradientButton(
                  height: 50,
                  text: 'Subscribe to Unlock',
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pop(context); // Back to dashboard to view plans
                    widget.onOpenPlans?.call();
                  },
                ),
                const SizedBox(height: 10),
              ],
              SizedBox(
                width: double.infinity,
                height: 48,
                child: TextButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      CupertinoPageRoute(
                        builder: (_) => HelpSupportPage(),
                      ),
                    );
                  },
                  icon: const Icon(PhosphorIconsRegular.headset, size: 18),
                  label: Text(
                    'Contact Admin / Support',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Boosting Services',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            Text(
              'Promote visibility & maximize orders',
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ],
        ),
        centerTitle: false,
        elevation: 0,
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadSubscription,
        color: AppColors.primary,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            _buildQuotaSummaryCard(isDark),
            const SizedBox(height: 20),

            // Service 1: Shop Visibility Boost
            _buildBoostingCard(
              title: 'Shop Visibility Boost',
              subtitle: 'Increase trending score for top spot in search & explore',
              quotaText: _quotaLabel('BOOSTING', defaultText: 'Boost Ranking'),
              icon: PhosphorIconsFill.trendUp,
              gradientColors: [const Color(0xFF8B5CF6), const Color(0xFFEC4899)],
              badgeText: 'Trending',
              actionLabel: 'Boost Now',
              isDark: isDark,
              onTap: () => _showBoostDetailDialog(
                title: 'Shop Visibility Boost',
                description:
                    'Boosts your shop’s trending score on the MyTogether consumer app by +10 points for 24 hours. This raises your shop to the top of search rankings and the Discover page.',
                benefit: 'Attracts up to 3× more impressions and customer clicks.',
                featureKey: 'BOOSTING',
                icon: PhosphorIconsFill.trendUp,
                gradientColors: [const Color(0xFF8B5CF6), const Color(0xFFEC4899)],
                directActionLabel: 'Boost Shop Now',
                onDirectAction: _triggerInstantBoost,
              ),
            ),
            const SizedBox(height: 12),

            // Service 2: Flash Drop Push Alert
            _buildBoostingCard(
              title: 'Flash Drop Push Alert',
              subtitle: 'Broadcast sudden discount push alert to nearby customers',
              quotaText: _quotaLabel('FLASH_DROP', defaultText: 'Push Alert'),
              icon: PhosphorIconsFill.lightning,
              gradientColors: [const Color(0xFFF59E0B), const Color(0xFFEF4444)],
              badgeText: 'High Clicks',
              actionLabel: 'Launch',
              isDark: isDark,
              onTap: () => _showBoostDetailDialog(
                title: 'Flash Drop Push Alert',
                description:
                    'Sends an urgent push alert to active diners within your delivery radius offering a limited-time flash discount on featured menu items.',
                benefit: 'Triggers immediate impulse orders during lunch and dinner peaks.',
                featureKey: 'FLASH_DROP',
                icon: PhosphorIconsFill.lightning,
                gradientColors: [const Color(0xFFF59E0B), const Color(0xFFEF4444)],
                directActionLabel: 'Open Shop Menu',
                onDirectAction: () => Navigator.push(
                  context,
                  CupertinoPageRoute(builder: (_) => const ManageShopMenuPage()),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Service 3: Reminder Alert Broadcast
            _buildBoostingCard(
              title: 'Reminder Alert Broadcast',
              subtitle: 'Send broadcast push alerts to local diners & past buyers',
              quotaText: _quotaLabel('REMINDER_ALERT', defaultText: 'Broadcast'),
              icon: PhosphorIconsFill.megaphone,
              gradientColors: [const Color(0xFF3B82F6), const Color(0xFF6366F1)],
              actionLabel: 'Broadcast',
              isDark: isDark,
              onTap: () => _showBoostDetailDialog(
                title: 'Reminder Alert Broadcast',
                description:
                    'Broadcasts custom notifications to local foodies reminding them of your specials, new dishes, or operating hours.',
                benefit: 'Re-engages repeat buyers who have ordered from you before.',
                featureKey: 'REMINDER_ALERT',
                icon: PhosphorIconsFill.megaphone,
                gradientColors: [const Color(0xFF3B82F6), const Color(0xFF6366F1)],
              ),
            ),
            const SizedBox(height: 12),

            // Service 4: Main App Banner Slot
            _buildBoostingCard(
              title: 'Main App Banner Slot',
              subtitle: 'Feature your shop in hero carousels and order waiting screens',
              quotaText: _quotaLabel('BANNER', defaultText: 'Banner Slot'),
              icon: PhosphorIconsFill.image,
              gradientColors: [const Color(0xFF10B981), const Color(0xFF06B6D4)],
              actionLabel: 'Book Slot',
              isDark: isDark,
              onTap: () => _showBoostDetailDialog(
                title: 'Main App Banner Slot',
                description:
                    'Secures premium visual banner ad placement on the MyTogether consumer home screen and order-waiting views.',
                benefit: 'Maximum brand awareness seen by thousands of daily users.',
                featureKey: 'BANNER',
                icon: PhosphorIconsFill.image,
                gradientColors: [const Color(0xFF10B981), const Color(0xFF06B6D4)],
              ),
            ),
            const SizedBox(height: 12),

            // Service 5: Social Media Package
            _buildBoostingCard(
              title: 'Social Media Package',
              subtitle: 'Facebook posts, viral Reels, and cross-channel spotlight',
              quotaText: _quotaLabel('SOCIAL_MEDIA_PACKAGE', defaultText: 'Viral Bundle'),
              icon: PhosphorIconsFill.shareNetwork,
              gradientColors: [const Color(0xFFEC4899), const Color(0xFFF43F5E)],
              badgeText: 'Popular',
              actionLabel: 'Request',
              isDark: isDark,
              onTap: () => _showBoostDetailDialog(
                title: 'Social Media Package',
                description:
                    'Professional culinary spotlight: Our media team produces dedicated Facebook food review posts, Instagram / TikTok Reels, and cross-promotions.',
                benefit: 'Brings immense external viral traction to your restaurant.',
                featureKey: 'SOCIAL_MEDIA_PACKAGE',
                icon: PhosphorIconsFill.shareNetwork,
                gradientColors: [const Color(0xFFEC4899), const Color(0xFFF43F5E)],
              ),
            ),
            const SizedBox(height: 12),

            // Service 6: 24h Shop Story / MyDay
            _buildBoostingCard(
              title: '24h Shop Story / MyDay',
              subtitle: 'Share live kitchen videos & daily fresh meal stories',
              quotaText: _quotaLabel('MYDAY', defaultText: 'Story'),
              icon: Icons.auto_stories_rounded,
              gradientColors: [const Color(0xFFF97316), const Color(0xFFFBBF24)],
              actionLabel: 'Post Story',
              isDark: isDark,
              onTap: () => Navigator.push(
                context,
                CupertinoPageRoute(builder: (_) => const ShopStoryPage()),
              ),
            ),
            const SizedBox(height: 12),

            // Service 7: Job Recruitment Post
            _buildBoostingCard(
              title: 'Staff Recruitment Post',
              subtitle: 'Recruit chefs, kitchen staff, and delivery riders locally',
              quotaText: _quotaLabel('JOB_POST', defaultText: 'Hiring Ad'),
              icon: PhosphorIconsFill.briefcase,
              gradientColors: [const Color(0xFF475569), const Color(0xFF64748B)],
              actionLabel: 'Post Job',
              isDark: isDark,
              onTap: () => Navigator.push(
                context,
                CupertinoPageRoute(builder: (_) => const JobPostsPage()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuotaSummaryCard(bool isDark) {
    final sub = _currentSubscription;
    final planName = sub?.plan?.nameEn ?? 'Free Tier';
    final isActive = sub?.isActive == true;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.12),
            const Color(0xFFFB923C).withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    PhosphorIconsFill.crown,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    planName,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isActive
                      ? const Color(0xFF10B981).withValues(alpha: 0.15)
                      : Colors.orange.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  isActive ? 'Active Plan' : 'No Active Plan',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isActive ? const Color(0xFF10B981) : Colors.orange,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            isActive
                ? 'Your boosting and advertising features are active. Tap any service below to launch or view benefits.'
                : 'Subscribe to a merchant plan to unlock instant boost quotas, push drops, and banner slots.',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBoostingCard({
    required String title,
    required String subtitle,
    required String quotaText,
    required IconData icon,
    required List<Color> gradientColors,
    required String actionLabel,
    required bool isDark,
    String? badgeText,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: gradientColors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: gradientColors.first.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              title,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Theme.of(context).textTheme.bodyLarge?.color,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (badgeText != null) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: gradientColors.first.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                badgeText,
                                style: GoogleFonts.poppins(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: gradientColors.first,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                          height: 1.35,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        quotaText,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: gradientColors.first,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: gradientColors,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    actionLabel,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
