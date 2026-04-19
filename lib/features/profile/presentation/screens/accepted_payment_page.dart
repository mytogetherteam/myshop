import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import '../../data/models/payment_method.dart';
import '../../data/models/shop_model.dart';
import '../../data/services/payment_service.dart';
import '../../../../core/presentation/widgets/skeleton.dart';
import 'edit_payment_page.dart';

class AcceptedPaymentPage extends StatefulWidget {
  final Shop shop;
  const AcceptedPaymentPage({super.key, required this.shop});

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
      final list = await _paymentService.getShopPaymentMethods(widget.shop.id);
      
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Image.network(pm.logoUrl, width: 24, height: 24, errorBuilder: (_, _, _) => const Icon(Icons.payment, size: 24)),
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
            GestureDetector(
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  CupertinoPageRoute(
                    builder: (_) => EditPaymentPage(
                      shopId: widget.shop.id,
                      paymentMethod: pm,
                    ),
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
          ],
        ),
        const SizedBox(height: 16),
        Container(
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
                child: Image.network(
                  pm.qrImageUrl,
                  width: double.infinity,
                  height: 250,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    width: double.infinity,
                    height: 250,
                    color: Colors.grey[50],
                    child: const Icon(Icons.qr_code, size: 48, color: Colors.grey),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(PhosphorIconsRegular.user, size: 16, color: Color(0xFF64748B)),
                  const SizedBox(width: 8),
                  Text(
                    'Name: ',
                    style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF64748B)),
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
                  const Icon(PhosphorIconsRegular.hash, size: 16, color: Color(0xFF64748B)),
                  const SizedBox(width: 8),
                  Text(
                    'No: ',
                    style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF64748B)),
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
                    pm.isActive ? PhosphorIconsRegular.checkCircle : PhosphorIconsRegular.xCircle,
                    size: 16,
                    color: pm.isActive ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    pm.isActive ? 'Active' : 'Inactive',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: pm.isActive ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
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
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
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
