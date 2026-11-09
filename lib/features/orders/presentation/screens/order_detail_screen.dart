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
import 'package:my_shop/features/profile/presentation/widgets/language_selector_sheet.dart';
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
import 'package:my_shop/features/chat/data/models/chat_window.dart';
import 'package:my_shop/features/chat/data/services/chat_service.dart';
import 'package:my_shop/features/chat/data/services/chat_unread_controller.dart';
import 'package:my_shop/features/chat/presentation/chat_navigation.dart';
import 'package:my_shop/features/orders/presentation/screens/pickup_complete_screen.dart';
import 'package:my_shop/features/orders/presentation/screens/live_delivery_tracking_screen.dart';
import 'package:my_shop/features/orders/presentation/widgets/order_qr_scan_icon.dart';
import 'package:my_shop/features/call/data/shop_call_session.dart';
import 'package:my_shop/features/call/presentation/outgoing_call_screen.dart';
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
  Timer? _chatWindowTicker;
  int _chatUnreadCount = 0;
  int _chatConversationId = 0;
  _IncomingFloatingNotificationData? _activeFloatingNotification;
  bool _isUpdating = false;
  bool _isFirstLoading = true;

  // Controllers for Confirmation Details
  final _deliveryFeeController = TextEditingController();
  final _deliveryCycleNoController = TextEditingController();
  final _deliveryRiderNameController = TextEditingController();
  final _deliveryPhoneNoController = TextEditingController();
  final _deliveryTrackingUrlController = TextEditingController();
  final _waitingTimeMinutesController = TextEditingController();
  final _transactionDiscountController = TextEditingController();
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
  bool _isShopVerified = false;
  bool _isDispatchingLalamove = false;
  bool get _isOrderVerifiedFlow =>
      _isShopVerified ||
      _currentOrder.isVerified ||
      _currentOrder.isOmisePayment ||
      _currentOrder.isLalamoveDelivery ||
      (_currentOrder.trackingUrl != null &&
          _currentOrder.trackingUrl!.trim().isNotEmpty);
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
    _startChatWindowTicker();
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
  /// displays floating messenger-style notification for incoming messages,
  /// and clears it immediately when the thread is read from another screen.
  void _setupChatListener() {
    _chatSubscription = WebSocketService().chatUpdates.listen((event) {
      _fetchChatUnreadCount();
      _handleIncomingChatMessage(event);
    });
    _chatReadSubscription = ChatUnreadController.instance.conversationRead
        .listen((conversationId) {
          if (!mounted || _chatUnreadCount == 0) return;
          if (conversationId == _chatConversationId) {
            setState(() => _chatUnreadCount = 0);
          }
        });
  }

  void _handleIncomingChatMessage(Map<String, dynamic> event) {
    if (!mounted) return;
    final type = event['type']?.toString();
    if (type != 'CHAT_MESSAGE') return;

    final raw = (event['message'] as Map?)?.cast<String, dynamic>();
    if (raw == null) return;

    final incoming = ChatMessage.fromJson(raw);
    if (incoming.isMe) return; // Do not notify for shop's own messages

    // If chat is actively open for this conversation, don't show floating noti
    final convId = incoming.conversationId ?? (event['conversationId'] as num?)?.toInt() ?? 0;
    if (convId > 0 && ChatUnreadController.instance.activeConversationId == convId) {
      return;
    }

    String previewText = incoming.content?.trim() ?? '';
    if (previewText.isEmpty) {
      if (incoming.kind == ChatMessageKind.image || incoming.attachments.any((a) => a.isImage)) {
        previewText = '📷 Sent a photo';
      } else if (incoming.kind == ChatMessageKind.voice || incoming.attachments.any((a) => a.isVoice)) {
        previewText = '🎤 Voice message';
      } else {
        previewText = 'Sent a message';
      }
    }

    final senderName = incoming.senderName?.trim().isNotEmpty == true
        ? incoming.senderName!.trim()
        : _currentOrder.customerName;
    final senderAvatar = incoming.senderAvatarUrl ?? _currentOrder.customerAvatar;

    setState(() {
      _activeFloatingNotification = _IncomingFloatingNotificationData(
        senderName: senderName.isNotEmpty ? senderName : 'Customer',
        senderAvatar: senderAvatar,
        messageText: previewText,
        onTap: () {
          setState(() => _activeFloatingNotification = null);
          _openChatForIncomingMessage(
            conversationId: convId,
            senderName: senderName,
          );
        },
        onDismiss: () {
          if (mounted) {
            setState(() => _activeFloatingNotification = null);
          }
        },
      );
    });
  }

  Future<void> _openChatForIncomingMessage({
    required int conversationId,
    required String senderName,
  }) async {
    final orderId = int.tryParse(_currentOrder.id) ?? 0;
    if (conversationId <= 0 || conversationId == _chatConversationId) {
      await _openCustomerChat();
      return;
    }

    final chatConversation = ChatConversation(
      id: conversationId,
      orderId: orderId,
      name: senderName.isNotEmpty ? senderName : _currentOrder.customerName,
      orderNo: _currentOrder.lastOrderNo,
      orderStatus: _currentOrder.status,
      orderUpdatedAt: _currentOrder.updatedAt,
      lastMessage: '',
      timestamp: DateTime.now(),
    );

    await ChatNavigation.open(context, chatConversation);
    if (!mounted) return;
    setState(() => _chatUnreadCount = 0);
    _fetchChatUnreadCount();
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
      _isShopVerified = profile.isVerified;
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
    if (_isFreeDeliveryLocked) {
      _deliveryFeeController.text = 'FREE';
    } else {
      _deliveryFeeController.text = _currentOrder.deliveryFee > 0
          ? formatter.format(_currentOrder.deliveryFee)
          : '';
    }
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
    _transactionDiscountController.text = _currentOrder.transactionDiscount > 0
        ? formatter.format(_currentOrder.transactionDiscount)
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
      _startChatWindowTicker();
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
    _chatWindowTicker?.cancel();
    _deliveryFeeController.dispose();
    _deliveryCycleNoController.dispose();
    _deliveryRiderNameController.dispose();
    _deliveryPhoneNoController.dispose();
    _deliveryTrackingUrlController.dispose();
    _waitingTimeMinutesController.dispose();
    _transactionDiscountController.dispose();
    super.dispose();
  }

  DateTime? get _chatClosesAt =>
      ChatWindow.closesAt(_currentOrder.status, _currentOrder.updatedAt);

  bool get _isChatWritable =>
      ChatWindow.isWritable(_currentOrder.status, _currentOrder.updatedAt);

  String get _chatTimeLeft => ChatWindow.compactTimeLeft(_chatClosesAt);

  void _startChatWindowTicker() {
    _chatWindowTicker?.cancel();
    if (_chatClosesAt == null) return;
    _chatWindowTicker = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (!mounted) return;
      setState(() {});
      if (!_isChatWritable) timer.cancel();
    });
  }

  void _addFormListeners() {
    _deliveryFeeController.addListener(_validateFormState);
    _deliveryCycleNoController.addListener(_validateFormState);
    _deliveryRiderNameController.addListener(_validateFormState);
    _deliveryPhoneNoController.addListener(_validateFormState);
    _waitingTimeMinutesController.addListener(_validateFormState);
    _deliveryTrackingUrlController.addListener(_validateFormState);
    _transactionDiscountController.addListener(_onPricingFieldsChanged);
  }

  void _onPricingFieldsChanged() {
    if (!mounted) return;
    setState(() {});
    _validateFormState();
  }

  /// Fee field lock: live promo only while PENDING (pre-confirm).
  /// After confirm, only the order's [isFreeDelivery] snapshot applies.
  bool get _isFreeDeliveryLocked {
    if (!_currentOrder.isDeliveryFulfillment) return false;
    if (_currentOrder.status == 'PENDING') {
      return _currentOrder.freeDeliveryActive;
    }
    return _currentOrder.isFreeDelivery;
  }

  void _validateFormState() {
    final fee = _deliveryFeeController.text.replaceAll(',', '');
    final waiting = _waitingTimeMinutesController.text;
    final freeDelivery = _isFreeDeliveryLocked;
    final isVerified = _isOrderVerifiedFlow;

    bool isValid = false;

    if (_currentOrder.status == 'PENDING') {
      if (isVerified) {
        // Verified shop: delivery fee is automated via Lalamove. Preparation time selected on Accept.
        isValid = true;
      } else if (_currentOrder.isPickupFulfillment) {
        isValid = true;
      } else if (_deliveryOption == 'NORMAL') {
        // Flexible Delivery: preparation time selected on Accept
        isValid = true;
      } else {
        // Fast Delivery (PENDING): fee required unless FREE promo
        isValid = freeDelivery || (fee.isNotEmpty && double.tryParse(fee) != null);
      }
      if (isValid &&
          !isVerified &&
          _parsedTransactionDiscount() >
              _payableBeforeTransactionDiscount()) {
        isValid = false;
      }
    } else if (_currentOrder.status == 'AWAITING_APPROVAL') {
      isValid = true;
    } else if (_currentOrder.status == 'COOKING') {
      bool baseValid =
          _currentOrder.isPickupFulfillment ||
          _selectedDriverId != null ||
          _deliveryTrackingUrlController.text.trim().isNotEmpty ||
          isVerified;
      if (!_currentOrder.isPickupFulfillment &&
          _currentOrder.deliveryType == 'NORMAL') {
        isValid = baseValid &&
            (freeDelivery ||
                (fee.isNotEmpty && double.tryParse(fee) != null));
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
      final orderId = event['orderId']?.toString() ??
          event['id']?.toString() ??
          (event['order'] is Map ? (event['order']['id'] ?? event['order']['orderId'])?.toString() : null);
      if (orderId != null && orderId == _currentOrder.id.toString()) {
        final eventType = (event['eventType'] ??
                (event['order'] is Map ? event['order']['eventType'] : null))
            ?.toString()
            .toUpperCase();
        // Ignore pure driver GPS telemetry & nearby alerts - they are for live tracking maps, NOT for resetting/reloading the order screen!
        if (eventType == 'DRIVER_LOCATION' ||
            eventType == 'RIDER_LOCATION' ||
            eventType == 'RIDER_NEARBY') {
          return;
        }

        debugPrint('Real-time update received for Order ${_currentOrder.id}');

        final previousStatus = _currentOrder.status;

        setState(() {
          _isUpdating = true;
          // If the event contains a full order object, we can reconstruct it
          // for an instant status/items refresh.
          if (event['order'] != null && event['order'] is Map<String, dynamic>) {
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
      ((_currentOrder.status == 'COOKING' && (_currentOrder.trackingUrl != null && _currentOrder.trackingUrl!.trim().isNotEmpty)) ||
          _currentOrder.status == 'ON_THE_WAY' ||
          _currentOrder.status == 'DELIVERED') &&
      (_assignedRider != null ||
          (_currentOrder.riderName != null &&
              _currentOrder.riderName!.trim().isNotEmpty) ||
          (_currentOrder.trackingUrl != null &&
              _currentOrder.trackingUrl!.trim().isNotEmpty));

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

  Future<void> _handleShowPreparationTimeAndConfirm() async {
    final isVerified = _isOrderVerifiedFlow;
    if (!isVerified && !(_formKey.currentState?.validate() ?? true)) {
      return;
    }

    int selectedMinutes = int.tryParse(_waitingTimeMinutesController.text) ?? 20;
    if (selectedMinutes < 5) selectedMinutes = 20;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final confirmed = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          final now = DateTime.now();
          final readyTime = now.add(Duration(minutes: selectedMinutes));
          final timeStr =
              "${readyTime.hour % 12 == 0 ? 12 : readyTime.hour % 12}:${readyTime.minute.toString().padLeft(2, '0')} ${readyTime.hour >= 12 ? 'PM' : 'AM'}";

          return Container(
            padding: EdgeInsets.fromLTRB(
              24,
              16,
              24,
              MediaQuery.of(context).padding.bottom + 20,
            ),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.12),
                  blurRadius: 20,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top drag handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // Header with Timer icon and title
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF6A00).withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        PhosphorIconsFill.timer,
                        color: Color(0xFFFF6A00),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Preparation Time',
                            style: GoogleFonts.poppins(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            'Select estimated time to cook before courier pickup',
                            style: GoogleFonts.poppins(
                              fontSize: 12.5,
                              color: isDark ? Colors.white60 : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Quick Preset Options starting from 5m!
                Text(
                  'Quick Select:',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : const Color(0xFF475569),
                  ),
                ),
                const SizedBox(height: 10),

                // Presets: [5m, 10m, 15m, 20m, 25m, 30m, 45m, 60m]
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [5, 10, 15, 20, 25, 30, 45, 60].map((mins) {
                    final isSelected = selectedMinutes == mins;
                    return InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => setSheetState(() => selectedMinutes = mins),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          gradient: isSelected ? AppColors.primaryGradient : null,
                          color: isSelected
                              ? null
                              : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9)),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? Colors.transparent
                                : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                            width: 1,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFFED3973).withValues(alpha: 0.35),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ]
                              : null,
                        ),
                        child: Text(
                          '$mins m',
                          style: GoogleFonts.poppins(
                            fontSize: 13.5,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                            color: isSelected
                                ? Colors.white
                                : (isDark ? Colors.white : const Color(0xFF1E293B)),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 18),

                // Fine-tune Stepper (Starts from 5m min)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Fine-tune Time:',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white70 : const Color(0xFF64748B),
                        ),
                      ),
                      const Spacer(),
                      // Minus button
                      GestureDetector(
                        onTap: () {
                          if (selectedMinutes > 5) {
                            setSheetState(() => selectedMinutes -= 5);
                          }
                        },
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                            ),
                          ),
                          child: const Icon(PhosphorIconsBold.minus, size: 14),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Text(
                          '$selectedMinutes mins',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      // Plus button
                      GestureDetector(
                        onTap: () {
                          if (selectedMinutes < 180) {
                            setSheetState(() => selectedMinutes += 5);
                          }
                        },
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                            ),
                          ),
                          child: const Icon(PhosphorIconsBold.plus, size: 14),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Estimated Ready notice
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFED3973).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        PhosphorIconsFill.clock,
                        size: 16,
                        color: Color(0xFFED3973),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Estimated ready by $timeStr (in $selectedMinutes mins)',
                          style: GoogleFonts.poppins(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFED3973),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Confirm & Accept Order Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: PrimaryGradientButton(
                    onPressed: () => Navigator.pop(sheetContext, selectedMinutes),
                    borderRadius: 16,
                    gradient: AppColors.primaryGradient,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(PhosphorIconsBold.check, color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Confirm & Accept Order',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    if (confirmed != null && mounted) {
      setState(() {
        _waitingTimeMinutesController.text = confirmed.toString();
      });
      await _handleConfirmOrder();
    }
  }

  Future<void> _handleConfirmOrder() async {
    final isVerified = _isOrderVerifiedFlow;
    if (!isVerified && !(_formKey.currentState?.validate() ?? true)) {
      return;
    }

    final orderDeliveryType = isVerified
        ? 'FAST'
        : (_deliveryOption == 'NORMAL' ? 'FLEXIBLE' : 'FAST');
    final isPickup = _currentOrder.isPickupFulfillment;
    final deliveryFee = isPickup || _isFreeDeliveryLocked
        ? 0.0
        : (isVerified
            ? (_currentOrder.deliveryFee > 0
                ? _currentOrder.deliveryFee
                : (double.tryParse(_deliveryFeeController.text.replaceAll(',', '')) ?? 0.0))
            : (double.tryParse(_deliveryFeeController.text.replaceAll(',', '')) ?? 0.0));

    await _runOrderAction(
      action: () => OrderService().confirmOrder(
        _currentOrder.id.toString(),
        orderDeliveryType: orderDeliveryType,
        deliveryFee: deliveryFee,
        waitingTimeMinutes:
            int.tryParse(_waitingTimeMinutesController.text) ?? 20,
        transactionDiscount: isVerified ? 0.0 : _parsedTransactionDiscount(),
        driverId: _selectedDriverId,
      ),
      errorMessage: 'Failed to confirm order. Please try again.',
      onSuccess: () {
        if (!mounted) return;
        final t = AppLocalizations.of(context);
        AppDialog.showToast(
          context,
          isVerified
              ? (t?.translate('order_confirmed_payment_requested') ??
                  'Order confirmed! Awaiting customer direct payment.')
              : 'Order confirmed! Bill sent to customer.',
          isError: false,
        );
      },
    );
  }

  double _parsedTransactionDiscount() {
    final raw = _transactionDiscountController.text.replaceAll(',', '').trim();
    if (raw.isEmpty) return 0;
    return double.tryParse(raw) ?? 0;
  }

  double _payableBeforeTransactionDiscount() {
    final itemPrice = _currentOrder.foodPrice;
    final tax = _currentOrder.taxEnable ? _currentOrder.resolvedTaxAmount : 0.0;
    final coupon = _currentOrder.discountAmount;
    final isPickup = _currentOrder.isPickupFulfillment;
    final isFlexible = _deliveryOption == 'NORMAL';
    final fee = isPickup || isFlexible || _isFreeDeliveryLocked
        ? 0.0
        : (double.tryParse(_deliveryFeeController.text.replaceAll(',', '')) ??
              0);
    return ((itemPrice + fee + tax - coupon) * 100).round() / 100;
  }

  String _freeDeliveryExplanation() {
    // After confirm, the order snapshot owns FREE — don't imply the promo is still live.
    if (_currentOrder.status != 'PENDING' && _currentOrder.isFreeDelivery) {
      return 'This order was confirmed with free delivery. The fee stays FREE.';
    }

    final source = _currentOrder.freeDeliverySource.toUpperCase();
    final end = (source == 'GLOBAL' || source == 'BOTH')
        ? (_currentOrder.globalFreeDeliveryEndsAt ??
            _currentOrder.freeDeliveryEndsAt)
        : _currentOrder.freeDeliveryEndsAt;
    final endText = end != null
        ? ' until ${DateFormat('d MMM yyyy, h:mm a').format(end.toLocal())}'
        : '';

    if (source == 'GLOBAL') {
      return 'Platform free delivery is on$endText (set by MyTogether). The fee field is locked.';
    }
    if (source == 'BOTH') {
      return 'Platform and shop free delivery are on$endText (set by MyTogether). The fee field is locked.';
    }
    if (end != null) {
      return 'Free delivery is on for this shop$endText (set by MyTogether). The fee field is locked.';
    }
    final start = _currentOrder.freeDeliveryStartsAt;
    if (start != null) {
      final formatted =
          DateFormat('d MMM yyyy, h:mm a').format(start.toLocal());
      return 'Free delivery is on for this shop from $formatted (set by MyTogether). The fee field is locked.';
    }
    return 'Free delivery is on for this shop (set by MyTogether). The fee field is locked.';
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
                  color: const Color(0xFFED3973).withValues(alpha: 0.1),
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
                  color: isDark
                      ? const Color(0xFFCBD5E1)
                      : const Color(0xFF64748B),
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
    final waitingMins = int.tryParse(_waitingTimeMinutesController.text);
    await _runOrderAction(
      action: () => OrderService().prepareOrder(
        _currentOrder.id.toString(),
        waitingTimeMinutes: waitingMins,
      ),
      errorMessage: 'Failed to prepare order. Please try again.',
      onSuccess: () {
        if (!mounted) return;
        AppDialog.showToast(context, 'Cooking started!', isError: false);
      },
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
          transactionDiscount: _currentOrder.transactionDiscount,
        ),
        errorMessage: 'Failed to request new slip. Please try again.',
      );
    }
  }

  bool get _isCustomerLocationInvalid {
    if (!_currentOrder.isDeliveryFulfillment) return false;
    final lat = _currentOrder.lat;
    final lon = _currentOrder.lon;
    if (lat == null || lon == null || lat == 0 || lon == 0) return true;
    if (lat < 5.5 || lat > 20.5 || lon < 97.0 || lon > 106.5) return true;
    return false;
  }

  /// Shop may cancel before customer uploads payment, OR if delivery location is invalid/broken.
  bool _isOrderCancelable(String status) {
    if (status == 'DELIVERED' || status == 'CANCELED' || status == 'PICKED_UP') {
      return false;
    }
    if (_isCustomerLocationInvalid) return true;
    return status == 'PENDING' ||
        status == 'REVISED' ||
        status == 'PAYMENT_SLIP_REQUESTED';
  }

  void _showInvalidLocationDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            const Icon(PhosphorIconsFill.warningCircle, color: Color(0xFFEF4444), size: 24),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Invalid Delivery Pin',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        ),
        content: Text(
          'Customer delivery GPS map pin is missing or invalid. Lalamove courier cannot route to this destination.\n\nTo protect your shop from wasted food & rider fees, you can cancel this order or contact the customer.',
          style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF64748B), height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (_currentOrder.customerPhone.isNotEmpty) {
                _callCustomer();
              }
            },
            child: Text(
              'Call Customer',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: const Color(0xFF0284C7)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _handleCancelOrder();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
              'Cancel Order',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleCancelOrder() async {
    final hasLalamoveRider = _currentOrder.trackingUrl != null &&
        _currentOrder.trackingUrl!.toLowerCase().contains('lalamove');

    if (hasLalamoveRider) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: const [
              Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
              SizedBox(width: 8),
              Text(
                'Cancellation Warning',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: const Text(
            'A Lalamove rider has already been dispatched for this order.\n\n'
            'Canceling now will incur a ุ30 cancellation fee charged to your shop, '
            'and the customer will receive a 100% total full refund.\n\n'
            'Are you sure you want to proceed?',
            style: TextStyle(fontSize: 13, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Keep Order'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Confirm & Accept ุ30 Fee'),
            ),
          ],
        ),
      );
      if (!mounted || confirmed != true) return;
    }
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
      builder: (sheetContext) =>
          MediaQuery(data: staticMediaQuery, child: const CancelOrderDialog()),
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
    if (_isFreeDeliveryLocked) {
      finalDeliveryFee = 0;
    } else if (_deliveryFeeController.text.isNotEmpty &&
        _deliveryFeeController.text.toUpperCase() != 'FREE') {
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

  String _getLocalizedStatusName(OrderModel order, BuildContext context) {
    final t = AppLocalizations.of(context);
    final status = order.status.toUpperCase();
    if (order.isOmisePayment && (status == 'PAYMENT_SLIP_REQUESTED' || status == 'PAYMENT')) {
      final lang = LocalizationService.instance.localeNotifier.value.languageCode;
      if (lang == 'my') return 'တိုက်ရိုက်ပေးချေမှု စောင့်ဆိုင်းနေသည်';
      if (lang == 'th') return 'รอชำระเงินอัตโนมัติ';
      return 'Awaiting Direct Payment';
    }
    switch (status) {
      case 'PENDING':
      case 'NEW':
        return t?.translate('tab_new') ?? 'New Order';
      case 'PAYMENT_SLIP_REQUESTED':
        return t?.translate('waiting_payment') ?? 'Waiting for Payment';
      case 'AWAITING_APPROVAL':
        return t?.translate('tab_payment') ?? 'Awaiting Approval';
      case 'PAYMENT_VERIFIED':
        final lang = LocalizationService.instance.localeNotifier.value.languageCode;
        if (lang == 'my') return 'ငွေပေးချေမှု အတည်ပြုပြီး';
        if (lang == 'th') return 'ยืนยันการชำระเงินแล้ว';
        return 'Payment Verified';
      case 'COOKING':
      case 'PREPARING':
        return t?.translate('tab_preparing') ?? 'Preparing';
      case 'READY_FOR_PICKUP':
        return t?.translate('tab_ready_for_pickup') ?? 'Ready for Pickup';
      case 'ON_THE_WAY':
      case 'DELIVERING':
        return t?.translate('tab_delivering') ?? 'Delivering';
      case 'DELIVERED':
        return t?.translate('tab_delivered') ?? 'Delivered';
      case 'PICKED_UP':
        return t?.translate('tab_picked_up') ?? 'Picked Up';
      case 'CANCELED':
        return t?.translate('tab_cancelled') ?? 'Cancelled';
      default:
        return order.statusName;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBack();
      },
      child: Stack(
        children: [
          Scaffold(
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
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ),
                  _currentOrder.status == 'CANCELED'
                      ? Text(
                          _getLocalizedStatusName(_currentOrder, context),
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFFEF4444),
                          ),
                        )
                      : GradientText(
                          _getLocalizedStatusName(_currentOrder, context),
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                ],
              ),
              actions: [
                if (_showPickupScanAction) const OrderQrScanIcon(),
                const SizedBox(width: 8),
              ],
            ),
            body: _isFirstLoading
                ? _buildSkeletonDetail()
                : AnimatedOpacity(
                    duration: const Duration(milliseconds: 300),
                    opacity: _isUpdating ? 0.6 : 1.0,
                    child: _isOrderVerifiedFlow
                        ? _buildVerifiedShopCleanOrderView()
                        : _buildLegacyOrderView(),
                  ),
          ),
          if (_activeFloatingNotification != null)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: _FloatingMessengerNotificationBanner(
                  key: ValueKey(_activeFloatingNotification.hashCode),
                  data: _activeFloatingNotification!,
                ),
              ),
            ),
        ],
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

  Widget _buildCompletedOrderChatAction() {
    if (!_isChatWritable && _chatConversationId <= 0) {
      return const SizedBox.shrink();
    }

    final t = AppLocalizations.of(context);
    final timeLeft = _chatTimeLeft;
    final isOpen = _isChatWritable;
    final label = isOpen
        ? [
            t?.translate('message_customer') ?? 'Message customer',
            if (timeLeft.isNotEmpty)
              '$timeLeft ${t?.translate('left') ?? 'left'}',
          ].join(' · ')
        : (t?.translate('view_chat') ?? 'View chat');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isOpen
            ? AppColors.primary.withValues(alpha: 0.07)
            : Theme.of(context).dividerColor.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isOpen
              ? AppColors.primary.withValues(alpha: 0.22)
              : Theme.of(context).dividerColor,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isOpen ? PhosphorIconsRegular.chatCircleDots : Icons.forum_outlined,
            color: isOpen ? AppColors.primary : const Color(0xFF64748B),
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isOpen
                  ? (t?.translate('post_order_chat_help') ??
                        'Order support is still available')
                  : (t?.translate('chat_read_only') ??
                        'This conversation is now read-only'),
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFFCBD5E1)
                    : const Color(0xFF475569),
              ),
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: _openCustomerChat,
            style: OutlinedButton.styleFrom(
              foregroundColor: isOpen
                  ? AppColors.primary
                  : const Color(0xFF64748B),
              side: BorderSide(
                color: isOpen
                    ? AppColors.primary.withValues(alpha: 0.55)
                    : const Color(0xFFCBD5E1),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
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
                        child:
                            _currentOrder.customerAvatar != null &&
                                _currentOrder.customerAvatar!.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: _currentOrder.customerAvatar!,
                                fit: BoxFit.contain,
                                placeholder: (context, url) =>
                                    const CustomLoadingIndicator(size: 32),
                                errorWidget: (context, url, error) =>
                                    const Icon(
                                      Icons.error,
                                      color: Colors.white,
                                    ),
                              )
                            : const Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 64,
                              ),
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
              image:
                  _currentOrder.customerAvatar != null &&
                      _currentOrder.customerAvatar!.isNotEmpty
                  ? DecorationImage(
                      image: CachedNetworkImageProvider(_currentOrder.customerAvatar!),
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
              if (_currentOrder.customerPhone.isNotEmpty && _currentOrder.customerPhone != '-')
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    _currentOrder.customerPhone,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ),
              if (_currentOrder.queueNo > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    'Queue No: #${_currentOrder.queueNo}',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.onSurfaceVariant,
                    ),
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
    final customerId = _currentOrder.customerId;
    final customerName = _currentOrder.customerName;

    if (customerId == null || customerId <= 0) {
      // Fallback to regular phone call if customer ID is unavailable
      final raw = _currentOrder.customerPhone.trim();
      final phone = raw.replaceAll(RegExp(r'[^\d+]'), '');
      if (phone.isEmpty) {
        AppDialog.showToast(context, 'No contact information available', isError: true);
        return;
      }
      final uri = Uri(scheme: 'tel', path: phone);
      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {
        if (mounted) AppDialog.showToast(context, 'Could not open dialer', isError: true);
      }
      return;
    }

    // Use in-app VoIP call
    final session = ShopCallSession();
    if (session.state.value != ShopCallState.idle) {
      AppDialog.showToast(context, 'You are already on a call', isError: true);
      return;
    }

    final orderId = int.tryParse(_currentOrder.id) ?? 0;
    final started = await session.initiateCallToUser(
      userId: customerId,
      customerName: customerName,
      customerImageUrl: _currentOrder.customerAvatar,
      orderId: orderId > 0 ? orderId : null,
    );

    if (!started) {
      if (mounted) AppDialog.showToast(context, 'Could not start the call', isError: true);
      return;
    }

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OutgoingCallScreen(
            customerName: customerName,
            customerImageUrl: _currentOrder.customerAvatar,
          ),
        ),
      );
    }
  }

  Future<void> _callRider(String? phone) async {
    final raw = phone?.trim();
    if (raw == null || raw.isEmpty || raw == '-') {
      AppDialog.showToast(context, 'No rider phone number available', isError: true);
      return;
    }
    final cleanPhone = raw.replaceAll(RegExp(r'[^\d+]'), '');
    if (cleanPhone.isEmpty) {
      AppDialog.showToast(context, 'Invalid rider phone number', isError: true);
      return;
    }
    final uri = Uri(scheme: 'tel', path: cleanPhone);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (mounted) AppDialog.showToast(context, 'Could not open phone dialer', isError: true);
    }
  }

  Future<void> _reDispatchLalamove() async {
    final t = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(PhosphorIconsFill.arrowsClockwise, color: Color(0xFFFF6A00), size: 24),
            const SizedBox(width: 8),
            Text(t?.translate('redispatch_rider') ?? 'Re-Dispatch Rider', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'Do you want to request a new Lalamove rider for this order? '
          'The previous rider request will be replaced.',
          style: TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(t?.translate('cancel') ?? 'Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6A00),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(t?.translate('redispatch_rider') ?? 'Re-Dispatch'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isDispatchingLalamove = true);
    try {
      final res = await OrderService().dispatchWithProvider(
        _currentOrder.id.toString(),
        provider: 'LALAMOVE',
      );
      if (res['success'] == true) {
        final rawUrl = res['trackingUrl'] ?? (res['data'] is Map ? res['data']['trackingUrl'] : null);
        final urlStr = rawUrl?.toString();
        if (urlStr != null && urlStr.isNotEmpty) {
          _deliveryTrackingUrlController.text = urlStr;
        }
        if (mounted) {
          AppDialog.showToast(
            context,
            'New Lalamove rider requested! Live tracking updated.',
            isError: false,
          );
        }
        await _fetchOrderDetails();
        if (mounted) {
          _openTrackingUrl(_currentOrder.trackingUrl ?? urlStr);
        }
      } else {
        if (mounted) {
          final errorMsg = res['message']?.toString() ?? 'Failed to re-dispatch Lalamove.';
          AppDialog.showToast(context, errorMsg, isError: true);
        }
      }
    } catch (e) {
      if (mounted) AppDialog.showToast(context, 'Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isDispatchingLalamove = false);
    }
  }

  Future<void> _switchToShopDriver() async {
    final t = AppLocalizations.of(context);
    final riders = _availableDrivers;
    if (riders.isEmpty) {
      AppDialog.showToast(context, 'No internal shop drivers available.', isError: true);
      return;
    }

    int? selectedId = _selectedDriverId ?? riders.first.id;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(t?.translate('switch_to_shop_driver') ?? 'Switch to Shop Driver', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Select an in-house delivery driver to take over this order:', style: TextStyle(fontSize: 13)),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                value: selectedId,
                items: riders.map((r) => DropdownMenuItem(
                  value: r.id,
                  child: Text('${r.name} (${r.phone ?? r.vehicleNo ?? "Active"})'),
                )).toList(),
                onChanged: (val) => setDialogState(() => selectedId = val),
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(t?.translate('cancel') ?? 'Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Assign & Dispatch'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || selectedId == null || !mounted) return;

    setState(() => _isUpdating = true);
    try {
      final res = await OrderService().dispatchWithProvider(
        _currentOrder.id.toString(),
        provider: 'OWN_FLEET',
        driverId: selectedId,
      );
      if (res['success'] == true) {
        if (mounted) {
          AppDialog.showToast(context, 'Switched to shop driver successfully!', isError: false);
        }
        await _fetchOrderDetails();
      } else {
        if (mounted) {
          final errorMsg = res['message']?.toString() ?? 'Failed to assign shop driver.';
          AppDialog.showToast(context, errorMsg, isError: true);
        }
      }
    } catch (e) {
      if (mounted) AppDialog.showToast(context, 'Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  Future<void> _handleAcceptVerifiedOrder() async {
    int selectedMinutes = 20;
    final confirmed = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(PhosphorIconsFill.checkCircle, color: Color(0xFF10B981), size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Payment Verified ✓ (Auto-Paid)',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF10B981),
                          ),
                        ),
                        Text(
                          'Accept Order & Set Kitchen Time',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'How many minutes does your kitchen need to prepare this order?',
                style: GoogleFonts.poppins(fontSize: 13, color: Theme.of(context).textTheme.bodyMedium?.color),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [5, 10, 15, 20, 30, 45, 60].map((mins) {
                  final isSelected = selectedMinutes == mins;
                  return InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => setSheetState(() => selectedMinutes = mins),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : Theme.of(context).scaffoldBackgroundColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : AppColors.outlineVariant,
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        '$mins mins',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(sheetContext, selectedMinutes),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(PhosphorIconsFill.cookingPot, size: 20),
                  label: Text(
                    'Accept & Start Cooking ($selectedMinutes mins)',
                    style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed == null || !mounted) return;

    await _runOrderAction(
      action: () => OrderService().prepareOrder(
        _currentOrder.id.toString(),
        waitingTimeMinutes: confirmed,
      ),
      errorMessage: 'Failed to accept order. Please try again.',
      onSuccess: () {
        if (!mounted) return;
        AppDialog.showToast(context, 'Order accepted! Cooking started ($confirmed mins).', isError: false);
      },
    );
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
          orderUpdatedAt: _currentOrder.updatedAt,
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
        if (!_isOrderVerifiedFlow) ...[
          FarOrderDeliveryBanner(
            order: _currentOrder,
            shopLatitude: _shopLatitude,
            shopLongitude: _shopLongitude,
          ),
          const SizedBox(height: 8),
        ],
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

    Widget _buildLalamoveDispatchCard() {
    final t = AppLocalizations.of(context);
    final trackingUrl = _currentOrder.trackingUrl;
    final hasLalamoveUrl = trackingUrl != null &&
        (trackingUrl.toLowerCase().contains('lalamove') ||
         trackingUrl.toLowerCase().contains('http'));

    const primaryColor = Color(0xFFFF6A00);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: primaryColor.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  PhosphorIconsFill.moped,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Lalamove Express',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Verified Only ✓',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Dispatch on-demand motorcycle delivery with live GPS tracking.',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.color
                            ?.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (hasLalamoveUrl) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF00B14F).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF00B14F).withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(PhosphorIconsFill.checkCircle, color: Color(0xFF00B14F), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Lalamove rider active & dispatched (See live tracking card above)',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF00B14F),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            SizedBox(
              width: double.infinity,
              height: 48,
              child: PrimaryGradientButton(
                onPressed: _isDispatchingLalamove
                    ? null
                    : () async {
                        setState(() => _isDispatchingLalamove = true);
                        try {
                          final res = await OrderService().dispatchWithProvider(
                            _currentOrder.id.toString(),
                            provider: 'LALAMOVE',
                          );
                          if (res['success'] == true) {
                            final rawUrl = res['trackingUrl'] ?? (res['data'] is Map ? res['data']['trackingUrl'] : null);
                            final urlStr = rawUrl?.toString();
                            if (urlStr != null && urlStr.isNotEmpty) {
                              _deliveryTrackingUrlController.text = urlStr;
                            }
                            if (mounted) {
                              AppDialog.showToast(
                                context,
                                'Lalamove rider requested! Live tracking active.',
                                isError: false,
                              );
                            }
                            await _fetchOrderDetails();
                            if (mounted) {
                              _openTrackingUrl(_currentOrder.trackingUrl ?? urlStr);
                            }
                          } else {
                            if (mounted) {
                              final errorMsg = res['message']?.toString() ?? 'Failed to dispatch Lalamove.';
                              AppDialog.showToast(
                                context,
                                errorMsg,
                                isError: true,
                              );
                            }
                          }
                        } catch (e) {
                          if (mounted) {
                            AppDialog.showToast(
                              context,
                              'Error: $e',
                              isError: true,
                            );
                          }
                        } finally {
                          if (mounted) {
                            setState(() => _isDispatchingLalamove = false);
                          }
                        }
                      },
                borderRadius: 12,
                gradient: AppColors.primaryGradient,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _isDispatchingLalamove
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(PhosphorIconsFill.paperPlaneTilt, size: 18, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      _isDispatchingLalamove
                          ? 'Requesting Lalamove...'
                          : 'Request Lalamove Rider 🛵',
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
        ],
      ),
    );
  }

  Future<void> _openTrackingUrl(String? rawUrl) async {
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LiveDeliveryTrackingScreen(
          order: _currentOrder,
          shopLatitude: _shopLatitude,
          shopLongitude: _shopLongitude,
        ),
      ),
    );
  }

  void _showProofOfDeliveryDialog(String photoUrl) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: InteractiveViewer(
                child: Image.network(
                  photoUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Container(
                    padding: const EdgeInsets.all(32),
                    color: Colors.white,
                    child: const Text('Could not load proof of delivery photo'),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(PhosphorIconsFill.xCircle, color: Colors.white, size: 28),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRiderSection() {
    final t = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final rider = _assignedRider;
    final isLalamove = _currentOrder.trackingUrl != null &&
        (_currentOrder.trackingUrl!.toLowerCase().contains('lalamove') ||
         _currentOrder.trackingUrl!.toLowerCase().contains('http'));

    final name = _currentOrder.riderName?.trim().isNotEmpty == true
        ? _currentOrder.riderName!
        : (isLalamove ? 'Lalamove Rider 🛵' : (rider?.name ?? 'Assigning Rider...'));
    final phone = (_currentOrder.riderPhone?.trim().isNotEmpty == true)
        ? _currentOrder.riderPhone
        : rider?.phone;
    final vehicleNo = (_currentOrder.deliveryCycleNo?.trim().isNotEmpty == true)
        ? _currentOrder.deliveryCycleNo
        : rider?.vehicleNo;
    final trackingUrl = _currentOrder.trackingUrl;
    final hasTrackingUrl = trackingUrl != null && trackingUrl.trim().isNotEmpty;
    final pickupCode = _currentOrder.lastOrderNo ?? '#${_currentOrder.id}';
    final proofPhotoUrl = _currentOrder.proofPhotoUrl;

    const brandOrange = Color(0xFFFF6A00);
    const emeraldGreen = Color(0xFF10B981);

    // Delivery Phase title & color
    String phaseTitle;
    Color phaseColor;
    if (_currentOrder.status == 'DELIVERED') {
      phaseTitle = _safeTranslate('courier_delivered', 'Delivered to Customer ✓');
      phaseColor = emeraldGreen;
    } else if (_currentOrder.status == 'ON_THE_WAY') {
      phaseTitle = _safeTranslate('courier_delivering_to_customer', 'Out for Delivery • En Route to Customer');
      phaseColor = const Color(0xFF2563EB);
    } else {
      phaseTitle = _safeTranslate('courier_matched_heading_to_store', 'Courier Matched • Heading to Store');
      phaseColor = brandOrange;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: (isLalamove ? brandOrange : AppColors.primary).withValues(alpha: 0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (isLalamove ? brandOrange : AppColors.primary).withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header: Live Status Pulse + Partner Pill ─────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: phaseColor.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(19)),
            ),
            child: Row(
              children: [
                // Pulse Dot
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: phaseColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: phaseColor.withValues(alpha: 0.5),
                        blurRadius: 6,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    phaseTitle,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: phaseColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Partner Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isLalamove ? brandOrange : AppColors.primary,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(PhosphorIconsFill.moped, color: Colors.white, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        isLalamove ? 'Lalamove' : 'Shop Rider',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Pickup Code Bar (Standard for Handover Verification) ──
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(PhosphorIconsBold.ticket, size: 16, color: isLalamove ? brandOrange : Theme.of(context).hintColor),
                      const SizedBox(width: 8),
                      Text(
                        'Pickup Code: ',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).hintColor,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          pickupCode,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: pickupCode));
                          AppDialog.showToast(context, 'Pickup code copied');
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            PhosphorIconsRegular.copy,
                            size: 16,
                            color: isLalamove ? brandOrange : AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // ── Professional Courier Profile & Quick Actions ──────
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: (isLalamove ? brandOrange : AppColors.primary).withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Icon(
                            PhosphorIconsFill.moped,
                            color: isLalamove ? brandOrange : AppColors.primary,
                            size: 24,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    name,
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: Theme.of(context).textTheme.bodyLarge?.color,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(PhosphorIconsFill.sealCheck, color: Color(0xFF0284C7), size: 14),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                const Icon(PhosphorIconsFill.star, color: Color(0xFFF59E0B), size: 12),
                                const SizedBox(width: 3),
                                Text(
                                  '4.9',
                                  style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF64748B)),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF0F172A) : Colors.white,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: const Color(0xFFCBD5E1)),
                                  ),
                                  child: Text(
                                    (vehicleNo != null && vehicleNo.trim().isNotEmpty)
                                        ? vehicleNo.trim()
                                        : 'LALAMOVE-TH',
                                    style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.8,
                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (phone != null && phone.trim().isNotEmpty)
                        GestureDetector(
                          onTap: () => _callRider(phone),
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: emeraldGreen.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(PhosphorIconsFill.phoneCall, color: emeraldGreen, size: 18),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // ── Sleek Delivery Route Progress Bar ─────────────────
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(PhosphorIconsFill.storefront, color: Color(0xFF00B14F), size: 16),
                      const SizedBox(width: 8),
                      Text('Store', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF00B14F))),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              height: 3,
                              decoration: BoxDecoration(
                                color: const Color(0xFFCBD5E1),
                                borderRadius: BorderRadius.circular(1.5),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: brandOrange,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(PhosphorIconsFill.moped, color: Colors.white, size: 11),
                                  SizedBox(width: 4),
                                  Text('En Route', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('Customer', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFFEF4444))),
                      const SizedBox(width: 8),
                      const Icon(PhosphorIconsFill.mapPin, color: Color(0xFFEF4444), size: 16),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // ── Single Prominent Action: Open Live GPS Tracking Map ──
                if (hasTrackingUrl) ...[
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton.icon(
                      onPressed: () => _openTrackingUrl(trackingUrl),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F172A),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(PhosphorIconsFill.navigationArrow, color: Color(0xFFFF6A00), size: 18),
                      label: Text(
                        _safeTranslate('track_live_gps', 'Track Courier on Live GPS Map ↗'),
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],

                // ── Proof of Delivery (Doorstep Photo preview) ─────────
                if (proofPhotoUrl != null && proofPhotoUrl.trim().isNotEmpty) ...[
                  const Divider(height: 20),
                  Row(
                    children: [
                      Icon(PhosphorIconsFill.camera, size: 16, color: emeraldGreen),
                      const SizedBox(width: 6),
                      Text(
                        t?.translate('proof_of_delivery') ?? 'Proof of Delivery (Doorstep Photo):',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: emeraldGreen,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => _showProofOfDeliveryDialog(proofPhotoUrl),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        height: 90,
                        width: double.infinity,
                        color: Colors.black12,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Image.network(
                              proofPhotoUrl,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              errorBuilder: (_, __, ___) => const Center(
                                child: Text('Proof of delivery recorded'),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(PhosphorIconsBold.magnifyingGlassPlus, color: Colors.white, size: 12),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Tap to view',
                                    style: GoogleFonts.poppins(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],

                // ── Secondary Management Row (Re-dispatch / Switch Driver) ─
                if (isLalamove && (_currentOrder.status == 'COOKING' || _currentOrder.status == 'ON_THE_WAY')) ...[
                  const Divider(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isDispatchingLalamove ? null : _reDispatchLalamove,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Theme.of(context).hintColor,
                            side: BorderSide(color: Theme.of(context).dividerColor),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                          icon: const Icon(PhosphorIconsFill.arrowsClockwise, size: 14),
                          label: Text(
                            _isDispatchingLalamove
                                ? 'Re-Dispatching...'
                                : (t?.translate('redispatch_rider') ?? 'Re-Dispatch'),
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _switchToShopDriver,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Theme.of(context).hintColor,
                            side: BorderSide(color: Theme.of(context).dividerColor),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                          icon: const Icon(PhosphorIconsFill.moped, size: 14),
                          label: Text(
                            t?.translate('switch_to_shop_driver') ?? 'Shop Driver',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
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
              if (item.menuItemImageUrl != null &&
                  item.menuItemImageUrl!.isNotEmpty) {
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
                                          const Center(
                                            child: CustomLoadingIndicator(
                                              size: 32,
                                            ),
                                          ),
                                      errorWidget: (context, url, error) =>
                                          const Center(
                                            child: Icon(
                                              Icons.error,
                                              color: Colors.grey,
                                            ),
                                          ),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                top: -15,
                                right: -15,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.7),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
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
                if (item.variant != null &&
                    item.variant!.displayName.isNotEmpty)
                  Text(
                    item.variant!.displayName,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: (Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFFCBD5E1)
                          : const Color(0xFF64748B)),
                    ),
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
        if (_currentOrder.isOmisePayment) ...[
          SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _currentOrder.status == 'PAYMENT_SLIP_REQUESTED'
                  ? const Color(0xFFEFF6FF)
                  : const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _currentOrder.status == 'PAYMENT_SLIP_REQUESTED'
                    ? const Color(0xFFBFDBFE)
                    : const Color(0xFFBBF7D0),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _currentOrder.status == 'PAYMENT_SLIP_REQUESTED'
                      ? PhosphorIconsFill.clock
                      : PhosphorIconsFill.sealCheck,
                  color: _currentOrder.status == 'PAYMENT_SLIP_REQUESTED'
                      ? const Color(0xFF2563EB)
                      : const Color(0xFF16A34A),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _currentOrder.status == 'PAYMENT_SLIP_REQUESTED'
                            ? 'Omise Direct Payment (Awaiting Customer)'
                            : 'Omise Direct Payment (Auto-verified ✓)',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: _currentOrder.status == 'PAYMENT_SLIP_REQUESTED'
                              ? const Color(0xFF1E40AF)
                              : const Color(0xFF166534),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _currentOrder.status == 'PAYMENT_SLIP_REQUESTED'
                            ? 'Customer pays via PromptPay QR / TrueMoney. System auto-verifies upon payment.'
                            : 'Paid directly via PromptPay / TrueMoney. No manual slip verification needed.',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: _currentOrder.status == 'PAYMENT_SLIP_REQUESTED'
                              ? const Color(0xFF1D4ED8)
                              : const Color(0xFF15803D),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ] else if (_currentOrder.paymentSlipUrl != null &&
            _currentOrder.paymentSlipUrl!.isNotEmpty) ...[
          SizedBox(height: 16),
          Row(
            children: [
              if (_currentOrder.paymentMethodIconUrl != null &&
                  _currentOrder.paymentMethodIconUrl!.isNotEmpty)
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
        _buildSummaryRow(
          'Food Price',
          _currentOrder.foodPrice.toFormattedPrice(),
        ),
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
                          color:
                              (Theme.of(context).brightness == Brightness.dark
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
        if (_currentOrder.transactionDiscount > 0) ...[
          SizedBox(height: 12),
          _buildSummaryRow(
            AppLocalizations.of(context)?.translate('transaction_discount') ??
                'Transaction Discount',
            '- ${_currentOrder.displayTransactionDiscount.isNotEmpty ? _currentOrder.displayTransactionDiscount : _currentOrder.transactionDiscount.toFormattedPrice()}',
          ),
        ],
        if (!_currentOrder.isPickupFulfillment) ...[
          SizedBox(height: 12),
          Row(
            children: [
              const GradientWidget(
                child: Icon(PhosphorIconsFill.moped, size: 20),
              ),
              SizedBox(width: 8),
              Text(
                (_currentOrder.isFreeDelivery ||
                        _currentOrder.deliveryFee > 0)
                    ? 'Delivery Fee'
                    : 'Est. Amount',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  color: (Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFFCBD5E1)
                      : const Color(0xFF64748B)),
                ),
              ),
              SizedBox(width: 8),
              if (_currentOrder.deliveryType == 'NORMAL' &&
                  ![
                    'ON_THE_WAY',
                    'DELIVERED',
                    'PICKED_UP',
                  ].contains(_currentOrder.status))
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Estimate',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFFEF4444),
                    ),
                  ),
                ),
              if (_currentOrder.deliveryType != 'NORMAL')
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
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
        ],
        SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                (_currentOrder.deliveryType == 'NORMAL' &&
                        ![
                          'ON_THE_WAY',
                          'DELIVERED',
                          'PICKED_UP',
                        ].contains(_currentOrder.status))
                    ? 'Est Total'
                    : 'Total',
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
                  (_currentOrder.deliveryType == 'NORMAL' &&
                          [
                            'ON_THE_WAY',
                            'DELIVERED',
                            'PICKED_UP',
                          ].contains(_currentOrder.status))
                      ? (_currentOrder.checkoutTotal +
                                _currentOrder.deliveryFee)
                            .toFormattedPrice()
                      : _currentOrder.displayTotalAmount.isNotEmpty
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
          if (!mounted) return;
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

  String _safeTranslate(String key, String fallback) {
    final t = AppLocalizations.of(context);
    final val = t?.translate(key);
    if (val != null && val.isNotEmpty && val != key) {
      return val;
    }
    final lang = LocalizationService.instance.localeNotifier.value.languageCode;
    if (lang == 'my') {
      switch (key) {
        case 'track_live_delivery':
          return 'ပို့ဆောင်မှု တိုက်ရိုက်ကြည့်ရှုမည်';
        case 'courier_delivering_auto_completes':
          return 'Rider ပို့ဆောင်နေပါသည် (အလိုအလျောက် ပြီးဆုံးပါမည်)';
        case 'order_successfully_delivered':
          return 'အော်ဒါ အောင်မြင်စွာ ပို့ဆောင်ပြီးပါပြီ';
        case 'ready_and_find_rider':
          return 'အဆင်သင့်ဖြစ်ပြီ Rider ရှာမည်';
        case 'request_rider':
          return 'Rider ခေါ်မည်';
        case 'accept_order':
          return 'အော်ဒါလက်ခံမည်';
        case 'accept_and_start_cooking':
          return 'အော်ဒါလက်ခံပြီး ချက်ပြုတ်မည်';
        case 'accept_order_to_cook':
          return 'ချက်ပြုတ်ရန် အော်ဒါလက်ခံမည်';
        case 'items_subtotal':
          return 'အစားအသောက် စုစုပေါင်း';
        case 'delivery_fee':
          return 'ပို့ဆောင်ခ';
        case 'coupon_discount':
          return 'ကူပွန် လျှော့စျေး';
        case 'transaction_discount':
          return 'အထူး လျှော့စျေး';
        case 'order_total':
          return 'စုစုပေါင်းငွေ';
        case 'track_live_gps':
          return 'တိုက်ရိုက် GPS မြေပုံပေါ်တွင် ခြေရာခံမည်';
        case 'courier_delivering_to_customer':
          return 'ပို့ဆောင်နေဆဲ • ဝယ်ယူသူထံ သွားနေပါသည်';
        case 'courier_matched_heading_to_store':
          return 'ပို့ဆောင်သူ လက်ခံရရှိပြီ • ဆိုင်သို့ လာနေပါသည်';
        case 'courier_delivered':
          return 'ဝယ်ယူသူထံ အောင်မြင်စွာ ပို့ဆောင်ပြီးပါပြီ ✓';
      }
    } else if (lang == 'th') {
      switch (key) {
        case 'track_live_delivery':
          return 'ติดตามการจัดส่งแบบสด';
        case 'courier_delivering_auto_completes':
          return 'ไรเดอร์กำลังจัดส่งถึงลูกค้า (เสร็จสิ้นอัตโนมัติ)';
        case 'order_successfully_delivered':
          return 'จัดส่งออเดอร์เรียบร้อยแล้ว';
        case 'ready_and_find_rider':
          return 'พร้อมแล้วและค้นหาไรเดอร์';
        case 'request_rider':
          return 'เรียกรถส่ง';
        case 'accept_order':
          return 'ยอมรับออเดอร์';
        case 'accept_and_start_cooking':
          return 'รับออเดอร์และเริ่มทำอาหาร';
        case 'accept_order_to_cook':
          return 'รับออเดอร์เพื่อเริ่มทำอาหาร';
        case 'items_subtotal':
          return 'ยอดรวมค่าอาหาร';
        case 'delivery_fee':
          return 'ค่าจัดส่ง';
        case 'coupon_discount':
          return 'ส่วนลดคูปอง';
        case 'transaction_discount':
          return 'ส่วนลดพิเศษ';
        case 'order_total':
          return 'ยอดรวมทั้งสิ้น';
        case 'track_live_gps':
          return 'ติดตามคนขับบนแผนที่สด (GPS)';
        case 'courier_delivering_to_customer':
          return 'กำลังจัดส่ง • กำลังเดินทางไปส่งลูกค้า';
        case 'courier_matched_heading_to_store':
          return 'คนขับรับงานแล้ว • กำลังเดินทางมาที่ร้าน';
        case 'courier_delivered':
          return 'จัดส่งถึงลูกค้าเรียบร้อยแล้ว ✓';
      }
    }
    return fallback;
  }

  Widget _buildBottomActionButtons() {
    final t = AppLocalizations.of(context);
    String mainButtonText = 'Accept order';
    bool isCancelable = false;
    VoidCallback? onPressed;

    switch (_currentOrder.status) {
      case 'PENDING':
        final isVerified = _isOrderVerifiedFlow;
        mainButtonText = _safeTranslate('accept_order', 'Accept Order');
        onPressed = (_isUpdating || (!isVerified && !_isFormValid))
            ? null
            : _handleShowPreparationTimeAndConfirm;
        break;
      case 'AWAITING_APPROVAL':
        mainButtonText = 'Confirm Payment';
        onPressed = _isUpdating ? null : _handleVerifyPayment;
        break;
      case 'PAYMENT_VERIFIED':
        mainButtonText = (_isShopVerified || _currentOrder.isVerified)
            ? _safeTranslate('accept_and_start_cooking', 'Accept & Start Cooking')
            : _safeTranslate('accept_order_to_cook', 'Accept order to cook');
        onPressed = _isUpdating ? null : _handlePrepareOrder;
        break;
      case 'PAYMENT_SLIP_REQUESTED':
        mainButtonText = _currentOrder.isOmisePayment
            ? 'Awaiting Direct Payment'
            : 'Waiting for payment';
        onPressed = null;
        break;
      case 'COOKING':
        if (_currentOrder.isPickupFulfillment) {
          mainButtonText = 'Mark Ready for Pickup';
          onPressed = _isUpdating ? null : _handleMarkReadyForPickup;
        } else if (_isOrderVerifiedFlow || _currentOrder.isLalamoveDelivery) {
          mainButtonText = _safeTranslate('ready_and_find_rider', 'Ready & Find Rider');
          onPressed = (_isUpdating || _isDispatchingLalamove)
              ? null
              : _handleReadyAndFindRider;
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
        if (_currentOrder.isPickupFulfillment) {
          mainButtonText = 'Verify Pickup';
          onPressed = _isUpdating ? null : _openPickupCompleteScreen;
        } else if (_isOrderVerifiedFlow || _currentOrder.isLalamoveDelivery) {
          final hasTracking = _currentOrder.trackingUrl != null &&
              _currentOrder.trackingUrl!.trim().isNotEmpty;
          mainButtonText = hasTracking
              ? _safeTranslate('track_live_delivery', 'Track Live Delivery 📍')
              : _safeTranslate('request_rider', 'Request Rider');
          onPressed = (_isUpdating || _isDispatchingLalamove)
              ? null
              : (hasTracking
                  ? () => _openTrackingUrl(_currentOrder.trackingUrl)
                  : _dispatchLalamove);
        } else {
          mainButtonText = 'Picked Up by Rider';
          onPressed = (_isUpdating ||
                  (_selectedDriverId == null &&
                      _deliveryTrackingUrlController.text.trim().isEmpty))
              ? null
              : _handleDispatchOrder;
        }
        break;
      case 'ON_THE_WAY':
        if (_isOrderVerifiedFlow || _currentOrder.isLalamoveDelivery) {
          return _buildLalamoveInTransitBottomBar();
        }
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
              if (_currentOrder.status == 'AWAITING_APPROVAL' &&
                  !_currentOrder.isOmisePayment) ...[
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

  Widget _buildLalamoveInTransitBottomBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
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
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(PhosphorIconsFill.moped, size: 16, color: Color(0xFFFF6A00)),
              const SizedBox(width: 6),
              Text(
                _safeTranslate(
                  'courier_delivering_auto_completes',
                  'Courier is delivering to customer (Auto-completes)',
                ),
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: PrimaryGradientButton(
              onPressed: () => _openTrackingUrl(_currentOrder.trackingUrl),
              borderRadius: 14,
              gradient: const LinearGradient(
                colors: [Color(0xFFFF6A00), Color(0xFFFF8A00)],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(PhosphorIconsFill.navigationArrow, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    _safeTranslate('track_live_delivery', 'Track Live Delivery'),
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
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
          const Icon(Icons.check_circle_rounded, color: Colors.white, size: 22),
          const SizedBox(width: 10),
          Text(
            _safeTranslate(
              'order_successfully_delivered',
              'Order successfully delivered',
            ),
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

    Widget _buildVerifiedOrderConfirmationCard() {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    const primaryOrange = Color(0xFFFF6A00);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Verified Flow Banner ──────────────────────────────────
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: primaryOrange.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: primaryOrange.withValues(alpha: 0.35),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: primaryOrange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      PhosphorIconsFill.moped,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                t?.translate('lalamove_express_delivery') ?? 'Lalamove Express Delivery',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: theme.textTheme.bodyLarge?.color,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(PhosphorIconsFill.checkCircle, color: Color(0xFF10B981), size: 11),
                                  const SizedBox(width: 3),
                                  Text(
                                    t?.translate('verified_order_flow') ?? 'Verified',
                                    style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF10B981),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'On-demand rider dispatch • Omise Direct Payment',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Divider(color: theme.dividerColor.withValues(alpha: 0.5)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    t?.translate('automated_delivery_fee') ?? 'Automated Delivery Fee',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: theme.textTheme.bodyMedium?.color,
                    ),
                  ),
                  if (_currentOrder.isFreeDelivery)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'FREE (Promo)',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF10B981),
                        ),
                      ),
                    )
                  else
                    Text(
                      _currentOrder.deliveryFee > 0
                          ? '฿${_currentOrder.deliveryFee.toStringAsFixed(0)}'
                          : 'Auto-Quoted (Lalamove)',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: primaryOrange,
                      ),
                    ),
                ],
              ),
              if (_currentOrder.customerAddress != null && _currentOrder.customerAddress!.trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(PhosphorIconsRegular.mapPin, size: 14, color: theme.hintColor),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _currentOrder.customerAddress!,
                        style: GoogleFonts.poppins(fontSize: 12, color: theme.hintColor),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),

        // ── Kitchen Prep Time (Quick 1-Tap Chips) ───────────────────
        Text(
          t?.translate('kitchen_prep_time') ?? 'Kitchen Preparation Time',
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          t?.translate('kitchen_prep_time_desc') ??
              'Select estimated minutes needed to prepare this food before rider arrival:',
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [5, 10, 15, 20, 30, 45, 60].map((mins) {
            final currentVal = int.tryParse(_waitingTimeMinutesController.text) ?? 20;
            final isSelected = currentVal == mins;
            return InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                setState(() {
                  _waitingTimeMinutesController.text = mins.toString();
                  _validateFormState();
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  gradient: isSelected ? AppColors.primaryGradient : null,
                  color: isSelected
                      ? null
                      : (isDark ? theme.cardColor : const Color(0xFFF1F5F9)),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? Colors.transparent : theme.dividerColor,
                    width: 1.2,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  '$mins mins',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    color: isSelected
                        ? Colors.white
                        : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569)),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),

        // ── Read-Only Live Order Total Summary ───────────────────────
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: theme.dividerColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    t?.translate('items_subtotal') ?? 'Items Subtotal',
                    style: GoogleFonts.poppins(fontSize: 13, color: theme.textTheme.bodyMedium?.color),
                  ),
                  Text(
                    '฿${_currentOrder.foodPrice.toStringAsFixed(2)}',
                    style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    t?.translate('delivery_fee') ?? 'Delivery Fee (Lalamove)',
                    style: GoogleFonts.poppins(fontSize: 13, color: theme.textTheme.bodyMedium?.color),
                  ),
                  Text(
                    _currentOrder.isFreeDelivery
                        ? 'FREE'
                        : '฿${_currentOrder.deliveryFee.toStringAsFixed(2)}',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _currentOrder.isFreeDelivery ? const Color(0xFF10B981) : null,
                    ),
                  ),
                ],
              ),
              if (_currentOrder.taxEnable && _currentOrder.resolvedTaxAmount > 0) ...[
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Tax / VAT',
                      style: GoogleFonts.poppins(fontSize: 13, color: theme.textTheme.bodyMedium?.color),
                    ),
                    Text(
                      '฿${_currentOrder.resolvedTaxAmount.toStringAsFixed(2)}',
                      style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
              if (_currentOrder.discountAmount > 0) ...[
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Coupon Discount',
                      style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF10B981)),
                    ),
                    Text(
                      '-฿${_currentOrder.discountAmount.toStringAsFixed(2)}',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 10),
              Divider(color: theme.dividerColor),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    t?.translate('order_total') ?? 'Order Total',
                    style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '฿${_currentOrder.totalAmount.toStringAsFixed(2)}',
                    style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(PhosphorIconsFill.shieldCheck, color: Color(0xFF10B981), size: 14),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Digital checkout amount locked. Direct payment via Omise PromptPay / TrueMoney.',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: const Color(0xFF10B981),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
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
                SizedBox(height: 12),
                _buildTransactionDiscountField(),
                SizedBox(height: 12),
                _buildLiveOrderTotalSummary(),
              ] else if (_isOrderVerifiedFlow) ...[
                _buildVerifiedOrderConfirmationCard(),
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
                    _currentOrder.isDeliveryFulfillment &&
                    !_isOrderVerifiedFlow) ||
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
                _currentOrder.isDeliveryFulfillment &&
                !_isOrderVerifiedFlow) ...[
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
                    child: _buildDeliveryFeeInputField(
                      label: 'Estimated Delivery Fee',
                      description:
                          'Enter the estimated delivery fee for this order.',
                      required: false,
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
              SizedBox(height: 12),
              _buildTransactionDiscountField(),
              SizedBox(height: 12),
              _buildLiveOrderTotalSummary(),

              // ── Fast Delivery (PENDING): fee + waiting only ─────────────
            ] else if (_deliveryOption == 'PREPAID' &&
                _currentOrder.status == 'PENDING' &&
                _currentOrder.isDeliveryFulfillment &&
                !_isOrderVerifiedFlow) ...[
              Row(
                children: [
                  Expanded(
                    child: _buildDeliveryFeeInputField(
                      label: 'Delivery Fee',
                      description: 'Enter the delivery fee for this order.',
                      required: true,
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
              SizedBox(height: 12),
              _buildTransactionDiscountField(),
              SizedBox(height: 12),
              _buildLiveOrderTotalSummary(),

              // ── COOKING / dispatch (single driver selection point) ─────
            ] else if (_currentOrder.status == 'COOKING' &&
                _currentOrder.isDeliveryFulfillment) ...[
              if (_currentOrder.deliveryType == 'NORMAL') ...[
                _buildDeliveryFeeInputField(
                  label: 'Real Delivery Fee',
                  description:
                      'Enter the final real delivery fee for this flexible delivery.',
                  required: true,
                ),
                SizedBox(height: 12),
              ],
              if (_isShopVerified || _currentOrder.isVerified) ...[
                _buildLalamoveDispatchCard(),
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

  Widget _buildTransactionDiscountField() {
    final t = AppLocalizations.of(context);
    return _buildInputField(
      '${t?.translate('transaction_discount') ?? 'Transaction Discount'} (optional)',
      _transactionDiscountController,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        ThousandsSeparatorInputFormatter(),
      ],
      validator: (value) {
        if (value == null || value.trim().isEmpty) return null;
        final parsed = double.tryParse(value.replaceAll(',', ''));
        if (parsed == null) return 'Invalid number';
        if (parsed > _payableBeforeTransactionDiscount()) {
          return t?.translate('transaction_discount_exceeds') ??
              'Cannot exceed the payable order total';
        }
        return null;
      },
      description:
          t?.translate('transaction_discount_desc') ??
          'Optional amount to take off this order total. Leave blank if none.',
      placeholder: 'e.g. 20',
      suffixText: 'THB',
    );
  }

  Widget _buildDeliveryFeeInputField({
    required String label,
    required String description,
    required bool required,
  }) {
    if (_isFreeDeliveryLocked) {
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
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).disabledColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Text(
              'FREE',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF10B981),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _freeDeliveryExplanation(),
            style: GoogleFonts.poppins(
              fontSize: 12,
              height: 1.4,
              color: (Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF94A3B8)
                  : const Color(0xFF64748B)),
            ),
          ),
        ],
      );
    }

    return _buildInputField(
      label,
      _deliveryFeeController,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        ThousandsSeparatorInputFormatter(),
      ],
      validator: (value) {
        if (value == null || value.isEmpty) {
          return required ? 'Required' : null;
        }
        final numValue = value.replaceAll(',', '');
        if (double.tryParse(numValue) == null) {
          return 'Invalid number';
        }
        return null;
      },
      description: description,
      placeholder: 'e.g. 50',
      showDeliveryApps: true,
      suffixText: 'THB',
    );
  }

  Widget _buildLiveOrderTotalSummary() {
    final itemPrice = _currentOrder.foodPrice;
    final tax = _currentOrder.taxEnable ? _currentOrder.resolvedTaxAmount : 0.0;
    final coupon = _currentOrder.discountAmount;
    final isPickup = _currentOrder.isPickupFulfillment;
    final isFlexible = _deliveryOption == 'NORMAL';
    final free = _isFreeDeliveryLocked;
    final fee = isPickup || isFlexible || free
        ? 0.0
        : (double.tryParse(
                _deliveryFeeController.text.replaceAll(',', '')) ??
            0);
    final txn = _parsedTransactionDiscount();
    final payableBefore = _payableBeforeTransactionDiscount();
    final total = ((payableBefore - txn) * 100).round() / 100;
    final dark = Theme.of(context).brightness == Brightness.dark;

    Widget row(String label, String value, {bool emphasize = false}) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: dark
                      ? const Color(0xFFCBD5E1)
                      : const Color(0xFF64748B),
                ),
              ),
            ),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: emphasize ? 15 : 13,
                fontWeight: emphasize ? FontWeight.w700 : FontWeight.w500,
                color: emphasize
                    ? AppColors.primary
                    : (dark ? Colors.white : const Color(0xFF1E293B)),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order total preview',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: dark ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 10),
          row('Items', itemPrice.toFormattedPrice()),
          if (tax > 0) row('Tax', tax.toFormattedPrice()),
          row(
            isFlexible ? 'Delivery (billed later)' : 'Delivery',
            free
                ? 'FREE'
                : (isFlexible
                    ? '—'
                    : fee.toFormattedPrice()),
          ),
          if (coupon > 0) row('Coupon', '- ${coupon.toFormattedPrice()}'),
          if (txn > 0)
            row('Transaction discount', '- ${txn.toFormattedPrice()}'),
          const Divider(height: 16),
          row('New total', total.toFormattedPrice(), emphasize: true),
          if (isFlexible && !free)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Estimated delivery fee is not included in this total for flexible delivery.',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  height: 1.35,
                  color: dark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF64748B),
                ),
              ),
            ),
        ],
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
                if (_currentOrder.paymentMethodIconUrl != null &&
                    _currentOrder.paymentMethodIconUrl!.isNotEmpty)
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
                (_currentOrder.deliveryType == 'NORMAL' &&
                        ![
                          'ON_THE_WAY',
                          'DELIVERED',
                          'PICKED_UP',
                        ].contains(_currentOrder.status))
                    ? 'Est Total'
                    : 'Total',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: (Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFFCBD5E1)
                      : const Color(0xFF64748B)),
                ),
              ),
            ),
            Text(
              (_currentOrder.deliveryType == 'NORMAL' &&
                      [
                        'ON_THE_WAY',
                        'DELIVERED',
                        'PICKED_UP',
                      ].contains(_currentOrder.status))
                  ? (_currentOrder.checkoutTotal + _currentOrder.deliveryFee)
                        .toFormattedPrice()
                  : _currentOrder.displayTotalAmount,
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
  // ─────────────────────────────────────────────────────────────
  //  LEGACY VIEW (PRESERVED 100% FOR UNVERIFIED / MANUAL SHOPS)
  // ─────────────────────────────────────────────────────────────
  Widget _buildLegacyOrderView() {
    return Column(
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
                                  if (ChatWindow.isCompletedStatus(
                                    _currentOrder.status,
                                  )) ...[
                                    SizedBox(height: 12),
                                    _buildCompletedOrderChatAction(),
                                  ],
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
                                if (_currentOrder.status == 'ON_THE_WAY' &&
                                      !_isOrderVerifiedFlow &&
                                      !_currentOrder.isLalamoveDelivery) ...[
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

                                      // Calculate delivery fee box (delivery only; hidden for pickup / DELIVERED / CANCELLED)
                                      if (!_currentOrder.isPickupFulfillment &&
                                          _currentOrder.status != 'CANCELED' &&
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
                );
  }

  // ─────────────────────────────────────────────────────────────
  //  CLEAN, FOOD-FIRST ORDER DETAIL VIEW FOR VERIFIED SHOPS
  // ─────────────────────────────────────────────────────────────
  Widget _buildVerifiedShopCleanOrderView() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Sleek Order Header (Order ID, Status Badge & Attached 5-Stage Stepper)
                _buildVerifiedOrderHeaderCard(),
                if (_isCustomerLocationInvalid) ...[
                  _buildInvalidLocationWarningBanner(),
                ],
                _buildSectionDivider(),

                // 2. HERO: ORDER ITEMS (Focus #1 for the kitchen/cook!)
                _buildVerifiedOrderItemsSection(),
                _buildSectionDivider(),

                // 3. Customer instructions / Kitchen notes (if any)
                if (_currentOrder.deliveryAddress?.note != null &&
                    _currentOrder.deliveryAddress!.note!.trim().isNotEmpty) ...[
                  _buildCustomerNoteCard(),
                  _buildSectionDivider(),
                ],

                // 4. Kitchen Prep & Delivery Action Card (shown when COOKING or beyond)
                if (_currentOrder.status.toUpperCase() != 'PENDING') ...[
                  _buildVerifiedFulfillmentCard(),
                  _buildSectionDivider(),
                ],

                // 5. Payment & Order Breakdown
                _buildVerifiedPaymentSummaryCard(),
                _buildSectionDivider(),

                // 6. Customer & Destination Info
                _buildVerifiedCustomerAndDeliveryCard(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
        _buildBottomActionButtons(),
      ],
    );
  }

  Widget _buildSectionDivider() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 8,
      width: double.infinity,
      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
    );
  }

  String _cleanOrderNo(String raw) {
    if (raw.startsWith('ORD-')) {
      final parts = raw.split('-');
      return parts.isNotEmpty ? parts.last : raw;
    }
    return raw;
  }

  Future<void> _handleReadyAndFindRider() async {
    if (_isCustomerLocationInvalid) {
      _showInvalidLocationDialog();
      return;
    }

    setState(() {
      _isDispatchingLalamove = true;
      _isUpdating = true;
    });

    try {
      // 1. Auto state change to ready
      await OrderService().markReadyForPickup(
        _currentOrder.id.toString(),
      );

      // 2. Request Lalamove rider
      final res = await OrderService().dispatchWithProvider(
        _currentOrder.id.toString(),
        provider: 'LALAMOVE',
      );

      String? trackingUrl;
      if (res['success'] == true) {
        final rawUrl = res['trackingUrl'] ??
            (res['data'] is Map ? res['data']['trackingUrl'] : null);
        final urlStr = rawUrl?.toString();
        if (urlStr != null && urlStr.isNotEmpty) {
          _deliveryTrackingUrlController.text = urlStr;
          trackingUrl = urlStr;
        }
        if (mounted) {
          AppDialog.showToast(
            context,
            'Order ready! Finding nearby Lalamove rider...',
            isError: false,
          );
        }
      } else {
        if (mounted) {
          final errorMsg =
              res['message']?.toString() ?? 'Order marked ready, but rider request failed.';
          AppDialog.showToast(context, errorMsg, isError: true);
        }
      }

      // 3. Refresh order details
      await _fetchOrderDetails();

      // 4. Directly navigate to map screen
      if (mounted) {
        _openTrackingUrl(_currentOrder.trackingUrl ?? trackingUrl);
      }
    } catch (e) {
      if (mounted) {
        AppDialog.showToast(context, 'Error: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDispatchingLalamove = false;
          _isUpdating = false;
        });
      }
    }
  }

  Future<void> _handleMarkFoodReadyForPickup() async {
    await _runOrderAction(
      action: () => OrderService().markReadyForPickup(
        _currentOrder.id.toString(),
      ),
      errorMessage: 'Failed to mark order ready for pickup.',
      onSuccess: () {
        if (!mounted) return;
        AppDialog.showToast(
          context,
          'Food is packed & ready for courier pickup 📦',
          isError: false,
        );
      },
    );
  }

  Widget _buildVerifiedOrderHeaderCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = Theme.of(context).cardColor;

    String statusLabel = 'New Order';
    Color statusColor = const Color(0xFFFF6A00);
    switch (_currentOrder.status) {
      case 'PENDING':
        statusLabel = 'New Order';
        statusColor = const Color(0xFFFF6A00);
        break;
      case 'PAYMENT_PENDING':
      case 'PAYMENT_SLIP_REQUESTED':
        statusLabel = 'Awaiting Payment';
        statusColor = const Color(0xFFF59E0B);
        break;
      case 'PAYMENT_VERIFIED':
        statusLabel = 'Ready to Cook';
        statusColor = const Color(0xFF10B981);
        break;
      case 'COOKING':
        statusLabel = 'Preparing Food';
        statusColor = const Color(0xFFFF6A00);
        break;
      case 'READY_FOR_PICKUP':
        statusLabel = 'Ready for Pickup';
        statusColor = const Color(0xFF10B981);
        break;
      case 'ON_THE_WAY':
        statusLabel = 'Out for Delivery';
        statusColor = const Color(0xFFED3973);
        break;
      case 'DELIVERED':
        statusLabel = 'Delivered ✓';
        statusColor = const Color(0xFF10B981);
        break;
      case 'CANCELED':
        statusLabel = 'Cancelled';
        statusColor = const Color(0xFFEF4444);
        break;
    }

    return Container(
      width: double.infinity,
      color: cardBg,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Customer Avatar & Name (Left) and Status Badge (Right)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                child: GestureDetector(
                  onTap: _showCustomerInfoBottomSheet,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          CircleAvatar(
                            radius: 15,
                            backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                            backgroundImage: (_currentOrder.customerAvatar != null &&
                                    _currentOrder.customerAvatar!.isNotEmpty)
                                ? CachedNetworkImageProvider(_currentOrder.customerAvatar!)
                                : null,
                            child: (_currentOrder.customerAvatar == null ||
                                    _currentOrder.customerAvatar!.isEmpty)
                                ? Text(
                                    _currentOrder.customerName.isNotEmpty
                                        ? _currentOrder.customerName[0].toUpperCase()
                                        : 'C',
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                    ),
                                  )
                                : null,
                          ),
                          if (_chatUnreadCount > 0)
                            Positioned(
                              right: -2,
                              top: -2,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFEF4444),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          _currentOrder.customerName.isNotEmpty
                              ? _currentOrder.customerName
                              : 'Customer',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : const Color(0xFF1E293B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      statusLabel,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 5-Stage Stepper: unverified shop progress bar style with live animation!
          StatusProgressIndicator(
            key: ValueKey('${_currentOrder.status}_verified_stepper'),
            status: _currentOrder.status,
            isVerifiedDelivery: true,
          ),
        ],
      ),
    );
  }

  Widget _buildInvalidLocationWarningBanner() {
    return Container(
      width: double.infinity,
      color: const Color(0xFFFEF2F2),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          const Icon(PhosphorIconsFill.warningCircle, color: Color(0xFFEF4444), size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Invalid Customer Delivery GPS Pin',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF991B1B),
                  ),
                ),
                Text(
                  'Map pin is missing. Cancel order to prevent food loss or deliver with shop rider.',
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    color: const Color(0xFFB91C1C),
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: _handleCancelOrder,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerifiedOrderItemsSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = Theme.of(context).cardColor;
    final dividerColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9);

    return Container(
      width: double.infinity,
      color: cardBg,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title + Revise items button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(PhosphorIconsFill.forkKnife, size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Order Items (${_currentOrder.items.length})',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
              if (_currentOrder.status == 'PENDING' || _currentOrder.status == 'AWAITING_APPROVAL')
                TextButton.icon(
                  onPressed: _showReviseItemsSheet,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  icon: const GradientWidget(
                    child: Icon(PhosphorIconsRegular.warning, size: 15),
                  ),
                  label: GradientText(
                    'Revise items',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Item Rows List (No outer boxes, no borders, clean attached rows separated by hairlines)
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _currentOrder.items.length,
            separatorBuilder: (_, __) => Divider(
              height: 20,
              thickness: 1,
              color: dividerColor,
            ),
            itemBuilder: (_, index) => _buildVerifiedOrderItemCard(_currentOrder.items[index]),
          ),
        ],
      ),
    );
  }

  Widget _buildVerifiedOrderItemCard(OrderItemModel item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // PROMINENT QUANTITY BADGE
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${item.quantity}x',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Item Image (tap to view)
          GestureDetector(
            onTap: () {
              if (item.menuItemImageUrl != null && item.menuItemImageUrl!.isNotEmpty) {
                _showItemImageDialog(item.menuItemImageUrl!);
              }
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: (item.menuItemImageUrl != null && item.menuItemImageUrl!.isNotEmpty)
                  ? CachedNetworkImage(
                      imageUrl: item.menuItemImageUrl!,
                      width: 52,
                      height: 52,
                      fit: BoxFit.cover,
                      placeholder: (_, _) => Container(
                        width: 52,
                        height: 52,
                        color: Colors.grey.withValues(alpha: 0.1),
                      ),
                      errorWidget: (_, _, _) => _buildNoImageBox(),
                    )
                  : _buildNoImageBox(),
            ),
          ),
          const SizedBox(width: 12),

          // Item Info & Options
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.displayName,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
                if (item.secondaryName != null && item.secondaryName!.trim().isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    item.secondaryName!.trim(),
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                ],
                if (item.options.isNotEmpty || (item.optionsString != null && item.optionsString!.isNotEmpty)) ...[
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: item.options.map((opt) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFEDE9FE),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          opt.name,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: isDark ? const Color(0xFFC084FC) : const Color(0xFF7C3AED),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
                if (item.specialInstructions != null && item.specialInstructions!.trim().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(PhosphorIconsRegular.note, size: 12, color: Color(0xFFD97706)),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            item.specialInstructions!.trim(),
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFFB45309),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item.displayPrice.startsWith('฿')
                          ? item.displayPrice
                          : '฿ ${item.displayPrice}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                    Text(
                      '฿ ${(item.price * item.quantity).toStringAsFixed(2)}',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerNoteCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = Theme.of(context).cardColor;
    final note = _currentOrder.deliveryAddress?.note?.trim() ?? '';
    if (note.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      color: cardBg,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(PhosphorIconsFill.notePencil, size: 16, color: Color(0xFFD97706)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Customer Kitchen Note',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFB45309),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    note,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      height: 1.4,
                      color: isDark ? const Color(0xFFFDE68A) : const Color(0xFF78350F),
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

  Widget _buildVerifiedFulfillmentCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = Theme.of(context).cardColor;
    final status = _currentOrder.status.toUpperCase();
    final t = AppLocalizations.of(context);

    if (status == 'PENDING' || status == 'COOKING' || status == 'ON_THE_WAY') {
      return const SizedBox.shrink();
    }

    if (status == 'READY_FOR_PICKUP') {
      final hasTracking = _currentOrder.trackingUrl != null && _currentOrder.trackingUrl!.trim().isNotEmpty;
      final hasRider = _currentOrder.riderName != null && _currentOrder.riderName!.trim().isNotEmpty;
      final cleanNo = _cleanOrderNo(_currentOrder.lastOrderNo);

      return Container(
        width: double.infinity,
        color: cardBg,
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(PhosphorIconsFill.package, color: Color(0xFF10B981), size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Food Packed & Ready for Pickup 📦',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF10B981),
                        ),
                      ),
                      Text(
                        hasRider
                            ? 'Courier ${_currentOrder.riderName ?? ""} (${_currentOrder.vehicleNo ?? ""}) will arrive shortly.'
                            : 'Food is waiting at the counter for courier pickup.',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(PhosphorIconsFill.ticket, size: 16, color: Color(0xFF10B981)),
                      const SizedBox(width: 8),
                      Text(
                        'Pickup Code: MT-$cleanNo',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: 'MT-$cleanNo'));
                      AppDialog.showToast(context, 'Pickup code copied');
                    },
                    child: const Icon(PhosphorIconsRegular.copy, size: 16, color: Color(0xFF10B981)),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }



    if (status == 'DELIVERED') {
      return Container(
        width: double.infinity,
        color: cardBg,
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        child: Row(
          children: [
            const Icon(PhosphorIconsFill.checkCircle, color: Color(0xFF10B981), size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order Delivered Successfully',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF10B981),
                    ),
                  ),
                  Text(
                    'Customer has received this order.',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            if (_currentOrder.proofPhotoUrl != null && _currentOrder.proofPhotoUrl!.isNotEmpty)
              TextButton(
                onPressed: () => _showProofOfDeliveryDialog(_currentOrder.proofPhotoUrl!),
                child: Text(
                  'View POD',
                  style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF10B981)),
                ),
              ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildVerifiedPaymentSummaryCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = Theme.of(context).cardColor;
    final t = AppLocalizations.of(context);

    final rawSubtotal = _currentOrder.foodPrice;
    final deliveryFee = _currentOrder.deliveryFee;
    final hasTax = _currentOrder.taxEnable || _currentOrder.resolvedTaxAmount > 0;
    final taxAmount = _currentOrder.resolvedTaxAmount > 0
        ? _currentOrder.resolvedTaxAmount
        : (_currentOrder.taxAmount > 0 ? _currentOrder.taxAmount : 0.0);
    final discountAmount = _currentOrder.discountAmount;
    final transactionDiscount = _currentOrder.transactionDiscount;
    final totalAmount = _currentOrder.totalAmount > 0
        ? _currentOrder.totalAmount
        : _currentOrder.checkoutTotal;
    final itemsSubtotal = rawSubtotal > 0
        ? rawSubtotal
        : (totalAmount - deliveryFee - (hasTax && taxAmount > 0 ? taxAmount : 0.0) + discountAmount + transactionDiscount)
            .clamp(0.0, double.infinity);

    return Container(
      width: double.infinity,
      color: cardBg,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Clean Header (Without Paid Online Badge) ──
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  PhosphorIconsFill.receipt,
                  size: 16,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Payment Summary',
                style: GoogleFonts.poppins(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // ── Clean Breakdown Frame ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                // Items Subtotal
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _safeTranslate('items_subtotal', 'Items Subtotal'),
                      style: GoogleFonts.poppins(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                    Text(
                      itemsSubtotal.toStringAsFixed(2),
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),

                // Tax (7%) if applicable
                if (hasTax && taxAmount > 0) ...[
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Tax (7%)',
                        style: GoogleFonts.poppins(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                      Text(
                        taxAmount.toStringAsFixed(2),
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                ],

                // Delivery Fee
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _safeTranslate('delivery_fee', 'Delivery Fee'),
                      style: GoogleFonts.poppins(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                    Text(
                      _currentOrder.isFreeDelivery
                          ? 'Free'
                          : (deliveryFee > 0
                              ? deliveryFee.toStringAsFixed(2)
                              : 'Free'),
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _currentOrder.isFreeDelivery || deliveryFee == 0
                            ? const Color(0xFF10B981)
                            : (isDark ? Colors.white : const Color(0xFF0F172A)),
                      ),
                    ),
                  ],
                ),

                // Coupon Discount (if any)
                if (discountAmount > 0) ...[
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            PhosphorIconsFill.ticket,
                            size: 14,
                            color: Color(0xFF10B981),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _currentOrder.couponName?.isNotEmpty == true
                                ? _currentOrder.couponName!
                                : _safeTranslate('coupon_discount', 'Coupon Discount'),
                            style: GoogleFonts.poppins(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF10B981),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '-${discountAmount.toStringAsFixed(2)}',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                ],

                // Transaction Discount (if any)
                if (transactionDiscount > 0) ...[
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _safeTranslate('transaction_discount', 'Transaction Discount'),
                        style: GoogleFonts.poppins(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF10B981),
                        ),
                      ),
                      Text(
                        '-${transactionDiscount.toStringAsFixed(2)}',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                ],

                // Divider
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Divider(
                    height: 1,
                    thickness: 0.8,
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                ),

                // Total Amount
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Amount',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    ShaderMask(
                      blendMode: BlendMode.srcIn,
                      shaderCallback: (bounds) => AppColors.primaryGradient.createShader(
                        Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                      ),
                      child: Text(
                        '฿${totalAmount.toStringAsFixed(2)}',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerifiedCustomerAndDeliveryCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = Theme.of(context).cardColor;
    final dividerColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9);

    return InkWell(
      onTap: _showCustomerInfoBottomSheet,
      child: Container(
        width: double.infinity,
        color: cardBg,
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      'Customer & Delivery Address',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      PhosphorIconsRegular.caretRight,
                      size: 14,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: _currentOrder.deliveryAddressDetail));
                    AppDialog.showToast(context, 'Address copied to clipboard');
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          PhosphorIconsRegular.copy,
                          size: 13,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Copy',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  backgroundImage: (_currentOrder.customerAvatar != null &&
                          _currentOrder.customerAvatar!.isNotEmpty)
                      ? CachedNetworkImageProvider(_currentOrder.customerAvatar!)
                      : null,
                  child: (_currentOrder.customerAvatar == null ||
                          _currentOrder.customerAvatar!.isEmpty)
                      ? Text(
                          _currentOrder.customerName.isNotEmpty
                              ? _currentOrder.customerName[0].toUpperCase()
                              : 'C',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _currentOrder.customerName,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : const Color(0xFF1E293B),
                        ),
                      ),
                      Text(
                        _currentOrder.customerPhone,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                _buildCircularIcon(PhosphorIconsFill.phone, onTap: _callCustomer),
                const SizedBox(width: 8),
                if (_currentOrder.status != 'CANCELED')
                  _buildCircularIcon(
                    PhosphorIconsFill.chatCircleDots,
                    onTap: _openCustomerChat,
                    badgeCount: _chatUnreadCount,
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Divider(color: dividerColor, height: 1),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(PhosphorIconsFill.mapPin, size: 16, color: Color(0xFFED3973)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _currentOrder.deliveryAddressDetail,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      height: 1.4,
                      color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showCustomerInfoBottomSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textPrimary = isDark ? Colors.white : const Color(0xFF1E293B);
    final textMuted = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          padding: EdgeInsets.fromLTRB(
            20,
            12,
            20,
            MediaQuery.of(sheetContext).padding.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Drag Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // 2. Header Row: Title & Close Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Customer & Delivery',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(sheetContext),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          PhosphorIconsRegular.x,
                          size: 16,
                          color: textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 3. Customer Profile Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                        backgroundImage: (_currentOrder.customerAvatar != null &&
                                _currentOrder.customerAvatar!.isNotEmpty)
                            ? CachedNetworkImageProvider(_currentOrder.customerAvatar!)
                            : null,
                        child: (_currentOrder.customerAvatar == null ||
                                _currentOrder.customerAvatar!.isEmpty)
                            ? Text(
                                _currentOrder.customerName.isNotEmpty
                                    ? _currentOrder.customerName[0].toUpperCase()
                                    : 'C',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    _currentOrder.customerName.isNotEmpty
                                        ? _currentOrder.customerName
                                        : 'Customer',
                                    style: GoogleFonts.poppins(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: textPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.verified,
                                  size: 16,
                                  color: Color(0xFF0284C7),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _currentOrder.customerPhone.isNotEmpty
                                  ? _currentOrder.customerPhone
                                  : 'No phone provided',
                              style: GoogleFonts.poppins(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                                color: textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Quick Call Circle Button (Primary Gradient)
                      Container(
                        decoration: const BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          shape: BoxShape.circle,
                        ),
                        child: Material(
                          color: Colors.transparent,
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: () {
                              Navigator.pop(sheetContext);
                              _callCustomer();
                            },
                            child: const Padding(
                              padding: EdgeInsets.all(10),
                              child: Icon(
                                PhosphorIconsFill.phone,
                                size: 20,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (_currentOrder.status != 'CANCELED') ...[
                        const SizedBox(width: 8),
                        // Quick Chat Circle Button
                        Material(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: () {
                              Navigator.pop(sheetContext);
                              _openCustomerChat();
                            },
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: Icon(
                                    PhosphorIconsFill.chatCircleDots,
                                    size: 20,
                                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                                  ),
                                ),
                                if (_chatUnreadCount > 0)
                                  Positioned(
                                    right: 2,
                                    top: 2,
                                    child: Container(
                                      width: 9,
                                      height: 9,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFEF4444),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // 4. Delivery Address Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Delivery Address',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: textPrimary,
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
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(PhosphorIconsRegular.copy, size: 12, color: textMuted),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Copy',
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            PhosphorIconsFill.mapPin,
                            size: 18,
                            color: Color(0xFFED3973),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _currentOrder.deliveryAddressDetail,
                              style: GoogleFonts.poppins(
                                fontSize: 12.5,
                                height: 1.45,
                                color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_currentOrder.deliveryAddress?.note != null &&
                          _currentOrder.deliveryAddress!.note!.trim().isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                PhosphorIconsFill.notepad,
                                size: 15,
                                color: Color(0xFFF59E0B),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Note: ${_currentOrder.deliveryAddress!.note!.trim()}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                    color: isDark ? const Color(0xFFFCD34D) : const Color(0xFFB45309),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showItemImageDialog(String imageUrl) {
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
                          imageUrl: imageUrl,
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
                        color: Colors.black.withValues(alpha: 0.7),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: IconButton(
                        padding: const EdgeInsets.all(4),
                        constraints: const BoxConstraints(),
                        icon: const Icon(Icons.close, color: Colors.white, size: 20),
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

  Future<void> _dispatchLalamove() async {
    if (_isCustomerLocationInvalid) {
      _showInvalidLocationDialog();
      return;
    }

    setState(() => _isDispatchingLalamove = true);
    try {
      final res = await OrderService().dispatchWithProvider(
        _currentOrder.id.toString(),
        provider: 'LALAMOVE',
      );
      if (res['success'] == true) {
        final rawUrl = res['trackingUrl'] ??
            (res['data'] is Map ? res['data']['trackingUrl'] : null);
        final urlStr = rawUrl?.toString();
        if (urlStr != null && urlStr.isNotEmpty) {
          _deliveryTrackingUrlController.text = urlStr;
        }
        if (mounted) {
          AppDialog.showToast(
            context,
            'Lalamove rider requested! Live tracking active.',
            isError: false,
          );
        }
        await _fetchOrderDetails();
        if (mounted) {
          _openTrackingUrl(_currentOrder.trackingUrl ?? urlStr);
        }
      } else {
        if (mounted) {
          final errorMsg =
              res['message']?.toString() ?? 'Failed to dispatch Lalamove.';
          AppDialog.showToast(context, errorMsg, isError: true);
        }
      }
    } catch (e) {
      if (mounted) {
        AppDialog.showToast(context, 'Error: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isDispatchingLalamove = false);
      }
    }
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
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final available =
        media.size.height - media.viewInsets.bottom - media.padding.top - 16;
    final maxHeight = available < 0 ? 0.0 : available;

    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + media.padding.bottom),
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
                        if (!context.mounted) return;
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
                        if (!context.mounted) return;
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
            const SizedBox(height: 24),
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
        ),
      ),
    );
  }
}

class _OrderDetailMapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFF64748B).withValues(alpha: 0.12)
      ..strokeWidth = 1.0;

    const step = 20.0;
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    final routePaint = Paint()
      ..color = const Color(0xFF64748B).withValues(alpha: 0.20)
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(size.width * 0.12, size.height * 0.5),
      Offset(size.width * 0.88, size.height * 0.5),
      routePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _IncomingFloatingNotificationData {
  final String senderName;
  final String? senderAvatar;
  final String messageText;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  _IncomingFloatingNotificationData({
    required this.senderName,
    this.senderAvatar,
    required this.messageText,
    required this.onTap,
    required this.onDismiss,
  });
}

class _FloatingMessengerNotificationBanner extends StatefulWidget {
  final _IncomingFloatingNotificationData data;

  const _FloatingMessengerNotificationBanner({
    super.key,
    required this.data,
  });

  @override
  State<_FloatingMessengerNotificationBanner> createState() =>
      _FloatingMessengerNotificationBannerState();
}

class _FloatingMessengerNotificationBannerState
    extends State<_FloatingMessengerNotificationBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  Timer? _autoDismissTimer;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
      reverseDuration: const Duration(milliseconds: 250),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.easeOutBack,
        reverseCurve: Curves.easeInCubic,
      ),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );

    HapticFeedback.mediumImpact();
    _animController.forward();

    _autoDismissTimer = Timer(const Duration(seconds: 5), () {
      _dismiss();
    });
  }

  void _dismiss() {
    if (!mounted) return;
    _autoDismissTimer?.cancel();
    _animController.reverse().then((_) {
      if (mounted) {
        widget.data.onDismiss();
      }
    });
  }

  @override
  void dispose() {
    _autoDismissTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF1E293B);
    final textSecondary = isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569);
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: GestureDetector(
          onVerticalDragEnd: (details) {
            if ((details.primaryVelocity ?? 0) < -80) {
              _dismiss();
            }
          },
          onTap: () {
            _autoDismissTimer?.cancel();
            widget.data.onTap();
          },
          child: Container(
            margin: const EdgeInsets.fromLTRB(14, 8, 14, 0),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: borderColor, width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.16),
                  blurRadius: 22,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Messenger-style Avatar with Chat Bubble badge
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                      backgroundImage: (widget.data.senderAvatar != null &&
                              widget.data.senderAvatar!.isNotEmpty)
                          ? CachedNetworkImageProvider(widget.data.senderAvatar!)
                          : null,
                      child: (widget.data.senderAvatar == null ||
                              widget.data.senderAvatar!.isEmpty)
                          ? Text(
                              widget.data.senderName.isNotEmpty
                                  ? widget.data.senderName[0].toUpperCase()
                                  : 'C',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            )
                          : null,
                    ),
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          shape: BoxShape.circle,
                          border: Border.all(color: cardBg, width: 2),
                        ),
                        child: const Icon(
                          PhosphorIconsFill.chatCircleDots,
                          size: 10,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                // Sender name & message preview
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              widget.data.senderName,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'now',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.data.messageText,
                        style: GoogleFonts.poppins(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: textSecondary,
                          height: 1.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                // Reply Action Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Reply',
                        style: GoogleFonts.poppins(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 3),
                      const Icon(
                        PhosphorIconsBold.arrowRight,
                        size: 11,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
