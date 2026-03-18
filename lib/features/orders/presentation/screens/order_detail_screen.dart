import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:intl/intl.dart';
import 'package:my_shop/core/network/websocket_service.dart';
import '../../data/models/order_model.dart';
import '../../data/services/order_service.dart';
import '../widgets/status_progress_indicator.dart';
import 'package:my_shop/core/presentation/widgets/custom_loading_indicator.dart';
import 'package:my_shop/core/presentation/widgets/skeleton.dart';

class OrderDetailScreen extends StatefulWidget {
  final OrderModel order;

  const OrderDetailScreen({super.key, required this.order});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  late OrderModel _currentOrder;
  StreamSubscription? _wsSubscription;
  bool _isUpdating = false;
  bool _isFirstLoading = true;

  // Controllers for Confirmation Details
  final _deliveryFeeController = TextEditingController();
  final _deliveryCycleNoController = TextEditingController();
  final _deliveryRiderNameController = TextEditingController();
  final _deliveryPhoneNoController = TextEditingController();
  final _deliveryTrackingUrlController = TextEditingController();
  final _waitingTimeMinutesController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _currentOrder = widget.order;
    _setupWebSocketListener();
    _fetchOrderDetails();
    _initControllers();
  }

  void _initControllers() {
    _deliveryFeeController.text = _currentOrder.deliveryFee.toString();
    _deliveryCycleNoController.text = _currentOrder.deliveryCycleNo ?? '';
    _deliveryRiderNameController.text = _currentOrder.riderName ?? '';
    _deliveryPhoneNoController.text = _currentOrder.riderPhone ?? '';
    _deliveryTrackingUrlController.text = _currentOrder.deliveryTrackingUrl ?? '';
    _waitingTimeMinutesController.text = _currentOrder.waitingTimeMinutes.toString();
  }

  Future<void> _fetchOrderDetails() async {
    setState(() => _isFirstLoading = true);
    final updatedOrder = await OrderService().getOrderDetail(_currentOrder.id);
    if (updatedOrder != null && mounted) {
      setState(() {
        _currentOrder = updatedOrder;
        _initControllers();
        _isFirstLoading = false;
      });
    } else if (mounted) {
      setState(() => _isFirstLoading = false);
    }
  }

  @override
  void dispose() {
    _wsSubscription?.cancel();
    _deliveryFeeController.dispose();
    _deliveryCycleNoController.dispose();
    _deliveryRiderNameController.dispose();
    _deliveryPhoneNoController.dispose();
    _deliveryTrackingUrlController.dispose();
    _waitingTimeMinutesController.dispose();
    super.dispose();
  }

  void _setupWebSocketListener() {
    _wsSubscription = WebSocketService().orderUpdates.listen((event) {
      final orderId = event['orderId']?.toString();
      if (orderId != null && orderId == _currentOrder.id.toString()) {
        debugPrint('Real-time update received for Order ${_currentOrder.id}');
        
        setState(() {
          _isUpdating = true;
          // If the event contains a full order object, we can reconstruct it
          if (event['order'] != null) {
            _currentOrder = OrderModel.fromJson(event['order']);
            _initControllers();
          }
        });

        // Small delay to show the "updated" flash or animation
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            setState(() {
              _isUpdating = false;
            });
          }
        });
      }
    });
  }

  Future<void> _handleStatusUpdate(String newStatus) async {
    setState(() => _isUpdating = true);
    final success = await OrderService().updateOrderStatus(_currentOrder.id.toString(), newStatus);
    
    if (success) {
      // Re-fetch full details to ensure all fields are synchronized
      await _fetchOrderDetails();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update status. Please try again.')),
        );
      }
    }
    
    if (mounted) {
      setState(() => _isUpdating = false);
    }
  }

  Future<void> _handleConfirmOrder() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isUpdating = true);

    final payload = {
      "deliveryFee": double.tryParse(_deliveryFeeController.text) ?? 0,
      "deliveryCycleNo": _deliveryCycleNoController.text,
      "deliveryRiderName": _deliveryRiderNameController.text,
      "deliveryPhoneNo": _deliveryPhoneNoController.text,
      "deliveryTrackingUrl": _deliveryTrackingUrlController.text,
      "waitingTimeMinutes": int.tryParse(_waitingTimeMinutesController.text) ?? 0,
    };

    final success = await OrderService().confirmOrder(_currentOrder.id.toString(), payload);
    
    if (success) {
      await _fetchOrderDetails();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to confirm order. Please try again.')),
        );
      }
    }
    
    if (mounted) {
      setState(() => _isUpdating = false);
    }
  }

  Future<void> _handleVerifyPayment() async {
    setState(() => _isUpdating = true);

    final success = await OrderService().verifyPayment(_currentOrder.id.toString());
    
    if (success) {
      await _fetchOrderDetails();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to verify payment. Please try again.')),
        );
      }
    }
    
    if (mounted) {
      setState(() => _isUpdating = false);
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'MT-${_currentOrder.lastOrderNo}',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1E293B),
              ),
            ),
            Text(
              _currentOrder.statusName,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: const Color(0xFFED3A72),
              ),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () {},
            icon: const Icon(PhosphorIconsRegular.printer, size: 20, color: Color(0xFF94A3B8)),
            label: Text(
              'Print',
              style: GoogleFonts.poppins(
                color: const Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isFirstLoading 
          ? _buildSkeletonDetail()
          : AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: _isUpdating ? 0.6 : 1.0,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    // Scheduled Info if applicable
                    if (_currentOrder.isScheduled) _buildScheduledInfo(),
                    
                    // Customer Section
                    _buildCustomerSection(),
                    const SizedBox(height: 24),
                    
                    // Address Section
                    _buildAddressSection(context),
                    const SizedBox(height: 24),
                    
                    // Rider Section if applicable
                    if (_currentOrder.riderName != null) _buildRiderSection(),
                    
                    // Progress Bar
                    _buildAnimatedProgress(),
                    const SizedBox(height: 12),
                    if (_currentOrder.estimatedDeliveryTime != null)
                      _buildEstimatedTimeBox(),
                    if (_currentOrder.status == 'CANCELLED' && _currentOrder.cancelReason != null)
                      _buildCancelReasonBox(),
                    const SizedBox(height: 32),
                    
                    // Items Ordered
                    _buildItemsSection(),
                    const SizedBox(height: 32),

                    // Payment Slip Section
                    if (_currentOrder.paymentSlipUrl != null) ...[
                      _buildPaymentSlipSection(),
                      const SizedBox(height: 32),
                    ],

                    
                    // Order Modifications
                    if (_currentOrder.modifications.isNotEmpty) _buildModificationsSection(),
                    
                    // Payment Summary
                    _buildPaymentSummary(),
                    const SizedBox(height: 24),
                    
                    // Confirmation Form for Pending Orders
                    if (_currentOrder.status == 'PENDING') ...[
                      _buildConfirmationForm(),
                      const SizedBox(height: 24),
                    ],

                    // Calculate delivery fee box
                    _buildDeliveryCalculator(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
            // Bottom Action Buttons
            _buildBottomActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonDetail() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Row(
            children: [
              const Skeleton.circle(width: 48, height: 48),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Skeleton(width: 120, height: 16),
                  const SizedBox(height: 8),
                  const Skeleton(width: 80, height: 14),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),
          const Skeleton(width: 100, height: 18),
          const SizedBox(height: 12),
          const Skeleton(width: double.infinity, height: 60),
          const SizedBox(height: 32),
          const Skeleton(width: double.infinity, height: 40),
          const SizedBox(height: 32),
          const Skeleton(width: 120, height: 18),
          const SizedBox(height: 16),
          ...List.generate(3, (index) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Skeleton(width: 20, height: 16),
                    const SizedBox(width: 8),
                    const Skeleton(width: 150, height: 16),
                  ],
                ),
                const Skeleton(width: 60, height: 16),
              ],
            ),
          )),
          const SizedBox(height: 32),
          const Skeleton(width: double.infinity, height: 100),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildAnimatedProgress() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 600),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.1, 0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: StatusProgressIndicator(
        key: ValueKey(_currentOrder.status),
        status: _currentOrder.status,
      ),
    );
  }

  Widget _buildEstimatedTimeBox() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDCFCE7)),
      ),
      child: Row(
        children: [
          const Icon(PhosphorIconsRegular.timer, color: Color(0xFF16A34A), size: 20),
          const SizedBox(width: 8),
          Text(
            'Estimated Delivery: ',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF16A34A),
            ),
          ),
          Text(
            _currentOrder.estimatedDeliveryTime!,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF15803D),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCancelReasonBox() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFECDD3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(PhosphorIconsRegular.warningCircle, color: Color(0xFFEF4444), size: 20),
              const SizedBox(width: 8),
              Text(
                'Cancellation Reason',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFB91C1C),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _currentOrder.cancelReason!,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: const Color(0xFF991B1B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerSection() {
    return Row(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFF1F5F9),
            image: _currentOrder.customerAvatar != null
                ? DecorationImage(
                    image: NetworkImage(_currentOrder.customerAvatar!),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: _currentOrder.customerAvatar == null
              ? const Icon(PhosphorIconsRegular.user, color: Color(0xFF94A3B8))
              : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _currentOrder.customerName,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1E293B),
                ),
              ),
              if (_currentOrder.queueNo > 0)
                Text(
                  'Queue No: #${_currentOrder.queueNo}',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF64748B),
                  ),
                ),
            ],
          ),
        ),
        _buildCircularIcon(PhosphorIconsRegular.phone),
        const SizedBox(width: 12),
        _buildCircularIcon(PhosphorIconsRegular.chatCircleText),
      ],
    );
  }

  Widget _buildCircularIcon(IconData icon) {
    return Container(
      width: 44,
      height: 44,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFFF1F5F9),
      ),
      child: Icon(icon, color: const Color(0xFF1E293B), size: 20),
    );
  }

  Widget _buildAddressSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _currentOrder.deliveryAddressTitle,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1E293B),
              ),
            ),
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: _currentOrder.deliveryAddressDetail));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Address copied to clipboard', style: GoogleFonts.poppins()),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1F2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFFECDD3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(PhosphorIconsRegular.copy, size: 14, color: Color(0xFFED3A72)),
                    const SizedBox(width: 4),
                    Text(
                      'Copy',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFED3A72),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          _currentOrder.deliveryAddressDetail,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: const Color(0xFF1E293B),
            height: 1.5,
          ),
        ),
        if (_currentOrder.deliveryAddress?.buildingName != null || _currentOrder.deliveryAddress?.floor != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '${_currentOrder.deliveryAddress?.buildingName ?? ''} ${_currentOrder.deliveryAddress?.floor != null ? "(Floor: ${_currentOrder.deliveryAddress!.floor})" : ""}',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: const Color(0xFF64748B),
              ),
            ),
          ),
        if (_currentOrder.deliveryAddress?.note != null && _currentOrder.deliveryAddress!.note!.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                const Icon(PhosphorIconsRegular.note, size: 16, color: Color(0xFF64748B)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _currentOrder.deliveryAddress!.note!,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildScheduledInfo() {
    final timeStr = _currentOrder.scheduledDeliveryTime != null 
        ? DateFormat('MMM dd, yyyy - hh:mm a').format(_currentOrder.scheduledDeliveryTime!) 
        : '-';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFECDD3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFFFEE2E2),
              shape: BoxShape.circle,
            ),
            child: const Icon(PhosphorIconsRegular.calendarCheck, color: Color(0xFFED3A72), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Scheduled Delivery',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF991B1B),
                  ),
                ),
                Text(
                  timeStr,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: const Color(0xFFB91C1C),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiderSection() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Rider Information',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(PhosphorIconsRegular.bicycle, color: Color(0xFF64748B), size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _currentOrder.riderName ?? 'Assigning Rider...',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    if (_currentOrder.riderPhone != null)
                      Text(
                        _currentOrder.riderPhone!,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                  ],
                ),
              ),
              if (_currentOrder.riderPhone != null)
                _buildCircularIcon(PhosphorIconsRegular.phone),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModificationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Order Modifications',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 16),
        ..._currentOrder.modifications.map((mod) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF7ED),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFFED7AA)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    mod.itemName,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF9A3412),
                    ),
                  ),
                  Text(
                    mod.modificationType,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFC2410C),
                    ),
                  ),
                ],
              ),
              if (mod.reason != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Reason: ${mod.reason}',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: const Color(0xFFC2410C),
                    ),
                  ),
                ),
              const SizedBox(height: 4),
              Text(
                'Modified by ${mod.modifiedBy} • ${DateFormat('hh:mm a').format(mod.createdAt)}',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: const Color(0xFFEA580C),
                ),
              ),
            ],
          ),
        )),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildItemsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Items Ordered',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1E293B),
              ),
            ),
            TextButton.icon(
              onPressed: () {},
              icon: const Icon(PhosphorIconsRegular.pencilSimple, size: 16, color: Color(0xFFED3A72)),
              label: Text(
                'Edit order',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFED3A72),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ..._currentOrder.items.map((item) => _buildOrderItem(item)),
      ],
    );
  }

  Widget _buildOrderItem(OrderItemModel item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: const Color(0xFFFEE2E2),
              image: item.menuItemImageUrl != null
                  ? DecorationImage(
                      image: NetworkImage(item.menuItemImageUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.displayName,
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1E293B),
                            ),
                          ),
                          if (item.secondaryName != null)
                            Text(
                              item.secondaryName!,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Text(
                      '×${item.quantity}',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
                if (item.optionsString != null && item.optionsString!.isNotEmpty)
                  Text(
                    item.optionsString!,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ...item.options.map((opt) => Text(
                      '+ ${opt.name} (+${opt.displayPrice})',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: const Color(0xFF64748B),
                      ),
                    )),
                if (item.specialInstructions != null && item.specialInstructions!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '"${item.specialInstructions}"',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                        color: const Color(0xFFF59E0B),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            item.displayPrice,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSummary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment Summary',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 16),
        _buildSummaryRow('Food Price', '฿ ${_currentOrder.foodPrice.toInt()}'),
        const SizedBox(height: 12),
        Row(
          children: [
            const Icon(PhosphorIconsRegular.bicycle, color: Color(0xFFED3A72), size: 20),
            const SizedBox(width: 8),
            Text(
              'Delivery Fee',
              style: GoogleFonts.poppins(
                fontSize: 15,
                color: const Color(0xFF64748B),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Delivery fee',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFFEF4444),
                ),
              ),
            ),
            const Spacer(),
            Text(
              _currentOrder.displayDeliveryFee.isNotEmpty ? _currentOrder.displayDeliveryFee : '+฿ 0',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFED3A72),
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF94A3B8), size: 20),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Total',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1E293B),
              ),
            ),
            Row(
              children: [
                Text(
                  _currentOrder.displayTotalAmount,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                Text(
                  ' +Delivery Fee',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 15,
            color: const Color(0xFF64748B),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  Widget _buildDeliveryCalculator() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Calculate delivery fee',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildLaunchButton('Bolt', 'assets/icons/bolt_logo.png', const Color(0xFF32BB78)),
              const SizedBox(width: 16),
              _buildLaunchButton('Grab', 'assets/icons/grab_logo.png', const Color(0xFF00B14F)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLaunchButton(String name, String iconPath, Color color) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: name == 'Bolt'
                ? const Text('Bolt', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18))
                : const Text('Grab', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Open $name',
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomActionButtons() {
    String mainButtonText = 'Accept order';
    String? nextStatus;
    bool isCancelable = false;
    VoidCallback? onPressed;

    switch (_currentOrder.status) {
      case 'PENDING':
        mainButtonText = 'Accept order & Send bill';
        onPressed = _isUpdating ? null : _handleConfirmOrder;
        isCancelable = true;
        break;
      case 'PAYMENT_UPLOADED':
        mainButtonText = 'Accept order & Send bill';
        onPressed = _isUpdating ? null : _handleVerifyPayment;
        isCancelable = true;
        break;

      case 'CONFIRMED':
      case 'PREPARING':
        mainButtonText = 'Mark as Ready';
        nextStatus = 'READY_FOR_PICKUP';
        onPressed = _isUpdating ? null : () => _handleStatusUpdate(nextStatus!);
        break;
      case 'READY_FOR_PICKUP':
        mainButtonText = 'Mark as Delivered';
        nextStatus = 'DELIVERED';
        onPressed = _isUpdating ? null : () => _handleStatusUpdate(nextStatus!);
        break;
      case 'DELIVERED':
      case 'CANCELLED':
        return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.black.withValues(alpha: 0.05))),
      ),
      child: Row(
        children: [
              if (isCancelable) ...[
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isUpdating ? null : () => _handleStatusUpdate('CANCELLED'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFED3A72),
                      side: const BorderSide(color: Color(0xFFFEE2E2)),
                      backgroundColor: const Color(0xFFFFF1F2),
                      minimumSize: const Size(0, 54),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: onPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFED3A72),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 54),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isUpdating
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CustomLoadingIndicator(size: 20, color: Colors.white),
                        )
                      : Text(
                          mainButtonText,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildConfirmationForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: const Color(0xFFF8FAFC),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Confirmation Details',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildInputField('Delivery Fee', _deliveryFeeController, keyboardType: TextInputType.number)),
                const SizedBox(width: 12),
                Expanded(child: _buildInputField('Waiting Time (Min)', _waitingTimeMinutesController, keyboardType: TextInputType.number)),
              ],
            ),
            const SizedBox(height: 12),
            _buildInputField('Rider Name', _deliveryRiderNameController),
            const SizedBox(height: 12),
            _buildInputField('Rider Phone', _deliveryPhoneNoController, keyboardType: TextInputType.phone),
            const SizedBox(height: 12),
            _buildInputField('Cycle No / License', _deliveryCycleNoController),
            const SizedBox(height: 12),
            _buildInputField('Tracking URL', _deliveryTrackingUrlController),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField(String label, TextEditingController controller, {TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          style: GoogleFonts.poppins(fontSize: 14),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFED3A72)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentSlipSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Receipt',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1E293B),
              ),
            ),
            Row(
              children: [
                const Icon(PhosphorIconsRegular.qrCode, size: 20, color: Color(0xFF64748B)),
                const SizedBox(width: 8),
                Text(
                  'QR Prompt Pay',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Total',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: const Color(0xFF64748B),
              ),
            ),
            Text(
              _currentOrder.displayTotalAmount,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1E293B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            _currentOrder.paymentSlipUrl!,
            width: double.infinity,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                height: 200,
                color: const Color(0xFFF1F5F9),
                child: const Center(child: CustomLoadingIndicator(size: 24)),
              );
            },
            errorBuilder: (context, error, stackTrace) => Container(
              height: 200,
              color: const Color(0xFFF1F5F9),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Icon(PhosphorIconsRegular.warningCircle, color: Color(0xFF94A3B8), size: 32),

                   SizedBox(height: 8),
                   Text('Failed to load receipt', style: TextStyle(color: Color(0xFF64748B))),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

