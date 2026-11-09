import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_shop/core/network/api_helper.dart';
import 'package:my_shop/core/presentation/widgets/app_dialog.dart';
import 'package:my_shop/core/presentation/widgets/back_title_app_bar.dart';
import 'package:my_shop/core/presentation/widgets/primary_gradient_button.dart';
import 'package:my_shop/core/utils/app_colors.dart';
import 'package:my_shop/features/subscription/data/services/subscription_service.dart';

class SubscriptionPlansPage extends StatefulWidget {
  const SubscriptionPlansPage({super.key});

  @override
  State<SubscriptionPlansPage> createState() => _SubscriptionPlansPageState();
}

class _SubscriptionPlansPageState extends State<SubscriptionPlansPage> {
  final SubscriptionService _service = SubscriptionService();
  bool _loading = true;
  String? _error;
  List<ShopPlan> _plans = [];
  ShopSubscriptionSummary? _current;
  ShopSubscriptionSummary? _pending;
  ShopSubscriptionSummary? _rejected;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final plans = await _service.getPlans();
      final current = await _quiet(_service.getCurrent());
      final history = await _quiet(_service.getHistory()) ?? <ShopSubscriptionSummary>[];
      if (!mounted) return;
      setState(() {
        _plans = plans;
        _current = current;
        _pending = _firstStatus(history, 'PENDING');
        _rejected = _firstStatus(history, 'REJECTED');
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not load plans. Pull to try again.';
      });
    }
  }

  Future<T?> _quiet<T>(Future<T> future) async {
    try {
      return await future;
    } catch (_) {
      return null;
    }
  }

  ShopSubscriptionSummary? _firstStatus(
    List<ShopSubscriptionSummary> rows,
    String status,
  ) {
    for (final row in rows) {
      if (row.status == status) return row;
    }
    return null;
  }

  Future<void> _openBuy(ShopPlan plan) async {
    if (_pending != null) {
      AppDialog.showToast(
        context,
        'You already confirmed a plan. Wait for it to be turned on.',
        isError: true,
      );
      return;
    }
    final message = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _BuyPlanSheet(
        plan: plan,
        service: _service,
      ),
    );
    if (!mounted || message == null || message.isEmpty) return;
    AppDialog.showToast(context, message);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const BackTitleAppBar(title: 'Subscription'),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                children: [
                  if (_error != null)
                    Text(_error!, style: GoogleFonts.poppins(color: AppColors.error)),
                  if (_current != null) _StatusCard(subscription: _current!, title: 'Current plan'),
                  if (_pending != null)
                    _StatusCard(
                      subscription: _pending!,
                      title: 'Waiting for review',
                      message: 'A SuperAdmin will turn this plan on. You can confirm another plan after that.',
                    ),
                  if (_pending == null && _rejected != null)
                    _StatusCard(
                      subscription: _rejected!,
                      title: 'Last request was not accepted',
                      message: _rejected!.rejectReason?.isNotEmpty == true
                          ? _rejected!.rejectReason!
                          : 'You can confirm a plan again below.',
                    ),
                  const SizedBox(height: 8),
                  if (_plans.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 48),
                      child: Text(
                        'No plans are available right now.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(color: AppColors.onSurfaceVariant),
                      ),
                    ),
                  ..._plans.map(
                    (plan) => _PlanCard(
                      plan: plan,
                      locked: _pending != null,
                      onBuy: () => _openBuy(plan),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final ShopSubscriptionSummary subscription;
  final String title;
  final String? message;

  const _StatusCard({
    required this.subscription,
    required this.title,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.poppins(fontSize: 12, color: AppColors.onSurfaceVariant)),
          const SizedBox(height: 4),
          Text(
            subscription.planName,
            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            [
              subscription.status,
              if (subscription.billingPeriod != null) subscription.billingPeriod,
              if (subscription.amount != null) formatBaht(subscription.amount!),
              if (subscription.daysRemaining != null) '${subscription.daysRemaining} days left',
            ].join(' · '),
            style: GoogleFonts.poppins(fontSize: 13),
          ),
          if (message != null) ...[
            const SizedBox(height: 8),
            Text(message!, style: GoogleFonts.poppins(fontSize: 13, color: AppColors.subtitle)),
          ],
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final ShopPlan plan;
  final bool locked;
  final VoidCallback onBuy;

  const _PlanCard({
    required this.plan,
    required this.locked,
    required this.onBuy,
  });

  @override
  Widget build(BuildContext context) {
    final price = plan.isCustomPricing
        ? "Let's talk"
        : plan.monthlyPrice == null
            ? 'Price on request'
            : '${formatBaht(plan.monthlyPrice!)} / month';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: plan.isPopular ? AppColors.primary : Theme.of(context).dividerColor,
          width: plan.isPopular ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  plan.name,
                  style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ),
              if (plan.isPopular)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Popular',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(price, style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600)),
          if (plan.hasAnnualPricing && plan.annualPrice != null)
            Text(
              '${formatBaht(plan.annualPrice!)} for the year',
              style: GoogleFonts.poppins(fontSize: 13, color: AppColors.subtitle),
            ),
          if (plan.description != null && plan.description!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(plan.description!, style: GoogleFonts.poppins(fontSize: 13)),
          ],
          if (plan.highlights.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...plan.highlights.take(6).map(
              (line) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('• $line', style: GoogleFonts.poppins(fontSize: 13)),
              ),
            ),
          ],
          const SizedBox(height: 12),
          PrimaryGradientButton(
            text: plan.isCustomPricing ? 'Contact us' : 'Confirm',
            height: 46,
            onPressed: plan.isCustomPricing || locked ? null : onBuy,
          ),
          if (plan.isCustomPricing)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'This plan has no fixed price. Message the MyTogether team.',
                style: GoogleFonts.poppins(fontSize: 12, color: AppColors.subtitle),
              ),
            ),
        ],
      ),
    );
  }
}

class _BuyPlanSheet extends StatefulWidget {
  final ShopPlan plan;
  final SubscriptionService service;

  const _BuyPlanSheet({
    required this.plan,
    required this.service,
  });

  @override
  State<_BuyPlanSheet> createState() => _BuyPlanSheetState();
}

class _BuyPlanSheetState extends State<_BuyPlanSheet> {
  late String _period;
  final Map<String, Set<int>> _picks = {};
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.plan.monthlyPrice == null && widget.plan.hasAnnualPricing) {
      _period = 'YEARLY';
    } else if (widget.plan.hasAnnualPricing && widget.plan.billingPeriod == 'YEARLY') {
      _period = 'YEARLY';
    } else {
      _period = 'MONTHLY';
    }
    for (final choice in widget.plan.choices) {
      _picks[choice.featureName] = {};
    }
  }

  double? get _amount => _period == 'YEARLY' ? widget.plan.annualPrice : widget.plan.monthlyPrice;

  Future<void> _submit() async {
    if (_amount == null) {
      AppDialog.showToast(
        context,
        'This plan has no price for that period.',
        isError: true,
      );
      return;
    }
    final selected = <int>[];
    for (final choice in widget.plan.choices) {
      final picks = _picks[choice.featureName] ?? {};
      final required = choice.chooseCount > choice.options.length
          ? choice.options.length
          : choice.chooseCount;
      if (picks.length != required) {
        AppDialog.showToast(
          context,
          'Choose $required option(s) for "${choice.featureName}".',
          isError: true,
        );
        return;
      }
      selected.addAll(picks);
    }

    setState(() => _saving = true);
    try {
      final message = await widget.service.confirm(
        planId: widget.plan.id,
        billingPeriod: _period,
        selectedOptionIds: selected,
      );
      if (!mounted) return;
      Navigator.pop(context, message);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      AppDialog.showToast(context, error.details ?? error.message, isError: true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      AppDialog.showToast(context, 'Could not confirm the plan.', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.92),
      padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + bottom),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppColors.outlineVariant,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            Text(
              'Confirm ${widget.plan.name}',
              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            if (widget.plan.hasAnnualPricing && widget.plan.monthlyPrice != null)
              Row(
                children: [
                  _PeriodChip(
                    label: 'Monthly',
                    selected: _period == 'MONTHLY',
                    onTap: () => setState(() => _period = 'MONTHLY'),
                  ),
                  const SizedBox(width: 8),
                  _PeriodChip(
                    label: 'Yearly',
                    selected: _period == 'YEARLY',
                    onTap: () => setState(() => _period = 'YEARLY'),
                  ),
                ],
              ),
            const SizedBox(height: 8),
            Text(
              _amount == null ? 'Amount is set by the plan' : formatBaht(_amount!),
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            for (final choice in widget.plan.choices) ...[
              const SizedBox(height: 16),
              Text(
                '${choice.featureName} (choose ${choice.chooseCount})',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              ...choice.options.map((option) {
                final selected = _picks[choice.featureName]?.contains(option.id) ?? false;
                return CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: selected,
                  activeColor: AppColors.primary,
                  title: Text(option.text, style: GoogleFonts.poppins(fontSize: 14)),
                  onChanged: (checked) {
                    final picks = _picks[choice.featureName] ?? {};
                    if (checked == true &&
                        !picks.contains(option.id) &&
                        picks.length >= choice.chooseCount) {
                      AppDialog.showToast(
                        context,
                        'Choose only ${choice.chooseCount} for "${choice.featureName}".',
                        isError: true,
                      );
                      return;
                    }
                    setState(() {
                      if (checked == true) {
                        picks.add(option.id);
                      } else {
                        picks.remove(option.id);
                      }
                      _picks[choice.featureName] = picks;
                    });
                  },
                );
              }),
            ],
            const SizedBox(height: 16),
            Text(
              'Payment comes later. Confirm sends this plan for approval.',
              style: GoogleFonts.poppins(fontSize: 13, color: AppColors.subtitle),
            ),
            const SizedBox(height: 16),
            PrimaryGradientButton(
              text: 'Confirm',
              isLoading: _saving,
              onPressed: _saving ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}

class _PeriodChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PeriodChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: selected ? AppColors.primary : AppColors.outline),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            color: selected ? Colors.white : null,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

String formatBaht(double amount) {
  final text = amount % 1 == 0 ? amount.toStringAsFixed(0) : amount.toStringAsFixed(2);
  return '฿$text';
}
