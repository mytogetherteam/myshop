import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

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
  const _MenuItem({required this.name, required this.price, required this.imageUrl, this.isHot = false, this.isPopular = false, this.isVeg = false, this.isSpicy = false});
}

class _Review {
  final String reviewer;
  final double rating;
  final String date;
  final String comment;
  final List<String> tags;
  const _Review({required this.reviewer, required this.rating, required this.date, required this.comment, this.tags = const []});
}

// ---------------------------------------------------------------------------
// ShopProfilePage
// ---------------------------------------------------------------------------
class ShopProfilePage extends StatefulWidget {
  const ShopProfilePage({super.key});

  @override
  State<ShopProfilePage> createState() => _ShopProfilePageState();
}

class _ShopProfilePageState extends State<ShopProfilePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedCategory = 0;

  final List<String> _categories = ['All', 'Rice & Noodles', 'Soups', 'Drinks', 'Desserts'];

  final List<_MenuItem> _menuItems = const [
    _MenuItem(name: 'Shan Noodles', price: 4500, imageUrl: 'https://delishglobe.com/wp-content/uploads/2025/02/Shan-Noodles.png', isPopular: true),
    _MenuItem(name: 'Mohinga', price: 3500, imageUrl: 'https://asianinspirations.com.au/wp-content/uploads/2023/03/MHG-6.jpg', isHot: true, isSpicy: true),
    _MenuItem(name: 'Tofu Kyaw', price: 3000, imageUrl: 'https://www.cookeatworld.com/wp-content/uploads/2019/11/Burmese-Chicken-10.jpg', isVeg: true),
    _MenuItem(name: 'Shan Rice', price: 5000, imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/7/7d/Shan_rice.jpg/320px-Shan_rice.jpg', isPopular: true),
    _MenuItem(name: 'Laphet Yay', price: 1500, imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/4/45/A_small_cup_of_coffee.JPG/320px-A_small_cup_of_coffee.JPG'),
  ];

  final List<_Review> _reviews = const [
    _Review(reviewer: 'Aung Kyaw', rating: 5, date: 'Mar 10, 2026', comment: 'The food is absolutely amazing! Shan noodles are my favourite.', tags: ['Great food', 'Fast delivery']),
    _Review(reviewer: 'Phyu Phyu', rating: 4, date: 'Mar 8, 2026', comment: 'Very tasty and affordable. The mohinga is just like home.', tags: ['Authentic', 'Affordable']),
    _Review(reviewer: 'Kyaw Zin', rating: 4, date: 'Mar 5, 2026', comment: 'Good portion sizes and freshly cooked.', tags: ['Fresh', 'Good value']),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverToBoxAdapter(child: _buildHero()),
          SliverToBoxAdapter(child: _buildInfoSection()),
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabHeaderDelegate(
              TabBar(
                controller: _tabController,
                labelColor: const Color(0xFFED3973),
                unselectedLabelColor: const Color(0xFF64748B),
                indicatorColor: const Color(0xFFED3973),
                indicatorWeight: 2,
                labelStyle: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600),
                unselectedLabelStyle: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500),
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
    );
  }

  // -------------------------------------------------------------------------
  // Hero Section
  // -------------------------------------------------------------------------
  Widget _buildHero() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Cover photo
        Container(
          height: 220,
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFED3973), Color(0xFFFF8C69)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: Opacity(
                  opacity: 0.1,
                  child: GridPaper(color: Colors.white, divisions: 1, subdivisions: 1, interval: 40, child: Container()),
                ),
              ),
              // Gradient overlay for readability
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withValues(alpha: 0.3)],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Back button
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Material(
              color: Colors.black.withValues(alpha: 0.3),
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => Navigator.of(context).pop(),
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: PhosphorIcon(PhosphorIconsRegular.arrowLeft, size: 22, color: Colors.white),
                ),
              ),
            ),
          ),
        ),
        // Logo overlay
        Positioned(
          bottom: -36,
          left: 20,
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 8, offset: const Offset(0, 2))],
              gradient: const LinearGradient(
                colors: [Color(0xFFED3973), Color(0xFFFF8C69)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Center(
              child: Text('B', style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------------------
  // Info Section (below hero)
  // -------------------------------------------------------------------------
  Widget _buildInfoSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 56, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name + category
          Text('Banbann Kitchen',
              style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B))),
          const SizedBox(height: 2),
          Text('Restaurant  •  Burmese • Myanmar Cuisine',
              style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF64748B))),
          const SizedBox(height: 10),

          // Rating
          Row(
            children: [
              const PhosphorIcon(PhosphorIconsFill.star, size: 16, color: Color(0xFFF59E0B)),
              const SizedBox(width: 4),
              Text('4.7', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B))),
              const SizedBox(width: 4),
              Text('(128 reviews)', style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF94A3B8))),
            ],
          ),
          const SizedBox(height: 12),

          // Amenity chips
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _amenityChip(PhosphorIconsRegular.car, 'Parking'),
              _amenityChip(PhosphorIconsRegular.wifiHigh, 'WiFi'),
              _amenityChip(PhosphorIconsRegular.motorcycle, 'Delivery'),
              _amenityChip(PhosphorIconsRegular.moon, 'Halal'),
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
                _infoStat(PhosphorIconsRegular.tag, 'Free', 'Delivery fee'),
                _infoStatDivider(),
                _infoStat(PhosphorIconsRegular.clock, '25–35 min', 'Est. time'),
                _infoStatDivider(),
                _infoStat(PhosphorIconsRegular.shoppingCart, '฿500', 'Min. order'),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {},
                  icon: const PhosphorIcon(PhosphorIconsRegular.motorcycle, size: 18, color: Colors.white),
                  label: Text('Order Delivery', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14)),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFED3973),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const PhosphorIcon(PhosphorIconsRegular.navigationArrow, size: 18, color: Color(0xFF475569)),
                  label: Text('Get Directions', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14, color: const Color(0xFF475569))),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Read-only phone info block
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                const PhosphorIcon(PhosphorIconsRegular.phone, size: 18, color: Color(0xFF475569)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('+95 9 123 456 789',
                          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B))),
                      Text('This is the phone number currently shown to customers on your public profile.',
                          style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF94A3B8))),
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
          Text(label, style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w500, color: const Color(0xFF475569))),
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
          Text(value, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B))),
          Text(label, style: GoogleFonts.poppins(fontSize: 10, color: const Color(0xFF94A3B8))),
        ],
      ),
    );
  }

  Widget _infoStatDivider() {
    return Container(width: 1, height: 36, color: const Color(0xFFE2E8F0));
  }

  // -------------------------------------------------------------------------
  // Menu Tab
  // -------------------------------------------------------------------------
  Widget _buildMenuTab() {
    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        // Category filter
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
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: selected ? const Color(0xFFED3973) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: selected ? const Color(0xFFED3973) : const Color(0xFFE2E8F0)),
                  ),
                  child: Text(_categories[i],
                      style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: selected ? Colors.white : const Color(0xFF475569))),
                ),
              );
            },
          ),
        ),
        // Section title
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Text('Rice & Noodles', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B))),
        ),
        // Menu items
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
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
            child: Image.network(
              item.imageUrl,
              width: 90,
              height: 80,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 90,
                height: 80,
                color: const Color(0xFFE2E8F0),
                child: const PhosphorIcon(PhosphorIconsRegular.forkKnife, size: 28, color: Color(0xFF94A3B8)),
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
                  Text(item.name, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B))),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 4,
                    children: [
                      if (item.isHot) _badge('🔥 Hot Deal', const Color(0xFFFFF3CD), const Color(0xFF92400E)),
                      if (item.isPopular) _badge('⭐ Popular', const Color(0xFFE0F2FE), const Color(0xFF0369A1)),
                      if (item.isVeg) _badge('🌿 Veg', const Color(0xFFDCFCE7), const Color(0xFF166534)),
                      if (item.isSpicy) _badge('🌶 Spicy', const Color(0xFFFFE4E6), const Color(0xFF9F1239)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text('฿${item.price.toStringAsFixed(0)}', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFFED3973))),
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
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
      child: Text(label, style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.w600, color: fg)),
    );
  }

  // -------------------------------------------------------------------------
  // Reviews Tab
  // -------------------------------------------------------------------------
  Widget _buildReviewsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Overall score
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Text('4.7', style: GoogleFonts.poppins(fontSize: 48, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B), height: 1)),
                  Row(
                    children: List.generate(5, (i) => Icon(i < 5 ? Icons.star : Icons.star_border, size: 14, color: const Color(0xFFF59E0B))),
                  ),
                  const SizedBox(height: 2),
                  Text('128 reviews', style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF94A3B8))),
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
                          Text('$star', style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF64748B))),
                          const SizedBox(width: 4),
                          const Icon(Icons.star, size: 10, color: Color(0xFFF59E0B)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: LinearProgressIndicator(
                              value: vals[i],
                              backgroundColor: const Color(0xFFE2E8F0),
                              valueColor: const AlwaysStoppedAnimation(Color(0xFFF59E0B)),
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
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFFED3973).withValues(alpha: 0.1),
                child: Text(r.reviewer[0], style: GoogleFonts.poppins(color: const Color(0xFFED3973), fontWeight: FontWeight.w700, fontSize: 14)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.reviewer, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B))),
                    Text(r.date, style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF94A3B8))),
                  ],
                ),
              ),
              Row(
                children: List.generate(5, (i) => Icon(i < r.rating ? Icons.star : Icons.star_border, size: 13, color: const Color(0xFFF59E0B))),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(r.comment, style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF475569))),
          if (r.tags.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              children: r.tags.map((t) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(20)),
                child: Text(t, style: GoogleFonts.poppins(fontSize: 10, color: const Color(0xFF64748B))),
              )).toList(),
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
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _infoCard([
          _infoRow(PhosphorIconsRegular.mapPin, 'Address', '12 Mingalar Taung Nyunt Road, Yangon'),
          _infoRow(PhosphorIconsRegular.phone, 'Phone', '+95 9 123 456 789'),
          _infoRow(PhosphorIconsRegular.envelope, 'Email', 'contact@banbann.com'),
        ]),
        const SizedBox(height: 12),
        // Map pin placeholder
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
                const PhosphorIcon(PhosphorIconsRegular.mapPin, size: 32, color: Color(0xFFED3973)),
                const SizedBox(height: 6),
                Text('16.8409° N, 96.1735° E', style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF475569))),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Operating hours
        _sectionLabel('Operating Hours'),
        _infoCard([
          for (final entry in {
            'Monday': '09:00 – 22:00', 'Tuesday': '09:00 – 22:00', 'Wednesday': '09:00 – 22:00',
            'Thursday': '09:00 – 22:00', 'Friday': '09:00 – 22:00', 'Saturday': '09:00 – 23:00', 'Sunday': 'Closed',
          }.entries)
            _infoRow(
              entry.value == 'Closed' ? PhosphorIconsRegular.door : PhosphorIconsRegular.clock,
              entry.key,
              entry.value,
              highlight: entry.value == 'Closed',
            ),
        ]),
        const SizedBox(height: 12),
        // Delivery tiers
        _sectionLabel('Delivery Options'),
        _infoCard([
          _infoRow(PhosphorIconsRegular.motorcycle, 'Standard', 'Free  •  25–35 min'),
          _infoRow(PhosphorIconsRegular.lightning, 'Express', '฿50  •  15–20 min'),
        ]),
        const SizedBox(height: 12),
        // Payment
        _sectionLabel('Accepted Payments'),
        _infoCard([
          _infoRow(PhosphorIconsRegular.money, 'Cash on Delivery', 'Accepted'),
          _infoRow(PhosphorIconsRegular.creditCard, 'Card', 'Accepted'),
          _infoRow(PhosphorIconsRegular.deviceMobile, 'Mobile Pay', 'KBZPay, AYAPay, WavePay'),
        ]),
      ],
    );
  }

  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(label, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF475569))),
    );
  }

  Widget _infoCard(List<Widget> rows) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(
        children: rows.asMap().entries.map((e) => Column(
          children: [
            e.value,
            if (e.key < rows.length - 1) const Divider(height: 1, color: Color(0xFFE2E8F0), indent: 14, endIndent: 14),
          ],
        )).toList(),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PhosphorIcon(icon, size: 18, color: const Color(0xFF94A3B8)),
          const SizedBox(width: 10),
          SizedBox(width: 90, child: Text(label, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: const Color(0xFF475569)))),
          Expanded(
            child: Text(value,
                style: GoogleFonts.poppins(fontSize: 13, color: highlight ? const Color(0xFFED3973) : const Color(0xFF1E293B), fontWeight: highlight ? FontWeight.w600 : FontWeight.w400)),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Photos Tab
  // -------------------------------------------------------------------------
  Widget _buildPhotosTab() {
    final photos = [
      'https://delishglobe.com/wp-content/uploads/2025/02/Shan-Noodles.png',
      'https://asianinspirations.com.au/wp-content/uploads/2023/03/MHG-6.jpg',
      'https://www.cookeatworld.com/wp-content/uploads/2019/11/Burmese-Chicken-10.jpg',
      'https://upload.wikimedia.org/wikipedia/commons/thumb/7/7d/Shan_rice.jpg/320px-Shan_rice.jpg',
      'https://upload.wikimedia.org/wikipedia/commons/thumb/4/45/A_small_cup_of_coffee.JPG/320px-A_small_cup_of_coffee.JPG',
      'https://asianinspirations.com.au/wp-content/uploads/2023/03/MHG-6.jpg',
    ];
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 4, mainAxisSpacing: 4),
      itemCount: photos.length,
      itemBuilder: (_, i) => ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.network(
          photos[i],
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: const Color(0xFFE2E8F0),
            child: const Center(child: PhosphorIcon(PhosphorIconsRegular.image, size: 24, color: Color(0xFF94A3B8))),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Pinned TabBar delegate
// ---------------------------------------------------------------------------
class _TabHeaderDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  const _TabHeaderDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_TabHeaderDelegate oldDelegate) => false;
}
