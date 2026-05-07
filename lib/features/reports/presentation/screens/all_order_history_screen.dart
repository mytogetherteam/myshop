import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:my_shop/core/presentation/widgets/custom_loading_indicator.dart';
import 'package:my_shop/features/reports/presentation/widgets/order_history_item.dart';

class AllOrderHistoryScreen extends StatefulWidget {
  const AllOrderHistoryScreen({super.key});

  @override
  State<AllOrderHistoryScreen> createState() => _AllOrderHistoryScreenState();
}

class _AllOrderHistoryScreenState extends State<AllOrderHistoryScreen> {
  final ScrollController _scrollController = ScrollController();
  final ScrollController _filterScrollController = ScrollController();
  final List<Map<String, dynamic>> _days = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  int _selectedFilterIndex = 11;
  final List<String> _filters = [];

  // Dummy data generated for Infinite Scroll
  final List<Map<String, dynamic>> _dummyData = [
    {
      "date": "14 Mar 2026",
      "orders": [
        {
          "orderId": "AX-3922",
          "time": "10:42 AM",
          "status": "Completed",
          "amount": "270",
          "statusColor": const Color(0xFF22C55E),
        },
        {
          "orderId": "GH-1943",
          "time": "11:11 AM",
          "status": "Completed",
          "amount": "410",
          "statusColor": const Color(0xFF22C55E),
        },
        {
          "orderId": "TR-6352",
          "time": "01:02 PM",
          "status": "Completed",
          "amount": "120",
          "statusColor": const Color(0xFF22C55E),
        },
        {
          "orderId": "QW-8349",
          "time": "04:59 AM",
          "status": "Cancelled",
          "amount": "235",
          "statusColor": const Color(0xFFEF4444),
        },
      ],
    },
    {
      "date": "13 Mar 2026",
      "orders": [
        {
          "orderId": "AX-3922",
          "time": "10:42 AM",
          "status": "Completed",
          "amount": "270",
          "statusColor": const Color(0xFF22C55E),
        },
        {
          "orderId": "GH-1943",
          "time": "11:11 AM",
          "status": "Completed",
          "amount": "410",
          "statusColor": const Color(0xFF22C55E),
        },
        {
          "orderId": "TR-6352",
          "time": "01:02 PM",
          "status": "Completed",
          "amount": "120",
          "statusColor": const Color(0xFF22C55E),
        },
        {
          "orderId": "QW-8349",
          "time": "04:59 AM",
          "status": "Cancelled",
          "amount": "235",
          "statusColor": const Color(0xFFEF4444),
        },
        {
          "orderId": "LP-7539",
          "time": "08:00 AM",
          "status": "Completed",
          "amount": "380",
          "statusColor": const Color(0xFF22C55E),
        },
        {
          "orderId": "ZX-2957",
          "time": "02:30 PM",
          "status": "Cancelled",
          "amount": "495",
          "statusColor": const Color(0xFFEF4444),
        },
        {
          "orderId": "VC-0926",
          "time": "06:15 AM",
          "status": "Completed",
          "amount": "210",
          "statusColor": const Color(0xFF22C55E),
        },
      ],
    },
    {
      "date": "12 Mar 2026",
      "orders": [
        {
          "orderId": "AX-3922",
          "time": "10:42 AM",
          "status": "Completed",
          "amount": "270",
          "statusColor": const Color(0xFF22C55E),
        },
        {
          "orderId": "GH-1943",
          "time": "11:11 AM",
          "status": "Completed",
          "amount": "410",
          "statusColor": const Color(0xFF22C55E),
        },
        {
          "orderId": "TR-6352",
          "time": "01:02 PM",
          "status": "Completed",
          "amount": "120",
          "statusColor": const Color(0xFF22C55E),
        },
        {
          "orderId": "QW-8349",
          "time": "04:59 AM",
          "status": "Cancelled",
          "amount": "235",
          "statusColor": const Color(0xFFEF4444),
        },
        {
          "orderId": "LP-7539",
          "time": "08:00 AM",
          "status": "Completed",
          "amount": "380",
          "statusColor": const Color(0xFF22C55E),
        },
        {
          "orderId": "ZX-2957",
          "time": "02:30 PM",
          "status": "Cancelled",
          "amount": "495",
          "statusColor": const Color(0xFFEF4444),
        },
      ],
    },
  ];

  @override
  void initState() {
    super.initState();
    _generateFilters();
    _loadInitialData();
    _scrollController.addListener(_onScroll);
    
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
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _filterScrollController.dispose();
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
      _days.clear();
    });

    if (mounted) {
      setState(() {
        _days.addAll(_dummyData.take(2));
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreData() async {
    if (_isLoadingMore || _days.length >= _dummyData.length) return;

    setState(() => _isLoadingMore = true);

    if (mounted) {
      setState(() {
        final currentLength = _days.length;
        final nextItems = _dummyData.skip(currentLength).take(1);
        _days.addAll(nextItems);
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
          'All order history',
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
                        _filters[realIndex],
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
                  ? const Center(
                      child: CustomLoadingIndicator(size: 40),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      itemCount: _days.length + (_isLoadingMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _days.length) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Center(
                              child: CustomLoadingIndicator(size: 24),
                            ),
                          );
                        }
                        final dayData = _days[index];
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Text(
                                dayData["date"],
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF1E293B),
                                ),
                              ),
                            ),
                            ...List.generate(dayData["orders"].length, (
                              orderIndex,
                            ) {
                              final order = dayData["orders"][orderIndex];
                              return Column(
                                children: [
                                  OrderHistoryItem(
                                    orderId: order["orderId"],
                                    time: order["time"],
                                    status: order["status"],
                                    amount: order["amount"],
                                    statusColor: order["statusColor"],
                                  ),
                                  if (orderIndex < dayData["orders"].length - 1)
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
}
