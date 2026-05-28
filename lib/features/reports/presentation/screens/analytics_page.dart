import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:my_shop/core/presentation/widgets/skeleton.dart';
import 'package:my_shop/features/reports/presentation/widgets/analytics_donut_chart.dart';
import 'package:my_shop/features/reports/presentation/widgets/analytics_line_chart.dart';
import 'package:my_shop/features/reports/presentation/widgets/progress_bar_item.dart';
import 'package:intl/intl.dart';
import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:my_shop/core/utils/app_colors.dart';
import 'package:my_shop/core/presentation/widgets/gradient_widgets.dart';
import 'package:my_shop/core/localization/app_localizations.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  Map<String, dynamic>? _data;
  DateTimeRange? _selectedDateRange;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    // Mock JSON Data
    _data = {
      "orders": {
        "total": "2,764",
        "trend": "8%",
        "trendPositive": true,
        "last30Days": 2764,
        "previous30Days": 2003,
      },
      "revenue": {
        "total": "฿ 148,320",
        "trend": "31%",
        "trendPositive": true,
        "chartData": [
          {"date": "Feb 16", "value": 3000.0},
          {"date": "Feb 20", "value": 3200.0},
          {"date": "Feb 23", "value": 3600.0},
          {"date": "Feb 25", "value": 3800.0},
          {"date": "Mar 02", "value": 4500.0},
          {"date": "Mar 06", "value": 6200.0},
          {"date": "Mar 11", "value": 10000.0},
        ],
      },
      "newCustomers": {
        "total": "418",
        "trend": "24%",
        "trendPositive": true,
        "adsPromotion": 123,
        "adsPercentage": 28,
        "organic": 457,
        "organicPercentage": 72,
      },
      "orderStatus": {
        "trend": "24%",
        "trendPositive": true,
        "cancelled": 123,
        "cancelledPercentage": 40,
        "completed": 457,
        "completedPercentage": 60,
      },
      "interactions": {
        "total": "18,540",
        "trend": "42%",
        "trendPositive": true,
        "items": [
          {"label": "Menu views", "value": "9,820", "percentage": 0.9},
          {"label": "Add to cart", "value": "4,260", "percentage": 0.5},
          {"label": "Checkout visit", "value": "2,003", "percentage": 0.3},
          {"label": "Ordered", "value": "640", "percentage": 0.15},
          {"label": "Reviews tapped", "value": "500", "percentage": 0.1},
        ],
      },
      "totalCustomers": {
        "total": "6,284",
        "trend": "42%",
        "trendPositive": true,
        "items": [
          {
            "label": "Lunch • 12:00-14:00",
            "value": "9,820",
            "percentage": 0.95,
          },
          {
            "label": "Dinner • 18:00-20:00",
            "value": "4,260",
            "percentage": 0.75,
          },
          {
            "label": "Breakfast • 18:00-20:00",
            "value": "2,003",
            "percentage": 0.4,
          },
        ],
      },
    };

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
    final t = AppLocalizations.of(context);
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
            String rangeText = t?.translate('custom') ?? "Select Dates";
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
                  // Header Indicator & Title
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
                            t?.translate('custom') ?? "Choose Revenue Period",
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
                            t?.translate('cancel').toUpperCase() ?? "CANCEL",
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
      if (mounted) {
        setState(() {
          _selectedDateRange = DateTimeRange(
            start: results[0]!,
            end: results[1]!,
          );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const PhosphorIcon(
            PhosphorIconsRegular.arrowLeft,
            color: Color(0xFF1E293B),
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          t?.translate('analytics') ?? "Analytics",
          style: GoogleFonts.poppins(
            color: const Color(0xFF1E293B),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: TextButton.icon(
              onPressed: () {},
              icon: const PhosphorIcon(
                PhosphorIconsRegular.uploadSimple,
                size: 16,
                color: Color(0xFF64748B),
              ),
              label: Text(
                t?.translate('export') ?? "Export",
                style: GoogleFonts.poppins(
                  color: const Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
              style: TextButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
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
                _buildFilterTab(t?.translate('today') ?? "Today", 0),
                _buildFilterTab(t?.translate('yesterday') ?? "Yesterday", 1),
                _buildFilterTab(t?.translate('this_week') ?? "This Week", 2),
                _buildFilterTab(t?.translate('custom') ?? "Custom", 3),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadData,
              color: AppColors.primary,
              backgroundColor: Colors.white,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
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
          borderRadius: BorderRadius.circular(24),
          border: isSelected ? null : Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: InkWell(
          onTap: () {
            if (index == 3) {
              _showCustomDatePicker();
            }
            _tabController.animateTo(index);
            setState(() {});
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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

  Widget _buildHeader(
    String title,
    String trend,
    bool isPositive, {
    String? subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            PhosphorIcon(
              isPositive
                  ? PhosphorIconsRegular.arrowUp
                  : PhosphorIconsRegular.arrowDown,
              size: 14,
              color: isPositive
                  ? const Color(0xFF22C55E)
                  : const Color(0xFFEF4444),
            ),
            const SizedBox(width: 4),
            Text(
              trend,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isPositive
                    ? const Color(0xFF22C55E)
                    : const Color(0xFFEF4444),
              ),
            ),
            const SizedBox(width: 4),
            if (subtitle != null) ...[
              Text(
                subtitle,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      padding: const EdgeInsets.all(20),
      child: child,
    );
  }

  List<Widget> _buildContent() {
    if (_data == null) return [];
    final t = AppLocalizations.of(context);

    final orders = _data!['orders'];
    final revenue = _data!['revenue'];
    final newCustomers = _data!['newCustomers'];
    final orderStatus = _data!['orderStatus'];
    final interactions = _data!['interactions'];
    final totalCustomers = _data!['totalCustomers'];

    return [
      if (_tabController.index == 3 && _selectedDateRange != null)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
      _buildCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(
              "${orders['total']} ${t?.translate('orders') ?? 'Orders'}",
              orders['trend'],
              orders['trendPositive'],
              subtitle: t?.translate('from_previous_30_days') ?? "from previous 30 days",
            ),
            const SizedBox(height: 24),
            ProgressBarItem(
              label: t?.translate('last_30_days') ?? "Last 30 days",
              value: "2,764",
              percentage: 0.9,
              barGradient: AppColors.primaryGradient,
            ),
            const SizedBox(height: 16),
            ProgressBarItem(
              label: t?.translate('previous_30_days') ?? "Previous 30 days",
              value: "2,003",
              percentage: 0.65,
              barGradient: AppColors.primaryGradient,
            ),
          ],
        ),
      ),
      _buildCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(
              "${revenue['total']} ${t?.translate('total_sales') ?? 'Total Sales'}",
              revenue['trend'],
              revenue['trendPositive'],
              subtitle: t?.translate('from_previous_30_days') ?? "from previous 30 days",
            ),
            const SizedBox(height: 32),
            AnalyticsLineChart(
              spots: (revenue['chartData'] as List).asMap().entries.map((e) {
                return FlSpot(e.key.toDouble(), e.value['value'] as double);
              }).toList(),
              bottomLabels: (revenue['chartData'] as List)
                  .map((e) => e['date'] as String)
                  .toList(),
              maxY: 10000,
            ),
          ],
        ),
      ),
      _buildCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(
              "${newCustomers['total']} ${t?.translate('new_customers') ?? 'New customers'}",
              newCustomers['trend'],
              newCustomers['trendPositive'],
              subtitle: t?.translate('from_previous_28_days') ?? "from previous 28 days",
            ),
            const SizedBox(height: 24),
            AnalyticsDonutChart(
              section1Value: newCustomers['organicPercentage'].toDouble(),
              section2Value: newCustomers['adsPercentage'].toDouble(),
              section1Gradient: AppColors.primaryGradient,
              section2Color: const Color(0xFFFBCFE8),
              section1Label: t?.translate('organic') ?? "Organic",
              section2Label: t?.translate('ads_promotion') ?? "Ads / Promotion",
              centerTitle: "${newCustomers['adsPercentage']}%",
              centerSubtitle: "${newCustomers['adsPromotion']}",
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendDot(
                  t?.translate('ads_promotion') ?? "Ads / Promotion",
                  const Color(0xFFFBCFE8),
                  "${newCustomers['adsPercentage']}%",
                  "${newCustomers['adsPromotion']}",
                ),
                const SizedBox(width: 32),
                _buildLegendDot(
                  t?.translate('organic') ?? "Organic",
                  AppColors.primary,
                  "${newCustomers['organicPercentage']}%",
                  "${newCustomers['organic']}",
                  useGradient: true,
                ),
              ],
            ),
          ],
        ),
      ),
      _buildCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(
              t?.translate('order_status_breakdown') ?? "Order Status Breakdown",
              orderStatus['trend'],
              orderStatus['trendPositive'],
              subtitle: t?.translate('from_previous_28_days') ?? "from previous 28 days",
            ),
            const SizedBox(height: 24),
            AnalyticsDonutChart(
              section1Value: orderStatus['completedPercentage'].toDouble(),
              section2Value: orderStatus['cancelledPercentage'].toDouble(),
              section1Gradient: AppColors.primaryGradient,
              section2Color: const Color(0xFFFBCFE8),
              section1Label: t?.translate('completed') ?? "Completed",
              section2Label: t?.translate('cancelled') ?? "Cancelled",
              centerTitle: "${orderStatus['cancelledPercentage']}%",
              centerSubtitle: "${orderStatus['cancelled']}",
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendDot(
                  t?.translate('cancelled') ?? "Cancelled",
                  const Color(0xFFFBCFE8),
                  "${orderStatus['cancelledPercentage']}%",
                  "${orderStatus['cancelled']}",
                ),
                const SizedBox(width: 32),
                _buildLegendDot(
                  t?.translate('completed') ?? "Completed",
                  AppColors.primary,
                  "${orderStatus['completedPercentage']}%",
                  "${orderStatus['completed']}",
                  useGradient: true,
                ),
              ],
            ),
          ],
        ),
      ),
      _buildCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(
              "${interactions['total']} ${t?.translate('customer_interaction') ?? 'Interactions'}",
              interactions['trend'],
              interactions['trendPositive'],
              subtitle: t?.translate('from_previous_30_days') ?? "from previous 30 days",
            ),
            const SizedBox(height: 24),
            ...List.generate(interactions['items'].length, (index) {
              final item = interactions['items'][index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: ProgressBarItem(
                  label: _translateInteractionLabel(item['label'], t),
                  value: item['value'],
                  percentage: item['percentage'],
                  barGradient: AppColors.primaryGradient,
                ),
              );
            }),
          ],
        ),
      ),
      _buildCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(
              "${totalCustomers['total']} ${t?.translate('new_customers') ?? 'Total customers'}", // Wait, "total_customers" or just "Total customers". Since totalCustomers maps returning vs new, let's fallback to "Total customers".
              totalCustomers['trend'],
              totalCustomers['trendPositive'],
              subtitle: t?.translate('from_previous_30_days') ?? "from previous 30 days",
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                _buildSimpleLegendDot(
                  t?.translate('returning_customers') ?? "Returning customers",
                  AppColors.primary,
                  useGradient: true,
                ),
                const SizedBox(width: 16),
                _buildSimpleLegendDot(t?.translate('new_customers') ?? "New customers", const Color(0xFF22C55E)),
              ],
            ),
            const SizedBox(height: 24),
            ...List.generate(totalCustomers['items'].length, (index) {
              final item = totalCustomers['items'][index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: ProgressBarItem(
                  label: _translatePeakHourLabel(item['label'], t),
                  value: item['value'],
                  percentage: item['percentage'],
                  barGradient: AppColors.primaryGradient,
                ),
              );
            }),
          ],
        ),
      ),
      const SizedBox(height: 40), // Padding for BottomNav
    ];
  }

  Widget _buildLegendDot(
    String label,
    Color color,
    String percent,
    String count, {
    bool useGradient = false,
  }) {
    return Column(
      children: [
        Text(
          percent,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1E293B),
          ),
        ),
        Text(
          count,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: const Color(0xFF64748B),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: useGradient ? null : color,
                gradient: useGradient ? AppColors.primaryGradient : null,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSimpleLegendDot(
    String label,
    Color color, {
    bool useGradient = false,
  }) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: useGradient ? null : color,
            gradient: useGradient ? AppColors.primaryGradient : null,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildSkeletons() {
    return List.generate(
      4,
      (index) => _buildCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Skeleton(width: 150, height: 24),
            const SizedBox(height: 8),
            const Skeleton(width: 200, height: 20),
            const SizedBox(height: 24),
            const Skeleton(
              width: double.infinity,
              height: 160,
              borderRadius: 16,
            ),
          ],
        ),
      ),
    );
  }

  String _translateInteractionLabel(String label, AppLocalizations? t) {
    switch (label) {
      case 'Menu views':
        return t?.translate('menu_views') ?? label;
      case 'Add to cart':
        return t?.translate('add_to_cart') ?? label;
      case 'Checkout visit':
        return t?.translate('checkout_visit') ?? label;
      case 'Ordered':
        return t?.translate('ordered') ?? label;
      case 'Reviews tapped':
        return t?.translate('reviews_tapped') ?? label;
      default:
        return label;
    }
  }

  String _translatePeakHourLabel(String label, AppLocalizations? t) {
    if (label.contains("Lunch")) {
      return label.replaceAll("Lunch", t?.translate('lunch') ?? "Lunch");
    }
    if (label.contains("Dinner")) {
      return label.replaceAll("Dinner", t?.translate('dinner') ?? "Dinner");
    }
    if (label.contains("Breakfast")) {
      return label.replaceAll("Breakfast", t?.translate('breakfast') ?? "Breakfast");
    }
    return label;
  }
}
