import 'package:flutter/material.dart';
import 'package:my_shop/core/data/services/storage_service.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:my_shop/features/orders/data/models/order_model.dart';
import 'package:my_shop/features/orders/data/services/order_service.dart';
import 'package:my_shop/features/orders/presentation/widgets/order_card.dart';
import 'dart:async';
import 'package:my_shop/core/network/websocket_service.dart';
import 'package:my_shop/core/presentation/widgets/skeleton.dart';
import 'package:my_shop/core/presentation/widgets/primary_gradient_button.dart';
import 'package:my_shop/core/utils/app_colors.dart';
import 'package:my_shop/core/presentation/widgets/gradient_widgets.dart';
import 'package:my_shop/core/presentation/widgets/app_dialog.dart';
import 'package:my_shop/core/utils/app_logger.dart';
import 'package:my_shop/core/localization/app_localizations.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => OrdersScreenState();
}

class OrdersScreenState extends State<OrdersScreen>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late TabController _tabController;
  final OrderService _orderService = OrderService();
  StreamSubscription? _socketSubscription;
  final StreamController<OrderModel> _orderUpdatesController =
      StreamController<OrderModel>.broadcast();
  final StreamController<void> _refreshController =
      StreamController<void>.broadcast();

  final Map<String, int> _tabCounts = {
    'NEW': 0,
    'PAYMENT': 0,
    'PREPARING': 0,
    'READY_FOR_PICKUP': 0,
    'DELIVERING': 0,
    'DELIVERED': 0,
    'PICKED_UP': 0,
    'CANCELED': 0,
  };
  int? _selectedShopId;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 8, vsync: this);
    _setupWebSocketListener();
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    _selectedShopId = await StorageService.instance.getSelectedShopId();
    final tabs = [
      'NEW',
      'PAYMENT',
      'PREPARING',
      'READY_FOR_PICKUP',
      'DELIVERING',
      'DELIVERED',
      'PICKED_UP',
      'CANCELED',
    ];

    final results = await Future.wait(
      tabs.map((tab) => _orderService.getOrders(tab: tab, page: 1, size: 1)),
    );

    if (mounted) {
      setState(() {
        for (int i = 0; i < tabs.length; i++) {
          final result = results[i];
          if (result != null) {
            _tabCounts[tabs[i]] = result.total;
          }
        }
      });
      // Tabs load their own lists independently on init or via lazy loading.
      // We don't call refreshAll() here because it causes a double load.
    }
  }

  void _setupWebSocketListener() {
    _socketSubscription = WebSocketService().orderUpdates.listen((event) {
      if (event['order'] != null) {
        try {
          final newOrder = OrderModel.fromJson(event['order']);
          _orderUpdatesController.add(newOrder);
          // Update tab counts directly from the new order status.
          // Do NOT call _fetchInitialData() here — that triggers full list
          // reloads on every tab which causes duplicate / ghost cards.
          _updateTabCountFromOrder(newOrder);
        } catch (e, stack) {
          AppLogger.realtime('[WS] Failed to parse OrderModel: $e\n$stack');
          if (mounted) {
            AppDialog.showToast(context, 'Parse error: $e', isError: true);
          }
        }
      }
    });
  }

  /// Adjusts the badge counts when an order moves between tabs.
  /// The source tab loses 1 and the destination tab gains 1.
  void _updateTabCountFromOrder(OrderModel order) {
    if (!mounted) return;
    final upperStatus = order.status.toUpperCase();

    // Map the new order status → destination tab key
    String? destTab;
    if (['PENDING', 'REVISED'].contains(upperStatus)) {
      destTab = 'NEW';
    } else if ([
      'PAYMENT_SLIP_REQUESTED',
      'AWAITING_APPROVAL',
      'PAYMENT_VERIFIED',
    ].contains(upperStatus)) {
      destTab = 'PAYMENT';
    } else if (upperStatus == 'COOKING') {
      destTab = 'PREPARING';
    } else if (upperStatus == 'READY_FOR_PICKUP') {
      destTab = 'READY_FOR_PICKUP';
    } else if (upperStatus == 'ON_THE_WAY') {
      destTab = 'DELIVERING';
    } else if (upperStatus == 'DELIVERED') {
      destTab = 'DELIVERED';
    } else if (upperStatus == 'PICKED_UP') {
      destTab = 'PICKED_UP';
    } else if (upperStatus == 'CANCELED') {
      destTab = 'CANCELED';
    }

    // Refresh counts from server in the background (non-blocking, no list reload)
    _fetchInitialData();
  }

  @override
  void dispose() {
    _socketSubscription?.cancel();
    _orderUpdatesController.close();
    _refreshController.close();
    _tabController.dispose();
    super.dispose();
  }

  void switchToStatus(String status) {
    int index = 0;
    final upperStatus = status.toUpperCase();

    if (upperStatus == 'PENDING' || upperStatus == 'REVISED') {
      index = 0;
    } else if ([
      'PAYMENT_SLIP_REQUESTED',
      'AWAITING_APPROVAL',
      'PAYMENT_VERIFIED',
    ].contains(upperStatus)) {
      index = 1;
    } else if (upperStatus == 'COOKING') {
      index = 2;
    } else if (upperStatus == 'READY_FOR_PICKUP') {
      index = 3;
    } else if (upperStatus == 'ON_THE_WAY') {
      index = 4;
    } else if (upperStatus == 'DELIVERED') {
      index = 5;
    } else if (upperStatus == 'PICKED_UP') {
      index = 6;
    } else if (upperStatus == 'CANCELED') {
      index = 7;
    }

    if (_tabController.index != index) {
      _tabController.animateTo(index);
    }
  }

  void _updateTabCount(String tab, int count) {
    if (_tabCounts[tab] != count) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() => _tabCounts[tab] = count);
        }
      });
    }
  }

  void refresh() {
    refreshAll();
  }

  void refreshAll() {
    _refreshController.add(null);
  }

  /// Re-fetches server-side totals for all tab badge counts.
  /// Call this after app resume to catch up with any changes made on other
  /// devices while this device was backgrounded.
  void syncCounts() {
    _fetchInitialData();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final t = AppLocalizations.of(context);
    return Scaffold(
      
      body: Column(
        children: [
          Container(
            color: Theme.of(context).cardColor,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelPadding: const EdgeInsets.symmetric(horizontal: 16),
              labelColor: AppColors.primary,
              unselectedLabelColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              indicatorColor: AppColors.primary,
              indicatorSize: TabBarIndicatorSize.label,
              labelStyle: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              tabs: [
                _buildTab(t?.translate('tab_new') ?? 'New Order', 'NEW', 0),
                _buildTab(t?.translate('tab_payment') ?? 'Payment', 'PAYMENT', 1),
                _buildTab(t?.translate('tab_preparing') ?? 'Preparing', 'PREPARING', 2),
                _buildTab(
                  t?.translate('tab_ready_for_pickup') ?? 'Ready for Pickup',
                  'READY_FOR_PICKUP',
                  3,
                ),
                _buildTab(t?.translate('tab_delivering') ?? 'Delivering', 'DELIVERING', 4),
                _buildTab(t?.translate('tab_delivered') ?? 'Delivered', 'DELIVERED', 5),
                _buildTab(t?.translate('tab_picked_up') ?? 'Picked Up', 'PICKED_UP', 6),
                _buildTab(t?.translate('tab_cancelled') ?? 'Cancelled', 'CANCELED', 7),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                OrderListTabView(
                  key: const ValueKey('NEW'),
                  tabStatus: 'NEW',
                  orderService: _orderService,
                  shopId: _selectedShopId,
                  updateStream: _orderUpdatesController.stream,
                  refreshStream: _refreshController.stream,
                  onCountUpdated: (count) => _updateTabCount('NEW', count),
                  loadImmediately: true,
                ),
                OrderListTabView(
                  key: const ValueKey('PAYMENT'),
                  tabStatus: 'PAYMENT',
                  orderService: _orderService,
                  shopId: _selectedShopId,
                  updateStream: _orderUpdatesController.stream,
                  refreshStream: _refreshController.stream,
                  onCountUpdated: (count) => _updateTabCount('PAYMENT', count),
                  loadImmediately: true,
                ),
                OrderListTabView(
                  key: const ValueKey('PREPARING'),
                  tabStatus: 'PREPARING',
                  orderService: _orderService,
                  shopId: _selectedShopId,
                  updateStream: _orderUpdatesController.stream,
                  refreshStream: _refreshController.stream,
                  onCountUpdated: (count) =>
                      _updateTabCount('PREPARING', count),
                  loadImmediately: true,
                ),
                OrderListTabView(
                  key: const ValueKey('READY_FOR_PICKUP'),
                  tabStatus: 'READY_FOR_PICKUP',
                  orderService: _orderService,
                  shopId: _selectedShopId,
                  updateStream: _orderUpdatesController.stream,
                  refreshStream: _refreshController.stream,
                  onCountUpdated: (count) =>
                      _updateTabCount('READY_FOR_PICKUP', count),
                  loadImmediately: true,
                ),
                OrderListTabView(
                  key: const ValueKey('DELIVERING'),
                  tabStatus: 'DELIVERING',
                  orderService: _orderService,
                  shopId: _selectedShopId,
                  updateStream: _orderUpdatesController.stream,
                  refreshStream: _refreshController.stream,
                  onCountUpdated: (count) =>
                      _updateTabCount('DELIVERING', count),
                  loadImmediately: true,
                ),
                OrderListTabView(
                  key: const ValueKey('DELIVERED'),
                  tabStatus: 'DELIVERED',
                  orderService: _orderService,
                  shopId: _selectedShopId,
                  updateStream: _orderUpdatesController.stream,
                  refreshStream: _refreshController.stream,
                  onCountUpdated: (count) =>
                      _updateTabCount('DELIVERED', count),
                  loadImmediately: true,
                ),
                OrderListTabView(
                  key: const ValueKey('PICKED_UP'),
                  tabStatus: 'PICKED_UP',
                  orderService: _orderService,
                  shopId: _selectedShopId,
                  updateStream: _orderUpdatesController.stream,
                  refreshStream: _refreshController.stream,
                  onCountUpdated: (count) =>
                      _updateTabCount('PICKED_UP', count),
                  loadImmediately: true,
                ),
                OrderListTabView(
                  key: const ValueKey('CANCELED'),
                  tabStatus: 'CANCELED',
                  orderService: _orderService,
                  shopId: _selectedShopId,
                  updateStream: _orderUpdatesController.stream,
                  refreshStream: _refreshController.stream,
                  onCountUpdated: (count) =>
                      _updateTabCount('CANCELED', count),
                  loadImmediately: true,
                ),

              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String label, String tabKey, int index) {
    return AnimatedBuilder(
      animation: _tabController.animation ?? _tabController,
      builder: (context, child) {
        final double animationValue =
            _tabController.animation?.value ?? _tabController.index.toDouble();
        final double diff = (animationValue - index).abs();
        final isSelected = diff < 0.5;
        final count = _tabCounts[tabKey] ?? 0;

        return Tab(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              isSelected
                  ? GradientText(
                      label,
                      style: TextStyle(fontWeight: FontWeight.w600),
                    )
                  : Text(label),
              if (count > 0) ...[
                SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: isSelected ? null : (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                    gradient: isSelected ? AppColors.primaryGradient : null,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$count',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? Colors.white
                          : (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
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

class OrderListTabView extends StatefulWidget {
  final String tabStatus;
  final OrderService orderService;
  final Stream<OrderModel> updateStream;
  final Stream<void> refreshStream;
  final Function(int) onCountUpdated;
  final bool loadImmediately;
  final int? shopId;

  const OrderListTabView({
    super.key,
    required this.tabStatus,
    required this.orderService,
    required this.updateStream,
    required this.refreshStream,
    required this.onCountUpdated,
    this.loadImmediately = true,
    this.shopId,
  });


  @override
  State<OrderListTabView> createState() => _OrderListTabViewState();
}

class _OrderListTabViewState extends State<OrderListTabView>
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

  // Tracks orders that have moved away from this tab via WebSocket.
  // Prevents race conditions where a slow API response tries to re-add
  // the old version of the order.
  final Set<String> _removedOrderIds = {};

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _updateSub = widget.updateStream.listen(_onOrderUpdated);
    _refreshSub = widget.refreshStream.listen(
      (_) => _fetchOrders(isRefresh: true),
    );
    
    if (widget.loadImmediately) {
      _fetchOrders(isRefresh: true);
    } else {
      // Lazy load: fetch when first built OR after a delay to stagger initial requests
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted && _isLoading) {
          _fetchOrders(isRefresh: true);
        }
      });
    }
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
    switch (widget.tabStatus) {
      case 'NEW':
        return ['PENDING', 'REVISED'].contains(upperStatus);
      case 'PAYMENT':
        return ['PAYMENT_SLIP_REQUESTED', 'AWAITING_APPROVAL', 'PAYMENT_VERIFIED']
            .contains(upperStatus);
      case 'PREPARING':
        return upperStatus == 'COOKING';
      case 'READY_FOR_PICKUP':
        return upperStatus == 'READY_FOR_PICKUP';
      case 'DELIVERING':
        return upperStatus == 'ON_THE_WAY';
      case 'DELIVERED':
        return upperStatus == 'DELIVERED';
      case 'PICKED_UP':
        return upperStatus == 'PICKED_UP';
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
        _removedOrderIds.add(newOrder.lastOrderNo); // Track both just in case
      } else {
        _removedOrderIds.remove(newOrder.id);
        _removedOrderIds.remove(newOrder.lastOrderNo);
      }

      // Aggressively remove any existing copy of this order (by id OR orderNo)
      _orders.removeWhere((o) => o.id == newOrder.id || o.lastOrderNo == newOrder.lastOrderNo);

      if (belongsHere) {
        _orders.insert(0, newOrder); // Insert the fresh copy
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

    final result = await widget.orderService.getOrders(
      tab: widget.tabStatus,
      page: _page,
      size: _size,
    );

    if (!mounted) return;

    final t = AppLocalizations.of(context);

    if (result == null) {
      setState(() {
        _hasError = isRefresh;
        _isLoading = false;
        _isLoadingMore = false;
      });
      if (!isRefresh) {
        AppDialog.showToast(context, t?.translate('failed_load_more_orders') ?? 'Failed to load more orders.', isError: true);
      }
      return;
    }

    setState(() {
      if (isRefresh) {
        _orders.clear();
        _removedOrderIds.clear(); // Reset the blacklist on manual full refresh
      }
      // Filter out orders that no longer belong to this tab
      // and orders that have been removed via real-time WebSocket events.
      final filtered = result.orders.where(
        (o) => _belongsToThisTab(o.status) && 
               !_removedOrderIds.contains(o.id) && 
               !_removedOrderIds.contains(o.lastOrderNo),
      ).toList();
      
      // Avoid duplicates: skip orders already in the list by ID or OrderNo
      final existingIds = _orders.map((o) => o.id).toSet();
      final existingNos = _orders.map((o) => o.lastOrderNo).toSet();
      
      _orders.addAll(filtered.where((o) => !existingIds.contains(o.id) && !existingNos.contains(o.lastOrderNo)));
      _hasMore = result.hasMore;
      if (_hasMore) _page++;
      _isLoading = false;
      _isLoadingMore = false;
      _hasError = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return _buildContent();
  }

  Widget _buildContent() {
    final t = AppLocalizations.of(context);

    if (_isLoading) {
      return _buildSkeletonList(key: const ValueKey('loading'));
    }

    if (_hasError) {
      return RefreshIndicator(
        key: const ValueKey('error'),
        color: const Color(0xFFED3973),
        onRefresh: () => _fetchOrders(isRefresh: true),
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: SizedBox(
              height: constraints.maxHeight,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Color(0xFFCBD5E1)),
                    SizedBox(height: 16),
                    Text(
                      t?.translate('failed_load_orders') == 'failed_load_orders' ? 'Failed to Load Orders' : (t?.translate('failed_load_orders') ?? 'Failed to Load Orders'),
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      t?.translate('pull_to_retry') == 'pull_to_retry' ? 'Pull down to retry' : (t?.translate('pull_to_retry') ?? 'Pull down to retry'),
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF94A3B8) : const Color(0xFF94A3B8),
                      ),
                    ),
                    SizedBox(height: 16),
                    PrimaryGradientButton(
                      onPressed: () => _fetchOrders(isRefresh: true),
                      text: t?.translate('retry') == 'retry' ? 'Retry' : (t?.translate('retry') ?? 'Retry'),
                      height: 48,
                      width: 120, // Set to a normal width instead of full width
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
        key: const ValueKey('empty'),
        color: const Color(0xFFED3973),
        onRefresh: () => _fetchOrders(isRefresh: true),
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: SizedBox(
              height: constraints.maxHeight,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.receipt_long_outlined,
                      size: 64,
                      color: Color(0xFFCBD5E1),
                    ),
                    SizedBox(height: 16),
                    Text(
                      t?.translate('no_orders_yet') ?? 'No Orders Yet',
                      style: GoogleFonts.poppins(
                        color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF94A3B8) : const Color(0xFF94A3B8),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      t?.translate('pull_to_refresh') ?? 'Pull down to refresh',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: const Color(0xFFCBD5E1),
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

    return RefreshIndicator(
      key: const ValueKey('data'),
      color: const Color(0xFFED3973),
      onRefresh: () => _fetchOrders(isRefresh: true),
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: 12, bottom: 20),
        itemCount: _orders.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _orders.length) {
            return Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(
                child: CircularProgressIndicator(color: Color(0xFFED3973)),
              ),
            );
          }
          return OrderCard(
            order: _orders[index],
            isPaymentTab: widget.tabStatus == 'PAYMENT',
            isDeliveryTab: widget.tabStatus == 'DELIVERING',
          );
        },
      ),
    );
  }


  Widget _buildSkeletonList({Key? key}) {
    return ListView.builder(
      key: key,
      padding: const EdgeInsets.only(top: 12, bottom: 20),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: (Theme.of(context).brightness == Brightness.dark ? Theme.of(context).cardColor : (Theme.of(context).brightness == Brightness.dark ? Theme.of(context).cardColor : const Color(0xFFF1F5F9)))),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Skeleton(width: 80, height: 20),
                      SizedBox(height: 8),
                      const Skeleton(width: 60, height: 14),
                    ],
                  ),
                  const Skeleton(width: 100, height: 24),
                ],
              ),
              SizedBox(height: 16),
              Row(
                children: const [
                  Skeleton(width: 70, height: 14),
                  SizedBox(width: 12),
                  Skeleton(width: 80, height: 14),
                ],
              ),
              SizedBox(height: 24),
              const Skeleton(width: double.infinity, height: 40),
              SizedBox(height: 24),
              const Skeleton(width: double.infinity, height: 16),
              SizedBox(height: 8),
              const Skeleton(width: 200, height: 16),
              SizedBox(height: 24),
              Divider(color: Theme.of(context).dividerColor.withOpacity(0.3), height: 1),
              SizedBox(height: 16),
              Row(
                children: const [
                  Expanded(child: Skeleton(height: 54)),
                  SizedBox(width: 12),
                  Expanded(flex: 2, child: Skeleton(height: 54)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}