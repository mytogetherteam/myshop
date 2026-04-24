import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/cupertino.dart';
import '../../data/models/payment_method.dart';
import '../../data/services/payment_service.dart';
import '../../../../core/presentation/widgets/skeleton.dart';
import '../../../../core/presentation/widgets/custom_loading_indicator.dart';
import '../../../../core/presentation/widgets/global_modal.dart';
import '../widgets/password_confirmation_sheet.dart';
import 'edit_payment_page.dart';

class AcceptedPaymentPage extends StatefulWidget {
  const AcceptedPaymentPage({super.key});

  @override
  State<AcceptedPaymentPage> createState() => _AcceptedPaymentPageState();
}

class _AcceptedPaymentPageState extends State<AcceptedPaymentPage> {
  final PaymentService _paymentService = PaymentService();
  List<PaymentMethod> _paymentMethods = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPaymentMethods();
  }

  Future<void> _loadPaymentMethods() async {
    setState(() => _isLoading = true);
    try {
      final list = await _paymentService.getShopPaymentMethods();

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
    await _loadPaymentMethods();
  }

  Future<void> _handleDelete(PaymentMethod pm) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete Payment Method',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 17),
        ),
        content: Text(
          'Are you sure you want to delete "${pm.paymentMethodName}"? This action cannot be undone.',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: const Color(0xFF475569),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: const Color(0xFF64748B)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Delete',
              style: GoogleFonts.poppins(
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

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
    // Show loading overlay
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CustomLoadingIndicator(size: 40)),
    );

    final result = await _paymentService.deletePaymentMethod(pm.id);

    if (!mounted) return;
    Navigator.pop(context); // Remove loading overlay

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result['message'] ?? 'Payment method deleted successfully',
          ),
          backgroundColor: Colors.green,
        ),
      );
      _loadPaymentMethods();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Failed to delete payment method'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Accepted payment',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: const Color(0xFFED3973),
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
          if (i < _paymentMethods.length - 1) const SizedBox(height: 16),
        ],
      ],
    );
  }

  Widget _buildPaymentItem(PaymentMethod pm) {
    final bool isPending = pm.status == 'PENDING';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildPaymentIcon(pm),
            const SizedBox(width: 12),
            Text(
              pm.paymentMethodName,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1E293B),
              ),
            ),
            const Spacer(),
            if (!isPending) ...[
              GestureDetector(
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    CupertinoPageRoute(
                      builder: (_) => EditPaymentPage(paymentMethod: pm),
                    ),
                  );
                  if (result == true) _loadPaymentMethods();
                },
                child: Text(
                  'Edit',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFED3973),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: () => _handleDelete(pm),
                child: const Icon(
                  PhosphorIconsRegular.trash,
                  size: 20,
                  color: Color(0xFFEF4444),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 16),
        Stack(
          children: [
            Opacity(
              opacity: isPending ? 0.4 : 1.0,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFF1F5F9)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: pm.qrImageUrl.isNotEmpty
                          ? Image.network(
                              pm.qrImageUrl,
                              width: double.infinity,
                              height: 250,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stack) =>
                                  _buildQrPlaceholder(),
                            )
                          : _buildQrPlaceholder(),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(
                          PhosphorIconsRegular.user,
                          size: 16,
                          color: Color(0xFF64748B),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Name: ',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                        Text(
                          pm.accountName,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          PhosphorIconsRegular.hash,
                          size: 16,
                          color: Color(0xFF64748B),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'No: ',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                        Text(
                          pm.accountNumber,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
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
                        const SizedBox(width: 8),
                        Text(
                          pm.isActive ? 'Active' : 'Inactive',
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
            ),
            if (isPending)
              Positioned.fill(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFEF4444),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 32,
                            height: 2,
                            color: const Color(
                              0xFFEF4444,
                            ).withValues(alpha: 0.3),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Checking for security reasons, this payment method will be available shortly.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFEF4444),
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: 32,
                            height: 2,
                            color: const Color(
                              0xFFEF4444,
                            ).withValues(alpha: 0.3),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildPaymentIcon(PaymentMethod pm) {
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
        color: const Color(0xFFF1F5F9),
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
      child: const Icon(Icons.qr_code, size: 48, color: Colors.grey),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 100),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.credit_card_off_rounded,
              size: 64,
              color: Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No payment methods yet',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your payment methods to start receiving payments.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: const Color(0xFF64748B),
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
          const Row(
            children: [
              Skeleton(width: 24, height: 24, borderRadius: 6),
              SizedBox(width: 12),
              Skeleton(width: 120, height: 18),
            ],
          ),
          const SizedBox(height: 16),
          const Skeleton(width: double.infinity, height: 250, borderRadius: 12),
          if (i == 0) const SizedBox(height: 32),
        ],
      ],
    );
  }
}
