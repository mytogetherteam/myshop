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
import 'package:my_shop/core/presentation/widgets/gradient_widgets.dart';
import 'package:my_shop/core/utils/app_colors.dart';
import 'package:intl/intl.dart';
import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import '../../data/models/report_model.dart';
import '../../data/services/report_service.dart';

class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

  @override
  State<ReportPage> createState() => ReportPageState();
}

class ReportPageState extends State<ReportPage>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late TabController _tabController;
  final ReportService _reportService = ReportService();
  
  bool _isLoading = true;
  DateTimeRange? _selectedDateRange;
  
  SalesSummaryModel? _summary;
  List<BestSellerModel> _bestSellers = [];
  List<OrderHistoryModel> _orderHistory = [];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    // Default range is "Today"
    _selectedDateRange = DateTimeRange(
      start: DateTime.now().subtract(Duration(hours: DateTime.now().hour, minutes: DateTime.now().minute)),
      end: DateTime.now(),
    );
    _loadData();
  }

  Future<void> refresh() async {
    await _loadData();
  }

  Future<void> _loadData() async {
    if (mounted) setState(() => _isLoading = true);
    
    DateTime start;
    DateTime end = DateTime.now();

    switch (_tabController.index) {
      case 0: // Today
        start = DateTime(end.year, end.month, end.day);
        break;
      case 1: // Yesterday
        start = DateTime(end.year, end.month, end.day).subtract(const Duration(days: 1));
        end = DateTime(end.year, end.month, end.day).subtract(const Duration(seconds: 1));
        break;
      case 2: // This Week
        start = end.subtract(Duration(days: end.weekday - 1));
        start = DateTime(start.year, start.month, start.day);
        break;
      case 3: // Custom
        if (_selectedDateRange != null) {
          start = _selectedDateRange!.start;
          end = _selectedDateRange!.end;
        } else {
          start = DateTime(end.year, end.month, end.day);
        }
        break;
      default:
        start = DateTime(end.year, end.month, end.day);
    }

    try {
      final results = await Future.wait([
        _reportService.getSummary(start: start, end: end),
        _reportService.getBestSellers(start: start, end: end),
        _reportService.getOrders(start: start, end: end),
      ]);

      if (mounted) {
        setState(() {
          _summary = results[0] as SalesSummaryModel?;
          _bestSellers = results[1] as List<BestSellerModel>;
          _orderHistory = results[2] as List<OrderHistoryModel>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
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
            if (tempValues.length == 2 &&
                tempValues[0] != null &&
                tempValues[1] != null) {
              final start = tempValues[0]!;
              final end = tempValues[1]!;
              if (start.month == end.month) {
                rangeText =
                    "${DateFormat('dd').format(start)} - ${DateFormat('dd MMM').format(end)}";
              } else {
                rangeText =
                    "${DateFormat('dd MMM').format(start)} - ${DateFormat('dd MMM').format(end)}";
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
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(
                            Icons.expand_more,
                            color: Color(0xFF64748B),
                          ),
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
                        const SizedBox(width: 48),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    rangeText,
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 16),
                  CalendarDatePicker2(
                    config: CalendarDatePicker2Config(
                      calendarType: CalendarDatePicker2Type.range,
                      selectedDayHighlightColor: AppColors.primary,
                      selectedRangeHighlightColor: AppColors.primary.withValues(alpha: 0.25),
                      dayBorderRadius: BorderRadius.circular(8),
                      centerAlignModePicker: true,
                      controlsHeight: 50,
                      dayMaxWidth: 45,
                      modePickersGap: 16,
                      disableVibration: true,
                      rangeBidirectional: true,
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
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                      firstDate: DateTime(2025, 1, 1),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    ),
                    value: tempValues,
                    onValueChanged: (values) {
                      setModalState(() => tempValues = values);
                    },
                  ),
                  const SizedBox(height: 16),
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
                            if (tempValues.length == 2 &&
                                tempValues[0] != null &&
                                tempValues[1] != null) {
                              Navigator.pop(context, tempValues);
                            }
                          },
                          child: const GradientText(
                            "OK",
                            style: TextStyle(
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

    if (results != null &&
        results.length == 2 &&
        results[0] != null &&
        results[1] != null) {
      setState(() {
        _selectedDateRange = DateTimeRange(
          start: results[0]!,
          end: results[1]!,
        );
      });
      _loadData();
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
              onTap: (index) {
                if (index != 3) {
                  _loadData();
                } else if (_selectedDateRange == null) {
                   _showCustomDatePicker();
                } else {
                  _loadData();
                }
                setState(() {});
              },
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
              color: AppColors.primary,
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
          gradient: isSelected ? AppColors.primaryGradient : null,
          color: isSelected ? null : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: isSelected ? null : Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: InkWell(
          onTap: () {
            if (index == 3) {
              _showCustomDatePicker();
            } else {
              _tabController.animateTo(index);
              _loadData();
            }
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
    );
  }

  List<Widget> _buildContent() {
    final currencyFormat = NumberFormat.currency(symbol: '', decimalDigits: 0);
    
    return [
      if (_tabController.index == 3 && _selectedDateRange != null)
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            children: [
              const GradientWidget(
                child: PhosphorIcon(
                  PhosphorIconsRegular.calendar,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              GradientText(
                "${DateFormat('MMM dd, yyyy').format(_selectedDateRange!.start)} - ${DateFormat('MMM dd, yyyy').format(_selectedDateRange!.end)}",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      RevenueCard(
        revenue: currencyFormat.format(_summary?.revenue ?? 0),
        trend: "${_summary?.revenueTrend ?? '0%'} from last period",
        orders: _summary?.orders.toString() ?? '0', // This is Total Orders
        avgOrder: currencyFormat.format(_summary?.avgOrderValue ?? 0),
        cancelled: _summary?.cancelledCount.toString() ?? '0',
      ),
      const SizedBox(height: 20),
      Column(
        children: [
          Row(
            children: [
              Expanded(
                child: SummaryCard(
                  label: "Completed",
                  value: ((_summary?.orders ?? 0) -
                          (_summary?.cancelledCount ?? 0))
                      .toString(),
                  trend: "Success",
                  isPositive: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SummaryCard(
                  label: "Cancelled",
                  value: _summary?.cancelledCount.toString() ?? '0',
                  trend: "Total",
                  isPositive: false,
                  isTrendPositive: false,
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
                  value: _summary?.avgWaitTime.toString() ?? '15',
                  unit: "min",
                  trend: "Estimated",
                  isPositive: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SummaryCard(
                  label: "Items Sold",
                  value: _summary?.itemsSold.toString() ?? '0',
                  trend: "Period",
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
          if (_bestSellers.isNotEmpty)
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TopSellingItemsScreen(),
                  ),
                );
              },
              child: Row(
                children: [
                  Text(
                    "See more",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const PhosphorIcon(
                    PhosphorIconsRegular.arrowRight,
                    size: 16,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
        ],
      ),
      const SizedBox(height: 16),
      if (_bestSellers.isEmpty)
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Text(
              "No sales data for this period",
              style: GoogleFonts.poppins(color: const Color(0xFF64748B)),
            ),
          ),
        )
      else
        ...List.generate(_bestSellers.length, (index) {
          final item = _bestSellers[index];
          final maxSold = _bestSellers.first.soldCount;
          return BestSellerTile(
            rank: index + 1,
            name: item.name,
            soldCount: item.soldCount,
            progress: maxSold > 0 ? item.soldCount / maxSold : 0,
            isTopThree: index < 3,
          );
        }),
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
          if (_orderHistory.isNotEmpty)
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AllOrderHistoryScreen(),
                  ),
                );
              },
              child: Row(
                children: [
                  Text(
                    "See more",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const PhosphorIcon(
                    PhosphorIconsRegular.arrowRight,
                    size: 16,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
        ],
      ),
      const SizedBox(height: 16),
      if (_orderHistory.isEmpty)
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Text(
              "No orders found",
              style: GoogleFonts.poppins(color: const Color(0xFF64748B)),
            ),
          ),
        )
      else
        ..._orderHistory.map((order) {
          return OrderHistoryItem(
            orderId: order.orderNumber,
            time: DateFormat('hh:mm a').format(order.createdAt),
            status: order.status,
            amount: currencyFormat.format(order.totalAmount),
            statusColor: order.status == 'CANCELLED' ? const Color(0xFFEF4444) : const Color(0xFF22C55E),
          );
        }),
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
      ...List.generate(
        5,
        (_) => const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Skeleton(height: 40),
        ),
      ),
    ];
  }
}
