import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:my_shop/core/presentation/widgets/skeleton.dart';
import 'package:my_shop/features/reports/presentation/widgets/order_history_item.dart';

class AllOrderHistoryScreen extends StatefulWidget {
  const AllOrderHistoryScreen({super.key});

  @override
  State<AllOrderHistoryScreen> createState() => _AllOrderHistoryScreenState();
}

class _AllOrderHistoryScreenState extends State<AllOrderHistoryScreen> {
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _days = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  int _selectedFilterIndex = 0;
  final List<String> _filters = ["Mar", "Feb", "Dec", "Nov", "Oct"];
  
  // Dummy data generated for Infinite Scroll
  final List<Map<String, dynamic>> _dummyData = [
    {
      "date": "14 Mar 2026",
      "orders": [
        {"orderId": "AX-3922", "time": "10:42 AM", "status": "Completed", "amount": "270", "statusColor": const Color(0xFF22C55E)},
        {"orderId": "GH-1943", "time": "11:11 AM", "status": "Completed", "amount": "410", "statusColor": const Color(0xFF22C55E)},
        {"orderId": "TR-6352", "time": "01:02 PM", "status": "Completed", "amount": "120", "statusColor": const Color(0xFF22C55E)},
        {"orderId": "QW-8349", "time": "04:59 AM", "status": "Cancelled", "amount": "235", "statusColor": const Color(0xFFEF4444)},
      ],
    },
    {
      "date": "13 Mar 2026",
      "orders": [
        {"orderId": "AX-3922", "time": "10:42 AM", "status": "Completed", "amount": "270", "statusColor": const Color(0xFF22C55E)},
        {"orderId": "GH-1943", "time": "11:11 AM", "status": "Completed", "amount": "410", "statusColor": const Color(0xFF22C55E)},
        {"orderId": "TR-6352", "time": "01:02 PM", "status": "Completed", "amount": "120", "statusColor": const Color(0xFF22C55E)},
        {"orderId": "QW-8349", "time": "04:59 AM", "status": "Cancelled", "amount": "235", "statusColor": const Color(0xFFEF4444)},
        {"orderId": "LP-7539", "time": "08:00 AM", "status": "Completed", "amount": "380", "statusColor": const Color(0xFF22C55E)},
        {"orderId": "ZX-2957", "time": "02:30 PM", "status": "Cancelled", "amount": "495", "statusColor": const Color(0xFFEF4444)},
        {"orderId": "VC-0926", "time": "06:15 AM", "status": "Completed", "amount": "210", "statusColor": const Color(0xFF22C55E)},
      ],
    },
    {
      "date": "12 Mar 2026",
      "orders": [
         {"orderId": "AX-3922", "time": "10:42 AM", "status": "Completed", "amount": "270", "statusColor": const Color(0xFF22C55E)},
        {"orderId": "GH-1943", "time": "11:11 AM", "status": "Completed", "amount": "410", "statusColor": const Color(0xFF22C55E)},
        {"orderId": "TR-6352", "time": "01:02 PM", "status": "Completed", "amount": "120", "statusColor": const Color(0xFF22C55E)},
        {"orderId": "QW-8349", "time": "04:59 AM", "status": "Cancelled", "amount": "235", "statusColor": const Color(0xFFEF4444)},
        {"orderId": "LP-7539", "time": "08:00 AM", "status": "Completed", "amount": "380", "statusColor": const Color(0xFF22C55E)},
        {"orderId": "ZX-2957", "time": "02:30 PM", "status": "Cancelled", "amount": "495", "statusColor": const Color(0xFFEF4444)},
      ],
    },
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
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _loadMoreData();
    }
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _days.clear();
    });
    
    await Future.delayed(const Duration(seconds: 2));
    
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
    
    await Future.delayed(const Duration(seconds: 1));
    
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'All order history',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1E293B),
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () {},
            icon: const PhosphorIcon(PhosphorIconsRegular.export, size: 18, color: Color(0xFF64748B)),
            label: Text(
              'Export',
              style: GoogleFonts.poppins(
                color: const Color(0xFF64748B),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
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
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFED3A72) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? const Color(0xFFED3A72) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Text(
                        _filters[index],
                        style: GoogleFonts.poppins(
                          color: isSelected ? Colors.white : const Color(0xFF64748B),
                          fontSize: 14,
                          fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
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
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    itemCount: _days.length + (_isLoadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _days.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: CircularProgressIndicator(color: Color(0xFFED3A72)),
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
                          ...List.generate(dayData["orders"].length, (orderIndex) {
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
                                  const Divider(color: Color(0xFFF1F5F9), height: 1, thickness: 1),
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

  Widget _buildSkeletons() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Skeleton(height: 24, width: 120),
            ),
            ...List.generate(4, (_) => const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  Skeleton(width: 8, height: 8, borderRadius: 4),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Skeleton(height: 18, width: 140),
                        SizedBox(height: 4),
                        Skeleton(height: 14, width: 80),
                      ],
                    ),
                  ),
                  Skeleton(height: 20, width: 60),
                ],
              ),
            )),
          ],
        );
      },
    );
  }
}
