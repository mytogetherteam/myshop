import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_shop/features/orders/data/models/order_model.dart';
import 'package:my_shop/features/orders/data/services/order_service.dart';
import 'package:my_shop/features/orders/presentation/widgets/order_card.dart';
import 'dart:async';
import 'package:my_shop/core/network/websocket_service.dart';
import 'package:my_shop/core/presentation/widgets/skeleton.dart';
import 'package:my_shop/features/notifications/presentation/widgets/notification_badge_icon.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final OrderService _orderService = OrderService();
  List<OrderModel> _allOrders = [];
  bool _isLoading = true;
  StreamSubscription? _socketSubscription;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _tabController.addListener(() {
      // Rebuild to update tab badges color immediately during change
      setState(() {}); 
    });
    _fetchOrders();
    _setupWebSocketListener();
  }

  void _setupWebSocketListener() {
    _socketSubscription = WebSocketService().orderUpdates.listen((event) {
      if (event['order'] != null) {
        final newOrder = OrderModel.fromJson(event['order']);
        setState(() {
          // Update existing order or add new one
          final index = _allOrders.indexWhere((o) => o.id == newOrder.id);
          if (index != -1) {
            _allOrders[index] = newOrder;
          } else {
            _allOrders.insert(0, newOrder);
          }
        });
      }
    });
  }

  Future<void> _fetchOrders() async {
    setState(() => _isLoading = true);
    final orders = await _orderService.getOrders();
    
    if (mounted) {
      if (orders == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to load orders. Please try again.'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
        setState(() => _isLoading = false);
      } else {
        setState(() {
          _allOrders = orders;
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _socketSubscription?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Orders',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1E293B),
          ),
        ),
        centerTitle: false,
        actions: [
          const NotificationBadgeIcon(),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelPadding: const EdgeInsets.symmetric(horizontal: 16),
          labelColor: const Color(0xFFED3A72),
          unselectedLabelColor: const Color(0xFF94A3B8),
          indicatorColor: const Color(0xFFED3A72),
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
            _buildTab('New order', _getCount('NEW'), 0),
            _buildTab('Payment', _getCount('PAYMENT'), 1),
            _buildTab('Preparing', _getCount('PREPARING'), 2),
            _buildTab('Delivering', _getCount('DELIVERING'), 3),
            _buildTab('Delivered', _getCount('DELIVERED'), 4),
            _buildTab('Cancelled', _getCount('CANCELLED'), 5),
          ],
        ),
      ),
      body: _isLoading
          ? _buildSkeletonList()
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOrderList('NEW'),
                _buildOrderList('PAYMENT'),
                _buildOrderList('PREPARING'),
                _buildOrderList('DELIVERING'),
                _buildOrderList('DELIVERED'),
                _buildOrderList('CANCELLED'),
              ],
            ),
    );
  }

  Widget _buildTab(String label, int count, int index) {
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          if (count > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: _tabController.index == index 
                    ? const Color(0xFFED3A72) 
                    : const Color(0xFFE2E8F0),
                shape: BoxShape.circle,
              ),
              child: Text(
                '$count',
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: _tabController.index == index ? Colors.white : const Color(0xFF64748B),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  int _getCount(String tab) {
    switch (tab) {
      case 'NEW':
        return _allOrders
            .where((o) => ['PENDING', 'CONFIRMED', 'AWAITING_APPROVAL'].contains(o.status))
            .length;
      case 'PAYMENT':
        return _allOrders
            .where((o) => ['PAYMENT_SLIP_REQUESTED', 'PAYMENT_UPLOADED', 'PAYMENT_VERIFIED']
                .contains(o.status))
            .length;
      case 'PREPARING':
        return _allOrders.where((o) => o.status == 'PREPARING').length;
      case 'DELIVERING':
        return _allOrders.where((o) => o.status == 'ON_THE_WAY').length;
      case 'DELIVERED':
        return _allOrders.where((o) => o.status == 'DELIVERED').length;
      case 'CANCELLED':
        return _allOrders.where((o) => o.status == 'CANCELLED').length;
      default:
        return 0;
    }
  }

  Widget _buildOrderList(String tab) {
    List<OrderModel> filteredOrders = [];
    switch (tab) {
      case 'NEW':
        filteredOrders = _allOrders
            .where((o) => ['PENDING', 'CONFIRMED', 'AWAITING_APPROVAL'].contains(o.status))
            .toList();
        break;
      case 'PAYMENT':
        filteredOrders = _allOrders
            .where((o) => ['PAYMENT_SLIP_REQUESTED', 'PAYMENT_UPLOADED', 'PAYMENT_VERIFIED']
                .contains(o.status))
            .toList();
        break;
      case 'PREPARING':
        filteredOrders = _allOrders.where((o) => o.status == 'PREPARING').toList();
        break;
      case 'DELIVERING':
        filteredOrders = _allOrders.where((o) => o.status == 'ON_THE_WAY').toList();
        break;
      case 'DELIVERED':
        filteredOrders = _allOrders.where((o) => o.status == 'DELIVERED').toList();
        break;
      case 'CANCELLED':
        filteredOrders = _allOrders.where((o) => o.status == 'CANCELLED').toList();
        break;
    }

    if (filteredOrders.isEmpty) {
      return Center(
        child: Text(
          'No orders yet',
          style: GoogleFonts.poppins(color: const Color(0xFF94A3B8)),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchOrders,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 12, bottom: 20),
        itemCount: filteredOrders.length,
        itemBuilder: (context, index) {
          return OrderCard(order: filteredOrders[index]);
        },
      ),
    );
  }

  Widget _buildSkeletonList() {
    return ListView.builder(
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
              const Row(
                children: [
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
              const Row(
                children: [
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
