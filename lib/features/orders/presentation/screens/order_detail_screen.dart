import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
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
import 'package:my_shop/core/utils/price_formatter.dart';
import 'package:my_shop/core/presentation/widgets/gradient_widgets.dart';
import 'package:my_shop/core/presentation/widgets/app_dialog.dart';
import 'package:my_shop/core/presentation/widgets/global_modal.dart';
import 'package:my_shop/features/orders/presentation/widgets/cancel_order_dialog.dart';
import 'package:my_shop/core/localization/app_localizations.dart';
import 'package:my_shop/features/coupons/coupon_display_helper.dart';
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
import 'package:my_shop/features/chat/data/services/chat_unread_controller.dart';
import 'package:my_shop/features/chat/presentation/chat_navigation.dart';
import 'package:my_shop/features/orders/presentation/screens/pickup_complete_screen.dart';
import 'package:my_shop/features/orders/presentation/widgets/order_qr_scan_icon.dart';
import 'package:my_shop/features/orders/presentation/widgets/far_order_delivery_banner.dart';
import 'package:my_shop/features/profile/data/services/profile_service.dart';

void _showAppNotInstalledSnackbar(BuildContext context, String name) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          '$name app is not installed',
          style: GoogleFonts.poppins(color: Colors.white),
        ),
      ),
      backgroundColor: Colors.transparent,
      elevation: 0,
      padding: EdgeInsets.zero,
      behavior: SnackBarBehavior.floating,
    ),
  );
}

class OrderDetailScreen extends StatefulWidget {
  final OrderModel order;

  const OrderDetailScreen({super.key, required this.order});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  late OrderModel _currentOrder;
  StreamSubscription? _wsSubscription;
  StreamSubscription? _chatSubscription;
  StreamSubscription<int>? _chatReadSubscription;
  int _chatUnreadCount = 0;
  int _chatConversationId = 0;
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
  bool _isFormValid = false;
  String _deliveryOption = 'PREPAID'; // 'PREPAID' (FAST) or 'NORMAL' (FLEXIBLE)
  int? _selectedDriverId;
  List<Rider> _availableDrivers = [];
  XFile? _proofImage;

  // Shop / user info needed to open the RiderFormSheet (add new driver)
  int? _shopId;
  int? _userId;
  double? _shopLatitude;
  double? _shopLongitude;
  bool _isLoadingRiders = false;
  bool _isScrolled = false;
  bool _hasShownCouponModal = false;
  bool _hasShownPaymentModal = false;
  bool _isInitialOrderFetch = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _currentOrder = widget.order;

    // Auto-acknowledge if the order is still PENDING and opened directly
    if (_currentOrder.status == 'PENDING') {
      OrderService().acknowledgeOrder(_currentOrder.id.toString());
    }

    _setupWebSocketListener();
    _setupChatListener();
    _fetchOrderDetails();
    _fetchChatUnreadCount();
    _initControllers();
    _addFormListeners();
    _loadShopAndUser();
    // Eagerly load the saved drivers so the picker is always populated,
    // regardless of whether the order payload carried any.
    _loadDrivers();

    _scrollController.addListener(() {
      if (_scrollController.offset > 80 && !_isScrolled) {
        setState(() => _isScrolled = true);
      } else if (_scrollController.offset <= 80 && _isScrolled) {
        setState(() => _isScrolled = false);
      }
    });
  }

  void _maybeShowPaymentVerificationModal({String? previousStatus}) {
    if (_hasShownPaymentModal || !mounted) return;
    if (_currentOrder.status != 'AWAITING_APPROVAL') return;

    final slipUrl = _currentOrder.paymentSlipUrl;
    if (slipUrl == null || slipUrl.isEmpty) return;

    // After the first detail fetch, only pop the existing modal when the order
    // newly enters AWAITING_APPROVAL (e.g. customer just uploaded a slip).
    if (previousStatus != null &&
        previousStatus.toUpperCase() == 'AWAITING_APPROVAL') {
      return;
    }

    _hasShownPaymentModal = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _showPaymentVerificationModal();
    });
  }

  /// Loads the unread customer-message count for this order so the chat icon
  /// can show a badge. Backed by GET /api/shop/chat/orders/{orderId}, which
  /// returns `shopUnreadCount` without marking the thread read.
  Future<void> _fetchChatUnreadCount() async {
    final orderId = int.tryParse(_currentOrder.id) ?? 0;
    if (orderId <= 0) return;
    final conversation = await ChatService.instance.getConversationByOrder(
      orderId,
    );
    if (!mounted) return;
    setState(() {
      _chatUnreadCount = conversation?.unreadCount ?? 0;
      if (conversation != null) _chatConversationId = conversation.id;
    });
  }

  /// Refreshes the badge whenever a realtime chat event arrives for this shop,
  /// and clears it immediately when the thread is read from another screen
  /// (e.g. the chat inbox) — a shop-side read emits no realtime event.
  void _setupChatListener() {
    _chatSubscription = WebSocketService().chatUpdates.listen(
      (_) => _fetchChatUnreadCount(),
    );
    _chatReadSubscription = ChatUnreadController.instance.conversationRead
        .listen((conversationId) {
          if (!mounted || _chatUnreadCount == 0) return;
          if (conversationId == _chatConversationId) {
            setState(() => _chatUnreadCount = 0);
          }
        });
  }

  Future<void> _loadShopAndUser() async {
    _shopId = await StorageService.instance.getSelectedShopId();
    final userInfo = await StorageService.instance.getUserInfo();
    _userId = userInfo?.id;
    final profile = await ProfileService().getShopProfile();
    if (!mounted || profile == null) return;
    setState(() {
      _shopLatitude = profile.latitude;
      _shopLongitude = profile.longitude;
    });
  }

  Future<void> _loadDrivers() async {
    if (!mounted) return;
    setState(() => _isLoadingRiders = true);
    final riders = await RiderService().getSelectableRiders();
    if (mounted) {
      setState(() {
        final byId = <int, Rider>{for (final r in riders) r.id: r};

        // Keep the already-assigned driver for read-only display after dispatch,
        // even if they are now busy or inactive.
        final assigned = _assignedRiderFromOrder();
        if (assigned != null) {
          byId.putIfAbsent(assigned.id, () => assigned);
        }

        _availableDrivers = byId.values.toList();
        if (_selectedDriverId != null && !_hasValidSelectedDriver) {
          _selectedDriverId = null;
        }
        _isLoadingRiders = false;
      });
      _validateFormState();
    }
  }

  Rider? _assignedRiderFromOrder() {
    final assignedId = _currentOrder.driverId;
    if (assignedId == null) return null;

    for (final r in _availableDrivers) {
      if (r.id == assignedId) return r;
    }

    for (final d in _currentOrder.shopDeliveryDrivers) {
      if (d.id == assignedId) {
        return Rider(
          id: d.id,
          name: d.name,
          phone: d.phone,
          vehicleNo: d.vehicleNo,
          profileUrl: d.profileUrl,
          shopId: 0,
          isActive: d.isActive,
          isBusy: d.isBusy,
        );
      }
    }

    final name = _currentOrder.riderName?.trim();
    if (name == null || name.isEmpty) return null;
    return Rider(
      id: assignedId,
      name: name,
      phone: _currentOrder.riderPhone,
      vehicleNo: _currentOrder.vehicleNo,
      profileUrl: null,
      shopId: 0,
      isActive: true,
      isBusy: true,
    );
  }

  void _initControllers() {
    final formatter = NumberFormat('#,##0');
    _deliveryFeeController.text = _currentOrder.deliveryFee > 0
        ? formatter.format(_currentOrder.deliveryFee)
        : '';
    _deliveryCycleNoController.text = _currentOrder.deliveryCycleNo ?? '';
    _deliveryRiderNameController.text = _currentOrder.riderName ?? '';
    _deliveryPhoneNoController.text =
        (_currentOrder.riderPhone == null || _currentOrder.riderPhone!.isEmpty)
        ? '+66'
        : _currentOrder.riderPhone!;
    _deliveryTrackingUrlController.text =
        _currentOrder.deliveryTrackingUrl ?? '';
    _waitingTimeMinutesController.text = _currentOrder.waitingTimeMinutes > 0
        ? _currentOrder.waitingTimeMinutes.toString()
        : '';
    _deliveryOption = _currentOrder.deliveryType == 'NORMAL'
        ? 'NORMAL'
        : 'PREPAID';
    _validateFormState();
  }

  Future<void> _fetchOrderDetails({
    bool showLoading = true,
    String? previousStatus,
  }) async {
    if (showLoading) setState(() => _isFirstLoading = true);
    final statusBeforeFetch = previousStatus ?? _currentOrder.status;
    final updatedOrder = await OrderService().getOrderDetail(_currentOrder.id);
    if (updatedOrder != null && mounted) {
      setState(() {
        _currentOrder = updatedOrder;
        _selectedDriverId = updatedOrder.driverId;
        _initControllers();
        _isFirstLoading = false;
      });
      // Always (re)load the shop's full rider roster so the picker shows every
      // saved rider, regardless of what the order payload carried.
      _loadDrivers();

      _maybeShowPaymentVerificationModal(
        previousStatus: _isInitialOrderFetch ? null : statusBeforeFetch,
      );
      _isInitialOrderFetch = false;

      if (_currentOrder.hasAppliedCoupon && !_hasShownCouponModal) {
        _hasShownCouponModal = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showCouponModal();
        });
      }
    } else if (mounted) {
      setState(() => _isFirstLoading = false);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _wsSubscription?.cancel();
    _chatSubscription?.cancel();
    _chatReadSubscription?.cancel();
    _deliveryFeeController.dispose();
    _deliveryCycleNoController.dispose();
    _deliveryRiderNameController.dispose();
    _deliveryPhoneNoController.dispose();
    _deliveryTrackingUrlController.dispose();
    _waitingTimeMinutesController.dispose();
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
      if (_currentOrder.isPickupFulfillment) {
        isValid = waiting.isNotEmpty && int.tryParse(waiting) != null;
      } else if (_deliveryOption == 'NORMAL') {
        // Flexible Delivery: only need preparation time
        isValid = waiting.isNotEmpty && int.tryParse(waiting) != null;
      } else {
        // Fast Delivery (PENDING): only need fee + waiting time
        isValid =
            fee.isNotEmpty &&
            double.tryParse(fee) != null &&
            waiting.isNotEmpty &&
            int.tryParse(waiting) != null;
      }
    } else if (_currentOrder.status == 'AWAITING_APPROVAL') {
      isValid = true;
    } else if (_currentOrder.status == 'COOKING') {
      bool baseValid =
          _currentOrder.isPickupFulfillment ||
          _selectedDriverId != null ||
          _deliveryTrackingUrlController.text.trim().isNotEmpty;
      if (!_currentOrder.isPickupFulfillment &&
          _currentOrder.deliveryType == 'NORMAL') {
        isValid = baseValid && fee.isNotEmpty && double.tryParse(fee) != null;
      } else {
        isValid = baseValid;
      }
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

        final previousStatus = _currentOrder.status;

        setState(() {
          _isUpdating = true;
          // If the event contains a full order object, we can reconstruct it
          // for an instant status/items refresh.
          if (event['order'] != null) {
            _currentOrder = OrderModel.fromJson(event['order']);
            _initControllers();
          }
        });

        // The WebSocket payload bypasses the API's URL-transform interceptor,
        // so its file fields (paymentSlipUrl, proofPhotoUrl, images) are raw
        // storage keys that don't resolve. Re-fetch over HTTP to get the
        // properly-built absolute URLs (otherwise the receipt fails to load).
        _fetchOrderDetails(showLoading: false, previousStatus: previousStatus);

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
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
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
                SizedBox(height: 16),
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
                  decoration: InputDecoration(
                    labelText: 'Reason',
                    border: const OutlineInputBorder(),
                    suffixIcon: ValueListenableBuilder<TextEditingValue>(
                      valueListenable: reasonController,
                      builder: (context, value, child) {
                        if (value.text.isEmpty) return const SizedBox.shrink();
                        return IconButton(
                          icon: Icon(Icons.clear, color: Colors.grey, size: 20),
                          onPressed: () {
                            reasonController.clear();
                          },
                        );
                      },
                    ),
                  ),
                ),
                SizedBox(height: 16),
                PrimaryGradientButton(
                  onPressed:
                      selectedIds.isEmpty ||
                          reasonController.text.trim().isEmpty
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
      _deliveryPhoneNoController.text = (phone == null || phone.isEmpty)
          ? '+66'
          : phone;
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

  /// Drivers that can be picked in the dispatch dropdown (`isActive && !isBusy`).
  List<Rider> get _selectableDrivers =>
      _availableDrivers.where((r) => r.isActive && !r.isBusy).toList();

  /// Whether the currently selected driver is still eligible for assignment.
  bool get _hasValidSelectedDriver =>
      _selectedDriverId != null &&
      _selectableDrivers.any((r) => r.id == _selectedDriverId);

  /// The driver assigned to this order, resolved from the loaded roster by
  /// `driverId`. The driver is chosen once at the COOKING (dispatch) step, so
  /// later steps display it read-only instead of offering another picker.
  Rider? get _assignedRider {
    final id = _currentOrder.driverId;
    if (id == null) return null;
    for (final r in _availableDrivers) {
      if (r.id == id) return r;
    }
    return null;
  }

  /// Whether to show the read-only assigned-rider card (after dispatch).
  bool get _showAssignedRider =>
      (_currentOrder.status == 'ON_THE_WAY' ||
          _currentOrder.status == 'DELIVERED') &&
      (_assignedRider != null ||
          (_currentOrder.riderName != null &&
              _currentOrder.riderName!.trim().isNotEmpty));

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
            if (rider.isActive && !rider.isBusy) {
              final idx = _availableDrivers.indexWhere((r) => r.id == rider.id);
              if (idx >= 0) {
                _availableDrivers[idx] = rider;
              } else {
                _availableDrivers = [rider, ..._availableDrivers];
              }
              _applySelectedDriver(rider);
            } else {
              AppDialog.showToast(
                context,
                'Driver must be active and not busy to assign to an order.',
                isError: true,
              );
            }
          });
        },
      ),
    );
  }

  Future<void> _openDriverPicker() async {
    // Always ensure the list is loaded before opening so the sheet never shows
    // an empty/blank state due to a skipped or in-flight load.
    if (_selectableDrivers.isEmpty) {
      await _loadDrivers();
    }
    if (!mounted) return;

    final drivers = _selectableDrivers;

    final selected = await showModalBottomSheet<Rider?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
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
                SizedBox(height: 12),
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
                          color:
                              (Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : const Color(0xFF1E293B)),
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
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: CustomLoadingIndicator(size: 24),
                  )
                else if (drivers.isEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                    child: Column(
                      children: [
                        Icon(
                          PhosphorIconsRegular.users,
                          size: 48,
                          color: Color(0xFFCBD5E1),
                        ),
                        SizedBox(height: 12),
                        Text(
                          'No available drivers',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF475569),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Only active drivers who are not on another delivery can be assigned. Add a new driver or wait until someone is free.',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color:
                                (Theme.of(context).brightness == Brightness.dark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF64748B)),
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
                      itemCount: drivers.length,
                      separatorBuilder: (_, _) => SizedBox(height: 8),
                      itemBuilder: (_, index) {
                        final rider = drivers[index];
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
              : (Theme.of(context).brightness == Brightness.dark
                    ? Colors.transparent
                    : Colors.white),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.5)
                : Theme.of(context).dividerColor,
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
                            Icon(PhosphorIconsRegular.user, size: 20),
                        errorWidget: (_, _, _) => Icon(
                          PhosphorIconsRegular.user,
                          size: 20,
                          color: AppColors.primary,
                        ),
                      ),
                    )
                  : Icon(
                      PhosphorIconsRegular.user,
                      size: 20,
                      color: AppColors.primary,
                    ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rider.name,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: (Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : const Color(0xFF1E293B)),
                    ),
                  ),
                  if (rider.phone != null && rider.phone!.isNotEmpty)
                    Text(
                      rider.phone!,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: (Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFFCBD5E1)
                            : const Color(0xFF64748B)),
                      ),
                    ),
                  if (rider.vehicleNo != null && rider.vehicleNo!.isNotEmpty)
                    Text(
                      'Plate: ${rider.vehicleNo}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF94A3B8),
                      ),
                    ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
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
    final selected = _hasValidSelectedDriver
        ? _selectableDrivers.firstWhere((r) => r.id == _selectedDriverId)
        : null;
    final hasSelection = selected != null;
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
            color: (Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFFCBD5E1)
                : const Color(0xFF64748B)),
          ),
        ),
        SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: _openDriverPicker,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: hasSelection
                          ? AppColors.primary.withValues(alpha: 0.4)
                          : Theme.of(context).dividerColor,
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
                      SizedBox(width: 10),
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
                                    ? (Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? Colors.white
                                          : const Color(0xFF1E293B))
                                    : (Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? const Color(0xFF64748B)
                                          : const Color(0xFF94A3B8)),
                              ),
                            ),
                            if (subtitle.isNotEmpty)
                              Text(
                                subtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color:
                                      Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? const Color(0xFF64748B)
                                      : const Color(0xFF94A3B8),
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (hasSelection)
                        GestureDetector(
                          onTap: _clearSelectedDriver,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Icon(
                              PhosphorIconsRegular.x,
                              size: 16,
                              color:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? const Color(0xFF64748B)
                                  : const Color(0xFF94A3B8),
                            ),
                          ),
                        )
                      else if (_isLoadingRiders)
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CustomLoadingIndicator(size: 16),
                        )
                      else
                        Icon(
                          PhosphorIconsRegular.caretDown,
                          size: 16,
                          color:
                              (Theme.of(context).brightness == Brightness.dark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B)),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(width: 8),
            InkWell(
              onTap: _openAddDriverSheet,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      PhosphorIconsRegular.plus,
                      size: 16,
                      color: Colors.white,
                    ),
                    SizedBox(width: 4),
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
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Image.asset('assets/images/app_logo.png', width: 24, height: 24),
            SizedBox(width: 8),
            Text(
              'MyTogether',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: (Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : const Color(0xFF1E293B)),
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
      AppDialog.showToast(
        context,
        errorDetails ??
            errorMessage ??
            (AppLocalizations.of(context)?.translate('operation_failed') ??
                'Operation failed. Please try again.'),
        isError: true,
      );
    }

    if (mounted) {
      setState(() => _isUpdating = false);
    }
  }

  Future<void> _handleConfirmOrder() async {
    if (_deliveryOption == 'PREPAID' && !_formKey.currentState!.validate()) {
      return;
    }

    final orderDeliveryType = _deliveryOption == 'NORMAL' ? 'FLEXIBLE' : 'FAST';
    final isPickup = _currentOrder.isPickupFulfillment;
    final deliveryFee = isPickup
        ? 0.0
        : (double.tryParse(_deliveryFeeController.text.replaceAll(',', '')) ??
              0);

    await _runOrderAction(
      action: () => OrderService().confirmOrder(
        _currentOrder.id.toString(),
        orderDeliveryType: orderDeliveryType,
        deliveryFee: deliveryFee,
        waitingTimeMinutes:
            int.tryParse(_waitingTimeMinutesController.text) ?? 0,
        driverId: _selectedDriverId,
      ),
      errorMessage: 'Failed to confirm order. Please try again.',
    );
  }

  String _formatTimeAgo(DateTime? date) {
    if (date == null) return '';
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}min ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  String _couponDetailHint() {
    final sc = _currentOrder.shopCoupon;
    if (sc == null || !sc.isFreeItem) return '';
    return CouponDisplayHelper.bogoGiftSummary(
      context,
      isFreeItem: true,
      isBogoAllItems: sc.isBogoAllItems,
      buyItems: sc.buyItems,
      freeItems: sc.freeItems,
    );
  }

  void _showCouponModal() {
    if (!mounted || !_currentOrder.hasAppliedCoupon) return;

    final sc = _currentOrder.shopCoupon;
    final message = CouponDisplayHelper.orderModalMessage(
      context,
      couponName: _currentOrder.couponName ?? sc?.name,
      discountAmount: _currentOrder.discountAmount,
      isFreeItem: sc?.isFreeItem ?? false,
      isBogoAllItems: sc?.isBogoAllItems ?? false,
      isPercentage: sc?.isPercentage ?? false,
      discountValue: sc?.discountValue ?? 0,
      buyItems: sc?.buyItems ?? const [],
      freeItems: sc?.freeItems ?? const [],
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFFED3973).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  PhosphorIconsFill.ticket,
                  color: Color(0xFFED3973),
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Coupon Applied!',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFED3973),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Got it',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _showPaymentVerificationModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final overdueMinutes = DateTime.now()
            .difference(_currentOrder.updatedAt)
            .inMinutes;
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: (Theme.of(context).brightness == Brightness.dark
                        ? Theme.of(context).cardColor
                        : (Theme.of(context).brightness == Brightness.dark
                              ? Theme.of(context).cardColor
                              : const Color(0xFFF1F5F9))),
                  ),
                ),
                child: Center(
                  child: Icon(
                    PhosphorIconsFill.ticket,
                    color: Color(0xFFE11D48),
                  ),
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Check payment',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: (Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : const Color(0xFF1E293B)),
                ),
              ),
              SizedBox(height: 4),
              Text(
                '#${_currentOrder.lastOrderNo} • ${_formatTimeAgo(_currentOrder.createdAt)} • ${_currentOrder.orderType == "DELIVERY" ? "🚚 Delivery" : "📦 Pickup"}',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: (Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFFCBD5E1)
                      : const Color(0xFF64748B)),
                ),
              ),
              SizedBox(height: 24),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (overdueMinutes > 5) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? const Color(0xFF4C0519)
                                : (Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? const Color(0xFF4C0519)
                                      : (Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? const Color(0xFF4C0519)
                                            : const Color(0xFFFFF1F2))),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '!! Verification overdue',
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFFE11D48),
                                    ),
                                  ),
                                  Text(
                                    '$overdueMinutes min',
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFFE11D48),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Customer has completed payment, please verify to continue the order.',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: const Color(0xFFE11D48),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 24),
                      ],
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color:
                                (Theme.of(context).brightness == Brightness.dark
                                ? Theme.of(context).cardColor
                                : (Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Theme.of(context).cardColor
                                      : const Color(0xFFF1F5F9))),
                          ),
                        ),
                        child: _buildPaymentSlipSection(),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: PrimaryGradientButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _handleRequestSlip();
                      },
                      height: 56,
                      borderRadius: 16,
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).brightness == Brightness.dark
                              ? const Color(0xFF4C0519)
                              : (Theme.of(context).brightness == Brightness.dark
                                    ? const Color(0xFF4C0519)
                                    : (Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? const Color(0xFF4C0519)
                                          : const Color(0xFFFFF1F2))),
                          Theme.of(context).brightness == Brightness.dark
                              ? const Color(0xFF4C0519)
                              : (Theme.of(context).brightness == Brightness.dark
                                    ? const Color(0xFF4C0519)
                                    : (Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? const Color(0xFF4C0519)
                                          : const Color(0xFFFFF1F2))),
                        ],
                      ),
                      child: Center(
                        child: GradientText(
                          'Revise',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: PrimaryGradientButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _handleVerifyPayment();
                      },
                      text: 'Confirm Payment',
                      height: 56,
                      borderRadius: 16,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
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
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Image.asset('assets/images/app_logo.png', width: 24, height: 24),
            SizedBox(width: 8),
            Text(
              'Revise Payment',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: (Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : const Color(0xFF1E293B)),
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
            SizedBox(height: 16),
            TextField(
              controller: reasonController,
              autofocus: true,
              style: GoogleFonts.poppins(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Enter reason here...',
                hintStyle: GoogleFonts.poppins(
                  fontSize: 14,
                  color: (Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF64748B)),
                ),
                filled: true,
                fillColor: Theme.of(context).cardColor,
                suffixIcon: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: reasonController,
                  builder: (context, value, child) {
                    if (value.text.isEmpty) return const SizedBox.shrink();
                    return IconButton(
                      icon: Icon(Icons.clear, color: Colors.grey, size: 20),
                      onPressed: () {
                        reasonController.clear();
                      },
                    );
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Theme.of(context).dividerColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Theme.of(context).dividerColor),
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
      // Resend the order's existing delivery details: the backend status
      // endpoint mandates them for PAYMENT_SLIP_REQUESTED and recomputes the
      // total from them, so omitting them would fail validation / wipe the fee.
      final orderDeliveryType =
          _currentOrder.orderDeliveryType ??
          (_currentOrder.deliveryType == 'NORMAL' ? 'FLEXIBLE' : 'FAST');
      await _runOrderAction(
        action: () => OrderService().requestSlip(
          _currentOrder.id.toString(),
          reason,
          orderDeliveryType: orderDeliveryType,
          deliveryFee: _currentOrder.deliveryFee,
          waitingTimeMinutes: _currentOrder.waitingTimeMinutes,
        ),
        errorMessage: 'Failed to request new slip. Please try again.',
      );
    }
  }

  /// Shop may cancel only before the customer has uploaded payment.
  bool _isOrderCancelable(String status) {
    return status == 'PENDING' ||
        status == 'REVISED' ||
        status == 'PAYMENT_SLIP_REQUESTED';
  }

  Future<void> _handleCancelOrder() async {
    final t = AppLocalizations.of(context);
    final staticMediaQuery = MediaQuery.of(
      context,
    ).copyWith(viewInsets: EdgeInsets.zero);

    final String? reason = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => MediaQuery(
        data: staticMediaQuery,
        child: const CancelOrderDialog(),
      ),
    );

    if (reason != null && mounted) {
      await _runOrderAction(
        action: () => OrderService().cancelOrder(
          _currentOrder.id.toString(),
          reason.isEmpty ? null : reason,
        ),
        errorMessage:
            t?.translate('order_cancelled_fail') ??
            'Failed to cancel order. Please try again.',
        onSuccess: () {
          if (!mounted) return;
          AppDialog.showToast(
            context,
            t?.translate('order_cancelled_success') ?? 'Order Cancelled',
          );
        },
      );
    }
  }

  Future<void> _handleMarkReadyForPickup() async {
    await _runOrderAction(
      action: () => OrderService().markReadyForPickup(
        _currentOrder.id.toString(),
        waitingTimeMinutes: int.tryParse(_waitingTimeMinutesController.text),
      ),
      errorMessage: 'Failed to mark order ready for pickup.',
    );
  }

  Future<void> _openPickupCompleteScreen() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => PickupCompleteScreen(order: _currentOrder),
      ),
    );
    if (result == 'PICKED_UP' && mounted) {
      await _fetchOrderDetails();
    }
  }

  bool get _showPickupScanAction =>
      _currentOrder.isPickupFulfillment &&
      (_currentOrder.status == 'COOKING' ||
          _currentOrder.status == 'READY_FOR_PICKUP');

  Future<void> _handleDispatchOrder() async {
    final hasTrackingUrl = _deliveryTrackingUrlController.text
        .trim()
        .isNotEmpty;
    if (_selectedDriverId == null && !hasTrackingUrl) {
      AppDialog.showToast(
        context,
        'Please select a delivery driver or provide a tracking URL',
        isError: true,
      );
      return;
    }

    // Send the delivery fee on dispatch regardless of delivery type so a FAST
    // order's fee can update too — not just FLEXIBLE. The backend bills it into
    // the total only for non-flexible orders, so this stays correct for both.
    double? finalDeliveryFee;
    if (_deliveryFeeController.text.isNotEmpty) {
      final numStr = _deliveryFeeController.text.replaceAll(',', '');
      finalDeliveryFee = double.tryParse(numStr);
    }

    await _runOrderAction(
      action: () => OrderService().dispatchOrder(
        _currentOrder.id.toString(),
        driverId: _selectedDriverId,
        trackingUrl: hasTrackingUrl
            ? _deliveryTrackingUrlController.text.trim()
            : null,
        deliveryFee: finalDeliveryFee,
        waitingTimeMinutes: int.tryParse(_waitingTimeMinutesController.text),
      ),
      errorMessage: 'Failed to dispatch order. Please try again.',
    );
  }

  Future<void> _handleCompleteDelivery() async {
    await _runOrderAction(
      action: () => OrderService().completeOrder(
        _currentOrder.id.toString(),
        proofImage: _proofImage,
      ),
      errorMessage: 'Failed to complete delivery. Please try again.',
      onSuccess: () {
        AppDialog.showSuccessDialog(
          context,
          message:
              'The order MT-${_currentOrder.lastOrderNo} has been successfully delivered and completed.',
        );
      },
    );
  }

  Future<void> _handleTrackingUrlChanged(String urlStr) async {
    try {
      final uri = Uri.tryParse(urlStr.trim());
      if (uri == null) return;
      if (!uri.host.contains('bolt.eu')) return;

      final sToken = uri.queryParameters['s'];
      if (sToken == null || sToken.isEmpty) return;

      setState(() => _isUpdating = true);
      AppDialog.showToast(context, 'Fetching rider details from Bolt...');

      final auth = base64Encode(utf8.encode(':$sToken'));
      final apiUrl =
          'https://node.bolt.eu/route-sharing/routeSharing/getOrder?version=RS.3.13&language=en-US';

      final response = await Dio().get(
        apiUrl,
        options: Options(
          headers: {'Authorization': 'Basic $auth'},
          validateStatus: (status) => true,
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['code'] == 0 && data['data'] != null) {
          final resData = data['data'];
          final driverName = resData['driver_name'] as String?;
          final carColor = resData['car_color'] as String?;
          final carModel = resData['car_model'] as String?;
          final carRegNumber = resData['car_reg_number'] as String?;
          final driverPicture = resData['driver_picture'] as String?;

          XFile? imageFile;
          if (driverPicture != null && driverPicture.isNotEmpty) {
            try {
              final imgRes = await Dio().get(
                driverPicture,
                options: Options(
                  responseType: ResponseType.bytes,
                  validateStatus: (status) => true,
                ),
              );
              if (imgRes.statusCode == 200) {
                imageFile = XFile.fromData(imgRes.data, name: 'bolt_rider.jpg');
              }
            } catch (_) {}
          }

          final vehicleNo = [
            carColor,
            carModel,
            carRegNumber,
          ].where((e) => e != null && e.isNotEmpty).join(' ');

          final riderData = {
            'name': driverName ?? 'Bolt Rider',
            'phone': '',
            'vehicleNo': vehicleNo,
            'isActive': true,
          };

          final newRider = await RiderService().createRider(
            riderData,
            image: imageFile,
          );

          if (newRider != null && mounted) {
            setState(() {
              _availableDrivers.add(newRider);
              _selectedDriverId = newRider.id;
            });
            AppDialog.showToast(context, 'Bolt rider auto-filled successfully');
          }
        }
      }
    } catch (_) {
      // Silently ignore errors
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
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
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: Theme.of(context).iconTheme.color,
            ),
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
                  color: (Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : const Color(0xFF1E293B)),
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
          actions: [
            if (_isScrolled && _currentOrder.status != 'CANCELED')
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: GestureDetector(
                  onTap: _openCustomerChat,
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Theme.of(context).cardColor,
                          image: _currentOrder.customerAvatar != null && _currentOrder.customerAvatar!.isNotEmpty
                              ? DecorationImage(
                                  image: NetworkImage(
                                    _currentOrder.customerAvatar!,
                                  ),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: _currentOrder.customerAvatar == null
                            ? Icon(
                                PhosphorIconsRegular.user,
                                color:
                                    (Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? const Color(0xFF94A3B8)
                                    : const Color(0xFF64748B)),
                                size: 20,
                              )
                            : null,
                      ),
                      if (_chatUnreadCount > 0)
                        Positioned(
                          right: -4,
                          top: 4,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Color(0xFFEF4444),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '$_chatUnreadCount',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                height: 1,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            if (_showPickupScanAction) const OrderQrScanIcon(),
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
                    Expanded(
                      child: CustomScrollView(
                        controller: _scrollController,
                        slivers: [
                          SliverToBoxAdapter(
                            child: Container(
                              color: Theme.of(context).cardColor,
                              padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildCustomerSection(),
                                  SizedBox(height: 16),
                                  _buildAddressSection(context),
                                ],
                              ),
                            ),
                          ),
                          SliverPersistentHeader(
                            pinned: true,
                            delegate: _StatusHeaderDelegate(
                              height: _currentOrder.status == 'CANCELED'
                                  ? 56.0
                                  : 104.0,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Theme.of(context).cardColor,
                                  border: Border(
                                    bottom: BorderSide(
                                      color: Theme.of(context).dividerColor,
                                      width: 1,
                                    ),
                                  ),
                                ),
                                child: _buildStickyProgress(),
                              ),
                            ),
                          ),
                          SliverToBoxAdapter(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(height: 16),
                                // Items Ordered (Padded)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                  ),
                                  child: Column(
                                    children: [
                                      _buildItemsSection(),
                                      SizedBox(height: 24),
                                      Divider(
                                        color:
                                            (Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Theme.of(context).cardColor
                                            : const Color(0xFFF1F5F9)),
                                        thickness: 1.5,
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 16),

                                // Confirmation Form (Full Width - it has its own internal padding)
                                if (_currentOrder.status == 'PENDING' ||
                                    _currentOrder.status == 'COOKING' ||
                                    _currentOrder.status ==
                                        'READY_FOR_PICKUP') ...[
                                  _buildConfirmationForm(),
                                  SizedBox(height: 8),
                                ],

                                // Waiting Time Update (PREPARING state only for Delivery)
                                if (_currentOrder.status == 'COOKING' &&
                                    _currentOrder.isDeliveryFulfillment) ...[
                                  _buildWaitingTimeUpdate(),
                                  SizedBox(height: 8),
                                ],

                                // Delivery proof photo — captured while the order is on the
                                // way so the shop can attach a photo when marking it
                                // Delivered. The image is shown to the customer as proof
                                // the food was successfully delivered.
                                if (_currentOrder.status == 'ON_THE_WAY') ...[
                                  _buildDeliveryProofSection(),
                                  SizedBox(height: 8),
                                ],

                                // Once Delivered, show the captured proof photo (read-only).
                                if (_currentOrder.status == 'DELIVERED' &&
                                    _currentOrder.proofPhotoUrl != null &&
                                    _currentOrder
                                        .proofPhotoUrl!
                                        .isNotEmpty) ...[
                                  _buildDeliveryProofView(
                                    _currentOrder.proofPhotoUrl!,
                                  ),
                                  SizedBox(height: 8),
                                ],

                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Scheduled Info if applicable
                                      if (_currentOrder.isScheduled)
                                        _buildScheduledInfo(),

                                      // Assigned rider (read-only) — the driver is selected
                                      // once at the dispatch step, so here we only display it.
                                      if (_showAssignedRider)
                                        _buildRiderSection(),

                                      if (_currentOrder.status == 'CANCELED')
                                        _buildCancelReasonBox(),

                                      if (_currentOrder.isScheduled ||
                                          _showAssignedRider ||
                                          _currentOrder.status == 'CANCELED')
                                        SizedBox(height: 16),

                                      // Order Modifications
                                      if (_currentOrder
                                          .modifications
                                          .isNotEmpty) ...[
                                        _buildModificationsSection(),
                                        SizedBox(height: 12),
                                      ],

                                      // Estimated Time
                                      if (_currentOrder.estimatedDeliveryTime !=
                                              null &&
                                          _currentOrder
                                              .estimatedDeliveryTime!
                                              .isNotEmpty &&
                                          _currentOrder.status !=
                                              'CANCELED') ...[
                                        _buildEstimatedTimeBox(),
                                        SizedBox(height: 24),
                                      ],

                                      // Payment Summary
                                      _buildPaymentSummary(),
                                      SizedBox(height: 32),

                                      // Calculate delivery fee box (hidden for DELIVERED & CANCELLED)
                                      if (_currentOrder.status != 'CANCELED' &&
                                          _currentOrder.status !=
                                              'DELIVERED') ...[
                                        _buildDeliveryCalculator(),
                                        SizedBox(height: 40),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
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
          SizedBox(height: 24),
          Row(
            children: [
              const Skeleton.circle(width: 48, height: 48),
              SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Skeleton(width: 120, height: 16),
                  SizedBox(height: 8),
                  const Skeleton(width: 80, height: 14),
                ],
              ),
            ],
          ),
          SizedBox(height: 32),
          const Skeleton(width: 100, height: 18),
          SizedBox(height: 12),
          const Skeleton(width: double.infinity, height: 60),
          SizedBox(height: 32),
          const Skeleton(width: double.infinity, height: 40),
          SizedBox(height: 32),
          const Skeleton(width: 120, height: 18),
          SizedBox(height: 16),
          ...List.generate(
            3,
            (index) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Skeleton(width: 20, height: 16),
                      SizedBox(width: 8),
                      const Skeleton(width: 150, height: 16),
                    ],
                  ),
                  const Skeleton(width: 60, height: 16),
                ],
              ),
            ),
          ),
          SizedBox(height: 32),
          const Skeleton(width: double.infinity, height: 100),
          SizedBox(height: 40),
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
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF4C0519)
              : (Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF4C0519)
                    : (Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF4C0519)
                          : const Color(0xFFFFF1F2))),
        ),
        child: Row(
          children: [
            Icon(
              PhosphorIconsFill.smileySad,
              color: Color(0xFFEF4444),
              size: 24,
            ),
            SizedBox(width: 12),
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      decoration: BoxDecoration(color: Theme.of(context).cardColor),
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
        key: ValueKey('${_currentOrder.status}_${_currentOrder.orderType}'),
        status: _currentOrder.status,
        isPickup: _currentOrder.isPickupFulfillment,
      ),
    );
  }

  Widget _buildEstimatedTimeBox() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF78350F)
            : (Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF78350F)
                  : const Color(0xFFFFFBEB))),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFEF3C7)),
      ),
      child: Row(
        children: [
          Icon(PhosphorIconsRegular.timer, color: Color(0xFFD97706), size: 20),
          SizedBox(width: 8),
          Text(
            'Est Waiting Time: ',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFFD97706),
            ),
          ),
          Text(
            _currentOrder.estimatedDeliveryTime!,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: const Color(0xFFB45309),
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
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF4C0519)
            : AppColors.errorContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF881337)
              : AppColors.errorLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                PhosphorIconsFill.smileySad,
                color: AppColors.error,
                size: 24,
              ),
              SizedBox(width: 10),
              GradientText(
                'Order Cancelled',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.black.withValues(alpha: 0.2)
                  : Colors.white.withValues(alpha: 0.5),

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
                SizedBox(height: 4),
                Text(
                  (_currentOrder.cancelReason != null &&
                          _currentOrder.cancelReason!.isNotEmpty)
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
        GestureDetector(
          onTap: () {
            if (_currentOrder.customerAvatar != null) {
              showDialog(
                context: context,
                builder: (context) => Dialog(
                  backgroundColor: Colors.transparent,
                  insetPadding: EdgeInsets.zero,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned.fill(
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(color: Colors.black54),
                        ),
                      ),
                      InteractiveViewer(
                        child: _currentOrder.customerAvatar != null && _currentOrder.customerAvatar!.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: _currentOrder.customerAvatar!,
                                fit: BoxFit.contain,
                                placeholder: (context, url) =>
                                    const CustomLoadingIndicator(size: 32),
                                errorWidget: (context, url, error) =>
                                    const Icon(Icons.error, color: Colors.white),
                              )
                            : const Icon(Icons.person, color: Colors.white, size: 64),
                      ),
                      Positioned(
                        top: 40,
                        right: 20,
                        child: IconButton(
                          icon: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 30,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
          },
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).cardColor,
              image: _currentOrder.customerAvatar != null && _currentOrder.customerAvatar!.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(_currentOrder.customerAvatar!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: _currentOrder.customerAvatar == null
                ? Icon(
                    PhosphorIconsRegular.user,
                    color: Theme.of(context).iconTheme.color,
                  )
                : null,
          ),
        ),
        SizedBox(width: 12),
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
        SizedBox(width: 12),
        if (_currentOrder.status != 'CANCELED') ...[
          _buildCircularIcon(
            PhosphorIconsFill.chatCircleDots,
            onTap: _openCustomerChat,
            badgeCount: _chatUnreadCount,
          ),
          SizedBox(width: 12),
        ],
        GestureDetector(
          onTap: () {
            Clipboard.setData(
              ClipboardData(
                text:
                    '${_currentOrder.customerName}\n${_currentOrder.customerPhone}',
              ),
            );
            AppDialog.showToast(context, 'Customer info copied to clipboard');
          },
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).cardColor,
            ),
            child: Icon(
              PhosphorIconsRegular.copy,
              color: Theme.of(context).iconTheme.color,
              size: 20,
            ),
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
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
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
      AppDialog.showToast(
        context,
        'Chat unavailable for this order',
        isError: true,
      );
      return;
    }

    var conversation = await ChatService.instance.getConversationByOrder(
      orderId,
    );
    if (!mounted) return;
    if (conversation != null) _chatConversationId = conversation.id;

    // No conversation yet — open a fresh one; the first message creates it.
    final chatConversation =
        conversation ??
        ChatConversation(
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

    // Opening the thread marks the customer's messages as read on the backend,
    // so clear the badge and re-sync with the server on return.
    if (!mounted) return;
    setState(() => _chatUnreadCount = 0);
    _fetchChatUnreadCount();
  }

  Widget _buildCircularIcon(
    IconData icon, {
    VoidCallback? onTap,
    int badgeCount = 0,
  }) {
    return GestureDetector(
      onTap: onTap ?? _showDemoDialog,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).cardColor,
            ),
            child: Icon(
              icon,
              color: Theme.of(context).iconTheme.color,
              size: 20,
            ),
          ),
          if (badgeCount > 0)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFED3973),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                child: Text(
                  badgeCount > 99 ? '99+' : '$badgeCount',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAddressSection(BuildContext context) {
    final t = AppLocalizations.of(context);

    if (_currentOrder.isPickupFulfillment) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFFDF2F8),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                PhosphorIconsRegular.shoppingBag,
                size: 18,
                color: AppColors.primary,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t?.translate('pickup') ?? 'Pickup',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    t?.translate('pickup_at_shop_desc') ??
                        'Customer will pick up this order at your shop.',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppColors.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
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
              _currentOrder.deliveryAddressTitle,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            GestureDetector(
              onTap: () {
                Clipboard.setData(
                  ClipboardData(text: _currentOrder.deliveryAddressDetail),
                );
                AppDialog.showToast(context, 'Address copied to clipboard');
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF4C0519)
                      : AppColors.errorContainer,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF881337)
                        : AppColors.errorLight,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GradientWidget(
                      child: Icon(PhosphorIconsRegular.copy, size: 14),
                    ),
                    SizedBox(width: 4),
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
        FarOrderDeliveryBanner(
          order: _currentOrder,
          shopLatitude: _shopLatitude,
          shopLongitude: _shopLongitude,
        ),
        SizedBox(height: 8),
        Text(
          _currentOrder.deliveryAddressDetail,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).textTheme.bodyLarge?.color,
            height: 1.5,
          ),
        ),
        if (_currentOrder.deliveryAddress?.addressMm != null &&
            _currentOrder.deliveryAddress!.addressMm!.trim().isNotEmpty &&
            _currentOrder.deliveryAddress!.addressMm!.trim() !=
                _currentOrder.deliveryAddressDetail)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              _currentOrder.deliveryAddress!.addressMm!.trim(),
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppColors.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ),
        if (_currentOrder.deliveryAddress?.buildingName != null ||
            _currentOrder.deliveryAddress?.floor != null)
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
        if (_currentOrder.deliveryAddress?.note != null &&
            _currentOrder.deliveryAddress!.note!.isNotEmpty)
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
                Icon(
                  PhosphorIconsRegular.note,
                  size: 16,
                  color: AppColors.onSurfaceVariant,
                ),
                SizedBox(width: 8),
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
        ? DateFormat(
            'MMM dd, yyyy - hh:mm a',
          ).format(_currentOrder.scheduledDeliveryTime!)
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
            decoration: BoxDecoration(
              color: AppColors.errorContainer,
              shape: BoxShape.circle,
            ),
            child: const GradientWidget(
              child: Icon(PhosphorIconsRegular.calendarCheck, size: 20),
            ),
          ),
          SizedBox(width: 12),
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
    final rider = _assignedRider;
    final name = _currentOrder.riderName?.trim().isNotEmpty == true
        ? _currentOrder.riderName!
        : (rider?.name ?? 'Assigning Rider...');
    final phone = (_currentOrder.riderPhone?.trim().isNotEmpty == true)
        ? _currentOrder.riderPhone
        : rider?.phone;
    final vehicleNo = (_currentOrder.deliveryCycleNo?.trim().isNotEmpty == true)
        ? _currentOrder.deliveryCycleNo
        : rider?.vehicleNo;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.5),
        ),
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
              child: Icon(PhosphorIconsFill.moped, size: 28),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color:
                        Theme.of(context).textTheme.bodyLarge?.color ??
                        AppColors.onSurface,
                  ),
                ),
                if (phone != null && phone.isNotEmpty)
                  Text(
                    phone,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color:
                          Theme.of(context).textTheme.bodyMedium?.color ??
                          AppColors.onSurfaceVariant,
                    ),
                  ),
                if (vehicleNo != null && vehicleNo.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: GradientText(
                      'Vehicle No: $vehicleNo',
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
        SizedBox(height: 16),
        ..._currentOrder.modifications.map(
          (mod) => Container(
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
                SizedBox(height: 4),
                Text(
                  'Modified by ${mod.modifiedBy} • ${DateFormat('hh:mm a').format(mod.createdAt)}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: const Color(0xFFEA580C),
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 16),
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
                color: (Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : const Color(0xFF1E293B)),
              ),
            ),
            if (_currentOrder.status == 'PENDING' ||
                _currentOrder.status == 'AWAITING_APPROVAL')
              TextButton.icon(
                onPressed: _showReviseItemsSheet,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: const GradientWidget(
                  child: Icon(PhosphorIconsRegular.warning, size: 16),
                ),
                label: GradientText(
                  'Revise items',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        SizedBox(height: 16),
        for (int i = 0; i < _currentOrder.items.length; i++)
          _buildOrderItem(
            _currentOrder.items[i],
            isLast: i == _currentOrder.items.length - 1,
          ),
      ],
    );
  }

  Widget _buildNoImageBox() {
    return Container(
      width: 54,
      height: 54,
      color: Theme.of(context).cardColor,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(PhosphorIconsRegular.image, size: 18, color: Color(0xFFCBD5E1)),
          SizedBox(height: 2),
          Text(
            'No Image',
            style: GoogleFonts.poppins(
              fontSize: 8,
              color: (Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF94A3B8)
                  : const Color(0xFF64748B)),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItem(OrderItemModel item, {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () {
              if (item.menuItemImageUrl != null && item.menuItemImageUrl!.isNotEmpty) {
                showDialog(
                  context: context,
                  builder: (context) => Dialog(
                    backgroundColor: Colors.transparent,
                    insetPadding: EdgeInsets.zero,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(color: Colors.black54),
                          ),
                        ),
                        Center(
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              InteractiveViewer(
                                child: Container(
                                  width: 300,
                                  height: 300,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    color: Theme.of(context).cardColor,
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: CachedNetworkImage(
                                      imageUrl: item.menuItemImageUrl!,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) =>
                                          const Center(child: CustomLoadingIndicator(size: 32)),
                                      errorWidget: (context, url, error) =>
                                          const Center(child: Icon(Icons.error, color: Colors.grey)),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                top: -15,
                                right: -15,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.7),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                  ),
                                  child: IconButton(
                                    padding: const EdgeInsets.all(4),
                                    constraints: const BoxConstraints(),
                                    icon: const Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    onPressed: () => Navigator.pop(context),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child:
                  item.menuItemImageUrl != null &&
                      item.menuItemImageUrl!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: item.menuItemImageUrl!,
                      width: 54,
                      height: 54,
                      fit: BoxFit.cover,
                      placeholder: (_, _) => Container(
                        width: 54,
                        height: 54,
                        color: Theme.of(context).cardColor,
                      ),
                      errorWidget: (_, _, _) => _buildNoImageBox(),
                    )
                  : _buildNoImageBox(),
            ),
          ),
          SizedBox(width: 12),
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
                              color:
                                  (Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.white
                                  : const Color(0xFF1E293B)),
                            ),
                          ),
                          if (item.secondaryName != null)
                            Text(
                              item.secondaryName!,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                                color:
                                    (Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? const Color(0xFFCBD5E1)
                                    : const Color(0xFF64748B)),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (item.optionsString != null &&
                    item.optionsString!.isNotEmpty)
                  Text(
                    item.optionsString!,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: (Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFFCBD5E1)
                          : const Color(0xFF64748B)),
                    ),
                  ),
                ...item.options.map(
                  (opt) => Text(
                    '+ ${opt.name} (+${opt.displayPrice})',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: (Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFFCBD5E1)
                          : const Color(0xFF64748B)),
                    ),
                  ),
                ),
                if (item.specialInstructions != null &&
                    item.specialInstructions!.isNotEmpty)
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
          SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '×${item.quantity}',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : const Color(0xFF94A3B8),
                ),
              ),
              SizedBox(height: 2),
              Text(
                item.displayPrice,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: (Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : const Color(0xFF1E293B)),
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
            color: (Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : const Color(0xFF1E293B)),
          ),
        ),
        if (_currentOrder.paymentSlipUrl != null && _currentOrder.paymentSlipUrl!.isNotEmpty) ...[
          SizedBox(height: 16),
          Row(
            children: [
              if (_currentOrder.paymentMethodIconUrl != null && _currentOrder.paymentMethodIconUrl!.isNotEmpty)
                CachedNetworkImage(
                  imageUrl: _currentOrder.paymentMethodIconUrl!,
                  width: 24,
                  height: 24,
                  fit: BoxFit.contain,
                )
              else
                Icon(
                  PhosphorIconsRegular.qrCode,
                  size: 20,
                  color: (Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFFCBD5E1)
                      : const Color(0xFF64748B)),
                ),
              SizedBox(width: 8),
              Text(
                _currentOrder.paymentMethodName ?? 'QR Prompt Pay',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: (Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFFCBD5E1)
                      : const Color(0xFF64748B)),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: _currentOrder.paymentSlipUrl!.startsWith('data:image')
                ? Image.memory(
                    base64Decode(
                      _currentOrder.paymentSlipUrl!.contains(',')
                          ? _currentOrder.paymentSlipUrl!.split(',').last
                          : _currentOrder.paymentSlipUrl!,
                    ),
                    width: double.infinity,
                    fit: BoxFit.cover,
                  )
                : CachedNetworkImage(
                    imageUrl: _currentOrder.paymentSlipUrl!,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      height: 200,
                      color: Theme.of(context).cardColor,
                      child: Center(child: CustomLoadingIndicator(size: 24)),
                    ),
                    errorWidget: (_, url, error) => _buildReceiptError(),
                  ),
          ),
        ],
        SizedBox(height: 16),
        _buildSummaryRow('Food Price', _currentOrder.foodPrice.toFormattedPrice()),
        if (_currentOrder.taxEnable) ...[
          SizedBox(height: 12),
          _buildSummaryRow(
            'Tax (7%)',
            _currentOrder.displayTaxAmount.isNotEmpty
                ? _currentOrder.displayTaxAmount
                : _currentOrder.resolvedTaxAmount.toFormattedPrice(),
          ),
        ],
        if (_currentOrder.discountAmount > 0 ||
            _currentOrder.shopCoupon?.isFreeItem == true) ...[
          SizedBox(height: 12),
          Row(
            children: [
              const GradientWidget(
                child: Icon(PhosphorIconsFill.ticket, size: 18),
              ),
              SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _currentOrder.couponName?.isNotEmpty == true
                          ? _currentOrder.couponName!
                          : 'Coupon Discount',
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        color: (Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFFCBD5E1)
                            : const Color(0xFF64748B)),
                      ),
                    ),
                    if (_couponDetailHint().isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        _couponDetailHint(),
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: (Theme.of(context).brightness == Brightness.dark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF94A3B8)),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(width: 8),
              Text(
                _currentOrder.discountAmount > 0
                    ? '- ${_currentOrder.displayDiscountAmount.isNotEmpty ? _currentOrder.displayDiscountAmount : _currentOrder.discountAmount.toFormattedPrice()}'
                    : (AppLocalizations.of(context)?.translate('coupon_free') ??
                        'FREE'),
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFED3973),
                ),
              ),
            ],
          ),
        ],
        SizedBox(height: 12),
        Row(
          children: [
            const GradientWidget(
              child: Icon(PhosphorIconsFill.moped, size: 20),
            ),
            SizedBox(width: 8),
            Text(
              _currentOrder.deliveryFee > 0 ? 'Delivery Fee' : 'Est. Amount',
              style: GoogleFonts.poppins(
                fontSize: 15,
                color: (Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFFCBD5E1)
                    : const Color(0xFF64748B)),
              ),
            ),
            SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _currentOrder.deliveryType == 'NORMAL'
                    ? 'Estimate'
                    : 'Delivery fee',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFFEF4444),
                ),
              ),
            ),
            const Spacer(),
            GradientText(
              _currentOrder.displayDeliveryFee.isNotEmpty
                  ? _currentOrder.displayDeliveryFee
                  : '+฿ 0',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                _currentOrder.deliveryType == 'NORMAL' ? 'Est Total' : 'Total',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: (Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : const Color(0xFF1E293B)),
                ),
              ),
            ),
            Row(
              children: [
                Text(
                  _currentOrder.displayTotalAmount.isNotEmpty
                      ? _currentOrder.displayTotalAmount
                      : _currentOrder.checkoutTotal.toFormattedPrice(),
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: (Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : const Color(0xFF1E293B)),
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
            color: (Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFFCBD5E1)
                : const Color(0xFF64748B)),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: (Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : const Color(0xFF1E293B)),
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
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Calculate delivery fee',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: (Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : const Color(0xFF1E293B)),
            ),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              _buildLaunchButton(
                'Bolt',
                'assets/icons/bolt_logo.png',
                const Color(0xFF32BB78),
              ),
              SizedBox(width: 16),
              _buildLaunchButton(
                'Grab',
                'assets/icons/grab_logo.png',
                const Color(0xFF00B14F),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLaunchButton(String name, String iconPath, Color color) {
    return InkWell(
      onTap: () async {
        final url = Uri.parse('${name.toLowerCase()}://');
        try {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        } catch (e) {
          _showAppNotInstalledSnackbar(context, name);
        }
      },
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
                  ? Text(
                      'Bolt',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    )
                  : Text(
                      'Grab',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Open $name',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: (Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFFCBD5E1)
                  : const Color(0xFF64748B)),
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
        break;
      case 'AWAITING_APPROVAL':
        mainButtonText = 'Confirm Payment';
        onPressed = _isUpdating ? null : _handleVerifyPayment;
        break;
      case 'PAYMENT_VERIFIED':
        mainButtonText = 'Accept order to cook';
        onPressed = _isUpdating ? null : _handlePrepareOrder;
        break;
      case 'PAYMENT_SLIP_REQUESTED':
        mainButtonText = 'Waiting for payment';
        onPressed = null;
        break;
      case 'COOKING':
        if (_currentOrder.isPickupFulfillment) {
          mainButtonText = 'Mark Ready for Pickup';
          onPressed = _isUpdating ? null : _handleMarkReadyForPickup;
        } else {
          mainButtonText = 'Picked Up by Rider';
          onPressed =
              (_isUpdating ||
                  (_selectedDriverId == null &&
                      _deliveryTrackingUrlController.text.trim().isEmpty))
              ? null
              : _handleDispatchOrder;
        }
        break;
      case 'READY_FOR_PICKUP':
        mainButtonText = 'Verify Pickup';
        onPressed = _isUpdating ? null : _openPickupCompleteScreen;
        break;
      case 'ON_THE_WAY':
        mainButtonText = 'Delivered';
        onPressed = _isUpdating ? null : _handleCompleteDelivery;
        break;
      case 'DELIVERED':
        return _buildDeliveredBanner();
      case 'PICKED_UP':
        return _buildPickedUpBanner();
      case 'CANCELED':
        return const SizedBox.shrink();
      case 'REVISED':
        mainButtonText = 'View Details';
        onPressed = null;
        break;
    }

    isCancelable = _isOrderCancelable(_currentOrder.status);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          top: BorderSide(color: Colors.black.withValues(alpha: 0.05)),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (isCancelable) ...[
                SizedBox(
                  width: 96,
                  child: PrimaryGradientButton(
                    onPressed: _isUpdating ? null : _handleCancelOrder,
                    height: 48,
                    borderRadius: 12,
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF4C0519)
                            : (Theme.of(context).brightness == Brightness.dark
                                  ? const Color(0xFF4C0519)
                                  : (Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? const Color(0xFF4C0519)
                                        : const Color(0xFFFFF1F2))),
                        Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF4C0519)
                            : (Theme.of(context).brightness == Brightness.dark
                                  ? const Color(0xFF4C0519)
                                  : (Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? const Color(0xFF4C0519)
                                        : const Color(0xFFFFF1F2))),
                      ],
                    ),
                    child: Center(
                      child: GradientText(
                        t?.translate('cancel') ?? 'Cancel',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10),
              ],
              if (_currentOrder.status == 'AWAITING_APPROVAL') ...[
                Expanded(
                  child: PrimaryGradientButton(
                    onPressed: _isUpdating ? null : _handleRequestSlip,
                    height: 54,
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF4C0519)
                            : (Theme.of(context).brightness == Brightness.dark
                                  ? const Color(0xFF4C0519)
                                  : (Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? const Color(0xFF4C0519)
                                        : const Color(0xFFFFF1F2))),
                        Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF4C0519)
                            : (Theme.of(context).brightness == Brightness.dark
                                  ? const Color(0xFF4C0519)
                                  : (Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? const Color(0xFF4C0519)
                                        : const Color(0xFFFFF1F2))),
                      ],
                    ),
                    child: Center(
                      child: GradientText(
                        'Revise',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
              ],
              Expanded(
                child: PrimaryGradientButton(
                  onPressed: onPressed,
                  isLoading: _isUpdating,
                  height: 54,
                  child: (_currentOrder.status == 'PAYMENT_SLIP_REQUESTED')
                      ? AnimatedEllipsisText(
                          text: mainButtonText,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: (onPressed == null || _isUpdating)
                                ? Colors.white.withValues(alpha: 0.6)
                                : Colors.white,
                          ),
                        )
                      : Text(
                          mainButtonText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: (onPressed == null || _isUpdating)
                                ? Colors.white.withValues(alpha: 0.6)
                                : Colors.white,
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
      decoration: BoxDecoration(gradient: AppColors.primaryGradient),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_rounded, color: Colors.white, size: 22),
          SizedBox(width: 10),
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

  Widget _buildPickedUpBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
      decoration: BoxDecoration(gradient: AppColors.primaryGradient),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_rounded, color: Colors.white, size: 22),
          SizedBox(width: 10),
          Text(
            AppLocalizations.of(context)?.translate('pickup_success_title') ??
                'Pickup complete',
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
      color: Theme.of(context).cardColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const GradientWidget(
                child: Icon(PhosphorIconsRegular.timer, size: 20),
              ),
              SizedBox(width: 8),
              Text(
                'Update Estimated Waiting Time',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: (Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : const Color(0xFF1E293B)),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
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
                color: (Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF94A3B8)
                    : const Color(0xFF64748B)),
              ),
              suffixText: 'mins',
              suffixIcon: ValueListenableBuilder<TextEditingValue>(
                valueListenable: _waitingTimeMinutesController,
                builder: (context, value, child) {
                  if (value.text.isEmpty) return const SizedBox.shrink();
                  return IconButton(
                    icon: Icon(Icons.clear, color: Colors.grey, size: 20),
                    onPressed: () {
                      _waitingTimeMinutesController.clear();
                      _validateFormState();
                    },
                  );
                },
              ),
              suffixStyle: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: (Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFFCBD5E1)
                    : const Color(0xFF64748B)),
              ),
              filled: true,
              fillColor: Theme.of(context).cardColor,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Theme.of(context).dividerColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Theme.of(context).dividerColor),
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

  /// Proof-of-delivery photo, shown while the order is ON_THE_WAY. The chosen
  /// image is sent on the "Delivered" action so the customer can see proof the
  /// food was successfully delivered.
  Widget _buildDeliveryProofSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Theme.of(context).cardColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Delivery Proof',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: (Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : const Color(0xFF1E293B)),
            ),
          ),
          SizedBox(height: 16),
          Align(
            alignment: Alignment.center,
            child: ImagePickerWidget(
              shape: ImagePickerShape.rectangle,
              width: 120,
              height: 120,
              themeGradient: AppColors.primaryGradient,
              pickedFile: _proofImage,
              onImageSelected: (file) => setState(() => _proofImage = file),
              onImageRemoved: () => setState(() => _proofImage = null),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Optional photo proving the food was delivered. Shown to the customer once the order is marked Delivered.',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: (Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFFCBD5E1)
                  : const Color(0xFF64748B)),
            ),
          ),
        ],
      ),
    );
  }

  /// Read-only proof-of-delivery photo shown once the order is DELIVERED.
  Widget _buildDeliveryProofView(String url) {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Theme.of(context).cardColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Delivery Proof',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: (Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : const Color(0xFF1E293B)),
            ),
          ),
          SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: CachedNetworkImage(
              imageUrl: url,
              width: double.infinity,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                height: 200,
                color: Theme.of(context).cardColor,
                child: Center(child: CustomLoadingIndicator(size: 24)),
              ),
              errorWidget: (_, url, error) => Container(
                width: double.infinity,
                height: 200,
                color: Theme.of(context).cardColor,
                child: Center(
                  child: Icon(
                    PhosphorIconsRegular.imageBroken,
                    size: 32,
                    color: Theme.of(context).dividerColor,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmationForm() {
    final t = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      color: Theme.of(context).cardColor,
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_currentOrder.status == 'PENDING') ...[
              if (_currentOrder.isPickupFulfillment) ...[
                Text(
                  t?.translate('pickup_confirmation') ?? 'Pickup confirmation',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: (Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : const Color(0xFF1E293B)),
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  t?.translate('pickup_confirmation_desc') ??
                      'Set how long the customer should wait before pickup.',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: (Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFFCBD5E1)
                        : const Color(0xFF64748B)),
                    height: 1.4,
                  ),
                ),
                SizedBox(height: 16),
                _buildInputField(
                  t?.translate('est_prep_time_mins') ?? 'Est Prep Time (mins)',
                  _waitingTimeMinutesController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) =>
                      (value == null || value.isEmpty) ? 'Required' : null,
                  description:
                      'Set the estimated preparation time for the order.',
                  placeholder: 'e.g. 15',
                ),
              ] else ...[
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
                            gradient: _deliveryOption == 'PREPAID'
                                ? AppColors.primaryGradient
                                : null,
                            color: _deliveryOption == 'PREPAID'
                                ? null
                                : (Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Theme.of(context).cardColor
                                      : (Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Theme.of(context).cardColor
                                            : const Color(0xFFF1F5F9))),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Fast Delivery',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _deliveryOption == 'PREPAID'
                                  ? Colors.white
                                  : (Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? const Color(0xFFCBD5E1)
                                        : const Color(0xFF64748B)),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
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
                            gradient: _deliveryOption == 'NORMAL'
                                ? AppColors.primaryGradient
                                : null,
                            color: _deliveryOption == 'NORMAL'
                                ? null
                                : (Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Theme.of(context).cardColor
                                      : (Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Theme.of(context).cardColor
                                            : const Color(0xFFF1F5F9))),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Flexible Delivery',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _deliveryOption == 'NORMAL'
                                  ? Colors.white
                                  : (Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? const Color(0xFFCBD5E1)
                                        : const Color(0xFF64748B)),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 24),
              ],
            ],
            // ── Section header ──────────────────────────────────────────
            if ((_deliveryOption == 'PREPAID' &&
                    _currentOrder.status == 'PENDING' &&
                    _currentOrder.isDeliveryFulfillment) ||
                (_currentOrder.status == 'COOKING' &&
                    _currentOrder.isDeliveryFulfillment)) ...[
              Text(
                _currentOrder.status == 'COOKING'
                    ? 'Dispatch Information'
                    : 'Prepare to confirm',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: (Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : const Color(0xFF1E293B)),
                ),
              ),
              SizedBox(height: 16),
            ],

            // ── Flexible Delivery (PENDING) ─────────────────────────────
            if (_deliveryOption == 'NORMAL' &&
                _currentOrder.status == 'PENDING' &&
                _currentOrder.isDeliveryFulfillment) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: Row(
                  children: [
                    const GradientWidget(
                      child: Icon(PhosphorIconsRegular.info, size: 22),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Flexible Delivery',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color:
                                  (Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.white
                                  : const Color(0xFF1E293B)),
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Shop admin choose delivery service to send food to customer. So user must pay order fee first and delivery fees later separately.',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color:
                                  (Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? const Color(0xFFCBD5E1)
                                  : const Color(0xFF64748B)),
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildInputField(
                      'Estimated Delivery Fee',
                      _deliveryFeeController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        ThousandsSeparatorInputFormatter(),
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) return null;
                        final numValue = value.replaceAll(',', '');
                        if (double.tryParse(numValue) == null) {
                          return 'Invalid number';
                        }
                        return null;
                      },
                      description:
                          'Enter the estimated delivery fee for this order.',
                      placeholder: 'e.g. 50',
                      showDeliveryApps: true,
                      suffixText: 'THB',
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _buildInputField(
                      'Est Prep Time (mins)',
                      _waitingTimeMinutesController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (value) =>
                          (value == null || value.isEmpty) ? 'Required' : null,
                      description:
                          'Set the estimated preparation time for the order.',
                      placeholder: 'e.g. 15',
                    ),
                  ),
                ],
              ),

              // ── Fast Delivery (PENDING): fee + waiting only ─────────────
            ] else if (_deliveryOption == 'PREPAID' &&
                _currentOrder.status == 'PENDING' &&
                _currentOrder.isDeliveryFulfillment) ...[
              Row(
                children: [
                  Expanded(
                    child: _buildInputField(
                      'Delivery Fee',
                      _deliveryFeeController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        ThousandsSeparatorInputFormatter(),
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Required';
                        final numValue = value.replaceAll(',', '');
                        if (double.tryParse(numValue) == null) {
                          return 'Invalid number';
                        }
                        return null;
                      },
                      description: 'Enter the delivery fee for this order.',
                      placeholder: 'e.g. 50',
                      showDeliveryApps: true,
                      suffixText: 'THB',
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _buildInputField(
                      'Est Waiting Time (mins)',
                      _waitingTimeMinutesController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (value) =>
                          (value == null || value.isEmpty) ? 'Required' : null,
                      description:
                          'Set the estimated waiting time for the order.',
                      placeholder: 'e.g. 15',
                    ),
                  ),
                ],
              ),

              // ── COOKING / dispatch (single driver selection point) ─────
            ] else if (_currentOrder.status == 'COOKING' &&
                _currentOrder.isDeliveryFulfillment) ...[
              if (_currentOrder.deliveryType == 'NORMAL') ...[
                _buildInputField(
                  'Real Delivery Fee',
                  _deliveryFeeController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    ThousandsSeparatorInputFormatter(),
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Required';
                    final numValue = value.replaceAll(',', '');
                    if (double.tryParse(numValue) == null) {
                      return 'Invalid number';
                    }
                    return null;
                  },
                  description:
                      'Enter the final real delivery fee for this flexible delivery.',
                  placeholder: 'e.g. 50',
                  showDeliveryApps: true,
                  suffixText: 'THB',
                ),
                SizedBox(height: 12),
              ],
              if (_deliveryTrackingUrlController.text.trim().isEmpty ||
                  _selectedDriverId != null)
                _buildDriverPicker(),
              if (_selectedDriverId == null) ...[
                if (_deliveryTrackingUrlController.text.trim().isEmpty)
                  SizedBox(height: 12),
                _buildInputField(
                  'Tracking URL',
                  _deliveryTrackingUrlController,
                  isNumeric: false,
                  modalTitle: 'Delivery Tracking Link',
                  description:
                      'Add a live tracking link so the customer can follow their order in real-time.',
                  fieldLabel: 'Tracking Link',
                  placeholder: 'https://tracking-service.com/...',
                  onChanged: _handleTrackingUrlChanged,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return null;
                    final uri = Uri.tryParse(value.trim());
                    if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
                      return 'Please enter a valid URL (e.g. https://...)';
                    }
                    return null;
                  },
                ),
              ],
            ] else if (_currentOrder.status == 'COOKING' &&
                _currentOrder.isPickupFulfillment) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: Text(
                  'Mark this order ready for pickup when the food is prepared. The customer can then show their QR code at the counter.',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: (Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFFCBD5E1)
                        : const Color(0xFF64748B)),
                    height: 1.5,
                  ),
                ),
              ),
            ] else if (_currentOrder.status == 'READY_FOR_PICKUP') ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: Text(
                  t?.translate('pickup_ready_hint') ??
                      'Hand the order to the customer and scan their QR code, or tap Verify Pickup when ready.',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: (Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFFCBD5E1)
                        : const Color(0xFF64748B)),
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInputField(
    String label,
    TextEditingController controller, {
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
    bool isNumeric = true,
    String? modalTitle,
    String? description,
    String? fieldLabel,
    String? placeholder,
    bool showDeliveryApps = false,
    String? suffixText,
    Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: (Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFFCBD5E1)
                : const Color(0xFF64748B)),
          ),
        ),
        SizedBox(height: 6),
        TextFormField(
          controller: controller,
          readOnly: true,
          onTap: () async {
            final result = await showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => _FullScreenTextInput(
                label: modalTitle ?? label,
                initialValue: controller.text,
                keyboardType: keyboardType,
                inputFormatters: inputFormatters,
                isNumeric: isNumeric,
                description: description,
                fieldLabel: fieldLabel,
                placeholder: placeholder,
                showDeliveryApps: showDeliveryApps,
                suffixText: suffixText,
              ),
            );
            if (result != null) {
              controller.text = result as String;
              if (onChanged != null) onChanged(result);
              _validateFormState();
            }
          },
          validator: validator,
          style: GoogleFonts.poppins(fontSize: 14),
          decoration: InputDecoration(
            filled: true,
            fillColor: Theme.of(context).cardColor,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Theme.of(context).dividerColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Theme.of(context).dividerColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppColors.primary),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.red, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.red, width: 2),
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
        final base64Str = slipUrl.contains(',')
            ? slipUrl.split(',').last
            : slipUrl;
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
        child: CachedNetworkImage(
          imageUrl: slipUrl,
          width: double.infinity,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            height: 200,
            color: Theme.of(context).cardColor,
            child: Center(child: CustomLoadingIndicator(size: 24)),
          ),
          errorWidget: (_, url, error) => _buildReceiptError(),
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
                color: (Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : const Color(0xFF1E293B)),
              ),
            ),
            Row(
              children: [
                if (_currentOrder.paymentMethodIconUrl != null && _currentOrder.paymentMethodIconUrl!.isNotEmpty)
                  CachedNetworkImage(
                    imageUrl: _currentOrder.paymentMethodIconUrl!,
                    width: 20,
                    height: 20,
                    fit: BoxFit.contain,
                  )
                else
                  Icon(
                    PhosphorIconsRegular.qrCode,
                    size: 20,
                    color: (Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFFCBD5E1)
                        : const Color(0xFF64748B)),
                  ),
                SizedBox(width: 8),
                Text(
                  _currentOrder.paymentMethodName ?? 'QR Prompt Pay',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: (Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFFCBD5E1)
                        : const Color(0xFF64748B)),
                  ),
                ),
              ],
            ),
          ],
        ),
        SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                _currentOrder.deliveryType == 'NORMAL' ? 'Est Total' : 'Total',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: (Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFFCBD5E1)
                      : const Color(0xFF64748B)),
                ),
              ),
            ),
            Text(
              _currentOrder.displayTotalAmount,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: (Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : const Color(0xFF1E293B)),
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        imageWidget,
      ],
    );
  }

  Widget _buildReceiptError() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            PhosphorIconsRegular.warningCircle,
            color: (Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF94A3B8)
                : const Color(0xFF64748B)),
            size: 32,
          ),
          SizedBox(height: 8),
          Text(
            'Failed to load receipt',
            style: GoogleFonts.poppins(
              color: (Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFFCBD5E1)
                  : const Color(0xFF64748B)),
              fontSize: 13,
            ),
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
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
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

class _StatusHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;

  _StatusHeaderDelegate({required this.child, required this.height});

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(covariant _StatusHeaderDelegate oldDelegate) {
    return oldDelegate.height != height || oldDelegate.child != child;
  }
}

class _FullScreenTextInput extends StatefulWidget {
  final String label;
  final String initialValue;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final bool isNumeric;
  final String? description;
  final String? fieldLabel;
  final String? placeholder;
  final bool showDeliveryApps;
  final String? suffixText;

  const _FullScreenTextInput({
    required this.label,
    required this.initialValue,
    this.keyboardType,
    this.inputFormatters,
    this.isNumeric = true,
    this.description,
    this.fieldLabel,
    this.placeholder,
    this.showDeliveryApps = false,
    this.suffixText,
  });

  @override
  State<_FullScreenTextInput> createState() => _FullScreenTextInputState();
}

class _FullScreenTextInputState extends State<_FullScreenTextInput> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }


  Widget _buildAppIcon({
    required String name,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: Text(
              name,
              style: GoogleFonts.poppins(
                color: Theme.of(context).cardColor,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Open $name',
            style: GoogleFonts.poppins(
              color: (Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFFCBD5E1)
                  : const Color(0xFF64748B)),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.5,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.label,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: (Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : const Color(0xFF1E293B)),
              ),
            ),
            if (widget.description != null) ...[
              SizedBox(height: 8),
              Text(
                widget.description!,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: (Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFFCBD5E1)
                      : const Color(0xFF64748B)),
                ),
              ),
            ],
            SizedBox(height: 24),
            if (widget.showDeliveryApps) ...[
              Text(
                'Calculate delivery fee',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: (Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : const Color(0xFF1E293B)),
                ),
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  _buildAppIcon(
                    name: 'Bolt',
                    color: const Color(0xFF32C671),
                    onTap: () async {
                      final url = Uri.parse('bolt://');
                      try {
                        await launchUrl(
                          url,
                          mode: LaunchMode.externalApplication,
                        );
                      } catch (e) {
                        _showAppNotInstalledSnackbar(context, 'Bolt');
                      }
                    },
                  ),
                  SizedBox(width: 24),
                  _buildAppIcon(
                    name: 'Grab',
                    color: const Color(0xFF00B14F),
                    onTap: () async {
                      final url = Uri.parse('grab://open');
                      try {
                        await launchUrl(
                          url,
                          mode: LaunchMode.externalApplication,
                        );
                      } catch (e) {
                        _showAppNotInstalledSnackbar(context, 'Grab');
                      }
                    },
                  ),
                ],
              ),
              SizedBox(height: 24),
            ],
            if (widget.fieldLabel != null) ...[
              Text(
                widget.fieldLabel!,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: (Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFFCBD5E1)
                      : const Color(0xFF64748B)),
                ),
              ),
              SizedBox(height: 8),
            ],
            TextField(
              controller: _controller,
              keyboardType: widget.keyboardType,
              inputFormatters: widget.inputFormatters,
              autofocus: true,
              style: GoogleFonts.poppins(fontSize: 14),
              decoration: InputDecoration(
                filled: true,
                fillColor: Theme.of(context).cardColor,
                hintText: widget.placeholder ?? 'Enter ${widget.label}',
                hintStyle: GoogleFonts.poppins(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF64748B)
                      : const Color(0xFF94A3B8),
                ),
                suffixText: widget.suffixText,
                suffixStyle: GoogleFonts.poppins(
                  color: (Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFFCBD5E1)
                      : const Color(0xFF64748B)),
                  fontWeight: FontWeight.w500,
                ),
                suffixIcon: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _controller,
                  builder: (context, value, child) {
                    if (value.text.isEmpty) return const SizedBox.shrink();
                    return IconButton(
                      icon: Icon(Icons.clear, color: Colors.grey, size: 20),
                      onPressed: () {
                        _controller.clear();
                      },
                    );
                  },
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.primary),
                ),
              ),
            ),
            SizedBox(height: 12),
            if (widget.fieldLabel != null ||
                widget.description !=
                    null) // Only show paste for tracking url or similar
              GestureDetector(
                onTap: () async {
                  final data = await Clipboard.getData('text/plain');
                  if (data?.text != null) {
                    _controller.text = data!.text!;
                  }
                },
                child: Row(
                  children: [
                    Icon(
                      PhosphorIconsRegular.clipboard,
                      color: Color(0xFFE11D48),
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Paste from Clipboard',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFFE11D48),
                      ),
                    ),
                  ],
                ),
              ),
            const Spacer(),
            PrimaryGradientButton(
              onPressed: () {
                Navigator.pop(context, _controller.text);
              },
              text: 'Save',
              height: 56,
              borderRadius: 16,
            ),
          ],
        ),
      ),
    );
  }
}
