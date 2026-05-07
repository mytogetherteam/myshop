import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:my_shop/core/data/services/storage_service.dart';
import '../../data/models/shop_model.dart';
import '../../data/services/shop_service.dart';
import '../../../../core/presentation/widgets/custom_loading_indicator.dart';
import 'package:my_shop/core/presentation/widgets/primary_gradient_button.dart';
import 'package:my_shop/features/categories/data/services/category_service.dart';
import 'package:my_shop/features/menu/data/services/menu_service.dart';

class GlobalShopSelectionPage extends StatefulWidget {
  final bool isInitialFlow;

  const GlobalShopSelectionPage({super.key, this.isInitialFlow = false});

  @override
  State<GlobalShopSelectionPage> createState() =>
      _GlobalShopSelectionPageState();
}

class _GlobalShopSelectionPageState extends State<GlobalShopSelectionPage> {
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

      if (shops.isEmpty) {
        if (widget.isInitialFlow) {
          Navigator.of(context).pushReplacementNamed('/home');
        } else {
          setState(() {
            _shops = [];
            _isLoading = false;
          });
        }
      } else if (shops.length == 1) {
        if (widget.isInitialFlow) {
          await StorageService.instance.saveSelectedShopId(shops[0].id);
          if (!mounted) return;
          Navigator.of(context).pushReplacementNamed('/home');
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Only one shop available: ${shops[0].name}',
                style: GoogleFonts.poppins(),
              ),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.of(context).pop();
        }
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

  Future<void> _selectShop(Shop shop) async {
    await StorageService.instance.saveSelectedShopId(shop.id);
    CategoryService.clearCache();
    MenuService.clearCache();
    if (!mounted) return;

    if (widget.isInitialFlow) {
      Navigator.of(context).pushReplacementNamed('/home');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Switched to ${shop.name}',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: widget.isInitialFlow
            ? null
            : IconButton(
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
        centerTitle: widget.isInitialFlow,
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
    return FutureBuilder<int?>(
      future: StorageService.instance.getSelectedShopId(),
      builder: (context, snapshot) {
        final isSelected = !widget.isInitialFlow && snapshot.data == shop.id;

        return GestureDetector(
          onTap: () => _selectShop(shop),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFFED3973).withValues(alpha: 0.05)
                  : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFFED3973)
                    : const Color(0xFFF1F5F9),
                width: isSelected ? 2 : 1,
              ),
              boxShadow: [
                if (!isSelected)
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
                Icon(
                  isSelected
                      ? PhosphorIconsFill.checkCircle
                      : PhosphorIconsRegular.caretRight,
                  color: isSelected
                      ? const Color(0xFFED3973)
                      : const Color(0xFF94A3B8),
                  size: 24,
                ),
              ],
            ),
          ),
        );
      },
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
