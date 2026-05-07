import 'package:flutter/material.dart';
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
    'DELIVERING': 0,
    'DELIVERED': 0,
    'CANCELLED': 0,
  };

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _setupWebSocketListener();
  }

  void _setupWebSocketListener() {
    _socketSubscription = WebSocketService().orderUpdates.listen((event) {
      if (event['order'] != null) {
        final newOrder = OrderModel.fromJson(event['order']);
        _orderUpdatesController.add(newOrder);
      }
    });
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

    if (['PENDING', 'CONFIRMED', 'AWAITING_APPROVAL'].contains(upperStatus)) {
      index = 0;
    } else if ([
      'PAYMENT_SLIP_REQUESTED',
      'PAYMENT_UPLOADED',
      'PAYMENT_VERIFIED',
    ].contains(upperStatus)) {
      index = 1;
    } else if (upperStatus == 'PREPARING') {
      index = 2;
    } else if (upperStatus == 'ON_THE_WAY') {
      index = 3;
    } else if (upperStatus == 'DELIVERED') {
      index = 4;
    } else if (upperStatus == 'CANCELLED') {
      index = 5;
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

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelPadding: const EdgeInsets.symmetric(horizontal: 16),
              labelColor: AppColors.primary,
              unselectedLabelColor: const Color(0xFF94A3B8),
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
                _buildTab('New order', 'NEW', 0),
                _buildTab('Payment', 'PAYMENT', 1),
                _buildTab('Preparing', 'PREPARING', 2),
                _buildTab('Delivering', 'DELIVERING', 3),
                _buildTab('Delivered', 'DELIVERED', 4),
                _buildTab('Cancelled', 'CANCELLED', 5),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                OrderListTabView(
                  tabStatus: 'NEW',
                  orderService: _orderService,
                  updateStream: _orderUpdatesController.stream,
                  refreshStream: _refreshController.stream,
                  onCountUpdated: (count) => _updateTabCount('NEW', count),
                  loadImmediately: true,
                ),
                OrderListTabView(
                  tabStatus: 'PAYMENT',
                  orderService: _orderService,
                  updateStream: _orderUpdatesController.stream,
                  refreshStream: _refreshController.stream,
                  onCountUpdated: (count) => _updateTabCount('PAYMENT', count),
                ),
                OrderListTabView(
                  tabStatus: 'PREPARING',
                  orderService: _orderService,
                  updateStream: _orderUpdatesController.stream,
                  refreshStream: _refreshController.stream,
                  onCountUpdated: (count) =>
                      _updateTabCount('PREPARING', count),
                ),
                OrderListTabView(
                  tabStatus: 'DELIVERING',
                  orderService: _orderService,
                  updateStream: _orderUpdatesController.stream,
                  refreshStream: _refreshController.stream,
                  onCountUpdated: (count) =>
                      _updateTabCount('DELIVERING', count),
                ),
                OrderListTabView(
                  tabStatus: 'DELIVERED',
                  orderService: _orderService,
                  updateStream: _orderUpdatesController.stream,
                  refreshStream: _refreshController.stream,
                  onCountUpdated: (count) =>
                      _updateTabCount('DELIVERED', count),
                ),
                OrderListTabView(
                  tabStatus: 'CANCELLED',
                  orderService: _orderService,
                  updateStream: _orderUpdatesController.stream,
                  refreshStream: _refreshController.stream,
                  onCountUpdated: (count) =>
                      _updateTabCount('CANCELLED', count),
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
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    )
                  : Text(label),
              if (count > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: isSelected ? null : const Color(0xFFE2E8F0),
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
                          : const Color(0xFF64748B),
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

  const OrderListTabView({
    super.key,
    required this.tabStatus,
    required this.orderService,
    required this.updateStream,
    required this.refreshStream,
    required this.onCountUpdated,
    this.loadImmediately = false,
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
  int _page = 0;
  final int _size = 20;
  final ScrollController _scrollController = ScrollController();
  StreamSubscription? _updateSub;
  StreamSubscription? _refreshSub;

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
        if (mounted && _orders.isEmpty && _isLoading) {
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

  void _onOrderUpdated(OrderModel newOrder) {
    if (!mounted) return;

    // Check if the order belongs to this tab
    bool belongsHere = false;
    final upperStatus = newOrder.status.toUpperCase();
    switch (widget.tabStatus) {
      case 'NEW':
        belongsHere = [
          'PENDING',
          'CONFIRMED',
          'AWAITING_APPROVAL',
        ].contains(upperStatus);
        break;
      case 'PAYMENT':
        belongsHere = [
          'PAYMENT_SLIP_REQUESTED',
          'PAYMENT_UPLOADED',
          'PAYMENT_VERIFIED',
        ].contains(upperStatus);
        break;
      case 'PREPARING':
        belongsHere = upperStatus == 'PREPARING';
        break;
      case 'DELIVERING':
        belongsHere = upperStatus == 'ON_THE_WAY';
        break;
      case 'DELIVERED':
        belongsHere = upperStatus == 'DELIVERED';
        break;
      case 'CANCELLED':
        belongsHere = upperStatus == 'CANCELLED';
        break;
    }

    setState(() {
      final index = _orders.indexWhere((o) => o.id == newOrder.id);
      if (index != -1) {
        if (belongsHere) {
          _orders[index] = newOrder; // Update existing
        } else {
          _orders.removeAt(index); // Moved to another tab
        }
      } else if (belongsHere) {
        _orders.insert(0, newOrder); // Add new
      }
    });
    widget.onCountUpdated(_orders.length);
  }

  Future<void> _fetchOrders({bool isRefresh = false}) async {
    if (isRefresh) {
      _page = 0;
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

    final fetchedOrders = await widget.orderService.getOrders(
      tab: widget.tabStatus,
      page: _page,
      size: _size,
    );

    if (!mounted) return;

    if (fetchedOrders == null) {
      setState(() {
        _hasError = isRefresh;
        _isLoading = false;
        _isLoadingMore = false;
      });
      if (!isRefresh) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to load more orders.'),
            backgroundColor: Color(0xFFEF4444),
          ),
        );
      }
      return;
    }

    setState(() {
      if (isRefresh) {
        _orders.clear();
      }
      _orders.addAll(fetchedOrders);
      _hasMore = fetchedOrders.length == _size;
      if (_hasMore) _page++;
      _isLoading = false;
      _isLoadingMore = false;
      _hasError = false;
    });
    widget.onCountUpdated(_orders.length);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return _buildSkeletonList(key: const ValueKey('loading'));
    }

    if (_hasError) {
      return Center(
        key: const ValueKey('error'),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Color(0xFFCBD5E1)),
            const SizedBox(height: 16),
            Text(
              'Failed to load orders',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 16),
            PrimaryGradientButton(
              onPressed: () => _fetchOrders(isRefresh: true),
              text: 'Retry',
              height: 48,
              borderRadius: 12,
            ),
          ],
        ),
      );
    }

    if (_orders.isEmpty) {
      return Center(
        key: const ValueKey('empty'),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: Color(0xFFCBD5E1),
            ),
            const SizedBox(height: 16),
            Text(
              'No orders yet',
              style: GoogleFonts.poppins(
                color: const Color(0xFF94A3B8),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      key: const ValueKey('data'),
      onRefresh: () => _fetchOrders(isRefresh: true),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.only(top: 12, bottom: 20),
        itemCount: _orders.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _orders.length) {
            return const Padding(
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
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFF1F5F9)),
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
                      const SizedBox(height: 8),
                      const Skeleton(width: 60, height: 14),
                    ],
                  ),
                  const Skeleton(width: 100, height: 24),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: const [
                  Skeleton(width: 70, height: 14),
                  SizedBox(width: 12),
                  Skeleton(width: 80, height: 14),
                ],
              ),
              const SizedBox(height: 24),
              const Skeleton(width: double.infinity, height: 40),
              const SizedBox(height: 24),
              const Skeleton(width: double.infinity, height: 16),
              const SizedBox(height: 8),
              const Skeleton(width: 200, height: 16),
              const SizedBox(height: 24),
              const Divider(color: Color(0xFFF1F5F9), height: 1),
              const SizedBox(height: 16),
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
