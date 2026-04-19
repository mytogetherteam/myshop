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
import 'package:intl/intl.dart';
import 'package:calendar_date_picker2/calendar_date_picker2.dart';

class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late TabController _tabController;
  bool _isLoading = false;
  DateTimeRange? _selectedDateRange;

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

  Future<void> _showCustomDatePicker() async {
    List<DateTime?>? results = await showModalBottomSheet<List<DateTime?>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        List<DateTime?> tempValues = _selectedDateRange != null 
            ? [_selectedDateRange!.start, _selectedDateRange!.end] 
            : [DateTime.now(), DateTime.now().add(const Duration(days: 7))];
            
        return StatefulBuilder(
          builder: (context, setModalState) {
            String rangeText = "Select Dates";
            if (tempValues.length == 2 && tempValues[0] != null && tempValues[1] != null) {
              final start = tempValues[0]!;
              final end = tempValues[1]!;
              if (start.month == end.month) {
                rangeText = "${DateFormat('dd').format(start)} - ${DateFormat('dd MMM').format(end)}";
              } else {
                rangeText = "${DateFormat('dd MMM').format(start)} - ${DateFormat('dd MMM').format(end)}";
              }
            }

            return Container(
              padding: EdgeInsets.only(
                top: 16, 
                bottom: MediaQuery.of(context).padding.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header Indicator & Title
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.expand_more, color: Color(0xFF64748B)),
                        ),
                        Expanded(
                          child: Text(
                            "Choose Revenue Period",
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF0F172A),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(width: 48), // Balance for back button
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Big Range Display
                  Text(
                    rangeText,
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Calendar Component
                  CalendarDatePicker2(
                    config: CalendarDatePicker2Config(
                      calendarType: CalendarDatePicker2Type.range,
                      selectedDayHighlightColor: const Color(0xFFED3A72),
                      selectedRangeHighlightColor: const Color(0xFFED3A72).withValues(alpha: 0.1),
                      weekdayLabelTextStyle: GoogleFonts.poppins(
                        color: const Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                      controlsTextStyle: GoogleFonts.poppins(
                        color: const Color(0xFF1E293B),
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                      dayTextStyle: GoogleFonts.poppins(
                        color: const Color(0xFF1E293B),
                        fontWeight: FontWeight.w400,
                      ),
                      selectedDayTextStyle: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                      todayTextStyle: GoogleFonts.poppins(
                        color: const Color(0xFFED3A72),
                        fontWeight: FontWeight.w600,
                      ),
                      firstDate: DateTime(2026, 1, 1),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    ),
                    value: tempValues,
                    onValueChanged: (values) {
                      setModalState(() => tempValues = values);
                    },
                  ),
                  const SizedBox(height: 16),
                  // Action Buttons
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            "CANCEL",
                            style: GoogleFonts.poppins(
                              color: const Color(0xFF64748B),
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            if (tempValues.length == 2 && tempValues[0] != null && tempValues[1] != null) {
                              Navigator.pop(context, tempValues);
                            }
                          },
                          child: Text(
                            "OK",
                            style: GoogleFonts.poppins(
                              color: const Color(0xFFED3A72),
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (results != null && results.length == 2 && results[0] != null && results[1] != null) {
      setState(() {
        _selectedDateRange = DateTimeRange(start: results[0]!, end: results[1]!);
      });
    }
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
            padding: const EdgeInsets.only(top: 8, bottom: 8),
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
              if (index == 3) {
                _showCustomDatePicker();
              }
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
      if (_tabController.index == 3 && _selectedDateRange != null)
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            children: [
              const PhosphorIcon(
                PhosphorIconsRegular.calendar,
                size: 20,
                color: Color(0xFFED3A72),
              ),
              const SizedBox(width: 10),
              Text(
                "${DateFormat('MMM dd, yyyy').format(_selectedDateRange!.start)} - ${DateFormat('MMM dd, yyyy').format(_selectedDateRange!.end)}",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFED3A72),
                ),
              ),
            ],
          ),
        ),
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
