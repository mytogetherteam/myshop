import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:intl/intl.dart';
import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:my_shop/core/presentation/widgets/skeleton.dart';
import 'package:my_shop/core/presentation/widgets/custom_loading_indicator.dart';
import 'package:my_shop/features/reports/presentation/widgets/best_seller_tile.dart';
import 'package:my_shop/core/utils/app_colors.dart';
import 'package:my_shop/core/presentation/widgets/gradient_widgets.dart';
import 'package:my_shop/core/localization/app_localizations.dart';

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
  final List<String> _filterKeys = ["today", "yesterday", "this_week", "custom"];
  DateTimeRange? _selectedDateRange;

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
      setState(() {
        _selectedDateRange = DateTimeRange(
          start: results[0]!,
          end: results[1]!,
        );
      });
      _loadInitialData();
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
          t?.translate('best_sellers') ?? 'Top Selling items',
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
                      if (index == 3) {
                        if (_selectedDateRange == null) {
                          _showCustomDatePicker();
                        } else {
                          _loadInitialData();
                        }
                      } else {
                        _loadInitialData();
                      }
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
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
                        t?.translate(_filterKeys[index]) ?? _filters[index],
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
          if (_selectedFilterIndex == 3 && _selectedDateRange != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16, left: 20, right: 20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const GradientWidget(
                          child: PhosphorIcon(
                            PhosphorIconsRegular.calendar,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: _showCustomDatePicker,
                          child: GradientText(
                            "${DateFormat('MMM dd, yyyy').format(_selectedDateRange!.start)} - ${DateFormat('MMM dd, yyyy').format(_selectedDateRange!.end)}",
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedDateRange = null;
                              _selectedFilterIndex = 0;
                            });
                            _loadInitialData();
                          },
                          child: const Icon(
                            Icons.close,
                            size: 16,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadInitialData,
              color: const Color(0xFFED3973),
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
                                color: Color(0xFFED3973),
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
