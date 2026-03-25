import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:my_shop/core/presentation/widgets/skeleton.dart';
import 'package:my_shop/features/reports/presentation/widgets/revenue_card.dart';
import 'package:my_shop/features/reports/presentation/widgets/summary_card.dart';
import 'package:my_shop/features/reports/presentation/widgets/best_seller_tile.dart';
import 'package:my_shop/features/reports/presentation/widgets/order_history_item.dart';
import 'package:my_shop/features/reports/presentation/screens/all_order_history_screen.dart';
import 'package:my_shop/features/reports/presentation/screens/top_selling_items_screen.dart';
import 'package:my_shop/features/reports/presentation/screens/analytics_page.dart';

class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late TabController _tabController;
  bool _isLoading = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    // Mock loading already complete or not needed for initial view
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.only(top: 8, bottom: 8, right: 8),
            child: Row(
              children: [
                Expanded(
                  child: TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    indicatorColor: Colors.transparent,
                    dividerColor: Colors.transparent,
                    labelColor: Colors.white,
                    unselectedLabelColor: const Color(0xFF94A3B8),
                    labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                    labelStyle: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    unselectedLabelStyle: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    onTap: (index) => setState(() {}),
                    tabs: [
                      _buildFilterTab("Today", 0),
                      _buildFilterTab("Yesterday", 1),
                      _buildFilterTab("This Week", 2),
                      _buildFilterTab("Custom", 3),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 24,
                  color: const Color(0xFFE2E8F0),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AnalyticsPage()),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFED3A72), Color(0xFFFB923C)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.all(1.2),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const PhosphorIcon(
                            PhosphorIconsFill.chartPieSlice,
                            size: 16,
                            color: Color(0xFFED3A72),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "View analytics",
                            style: GoogleFonts.poppins(
                              color: const Color(0xFFED3A72),
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadData,
              color: const Color(0xFFED3A72),
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: _isLoading ? _buildSkeletons() : _buildContent(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTab(String text, int index) {
    bool isSelected = _tabController.index == index;
    return Tab(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.transparent : const Color(0xFFE2E8F0),
          ),
        ),
        child: Material(
          color: isSelected ? const Color(0xFFED3A72) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () {
              _tabController.animateTo(index);
              setState(() {});
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                text,
                style: GoogleFonts.poppins(
                  color: isSelected ? Colors.white : const Color(0xFF64748B),
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildContent() {
    return [
      const RevenueCard(
        revenue: "12,480",
        trend: "18% from yesterday",
        orders: "47",
        avgOrder: "457",
        cancelled: "3",
      ),
      const SizedBox(height: 20),
      Column(
        children: [
          Row(
            children: [
              Expanded(
                child: SummaryCard(
                  label: "Completed",
                  value: "44",
                  trend: "8%",
                  isPositive: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SummaryCard(
                  label: "Cancelled",
                  value: "3",
                  trend: "3%",
                  isPositive: false,
                  isTrendPositive: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: SummaryCard(
                  label: "Avg Wait Time",
                  value: "12",
                  unit: "min",
                  trend: "3 min",
                  isPositive: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SummaryCard(
                  label: "Items Sold",
                  value: "138",
                  trend: "7%",
                  isPositive: true,
                ),
              ),
            ],
          ),
        ],
      ),
      const SizedBox(height: 32),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "Best Sellers",
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E293B),
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TopSellingItemsScreen()),
              );
            },
            child: Row(
              children: [
                Text(
                  "See more",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFED3A72),
                  ),
                ),
                const SizedBox(width: 4),
                const PhosphorIcon(
                  PhosphorIconsRegular.arrowRight,
                  size: 16,
                  color: Color(0xFFED3A72),
                ),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      const BestSellerTile(
        rank: 1,
        name: "Kimchi Jigae",
        soldCount: 38,
        progress: 0.9,
        isTopThree: true,
      ),
      const BestSellerTile(
        rank: 2,
        name: "Traditional Mohinga",
        soldCount: 29,
        progress: 0.7,
        isTopThree: true,
      ),
      const BestSellerTile(
        rank: 3,
        name: "Green Tea Latte",
        soldCount: 24,
        progress: 0.6,
        isTopThree: true,
      ),
      const BestSellerTile(
        rank: 4,
        name: "Duck Egg Salad",
        soldCount: 18,
        progress: 0.4,
      ),
      const BestSellerTile(
        rank: 5,
        name: "Fired Gourd Soup",
        soldCount: 12,
        progress: 0.3,
      ),
      const SizedBox(height: 32),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "Order History",
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E293B),
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AllOrderHistoryScreen()),
              );
            },
            child: Row(
              children: [
                Text(
                  "See more",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFED3A72),
                  ),
                ),
                const SizedBox(width: 4),
                const PhosphorIcon(
                  PhosphorIconsRegular.arrowRight,
                  size: 16,
                  color: Color(0xFFED3A72),
                ),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      const OrderHistoryItem(
        orderId: "AX-3922",
        time: "10:42 AM",
        status: "Completed",
        amount: "270",
        statusColor: Color(0xFF22C55E),
      ),
      const OrderHistoryItem(
        orderId: "GH-1943",
        time: "11:11 AM",
        status: "Completed",
        amount: "410",
        statusColor: Color(0xFF22C55E),
      ),
      const OrderHistoryItem(
        orderId: "TR-6352",
        time: "01:02 PM",
        status: "Completed",
        amount: "120",
        statusColor: Color(0xFF22C55E),
      ),
       const OrderHistoryItem(
        orderId: "QW-8349",
        time: "04:59 AM",
        status: "Cancelled",
        amount: "235",
        statusColor: Color(0xFFEF4444),
      ),
       const OrderHistoryItem(
        orderId: "LP-7539",
        time: "08:00 AM",
        status: "Completed",
        amount: "380",
        statusColor: Color(0xFF22C55E),
      ),
      const SizedBox(height: 20),
      const SizedBox(height: 40),
    ];
  }

  List<Widget> _buildSkeletons() {
    return [
      const Skeleton(height: 200, borderRadius: 24),
      const SizedBox(height: 20),
      Column(
        children: [
          Row(
            children: [
              const Expanded(child: Skeleton(height: 100, borderRadius: 16)),
              const SizedBox(width: 12),
              const Expanded(child: Skeleton(height: 100, borderRadius: 16)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Expanded(child: Skeleton(height: 100, borderRadius: 16)),
              const SizedBox(width: 12),
              const Expanded(child: Skeleton(height: 100, borderRadius: 16)),
            ],
          ),
        ],
      ),
      const SizedBox(height: 32),
      const Skeleton(width: 150, height: 24),
      const SizedBox(height: 16),
      ...List.generate(5, (_) => const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Skeleton(height: 40),
      )),
    ];
  }
}
