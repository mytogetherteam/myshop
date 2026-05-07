import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter/cupertino.dart';
import '../../data/models/shop_model.dart';
import '../../data/services/shop_service.dart';
import 'accepted_payment_page.dart';
import '../../../../core/presentation/widgets/custom_loading_indicator.dart';
import 'package:my_shop/core/presentation/widgets/primary_gradient_button.dart';

class ShopSelectionPage extends StatefulWidget {
  const ShopSelectionPage({super.key});

  @override
  State<ShopSelectionPage> createState() => _ShopSelectionPageState();
}

class _ShopSelectionPageState extends State<ShopSelectionPage> {
  final ShopService _shopService = ShopService();
  List<Shop> _shops = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadShops();
  }

  Future<void> _loadShops() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final shops = await _shopService.getShops();

      if (!mounted) return;

      if (shops.length == 1) {
        // Auto-skip logic
        Navigator.pushReplacement(
          context,
          CupertinoPageRoute(builder: (_) => const AcceptedPaymentPage()),
        );
      } else {
        setState(() {
          _shops = shops;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Failed to load shops. Please try again.';
        });
      }
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
          'Choose Shop',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CustomLoadingIndicator())
          : _error != null
          ? _buildErrorState()
          : _shops.isEmpty
          ? _buildEmptyState()
          : _buildShopList(),
    );
  }

  Widget _buildShopList() {
    return RefreshIndicator(
      onRefresh: _loadShops,
      color: const Color(0xFFED3973),
      child: ListView.separated(
        padding: const EdgeInsets.all(24),
        itemCount: _shops.length,
        separatorBuilder: (context, index) => const SizedBox(height: 16),
        itemBuilder: (context, index) => _buildShopCard(_shops[index]),
      ),
    );
  }

  Widget _buildShopCard(Shop shop) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          CupertinoPageRoute(builder: (_) => const AcceptedPaymentPage()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF1F5F9)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: shop.logoUrl != null
                    ? Image.network(
                        shop.logoUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stack) => const Icon(
                          PhosphorIconsRegular.storefront,
                          color: Color(0xFF64748B),
                        ),
                      )
                    : const Icon(
                        PhosphorIconsRegular.storefront,
                        color: Color(0xFF64748B),
                      ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    shop.name,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  if (shop.address != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      shop.address!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(
              PhosphorIconsRegular.caretRight,
              color: Color(0xFF94A3B8),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            PhosphorIconsRegular.storefront,
            size: 64,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'No shops found',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Color(0xFFEF4444)),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: const Color(0xFF1E293B)),
            ),
            const SizedBox(height: 24),
            PrimaryGradientButton(
              onPressed: _loadShops,
              text: 'Retry',
              height: 48,
              borderRadius: 12,
            ),
          ],
        ),
      ),
    );
  }
}
