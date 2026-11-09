import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'package:my_shop/core/network/websocket_service.dart';
import 'package:my_shop/core/presentation/widgets/primary_gradient_button.dart';
import 'package:my_shop/core/presentation/widgets/gradient_widgets.dart';
import 'package:my_shop/core/presentation/widgets/skeleton.dart';
import 'package:my_shop/core/utils/app_colors.dart';
import 'package:my_shop/features/orders/data/models/order_model.dart';
import 'package:my_shop/features/orders/data/services/order_service.dart';
import 'package:my_shop/features/orders/presentation/widgets/order_card.dart';
import 'package:my_shop/core/localization/app_localizations.dart';
import 'package:my_shop/core/presentation/widgets/global_modal.dart';
import 'package:my_shop/features/profile/presentation/widgets/language_selector_sheet.dart';

/// Stage metadata model for Focus Mode Order List.
class FocusStageItem {
  final String key;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color primaryColor;

  const FocusStageItem({
    required this.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.primaryColor,
  });
}

/// Screen that displays order cards in the exact same style as the Order Page,
/// opened when a state section is clicked from the Focus Mode Dashboard.
class FocusModeOrderListScreen extends StatefulWidget {
  final String initialStage;
  final bool isSoundEnabled;
  final VoidCallback? onSoundToggle;

  const FocusModeOrderListScreen({
    super.key,
    required this.initialStage,
    this.isSoundEnabled = true,
    this.onSoundToggle,
  });

  @override
  State<FocusModeOrderListScreen> createState() => _FocusModeOrderListScreenState();
}

class _FocusModeOrderListScreenState extends State<FocusModeOrderListScreen>
    with SingleTickerProviderStateMixin {
  final OrderService _orderService = OrderService();
  late TabController _tabController;

  late bool _soundEnabled;
  AudioPlayer? _audioPlayer;
  StreamSubscription? _socketSubscription;
  final StreamController<OrderModel> _orderUpdatesController =
      StreamController<OrderModel>.broadcast();
  final StreamController<void> _refreshController =
      StreamController<void>.broadcast();

  static const List<FocusStageItem> stages = [
    FocusStageItem(
      key: 'NEW',
      title: 'New Orders',
      subtitle: 'To Accept',
      icon: PhosphorIconsFill.bellRinging,
      primaryColor: Color(0xFFEF4444),
    ),
    FocusStageItem(
      key: 'PAYMENT',
      title: 'Payment',
      subtitle: 'Direct / Verify',
      icon: PhosphorIconsFill.creditCard,
      primaryColor: Color(0xFFF59E0B),
    ),
    FocusStageItem(
      key: 'PREPARING',
      title: 'In Kitchen',
      subtitle: 'Cooking',
      icon: PhosphorIconsFill.cookingPot,
      primaryColor: Color(0xFFF97316),
    ),
    FocusStageItem(
      key: 'READY_FOR_PICKUP',
      title: 'Ready',
      subtitle: 'Bagged & Ready',
      icon: PhosphorIconsFill.forkKnife,
      primaryColor: Color(0xFF10B981),
    ),
    FocusStageItem(
      key: 'DELIVERING',
      title: 'On The Way',
      subtitle: 'Rider Dispatched',
      icon: PhosphorIconsFill.moped,
      primaryColor: Color(0xFF06B6D4),
    ),
    FocusStageItem(
      key: 'DELIVERED',
      title: 'Completed',
      subtitle: 'Delivered',
      icon: PhosphorIconsFill.checkCircle,
      primaryColor: Color(0xFF64748B),
    ),
    FocusStageItem(
      key: 'CANCELED',
      title: 'Cancelled',
      subtitle: 'Voided',
      icon: PhosphorIconsFill.xCircle,
      primaryColor: Color(0xFFBE123C),
    ),
  ];

  final Map<String, int> _tabCounts = {
    'NEW': 0,
    'PAYMENT': 0,
    'PREPARING': 0,
    'READY_FOR_PICKUP': 0,
    'DELIVERING': 0,
    'DELIVERED': 0,
    'CANCELED': 0,
  };

  @override
  void initState() {
    super.initState();
    _soundEnabled = widget.isSoundEnabled;

    int initialIndex = stages.indexWhere((s) => s.key == widget.initialStage);
    if (initialIndex < 0) initialIndex = 0;

    _tabController = TabController(
      length: stages.length,
      initialIndex: initialIndex,
      vsync: this,
    );

    _tabController.addListener(() {
      if (mounted) setState(() {});
    });

    _setupWebSocketListener();
    _fetchTabCounts();

    try {
      WakelockPlus.enable();
    } catch (_) {}
  }

  void _setupWebSocketListener() {
    _socketSubscription = WebSocketService().orderUpdates.listen((event) {
      if (!mounted) return;
      if (event['order'] != null) {
        try {
          final order = OrderModel.fromJson(event['order']);
          _orderUpdatesController.add(order);

          final status = order.status.toUpperCase();
          if (status == 'PENDING' || status == 'NEW') {
            _playNewOrderSound();
          }

          _fetchTabCounts();
        } catch (_) {}
      }
    });
  }

  Future<void> _playNewOrderSound() async {
    if (!_soundEnabled) return;
    try {
      _audioPlayer?.stop();
      _audioPlayer?.dispose();
      _audioPlayer = AudioPlayer();
      await _audioPlayer?.play(AssetSource('alert/alert.mp3'));
      Vibration.vibrate(duration: 600);
    } catch (_) {}
  }

  Future<void> _fetchTabCounts() async {
    final counts = await _orderService.getOrderTabCounts();
    if (counts != null && mounted) {
      setState(() {
        counts.forEach((key, val) {
          if (_tabCounts.containsKey(key)) {
            _tabCounts[key] = val;
          }
        });
      });
      return;
    }

    // Fallback count query
    final tabs = ['NEW', 'PAYMENT', 'PREPARING', 'READY_FOR_PICKUP', 'DELIVERING', 'DELIVERED', 'CANCELED'];
    try {
      final results = await Future.wait(
        tabs.map((tab) => _orderService.getOrders(tab: tab, page: 1, size: 1)),
      );
      if (mounted) {
        setState(() {
          for (int i = 0; i < tabs.length; i++) {
            final res = results[i];
            if (res != null) {
              _tabCounts[tabs[i]] = res.total;
            }
          }
        });
      }
    } catch (_) {}
  }

  void _toggleSound() {
    setState(() => _soundEnabled = !_soundEnabled);
    widget.onSoundToggle?.call();
  }

  void _refreshAll() {
    _refreshController.add(null);
    _fetchTabCounts();
  }

  @override
  void dispose() {
    _socketSubscription?.cancel();
    _orderUpdatesController.close();
    _refreshController.close();
    _audioPlayer?.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentStage = stages[_tabController.index];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        body: Column(
          children: [
            // 1. Kitchen Top Command Bar with Back to Dashboard Button (extends behind transparent status bar)
            _buildTopBar(currentStage, isDark),

            // 2. Tab Bar matching Order Page style
            _buildTabBar(isDark),

            // 3. TabBarView with Order Cards
            Expanded(
              child: SafeArea(
                top: false,
                child: TabBarView(
                  controller: _tabController,
                  children: stages.map((stage) {
                    return _FocusOrderListTab(
                      key: ValueKey(stage.key),
                      stageKey: stage.key,
                      orderService: _orderService,
                      updateStream: _orderUpdatesController.stream,
                      refreshStream: _refreshController.stream,
                      onCountUpdated: (count) {
                        if (mounted) {
                          setState(() => _tabCounts[stage.key] = count);
                        }
                      },
                      onOrderMoved: () => _fetchTabCounts(),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(FocusStageItem currentStage, bool isDark) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Row(
            children: [
              // Normal Back Button like others
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                tooltip: 'Back',
                onPressed: () => Navigator.of(context).pop(),
              ),
              const SizedBox(width: 4),

              // Title
              Expanded(
                child: Text(
                  _getStageTitle(currentStage.key, currentStage.title, context),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),

              // Actions
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Refresh Button
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: _refreshAll,
                      child: Container(
                        width: 32,
                        height: 32,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.22),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
                        ),
                        child: const PhosphorIcon(
                          PhosphorIconsRegular.arrowsClockwise,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),

                  // Sound Toggle
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: _toggleSound,
                      child: Container(
                        width: 32,
                        height: 32,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.22),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
                        ),
                        child: PhosphorIcon(
                          _soundEnabled ? PhosphorIconsFill.speakerHigh : PhosphorIconsFill.speakerSlash,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),

                  // Language Switcher Button
                  ValueListenableBuilder<Locale>(
                    valueListenable: LocalizationService.instance.localeNotifier,
                    builder: (context, locale, _) {
                      String langCode = locale.languageCode.toUpperCase();
                      if (locale.languageCode == 'my') langCode = 'MM';
                      return Tooltip(
                        message: 'Language ($langCode)',
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              GlobalModal.show(
                                context: context,
                                child: const LanguageSelectorSheet(),
                              );
                            },
                            child: Container(
                              height: 32,
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.22),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const PhosphorIcon(
                                    PhosphorIconsRegular.globe,
                                    color: Colors.white,
                                    size: 15,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    langCode,
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                ],
              ),
        ],
      ),
    ),
  ),
);
}

  String _getStageTitle(String key, String fallback, BuildContext context) {
    final t = AppLocalizations.of(context);
    switch (key) {
      case 'NEW':
        return t?.translate('tab_new') ?? fallback;
      case 'PAYMENT':
        return t?.translate('tab_payment') ?? fallback;
      case 'PREPARING':
        return t?.translate('tab_preparing') ?? fallback;
      case 'READY_FOR_PICKUP':
        return t?.translate('tab_ready_for_pickup') ?? fallback;
      case 'DELIVERING':
        return t?.translate('tab_delivering') ?? fallback;
      case 'DELIVERED':
        return t?.translate('tab_delivered') ?? fallback;
      case 'CANCELED':
        return t?.translate('tab_cancelled') ?? fallback;
      default:
        return fallback;
    }
  }

  Widget _buildTabBar(bool isDark) {
    return Container(
      color: Theme.of(context).cardColor,
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        labelPadding: const EdgeInsets.symmetric(horizontal: 14),
        labelColor: AppColors.primary,
        unselectedLabelColor: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
        indicatorColor: AppColors.primary,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        tabs: stages.asMap().entries.map((entry) {
          final index = entry.key;
          final stage = entry.value;
          return _buildSingleTab(stage, index, isDark);
        }).toList(),
      ),
    );
  }

  Widget _buildSingleTab(FocusStageItem stage, int index, bool isDark) {
    final title = _getStageTitle(stage.key, stage.title, context);
    return AnimatedBuilder(
      animation: _tabController.animation ?? _tabController,
      builder: (context, child) {
        final double animationValue =
            _tabController.animation?.value ?? _tabController.index.toDouble();
        final double diff = (animationValue - index).abs();
        final isSelected = diff < 0.5;
        final count = _tabCounts[stage.key] ?? 0;

        return Tab(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              isSelected
                  ? GradientText(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    )
                  : Text(title),
              if (count > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isSelected ? null : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                    gradient: isSelected ? AppColors.primaryGradient : null,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$count',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? Colors.white : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// Tab view that renders the order cards using the exact same style as the regular Order Page.
class _FocusOrderListTab extends StatefulWidget {
  final String stageKey;
  final OrderService orderService;
  final Stream<OrderModel> updateStream;
  final Stream<void> refreshStream;
  final Function(int) onCountUpdated;
  final VoidCallback onOrderMoved;

  const _FocusOrderListTab({
    super.key,
    required this.stageKey,
    required this.orderService,
    required this.updateStream,
    required this.refreshStream,
    required this.onCountUpdated,
    required this.onOrderMoved,
  });

  @override
  State<_FocusOrderListTab> createState() => _FocusOrderListTabState();
}

class _FocusOrderListTabState extends State<_FocusOrderListTab>
    with AutomaticKeepAliveClientMixin {
  final List<OrderModel> _orders = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  bool _hasError = false;
  int _page = 1;
  final int _size = 20;
  final ScrollController _scrollController = ScrollController();
  StreamSubscription? _updateSub;
  StreamSubscription? _refreshSub;
  final Set<String> _removedOrderIds = {};

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _updateSub = widget.updateStream.listen(_onOrderUpdated);
    _refreshSub = widget.refreshStream.listen((_) => _fetchOrders(isRefresh: true));
    _fetchOrders(isRefresh: true);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _updateSub?.cancel();
    _refreshSub?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _fetchOrders();
    }
  }

  bool _belongsToThisTab(String status) {
    final upperStatus = status.toUpperCase();
    switch (widget.stageKey) {
      case 'NEW':
        return ['PENDING', 'REVISED', 'NEW'].contains(upperStatus);
      case 'PAYMENT':
        return ['PAYMENT_SLIP_REQUESTED', 'AWAITING_APPROVAL', 'PAYMENT_VERIFIED', 'PAYMENT']
            .contains(upperStatus);
      case 'PREPARING':
        return upperStatus == 'COOKING' || upperStatus == 'PREPARING';
      case 'READY_FOR_PICKUP':
        return upperStatus == 'READY_FOR_PICKUP';
      case 'DELIVERING':
        return upperStatus == 'ON_THE_WAY' || upperStatus == 'DELIVERING';
      case 'DELIVERED':
        return upperStatus == 'DELIVERED' || upperStatus == 'PICKED_UP';
      case 'CANCELED':
        return upperStatus == 'CANCELED';
      default:
        return false;
    }
  }

  void _onOrderUpdated(OrderModel newOrder) {
    if (!mounted) return;
    final belongsHere = _belongsToThisTab(newOrder.status);

    setState(() {
      if (!belongsHere) {
        _removedOrderIds.add(newOrder.id);
        _removedOrderIds.add(newOrder.lastOrderNo);
      } else {
        _removedOrderIds.remove(newOrder.id);
        _removedOrderIds.remove(newOrder.lastOrderNo);
      }

      _orders.removeWhere((o) => o.id == newOrder.id || o.lastOrderNo == newOrder.lastOrderNo);

      if (belongsHere) {
        _orders.insert(0, newOrder);
      }
    });

    widget.onCountUpdated(_orders.length);
  }

  Future<void> _fetchOrders({bool isRefresh = false}) async {
    if (isRefresh) {
      _page = 1;
      _hasMore = true;
      if (mounted) {
        setState(() {
          _isLoading = true;
          _hasError = false;
        });
      }
    } else {
      if (_isLoading || _isLoadingMore || !_hasMore) return;
      if (mounted) setState(() => _isLoadingMore = true);
    }

    try {
      final result = await widget.orderService.getOrders(
        tab: widget.stageKey,
        page: _page,
        size: _size,
      );

      if (!mounted) return;

      if (result == null) {
        setState(() {
          _hasError = isRefresh;
          _isLoading = false;
          _isLoadingMore = false;
        });
        return;
      }

      setState(() {
        if (isRefresh) {
          _orders.clear();
          _removedOrderIds.clear();
        }

        final filtered = result.orders.where(
          (o) => _belongsToThisTab(o.status) &&
                 !_removedOrderIds.contains(o.id) &&
                 !_removedOrderIds.contains(o.lastOrderNo),
        ).toList();

        final existingIds = _orders.map((o) => o.id).toSet();
        final existingNos = _orders.map((o) => o.lastOrderNo).toSet();

        _orders.addAll(
          filtered.where((o) => !existingIds.contains(o.id) && !existingNos.contains(o.lastOrderNo)),
        );

        _hasMore = result.hasMore;
        if (_hasMore) _page++;
        _isLoading = false;
        _isLoadingMore = false;
        _hasError = false;
      });

      widget.onCountUpdated(_orders.length);
    } catch (_) {
      if (mounted) {
        setState(() {
          _hasError = isRefresh;
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return _buildSkeletonList();
    }

    if (_hasError) {
      return RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => _fetchOrders(isRefresh: true),
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: SizedBox(
              height: constraints.maxHeight > 250 ? constraints.maxHeight : 300,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: Color(0xFFCBD5E1)),
                    const SizedBox(height: 16),
                    Text(
                      AppLocalizations.of(context)?.translate('failed_load_orders') ?? 'Failed to Load Orders',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Pull down to retry',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                    const SizedBox(height: 16),
                    PrimaryGradientButton(
                      onPressed: () => _fetchOrders(isRefresh: true),
                      text: AppLocalizations.of(context)?.translate('retry') ?? 'Retry',
                      height: 44,
                      width: 120,
                      borderRadius: 12,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    if (_orders.isEmpty) {
      return RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => _fetchOrders(isRefresh: true),
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: SizedBox(
              height: constraints.maxHeight > 250 ? constraints.maxHeight : 300,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.receipt_long_outlined,
                          size: 38,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppLocalizations.of(context)?.translate('no_orders_yet') ?? 'No Orders Yet',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : const Color(0xFF475569),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Pull down to refresh',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = constraints.maxWidth >= 650;

        if (!isTablet) {
          // Mobile standard order page list
          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () => _fetchOrders(isRefresh: true),
            child: ListView.builder(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(top: 10, bottom: 24),
              itemCount: _orders.length + (_isLoadingMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _orders.length) {
                  return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    ),
                  );
                }
                final order = _orders[index];
                return OrderCard(
                  key: ValueKey(order.id),
                  order: order,
                  isPaymentTab: widget.stageKey == 'PAYMENT',
                  isDeliveryTab: widget.stageKey == 'DELIVERING',
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  onRefresh: () {
                    _fetchOrders(isRefresh: true);
                    widget.onOrderMoved();
                  },
                  onStatusChanged: (_) {
                    _fetchOrders(isRefresh: true);
                    widget.onOrderMoved();
                  },
                );
              },
            ),
          );
        }

        // Tablet 2-column masonry grid
        final colCount = constraints.maxWidth >= 1050 ? 3 : 2;
        final colOrders = List.generate(colCount, (_) => <OrderModel>[]);
        for (int i = 0; i < _orders.length; i++) {
          colOrders[i % colCount].add(_orders[i]);
        }

        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () => _fetchOrders(isRefresh: true),
          child: SingleChildScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(colCount, (colIndex) {
                final list = colOrders[colIndex];
                return Expanded(
                  child: Column(
                    children: list.map((order) {
                      return OrderCard(
                        key: ValueKey(order.id),
                        order: order,
                        isPaymentTab: widget.stageKey == 'PAYMENT',
                        isDeliveryTab: widget.stageKey == 'DELIVERING',
                        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                        onRefresh: () {
                          _fetchOrders(isRefresh: true);
                          widget.onOrderMoved();
                        },
                        onStatusChanged: (_) {
                          _fetchOrders(isRefresh: true);
                          widget.onOrderMoved();
                        },
                      );
                    }).toList(),
                  ),
                );
              }),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSkeletonList() {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 12, bottom: 20),
      itemCount: 4,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Skeleton(height: 20, width: 90, borderRadius: 6),
                  Skeleton(height: 20, width: 70, borderRadius: 6),
                ],
              ),
              const SizedBox(height: 12),
              const Skeleton(height: 14, width: 140, borderRadius: 4),
              const SizedBox(height: 8),
              const Skeleton(height: 14, width: 220, borderRadius: 4),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Skeleton(height: 16, width: 80, borderRadius: 4),
                  Skeleton(height: 36, width: 100, borderRadius: 10),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
