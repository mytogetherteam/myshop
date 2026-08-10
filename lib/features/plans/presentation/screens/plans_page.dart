import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:my_shop/core/localization/app_localizations.dart';
import 'package:my_shop/core/presentation/widgets/app_dialog.dart';
import 'package:my_shop/core/presentation/widgets/back_title_app_bar.dart';
import 'package:my_shop/core/presentation/widgets/empty_state.dart';
import 'package:my_shop/core/presentation/widgets/primary_gradient_button.dart';
import 'package:my_shop/core/presentation/widgets/skeleton.dart';
import 'package:my_shop/core/utils/app_colors.dart';
import 'package:my_shop/features/profile/presentation/screens/help_support_page.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../data/models/plan_model.dart';
import '../../data/models/subscription_model.dart';
import '../../data/services/plan_service.dart';
import '../../data/services/subscription_service.dart';
import 'subscribe_plan_page.dart';

class PlansPage extends StatefulWidget {
  const PlansPage({super.key});

  @override
  State<PlansPage> createState() => _PlansPageState();
}

class _PlansPageState extends State<PlansPage> {
  final PlanService _service = PlanService();
  final SubscriptionService _subscriptionService = SubscriptionService();
  final NumberFormat _priceFormat = NumberFormat('#,##0.##');

  List<PlanModel> _plans = [];
  SubscriptionModel? _currentSubscription;
  SubscriptionModel? _actionableSubscription;
  bool _isLoading = true;
  bool _loadFailed = false;
  bool _annualBilling = false;
  bool _billingInitialized = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _loadFailed = false;
    });

    final results = await Future.wait([
      _service.getPlans(page: 1, size: 50),
      _subscriptionService.getCurrent(),
      _subscriptionService.getSubscriptions(page: 1, size: 20),
    ]);
    if (!mounted) return;

    final planResult = results[0] as PlanListResult?;
    final currentResult =
        results[1] as ({SubscriptionModel? subscription, bool failed});
    final historyResult = results[2] as SubscriptionListResult?;

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
    // Pending review always wins. An older rejection must not hide a live plan.
    final actionable = pending ?? (current == null ? rejected : null);

    setState(() {
      _plans = plans;
      _currentSubscription = current;
      _actionableSubscription = actionable;
      _isLoading = false;
      _loadFailed = planResult == null;
      if (!_billingInitialized && planResult != null && plans.isNotEmpty) {
        final preferred = plans.firstWhere(
          (p) => p.isPopular,
          orElse: () => plans.first,
        );
        _annualBilling = preferred.billingPeriod == 'YEARLY';
        _billingInitialized = true;
      }
    });
  }

  bool get _anyHasAnnual =>
      _plans.any((p) => !p.isCustomPricing && p.hasAnnualPricing);

  int? get _savePercent {
    for (final plan in _plans) {
      if (plan.annualDiscountPercent != null &&
          plan.annualDiscountPercent! > 0) {
        return plan.annualDiscountPercent;
      }
    }
    return null;
  }

  Future<void> _onCta(PlanModel plan) async {
    final t = AppLocalizations.of(context);
    if (plan.isCustomPricing) {
      await Navigator.push(
        context,
        CupertinoPageRoute(builder: (_) => const HelpSupportPage()),
      );
      return;
    }

    final pending = _actionableSubscription;
    if (pending != null && pending.isPending) {
      AppDialog.showToast(
        context,
        (t?.translate('plans_pending_exists') ??
                'You already have a pending request for "{plan}".')
            .replaceAll('{plan}', pending.planName),
        isError: true,
      );
      return;
    }

    final changed = await Navigator.push<bool>(
      context,
      CupertinoPageRoute(
        builder: (_) => SubscribePlanPage.purchase(
          plan: plan,
          annualBilling: _annualBilling,
        ),
      ),
    );
    if (changed == true) _load();
  }

  Future<void> _openResubmit(SubscriptionModel subscription) async {
    final changed = await Navigator.push<bool>(
      context,
      CupertinoPageRoute(
        builder: (_) =>
            SubscribePlanPage.resubmit(subscription: subscription),
      ),
    );
    if (changed == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0B1120) : const Color(0xFFF1F5F9);

    return Scaffold(
      backgroundColor: bg,
      appBar: BackTitleAppBar(title: t?.translate('plans') ?? 'Plans'),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _load,
        child: _isLoading
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  20,
                  20,
                  20,
                  20 + MediaQuery.paddingOf(context).bottom,
                ),
                children: const [
                  Skeleton(height: 120, borderRadius: 20),
                  SizedBox(height: 16),
                  Skeleton(height: 280, borderRadius: 20),
                  SizedBox(height: 16),
                  Skeleton(height: 280, borderRadius: 20),
                ],
              )
            : _plans.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.55,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            EmptyState(
                              scrollable: false,
                              icon: const PhosphorIcon(
                                PhosphorIconsRegular.crown,
                                size: 64,
                                color: AppColors.iconDisabled,
                              ),
                              title: _loadFailed
                                  ? (t?.translate('plans_load_failed') ??
                                      'Could not load plans')
                                  : (t?.translate('no_plans') ??
                                      'No Plans Yet'),
                              subtitle: _loadFailed
                                  ? (t?.translate('plans_load_failed_desc') ??
                                      'Pull to refresh and try again.')
                                  : (t?.translate('no_plans_desc') ??
                                      'Subscription plans will appear here once available.'),
                            ),
                            if (_loadFailed) ...[
                              const SizedBox(height: 20),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 48),
                                child: PrimaryGradientButton(
                                  height: 48,
                                  text: t?.translate('retry') ?? 'Retry',
                                  onPressed: _load,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  )
                : ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(
                      20,
                      8,
                      20,
                      32 + MediaQuery.paddingOf(context).bottom,
                    ),
                    children: [
                      _buildHeader(t, isDark),
                      if (_currentSubscription != null ||
                          _actionableSubscription != null) ...[
                        const SizedBox(height: 16),
                        _buildSubscriptionBanner(t, isDark),
                      ],
                      if (_anyHasAnnual) ...[
                        const SizedBox(height: 20),
                        _buildBillingToggle(t, isDark),
                      ],
                      const SizedBox(height: 20),
                      ..._plans.map(
                        (plan) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _PlanCard(
                            plan: plan,
                            annualBilling: _annualBilling,
                            priceFormat: _priceFormat,
                            isCurrent: _currentSubscription?.planId == plan.id,
                            onCta: () => _onCta(plan),
                          ),
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }

  Widget _buildSubscriptionBanner(AppLocalizations? t, bool isDark) {
    final actionable = _actionableSubscription;
    final current = _currentSubscription;
    final children = <Widget>[];

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
          actionable.isRejected ? AppColors.error : AppColors.secondary;
      children.add(
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: accent.withValues(alpha: 0.45)),
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
                    size: 18,
                    color: accent,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      actionable.isRejected
                          ? (t?.translate('plans_status_rejected') ??
                              'Payment not accepted')
                          : (t?.translate('plans_status_pending') ??
                              'Awaiting review'),
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
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (rejectReason != null) ...[
                const SizedBox(height: 6),
                Text(
                  rejectReason,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    height: 1.35,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
              ],
              if (canResubmit) ...[
                const SizedBox(height: 12),
                PrimaryGradientButton(
                  height: 44,
                  text: t?.translate('plans_resubmit_payment') ??
                      'Resubmit Payment',
                  onPressed: () => _openResubmit(actionable),
                ),
              ],
            ],
          ),
        ),
      );
    }

    if (current != null &&
        (actionable == null || actionable.planId != current.planId)) {
      final days = current.daysRemaining;
      if (children.isNotEmpty) children.add(const SizedBox(height: 12));
      children.add(
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t?.translate('plans_current_plan') ?? 'Current plan',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                current.planName,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              if (days != null) ...[
                const SizedBox(height: 4),
                Text(
                  (t?.translate('plans_days_remaining') ??
                          '{days} days remaining')
                      .replaceAll('{days}', '$days'),
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    if (children.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }

  Widget _buildHeader(AppLocalizations? t, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: isDark ? 0.25 : 0.2),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t?.translate('plans_header_title') ?? 'Grow your shop with us',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            t?.translate('plans_header_subtitle') ??
                'Choose a plan to boost sales, manage orders, and reach more customers.',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: Colors.white.withValues(alpha: 0.9),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBillingToggle(AppLocalizations? t, bool isDark) {
    final save = _savePercent;
    return Container(
      padding: const EdgeInsets.all(6),
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            gradient: selected ? AppColors.primaryGradient : null,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              height: 1.2,
              fontWeight: FontWeight.w600,
              color: selected
                  ? Colors.white
                  : Theme.of(context).textTheme.bodyMedium?.color,
            ),
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
  final VoidCallback onCta;

  const _PlanCard({
    required this.plan,
    required this.annualBilling,
    required this.priceFormat,
    required this.isCurrent,
    required this.onCta,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final amount = plan.displayMonthlyAmount(annual: annualBilling);
    final showAnnualSubtext =
        annualBilling && !plan.isCustomPricing && plan.hasAnnualPricing;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isCurrent || plan.isPopular
              ? AppColors.primary.withValues(alpha: 0.55)
              : (isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : AppColors.outlineVariant),
          width: (isCurrent || plan.isPopular) ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.transparent
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              (plan.isPopular || isCurrent) ? 28 : 20,
              20,
              20,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plan.displayName,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                if (plan.displayDescription.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    plan.displayDescription,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      height: 1.4,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                if (plan.isCustomPricing)
                  Text(
                    t?.translate('plans_lets_talk') ?? "Let's talk",
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      fontStyle: FontStyle.italic,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  )
                else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '฿',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            amount == null ? '—' : priceFormat.format(amount),
                            style: GoogleFonts.poppins(
                              fontSize: 34,
                              fontWeight: FontWeight.w700,
                              height: 1,
                              color: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.color,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          t?.translate('plans_per_month') ?? '/ mo',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color:
                                Theme.of(context).textTheme.bodySmall?.color,
                          ),
                        ),
                      ),
                    ],
                  ),
                if (showAnnualSubtext) ...[
                  const SizedBox(height: 4),
                  Text(
                    t?.translate('plans_billed_annually') ?? 'Billed annually',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primary,
                    ),
                  ),
                ],
                if (plan.featureValues.isNotEmpty ||
                    plan.highlights.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  ...plan.featureValues.map((feature) {
                    final line = feature.displayLine;
                    if (line.isEmpty) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _FeatureRow(text: line),
                          if (feature.offeredOptions.isNotEmpty)
                            ...feature.offeredOptions.map(
                              (option) => Padding(
                                padding:
                                    const EdgeInsets.only(left: 28, top: 6),
                                child: Text(
                                  '• ${option.displayText}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    height: 1.35,
                                    fontWeight: FontWeight.w400,
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.color,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  }),
                  ...plan.highlights.map((highlight) {
                    final line = highlight.displayText;
                    if (line.isEmpty) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _FeatureRow(text: line),
                    );
                  }),
                ],
                const SizedBox(height: 8),
                if (isCurrent)
                  Container(
                    width: double.infinity,
                    height: 54,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.primary, width: 1.5),
                      color: AppColors.primary.withValues(alpha: 0.08),
                    ),
                    child: Text(
                      t?.translate('plans_current_plan') ?? 'Current plan',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  )
                else
                  PrimaryGradientButton(
                    text: plan.ctaLabel?.trim().isNotEmpty == true
                        ? plan.ctaLabel!.trim()
                        : (plan.isCustomPricing
                            ? (t?.translate('plans_contact_us') ??
                                'Contact Us')
                            : (t?.translate('plans_get_started') ??
                                'Get Started')),
                    onPressed: onCta,
                  ),
              ],
            ),
          ),
          if (isCurrent || plan.isPopular)
            Positioned(
              top: 0,
              right: 16,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(10),
                  ),
                ),
                child: Text(
                  isCurrent
                      ? (t?.translate('plans_current_badge') ?? 'Current')
                      : (t?.translate('plans_most_popular') ?? 'Most Popular'),
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final String text;

  const _FeatureRow({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          PhosphorIconsRegular.checkCircle,
          size: 18,
          color: AppColors.primary,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 13,
              height: 1.35,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
        ),
      ],
    );
  }
}
