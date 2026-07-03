import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/cupertino.dart';
import '../../data/models/payment_method.dart';
import '../../data/services/payment_service.dart';
import '../../../../core/presentation/widgets/skeleton.dart';
import '../../../../core/presentation/widgets/custom_loading_indicator.dart';
import '../../../../core/presentation/widgets/global_modal.dart';

import '../widgets/password_confirmation_sheet.dart';
import '../../../../core/presentation/widgets/app_dialog.dart';
import 'package:my_shop/core/presentation/widgets/back_title_app_bar.dart';
import 'package:my_shop/core/utils/app_colors.dart';
import 'package:my_shop/core/localization/app_localizations.dart';

import 'edit_payment_page.dart';

class AcceptedPaymentPage extends StatefulWidget {
  const AcceptedPaymentPage({super.key});

  @override
  State<AcceptedPaymentPage> createState() => AcceptedPaymentPageState();
}

class AcceptedPaymentPageState extends State<AcceptedPaymentPage> {
  final PaymentService _paymentService = PaymentService();
  List<PaymentMethod> _paymentMethods = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPaymentMethods();
  }

  Future<void> refresh() async {
    await _loadPaymentMethods(forceRefresh: true);
  }

  Future<void> _loadPaymentMethods({bool forceRefresh = false}) async {
    setState(() => _isLoading = true);
    try {
      final list = await _paymentService.getShopPaymentMethods(
        forceRefresh: forceRefresh,
      );

      if (mounted) {
        setState(() {
          _paymentMethods = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _paymentMethods = [];
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleRefresh() async {
    await _loadPaymentMethods(forceRefresh: true);
  }

  Future<void> _handleDelete(PaymentMethod pm) async {
    final t = AppLocalizations.of(context);
    final confirmed = await AppDialog.showConfirm(
      context,
      title: t?.translate('delete_payment_method') ?? 'Delete Payment Method',
      message: t
              ?.translate('delete_payment_confirm')
              .replaceAll('{name}', pm.paymentMethodName) ??
          'Are you sure you want to delete "${pm.paymentMethodName}"? This action cannot be undone.',
      confirmLabel: t?.translate('delete') ?? 'Delete',
      cancelLabel: t?.translate('cancel') ?? 'Cancel',
    );

    if (!confirmed || !mounted) return;

    GlobalModal.show(
      context: context,
      child: PasswordConfirmationSheet(
        onConfirm: (password) {
          Navigator.pop(context); // Close the sheet
          _performDelete(pm);
        },
      ),
    );
  }

  Future<void> _performDelete(PaymentMethod pm) async {
    final t = AppLocalizations.of(context);
    // Show loading overlay
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(child: CustomLoadingIndicator(size: 40)),
    );

    final result = await _paymentService.deletePaymentMethod(pm.id);

    if (!mounted) return;
    Navigator.pop(context); // Remove loading overlay

    if (result['success'] == true) {
      AppDialog.showToast(context, result['message'] ?? (t?.translate('payment_deleted_success') ?? 'Payment Method Deleted Successfully'));
      _loadPaymentMethods();
    } else {
      AppDialog.showToast(context, result['message'] ?? (t?.translate('failed_delete_payment') ?? 'Failed to Delete Payment Method'), isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      
      appBar: BackTitleAppBar(
        title: t?.translate('accepted_payment') ?? 'Accepted payment',
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_isLoading)
                _buildSkeleton()
              else if (_paymentMethods.isEmpty)
                _buildEmptyState()
              else
                _buildPaymentList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentList() {
    return Column(
      children: [
        for (int i = 0; i < _paymentMethods.length; i++) ...[
          _buildPaymentItem(_paymentMethods[i]),
          if (i < _paymentMethods.length - 1) SizedBox(height: 16),
        ],
      ],
    );
  }

  Widget _buildPaymentItem(PaymentMethod pm) {
    final t = AppLocalizations.of(context);
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          CupertinoPageRoute(
            builder: (_) => EditPaymentPage(paymentMethod: pm),
          ),
        );
        if (result == true) _loadPaymentMethods(forceRefresh: true);
      },
      child: Container(
        color: Colors.transparent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildPaymentIcon(pm),
                SizedBox(width: 12),
                Text(
                  pm.paymentMethodName,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                const Spacer(),
                if (_paymentMethods.length > 1) ...[
                  SizedBox(width: 16),
                  GestureDetector(
                    onTap: () => _handleDelete(pm),
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Icon(
                        PhosphorIconsRegular.trash,
                        size: 20,
                        color: Color(0xFFEF4444),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).dividerColor.withOpacity(0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: pm.qrImageUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: pm.fullQrImageUrl,
                        width: double.infinity,
                        height: 250,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => _buildQrPlaceholder(),
                        errorWidget: (context, url, error) => _buildQrPlaceholder(),
                      )
                    : _buildQrPlaceholder(),
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Icon(
                    PhosphorIconsRegular.user,
                    size: 16,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                  SizedBox(width: 8),
                  Text(
                    t?.translate('name_label') ?? 'Name: ',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                  Text(
                    pm.accountName,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    PhosphorIconsRegular.hash,
                    size: 16,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                  SizedBox(width: 8),
                  Text(
                    t?.translate('no_label') ?? 'No: ',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                  Text(
                    pm.accountNumber,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    pm.isActive
                        ? PhosphorIconsRegular.checkCircle
                        : PhosphorIconsRegular.xCircle,
                    size: 16,
                    color: pm.isActive
                        ? const Color(0xFF22C55E)
                        : const Color(0xFFEF4444),
                  ),
                  SizedBox(width: 8),
                  Text(
                    pm.isActive ? (t?.translate('active') ?? 'Active') : (t?.translate('inactive') ?? 'Inactive'),
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: pm.isActive
                          ? const Color(0xFF22C55E)
                          : const Color(0xFFEF4444),
                    ),
                  ),
                ],
              ),
            ],
          ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentIcon(PaymentMethod pm) {
    if (pm.fullPaymentMethodIconUrl.isNotEmpty) {
      return Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
        ),
        clipBehavior: Clip.antiAlias,
        child: CachedNetworkImage(
          imageUrl: pm.fullPaymentMethodIconUrl,
          fit: BoxFit.cover,
          placeholder: (context, url) => _buildFallbackIcon(pm),
          errorWidget: (context, url, error) => _buildFallbackIcon(pm),
        ),
      );
    }
    return _buildFallbackIcon(pm);
  }

  Widget _buildFallbackIcon(PaymentMethod pm) {
    // Use payment method code to show an appropriate icon
    final code = pm.paymentMethodCode.toUpperCase();
    IconData iconData;
    if (code.contains('PROMPT') || code.contains('QR')) {
      iconData = PhosphorIconsRegular.qrCode;
    } else if (code.contains('BANK') || code.contains('TRANSFER')) {
      iconData = PhosphorIconsRegular.bank;
    } else if (code.contains('WALLET') || code.contains('MONEY')) {
      iconData = PhosphorIconsRegular.wallet;
    } else if (code.contains('CARD') ||
        code.contains('CREDIT') ||
        code.contains('DEBIT')) {
      iconData = PhosphorIconsRegular.creditCard;
    } else {
      iconData = PhosphorIconsRegular.currencyCircleDollar;
    }

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: Theme.of(context).dividerColor.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(iconData, size: 18, color: const Color(0xFF475569)),
    );
  }

  Widget _buildQrPlaceholder() {
    return Container(
      width: double.infinity,
      height: 250,
      color: Colors.grey[50],
      child: Icon(Icons.qr_code, size: 48, color: Colors.grey),
    );
  }

  Widget _buildEmptyState() {
    final t = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: 100),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).dividerColor.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.credit_card_off_rounded,
              size: 64,
              color: (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
            ),
          ),
          SizedBox(height: 24),
          Text(
            t?.translate('no_payment_methods') ?? 'No Payment Methods Yet',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          SizedBox(height: 8),
          Text(
            t?.translate('add_payment_methods_desc') ?? 'Add your payment methods to start receiving payments.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeleton() {
    return Column(
      children: [
        for (int i = 0; i < 2; i++) ...[
          Row(
            children: [
              Skeleton(width: 24, height: 24, borderRadius: 6),
              SizedBox(width: 12),
              Skeleton(width: 120, height: 18),
            ],
          ),
          SizedBox(height: 16),
          const Skeleton(width: double.infinity, height: 250, borderRadius: 12),
          if (i == 0) SizedBox(height: 32),
        ],
      ],
    );
  }
}