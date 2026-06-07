import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:my_shop/core/presentation/widgets/skeleton.dart';
import 'package:my_shop/features/reports/presentation/widgets/order_history_item.dart';
import 'package:my_shop/core/localization/app_localizations.dart';
import '../../data/models/report_model.dart';
import '../../data/services/report_service.dart';

class _OrderDayGroup {
  final String date;
  final List<OrderHistoryModel> orders;

  _OrderDayGroup({required this.date, required this.orders});
}

class AllOrderHistoryScreen extends StatefulWidget {
  const AllOrderHistoryScreen({super.key});

  @override
  State<AllOrderHistoryScreen> createState() => _AllOrderHistoryScreenState();
}

class _AllOrderHistoryScreenState extends State<AllOrderHistoryScreen> {
  final ScrollController _scrollController = ScrollController();
  final ScrollController _filterScrollController = ScrollController();
  final ReportService _reportService = ReportService();
  List<_OrderDayGroup> _days = [];
  bool _isLoading = true;
  int _selectedFilterIndex = 11;
  final List<String> _filters = [];
  final List<DateTime> _filterDates = [];

  @override
  void initState() {
    super.initState();
    _generateFilters();
    _loadInitialData();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_filterScrollController.hasClients) {
        final screenWidth = MediaQuery.of(context).size.width;
        const double itemTotalWidth = 96.0; // 84 width + 12 right padding
        const int initialIndex = 1200 + 11; // Multiple of 12 plus the 11th index

        // Offset to center the item:
        // list padding (20) + items before it (initialIndex * itemTotalWidth) + half item width (42) - half screen width
        final double initialOffset = 20.0 + (initialIndex * itemTotalWidth) + 42.0 - (screenWidth / 2);

        _filterScrollController.jumpTo(initialOffset);
      }
    });
  }

  void _generateFilters() {
    final now = DateTime.now();
    for (int i = 11; i >= 0; i--) {
      final monthDate = DateTime(now.year, now.month - i, 1);
      _filters.add(DateFormat('MMM').format(monthDate));
      _filterDates.add(monthDate);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _filterScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _days = [];
      });
    }

    final monthDate = _filterDates[_selectedFilterIndex];
    final start = DateTime(monthDate.year, monthDate.month, 1);
    final end = DateTime(monthDate.year, monthDate.month + 1, 0, 23, 59, 59);

    final orders = await _reportService.getOrders(
      start: start,
      end: end,
      limit: 100,
    );

    // Group orders by day (newest first).
    final Map<String, List<OrderHistoryModel>> grouped = {};
    for (final order in orders) {
      final key = DateFormat('dd MMM yyyy').format(order.createdAt);
      grouped.putIfAbsent(key, () => []).add(order);
    }

    final days = grouped.entries
        .map((e) => _OrderDayGroup(date: e.key, orders: e.value))
        .toList();

    if (mounted) {
      setState(() {
        _days = days;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
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
          t?.translate('order_history') ?? 'All order history',
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
          SizedBox(
            height: 40,
            child: ListView.builder(
              controller: _filterScrollController,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: 10000,
              itemBuilder: (context, index) {
                final realIndex = index % _filters.length;
                final isSelected = _selectedFilterIndex == realIndex;
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: InkWell(
                    onTap: () {
                      setState(() => _selectedFilterIndex = realIndex);
                      _loadInitialData();
                      
                      // Animate centering
                      final screenWidth = MediaQuery.of(context).size.width;
                      const double itemTotalWidth = 96.0;
                      final double targetOffset = 20.0 + (index * itemTotalWidth) + 42.0 - (screenWidth / 2);
                      
                      _filterScrollController.animateTo(
                        targetOffset,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 84,
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFED3973)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFFED3973)
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Text(
                        DateFormat('MMM', Localizations.localeOf(context).toString()).format(_filterDates[realIndex]),
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
              },
            ),
          ),
          const Divider(color: Color(0xFFF1F5F9), height: 32, thickness: 1),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadInitialData,
              color: const Color(0xFFED3973),
              child: _isLoading
                  ? _buildSkeletonList()
                  : _days.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 80),
                              child: Center(
                                child: Text(
                                  t?.translate('no_orders_yet') ??
                                      "No orders found",
                                  style: GoogleFonts.poppins(
                                    color: const Color(0xFF64748B),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 8,
                          ),
                          itemCount: _days.length,
                          itemBuilder: (context, index) {
                            final dayData = _days[index];
                            final currencyFormat = NumberFormat.currency(
                              symbol: '',
                              decimalDigits: 0,
                            );
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  child: Text(
                                    dayData.date,
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF1E293B),
                                    ),
                                  ),
                                ),
                                ...List.generate(dayData.orders.length, (
                                  orderIndex,
                                ) {
                                  final order = dayData.orders[orderIndex];
                                  final isCancelled =
                                      order.status.toUpperCase() == 'CANCELLED';
                                  return Column(
                                    children: [
                                      OrderHistoryItem(
                                        orderId: order.orderNumber,
                                        time: DateFormat('hh:mm a')
                                            .format(order.createdAt),
                                        status: order.status,
                                        amount: currencyFormat
                                            .format(order.totalAmount),
                                        statusColor: isCancelled
                                            ? const Color(0xFFEF4444)
                                            : const Color(0xFF22C55E),
                                      ),
                                      if (orderIndex < dayData.orders.length - 1)
                                        const Divider(
                                          color: Color(0xFFF1F5F9),
                                          height: 1,
                                          thickness: 1,
                                        ),
                                    ],
                                  );
                                }),
                                const SizedBox(height: 16),
                              ],
                            );
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonList() {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: 3,
      itemBuilder: (_, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Skeleton(height: 16, width: 120),
          ),
          ...List.generate(
            3,
            (i) => Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      const Skeleton.circle(width: 8, height: 8),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Skeleton(height: 14, width: 140),
                            SizedBox(height: 6),
                            Skeleton(height: 10, width: 70),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Skeleton(height: 14, width: 60),
                    ],
                  ),
                ),
                if (i < 2)
                  const Divider(
                    color: Color(0xFFF1F5F9),
                    height: 1,
                    thickness: 1,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
