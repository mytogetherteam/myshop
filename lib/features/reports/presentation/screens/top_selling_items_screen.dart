import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_shop/core/presentation/widgets/skeleton.dart';
import 'package:my_shop/core/presentation/widgets/custom_loading_indicator.dart';
import 'package:my_shop/features/reports/presentation/widgets/best_seller_tile.dart';

class TopSellingItemsScreen extends StatefulWidget {
  const TopSellingItemsScreen({super.key});

  @override
  State<TopSellingItemsScreen> createState() => _TopSellingItemsScreenState();
}

class _TopSellingItemsScreenState extends State<TopSellingItemsScreen> {
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _items = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  int _selectedFilterIndex = 0;
  final List<String> _filters = ["Today", "Yesterday", "This Week", "Custom"];

  // Dummy data generated for Infinite Scroll
  final List<Map<String, dynamic>> _dummyData = [
    {"name": "Kimchi Jigae", "soldCount": 38, "progress": 0.90},
    {"name": "Traditional Mohinga", "soldCount": 29, "progress": 0.70},
    {"name": "Green Tea Latte", "soldCount": 24, "progress": 0.60},
    {"name": "Duck Egg Salad", "soldCount": 18, "progress": 0.40},
    {"name": "Fired Gourd Soup", "soldCount": 12, "progress": 0.30},
    {"name": "Spicy Pad Thai", "soldCount": 45, "progress": 0.85},
    {"name": "Beef Tacos", "soldCount": 37, "progress": 0.80},
    {"name": "Sushi Platter", "soldCount": 50, "progress": 0.50},
    {"name": "Margherita Pizza", "soldCount": 60, "progress": 0.50},
    {"name": "Chicken Biryani", "soldCount": 33, "progress": 0.50},
    {"name": "Vegetable Stir Fry", "soldCount": 29, "progress": 0.50},
    {"name": "Seafood Paella", "soldCount": 40, "progress": 0.50},
    {"name": "Pork Schnitzel", "soldCount": 34, "progress": 0.50},
    {"name": "Falafel Wrap", "soldCount": 28, "progress": 0.50},
    {"name": "Beef Stroganoff", "soldCount": 22, "progress": 0.50},
    {"name": "Lamb Gyro", "soldCount": 31, "progress": 0.50},
    {"name": "Eggplant Parmesan", "soldCount": 26, "progress": 0.50},
    {"name": "Shrimp Tacos", "soldCount": 35, "progress": 0.50},
    {"name": "Quinoa Salad", "soldCount": 24, "progress": 0.50},
    {"name": "Chicken Alfredo", "soldCount": 39, "progress": 0.50},
  ];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreData();
    }
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _items.clear();
    });

    if (mounted) {
      setState(() {
        _items.addAll(_dummyData.take(10));
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreData() async {
    if (_isLoadingMore || _items.length >= _dummyData.length) return;

    setState(() => _isLoadingMore = true);

    if (mounted) {
      setState(() {
        final currentLength = _items.length;
        final nextItems = _dummyData.skip(currentLength).take(10);
        _items.addAll(nextItems);
        _isLoadingMore = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Top Selling items',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1E293B),
          ),
        ),
        centerTitle: false,
        actions: const [SizedBox(width: 8)],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: List.generate(_filters.length, (index) {
                final isSelected = _selectedFilterIndex == index;
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: InkWell(
                    onTap: () {
                      setState(() => _selectedFilterIndex = index);
                      _loadInitialData();
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFED3A72)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFFED3A72)
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Text(
                        _filters[index],
                        style: GoogleFonts.poppins(
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF64748B),
                          fontSize: 14,
                          fontWeight: isSelected
                              ? FontWeight.w500
                              : FontWeight.w400,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const Divider(color: Color(0xFFF1F5F9), height: 32, thickness: 1),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadInitialData,
              color: const Color(0xFFED3A72),
              child: _isLoading
                  ? _buildSkeletons()
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      itemCount: _items.length + (_isLoadingMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _items.length) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Center(
                              child: CustomLoadingIndicator(
                                size: 24,
                                color: Color(0xFFED3A72),
                              ),
                            ),
                          );
                        }
                        final item = _items[index];
                        // Display items accurately per screenshot design.
                        return BestSellerTile(
                          rank: index + 1,
                          name: item['name'],
                          soldCount: item['soldCount'],
                          progress: item['progress'],
                          // Make progress top three looking if rank is 1-3
                          isTopThree: index < 3,
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletons() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: 8,
      itemBuilder: (context, index) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Row(
            children: [
              Skeleton(width: 28, height: 28, borderRadius: 14),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Skeleton(height: 16, width: double.infinity),
                    SizedBox(height: 12),
                    Skeleton(height: 6, width: double.infinity),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
