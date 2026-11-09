import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import 'package:my_shop/core/localization/app_localizations.dart';
import 'package:my_shop/core/presentation/widgets/app_dialog.dart';
import 'package:my_shop/core/presentation/widgets/primary_gradient_button.dart';
import 'package:my_shop/core/presentation/widgets/skeleton.dart';
import 'package:my_shop/core/utils/app_colors.dart';

import 'package:my_shop/features/plans/data/models/plan_model.dart';
import 'package:my_shop/features/plans/data/models/subscription_model.dart';
import 'package:my_shop/features/plans/data/services/plan_service.dart';
import 'package:my_shop/features/plans/data/services/subscription_service.dart';
import 'package:my_shop/features/plans/presentation/screens/plans_page.dart';
import 'package:my_shop/features/plans/presentation/screens/subscribe_plan_page.dart';
import 'package:my_shop/features/profile/data/models/shop_profile_model.dart';
import 'package:my_shop/features/profile/data/services/profile_service.dart';
import 'package:my_shop/features/profile/presentation/screens/help_support_page.dart';
import 'package:my_shop/features/orders/presentation/screens/order_qr_scanner_screen.dart';
import 'package:my_shop/features/profile/presentation/screens/shop_story_page.dart';
import 'package:my_shop/features/job_posts/presentation/screens/job_posts_page.dart';
import 'package:my_shop/features/categories/presentation/screens/category_list_screen.dart';
import 'package:my_shop/features/reports/data/models/report_model.dart';
import 'package:my_shop/features/reports/data/services/report_service.dart';
import 'package:my_shop/features/reports/presentation/screens/report_page.dart';
import 'package:my_shop/features/menu/presentation/screens/manage_shop_menu_page.dart';
import 'package:my_shop/features/menu/presentation/screens/boosting_services_page.dart';
import 'package:my_shop/features/main_navigation/presentation/screens/main_navigation_screen.dart';
import 'package:my_shop/features/notifications/presentation/widgets/notification_badge_icon.dart';

class MenuPage extends StatefulWidget {
  const MenuPage({super.key});

  @override
  State<MenuPage> createState() => MenuPageState();
}

class MenuPageState extends State<MenuPage>
    with AutomaticKeepAliveClientMixin {
  final PlanService _planService = PlanService();
  final SubscriptionService _subscriptionService = SubscriptionService();
  final ReportService _reportService = ReportService();
  final ProfileService _profileService = ProfileService();
  final NumberFormat _priceFormat = NumberFormat('#,##0.##');
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _plansSectionKey = GlobalKey();

  List<PlanModel> _plans = [];
  SubscriptionModel? _currentSubscription;
  SubscriptionModel? _actionableSubscription;
  SalesSummaryModel? _todaySummary;
  SalesSummaryModel? _yesterdaySummary;
  ShopProfileModel? _shopProfile;

  bool _isLoading = true;
  bool _loadFailed = false;
  bool _annualBilling = false;
  bool _billingInitialized = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> refresh() async {
    await _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _loadFailed = false;
    });

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = now;

    final yesterdayStart = todayStart.subtract(const Duration(days: 1));
    final yesterdayEnd = todayStart.subtract(const Duration(seconds: 1));

    try {
      final results = await Future.wait([
        _planService.getPlans(page: 1, size: 50),
        _subscriptionService.getCurrent(),
        _subscriptionService.getSubscriptions(page: 1, size: 20),
        _reportService.getSummary(start: todayStart, end: todayEnd),
        _reportService.getSummary(start: yesterdayStart, end: yesterdayEnd),
        _profileService.getShopProfile(),
      ]);

      if (!mounted) return;

      final planResult = results[0] as PlanListResult?;
      final currentResult =
          results[1] as ({SubscriptionModel? subscription, bool failed});
      final historyResult = results[2] as SubscriptionListResult?;
      final todaySummary = results[3] as SalesSummaryModel?;
      final yesterdaySummary = results[4] as SalesSummaryModel?;
      final shopProfile = results[5] as ShopProfileModel?;

      final plans = planResult?.items ?? const <PlanModel>[];
      final current = currentResult.subscription;
      SubscriptionModel? pending;
      SubscriptionModel? rejected;
      for (final item in historyResult?.items ?? const <SubscriptionModel>[]) {
        if (pending == null && item.isPending) pending = item;
        if (rejected == null && item.isRejected && item.canResubmitSlip) {
          rejected = item;
        }
        if (pending != null) break;
      }
      final actionable = pending ?? (current == null ? rejected : null);

      setState(() {
        _plans = plans;
        _currentSubscription = current;
        _actionableSubscription = actionable;
        _todaySummary = todaySummary;
        _yesterdaySummary = yesterdaySummary;
        _shopProfile = shopProfile;
        _isLoading = false;
        _loadFailed = planResult == null && plans.isEmpty;

        if (!_billingInitialized && current != null) {
          _annualBilling = current.billingPeriod.toUpperCase() == 'ANNUALLY';
          _billingInitialized = true;
        }
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadFailed = true;
        });
      }
    }
  }

  void _scrollToPlans() {
    Navigator.push(
      context,
      CupertinoPageRoute(builder: (_) => const PlansPage()),
    ).then((_) => refresh());
  }

  bool get _anyHasAnnual => _plans.any((p) => p.hasAnnualPricing || p.annualPrice != null);

  int? get _savePercent {
    for (final plan in _plans) {
      if (plan.annualDiscountPercent != null && plan.annualDiscountPercent! > 0) {
        return plan.annualDiscountPercent;
      }
      final monthly = plan.price;
      final annual = plan.annualPrice;
      if (monthly != null && monthly > 0 && annual != null && annual > 0) {
        final yearlyViaMonthly = monthly * 12;
        if (yearlyViaMonthly > annual) {
          final pct =
              (((yearlyViaMonthly - annual) / yearlyViaMonthly) * 100).round();
          if (pct > 0) return pct;
        }
      }
    }
    return null;
  }

  Future<void> _onPlanCta(PlanModel plan) async {
    HapticFeedback.lightImpact();

    if (plan.isCustomPricing) {
      await _openContactSales(plan);
      return;
    }

    if (_currentSubscription?.isActive == true &&
        _currentSubscription?.planId == plan.id) {
      AppDialog.showToast(
        context,
        AppLocalizations.of(context)?.translate('plans_already_active') ??
            'This is your current active plan.',
      );
      return;
    }

    final actionable = _actionableSubscription;
    if (actionable != null && actionable.planId == plan.id && actionable.canResubmitSlip) {
      _openResubmit(actionable);
      return;
    }

    _openPurchase(plan);
  }

  void _openPurchase(PlanModel plan) {
    Navigator.of(context).push(
      CupertinoPageRoute<bool>(
        builder: (_) => SubscribePlanPage.purchase(
          plan: plan,
          annualBilling: _annualBilling,
        ),
      ),
    ).then((result) {
      if (result == true) refresh();
    });
  }

  void _openResubmit(SubscriptionModel subscription) {
    Navigator.of(context).push(
      CupertinoPageRoute<bool>(
        builder: (_) => SubscribePlanPage.resubmit(
          subscription: subscription,
        ),
      ),
    ).then((result) {
      if (result == true) refresh();
    });
  }

  Future<void> _openContactSales(PlanModel plan) async {
    final t = AppLocalizations.of(context);
    final confirmed = await AppDialog.showConfirm(
      context,
      title: t?.translate('plans_contact_sales') ?? 'Contact Sales',
      message:
          '${plan.nameEn} offers custom features and pricing tailored to your restaurant.\n\nWould you like to contact our team now?',
      confirmLabel: t?.translate('contact_us') ?? 'Contact Us',
    );
    if (confirmed == true && mounted) {
      Navigator.push(
        context,
        CupertinoPageRoute(
          builder: (_) => HelpSupportPage(),
        ),
      );
    }
  }

  void _triggerInstantBoost() {
    HapticFeedback.mediumImpact();
    AppDialog.showConfirm(
      context,
      title: 'Shop Visibility Boost',
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

  void _showVisibilityBoostDetail() {
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
                      gradient: const LinearGradient(
                        colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF8B5CF6).withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        PhosphorIconsFill.trendUp,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Shop Visibility Boost',
                          style: GoogleFonts.poppins(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '+10 Trending Score',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF10B981),
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
                'Boosts your restaurant’s trending score on the MyTogether consumer app by +10 points for 24 hours. This raises your shop to the top of search rankings and the Discover page.',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  height: 1.5,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
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
                        'Attracts up to 3× more impressions and customer clicks.',
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
              PrimaryGradientButton(
                height: 50,
                text: 'Boost Shop Now',
                onPressed: () {
                  Navigator.pop(ctx);
                  _triggerInstantBoost();
                },
              ),
              const SizedBox(height: 10),
              if (!hasActiveSub) ...[
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _scrollToPlans();
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.primary, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'View Subscription Plans',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ],
          ),
        );
      },
    );
  }



  Widget _buildTopBanner(bool isDark) {
    final topPadding = MediaQuery.paddingOf(context).top;
    final name = _shopProfile?.displayName.isNotEmpty == true
        ? _shopProfile!.displayName
        : 'Merchant';
    final subtitle = _shopProfile?.addressEn?.isNotEmpty == true
        ? _shopProfile!.addressEn!
        : (_shopProfile?.categoryEn?.isNotEmpty == true
            ? _shopProfile!.categoryEn!
            : 'Ready to serve diners');

    final bannerHeight = topPadding + 115;
    final fadeColor = isDark ? Theme.of(context).scaffoldBackgroundColor : Colors.white;

    return SizedBox(
      width: double.infinity,
      height: bannerHeight,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Panoramic Image with bottom white fade
          ShaderMask(
            shaderCallback: (rect) {
              return const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black,
                  Colors.black,
                  Colors.transparent,
                ],
                stops: [0.0, 0.40, 1.0],
              ).createShader(rect);
            },
            blendMode: BlendMode.dstIn,
            child: Image.asset(
              'assets/images/dashboard_banner.jpg',
              width: double.infinity,
              height: bannerHeight,
              fit: BoxFit.cover,
              alignment: Alignment.center,
            ),
          ),

          // 2. Top-down dark vignette for status bar icons & actions legibility
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: topPadding + 44,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.60),
                    Colors.black.withValues(alpha: 0.20),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // 3. Bottom-up white fade effect
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 85,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    fadeColor.withValues(alpha: 0.0),
                    fadeColor.withValues(alpha: 0.60),
                    fadeColor.withValues(alpha: 0.95),
                    fadeColor,
                  ],
                  stops: const [0.0, 0.40, 0.80, 1.0],
                ),
              ),
            ),
          ),

          // 4. Top Left: MyShop Logo Icon
          Positioned(
            top: topPadding + 2,
            left: 14,
            child: Container(
              width: 38,
              height: 38,
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.92),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.35),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Image.asset(
                'assets/images/app_logo2.png',
                fit: BoxFit.contain,
              ),
            ),
          ),

          // 5. Top Action Buttons (Notification Bell)
          Positioned(
            top: topPadding + 2,
            right: 14,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.35),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.25),
                  width: 1,
                ),
              ),
              child: const NotificationBadgeIcon(color: Colors.white),
            ),
          ),

          // 5. Bottom Overlay: Welcome Text & Location description on white fade
          Positioned(
            left: 18,
            right: 18,
            bottom: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Welcome, $name',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2.5),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        PhosphorIconsFill.mapPin,
                        size: 12,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.85)
                              : const Color(0xFF64748B),
                          height: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final t = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: RefreshIndicator(
          onRefresh: refresh,
          color: AppColors.primary,
          child: SingleChildScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Top Banner with bottom fade & header overlay
                _buildTopBanner(isDark),

                const SizedBox(height: 10),

                // 2. Today's Sales Card
                _buildTodaySalesCard(isDark),
                const SizedBox(height: 14),

                // 3. Icon Cards Grid (8 items in 4x2 grid)
                _buildIconCardsGrid(t, isDark),
                const SizedBox(height: 16),

                // 4. Plans & Pricing Section Card
                _buildPlansSectionCard(t, isDark),
                const SizedBox(height: 28),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlansSectionCard(AppLocalizations? t, bool isDark) {
    final hasActiveSub = _currentSubscription?.isActive == true;
    final planName = _currentSubscription?.plan?.nameEn;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.push(
              context,
              CupertinoPageRoute(builder: (_) => const PlansPage()),
            ).then((_) => refresh());
          },
          borderRadius: BorderRadius.circular(18),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              gradient: isDark
                  ? const LinearGradient(
                      colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : const LinearGradient(
                      colors: [Color(0xFFFFF7ED), Color(0xFFFFF1F2)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF334155)
                    : const Color(0xFFFED7AA),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                // Left: Glowing Crown Icon in gradient circle
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      PhosphorIconsFill.crown,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Center: Title, status badge & description
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Text(
                            t?.translate('plans') ?? 'Merchant Plans',
                            style: GoogleFonts.poppins(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              gradient: hasActiveSub
                                  ? const LinearGradient(
                                      colors: [Color(0xFF10B981), Color(0xFF059669)],
                                    )
                                  : AppColors.primaryGradient,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              hasActiveSub ? 'ACTIVE' : 'PRO',
                              style: GoogleFonts.poppins(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        hasActiveSub
                            ? 'Plan: $planName • Tap to manage or upgrade'
                            : 'Unlock priority reach, boost services & zero limits',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.70)
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Right: Caret Arrow
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      PhosphorIconsBold.caretRight,
                      size: 14,
                      color: AppColors.primary,
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

  Widget _buildTodaySalesCard(bool isDark) {
    final todayRevenue = _todaySummary?.revenue ?? 0.0;
    final yesterdayRevenue = _yesterdaySummary?.revenue ?? 0.0;
    final todayOrders = _todaySummary?.orders ?? 0;
    final todayItems = _todaySummary?.itemsSold ?? 0;
    final currency = _shopProfile?.currency ?? 'MMK';
    final formattedToday = NumberFormat('#,##0.00').format(todayRevenue);
    final formattedYesterday = NumberFormat('#,##0.00').format(yesterdayRevenue);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.push(
            context,
            CupertinoPageRoute(builder: (_) => const ReportPage()),
          );
        },
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFE11D48), // Rich Crimson
                Color(0xFFED3973), // Signature Primary Pink
                Color(0xFFF97316), // Warm Coral Orange
                Color(0xFFEFA240), // Golden Amber
              ],
              stops: [0.0, 0.32, 0.70, 1.0],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFED3973).withValues(alpha: 0.30),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                // Background food image icons
                Positioned(
                  right: -15,
                  top: -15,
                  bottom: -15,
                  child: Image.asset(
                    'assets/images/revenue_background_icons.png',
                    fit: BoxFit.fitHeight,
                  ),
                ),

                // Foreground Content
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Top Bar: Wallet icon + Total sales Today | Yesterday
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            PhosphorIconsFill.wallet,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Total sales Today',
                          style: GoogleFonts.poppins(
                            color: Colors.white.withValues(alpha: 0.95),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Yesterday',
                          style: GoogleFonts.poppins(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          '$currency $formattedYesterday',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // 2. Main Revenue Display
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      currency,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      formattedToday,
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),

              // 3. Subtle Divider
              Container(
                height: 1,
                color: Colors.white.withValues(alpha: 0.16),
              ),

              // 4. Bottom Row: Orders | Items | Report →
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.10),
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    Row(
                      children: [
                        const Icon(
                          PhosphorIconsFill.cookingPot,
                          size: 14,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '$todayOrders Food Orders',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Container(
                        width: 1,
                        height: 11,
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(
                          PhosphorIconsFill.package,
                          size: 14,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '$todayItems Items',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.20),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Report',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 2),
                          const Icon(
                            PhosphorIconsBold.arrowRight,
                            size: 9,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  ),
),
);
  }

  Widget _buildIconCardsGrid(AppLocalizations? t, bool isDark) {
    final items = [
      _DashboardGridItem(
        icon: PhosphorIconsFill.rocketLaunch,
        title: 'Boosting',
        badge: 'HOT',
        onTap: () => Navigator.push(
          context,
          CupertinoPageRoute(
            builder: (_) => BoostingServicesPage(
              currentSubscription: _currentSubscription,
              onRefresh: refresh,
              onOpenPlans: _scrollToPlans,
            ),
          ),
        ),
      ),
      _DashboardGridItem(
        icon: PhosphorIconsFill.trendUp,
        title: 'Visibility',
        badge: '+10',
        onTap: _showVisibilityBoostDetail,
      ),
      _DashboardGridItem(
        icon: PhosphorIconsFill.chartPieSlice,
        title: t?.translate('report') ?? 'Reports',
        onTap: () => Navigator.push(
          context,
          CupertinoPageRoute(builder: (_) => const ReportPage()),
        ),
      ),
      _DashboardGridItem(
        icon: Icons.auto_stories_rounded,
        title: 'Story',
        badge: 'NEW',
        onTap: () => Navigator.push(
          context,
          CupertinoPageRoute(builder: (_) => const ShopStoryPage()),
        ),
      ),
      _DashboardGridItem(
        icon: PhosphorIconsFill.briefcase,
        title: t?.translate('job_posts') ?? 'Job Posts',
        badge: 'NEW',
        onTap: () => Navigator.push(
          context,
          CupertinoPageRoute(builder: (_) => const JobPostsPage()),
        ),
      ),
      _DashboardGridItem(
        icon: PhosphorIconsFill.forkKnife,
        title: t?.translate('manage_menu_bottom') ?? 'Shop Menu',
        onTap: () => Navigator.push(
          context,
          CupertinoPageRoute(builder: (_) => const ManageShopMenuPage()),
        ),
      ),
      _DashboardGridItem(
        icon: PhosphorIconsFill.tag,
        title: t?.translate('manage_category_bottom') ?? 'Category',
        onTap: () => Navigator.push(
          context,
          CupertinoPageRoute(builder: (_) => const CategoryListScreen()),
        ),
      ),
      _DashboardGridItem(
        icon: PhosphorIconsRegular.qrCode,
        title: t?.translate('qr_scanner') ?? 'QR Scanner',
        onTap: () => Navigator.push(
          context,
          CupertinoPageRoute(builder: (_) => const OrderQrScannerScreen()),
        ),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: 6,
          mainAxisSpacing: 8,
          childAspectRatio: 0.94,
        ),
        itemBuilder: (context, index) {
          final item = items[index];
          return InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              item.onTap();
            },
            borderRadius: BorderRadius.circular(18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 66,
                      height: 66,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF334155)
                              : const Color(0xFFF1F5F9),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: isDark ? 0.35 : 0.06,
                            ),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: ShaderMask(
                          shaderCallback: (bounds) =>
                              AppColors.primaryGradient.createShader(bounds),
                          child: Icon(
                            item.icon,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                    if (item.badge != null)
                      Positioned(
                        top: -4,
                        right: -4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            gradient: item.badge == 'HOT'
                                ? const LinearGradient(
                                    colors: [Color(0xFFEF4444), Color(0xFFF97316)],
                                  )
                                : AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.35),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Text(
                            item.badge!,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 8.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  item.title,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSubscriptionStatusCard(AppLocalizations? t, bool isDark) {
    final actionable = _actionableSubscription;
    final current = _currentSubscription;

    if (actionable != null) {
      final canResubmit = actionable.canResubmitSlip;
      final rejectReason = () {
        final fromSub = actionable.rejectReason?.trim();
        if (fromSub != null && fromSub.isNotEmpty) return fromSub;
        final fromPayment = actionable.latestPayment?.rejectReason?.trim();
        if (fromPayment != null && fromPayment.isNotEmpty) return fromPayment;
        return null;
      }();
      final accent =
          actionable.isRejected ? AppColors.error : const Color(0xFFF59E0B);

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: accent.withValues(alpha: 0.5), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.1),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  actionable.isRejected
                      ? PhosphorIconsRegular.warningCircle
                      : PhosphorIconsRegular.clock,
                  size: 20,
                  color: accent,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    actionable.isRejected
                        ? (t?.translate('plans_status_rejected') ??
                            'Payment not accepted')
                        : (t?.translate('plans_status_pending') ??
                            'Awaiting Admin Review'),
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: accent,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              actionable.planName,
              style: GoogleFonts.poppins(
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (rejectReason != null) ...[
              const SizedBox(height: 6),
              Text(
                rejectReason,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  height: 1.4,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
            ],
            if (canResubmit) ...[
              const SizedBox(height: 14),
              PrimaryGradientButton(
                height: 44,
                text: t?.translate('plans_resubmit_payment') ??
                    'Resubmit Payment',
                onPressed: () => _openResubmit(actionable),
              ),
            ],
          ],
        ),
      );
    }

    if (current != null) {
      final days = current.daysRemaining;
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.25),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        PhosphorIconsFill.crown,
                        size: 14,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        t?.translate('plans_current_plan') ?? 'Current Plan',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                if (days != null)
                  Text(
                    (t?.translate('plans_days_remaining') ??
                            '{days} days left')
                        .replaceAll('{days}', '$days'),
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.95),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              current.planName,
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            if (current.quotas.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: current.quotas.take(4).map((q) {
                  final label = q.isUnlimited
                      ? '${q.featureName ?? q.featureKey}: Unlimited'
                      : (q.limit != null
                          ? '${q.featureName ?? q.featureKey}: ×${q.limit}'
                          : '${q.featureName ?? q.featureKey}');
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      label,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildSubscriptionPlansSection(AppLocalizations? t, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t?.translate('plans') ?? 'Subscription Plans',
                style: GoogleFonts.poppins(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                  letterSpacing: -0.3,
                ),
              ),
              Text(
                'Unlock all boosting services, priority reach & zero limits',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
            ],
          ),
        ),
        if (_anyHasAnnual) ...[
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _buildBillingToggle(t, isDark),
          ),
        ],
        const SizedBox(height: 16),
        if (_plans.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
            child: Center(
              child: Text(
                _loadFailed
                    ? (t?.translate('plans_load_failed') ?? 'Could not load plans')
                    : (t?.translate('no_plans') ?? 'No Plans Available'),
                style: GoogleFonts.poppins(
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
            ),
          )
        else
          ..._plans.map(
            (plan) => Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: _PlanCard(
                plan: plan,
                annualBilling: _annualBilling,
                priceFormat: _priceFormat,
                currency: _shopProfile?.currency ?? 'MMK',
                isCurrent: _currentSubscription?.planId == plan.id &&
                    _currentSubscription?.isActive == true,
                onCta: () => _onPlanCta(plan),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBillingToggle(AppLocalizations? t, bool isDark) {
    final save = _savePercent;
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : AppColors.outlineVariant,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _BillingChip(
              label: t?.translate('plans_monthly') ?? 'Monthly',
              selected: !_annualBilling,
              onTap: () => setState(() => _annualBilling = false),
            ),
          ),
          Expanded(
            child: _BillingChip(
              label: save != null
                  ? (t?.translate('plans_annually_save') ??
                          'Annually · Save {percent}%')
                      .replaceAll('{percent}', '$save')
                  : (t?.translate('plans_annually') ?? 'Annually'),
              selected: _annualBilling,
              onTap: () => setState(() => _annualBilling = true),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: const [
          Skeleton(height: 120, borderRadius: 20),
          SizedBox(height: 16),
          Skeleton(height: 72, borderRadius: 16),
          SizedBox(height: 12),
          Skeleton(height: 72, borderRadius: 16),
          SizedBox(height: 12),
          Skeleton(height: 72, borderRadius: 16),
          SizedBox(height: 20),
          Skeleton(height: 240, borderRadius: 20),
        ],
      ),
    );
  }
}

class _DashboardGridItem {
  final IconData icon;
  final String title;
  final Color? color;
  final String? badge;
  final VoidCallback onTap;

  const _DashboardGridItem({
    required this.icon,
    required this.title,
    this.color,
    this.badge,
    required this.onTap,
  });
}

class _BillingChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _BillingChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: selected ? AppColors.primaryGradient : null,
          color: selected ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected
                ? Colors.white
                : Theme.of(context).textTheme.bodyMedium?.color,
          ),
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final PlanModel plan;
  final bool annualBilling;
  final NumberFormat priceFormat;
  final bool isCurrent;
  final String currency;
  final VoidCallback onCta;

  const _PlanCard({
    required this.plan,
    required this.annualBilling,
    required this.priceFormat,
    required this.isCurrent,
    required this.currency,
    required this.onCta,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isHighlighted = plan.isPopular;

    final displayPrice = plan.displayMonthlyAmount(annual: annualBilling) ?? plan.price ?? 0;
    final periodLabel = annualBilling && plan.hasAnnualPricing
        ? (t?.translate('plans_per_year') ?? '/ year')
        : (t?.translate('plans_per_month') ?? '/ month');

    final effectiveDiscount = annualBilling ? plan.annualDiscountPercent : null;

    final baseBorder = isHighlighted
        ? AppColors.primary
        : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0));

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: baseBorder,
          width: isHighlighted ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isHighlighted
                ? AppColors.primary.withValues(alpha: 0.15)
                : Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: isHighlighted ? 22 : 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isHighlighted || plan.ctaLabel != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: const BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(22)),
              ),
              alignment: Alignment.center,
              child: Text(
                (isHighlighted
                        ? (t?.translate('plans_most_popular') ?? 'MOST POPULAR')
                        : (plan.ctaLabel ?? 'FEATURED'))
                    .toUpperCase(),
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            plan.displayName,
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color:
                                  Theme.of(context).textTheme.bodyLarge?.color,
                            ),
                          ),
                          if (plan.displayDescription.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              plan.displayDescription,
                              style: GoogleFonts.poppins(
                                fontSize: 12.5,
                                color: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.color,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (isCurrent)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFF10B981).withValues(alpha: 0.4),
                          ),
                        ),
                        child: Text(
                          t?.translate('plans_active_badge') ?? 'Active',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF10B981),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 18),
                if (plan.isCustomPricing) ...[
                  Text(
                    t?.translate('plans_custom_pricing') ?? 'Custom Pricing',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    t?.translate('plans_contact_sales_desc') ??
                        'Tailored for large restaurant franchises',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                ] else ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        currency,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        priceFormat.format(displayPrice),
                        style: GoogleFonts.poppins(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        periodLabel,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                    ],
                  ),
                  if (effectiveDiscount != null && effectiveDiscount > 0) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${t?.translate('plans_save') ?? 'Save'} $effectiveDiscount%',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF10B981),
                        ),
                      ),
                    ),
                  ],
                ],
                const SizedBox(height: 20),
                Divider(
                  height: 1,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : AppColors.outlineVariant,
                ),
                const SizedBox(height: 18),
                Text(
                  t?.translate('plans_whats_included') ?? "WHAT'S INCLUDED",
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
                const SizedBox(height: 12),
                if (plan.highlights.isNotEmpty)
                  ...plan.highlights.map(
                    (h) => _BulletRow(text: h.textEn),
                  ),
                if (plan.featureValues.isNotEmpty)
                  ...plan.featureValues.map(
                    (fv) => _FeatureValueRow(featureValue: fv),
                  ),
                if (plan.highlights.isEmpty && plan.featureValues.isEmpty)
                  _BulletRow(
                    text: t?.translate('plans_all_core_features') ??
                        'All core merchant dashboard features',
                  ),
                const SizedBox(height: 22),
                if (isCurrent)
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton(
                      onPressed: onCta,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF10B981), width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        t?.translate('plans_current_active') ?? 'Active Plan',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF10B981),
                        ),
                      ),
                    ),
                  )
                else
                  PrimaryGradientButton(
                    height: 50,
                    text: plan.isCustomPricing
                        ? (t?.translate('plans_contact_sales') ?? 'Contact Sales')
                        : (t?.translate('plans_subscribe_now') ?? 'Subscribe Now'),
                    onPressed: onCta,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureValueRow extends StatelessWidget {
  final PlanFeatureValueModel featureValue;
  const _FeatureValueRow({required this.featureValue});

  @override
  Widget build(BuildContext context) {
    final title = featureValue.feature?.displayName ?? 'Feature';
    final amountLabel = featureValue.isUnlimited
        ? 'Unlimited'
        : (featureValue.quantity != null
            ? '×${featureValue.quantity} ${featureValue.period ?? ''}'.trim()
            : (featureValue.valueLabel ?? 'Included'));

    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: 0.12),
            ),
            child: const Icon(
              PhosphorIconsBold.check,
              size: 13,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
          ),
          Text(
            amountLabel,
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _BulletRow extends StatelessWidget {
  final String text;
  const _BulletRow({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: 0.12),
            ),
            child: const Icon(
              PhosphorIconsBold.check,
              size: 13,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
