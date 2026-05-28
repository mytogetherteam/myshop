import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:flutter/cupertino.dart';
import 'package:my_shop/core/localization/app_localizations.dart';
import '../../data/models/shop_model.dart';
import '../../data/services/shop_service.dart';
import 'accepted_payment_page.dart';
import 'package:my_shop/core/presentation/widgets/back_title_app_bar.dart';
import 'package:my_shop/core/presentation/widgets/empty_state.dart';
import 'package:my_shop/core/presentation/widgets/error_retry_state.dart';
import 'package:my_shop/core/presentation/widgets/skeleton.dart';
import 'package:my_shop/core/presentation/widgets/skeleton_list.dart';
import 'package:my_shop/core/utils/app_colors.dart';

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
    final t = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: BackTitleAppBar(title: t?.translate('choose_shop') ?? 'Choose Shop'),
      body: RefreshIndicator(
        onRefresh: _loadShops,
        color: AppColors.primary,
        child: _isLoading
            ? SkeletonList(
                itemCount: 5,
                padding: const EdgeInsets.all(24),
                separatorHeight: 16,
                itemBuilder: (_, _) => _buildShopSkeletonCard(),
              )
            : _error != null
                ? ErrorRetryState(
                    message: _error!,
                    onRetry: _loadShops,
                    scrollable: true,
                  )
                : _shops.isEmpty
                    ? EmptyState(
                        icon: Icon(
                          PhosphorIconsRegular.storefront,
                          size: 64,
                          color: AppColors.iconDisabled,
                        ),
                        title: 'No shops found',
                      )
                    : _buildShopList(),
      ),
    );
  }

  Widget _buildShopList() {
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      itemCount: _shops.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) => _buildShopCard(_shops[index]),
    );
  }

  Widget _buildShopSkeletonCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        children: [
          const Skeleton(width: 60, height: 60, borderRadius: 12),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Skeleton(height: 14, width: 160),
                SizedBox(height: 8),
                Skeleton(height: 12, width: 200),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const Skeleton(width: 20, height: 20, borderRadius: 4),
        ],
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

}
