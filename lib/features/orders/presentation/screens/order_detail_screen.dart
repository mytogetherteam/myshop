import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:google_fonts/google_fonts.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:intl/intl.dart';
import 'package:my_shop/core/presentation/widgets/animated_ellipsis_text.dart';
import 'package:my_shop/core/network/websocket_service.dart';
import '../../data/models/order_model.dart';
import '../../data/services/order_service.dart';
import '../widgets/status_progress_indicator.dart';
import 'package:my_shop/core/presentation/widgets/custom_loading_indicator.dart';
import 'package:my_shop/core/presentation/widgets/skeleton.dart';
import 'package:my_shop/core/presentation/widgets/primary_gradient_button.dart';
import 'package:my_shop/core/utils/app_colors.dart';
import 'package:my_shop/core/presentation/widgets/gradient_widgets.dart';
import 'package:my_shop/core/presentation/widgets/app_dialog.dart';
import 'package:my_shop/core/presentation/widgets/global_modal.dart';
import 'package:my_shop/core/localization/app_localizations.dart';
import 'package:my_shop/core/data/services/storage_service.dart';
import 'package:my_shop/features/profile/data/models/rider_model.dart';
import 'package:my_shop/features/profile/data/services/rider_service.dart';
import 'package:my_shop/features/profile/presentation/screens/rider_management_page.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:my_shop/core/presentation/widgets/image_picker_widget.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:my_shop/features/chat/data/models/chat_model.dart';
import 'package:my_shop/features/chat/data/services/chat_service.dart';
import 'package:my_shop/features/chat/presentation/chat_navigation.dart';


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
  String _deliveryOption = 'PREPAID'; // 'PREPAID' (FAST) or 'NORMAL' (FLEXIBLE)
  int? _selectedDriverId;
  List<Rider> _availableDrivers = [];
  XFile? _proofImage;

  // Shop / user info needed to open the RiderFormSheet (add new driver)
  int? _shopId;
  int? _userId;
  bool _isLoadingRiders = false;

  @override
  void initState() {
    super.initState();
    _currentOrder = widget.order;
    _setupWebSocketListener();
    _fetchOrderDetails();
    _initControllers();
    _addFormListeners();
    _loadShopAndUser();
    // Eagerly load the saved drivers so the picker is always populated,
    // regardless of whether the order payload carried any.
    _loadDrivers();
  }

  Future<void> _loadShopAndUser() async {
    _shopId = await StorageService.instance.getSelectedShopId();
    final userInfo = await StorageService.instance.getUserInfo();
    _userId = userInfo?.id;
  }

  Future<void> _loadDrivers() async {
    if (!mounted) return;
    setState(() => _isLoadingRiders = true);
    final riders = await RiderService().getActiveRiders();
    if (mounted) {
      setState(() {
        // Merge so any driver already known from the order (e.g. the assigned
        // one) is preserved even if it isn't in the active list.
        final byId = <int, Rider>{for (final r in _availableDrivers) r.id: r};
        for (final r in riders) {
          byId[r.id] = r;
        }
        _availableDrivers = byId.values.toList();
        _isLoadingRiders = false;
      });
    }
  }

  void _initControllers() {
    final formatter = NumberFormat('#,##0');
    _deliveryFeeController.text = _currentOrder.deliveryFee > 0 ? formatter.format(_currentOrder.deliveryFee) : _currentOrder.deliveryFee.toString();
    _deliveryCycleNoController.text = _currentOrder.deliveryCycleNo ?? '';
    _deliveryRiderNameController.text = _currentOrder.riderName ?? '';
    _deliveryPhoneNoController.text = (_currentOrder.riderPhone == null || _currentOrder.riderPhone!.isEmpty) ? '+66' : _currentOrder.riderPhone!;
    _deliveryTrackingUrlController.text = _currentOrder.deliveryTrackingUrl ?? '';
    _waitingTimeMinutesController.text = _currentOrder.waitingTimeMinutes > 0 
        ? _currentOrder.waitingTimeMinutes.toString() 
        : '';
    _deliveryOption = _currentOrder.deliveryType == 'NORMAL' ? 'NORMAL' : 'PREPAID';
    _validateFormState();
  }

  Future<void> _fetchOrderDetails() async {
    setState(() => _isFirstLoading = true);
    final updatedOrder = await OrderService().getOrderDetail(_currentOrder.id);
    if (updatedOrder != null && mounted) {
      setState(() {
        _currentOrder = updatedOrder;
        _selectedDriverId = updatedOrder.driverId;
        if (updatedOrder.shopDeliveryDrivers.isNotEmpty) {
          _availableDrivers = updatedOrder.shopDeliveryDrivers
              .map((d) => Rider(
                    id: d.id,
                    name: d.name,
                    phone: d.phone,
                    vehicleNo: d.vehicleNo,
                    profileUrl: d.profileUrl,
                    shopId: 0,
                    isActive: d.isActive,
                  ))
              .toList();
        } else {
          _loadDrivers();
        }
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
    final waiting = _waitingTimeMinutesController.text;

    bool isValid = false;

    if (_currentOrder.status == 'PENDING') {
      if (_deliveryOption == 'NORMAL') {
        // Flexible Delivery: only need preparation time
        isValid = waiting.isNotEmpty && int.tryParse(waiting) != null;
      } else {
        // Fast Delivery (PENDING): only need fee + waiting time
        isValid = fee.isNotEmpty &&
          double.tryParse(fee) != null &&
          waiting.isNotEmpty &&
          int.tryParse(waiting) != null;
      }
    } else if (_currentOrder.status == 'AWAITING_APPROVAL') {
      isValid = true;
    } else if (_currentOrder.status == 'COOKING') {
      isValid = _selectedDriverId != null;
    } else {
      isValid = true;
    }

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

  Future<void> _showReviseItemsSheet() async {
    final selectedIds = <int>{};
    final reasonController = TextEditingController();

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Revise unavailable items',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                ..._currentOrder.items.map((item) {
                  return Material(
                    color: Colors.transparent,
                    child: CheckboxListTile(
                      value: selectedIds.contains(item.id),
                      onChanged: (v) {
                        setModalState(() {
                          if (v == true) {
                            selectedIds.add(item.id);
                          } else {
                            selectedIds.remove(item.id);
                          }
                        });
                      },
                      title: Text('${item.quantity}x ${item.displayName}'),
                    ),
                  );
                }),
                TextField(
                  controller: reasonController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Reason',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                PrimaryGradientButton(
                  onPressed: selectedIds.isEmpty || reasonController.text.trim().isEmpty
                      ? null
                      : () => Navigator.pop(ctx, true),
                  text: 'Submit revision',
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (confirmed == true && mounted) {
      await _runOrderAction(
        action: () => OrderService().reviseOrder(
          _currentOrder.id.toString(),
          reviseReason: reasonController.text.trim(),
          unavailableItems: selectedIds.toList(),
        ),
        errorMessage: 'Failed to revise order.',
      );
    }
    reasonController.dispose();
  }

  void _applySelectedDriver(Rider rider) {
    setState(() {
      _selectedDriverId = rider.id;
      _deliveryRiderNameController.text = rider.name;
      final phone = rider.phone?.trim();
      _deliveryPhoneNoController.text =
          (phone == null || phone.isEmpty) ? '+66' : phone;
      _deliveryCycleNoController.text = rider.vehicleNo ?? '';
    });
    _validateFormState();
  }

  void _clearSelectedDriver() {
    setState(() {
      _selectedDriverId = null;
      _deliveryRiderNameController.clear();
      _deliveryPhoneNoController.text = '+66';
      _deliveryCycleNoController.clear();
    });
    _validateFormState();
  }

  void _openAddDriverSheet() {
    if (_shopId == null || _userId == null) {
      AppDialog.showToast(
        context,
        'Shop info is loading. Please try again in a moment.',
        isError: true,
      );
      return;
    }
    GlobalModal.show(
      context: context,
      child: RiderFormSheet(
        shopId: _shopId!,
        userId: _userId!,
        onSaved: (rider) {
          Navigator.pop(context);
          if (!mounted) return;
          setState(() {
            final idx = _availableDrivers.indexWhere((r) => r.id == rider.id);
            if (idx >= 0) {
              _availableDrivers[idx] = rider;
            } else {
              _availableDrivers = [rider, ..._availableDrivers];
            }
          });
          _applySelectedDriver(rider);
        },
      ),
    );
  }

  Future<void> _openDriverPicker() async {
    // Always ensure the list is loaded before opening so the sheet never shows
    // an empty/blank state due to a skipped or in-flight load.
    if (_availableDrivers.isEmpty) {
      await _loadDrivers();
    }
    if (!mounted) return;

    final selected = await showModalBottomSheet<Rider?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Row(
                    children: [
                      Text(
                        'Select Driver',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () {
                          Navigator.pop(sheetContext);
                          _openAddDriverSheet();
                        },
                        icon: const GradientWidget(
                          child: Icon(PhosphorIconsRegular.plus, size: 16),
                        ),
                        label: GradientText(
                          'Add new',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_isLoadingRiders)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: CustomLoadingIndicator(size: 24),
                  )
                else if (_availableDrivers.isEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                    child: Column(
                      children: [
                        const Icon(
                          PhosphorIconsRegular.users,
                          size: 48,
                          color: Color(0xFFCBD5E1),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No saved drivers yet',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF475569),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tap "Add new" to save a driver for next time.',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: const Color(0xFF94A3B8),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                      itemCount: _availableDrivers.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (_, index) {
                        final rider = _availableDrivers[index];
                        final isSelected = _selectedDriverId == rider.id;
                        return _buildDriverTile(
                          rider,
                          isSelected: isSelected,
                          onTap: () => Navigator.pop(sheetContext, rider),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );

    if (selected != null) {
      _applySelectedDriver(selected);
    }
  }

  Widget _buildDriverTile(
    Rider rider, {
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.06)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.5)
                : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              child: rider.profileUrl != null && rider.profileUrl!.isNotEmpty
                  ? ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: rider.profileUrl!,
                        width: 44,
                        height: 44,
                        fit: BoxFit.cover,
                        placeholder: (_, _) =>
                            const Icon(PhosphorIconsRegular.user, size: 20),
                        errorWidget: (_, _, _) => const Icon(
                          PhosphorIconsRegular.user,
                          size: 20,
                          color: AppColors.primary,
                        ),
                      ),
                    )
                  : const Icon(
                      PhosphorIconsRegular.user,
                      size: 20,
                      color: AppColors.primary,
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rider.name,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  if (rider.phone != null && rider.phone!.isNotEmpty)
                    Text(
                      rider.phone!,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  if (rider.vehicleNo != null && rider.vehicleNo!.isNotEmpty)
                    Text(
                      'Plate: ${rider.vehicleNo}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                PhosphorIconsRegular.checkCircle,
                color: AppColors.primary,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDriverPicker({bool required = true}) {
    final selected = _selectedDriverId == null
        ? null
        : _availableDrivers.firstWhere(
            (r) => r.id == _selectedDriverId,
            orElse: () => Rider(id: -1, name: '', shopId: 0),
          );
    final hasSelection = selected != null && selected.id != -1;
    final displayName = hasSelection ? selected.name : 'Choose a saved driver';
    final subtitle = hasSelection
        ? [
            (selected.phone ?? '').trim(),
            (selected.vehicleNo ?? '').trim(),
          ].where((s) => s.isNotEmpty).join(' • ')
        : 'or add a new one';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          required ? 'Driver *' : 'Driver',
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: _openDriverPicker,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: hasSelection
                          ? AppColors.primary.withValues(alpha: 0.4)
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const GradientWidget(
                          child: Icon(PhosphorIconsFill.moped, size: 18),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: hasSelection
                                    ? const Color(0xFF1E293B)
                                    : const Color(0xFF94A3B8),
                              ),
                            ),
                            if (subtitle.isNotEmpty)
                              Text(
                                subtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: const Color(0xFF94A3B8),
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (hasSelection)
                        GestureDetector(
                          onTap: _clearSelectedDriver,
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4),
                            child: Icon(
                              PhosphorIconsRegular.x,
                              size: 16,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        )
                      else if (_isLoadingRiders)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CustomLoadingIndicator(size: 16),
                        )
                      else
                        const Icon(
                          PhosphorIconsRegular.caretDown,
                          size: 16,
                          color: Color(0xFF94A3B8),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: _openAddDriverSheet,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      PhosphorIconsRegular.plus,
                      size: 16,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'New',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showDemoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Image.asset('assets/images/app_logo.png', width: 24, height: 24),
            const SizedBox(width: 8),
            Text(
              'MyTogether',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: const Color(0xFF1E293B),
              ),
            ),
          ],
        ),
        content: Text(
          'This feature is currently unavailable in demo app.',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: const Color(0xFF475569),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: GoogleFonts.poppins(
                color: const Color(0xFFED3973),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _runOrderAction({
    required Future<dynamic> Function() action,
    String? errorMessage,
    VoidCallback? onSuccess,
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
      if (onSuccess != null) onSuccess();
    } else if (mounted) {
      AppDialog.showToast(context, errorDetails ?? errorMessage ?? 'Operation failed. Please try again.', isError: true);
    }
    
    if (mounted) {
      setState(() => _isUpdating = false);
    }
  }



  Future<void> _handleConfirmOrder() async {
    if (_deliveryOption == 'PREPAID' && !_formKey.currentState!.validate()) return;

    final orderDeliveryType = _deliveryOption == 'NORMAL' ? 'FLEXIBLE' : 'FAST';

    await _runOrderAction(
      action: () => OrderService().confirmOrder(
        _currentOrder.id.toString(),
        orderDeliveryType: orderDeliveryType,
        deliveryFee: double.tryParse(_deliveryFeeController.text.replaceAll(',', '')) ?? 0,
        waitingTimeMinutes: int.tryParse(_waitingTimeMinutesController.text) ?? 0,
        driverId: _selectedDriverId,
      ),
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
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Image.asset('assets/images/app_logo.png', width: 24, height: 24),
            const SizedBox(width: 8),
            Text(
              'Revise Payment',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: const Color(0xFF1E293B),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Please provide a reason for requesting a new payment slip.',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: const Color(0xFF475569),
              ),
            ),
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
                  borderSide: BorderSide(color: AppColors.primary),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(
                color: const Color(0xFF475569),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              if (reasonController.text.trim().isNotEmpty) {
                Navigator.pop(context, reasonController.text.trim());
              }
            },
            child: Text(
              'Submit',
              style: GoogleFonts.poppins(
                color: const Color(0xFFED3973),
                fontWeight: FontWeight.w600,
              ),
            ),
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
    final t = AppLocalizations.of(context);
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
                t?.translate('cancel_order') ?? 'Cancel Order',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                t?.translate('cancel_order_confirm') ?? 'Are you sure you want to cancel this order? This action cannot be undone.',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                t?.translate('cancel_reason') ?? 'Reason for Cancellation',
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
                  hintText: t?.translate('cancel_reason_hint') ?? 'Enter reason here...',
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
                  child: PrimaryGradientButton(
                    onPressed: () => Navigator.pop(context, false),
                    height: 52,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF8FAFC), Color(0xFFF8FAFC)],
                    ),
                    child: Text(
                      t?.translate('no_go_back') ?? 'No, Go Back',
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
                  child: PrimaryGradientButton(
                    onPressed: () => Navigator.pop(context, true),
                    height: 52,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFEF4444), Color(0xFFEF4444)],
                    ),
                    child: Text(
                      t?.translate('yes_cancel_order') ?? 'Yes, Cancel Order',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
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
    if (_selectedDriverId == null) {
      AppDialog.showToast(context, 'Please select a delivery driver', isError: true);
      return;
    }

    XFile? proofFile;
    if (_proofImage != null) {
      proofFile = _proofImage;
    }

    await _runOrderAction(
      action: () => OrderService().dispatchOrder(
        _currentOrder.id.toString(),
        driverId: _selectedDriverId!,
        trackingUrl: _deliveryTrackingUrlController.text.isNotEmpty
            ? _deliveryTrackingUrlController.text
            : null,
        proofImage: proofFile,
      ),
      errorMessage: 'Failed to dispatch order. Please try again.',
    );
  }

  Future<void> _handleCompleteDelivery() async {
    await _runOrderAction(
      action: () => OrderService().completeOrder(_currentOrder.id.toString()),
      errorMessage: 'Failed to complete delivery. Please try again.',
      onSuccess: () {
        AppDialog.showSuccessDialog(
          context,
          message: 'The order MT-${_currentOrder.lastOrderNo} has been successfully delivered and completed.',
        );
      },
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
          icon: const Icon(Icons.arrow_back, color: Colors.black),
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
            _currentOrder.status == 'CANCELED' 
                ? Text(
                    _currentOrder.statusName,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFFEF4444),
                    ),
                  )
                : GradientText(
                    _currentOrder.statusName,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
          ],
        ),
        actions: const [
          SizedBox(width: 8),
        ],
      ),
      body: _isFirstLoading 
          ? _buildSkeletonDetail()
          : AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: _isUpdating ? 0.6 : 1.0,
        child: Column(
          children: [
            // Fixed Header Section (Info + Status)
            Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildCustomerSection(),
                        const SizedBox(height: 16),
                        _buildAddressSection(context),
                      ],
                    ),
                  ),
                  _buildStickyProgress(),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    // Items Ordered (Padded)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          _buildItemsSection(),
                          const SizedBox(height: 24),
                          const Divider(color: Color(0xFFF1F5F9), thickness: 1.5),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Confirmation Form (Full Width - it has its own internal padding)
                    if (_currentOrder.status == 'PENDING' ||
                        _currentOrder.status == 'COOKING') ...[
                      _buildConfirmationForm(),
                      const SizedBox(height: 8),
                    ],

                    // Waiting Time Update (PREPARING state only for Fast Delivery)
                    if (_currentOrder.status == 'COOKING' && _currentOrder.deliveryType == 'PREPAID') ...[
                      _buildWaitingTimeUpdate(),
                      const SizedBox(height: 8),
                    ],
                    
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Scheduled Info if applicable
                          if (_currentOrder.isScheduled) _buildScheduledInfo(),
                          
                          // Rider Section if applicable
                          if (_currentOrder.riderName != null && _currentOrder.riderName!.trim().isNotEmpty) _buildRiderSection(),
                          
                          if (_currentOrder.status == 'CANCELED')
                            _buildCancelReasonBox(),
                          
                          if (_currentOrder.isScheduled || 
                              (_currentOrder.riderName != null && _currentOrder.riderName!.trim().isNotEmpty) ||
                              _currentOrder.status == 'CANCELED')
                            const SizedBox(height: 16),

                          // Payment Slip Section
                          if (_currentOrder.paymentSlipUrl != null) ...[
                            _buildPaymentSlipSection(),
                            const SizedBox(height: 16),
                          ],

                          // Rider Info Form — shown below slip for Fast Delivery payment state
                          if (_currentOrder.status == 'AWAITING_APPROVAL') ...[
                            _buildConfirmationForm(),
                            const SizedBox(height: 16),
                          ],
                          
                          // Order Modifications
                          if (_currentOrder.modifications.isNotEmpty) ...[
                            _buildModificationsSection(),
                            const SizedBox(height: 12),
                          ],
                          
                          // Estimated Time
                          if (_currentOrder.estimatedDeliveryTime != null && _currentOrder.estimatedDeliveryTime!.isNotEmpty && _currentOrder.status != 'CANCELED') ...[
                            _buildEstimatedTimeBox(),
                            const SizedBox(height: 24),
                          ],

                          // Payment Summary
                          _buildPaymentSummary(),
                          const SizedBox(height: 32),

                          // Calculate delivery fee box (hidden for DELIVERED & CANCELLED)
                          if (_currentOrder.status != 'CANCELED' && _currentOrder.status != 'DELIVERED') ...[
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
    final t = AppLocalizations.of(context);
    if (_currentOrder.status == 'CANCELED') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF1F2),
        ),
        child: Row(
          children: [
            const Icon(PhosphorIconsFill.smileySad, color: Color(0xFFEF4444), size: 24),
            const SizedBox(width: 12),
            Text(
              t?.translate('order_cancelled') ?? 'Order Cancelled',
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
            'Est Waiting Time: ',
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
        color: AppColors.errorContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.errorLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(PhosphorIconsFill.smileySad, color: AppColors.error, size: 24),
              const SizedBox(width: 10),
              GradientText(
                'Order Cancelled',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.5),

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
                    color: AppColors.error,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  (_currentOrder.cancelReason != null && _currentOrder.cancelReason!.isNotEmpty)
                      ? _currentOrder.cancelReason!
                      : 'Reason not specified',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: AppColors.error,
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
            color: AppColors.surfaceVariant,
            image: _currentOrder.customerAvatar != null
                ? DecorationImage(
                    image: NetworkImage(_currentOrder.customerAvatar!),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: _currentOrder.customerAvatar == null
              ? const Icon(PhosphorIconsRegular.user, color: AppColors.outline)
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
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (_currentOrder.queueNo > 0)
                Text(
                  'Queue No: #${_currentOrder.queueNo}',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
        _buildCircularIcon(PhosphorIconsFill.phone, onTap: _callCustomer),
        const SizedBox(width: 12),
        _buildCircularIcon(PhosphorIconsFill.chatCircleDots,
            onTap: _openCustomerChat),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: () {
            Clipboard.setData(ClipboardData(
                text: '${_currentOrder.customerName}\n${_currentOrder.customerPhone}'));
            AppDialog.showToast(context, 'Customer info copied to clipboard');
          },
          child: Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surfaceVariant,
            ),
            child: const Icon(PhosphorIconsRegular.copy,
                color: AppColors.onSurface, size: 20),
          ),
        ),
      ],
    );
  }

  Future<void> _callCustomer() async {
    final phone = _currentOrder.customerPhone.trim();
    if (phone.isEmpty || phone == '-') {
      AppDialog.showToast(context, 'No phone number available', isError: true);
      return;
    }
    final uri = Uri(scheme: 'tel', path: phone);
    try {
      final launched =
          await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && mounted) {
        AppDialog.showToast(context, 'Could not open dialer', isError: true);
      }
    } catch (_) {
      if (mounted) {
        AppDialog.showToast(context, 'Could not open dialer', isError: true);
      }
    }
  }

  Future<void> _openCustomerChat() async {
    final orderId = int.tryParse(_currentOrder.id) ?? 0;
    if (orderId <= 0) {
      AppDialog.showToast(context, 'Chat unavailable for this order',
          isError: true);
      return;
    }

    var conversation = await ChatService.instance.getConversationByOrder(orderId);
    if (!mounted) return;

    // No conversation yet — open a fresh one; the first message creates it.
    final chatConversation = conversation ?? ChatConversation(
      id: 0,
      orderId: orderId,
      name: _currentOrder.customerName,
      orderNo: _currentOrder.lastOrderNo,
      orderStatus: _currentOrder.status,
      lastMessage: '',
      timestamp: DateTime.now(),
    );

    if (!mounted) return;
    await ChatNavigation.open(context, chatConversation);
  }

  Widget _buildCircularIcon(IconData icon, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap ?? _showDemoDialog,
      child: Container(
        width: 44,
        height: 44,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.surfaceVariant,
        ),
        child: Icon(icon, color: AppColors.onSurface, size: 20),
      ),
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
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
              ),
            ),
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: _currentOrder.deliveryAddressDetail));
                AppDialog.showToast(context, 'Address copied to clipboard');
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.errorContainer,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.errorLight),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GradientWidget(child: const Icon(PhosphorIconsRegular.copy, size: 14)),
                    const SizedBox(width: 4),
                    GradientText(
                      'Copy',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
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
            fontSize: 12,
            color: AppColors.onSurfaceVariant,
            height: 1.5,
          ),
        ),
        if (_currentOrder.deliveryAddress?.buildingName != null || _currentOrder.deliveryAddress?.floor != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '${_currentOrder.deliveryAddress?.buildingName ?? ''} ${_currentOrder.deliveryAddress?.floor != null ? "(Floor: ${_currentOrder.deliveryAddress!.floor})" : ""}',
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
        if (_currentOrder.deliveryAddress?.note != null && _currentOrder.deliveryAddress!.note!.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.outlineVariant),
            ),
            child: Row(
              children: [
                const Icon(PhosphorIconsRegular.note, size: 16, color: AppColors.onSurfaceVariant),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _currentOrder.deliveryAddress!.note!,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: AppColors.onSurfaceVariant,
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
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.errorContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.errorLight),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: AppColors.errorContainer,
              shape: BoxShape.circle,
            ),
            child: const GradientWidget(child: Icon(PhosphorIconsRegular.calendarCheck, size: 20)),
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
                    color: AppColors.error,
                  ),
                ),
                Text(
                  timeStr,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: AppColors.error,
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
    final name = _currentOrder.riderName ?? 'Assigning Rider...';
    final phone = _currentOrder.riderPhone;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const GradientWidget(
              child: Icon(
                PhosphorIconsFill.moped,
                size: 28,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.onSurface,
                  ),
                ),
                if (phone != null && phone.isNotEmpty)
                  Text(
                    phone,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                if (_currentOrder.deliveryCycleNo != null && _currentOrder.deliveryCycleNo!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: GradientText(
                      'Vehicle No: ${_currentOrder.deliveryCycleNo!}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (phone != null && phone.isNotEmpty)
            _buildCircularIcon(PhosphorIconsFill.phone),
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
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        ..._currentOrder.modifications.map((mod) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.warningContainer,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.warningLight),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GradientText(
                    'Update',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
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
        const SizedBox(height: 16),
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
            if (_currentOrder.status == 'PENDING' ||
                _currentOrder.status == 'PAYMENT_SLIP_REQUESTED' ||
                _currentOrder.status == 'AWAITING_APPROVAL')
              Row(
                children: [
                  TextButton.icon(
                    onPressed: _showReviseItemsSheet,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    icon: const GradientWidget(child: Icon(PhosphorIconsRegular.warning, size: 16)),
                    label: GradientText(
                      'Revise items',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  TextButton.icon(
                    onPressed: _showDemoDialog,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: const GradientWidget(child: Icon(PhosphorIconsRegular.pencilSimple, size: 16)),
                label: GradientText(
                  'Edit order',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                  ),
                ],
              ),
          ],
        ),
        const SizedBox(height: 16),
        for (int i = 0; i < _currentOrder.items.length; i++)
          _buildOrderItem(_currentOrder.items[i], isLast: i == _currentOrder.items.length - 1),
      ],
    );
  }

  Widget _buildOrderItem(OrderItemModel item, {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '×${item.quantity}',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: const Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(height: 2),
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
            const GradientWidget(child: Icon(PhosphorIconsFill.moped, size: 20)),
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
                _currentOrder.deliveryType == 'NORMAL' ? 'Estimate' : 'Delivery fee',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFFEF4444),
                ),
              ),
            ),
            const Spacer(),
            GradientText(
              _currentOrder.displayDeliveryFee.isNotEmpty ? _currentOrder.displayDeliveryFee : '+฿ 0',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
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
                  '฿ ${(_currentOrder.foodPrice + _currentOrder.deliveryFee).toInt()}',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E293B),
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
    return InkWell(
      onTap: _showDemoDialog,
      borderRadius: BorderRadius.circular(12),
      child: Column(
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
      ),
    );
  }

  Widget _buildBottomActionButtons() {
    final t = AppLocalizations.of(context);
    String mainButtonText = 'Accept order';
    bool isCancelable = false;
    VoidCallback? onPressed;

    switch (_currentOrder.status) {
      case 'PENDING':
        mainButtonText = 'Accept order & Send bill';
        onPressed = (_isUpdating || !_isFormValid) ? null : _handleConfirmOrder;
        isCancelable = true;
        break;
      case 'AWAITING_APPROVAL':
        mainButtonText = 'Confirm Payment';
        onPressed = _isUpdating ? null : _handleVerifyPayment;
        isCancelable = false;
        break;
      case 'PAYMENT_VERIFIED':
        mainButtonText = 'Accept order to cook';
        onPressed = _isUpdating ? null : _handlePrepareOrder;
        isCancelable = false;
        break;
      case 'PAYMENT_SLIP_REQUESTED':
        mainButtonText = 'Waiting for payment';
        onPressed = null;
        isCancelable = false;
        break;
      case 'COOKING':
        mainButtonText = 'Picked Up by Rider';
        onPressed = (_isUpdating || _selectedDriverId == null)
            ? null
            : _handleDispatchOrder;
        isCancelable = false;
        break;
      case 'ON_THE_WAY':
        mainButtonText = 'Delivered';
        onPressed = _isUpdating ? null : _handleCompleteDelivery;
        isCancelable = false;
        break;
      case 'DELIVERED':
        return _buildDeliveredBanner();
      case 'CANCELED':
        return const SizedBox.shrink();
      case 'REVISED':
        mainButtonText = 'View Details';
        onPressed = null;
        isCancelable = false;
        break;
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.black.withValues(alpha: 0.05))),

      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (isCancelable) ...[
                Expanded(
                  child: PrimaryGradientButton(
                    onPressed: _isUpdating ? null : _handleCancelOrder,
                    height: 54,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFF1F2), Color(0xFFFFF1F2)],
                    ),
                    child: GradientText(
                      t?.translate('cancel') ?? 'Cancel',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600, 
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              if (_currentOrder.status == 'PAYMENT_VERIFIED' || _currentOrder.status == 'AWAITING_APPROVAL') ...[
                Expanded(
                  child: PrimaryGradientButton(
                    onPressed: _isUpdating ? null : _handleRequestSlip,
                    height: 54,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFF1F2), Color(0xFFFFF1F2)],
                    ),
                    child: GradientText(
                      'Revise',
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
                child: PrimaryGradientButton(
                  onPressed: onPressed,
                  isLoading: _isUpdating,
                  child: (_currentOrder.status == 'PAYMENT_SLIP_REQUESTED')
                      ? AnimatedEllipsisText(
                          text: mainButtonText,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          mainButtonText,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveredBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle_rounded, color: Colors.white, size: 22),
          const SizedBox(width: 10),
          Text(
            'Order successfully delivered',
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaitingTimeUpdate() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      color: const Color(0xFFF8FAFC),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const GradientWidget(
                child: Icon(PhosphorIconsRegular.timer, size: 20),
              ),
              const SizedBox(width: 8),
              Text(
                'Update Estimated Waiting Time',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _waitingTimeMinutesController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (_) => _validateFormState(),
            style: GoogleFonts.poppins(fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Enter minutes...',
              hintStyle: GoogleFonts.poppins(
                fontSize: 14,
                color: const Color(0xFF94A3B8),
              ),
              suffixText: 'mins',
              suffixStyle: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF64748B),
              ),
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
                borderSide: BorderSide(color: AppColors.primary),
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
            if (_currentOrder.status == 'PENDING') ...[
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _deliveryOption = 'PREPAID';
                          _validateFormState();
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          gradient: _deliveryOption == 'PREPAID' ? AppColors.primaryGradient : null,
                          color: _deliveryOption == 'PREPAID' ? null : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Fast Delivery',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _deliveryOption == 'PREPAID' ? Colors.white : const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _deliveryOption = 'NORMAL';
                          _validateFormState();
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          gradient: _deliveryOption == 'NORMAL' ? AppColors.primaryGradient : null,
                          color: _deliveryOption == 'NORMAL' ? null : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Flexible Delivery',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _deliveryOption == 'NORMAL' ? Colors.white : const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
            // ── Section header ──────────────────────────────────────────
            if (_deliveryOption == 'PREPAID' ||
                _currentOrder.status == 'COOKING' ||
                _currentOrder.status == 'AWAITING_APPROVAL') ...[
              Text(
                _currentOrder.status == 'COOKING'
                    ? 'Dispatch Information'
                    : _currentOrder.status == 'AWAITING_APPROVAL'
                        ? 'Rider Information'
                        : 'Prepare to confirm',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ── Flexible Delivery (PENDING) ─────────────────────────────
            if (_deliveryOption == 'NORMAL' && _currentOrder.status == 'PENDING') ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    const GradientWidget(
                      child: Icon(PhosphorIconsRegular.info, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Flexible Delivery',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Shop admin choose delivery service to send food to customer. So user must pay order fee first and delivery fees later separately.',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: const Color(0xFF64748B),
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildInputField(
                      'Estimated Delivery Fee',
                      _deliveryFeeController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        ThousandsSeparatorInputFormatter()
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) return null;
                        final numValue = value.replaceAll(',', '');
                        if (double.tryParse(numValue) == null) return 'Invalid number';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildInputField(
                      'Est Prep Time (mins)',
                      _waitingTimeMinutesController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (value) => (value == null || value.isEmpty) ? 'Required' : null,
                    ),
                  ),
                ],
              ),

            // ── Fast Delivery (PENDING): fee + waiting only ─────────────
            ] else if (_deliveryOption == 'PREPAID' && _currentOrder.status == 'PENDING') ...[
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
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildInputField(
                      'Est Waiting Time (mins)',
                      _waitingTimeMinutesController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (value) => (value == null || value.isEmpty) ? 'Required' : null,
                    ),
                  ),
                ],
              ),

            // ── COOKING / dispatch ────────────────────────────────────
            ] else if (_currentOrder.status == 'COOKING') ...[
              _buildDriverPicker(),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.center,
                child: ImagePickerWidget(
                  shape: ImagePickerShape.rectangle,
                  width: 120,
                  height: 120,
                  onImageSelected: (file) => setState(() => _proofImage = file),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Optional proof photo (COOKING → ON_THE_WAY)',
                style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF64748B)),
              ),
              const SizedBox(height: 12),
              _buildInputField('Tracking URL', _deliveryTrackingUrlController),
            ] else ...[
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
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildInputField(
                      'Est Waiting Time (mins)',
                      _waitingTimeMinutesController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (value) => (value == null || value.isEmpty) ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildDriverPicker(required: false),
              const SizedBox(height: 16),
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
              borderSide: BorderSide(color: AppColors.primary),
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

  /// Builds the payment slip / receipt section.
  /// Handles two formats the customer app may upload:
  ///  1. Base64 data URI  → `data:image/jpeg;base64,...`  (decoded via Image.memory)
  ///  2. Absolute https URL                               (loaded via Image.network)
  Widget _buildPaymentSlipSection() {
    final slipUrl = _currentOrder.paymentSlipUrl!;
    final isBase64 = slipUrl.startsWith('data:image');

    Widget imageWidget;
    if (isBase64) {
      // Strip the data URI prefix and decode the raw base64 bytes
      try {
        final base64Str = slipUrl.contains(',') ? slipUrl.split(',').last : slipUrl;
        final bytes = base64Decode(base64Str);
        imageWidget = ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.memory(
            bytes,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => _buildReceiptError(),
          ),
        );
      } catch (_) {
        imageWidget = _buildReceiptError();
      }
    } else {
      imageWidget = ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Image.network(
          slipUrl,
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
          errorBuilder: (_, _, _) => _buildReceiptError(),
        ),
      );
    }

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
        imageWidget,
      ],
    );
  }

  Widget _buildReceiptError() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(PhosphorIconsRegular.warningCircle, color: Color(0xFF94A3B8), size: 32),
          const SizedBox(height: 8),
          Text(
            'Failed to load receipt',
            style: GoogleFonts.poppins(color: const Color(0xFF64748B), fontSize: 13),
          ),
        ],
      ),
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
