import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:my_shop/core/data/services/image_upload_service.dart';
import 'package:my_shop/core/localization/app_localizations.dart';
import 'package:my_shop/core/presentation/widgets/app_dialog.dart';
import 'package:my_shop/core/presentation/widgets/back_title_app_bar.dart';
import 'package:my_shop/core/presentation/widgets/primary_gradient_button.dart';
import 'package:my_shop/core/utils/app_colors.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../data/models/plan_model.dart';
import '../../data/models/platform_payment_account_model.dart';
import '../../data/models/subscription_model.dart';
import '../../data/services/platform_payment_account_service.dart';
import '../../data/services/subscription_service.dart';

class SubscribePlanPage extends StatefulWidget {
  final PlanModel? plan;
  final bool annualBilling;
  final SubscriptionModel? resubmitSubscription;

  const SubscribePlanPage.purchase({
    super.key,
    required PlanModel this.plan,
    this.annualBilling = false,
  }) : resubmitSubscription = null;

  const SubscribePlanPage.resubmit({
    super.key,
    required SubscriptionModel subscription,
  })  : plan = null,
        annualBilling = false,
        resubmitSubscription = subscription;

  @override
  State<SubscribePlanPage> createState() => _SubscribePlanPageState();
}

class _SubscribePlanPageState extends State<SubscribePlanPage> {
  final SubscriptionService _subscriptionService = SubscriptionService();
  final PlatformPaymentAccountService _accountService =
      PlatformPaymentAccountService();
  final ImageUploadService _imageService = ImageUploadService();
  final TextEditingController _transferRefController = TextEditingController();
  final NumberFormat _priceFormat = NumberFormat('#,##0.##');

  List<PlatformPaymentAccountModel> _accounts = [];
  final Map<int, Set<int>> _selectedOptionsByFeature = {};
  int? _selectedAccountId;
  XFile? _slip;
  Future<Uint8List>? _slipBytes;
  bool _loadingAccounts = true;
  bool _accountsFailed = false;
  bool _submitting = false;
  late bool _annualBilling;

  bool get _isResubmit => widget.resubmitSubscription != null;
  PlanModel? get _plan => widget.plan;

  @override
  void initState() {
    super.initState();
    _annualBilling = widget.annualBilling && (_plan?.hasAnnualPricing == true);
    for (final feature in _plan?.selectableFeatures ?? const []) {
      _selectedOptionsByFeature[feature.id] = <int>{};
    }
    _loadAccounts();
  }

  @override
  void dispose() {
    _transferRefController.dispose();
    super.dispose();
  }

  Future<void> _loadAccounts() async {
    setState(() {
      _loadingAccounts = true;
      _accountsFailed = false;
    });
    final accounts = await _accountService.getAccounts();
    if (!mounted) return;
    setState(() {
      _loadingAccounts = false;
      if (accounts == null) {
        _accounts = [];
        _accountsFailed = true;
        return;
      }
      _accounts = accounts;
      _accountsFailed = false;
      if (accounts.isNotEmpty) {
        _selectedAccountId = accounts.first.id;
      }
    });
  }

  double? get _amountDue {
    if (_isResubmit) return widget.resubmitSubscription?.amount;
    return _plan?.chargeAmount(annual: _annualBilling);
  }

  String get _billingPeriod => _annualBilling ? 'YEARLY' : 'MONTHLY';

  PlatformPaymentAccountModel? get _selectedAccount {
    for (final account in _accounts) {
      if (account.id == _selectedAccountId) return account;
    }
    return null;
  }

  Future<void> _pickSlip() async {
    final t = AppLocalizations.of(context);
    final source = await _askSlipSource(t);
    if (source == null || !mounted) return;

    final result = source == ImageSource.camera
        ? await _imageService.pickFromCamera(
            crop: true,
            maxFileSizeMB: 8,
          )
        : await _imageService.pickFromGallery(
            crop: true,
            maxFileSizeMB: 8,
          );
    if (!mounted) return;

    if (result.permanentlyDenied) {
      final openSettings = await AppDialog.showConfirm(
        context,
        title: t?.translate('plans_permission_title') ?? 'Permission Required',
        message: t?.translate('plans_permission_settings') ??
            'Photo or camera access is required to upload a payment slip. Please enable it in Settings.',
        confirmLabel: t?.translate('open_settings') ?? 'Open Settings',
      );
      if (openSettings == true) {
        await openAppSettings();
      }
      return;
    }

    if (result.permissionDenied) {
      AppDialog.showToast(
        context,
        t?.translate('plans_permission_denied') ??
            'Photo permission is required to upload a slip.',
        isError: true,
      );
      return;
    }
    if (result.isTooLarge) {
      AppDialog.showToast(
        context,
        t?.translate('plans_slip_too_large') ??
            'Payment slip must be under 8 MB.',
        isError: true,
      );
      return;
    }
    if (result.file != null) {
      setState(() {
        _slip = result.file;
        _slipBytes = result.file!.readAsBytes();
      });
    }
  }

  Future<ImageSource?> _askSlipSource(AppLocalizations? t) async {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: Text(
                  t?.translate('choose_from_gallery') ?? 'Choose from Gallery',
                  style: GoogleFonts.poppins(),
                ),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: Text(
                  t?.translate('take_photo') ?? 'Take a Photo',
                  style: GoogleFonts.poppins(),
                ),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
            ],
          ),
        );
      },
    );
  }

  bool _validateSelections(AppLocalizations? t) {
    for (final feature in _plan?.selectableFeatures ?? const []) {
      final required = feature.chooseCount ?? 0;
      final picked = _selectedOptionsByFeature[feature.id]?.length ?? 0;
      if (picked != required) {
        AppDialog.showToast(
          context,
          (t?.translate('plans_choose_options') ??
                  'Choose {count} option(s) for "{feature}".')
              .replaceAll('{count}', '$required')
              .replaceAll('{feature}', feature.feature?.displayName ?? ''),
          isError: true,
        );
        return false;
      }
    }
    return true;
  }

  Future<void> _submit() async {
    final t = AppLocalizations.of(context);
    FocusManager.instance.primaryFocus?.unfocus();
    if (_submitting) return;
    if (_slip == null) {
      AppDialog.showToast(
        context,
        t?.translate('plans_slip_required') ??
            'Please upload your payment screenshot.',
        isError: true,
      );
      return;
    }
    if (!_isResubmit && !_validateSelections(t)) return;

    setState(() => _submitting = true);
    try {
      if (_isResubmit) {
        await _subscriptionService.resubmitPayment(
          subscriptionId: widget.resubmitSubscription!.id,
          screenshot: _slip!,
          platformAccountId: _selectedAccountId,
          paidAmount: _amountDue,
          transferRef: _transferRefController.text,
        );
      } else {
        final selectedIds =
            _selectedOptionsByFeature.values.expand((ids) => ids).toList();
        await _subscriptionService.purchase(
          planId: _plan!.id,
          screenshot: _slip!,
          billingPeriod: _billingPeriod,
          platformAccountId: _selectedAccountId,
          paidAmount: _amountDue,
          transferRef: _transferRefController.text,
          selectedOptionIds: selectedIds,
        );
      }
      if (!mounted) return;
      AppDialog.showToast(
        context,
        t?.translate('plans_purchase_submitted') ??
            'Payment submitted for review.',
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      AppDialog.showToast(
        context,
        subscriptionApiErrorMessage(e),
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0B1120) : const Color(0xFFF1F5F9);
    final muted = Theme.of(context).textTheme.bodySmall?.color;
    final title = _isResubmit
        ? (t?.translate('plans_resubmit_payment') ?? 'Resubmit Payment')
        : (t?.translate('plans_subscribe') ?? 'Subscribe');
    final planName = _isResubmit
        ? (widget.resubmitSubscription?.planName ?? '')
        : (_plan?.displayName ?? '');
    final selectedAccount = _selectedAccount;

    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final bottomSafe = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: bg,
      resizeToAvoidBottomInset: true,
      appBar: BackTitleAppBar(title: title),
      body: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        behavior: HitTestBehavior.deferToChild,
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.fromLTRB(
            20,
            12,
            20,
            32 + bottomSafe + bottomInset,
          ),
          children: [
            _sectionCard(
              isDark: isDark,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    planName,
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _amountDue == null
                          ? '—'
                          : '฿${_priceFormat.format(_amountDue)}',
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  Text(
                    _isResubmit
                        ? (widget.resubmitSubscription?.billingPeriod ==
                                'YEARLY'
                            ? (t?.translate('plans_billed_annually') ??
                                'Billed annually')
                            : (t?.translate('plans_monthly') ?? 'Monthly'))
                        : (_annualBilling
                            ? (t?.translate('plans_billed_annually') ??
                                'Billed annually')
                            : (t?.translate('plans_monthly') ?? 'Monthly')),
                    style: GoogleFonts.poppins(fontSize: 13, color: muted),
                  ),
                  if (!_isResubmit && _plan?.hasAnnualPricing == true) ...[
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _toggleChip(
                            isDark: isDark,
                            label: t?.translate('plans_monthly') ?? 'Monthly',
                            selected: !_annualBilling,
                            onTap: () =>
                                setState(() => _annualBilling = false),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _toggleChip(
                            isDark: isDark,
                            label: t?.translate('plans_annually') ?? 'Annually',
                            selected: _annualBilling,
                            onTap: () =>
                                setState(() => _annualBilling = true),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (_isResubmit) ...[
                    Builder(
                      builder: (context) {
                        final fromSub =
                            widget.resubmitSubscription?.rejectReason?.trim();
                        final fromPayment = widget
                            .resubmitSubscription?.latestPayment?.rejectReason
                            ?.trim();
                        final reason = (fromSub != null && fromSub.isNotEmpty)
                            ? fromSub
                            : ((fromPayment != null && fromPayment.isNotEmpty)
                                ? fromPayment
                                : null);
                        if (reason == null) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: AppColors.error.withValues(alpha: 0.25),
                              ),
                            ),
                            child: Text(
                              reason,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                height: 1.35,
                                color: AppColors.error,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
            if (!_isResubmit)
              ...(_plan?.selectableFeatures ?? const []).map((feature) {
                final required = feature.chooseCount ?? 0;
                final selected =
                    _selectedOptionsByFeature[feature.id] ?? <int>{};
                return Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: _sectionCard(
                    isDark: isDark,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          feature.feature?.displayName ?? '',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          (t?.translate('plans_choose_n') ?? 'Choose {count}')
                              .replaceAll('{count}', '$required'),
                          style:
                              GoogleFonts.poppins(fontSize: 12, color: muted),
                        ),
                        const SizedBox(height: 6),
                        ...feature.offeredOptions.map((option) {
                          final checked = selected.contains(option.id);
                          return CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                            controlAffinity: ListTileControlAffinity.leading,
                            value: checked,
                            activeColor: AppColors.primary,
                            checkColor: Colors.white,
                            title: Text(
                              option.displayText,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                height: 1.35,
                              ),
                            ),
                            onChanged: (value) {
                              setState(() {
                                final next = {...selected};
                                if (value == true) {
                                  if (next.length >= required) {
                                    AppDialog.showToast(
                                      context,
                                      (t?.translate('plans_choose_max') ??
                                              'You can choose only {count}.')
                                          .replaceAll('{count}', '$required'),
                                      isError: true,
                                    );
                                    return;
                                  }
                                  next.add(option.id);
                                } else {
                                  next.remove(option.id);
                                }
                                _selectedOptionsByFeature[feature.id] = next;
                              });
                            },
                          );
                        }),
                      ],
                    ),
                  ),
                );
              }),
            const SizedBox(height: 16),
            _sectionCard(
              isDark: isDark,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t?.translate('plans_transfer_to') ?? 'Transfer to',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (_loadingAccounts)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    )
                  else if (_accountsFailed)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          t?.translate('plans_load_failed') ??
                              'Could not load plans',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: muted,
                          ),
                        ),
                        const SizedBox(height: 12),
                        PrimaryGradientButton(
                          height: 44,
                          text: t?.translate('retry') ?? 'Retry',
                          onPressed: _loadAccounts,
                        ),
                      ],
                    )
                  else if (_accounts.isEmpty)
                    Text(
                      t?.translate('plans_no_payment_accounts') ??
                          'No payment accounts available. Contact support.',
                      style: GoogleFonts.poppins(fontSize: 13, color: muted),
                    )
                  else
                    ..._accounts.map((account) {
                      final selected = account.id == _selectedAccountId;
                      final borderColor = selected
                          ? AppColors.primary
                          : (isDark
                              ? Colors.white.withValues(alpha: 0.12)
                              : AppColors.outlineVariant);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Material(
                          color: selected
                              ? AppColors.primary.withValues(alpha: 0.08)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            onTap: () => setState(
                              () => _selectedAccountId = account.id,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: borderColor,
                                  width: selected ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    selected
                                        ? PhosphorIconsFill.checkCircle
                                        : PhosphorIconsRegular.circle,
                                    color: selected
                                        ? AppColors.primary
                                        : AppColors.outline,
                                    size: 22,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          account.methodName.isEmpty
                                              ? account.accountName
                                              : '${account.methodName} · ${account.accountName}',
                                          style: GoogleFonts.poppins(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        SelectableText(
                                          account.accountNumber,
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            color: muted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  if (selectedAccount?.qrUrl != null &&
                      selectedAccount!.qrUrl!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: ColoredBox(
                        color: Colors.white,
                        child: CachedNetworkImage(
                          imageUrl: selectedAccount.qrUrl!,
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.contain,
                          placeholder: (_, _) => const SizedBox(
                            height: 180,
                            child: Center(
                              child: SizedBox(
                                width: 28,
                                height: 28,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                          errorWidget: (_, _, _) => SizedBox(
                            height: 180,
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    PhosphorIconsRegular.qrCode,
                                    size: 36,
                                    color: AppColors.outline,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    t?.translate('plans_load_failed') ??
                                        'Could not load QR',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: AppColors.outline,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                  if (selectedAccount?.note != null &&
                      selectedAccount!.note!.trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      selectedAccount.note!,
                      style: GoogleFonts.poppins(fontSize: 12, color: muted),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            _sectionCard(
              isDark: isDark,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t?.translate('plans_transfer_ref') ?? 'Transfer reference',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _transferRefController,
                    textInputAction: TextInputAction.done,
                    maxLength: 100,
                    scrollPadding: const EdgeInsets.only(bottom: 160),
                    onSubmitted: (_) =>
                        FocusManager.instance.primaryFocus?.unfocus(),
                    style: GoogleFonts.poppins(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: t?.translate('plans_transfer_ref_hint') ??
                          'Optional bank reference',
                      hintStyle: GoogleFonts.poppins(
                        fontSize: 13,
                        color: muted,
                      ),
                      counterText: '',
                      filled: true,
                      fillColor: isDark
                          ? Colors.white.withValues(alpha: 0.04)
                          : AppColors.surfaceVariant,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.1)
                              : AppColors.outlineVariant,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.1)
                              : AppColors.outlineVariant,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColors.primary,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    t?.translate('plans_payment_slip') ?? 'Payment slip',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _pickSlip,
                      borderRadius: BorderRadius.circular(12),
                      child: Ink(
                        height: 168,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _slip == null
                                ? (isDark
                                    ? Colors.white.withValues(alpha: 0.12)
                                    : AppColors.outlineVariant)
                                : AppColors.primary.withValues(alpha: 0.45),
                          ),
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.04)
                              : AppColors.surfaceVariant,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: _slip == null
                              ? Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      PhosphorIconsRegular.image,
                                      size: 32,
                                      color: AppColors.outline,
                                    ),
                                    const SizedBox(height: 8),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                      ),
                                      child: Text(
                                        t?.translate('plans_upload_slip') ??
                                            'Upload payment screenshot',
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          color: AppColors.onSurfaceVariant,
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    FutureBuilder<Uint8List>(
                                      future: _slipBytes,
                                      builder: (context, snapshot) {
                                        if (snapshot.hasError) {
                                          return Center(
                                            child: Text(
                                              t?.translate(
                                                    'plans_load_failed',
                                                  ) ??
                                                  'Could not load image',
                                              style: GoogleFonts.poppins(
                                                fontSize: 12,
                                                color: AppColors.error,
                                              ),
                                            ),
                                          );
                                        }
                                        if (!snapshot.hasData) {
                                          return const Center(
                                            child: SizedBox(
                                              width: 28,
                                              height: 28,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2.5,
                                                color: AppColors.primary,
                                              ),
                                            ),
                                          );
                                        }
                                        return Image.memory(
                                          snapshot.data!,
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                        );
                                      },
                                    ),
                                    Positioned(
                                      left: 0,
                                      right: 0,
                                      bottom: 0,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 8,
                                        ),
                                        color: Colors.black.withValues(
                                          alpha: 0.55,
                                        ),
                                        child: Text(
                                          t?.translate('change_image') ??
                                              'Change Image',
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            PrimaryGradientButton(
              text: _isResubmit
                  ? (t?.translate('plans_resubmit_payment') ??
                      'Resubmit Payment')
                  : (t?.translate('plans_submit_purchase') ??
                      'Submit Payment'),
              isLoading: _submitting,
              onPressed: _submitting ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard({required bool isDark, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : AppColors.outlineVariant,
        ),
      ),
      child: child,
    );
  }

  Widget _toggleChip({
    required bool isDark,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: selected ? AppColors.primaryGradient : null,
            color: selected
                ? null
                : (isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : AppColors.surfaceVariant),
            borderRadius: BorderRadius.circular(12),
            border: selected
                ? null
                : Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : AppColors.outlineVariant,
                  ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 13,
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
