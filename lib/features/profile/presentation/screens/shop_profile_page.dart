import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:my_shop/features/profile/data/models/shop_profile_model.dart';
import 'package:my_shop/features/profile/data/services/profile_service.dart';
import 'package:my_shop/features/profile/presentation/screens/edit_shop_profile_page.dart';
import 'package:my_shop/features/profile/presentation/screens/operating_hours_page.dart';
import 'package:my_shop/core/presentation/widgets/skeleton.dart';
import 'package:my_shop/features/categories/data/services/category_service.dart';
import 'package:flutter/foundation.dart';
import 'package:cached_network_image/cached_network_image.dart';

// ---------------------------------------------------------------------------
// Demo data models
// ---------------------------------------------------------------------------
class _MenuItem {
  final String name;
  final double price;
  final String imageUrl;
  final bool isHot;
  final bool isPopular;
  final bool isVeg;
  final bool isSpicy;
  const _MenuItem({
    required this.name,
    required this.price,
    required this.imageUrl,
    this.isHot = false,
    this.isPopular = false,
    this.isVeg = false,
    this.isSpicy = false,
  });
}

class _Review {
  final String reviewer;
  final double rating;
  final String date;
  final String comment;
  final List<String> tags;
  const _Review({
    required this.reviewer,
    required this.rating,
    required this.date,
    required this.comment,
    this.tags = const [],
  });
}

// ---------------------------------------------------------------------------
// ShopProfilePage
// ---------------------------------------------------------------------------
class ShopProfilePage extends StatefulWidget {
  const ShopProfilePage({super.key});

  @override
  State<ShopProfilePage> createState() => _ShopProfilePageState();
}

class _ShopProfilePageState extends State<ShopProfilePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late ScrollController _scrollController;
  int _selectedCategory = 0;
  bool _isScrolled = false;

  // ---- CHANGE 1: hero height constant used everywhere ----
  static const double _heroHeight = 280.0;
  static const double _cardTopBase = 245.0; // heroHeight - 35

  final List<String> _categories = ['All'];
  final CategoryService _categoryService = CategoryService();

  final List<_MenuItem> _menuItems = const [
    _MenuItem(
      name: 'Shan Noodles',
      price: 4500,
      imageUrl:
          'https://delishglobe.com/wp-content/uploads/2025/02/Shan-Noodles.png',
      isPopular: true,
    ),
    _MenuItem(
      name: 'Mohinga',
      price: 3500,
      imageUrl:
          'https://asianinspirations.com.au/wp-content/uploads/2023/03/MHG-6.jpg',
      isHot: true,
      isSpicy: true,
    ),
    _MenuItem(
      name: 'Tofu Kyaw',
      price: 3000,
      imageUrl:
          'https://www.cookeatworld.com/wp-content/uploads/2019/11/Burmese-Chicken-10.jpg',
      isVeg: true,
    ),
    _MenuItem(
      name: 'Shan Rice',
      price: 5000,
      imageUrl:
          'https://upload.wikimedia.org/wikipedia/commons/thumb/7/7d/Shan_rice.jpg/320px-Shan_rice.jpg',
      isPopular: true,
    ),
    _MenuItem(
      name: 'Laphet Yay',
      price: 1500,
      imageUrl:
          'https://upload.wikimedia.org/wikipedia/commons/thumb/4/45/A_small_cup_of_coffee.JPG/320px-A_small_cup_of_coffee.JPG',
    ),
  ];

  final List<_Review> _reviews = const [
    _Review(
      reviewer: 'Aung Kyaw',
      rating: 5,
      date: 'Mar 10, 2026',
      comment: 'The food is absolutely amazing! Shan noodles are my favourite.',
      tags: ['Great food', 'Fast delivery'],
    ),
    _Review(
      reviewer: 'Phyu Phyu',
      rating: 4,
      date: 'Mar 8, 2026',
      comment: 'Very tasty and affordable. The mohinga is just like home.',
      tags: ['Authentic', 'Affordable'],
    ),
    _Review(
      reviewer: 'Kyaw Zin',
      rating: 4,
      date: 'Mar 5, 2026',
      comment: 'Good portion sizes and freshly cooked.',
      tags: ['Fresh', 'Good value'],
    ),
  ];

  final ProfileService _profileService = ProfileService();
  ShopProfileModel? _shopProfile;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    _loadProfile();
  }

  void _onScroll() {
    if (_scrollController.offset > 50 && !_isScrolled) {
      setState(() => _isScrolled = true);
    } else if (_scrollController.offset <= 50 && _isScrolled) {
      setState(() => _isScrolled = false);
    }
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final profile = await _profileService.getShopProfile();
    final categories = await _categoryService.getCategories();

    if (mounted) {
      if (profile != null) {
        setState(() {
          _shopProfile = profile;
          if (categories != null && categories.isNotEmpty) {
            _categories.clear();
            _categories.add('All');
            _categories.addAll(categories.map((c) => c.displayName));
          }
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load shop profile. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildSkeletonProfile();
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const PhosphorIcon(
                PhosphorIconsRegular.warningCircle,
                size: 48,
                color: Color(0xFFED3973),
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: GoogleFonts.poppins(color: const Color(0xFF475569)),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFED3973),
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          // ── Main scrollable content ──────────────────────────────────────
          NestedScrollView(
              controller: _scrollController,
              headerSliverBuilder: (context, _) => [
                SliverToBoxAdapter(child: _buildHero()),
                SliverToBoxAdapter(
                  child: Transform.translate(
                    offset: const Offset(0, -32),
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(32),
                        ),
                      ),
                      child: Column(
                        children: [
                          const SizedBox(height: 100), // Space for floating card
                          _buildInfoSection(),
                        ],
                      ),
                    ),
                  ),
                ),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _TabHeaderDelegate(
                    TabBar(
                      controller: _tabController,
                      labelColor: const Color(0xFFED3973),
                      unselectedLabelColor: const Color(0xFF64748B),
                      indicatorColor: const Color(0xFFED3973),
                      indicatorWeight: 2,
                      labelStyle: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      unselectedLabelStyle: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                      tabs: const [
                        Tab(text: 'Menu'),
                        Tab(text: 'Reviews'),
                        Tab(text: 'Info'),
                        Tab(text: 'Photos'),
                      ],
                    ),
                  ),
                ),
              ],
              body: TabBarView(
                controller: _tabController,
                children: [
                  _buildMenuTab(),
                  _buildReviewsTab(),
                  _buildInfoTab(),
                  _buildPhotosTab(),
                ],
            ),
          ),

          // ── CHANGE 2: Floating Info Card ─────────────────────────────────
          AnimatedBuilder(
            animation: _scrollController,
            builder: (context, child) {
              double scrollOffset = 0;
              if (_scrollController.hasClients) {
                scrollOffset = _scrollController.offset;
              }

              // Card sits just below the hero image bottom edge
              double cardTop = _cardTopBase - scrollOffset;

              // Fade out as user scrolls up
              double opacity = 1.0;
              if (scrollOffset > 50) {
                opacity = (1.0 - (scrollOffset - 50) / 200).clamp(0.0, 1.0);
              }

              if (opacity <= 0) return const SizedBox.shrink();

              return Positioned(
                top: cardTop,
                left: 16,
                right: 16,
                child: Opacity(
                  opacity: opacity,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Logo
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: (_shopProfile?.logoUrl ?? '').isNotEmpty
                                ? _buildImage(_shopProfile!.logoUrl!,
                                    fit: BoxFit.cover,
                                    fallback: _buildLogoFallback(
                                      _shopProfile?.nameEn ?? '',
                                    ))
                                : _buildLogoFallback(
                                    _shopProfile?.nameEn ?? '',
                                  ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Name + category
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      _shopProfile?.nameEn ?? '',
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (_shopProfile?.isVerified == true) ...[
                                    const SizedBox(width: 4),
                                    const PhosphorIcon(
                                      PhosphorIconsFill.sealCheck,
                                      size: 16,
                                      color: Color(0xFF38BDF8),
                                    ),
                                  ],
                                ],
                              ),
                              if ((_shopProfile?.categoryEn ?? '').isNotEmpty)
                                Text(
                                  '${_shopProfile?.categoryEn}${(_shopProfile?.subCategoryEn ?? '').isNotEmpty ? ' • ${_shopProfile?.subCategoryEn}' : ''}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

          // ── App Bar ──────────────────────────────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
              height: kToolbarHeight + MediaQuery.of(context).padding.top,
              decoration: BoxDecoration(
                color: _isScrolled ? Colors.white : Colors.transparent,
                border: Border(
                  bottom: BorderSide(
                    color: _isScrolled
                        ? Colors.black.withValues(alpha: 0.05)
                        : Colors.transparent,
                    width: 1,
                  ),
                ),
              ),
              child: Stack(
                children: [
                  // Back arrow (left)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: _buildCircleIconButton(
                        icon: PhosphorIconsRegular.arrowLeft,
                        onPressed: () => Navigator.pop(context),
                        isScrolled: _isScrolled,
                      ),
                    ),
                  ),
                  // Shop name (center, visible only when scrolled)
                  Align(
                    alignment: Alignment.center,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 300),
                      opacity: _isScrolled ? 1.0 : 0.0,
                      child: Text(
                        _shopProfile?.nameEn ?? '',
                        style: GoogleFonts.poppins(
                          color: Colors.black,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  // NO share icon, NO heart icon
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── CHANGE 3: Hero Section ───────────────────────────────────────────────
  Widget _buildHero() {
    return Container(
      height: _heroHeight,
      width: double.infinity,
      clipBehavior: Clip.hardEdge,
      decoration: const BoxDecoration(color: Colors.white),
      child: Stack(
        children: [
          // Gradient as base / fallback (always visible)
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFED3973), Color(0xFFE8895A)],
                ),
              ),
            ),
          ),
          // Cover image (overlays gradient when available)
          if (_shopProfile?.coverUrl != null &&
              _shopProfile!.coverUrl!.isNotEmpty)
            Positioned.fill(
              child: _buildImage(_shopProfile!.coverUrl!, fit: BoxFit.cover, fallback: const SizedBox.shrink()),
            ),
          // Dark gradient overlay for contrast
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.3),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.35),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Info Section (below hero)
  // -------------------------------------------------------------------------
  Widget _buildInfoSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Restaurant Details',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E293B),
                ),
              ),
              _buildOpenStatusBadge(),
            ],
          ),
          const SizedBox(height: 12),

          // Rating
          Row(
            children: [
              const PhosphorIcon(
                PhosphorIconsFill.star,
                size: 16,
                color: Color(0xFFF59E0B),
              ),
              const SizedBox(width: 4),
              Text(
                '${_shopProfile?.ratingAvg ?? 0.0}',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '(${_shopProfile?.ratingCount ?? 0} reviews)',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: const Color(0xFF94A3B8),
                ),
              ),
              if ((_shopProfile?.viewCount ?? 0) > 0) ...[
                const SizedBox(width: 8),
                const PhosphorIcon(PhosphorIconsRegular.eye, size: 14, color: Color(0xFF94A3B8)),
                const SizedBox(width: 4),
                Text(
                  '${_shopProfile?.viewCount}',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),

          // Amenity chips
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              if (_shopProfile?.hasParking == true)
                _amenityChip(PhosphorIconsRegular.car, 'Parking'),
              if (_shopProfile?.hasWifi == true)
                _amenityChip(PhosphorIconsRegular.wifiHigh, 'WiFi'),
              if (_shopProfile?.hasDelivery == true)
                _amenityChip(PhosphorIconsRegular.motorcycle, 'Delivery'),
              if (_shopProfile?.isHalal == true)
                _amenityChip(PhosphorIconsRegular.moon, 'Halal'),
              if (_shopProfile?.isVegetarian == true)
                _amenityChip(PhosphorIconsRegular.leaf, 'Vegetarian'),
            ],
          ),
          const SizedBox(height: 12),

          // Delivery info row
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                _infoStat(
                  PhosphorIconsRegular.tag,
                  _shopProfile?.displayBaseDeliveryFee ?? '฿${_shopProfile?.baseDeliveryFee ?? 0}',
                  'Delivery fee',
                ),
                _infoStatDivider(),
                _infoStat(
                  PhosphorIconsRegular.clock,
                  _shopProfile?.estimatedTime ?? '25-35 min',
                  'Est. time',
                ),
                _infoStatDivider(),
                _infoStat(
                  PhosphorIconsRegular.shoppingCart,
                  _shopProfile?.displayMinOrderAmount ?? '฿${_shopProfile?.minOrderAmount ?? 0}',
                  'Min. order',
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            OperatingHoursPage(shopProfile: _shopProfile),
                      ),
                    ).then((_) => _loadProfile());
                  },
                  icon: const PhosphorIcon(
                    PhosphorIconsRegular.clock,
                    size: 18,
                    color: Colors.white,
                  ),
                  label: Text(
                    'Operating Hours',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFED3973),
                    overlayColor: Colors.white.withValues(alpha: 0.12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 8,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            EditShopProfilePage(shopProfile: _shopProfile),
                      ),
                    ).then((_) => _loadProfile());
                  },
                  icon: const PhosphorIcon(
                    PhosphorIconsRegular.pencilSimple,
                    size: 18,
                    color: Color(0xFF475569),
                  ),
                  label: Text(
                    'Edit Profile',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: const Color(0xFF475569),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                    overlayColor: const Color(0xFF1E293B).withValues(alpha: 0.04),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 8,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                const PhosphorIcon(
                  PhosphorIconsRegular.phone,
                  size: 18,
                  color: Color(0xFF475569),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _shopProfile?.phone ?? 'No phone added',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      Text(
                        'This is the phone number currently shown to customers on your public profile.',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOpenStatusBadge() {
    final isOpen = _shopProfile?.isOpen ?? true;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isOpen ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isOpen ? 'OPEN' : 'CLOSED',
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: isOpen ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
        ),
      ),
    );
  }

  Widget _amenityChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PhosphorIcon(icon, size: 13, color: const Color(0xFF64748B)),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF475569),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoStat(IconData icon, String value, String label) {
    return Expanded(
      child: Column(
        children: [
          PhosphorIcon(icon, size: 18, color: const Color(0xFFED3973)),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E293B),
            ),
          ),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoStatDivider() {
    return Container(width: 1, height: 24, color: const Color(0xFFE2E8F0));
  }

  Widget _buildLogoFallback(String name) {
    return Container(
      color: const Color(0xFFED3973).withValues(alpha: 0.1),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : 'B',
          style: GoogleFonts.poppins(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: const Color(0xFFED3973),
          ),
        ),
      ),
    );
  }

  Widget _buildCircleIconButton({
    required IconData icon,
    required VoidCallback onPressed,
    required bool isScrolled,
    Color? iconColorOverride,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isScrolled
            ? Colors.black.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.2),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: PhosphorIcon(
          icon,
          color:
              iconColorOverride ?? (isScrolled ? Colors.black : Colors.white),
          size: 20,
        ),
        onPressed: onPressed,
        constraints: const BoxConstraints(),
        padding: const EdgeInsets.all(8),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Menu Tab
  // -------------------------------------------------------------------------
  Widget _buildMenuTab() {
    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        SizedBox(
          height: 44,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            itemCount: _categories.length,
            itemBuilder: (_, i) {
              final selected = _selectedCategory == i;
              return GestureDetector(
                onTap: () => setState(() => _selectedCategory = i),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: selected ? const Color(0xFFED3973) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected
                          ? const Color(0xFFED3973)
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Text(
                    _categories[i],
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: selected ? Colors.white : const Color(0xFF475569),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Text(
            'Rice & Noodles',
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E293B),
            ),
          ),
        ),
        ..._menuItems.map((item) => _buildMenuItemCard(item)),
      ],
    );
  }

  Widget _buildMenuItemCard(_MenuItem item) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(
              left: Radius.circular(12),
            ),
            child: Image.network(
              item.imageUrl,
              width: 90,
              height: 80,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                width: 90,
                height: 80,
                color: const Color(0xFFE2E8F0),
                child: const PhosphorIcon(
                  PhosphorIconsRegular.forkKnife,
                  size: 28,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 4,
                    children: [
                      if (item.isHot)
                        _badge(
                          '🔥 Hot Deal',
                          const Color(0xFFFFF3CD),
                          const Color(0xFF92400E),
                        ),
                      if (item.isPopular)
                        _badge(
                          '⭐ Popular',
                          const Color(0xFFE0F2FE),
                          const Color(0xFF0369A1),
                        ),
                      if (item.isVeg)
                        _badge(
                          '🌿 Veg',
                          const Color(0xFFDCFCE7),
                          const Color(0xFF166534),
                        ),
                      if (item.isSpicy)
                        _badge(
                          '🌶 Spicy',
                          const Color(0xFFFFE4E6),
                          const Color(0xFF9F1239),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '฿${item.price.toStringAsFixed(0)}',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFED3973),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _badge(String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Reviews Tab
  // -------------------------------------------------------------------------
  Widget _buildReviewsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Text(
                    '4.7',
                    style: GoogleFonts.poppins(
                      fontSize: 48,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E293B),
                      height: 1,
                    ),
                  ),
                  Row(
                    children: List.generate(
                      5,
                      (i) => Icon(
                        i < 5 ? Icons.star : Icons.star_border,
                        size: 14,
                        color: const Color(0xFFF59E0B),
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '128 reviews',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  children: List.generate(5, (i) {
                    final star = 5 - i;
                    const vals = [0.7, 0.2, 0.05, 0.03, 0.02];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Text(
                            '$star',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.star,
                            size: 10,
                            color: Color(0xFFF59E0B),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: LinearProgressIndicator(
                              value: vals[i],
                              backgroundColor: const Color(0xFFE2E8F0),
                              valueColor: const AlwaysStoppedAnimation(
                                Color(0xFFF59E0B),
                              ),
                              minHeight: 6,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ..._reviews.map((r) => _buildReviewCard(r)),
      ],
    );
  }

  Widget _buildReviewCard(_Review r) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFFED3973).withValues(alpha: 0.1),
                child: Text(
                  r.reviewer[0],
                  style: GoogleFonts.poppins(
                    color: const Color(0xFFED3973),
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.reviewer,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    Text(
                      r.date,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: List.generate(
                  5,
                  (i) => Icon(
                    i < r.rating ? Icons.star : Icons.star_border,
                    size: 13,
                    color: const Color(0xFFF59E0B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            r.comment,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: const Color(0xFF475569),
            ),
          ),
          if (r.tags.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              children: r.tags
                  .map(
                    (t) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        t,
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Info Tab
  // -------------------------------------------------------------------------
  Widget _buildInfoTab() {
    final address = _shopProfile?.addressEn ?? 'No address added';
    final phone = _shopProfile?.phone ?? 'No phone added';
    final email = _shopProfile?.email ?? 'No email added';
    final lat = _shopProfile?.latitude?.toStringAsFixed(4) ?? '0.0000';
    final lng = _shopProfile?.longitude?.toStringAsFixed(4) ?? '0.0000';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _infoCard([
          _infoRow(PhosphorIconsRegular.mapPin, 'Address', address),
          _infoRow(PhosphorIconsRegular.phone, 'Phone', phone),
          _infoRow(PhosphorIconsRegular.envelope, 'Email', email),
          _infoRow(PhosphorIconsRegular.tag, 'Category', _shopProfile?.categoryEn ?? '-'),
          _infoRow(PhosphorIconsRegular.listBullets, 'Sub-category', _shopProfile?.subCategoryEn ?? '-'),
          _infoRow(PhosphorIconsRegular.link, 'Slug', _shopProfile?.slug ?? '-'),
          if (_shopProfile?.googleMapsLink?.isNotEmpty == true)
            _infoRow(PhosphorIconsRegular.mapTrifold, 'Map Link', 'Open in Google Maps', highlight: true),
        ]),
        const SizedBox(height: 12),
        if (_shopProfile?.latitude != null && _shopProfile?.longitude != null)
          Container(
            height: 140,
            decoration: BoxDecoration(
              color: const Color(0xFFE0F2FE),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const PhosphorIcon(
                    PhosphorIconsRegular.mapPin,
                    size: 32,
                    color: Color(0xFFED3973),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$lat° N, $lng° E',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: const Color(0xFF475569),
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (_shopProfile?.latitude != null && _shopProfile?.longitude != null)
          const SizedBox(height: 12),
        _sectionLabel('Operating Hours'),
        _infoCard([
          if (_shopProfile?.operatingHours.isEmpty ?? true)
            _infoRow(PhosphorIconsRegular.clock, 'Hours', 'Not set'),
          for (final opHour in _shopProfile?.operatingHours ?? [])
            _infoRow(
              opHour.isClosed
                  ? PhosphorIconsRegular.door
                  : PhosphorIconsRegular.clock,
              opHour.dayName,
              opHour.isClosed
                  ? 'Closed'
                  : '${opHour.openingTime.formatTime()} – ${opHour.closingTime.formatTime()}',
              highlight: opHour.isClosed,
            ),
        ]),
        const SizedBox(height: 12),
        _sectionLabel('Order Settings'),
        _infoCard([
          _infoRow(PhosphorIconsRegular.shoppingBag, 'Max Items', '${_shopProfile?.maxItemQuantityPerOrder ?? 10} per order'),
        ]),
        const SizedBox(height: 12),
        _sectionLabel('Delivery Options'),
        _infoCard([
          _infoRow(
            PhosphorIconsRegular.motorcycle,
            'Standard',
            _shopProfile?.deliveryEnabled == true ? 'Available' : 'Unavailable',
          ),
          _infoRow(
            PhosphorIconsRegular.lightning,
            'Express',
            '฿50  •  15–20 min',
          ),
        ]),
        const SizedBox(height: 12),
        _sectionLabel('Accepted Payments'),
        _infoCard([
          _infoRow(PhosphorIconsRegular.money, 'Cash on Delivery', 'Accepted'),
          _infoRow(PhosphorIconsRegular.creditCard, 'Card', 'Accepted'),
          _infoRow(
            PhosphorIconsRegular.deviceMobile,
            'Mobile Pay',
            'KBZPay, AYAPay, WavePay',
          ),
        ]),
      ],
    );
  }

  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF475569),
        ),
      ),
    );
  }

  Widget _infoCard(List<Widget> rows) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: rows
            .asMap()
            .entries
            .map(
              (e) => Column(
                children: [
                  e.value,
                  if (e.key < rows.length - 1)
                    const Divider(
                      height: 1,
                      color: Color(0xFFE2E8F0),
                      indent: 14,
                      endIndent: 14,
                    ),
                ],
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _infoRow(
    IconData icon,
    String label,
    String value, {
    bool highlight = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PhosphorIcon(icon, size: 18, color: const Color(0xFF94A3B8)),
          const SizedBox(width: 10),
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF475569),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: highlight
                    ? const Color(0xFFED3973)
                    : const Color(0xFF1E293B),
                fontWeight: highlight ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Photos Tab
  // -------------------------------------------------------------------------
  Widget _buildPhotosTab() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: 12,
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFFE2E8F0),
            borderRadius: BorderRadius.circular(8),
          ),
        );
      },
    );
  }

  // -------------------------------------------------------------------------
  // Skeleton Loader
  // -------------------------------------------------------------------------
  Widget _buildSkeletonProfile() {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const Skeleton(width: double.infinity, height: 220),
            Transform.translate(
              offset: const Offset(0, -36),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 20),
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                    child: const ClipOval(
                      child: Skeleton(width: 72, height: 72),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  const Skeleton(width: 200, height: 24),
                  const SizedBox(height: 8),
                  const Skeleton(width: 120, height: 16),
                  const SizedBox(height: 16),
                  const Skeleton(width: 150, height: 16),
                  const SizedBox(height: 16),
                  Row(
                    children: const [
                      Skeleton(width: 60, height: 24),
                      SizedBox(width: 8),
                      Skeleton(width: 80, height: 24),
                      SizedBox(width: 8),
                      Skeleton(width: 70, height: 24),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Skeleton(width: double.infinity, height: 64),
                  const SizedBox(height: 16),
                  Row(
                    children: const [
                      Expanded(child: Skeleton(height: 48)),
                      SizedBox(width: 8),
                      Expanded(child: Skeleton(height: 48)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Skeleton(width: double.infinity, height: 60),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

  Widget _buildImage(String url, {required BoxFit fit, required Widget fallback}) {
    if (url.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: url,
        fit: fit,
        placeholder: (_, _) => fallback,
        errorWidget: (_, _, _) => fallback,
      );
    } else {
      // Local file path
      return kIsWeb
          ? Image.network(url, fit: fit, errorBuilder: (_, __, ___) => fallback)
          : Image.file(
              File(url),
              fit: fit,
              errorBuilder: (_, __, ___) => fallback,
            );
    }
  }
}

class _TabHeaderDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  _TabHeaderDelegate(this.tabBar);

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(color: Colors.white, child: tabBar);
  }

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) =>
      false;
}

class ImageSkeletonLoader extends StatelessWidget {
  const ImageSkeletonLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return const Skeleton(width: double.infinity, height: double.infinity);
  }
}
