import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:intl/intl.dart';
import 'package:my_shop/core/presentation/widgets/animated_ellipsis_text.dart';
import 'package:my_shop/core/network/websocket_service.dart';
import '../../data/models/order_model.dart';
import '../../data/services/order_service.dart';
import '../widgets/status_progress_indicator.dart';
import 'package:my_shop/core/presentation/widgets/custom_loading_indicator.dart';
import 'package:my_shop/core/presentation/widgets/skeleton.dart';
import 'package:my_shop/features/main_navigation/presentation/screens/main_navigation_screen.dart';

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
  final _cancelReasonController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isFormValid = false;

  @override
  void initState() {
    super.initState();
    _currentOrder = widget.order;
    _setupWebSocketListener();
    _fetchOrderDetails();
    _initControllers();
    _addFormListeners();
  }

  void _initControllers() {
    final formatter = NumberFormat('#,##0');
    _deliveryFeeController.text = _currentOrder.deliveryFee > 0 ? formatter.format(_currentOrder.deliveryFee) : _currentOrder.deliveryFee.toString();
    _deliveryCycleNoController.text = _currentOrder.deliveryCycleNo ?? '';
    _deliveryRiderNameController.text = _currentOrder.riderName ?? '';
    _deliveryPhoneNoController.text = (_currentOrder.riderPhone == null || _currentOrder.riderPhone!.isEmpty) ? '+66' : _currentOrder.riderPhone!;
    _deliveryTrackingUrlController.text = _currentOrder.deliveryTrackingUrl ?? '';
    _waitingTimeMinutesController.text = _currentOrder.waitingTimeMinutes.toString();
    _validateFormState();
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
    _cancelReasonController.dispose();
    super.dispose();
  }

  void _addFormListeners() {
    _deliveryFeeController.addListener(_validateFormState);
    _deliveryCycleNoController.addListener(_validateFormState);
    _deliveryRiderNameController.addListener(_validateFormState);
    _deliveryPhoneNoController.addListener(_validateFormState);
    _waitingTimeMinutesController.addListener(_validateFormState);
    _deliveryTrackingUrlController.addListener(_validateFormState);
  }

  void _validateFormState() {
    final fee = _deliveryFeeController.text.replaceAll(',', '');
    final rider = _deliveryRiderNameController.text;
    final phone = _deliveryPhoneNoController.text;
    final cycle = _deliveryCycleNoController.text;

    final thaiPhoneRegex = RegExp(r'^\+66[0-9]{9}$');

    final isValid = fee.isNotEmpty &&
        double.tryParse(fee) != null &&
        rider.isNotEmpty &&
        phone.isNotEmpty &&
        thaiPhoneRegex.hasMatch(phone) &&
        cycle.isNotEmpty;

    if (isValid != _isFormValid) {
      setState(() {
        _isFormValid = isValid;
      });
    }
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

  Future<void> _runOrderAction({
    required Future<dynamic> Function() action,
    String? errorMessage,
  }) async {
    setState(() => _isUpdating = true);
    final result = await action();
    
    bool success = false;
    String? errorDetails;
    
    if (result is bool) {
      success = result;
    } else if (result is Map<String, dynamic>) {
      success = result['success'] == true;
      errorDetails = result['details'];
    }
    
    if (success) {
      await _fetchOrderDetails();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorDetails ?? errorMessage ?? 'Operation failed. Please try again.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.fixed,
        ),
      );
    }
    
    if (mounted) {
      setState(() => _isUpdating = false);
    }
  }

  Future<void> _handleStatusUpdate(String newStatus) async {
    await _runOrderAction(
      action: () => OrderService().updateOrderStatus(_currentOrder.id.toString(), newStatus),
      errorMessage: 'Failed to update status. Please try again.',
    );
  }

  Future<void> _handleConfirmOrder() async {
    if (!_formKey.currentState!.validate()) return;

    final payload = {
      "deliveryFee": double.tryParse(_deliveryFeeController.text.replaceAll(',', '')) ?? 0,
      "deliveryCycleNo": _deliveryCycleNoController.text,
      "deliveryRiderName": _deliveryRiderNameController.text,
      "deliveryPhoneNo": _deliveryPhoneNoController.text,
      "deliveryTrackingUrl": _deliveryTrackingUrlController.text,
      "waitingTimeMinutes": int.tryParse(_waitingTimeMinutesController.text) ?? 0,
    };

    await _runOrderAction(
      action: () => OrderService().confirmOrder(_currentOrder.id.toString(), payload),
      errorMessage: 'Failed to confirm order. Please try again.',
    );
  }

  Future<void> _handleVerifyPayment() async {
    await _runOrderAction(
      action: () => OrderService().verifyPayment(_currentOrder.id.toString()),
      errorMessage: 'Failed to verify payment. Please try again.',
    );
  }

  Future<void> _handlePrepareOrder() async {
    await _runOrderAction(
      action: () => OrderService().prepareOrder(_currentOrder.id.toString()),
      errorMessage: 'Failed to prepare order. Please try again.',
    );
  }

  Future<void> _handleRequestSlip() async {
    final reasonController = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Revise Payment', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Please provide a reason for requesting a new payment slip.', style: GoogleFonts.poppins(fontSize: 14)),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              autofocus: true,
              style: GoogleFonts.poppins(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Enter reason here...',
                hintStyle: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF94A3B8)),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
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
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: Text('Cancel', style: GoogleFonts.poppins(color: const Color(0xFF64748B), fontWeight: FontWeight.w500))
          ),
          TextButton(
            onPressed: () {
              if (reasonController.text.trim().isNotEmpty) {
                Navigator.pop(context, reasonController.text.trim());
              }
            },
            child: Text('Submit', style: GoogleFonts.poppins(color: const Color(0xFFED3A72), fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (reason != null && reason.isNotEmpty) {
      await _runOrderAction(
        action: () => OrderService().requestSlip(_currentOrder.id.toString(), reason),
        errorMessage: 'Failed to request new slip. Please try again.',
      );
    }
  }

  Future<void> _handleCancelOrder() async {
    _cancelReasonController.clear();
    
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Cancel Order',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Are you sure you want to cancel this order? This action cannot be undone.',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Reason for cancellation',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF475569),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _cancelReasonController,
                maxLines: 3,
                style: GoogleFonts.poppins(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Enter reason here...',
                  hintStyle: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[400]),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      child: Text(
                        'No, Go Back',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Yes, Cancel Order',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (result == true) {
      await _runOrderAction(
        action: () => OrderService().cancelOrder(
          _currentOrder.id.toString(),
          _cancelReasonController.text.isEmpty ? null : _cancelReasonController.text,
        ),
        errorMessage: 'Failed to cancel order. Please try again.',
      );
    }
  }

  Future<void> _handleDispatchOrder() async {
    await _runOrderAction(
      action: () => OrderService().dispatchOrder(_currentOrder.id.toString()),
      errorMessage: 'Failed to dispatch order. Please try again.',
    );
  }

  Future<void> _handleCompleteDelivery() async {
    await _runOrderAction(
      action: () => OrderService().completeOrder(
        _currentOrder.id.toString(),
        'test',
      ),
      errorMessage: 'Failed to complete delivery. Please try again.',
    );
  }

  ButtonStyle _getPrimaryButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFFED3A72),
      foregroundColor: Colors.white,
      disabledBackgroundColor: const Color(0xFFF1F5F9),
      disabledForegroundColor: const Color(0xFF94A3B8),
      minimumSize: const Size(0, 54),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  ButtonStyle _getSecondaryButtonStyle() {
    return ElevatedButton.styleFrom(
      foregroundColor: const Color(0xFFED3A72),
      backgroundColor: const Color(0xFFFFF1F2),
      elevation: 0,
      minimumSize: const Size(0, 54),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFFEE2E2)),
      ),
    );
  }




  void _handleBack() {
    Navigator.pop(context, _currentOrder.status);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBack();
      },
      child: Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(PhosphorIconsRegular.arrowLeft, color: Colors.black),
          onPressed: _handleBack,
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
                color: _currentOrder.status == 'CANCELLED' 
                    ? const Color(0xFFEF4444) 
                    : const Color(0xFFED3A72),
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
            // Sticky Progress Bar
            _buildStickyProgress(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
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
                          
                          if (_currentOrder.estimatedDeliveryTime != null && _currentOrder.status != 'CANCELLED')
                            _buildEstimatedTimeBox(),
                          if (_currentOrder.status == 'CANCELLED')
                            _buildCancelReasonBox(),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                    
                    // Confirmation Form for Pending Orders (Full Width)
                    if (_currentOrder.status == 'PENDING') ...[
                      _buildConfirmationForm(),
                      const SizedBox(height: 32),
                    ],

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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

                          // Calculate delivery fee box
                          if (_currentOrder.status != 'CANCELLED') ...[
                            _buildDeliveryCalculator(),
                            const SizedBox(height: 40),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Bottom Action Buttons
            _buildBottomActionButtons(),
          ],
        ),
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

  Widget _buildStickyProgress() {
    if (_currentOrder.status == 'CANCELLED') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF1F2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(PhosphorIconsFill.smileySad, color: Color(0xFFEF4444), size: 24),
            const SizedBox(width: 12),
            Text(
              'Order Cancelled',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFFBE123C),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: _buildAnimatedProgress(),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFECDD3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(PhosphorIconsFill.smileySad, color: Color(0xFFEF4444), size: 24),
              const SizedBox(width: 10),
              Text(
                'Order Cancelled',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFBE123C),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reason:',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF9F1239),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  (_currentOrder.cancelReason != null && _currentOrder.cancelReason!.isNotEmpty)
                      ? _currentOrder.cancelReason!
                      : 'Reason not specified',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: const Color(0xFF9F1239),
                    height: 1.5,
                  ),
                ),
              ],
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
        _buildCircularIcon(PhosphorIconsFill.phone),
        const SizedBox(width: 12),
        _buildCircularIcon(PhosphorIconsFill.chatCircleDots),
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
                _buildCircularIcon(PhosphorIconsFill.phone),
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
            if (_currentOrder.status != 'CANCELLED')
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
              _currentOrder.deliveryFee > 0 ? 'Delivery Fee' : 'Est. Amount',
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
        onPressed = (_isUpdating || !_isFormValid) ? null : _handleConfirmOrder;
        isCancelable = true;
        break;
      case 'PAYMENT_UPLOADED':
        mainButtonText = 'Accept order & Send bill';
        onPressed = _isUpdating ? null : _handleVerifyPayment;
        isCancelable = false;
        break;
      case 'PAYMENT_VERIFIED':
        mainButtonText = 'Accept order to cook';
        onPressed = _isUpdating ? null : _handlePrepareOrder;
        isCancelable = false;
        break;

      case 'CONFIRMED':
      case 'PAYMENT_SLIP_REQUESTED':
        mainButtonText = 'Waiting for payment';
        onPressed = null; // Disabled
        isCancelable = false;
        break;
      case 'PREPARING':
        mainButtonText = 'Picked Up by Rider';
        onPressed = _isUpdating ? null : _handleDispatchOrder;
        isCancelable = false;
        break;
      case 'ON_THE_WAY':
        mainButtonText = 'Delivered';
        onPressed = _isUpdating ? null : _handleCompleteDelivery;
        isCancelable = false;
        break;
      case 'READY_FOR_PICKUP':
        mainButtonText = 'Mark as Delivered';
        nextStatus = 'DELIVERED';
        onPressed = _isUpdating ? null : () => _handleStatusUpdate(nextStatus!);
        isCancelable = false;
        break;
      case 'DELIVERED':
      case 'CANCELLED':
        return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.black.withOpacity(0.05))),
      ),
      child: Row(
        children: [
          if (isCancelable) ...[
            Expanded(
              child: ElevatedButton(
                onPressed: _isUpdating ? null : _handleCancelOrder,
                style: _getSecondaryButtonStyle(),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          if (_currentOrder.status == 'PAYMENT_VERIFIED' || _currentOrder.status == 'PAYMENT_UPLOADED') ...[
            Expanded(
              child: ElevatedButton(
                onPressed: _isUpdating ? null : _handleRequestSlip,
                style: _getSecondaryButtonStyle(),
                child: Text(
                  'Revise',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: onPressed,
              style: _getPrimaryButtonStyle(),
              child: _isUpdating
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CustomLoadingIndicator(size: 20, color: Colors.white),
                    )
                  : (_currentOrder.status == 'CONFIRMED' || _currentOrder.status == 'PAYMENT_SLIP_REQUESTED')
                      ? AnimatedEllipsisText(
                          text: mainButtonText,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: const Color(0xFF94A3B8),
                          ),
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
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
            'Prepare to confirm',
            style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildInputField(
                    'Delivery Fee', 
                    _deliveryFeeController, 
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      ThousandsSeparatorInputFormatter()
                    ],
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Required';
                      final numValue = value.replaceAll(',', '');
                      if (double.tryParse(numValue) == null) return 'Invalid number';
                      return null;
                    },
                  )
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildInputField(
                    'Waiting Time (Min)', 
                    _waitingTimeMinutesController, 
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly]
                  )
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInputField(
              'Rider Name', 
              _deliveryRiderNameController,
              validator: (value) => (value == null || value.isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            _buildInputField(
              'Rider Phone', 
              _deliveryPhoneNoController, 
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9+]')),
              ],
              validator: (value) {
                if (value == null || value.isEmpty || value == '+66') return 'Required';
                // Thai Mobile: +66 + 9 digits (total 12 chars)
                final thaiPhoneRegex = RegExp(r'^\+66[0-9]{9}$');
                if (!thaiPhoneRegex.hasMatch(value)) {
                  return 'Invalid Thai number (+66xxxxxxxxx)';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            _buildInputField(
              'Cycle No / License', 
              _deliveryCycleNoController,
              validator: (value) => (value == null || value.isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            _buildInputField('Tracking URL', _deliveryTrackingUrlController),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField(String label, TextEditingController controller, {TextInputType? keyboardType, String? Function(String?)? validator, List<TextInputFormatter>? inputFormatters}) {
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
          validator: validator,
          inputFormatters: inputFormatters,
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
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.red, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            errorStyle: GoogleFonts.poppins(fontSize: 11, color: Colors.red),
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
                child: Center(child: CustomLoadingIndicator(size: 24)),
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

class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  static const separator = ',';

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    String newValueText = newValue.text.replaceAll(separator, '');

    if (oldValue.text.endsWith(separator) &&
        oldValue.text.length == newValue.text.length + 1) {
      newValueText = newValueText.substring(0, newValueText.length - 1);
    }
    
    int? value = int.tryParse(newValueText);
    if (value == null) {
      return oldValue; // Revert if not a valid integer
    }

    final formatter = NumberFormat('#,##0');
    String newText = formatter.format(value);

    int selectionIndex = newValue.text.length - newValue.selection.extentOffset;

    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset: newText.length - selectionIndex,
      ),
    );
  }
}
