import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:dio/dio.dart';

import '../../data/models/order_model.dart';
import '../../data/services/order_service.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../../core/utils/file_url_util.dart';
import '../../../../core/presentation/widgets/app_dialog.dart';
import '../../../../core/presentation/widgets/primary_gradient_button.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../main_navigation/presentation/screens/main_navigation_screen.dart';
import '../../../../core/network/websocket_service.dart';
import '../../../../core/config/env_config.dart';
import '../../../profile/data/services/profile_service.dart';

enum LalamoveLifecycleState {
  searching, // ASSIGNING_DRIVER - Finding rider
  accepted,  // ON_GOING - Rider found, heading to store
  arrived,   // ARRIVED_AT_STORE - Rider arrived at store
  pickedUp,  // PICKED_UP - Out for delivery to customer
  delivered, // COMPLETED - Delivered to customer
  rejected,  // REJECTED / CANCELLED - Rider rejected/cancelled
}

class LiveDeliveryTrackingScreen extends StatefulWidget {
  final OrderModel order;
  final bool isSandbox;
  final double? shopLatitude;
  final double? shopLongitude;

  const LiveDeliveryTrackingScreen({
    super.key,
    required this.order,
    this.isSandbox = true,
    this.shopLatitude,
    this.shopLongitude,
  });

  @override
  State<LiveDeliveryTrackingScreen> createState() => _LiveDeliveryTrackingScreenState();
}

class _LiveDeliveryTrackingScreenState extends State<LiveDeliveryTrackingScreen>
    with SingleTickerProviderStateMixin {
  late OrderModel _currentOrder;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  WebViewController? _webViewController;
  bool _isWebViewLoading = true;
  bool _isSimulating = false;

  LalamoveLifecycleState _lifecycleState = LalamoveLifecycleState.searching;
  StreamSubscription<Map<String, dynamic>>? _wsSub;

  // Real-time searching elapsed timer & polling timer
  Timer? _searchTimer;
  Timer? _pollTimer;
  int _searchSeconds = 0;
  bool _isRefreshing = false;

  // Real-time Driver Information
  String? _driverName;
  String? _driverPhone;
  String? _driverPlate;
  String? _driverAvatar;

  // Real Shop Info
  String _shopName = 'Your Shop';
  String? _shopLogo;

  // Real Coordinates
  double _shopLat = 13.7563;
  double _shopLng = 100.5018;
  double _custLat = 13.7763;
  double _custLng = 100.5218;
  double? _driverLat;
  double? _driverLng;

  @override
  void initState() {
    super.initState();
    _currentOrder = widget.order;
    _driverName = _currentOrder.riderName;
    _driverPhone = _currentOrder.riderPhone;
    _driverPlate = _currentOrder.vehicleNo;
    _driverAvatar = _resolveDriverAvatar();
    _resolveShopInfo();
    _resolveCoordinates();
    _resolveInitialState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.25).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _initRealMapWebView();
    _subscribeToOrderUpdates();
    _startSearchTimerIfNeeded();
    _startPolling();
    // Immediate silent poll so latest driver/lifecycle data is loaded without waiting 4s
    _pollOrderDetails(silent: true);
  }

  void _startPolling() {
    _pollTimer?.cancel();
    // Periodic refresh every 4 seconds to guarantee syncing with Lalamove Webhooks / Portal changes
    _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (mounted) _pollOrderDetails(silent: true);
    });
  }

  Future<void> _pollOrderDetails({bool silent = true}) async {
    if (_isRefreshing) return;
    if (!silent && mounted) setState(() => _isRefreshing = true);
    try {
      final updated = await OrderService().getOrderDetail(_currentOrder.id.toString());
      if (updated != null && mounted) {
        setState(() {
          _currentOrder = updated;
          if (updated.riderName != null &&
              updated.riderName!.trim().isNotEmpty &&
              updated.riderName != 'Assigning Rider...') {
            _driverName = updated.riderName!.trim();
          } else if (updated.lalamoveStatus == 'ASSIGNING_DRIVER' || updated.lalamoveStatus == 'REJECTED') {
            _driverName = null;
          }

          if (updated.riderPhone != null && updated.riderPhone!.trim().isNotEmpty) {
            _driverPhone = updated.riderPhone!.trim();
          } else if (updated.lalamoveStatus == 'ASSIGNING_DRIVER' || updated.lalamoveStatus == 'REJECTED') {
            _driverPhone = null;
          }

          if (updated.vehicleNo != null && updated.vehicleNo!.trim().isNotEmpty) {
            _driverPlate = updated.vehicleNo!.trim();
          } else if (updated.lalamoveStatus == 'ASSIGNING_DRIVER' || updated.lalamoveStatus == 'REJECTED') {
            _driverPlate = null;
          }

          _driverAvatar = _resolveDriverAvatar();
          _updateLifecycleFromOrder(updated);
        });
        _syncMapStateToWebView();
        _syncRiderAvatarToWebView();
        _syncCustomerInfoToWebView();
        if (!silent && mounted) {
          AppDialog.showToast(context, 'Delivery status refreshed', isError: false);
        }
      }
    } catch (_) {
    } finally {
      if (!silent && mounted) setState(() => _isRefreshing = false);
    }
  }

  void _resolveShopInfo() {
    if (_currentOrder.shopName.trim().isNotEmpty) {
      _shopName = _currentOrder.shopName.trim();
    }
    if (_currentOrder.shopLogo != null && _currentOrder.shopLogo!.trim().isNotEmpty) {
      _shopLogo = _currentOrder.shopLogo!.trim();
    }
    _fetchShopProfile();
  }

  Future<void> _fetchShopProfile() async {
    try {
      final profile = await ProfileService().getShopProfile();
      if (profile != null && mounted) {
        setState(() {
          if (profile.displayName.trim().isNotEmpty) {
            _shopName = profile.displayName.trim();
          }
          final resolvedLogo = FileUrlUtil.resolve(profile.logoUrl);
          if (resolvedLogo != null && resolvedLogo.trim().isNotEmpty) {
            _shopLogo = resolvedLogo.trim();
          }
          if (widget.shopLatitude == null && profile.latitude != null) {
            _shopLat = profile.latitude!;
          }
          if (widget.shopLongitude == null && profile.longitude != null) {
            _shopLng = profile.longitude!;
          }
        });
        _syncShopInfoToWebView();
      }
    } catch (_) {}
  }

  void _syncShopInfoToWebView() {
    if (_webViewController == null) return;
    final safeName = _escapeJs(_shopName);
    final safeLogo = _escapeJs(_shopLogo ?? '');
    _webViewController?.runJavaScript(
      "if (window.updateStoreInfo) { window.updateStoreInfo('$safeName', '$safeLogo'); } if (window.updateShopCoordinates) { window.updateShopCoordinates($_shopLat, $_shopLng); }",
    );
  }

  String? _resolveDriverAvatar() {
    final isLalamove = _currentOrder.isLalamoveDelivery ||
        (_currentOrder.lalamoveStatus != null && _currentOrder.lalamoveStatus!.trim().isNotEmpty);

    // Lalamove does not distribute driver face photos (PDPA privacy laws in Thailand)
    // Always returns null for Lalamove so the branded pink moped courier icon badge is used
    if (isLalamove) {
      return null;
    }

    // 1. Direct rider avatar from the order (real photo for shop delivery driver)
    if (_currentOrder.riderAvatar != null && _currentOrder.riderAvatar!.trim().isNotEmpty) {
      return _currentOrder.riderAvatar!.trim();
    }

    // 2. Assigned driver from shop delivery drivers
    if (_currentOrder.driverId != null && _currentOrder.shopDeliveryDrivers.isNotEmpty) {
      for (final d in _currentOrder.shopDeliveryDrivers) {
        if (d.id == _currentOrder.driverId && d.profileUrl != null && d.profileUrl!.trim().isNotEmpty) {
          return d.profileUrl!.trim();
        }
      }
    }

    return null;
  }

  void _syncRiderAvatarToWebView() {
    if (_webViewController == null) return;
    final safeAvatar = _escapeJs(_driverAvatar ?? '');
    _webViewController?.runJavaScript(
      "if (window.updateRiderAvatar) { window.updateRiderAvatar('$safeAvatar'); }",
    );
  }

  void _syncCustomerInfoToWebView() {
    if (_webViewController == null) return;
    final safeName = _escapeJs(_currentOrder.customerName.isNotEmpty ? _currentOrder.customerName : 'Customer');
    final safeAvatar = _escapeJs(_currentOrder.customerAvatar ?? '');
    _webViewController?.runJavaScript(
      "if (window.updateCustomerInfo) { window.updateCustomerInfo('$safeName', '$safeAvatar'); }",
    );
  }

  String _escapeJs(String text) {
    return text
        .replaceAll(r'\', r'\\')
        .replaceAll("'", r"\'")
        .replaceAll('"', r'\"')
        .replaceAll('\n', r' ')
        .replaceAll('\r', '');
  }

  void _resolveCoordinates() {
    final sLat = widget.shopLatitude;
    final sLng = widget.shopLongitude;
    if (sLat != null && sLng != null && sLat >= 12.0 && sLat <= 16.0 && sLng >= 99.0 && sLng <= 102.0) {
      _shopLat = sLat;
      _shopLng = sLng;
    } else {
      _shopLat = 13.7563;
      _shopLng = 100.5018;
    }

    final cLat = _currentOrder.lat ?? _currentOrder.deliveryAddress?.latitude;
    final cLng = _currentOrder.lon ?? _currentOrder.deliveryAddress?.longitude;
    if (cLat != null && cLng != null && cLat >= 12.0 && cLat <= 16.0 && cLng >= 99.0 && cLng <= 102.0) {
      _custLat = cLat;
      _custLng = cLng;
    } else {
      _custLat = _shopLat + 0.022;
      _custLng = _shopLng + 0.018;
    }
  }

  void _resolveInitialState() {
    final status = _currentOrder.status.toUpperCase();
    final llmStatus = _currentOrder.lalamoveStatus?.toUpperCase();
    final effectiveDriver = _driverName ?? _currentOrder.riderName;
    final isDriverAssigned = effectiveDriver != null &&
        effectiveDriver.trim().isNotEmpty &&
        effectiveDriver != 'Assigning Rider...';
    final hasTracking = _currentOrder.trackingUrl != null && _currentOrder.trackingUrl!.trim().isNotEmpty;

    if (status == 'DELIVERED' || llmStatus == 'COMPLETED') {
      _lifecycleState = LalamoveLifecycleState.delivered;
    } else if (status == 'PICKED_UP' || llmStatus == 'PICKED_UP') {
      _lifecycleState = LalamoveLifecycleState.pickedUp;
    } else if (llmStatus == 'ARRIVED_AT_STORE') {
      _lifecycleState = LalamoveLifecycleState.arrived;
    } else if (llmStatus == 'REJECTED' || llmStatus == 'CANCELLED') {
      _lifecycleState = LalamoveLifecycleState.rejected;
    } else if (llmStatus == 'ON_GOING' ||
        llmStatus == 'ASSIGNED' ||
        llmStatus == 'ACCEPTED' ||
        isDriverAssigned ||
        status == 'ON_THE_WAY' ||
        hasTracking) {
      _lifecycleState = LalamoveLifecycleState.accepted;
    } else if (llmStatus == 'ASSIGNING_DRIVER') {
      _lifecycleState = LalamoveLifecycleState.searching;
    } else {
      _lifecycleState = LalamoveLifecycleState.searching;
    }
  }

  void _updateLifecycleFromOrder(OrderModel order) {
    final llmStatus = order.lalamoveStatus?.toUpperCase();
    final effectiveDriver = _driverName ?? order.riderName;
    final isDriverAssigned = effectiveDriver != null &&
        effectiveDriver.trim().isNotEmpty &&
        effectiveDriver != 'Assigning Rider...';
    final hasTracking = order.trackingUrl != null && order.trackingUrl!.trim().isNotEmpty;
    final status = order.status.toUpperCase();

    if (status == 'DELIVERED' || llmStatus == 'COMPLETED') {
      _lifecycleState = LalamoveLifecycleState.delivered;
    } else if (llmStatus == 'PICKED_UP' || status == 'PICKED_UP') {
      _lifecycleState = LalamoveLifecycleState.pickedUp;
    } else if (llmStatus == 'ARRIVED_AT_STORE') {
      _lifecycleState = LalamoveLifecycleState.arrived;
    } else if (llmStatus == 'REJECTED' || llmStatus == 'CANCELLED') {
      _lifecycleState = LalamoveLifecycleState.rejected;
    } else if (llmStatus == 'ON_GOING' ||
        llmStatus == 'ASSIGNED' ||
        llmStatus == 'ACCEPTED' ||
        isDriverAssigned ||
        status == 'ON_THE_WAY' ||
        hasTracking) {
      _lifecycleState = LalamoveLifecycleState.accepted;
    } else if (llmStatus == 'ASSIGNING_DRIVER') {
      if (_lifecycleState != LalamoveLifecycleState.accepted &&
          _lifecycleState != LalamoveLifecycleState.arrived &&
          _lifecycleState != LalamoveLifecycleState.pickedUp) {
        _lifecycleState = LalamoveLifecycleState.searching;
      }
    } else if (llmStatus == null &&
        (_lifecycleState == LalamoveLifecycleState.accepted ||
            _lifecycleState == LalamoveLifecycleState.arrived ||
            _lifecycleState == LalamoveLifecycleState.pickedUp)) {
      // Retain active delivery status; do not revert to searching
    } else {
      _lifecycleState = LalamoveLifecycleState.searching;
    }
  }

  void _startSearchTimerIfNeeded() {
    if (_lifecycleState == LalamoveLifecycleState.searching) {
      _searchTimer?.cancel();
      _searchTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) return;
        setState(() => _searchSeconds++);
      });
    } else {
      _searchTimer?.cancel();
    }
  }

  void _initRealMapWebView() {
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFFF8FAFC))
      ..setOnConsoleMessage((message) {
        debugPrint('[LeafletWebView] ${message.level.name}: ${message.message}');
      })
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (mounted) setState(() => _isWebViewLoading = false);
            _syncMapStateToWebView();
            _syncShopInfoToWebView();
            _syncRiderAvatarToWebView();
            _syncCustomerInfoToWebView();
          },
        ),
      );

    final html = _buildLeafletHtml();
    controller.loadHtmlString(html);
    _webViewController = controller;
  }

  void _syncMapStateToWebView() {
    if (_webViewController == null) return;
    double rLat;
    double rLng;
    final hasRealGps = _driverLat != null && _driverLng != null;

    if (hasRealGps) {
      rLat = _driverLat!;
      rLng = _driverLng!;
    } else {
      switch (_lifecycleState) {
        case LalamoveLifecycleState.searching:
        case LalamoveLifecycleState.rejected:
          rLat = _shopLat;
          rLng = _shopLng;
          break;
        case LalamoveLifecycleState.accepted:
          rLat = _shopLat - 0.007;
          rLng = _shopLng - 0.005;
          break;
        case LalamoveLifecycleState.arrived:
          rLat = _shopLat;
          rLng = _shopLng;
          break;
        case LalamoveLifecycleState.pickedUp:
          rLat = (_shopLat + _custLat) / 2;
          rLng = (_shopLng + _custLng) / 2;
          break;
        case LalamoveLifecycleState.delivered:
          rLat = _custLat;
          rLng = _custLng;
          break;
      }
    }

    final script = "if (window.updateDeliveryState) { window.updateDeliveryState('${_lifecycleState.name}', $rLat, $rLng, $hasRealGps); }";
    _webViewController?.runJavaScript(script);
  }

  String _buildLeafletHtml() {
    final safeShopName = _escapeJs(_shopName);
    final safeShopLogo = _escapeJs(_shopLogo ?? '');
    final safeDriverAvatar = _escapeJs(_driverAvatar ?? '');
    final safeCustName = _escapeJs(_currentOrder.customerName.isNotEmpty ? _currentOrder.customerName : 'Customer');
    final safeCustAvatar = _escapeJs(_currentOrder.customerAvatar ?? '');
    final initRiderLat = _driverLat ?? (_shopLat - 0.007);
    final initRiderLng = _driverLng ?? (_shopLng - 0.005);
    final initHasRealGps = _driverLat != null && _driverLng != null;
    final initialLifecycle = _lifecycleState.name;

    return '''<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8" />
<meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no" />
<link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css" />
<script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>
<style>
  html, body, #map { margin: 0; padding: 0; width: 100%; height: 100%; background: #E5E3DF; overflow: hidden; font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; }

  /* Modern Multi-ring Concentric Radar Pulse for Courier Searching */
  .radar-container {
    position: relative;
    width: 240px;
    height: 240px;
    pointer-events: none;
  }
  .pulse-radar-1, .pulse-radar-2, .pulse-radar-3 {
    position: absolute;
    top: 50%; left: 50%;
    transform: translate(-50%, -50%);
    border-radius: 50%;
    background: rgba(237, 57, 115, 0.12);
    border: 2px solid rgba(237, 57, 115, 0.55);
    box-sizing: border-box;
    pointer-events: none;
  }
  .pulse-radar-1 {
    width: 70px; height: 70px;
    animation: radarPulse 2.4s ease-out infinite;
  }
  .pulse-radar-2 {
    width: 140px; height: 140px;
    animation: radarPulse 2.4s ease-out infinite 0.8s;
  }
  .pulse-radar-3 {
    width: 210px; height: 210px;
    animation: radarPulse 2.4s ease-out infinite 1.6s;
  }
  @keyframes radarPulse {
    0% { transform: translate(-50%, -50%) scale(0.2); opacity: 1; }
    75% { opacity: 0.6; }
    100% { transform: translate(-50%, -50%) scale(1.4); opacity: 0; }
  }

  .pin-badge {
    padding: 4px 10px; border-radius: 20px; font-size: 11px; font-weight: 700;
    white-space: nowrap; box-shadow: 0 4px 12px rgba(0,0,0,0.18);
    display: inline-flex; align-items: center; gap: 4px; border: 2px solid white;
  }
  .store-pin-wrapper {
    position: relative;
    width: 200px;
    height: 52px;
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: flex-end;
    margin: 0;
    padding: 0;
    box-sizing: border-box;
    pointer-events: none;
  }
  .store-pin-card {
    background: #FFFFFF;
    color: #0F172A;
    padding: 3px 9px 3px 5px;
    border-radius: 20px;
    font-size: 11.5px;
    font-weight: 700;
    white-space: nowrap;
    box-shadow: 0 4px 14px rgba(237, 57, 115, 0.22), 0 2px 6px rgba(0,0,0,0.15);
    display: inline-flex;
    align-items: center;
    gap: 6px;
    border: 2px solid #ED3973;
    max-width: 190px;
    margin-bottom: 2px;
    pointer-events: auto;
  }
  .store-pin-logo {
    width: 22px;
    height: 22px;
    border-radius: 50%;
    object-fit: cover;
    border: 1px solid #E2E8F0;
    flex-shrink: 0;
    display: block;
    background: #F8FAFC;
  }
  .store-pin-fallback {
    width: 22px;
    height: 22px;
    border-radius: 50%;
    background: #ED3973;
    color: white;
    font-size: 11px;
    display: flex;
    align-items: center;
    justify-content: center;
    flex-shrink: 0;
  }
  .store-pin-name {
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
    max-width: 150px;
    color: #0F172A;
  }
  .store-dot {
    width: 12px;
    height: 12px;
    background: #ED3973;
    border: 2px solid white;
    border-radius: 50%;
    margin: 0 auto;
    box-shadow: 0 2px 6px rgba(0,0,0,0.3);
    flex-shrink: 0;
  }

  /* Customer Dropoff Pin with Real Circular Avatar & Dropoff Badge */
  .cust-pin-wrapper {
    position: relative;
    width: 160px;
    height: 88px;
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: flex-end;
    margin: 0;
    padding: 0;
    box-sizing: border-box;
    pointer-events: none;
  }
  .cust-pin-badge {
    background: #FFFFFF;
    color: #0F172A;
    padding: 3px 8px;
    border-radius: 12px;
    font-size: 11px;
    font-weight: 700;
    white-space: nowrap;
    box-shadow: 0 3px 10px rgba(16, 185, 129, 0.25), 0 1px 4px rgba(0,0,0,0.12);
    display: inline-flex;
    align-items: center;
    gap: 4px;
    border: 1.5px solid #10B981;
    margin-bottom: 3px;
    max-width: 150px;
    position: relative;
    z-index: 3;
    flex-shrink: 0;
    pointer-events: auto;
  }
  .cust-pin-badge span {
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
  }
  .cust-pulse-halo {
    position: absolute;
    width: 52px;
    height: 52px;
    top: 50%;
    left: 50%;
    transform: translate(-50%, -50%);
    border-radius: 50%;
    background: rgba(16, 185, 129, 0.28);
    animation: custPulse 2s ease-out infinite;
    pointer-events: none;
  }
  @keyframes custPulse {
    0% { transform: translate(-50%, -50%) scale(0.7); opacity: 0.9; }
    100% { transform: translate(-50%, -50%) scale(1.4); opacity: 0; }
  }
  .cust-marker-circle {
    width: 44px;
    height: 44px;
    border-radius: 50%;
    background: #10B981;
    box-shadow: 0 4px 14px rgba(16, 185, 129, 0.45), 0 2px 6px rgba(0,0,0,0.15);
    border: 3px solid #FFFFFF;
    display: flex;
    align-items: center;
    justify-content: center;
    position: relative;
    z-index: 2;
    overflow: hidden;
    box-sizing: border-box;
    flex-shrink: 0;
  }
  .cust-avatar-img {
    width: 100%;
    height: 100%;
    border-radius: 50%;
    object-fit: cover;
    display: block;
  }
  .cust-fallback-icon {
    display: flex;
    align-items: center;
    justify-content: center;
    width: 100%;
    height: 100%;
    background: linear-gradient(135deg, #10B981 0%, #059669 100%);
    color: white;
    font-size: 20px;
    line-height: 1;
  }
  .cust-dot {
    width: 12px;
    height: 12px;
    background: #10B981;
    border: 2px solid white;
    border-radius: 50%;
    margin-top: 2px;
    box-shadow: 0 2px 5px rgba(0,0,0,0.35);
    position: relative;
    z-index: 2;
    flex-shrink: 0;
  }

  /* Animated Rider Marker with Pulsing Beacon & Real Avatar / Scooter Icon */
  .rider-pin-wrapper {
    position: relative;
    width: 52px;
    height: 52px;
    display: flex;
    align-items: center;
    justify-content: center;
  }
  .rider-pulse-halo {
    position: absolute;
    width: 52px;
    height: 52px;
    border-radius: 50%;
    background: rgba(237, 57, 115, 0.28);
    animation: riderPulse 1.8s ease-out infinite;
  }
  @keyframes riderPulse {
    0% { transform: scale(0.6); opacity: 0.9; }
    100% { transform: scale(1.4); opacity: 0; }
  }
  .rider-marker-circle {
    width: 44px;
    height: 44px;
    border-radius: 50%;
    background: linear-gradient(135deg, #ED3973 0%, #EFA240 100%);
    box-shadow: 0 6px 18px rgba(237, 57, 115, 0.45);
    border: 3px solid #FFFFFF;
    display: flex;
    align-items: center;
    justify-content: center;
    position: relative;
    z-index: 2;
    overflow: hidden;
    box-sizing: border-box;
  }
  .rider-avatar-img {
    width: 100%;
    height: 100%;
    border-radius: 50%;
    object-fit: cover;
    display: block;
  }
  .rider-scooter-icon {
    display: flex;
    align-items: center;
    justify-content: center;
    width: 100%;
    height: 100%;
    font-size: 22px;
    line-height: 1;
    transform: translateY(-1px);
    user-select: none;
  }

  /* Primary Gradient Route Styling */
  .route-primary-line {
    stroke: url(#routePrimaryGradient) !important;
  }
  .route-primary-glow {
    stroke: rgba(237, 57, 115, 0.28) !important;
  }
</style>
</head>
<body>
<svg style="position: absolute; width: 0; height: 0; pointer-events: none;" aria-hidden="true">
  <defs>
    <linearGradient id="routePrimaryGradient" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#ED3973" />
      <stop offset="50%" stop-color="#F43F5E" />
      <stop offset="100%" stop-color="#EFA240" />
    </linearGradient>
  </defs>
</svg>
<div id="map"></div>
<script>
  var shop = [$_shopLat, $_shopLng];
  var cust = [$_custLat, $_custLng];
  // Offset latitude southwards so store pin & radar wave sit higher UP on visible map
  var shopCenterOffset = [shop[0] - 0.0095, shop[1]];
  var initialState = '$initialLifecycle';
  var initRiderPos = [$initRiderLat, $initRiderLng];
  var initHasRealGps = $initHasRealGps;

  // Initialize map with appropriate view based on initial state
  var map = L.map('map', { zoomControl: false, attributionControl: false });
  if (initialState === 'accepted') {
    map.fitBounds(L.latLngBounds([initRiderPos, shop]), {
      paddingTopLeft: [50, 100],
      paddingBottomRight: [50, 420],
      maxZoom: 16
    });
  } else if (initialState === 'pickedUp') {
    map.fitBounds(L.latLngBounds([shop, cust]), {
      paddingTopLeft: [50, 100],
      paddingBottomRight: [50, 420]
    });
  } else if (initialState === 'delivered') {
    map.setView(cust, 15);
  } else {
    map.setView(shopCenterOffset, 15);
  }

  // Google Maps Official Standard Roadmap Tiles (Method A: 100% Free, Zero Billing, No API Key Required)
  L.tileLayer('https://mt{s}.google.com/vt/lyrs=m&x={x}&y={y}&z={z}', {
    subdomains: ['0', '1', '2', '3'],
    maxZoom: 21,
    attribution: ''
  }).addTo(map);

  // Store Marker with Real Shop Logo & Name
  var currentShopName = '$safeShopName';
  var currentShopLogo = '$safeShopLogo';

  function hideStoreLogo(img) {
    if (img && img.parentNode) {
      img.outerHTML = '<div class="store-pin-fallback">🏬</div>';
    }
  }

  function hideRiderAvatar(img) {
    if (img && img.parentNode) {
      img.outerHTML = '<div class="rider-scooter-icon">🛵</div>';
    }
  }

  function hideCustAvatar(img) {
    if (img && img.parentNode) {
      img.outerHTML = '<div class="cust-fallback-icon">👤</div>';
    }
  }

  function fetchRealDrivingRoute(start, end, cb) {
    if (!start || !end) return;
    var url = 'https://router.project-osrm.org/route/v1/driving/' +
              start[1] + ',' + start[0] + ';' + end[1] + ',' + end[0] +
              '?overview=full&geometries=geojson&continue_straight=true';
    fetch(url)
      .then(function(res) { return res.json(); })
      .then(function(data) {
        if (data && data.routes && data.routes[0] && data.routes[0].geometry) {
          var pts = data.routes[0].geometry.coordinates.map(function(c) {
            return [c[1], c[0]];
          });
          if (pts && pts.length > 1) {
            cb(pts);
          }
        }
      })
      .catch(function(e) {});
  }

  function buildStoreMarkerHtml(name, logoUrl) {
    var logoHtml = '';
    if (logoUrl && logoUrl.length > 5) {
      logoHtml = '<img src="' + encodeURI(logoUrl) + '" class="store-pin-logo" onerror="hideStoreLogo(this)" />';
    } else {
      logoHtml = '<div class="store-pin-fallback">🏬</div>';
    }
    return '<div class="store-pin-wrapper">' +
             '<div class="store-pin-card">' +
               logoHtml +
               '<span class="store-pin-name">' + (name || 'Store') + '</span>' +
             '</div>' +
             '<div class="store-dot"></div>' +
           '</div>';
  }

  var storeIcon = L.divIcon({
    className: '',
    html: buildStoreMarkerHtml(currentShopName, currentShopLogo),
    iconSize: [200, 52],
    iconAnchor: [100, 52]
  });
  var storeMarker = L.marker(shop, { icon: storeIcon, zIndexOffset: 500 }).addTo(map);

  window.updateStoreInfo = function(name, logoUrl) {
    currentShopName = name;
    currentShopLogo = logoUrl;
    var updatedIcon = L.divIcon({
      className: '',
      html: buildStoreMarkerHtml(name, logoUrl),
      iconSize: [200, 52],
      iconAnchor: [100, 52]
    });
    storeMarker.setIcon(updatedIcon);
  };

  window.updateShopCoordinates = function(lat, lng) {
    if (lat && lng && (shop[0] !== lat || shop[1] !== lng)) {
      shop = [lat, lng];
      shopCenterOffset = [lat - 0.0095, lng];
      storeMarker.setLatLng(shop);
      radarMarker.setLatLng(shop);
      fetchRealDrivingRoute(shop, cust, function(realPts) {
        deliveryRoutePoints = realPts;
        routeGlow.setLatLngs(realPts);
        routeLine.setLatLngs(realPts);
      });
    }
  };

  // Radar Pulsing Marker (Around Store during Searching)
  var radarIcon = L.divIcon({
    className: '',
    html: '<div class="radar-container"><div class="pulse-radar-1"></div><div class="pulse-radar-2"></div><div class="pulse-radar-3"></div></div>',
    iconSize: [240, 240],
    iconAnchor: [120, 120]
  });
  var radarMarker = L.marker(shop, { icon: radarIcon, zIndexOffset: 100 });

  // Customer Marker (Shown during pickedUp and delivered) with Real Circular Avatar & Dropoff Badge
  var currentCustName = '$safeCustName';
  var currentCustAvatar = '$safeCustAvatar';

  function buildCustMarkerHtml(name, avatarUrl) {
    var avatarHtml = '';
    if (avatarUrl && avatarUrl.length > 5) {
      avatarHtml = '<img src="' + encodeURI(avatarUrl) + '" class="cust-avatar-img" onerror="hideCustAvatar(this)" />';
    } else {
      avatarHtml = '<div class="cust-fallback-icon">👤</div>';
    }
    var displayName = (name && name.length > 0) ? name : 'Customer';
    return '<div class="cust-pin-wrapper">' +
             '<div class="cust-pin-badge"><span>📍 ' + displayName + '</span></div>' +
             '<div style="position: relative; width: 44px; height: 44px;">' +
               '<div class="cust-pulse-halo"></div>' +
               '<div class="cust-marker-circle">' + avatarHtml + '</div>' +
             '</div>' +
             '<div class="cust-dot"></div>' +
           '</div>';
  }

  var custIcon = L.divIcon({
    className: '',
    html: buildCustMarkerHtml(currentCustName, currentCustAvatar),
    iconSize: [160, 88],
    iconAnchor: [80, 88]
  });
  var custMarker = L.marker(cust, { icon: custIcon, zIndexOffset: 500 });

  window.updateCustomerInfo = function(name, avatarUrl) {
    currentCustName = name;
    currentCustAvatar = avatarUrl;
    var updatedIcon = L.divIcon({
      className: '',
      html: buildCustMarkerHtml(name, avatarUrl),
      iconSize: [160, 88],
      iconAnchor: [80, 88]
    });
    custMarker.setIcon(updatedIcon);
  };

  function buildRiderMarkerHtml(avatarUrl) {
    if (avatarUrl && avatarUrl.length > 5) {
      return '<div class="rider-pin-wrapper"><div class="rider-pulse-halo"></div><div class="rider-marker-circle"><img src="' + encodeURI(avatarUrl) + '" class="rider-avatar-img" onerror="hideRiderAvatar(this)" /></div></div>';
    }
    return '<div class="rider-pin-wrapper"><div class="rider-pulse-halo"></div><div class="rider-marker-circle"><div class="rider-scooter-icon">🛵</div></div></div>';
  }

  // Rider Marker with Pulsing Beacon & Real Avatar / Scooter Fallback
  var riderIcon = L.divIcon({
    className: '',
    html: buildRiderMarkerHtml('$safeDriverAvatar'),
    iconSize: [52, 52],
    iconAnchor: [26, 26]
  });
  var riderMarker = L.marker(shop, { icon: riderIcon, zIndexOffset: 1000 });

  window.updateRiderAvatar = function(avatarUrl) {
    var updatedIcon = L.divIcon({
      className: '',
      html: buildRiderMarkerHtml(avatarUrl),
      iconSize: [52, 52],
      iconAnchor: [26, 26]
    });
    riderMarker.setIcon(updatedIcon);
  };

  // Route: Store -> Customer (for pickedUp / delivery phase)
  var mid1 = [shop[0] * 0.7 + cust[0] * 0.3, shop[1] * 0.6 + cust[1] * 0.4 + 0.004];
  var mid2 = [shop[0] * 0.3 + cust[0] * 0.7, shop[1] * 0.4 + cust[1] * 0.6 - 0.003];
  var deliveryRoutePoints = [shop, mid1, mid2, cust];

  var routeGlow = L.polyline(deliveryRoutePoints, { color: 'rgba(237, 57, 115, 0.28)', weight: 12, lineCap: 'round', lineJoin: 'round', className: 'route-primary-glow' });
  var routeLine = L.polyline(deliveryRoutePoints, { color: '#ED3973', weight: 5, lineCap: 'round', lineJoin: 'round', className: 'route-primary-line' });

  function getPointAlongRoute(progress) {
    if (!deliveryRoutePoints || deliveryRoutePoints.length === 0) return shop;
    var idx = Math.floor((deliveryRoutePoints.length - 1) * Math.max(0, Math.min(1, progress)));
    return deliveryRoutePoints[idx];
  }

  // Real-Time Road Tracking Simulator (for Testing / Sandbox when no satellite feed is available)
  var simProgress = 0.35;
  var simTimer = null;

  function runRouteSimulation() {
    if (simTimer) clearInterval(simTimer);
    simTimer = setInterval(function() {
      if (window.hasRealDriverGps || window.currentDeliveryState !== 'pickedUp') return;
      if (!deliveryRoutePoints || deliveryRoutePoints.length < 5) return;
      simProgress += 0.025;
      if (simProgress > 0.95) simProgress = 0.20;
      var pt = getPointAlongRoute(simProgress);
      smoothMoveRider(pt[0], pt[1], 2500);
    }, 3500);
  }

  // Fetch real street road driving route from Store to Customer
  fetchRealDrivingRoute(shop, cust, function(realPts) {
    deliveryRoutePoints = realPts;
    routeGlow.setLatLngs(realPts);
    routeLine.setLatLngs(realPts);
    if (!window.hasRealDriverGps && window.currentDeliveryState === 'pickedUp') {
      var midPt = getPointAlongRoute(0.40);
      smoothMoveRider(midPt[0], midPt[1], 800);
      runRouteSimulation();
    }
  });

  // Route: Rider -> Store (for accepted / heading to store phase - Primary Gradient!)
  var riderToStoreGlow = L.polyline([], { color: 'rgba(237, 57, 115, 0.28)', weight: 12, lineCap: 'round', lineJoin: 'round', className: 'route-primary-glow' });
  var riderToStoreLine = L.polyline([], { color: '#ED3973', weight: 5, lineCap: 'round', lineJoin: 'round', dashArray: '8, 8', className: 'route-primary-line' });

  // Persistent road route caching to eliminate flickering
  var currentRiderRoute = null;
  var lastRoutedRiderPos = null;
  var isFetchingRiderRoute = false;
  window.lastFittedState = initialState;

  function getDistanceMeters(p1, p2) {
    if (!p1 || !p2) return 999999;
    var lat1 = p1[0] * Math.PI / 180;
    var lat2 = p2[0] * Math.PI / 180;
    var dLat = (p2[0] - p1[0]) * Math.PI / 180;
    var dLon = (p2[1] - p1[1]) * Math.PI / 180;
    var a = Math.sin(dLat/2) * Math.sin(dLat/2) +
            Math.cos(lat1) * Math.cos(lat2) *
            Math.sin(dLon/2) * Math.sin(dLon/2);
    var c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
    return 6371000 * c;
  }

  function removeLayerSafe(l) {
    if (map.hasLayer(l)) map.removeLayer(l);
  }
  function addLayerSafe(l) {
    if (!map.hasLayer(l)) map.addLayer(l);
  }

  // Smooth Interpolation and Bearing Rotation for Rider
  var currentRiderLatLng = null;
  var riderAnimId = null;

  function calculateBearing(lat1, lon1, lat2, lon2) {
    var dLon = (lon2 - lon1) * Math.PI / 180;
    var y = Math.sin(dLon) * Math.cos(lat2 * Math.PI / 180);
    var x = Math.cos(lat1 * Math.PI / 180) * Math.sin(lat2 * Math.PI / 180) -
            Math.sin(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) * Math.cos(dLon);
    var brng = (Math.atan2(y, x) * 180 / Math.PI + 360) % 360;
    return brng;
  }

  function smoothMoveRider(targetLat, targetLng, duration, onComplete) {
    if (!currentRiderLatLng) {
      currentRiderLatLng = [targetLat, targetLng];
      riderMarker.setLatLng(currentRiderLatLng);
      if (onComplete) onComplete();
      return;
    }
    var startLat = currentRiderLatLng[0];
    var startLng = currentRiderLatLng[1];
    var deltaLat = targetLat - startLat;
    var deltaLng = targetLng - startLng;

    if (Math.abs(deltaLat) < 0.000005 && Math.abs(deltaLng) < 0.000005) {
      currentRiderLatLng = [targetLat, targetLng];
      riderMarker.setLatLng(currentRiderLatLng);
      if (onComplete) onComplete();
      return;
    }

    var bearing = calculateBearing(startLat, startLng, targetLat, targetLng);
    var iconEl = document.getElementById('rider-vehicle-icon');
    if (iconEl) {
      iconEl.style.transform = 'rotate(' + (bearing - 45) + 'deg)';
    }

    if (riderAnimId) cancelAnimationFrame(riderAnimId);
    var startTime = null;
    var dur = duration || 1400;

    function step(timestamp) {
      if (!startTime) startTime = timestamp;
      var elapsed = timestamp - startTime;
      var progress = Math.min(elapsed / dur, 1.0);
      var ease = progress < 0.5 ? 4 * progress * progress * progress : 1 - Math.pow(-2 * progress + 2, 3) / 2;
      var curLat = startLat + deltaLat * ease;
      var curLng = startLng + deltaLng * ease;
      currentRiderLatLng = [curLat, curLng];
      riderMarker.setLatLng(currentRiderLatLng);

      if (progress < 1.0) {
        riderAnimId = requestAnimationFrame(step);
      } else {
        if (onComplete) onComplete();
      }
    }
    riderAnimId = requestAnimationFrame(step);
  }

  window.currentDeliveryState = initialState;
  window.lastRiderLat = initRiderPos[0];
  window.lastRiderLng = initRiderPos[1];
  window.hasRealDriverGps = initHasRealGps;

  // Immediate Initial Layer Mount based on Resolved State
  if (initialState === 'searching') {
    radarMarker.addTo(map);
  } else if (initialState === 'accepted') {
    riderMarker.setLatLng(initRiderPos).addTo(map);
    currentRiderLatLng = initRiderPos;
    riderToStoreGlow.addTo(map);
    riderToStoreLine.addTo(map);
    lastRoutedRiderPos = [initRiderPos[0], initRiderPos[1]];
    fetchRealDrivingRoute(initRiderPos, shop, function(realPts) {
      if (realPts && realPts.length > 1) {
        currentRiderRoute = realPts;
        riderToStoreLine.setLatLngs(realPts);
        riderToStoreGlow.setLatLngs(realPts);
      }
    });
  } else if (initialState === 'pickedUp') {
    custMarker.addTo(map);
    routeGlow.addTo(map);
    routeLine.addTo(map);
    riderMarker.setLatLng(shop).addTo(map);
  } else if (initialState === 'delivered') {
    custMarker.addTo(map);
    riderMarker.setLatLng(cust).addTo(map);
  }

  window.recenterMap = function() {
    if (window.currentDeliveryState === 'accepted' && (currentRiderLatLng || (window.lastRiderLat && window.lastRiderLng))) {
      var pos = currentRiderLatLng || [window.lastRiderLat, window.lastRiderLng];
      map.fitBounds(L.latLngBounds([pos, shop]), {
        paddingTopLeft: [50, 100],
        paddingBottomRight: [50, 420],
        maxZoom: 16
      });
    } else if (window.currentDeliveryState === 'pickedUp') {
      map.fitBounds(L.latLngBounds(deliveryRoutePoints), {
        paddingTopLeft: [50, 100],
        paddingBottomRight: [50, 420]
      });
    } else if (window.currentDeliveryState === 'delivered') {
      map.setView(cust, 15, { animate: true });
    } else {
      map.setView(shopCenterOffset, 15, { animate: true });
    }
  };

  window.updateDeliveryState = function(state, rLat, rLng, hasRealGps) {
    window.currentDeliveryState = state;
    window.lastRiderLat = rLat;
    window.lastRiderLng = rLng;
    window.hasRealDriverGps = !!hasRealGps;
    if (simTimer && (state !== 'pickedUp' || window.hasRealDriverGps)) {
      clearInterval(simTimer);
      simTimer = null;
    }
    addLayerSafe(storeMarker);

    if (state === 'searching') {
      // 🔍 SEARCHING: ONLY STORE PIN + PULSING RADAR WAVE
      window.lastFittedState = 'searching';
      currentRiderRoute = null;
      lastRoutedRiderPos = null;
      addLayerSafe(radarMarker);
      removeLayerSafe(custMarker);
      removeLayerSafe(riderMarker);
      removeLayerSafe(routeLine);
      removeLayerSafe(routeGlow);
      removeLayerSafe(riderToStoreLine);
      removeLayerSafe(riderToStoreGlow);
      currentRiderLatLng = null;
      map.setView(shopCenterOffset, 15, { animate: true });

    } else if (state === 'accepted') {
      // 🛵 ACCEPTED: Rider heading to Store
      removeLayerSafe(radarMarker);
      removeLayerSafe(custMarker);
      removeLayerSafe(routeLine);
      removeLayerSafe(routeGlow);

      var riderPos = [rLat, rLng];
      addLayerSafe(riderMarker);
      addLayerSafe(riderToStoreGlow);
      addLayerSafe(riderToStoreLine);

      // Stable Road Route Logic: NEVER wipe out an established road route!
      if (!currentRiderRoute || currentRiderRoute.length < 2) {
        // Fallback straight line only if road route has not arrived yet
        var midRider = [(riderPos[0] + shop[0]) / 2, (riderPos[1] + shop[1]) / 2];
        var fallbackPts = [riderPos, midRider, shop];
        riderToStoreLine.setLatLngs(fallbackPts);
        riderToStoreGlow.setLatLngs(fallbackPts);
      } else {
        // Seamlessly update rider position at the head of existing street route
        currentRiderRoute[0] = riderPos;
        riderToStoreLine.setLatLngs(currentRiderRoute);
        riderToStoreGlow.setLatLngs(currentRiderRoute);
      }

      // Re-fetch road route ONLY if not yet fetched OR rider moved > 80m
      var distMoved = lastRoutedRiderPos ? getDistanceMeters(lastRoutedRiderPos, riderPos) : 999999;
      if ((!lastRoutedRiderPos || distMoved > 80) && !isFetchingRiderRoute) {
        isFetchingRiderRoute = true;
        lastRoutedRiderPos = [riderPos[0], riderPos[1]];
        fetchRealDrivingRoute(riderPos, shop, function(realRiderPts) {
          isFetchingRiderRoute = false;
          if (realRiderPts && realRiderPts.length > 1) {
            currentRiderRoute = realRiderPts;
            riderToStoreLine.setLatLngs(realRiderPts);
            riderToStoreGlow.setLatLngs(realRiderPts);
          }
        });
      }

      smoothMoveRider(rLat, rLng, 1400);

      // Fit map view bounds only once upon entering accepted state
      if (window.lastFittedState !== 'accepted') {
        window.lastFittedState = 'accepted';
        map.fitBounds(L.latLngBounds([riderPos, shop]), {
          paddingTopLeft: [50, 100],
          paddingBottomRight: [50, 420],
          maxZoom: 16
        });
      }

    } else if (state === 'arrived') {
      // 📍 ARRIVED: Rider docked at Store
      window.lastFittedState = 'arrived';
      currentRiderRoute = null;
      lastRoutedRiderPos = null;
      removeLayerSafe(radarMarker);
      removeLayerSafe(custMarker);
      removeLayerSafe(routeLine);
      removeLayerSafe(routeGlow);
      removeLayerSafe(riderToStoreLine);
      removeLayerSafe(riderToStoreGlow);

      addLayerSafe(riderMarker);
      smoothMoveRider(shop[0], shop[1], 1000);
      map.setView(shopCenterOffset, 16, { animate: true });

    } else if (state === 'pickedUp') {
      // 📦 PICKED UP: Store -> Customer Route with Rider en route
      removeLayerSafe(radarMarker);
      removeLayerSafe(riderToStoreLine);
      removeLayerSafe(riderToStoreGlow);

      addLayerSafe(custMarker);
      addLayerSafe(routeGlow);
      addLayerSafe(routeLine);
      addLayerSafe(riderMarker);

      var riderPos = [rLat, rLng];
      if (!window.hasRealDriverGps && deliveryRoutePoints && deliveryRoutePoints.length > 5) {
        // Snap rider DEAD-CENTER on the actual street route line!
        riderPos = getPointAlongRoute(simProgress || 0.40);
      }

      smoothMoveRider(riderPos[0], riderPos[1], 1400);

      if (window.lastFittedState !== 'pickedUp') {
        window.lastFittedState = 'pickedUp';
        map.fitBounds(L.latLngBounds(deliveryRoutePoints), {
          paddingTopLeft: [50, 100],
          paddingBottomRight: [50, 420]
        });
      }

      if (!window.hasRealDriverGps) {
        runRouteSimulation();
      }

    } else if (state === 'delivered') {
      // ✅ DELIVERED: Rider at Customer
      window.lastFittedState = 'delivered';
      removeLayerSafe(radarMarker);
      removeLayerSafe(riderToStoreLine);
      removeLayerSafe(riderToStoreGlow);

      addLayerSafe(custMarker);
      addLayerSafe(routeGlow);
      addLayerSafe(routeLine);
      addLayerSafe(riderMarker);

      smoothMoveRider(cust[0], cust[1], 1200);
      map.setView(cust, 15, { animate: true });

    } else if (state === 'rejected') {
      // ❌ REJECTED / CANCELLED
      window.lastFittedState = 'rejected';
      currentRiderRoute = null;
      lastRoutedRiderPos = null;
      removeLayerSafe(radarMarker);
      removeLayerSafe(riderMarker);
      removeLayerSafe(custMarker);
      removeLayerSafe(routeLine);
      removeLayerSafe(routeGlow);
      removeLayerSafe(riderToStoreLine);
      removeLayerSafe(riderToStoreGlow);
      currentRiderLatLng = null;
      map.setView(shopCenterOffset, 15, { animate: true });
    }
  };
</script>
</body>
</html>''';
  }

  void _subscribeToOrderUpdates() {
    _wsSub = WebSocketService().orderUpdates.listen((raw) {
      if (!mounted) return;

      // Extract order payload whether wrapped under 'order' or top-level
      final Map<String, dynamic> data = (raw['order'] is Map<String, dynamic>)
          ? raw['order'] as Map<String, dynamic>
          : (raw['order'] is Map)
              ? Map<String, dynamic>.from(raw['order'] as Map)
              : raw;

      final incomingId = data['id']?.toString() ??
          data['orderId']?.toString() ??
          raw['orderId']?.toString() ??
          raw['id']?.toString();

      if (incomingId == _currentOrder.id.toString()) {
        setState(() {
          final lalamoveStatus = (data['lalamoveStatus'] ?? raw['lalamoveStatus'])?.toString().toUpperCase();
          final isDriverCancelled = data['isDriverCancelled'] == true || raw['isDriverCancelled'] == true;
          final status = (data['status'] ?? raw['status'])?.toString().toUpperCase();

          // Real-time Driver Information update
          final dName = data['driverName'] ??
              data['deliveryRiderName'] ??
              (data['driver'] is Map ? data['driver']['name'] : null);
          if (dName != null && dName.toString().trim().isNotEmpty) {
            _driverName = dName.toString().trim();
          }

          final dPhone = data['driverPhone'] ??
              data['riderPhone'] ??
              data['deliveryPhoneNo'] ??
              (data['driver'] is Map ? data['driver']['phone'] : null);
          if (dPhone != null && dPhone.toString().trim().isNotEmpty) {
            _driverPhone = dPhone.toString().trim();
          }

          final dPlate = data['driverVehiclePlate'] ??
              data['riderVehicleNumber'] ??
              (data['driver'] is Map ? data['driver']['vehicleNo'] : null);
          if (dPlate != null && dPlate.toString().trim().isNotEmpty) {
            _driverPlate = dPlate.toString().trim();
          }

          final isLalamove = _currentOrder.isLalamoveDelivery ||
              (lalamoveStatus != null && lalamoveStatus.trim().isNotEmpty);

          if (isLalamove) {
            _driverAvatar = _resolveDriverAvatar();
          } else {
            final dAvatar = data['driverAvatar'] ??
                data['riderAvatar'] ??
                data['deliveryRiderAvatar'] ??
                (data['driver'] is Map ? data['driver']['profileUrl'] : null);
            if (dAvatar != null && dAvatar.toString().trim().isNotEmpty) {
              _driverAvatar = dAvatar.toString().trim();
            } else {
              _driverAvatar = _resolveDriverAvatar();
            }
          }

          final effectiveDriver = _driverName ?? _currentOrder.riderName;
          final isDriverAssigned = effectiveDriver != null &&
              effectiveDriver.trim().isNotEmpty &&
              effectiveDriver != 'Assigning Rider...';
          final hasTracking = _currentOrder.trackingUrl != null && _currentOrder.trackingUrl!.trim().isNotEmpty;

          if (isDriverCancelled || lalamoveStatus == 'REJECTED' || lalamoveStatus == 'CANCELLED') {
            _lifecycleState = LalamoveLifecycleState.rejected;
            _driverName = null;
            _driverPhone = null;
            _driverPlate = null;
          } else if (lalamoveStatus == 'COMPLETED' || status == 'DELIVERED') {
            _lifecycleState = LalamoveLifecycleState.delivered;
          } else if (lalamoveStatus == 'PICKED_UP' || status == 'PICKED_UP') {
            _lifecycleState = LalamoveLifecycleState.pickedUp;
          } else if (lalamoveStatus == 'ARRIVED_AT_STORE') {
            _lifecycleState = LalamoveLifecycleState.arrived;
          } else if (lalamoveStatus == 'ON_GOING' ||
              lalamoveStatus == 'ASSIGNED' ||
              lalamoveStatus == 'ACCEPTED' ||
              isDriverAssigned ||
              status == 'ON_THE_WAY' ||
              hasTracking) {
            _lifecycleState = LalamoveLifecycleState.accepted;
          } else if (lalamoveStatus == 'ASSIGNING_DRIVER') {
            if (_lifecycleState != LalamoveLifecycleState.accepted &&
                _lifecycleState != LalamoveLifecycleState.arrived &&
                _lifecycleState != LalamoveLifecycleState.pickedUp) {
              _lifecycleState = LalamoveLifecycleState.searching;
            }
          } else {
            // Retain active lifecycle state; NEVER downgrade accepted driver back to searching!
          }

          if (data['driverLat'] != null && data['driverLon'] != null) {
            _driverLat = double.tryParse(data['driverLat'].toString());
            _driverLng = double.tryParse(data['driverLon'].toString());
          } else if (data['riderLocation'] is Map) {
            final loc = data['riderLocation'] as Map;
            _driverLat = double.tryParse(loc['lat']?.toString() ?? '');
            _driverLng = double.tryParse(loc['lng']?.toString() ?? '');
          } else if (data['driverLocation'] is Map) {
            final loc = data['driverLocation'] as Map;
            _driverLat = double.tryParse(loc['lat']?.toString() ?? '');
            _driverLng = double.tryParse(loc['lng']?.toString() ?? '');
          }

          if (data['items'] != null || data['totalAmount'] != null) {
            try {
              _currentOrder = OrderModel.fromJson(data);
            } catch (_) {}
          }
        });

        _startSearchTimerIfNeeded();
        _syncMapStateToWebView();
        _syncRiderAvatarToWebView();
        _syncCustomerInfoToWebView();
      }
    });
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    _pollTimer?.cancel();
    _wsSub?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _callRider(String? phone) async {
    final raw = phone?.trim();
    if (raw == null || raw.isEmpty) {
      AppDialog.showToast(context, 'No phone number available', isError: true);
      return;
    }
    final cleanPhone = raw.replaceAll(RegExp(r'[^\d+]'), '');
    if (cleanPhone.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: cleanPhone);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (mounted) AppDialog.showToast(context, 'Could not open phone dialer', isError: true);
    }
  }

  void _recenterMap() {
    _webViewController?.runJavaScript("if (window.recenterMap) { window.recenterMap(); }");
  }

  Widget _buildFallbackCustomerAvatar({double size = 32}) {
    return Container(
      width: size,
      height: size,
      color: AppColors.primary.withValues(alpha: 0.12),
      child: Center(
        child: Icon(PhosphorIconsFill.user, size: size * 0.5, color: AppColors.primary),
      ),
    );
  }

  Widget _buildFallbackDriverIcon(bool isDark) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFFED3973).withValues(alpha: 0.18) : const Color(0xFFFDE8EF),
        shape: BoxShape.circle,
      ),
      child: const Center(
        child: Icon(
          PhosphorIconsFill.moped,
          color: Color(0xFFED3973),
          size: 26,
        ),
      ),
    );
  }

  Widget _buildGrabDriverCard({
    required bool isDark,
    required String driverName,
    required String? driverPhone,
  }) {
    final isLalamove = _currentOrder.isLalamoveDelivery ||
        (_currentOrder.lalamoveStatus != null && _currentOrder.lalamoveStatus!.trim().isNotEmpty);
    final cleanName = driverName.replaceAll('🛵', '').trim();
    final displayName = cleanName.isNotEmpty ? '$cleanName 🛵' : 'Lalamove Courier 🛵';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Driver Avatar: Soft Pink Circle with Pink Delivery Moped Icon & Amber Active Dot Badge
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFFED3973).withValues(alpha: 0.18) : const Color(0xFFFDE8EF),
                  shape: BoxShape.circle,
                ),
                child: ClipOval(
                  child: (!isLalamove && _driverAvatar != null && _driverAvatar!.trim().isNotEmpty)
                      ? Image.network(
                          _driverAvatar!,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildFallbackDriverIcon(isDark),
                        )
                      : _buildFallbackDriverIcon(isDark),
                ),
              ),
              Positioned(
                right: 1,
                bottom: 1,
                child: Container(
                  width: 11,
                  height: 11,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? const Color(0xFF0F172A) : Colors.white,
                      width: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),

          // Name with Scooter Emoji & Lalamove Delivery Subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: GoogleFonts.poppins(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(
                      PhosphorIconsRegular.motorcycle,
                      size: 14,
                      color: Color(0xFF64748B),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Lalamove Delivery',
                      style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Quick Action: Call Button
          GestureDetector(
            onTap: () => _callRider(driverPhone),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFEF4444), Color(0xFFF97316)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(PhosphorIconsFill.phoneCall, color: Colors.white, size: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _simulateSandboxStatus(String status) async {
    // 1. Snappy optimistic UI state update
    setState(() {
      _isSimulating = true;
      if (status == 'SEARCHING') {
        _lifecycleState = LalamoveLifecycleState.searching;
        _driverName = null;
        _driverPhone = null;
        _driverPlate = null;
        _searchSeconds = 0;
      } else if (status == 'ACCEPTED') {
        _lifecycleState = LalamoveLifecycleState.accepted;
        _driverName = 'TestDriver 45679';
        _driverPhone = '+6666100345679';
        _driverPlate = '1กข 8899';
      } else if (status == 'ARRIVED') {
        _lifecycleState = LalamoveLifecycleState.arrived;
        _driverName ??= 'TestDriver 45679';
        _driverPhone ??= '+6666100345679';
        _driverPlate ??= '1กข 8899';
      } else if (status == 'PICKED_UP') {
        _lifecycleState = LalamoveLifecycleState.pickedUp;
        _driverName ??= 'TestDriver 45679';
        _driverPhone ??= '+6666100345679';
        _driverPlate ??= '1กข 8899';
      } else if (status == 'COMPLETED') {
        _lifecycleState = LalamoveLifecycleState.delivered;
      } else if (status == 'REJECTED') {
        _lifecycleState = LalamoveLifecycleState.rejected;
        _driverName = null;
        _driverPhone = null;
        _driverPlate = null;
      }
    });
    _startSearchTimerIfNeeded();
    _syncMapStateToWebView();

    // 2. Call backend simulation endpoint
    try {
      final dio = Dio();
      final res = await dio.post(
        '${EnvConfig.apiBaseUrl}/webhooks/lalamove/simulate',
        data: {
          'orderId': _currentOrder.id,
          'status': status,
        },
      );
      if (res.data['success'] == true) {
        AppDialog.showToast(context, 'Simulated State: $status', isError: false);
      }
    } catch (_) {
      // Optimistic update already handled UI gracefully
    } finally {
      if (mounted) setState(() => _isSimulating = false);
    }
  }

  String _formatTimer(int totalSeconds) {
    final m = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // ── In Delivered State: Full-Screen Animated Celebratory View (No Map View) ──
    if (_lifecycleState == LalamoveLifecycleState.delivered) {
      return _buildDeliveredFullScreenView(isDark);
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          // ── Layer 1: REAL Map View (Full Screen Leaflet / OSM Tiles) ──
          Positioned.fill(
            child: _webViewController != null
                ? WebViewWidget(controller: _webViewController!)
                : const Center(child: CircularProgressIndicator(color: AppColors.primary)),
          ),

          if (_isWebViewLoading)
            const Positioned(
              top: 100,
              left: 0,
              right: 0,
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),

          // ── Layer 2: Top Floating Navigation Bar (Back Button Only) ──
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3))],
                ),
                child: Icon(PhosphorIconsBold.arrowLeft, color: isDark ? Colors.white : const Color(0xFF0F172A), size: 20),
              ),
            ),
          ),

          // ── Layer 3: Floating Controls & Grab-Style Bottom Sheet ──
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Floating Re-Center Map Action Button (Top-right above Bottom Sheet)
                Padding(
                  padding: const EdgeInsets.only(right: 16, bottom: 12),
                  child: GestureDetector(
                    onTap: _recenterMap,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.12),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(PhosphorIconsBold.crosshair, color: AppColors.primary, size: 21),
                      ),
                    ),
                  ),
                ),
                _buildGrabStyleBottomSheet(isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrabStyleBottomSheet(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        10,
        20,
        MediaQuery.paddingOf(context).bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Grab Drag Handle ──
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── Grab Ride Clean State View (No Bulky Stepper) ──
          if (_lifecycleState == LalamoveLifecycleState.searching)
            _buildGrabSearchingView(isDark)
          else if (_lifecycleState == LalamoveLifecycleState.accepted ||
              _lifecycleState == LalamoveLifecycleState.arrived)
            _buildGrabAssignedView(isDark)
          else if (_lifecycleState == LalamoveLifecycleState.pickedUp)
            _buildGrabDeliveringView(isDark)
          else if (_lifecycleState == LalamoveLifecycleState.delivered)
            const SizedBox.shrink()
          else
            _buildRejectedStateCard(),
        ],
      ),
    );
  }

  String _formatShortOrderNo(String fullCode) {
    if (fullCode.isEmpty) return '';
    if (fullCode.contains('-')) {
      final parts = fullCode.split('-');
      if (parts.isNotEmpty && parts.last.isNotEmpty) {
        return '#${parts.last}';
      }
    }
    if (fullCode.startsWith('#')) return fullCode;
    return '#$fullCode';
  }

  Widget _buildStoreLogoWidget() {
    if (_shopLogo != null && _shopLogo!.trim().isNotEmpty) {
      return Container(
        width: 32,
        height: 32,
        margin: const EdgeInsets.only(top: 2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: const Color(0xFFED3973).withValues(alpha: 0.35),
            width: 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(9),
          child: Image.network(
            _shopLogo!,
            width: 32,
            height: 32,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildFallbackLogo(),
          ),
        ),
      );
    }
    return _buildFallbackLogo();
  }

  Widget _buildFallbackLogo() {
    return Container(
      width: 32,
      height: 32,
      margin: const EdgeInsets.only(top: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFED3973).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Center(
        child: Icon(PhosphorIconsFill.storefront, size: 16, color: Color(0xFFED3973)),
      ),
    );
  }

  Widget _buildGrabRouteCard(bool isDark, String pickupCode, String custAddress) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          // ── Pickup Store Row with Real Shop Logo & Name (No order badge) ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStoreLogoWidget(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pickup Store',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      _shopName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      'Kitchen Prepared • Ready for pickup',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // ── Timeline Connector Line ──
          Row(
            children: [
              const SizedBox(width: 15),
              Container(
                width: 2,
                height: 18,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFFED3973).withValues(alpha: 0.5),
                      const Color(0xFF10B981).withValues(alpha: 0.5),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // ── Destination Dropoff Row ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                margin: const EdgeInsets.only(top: 1),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: Icon(PhosphorIconsFill.mapPin, size: 16, color: Color(0xFF10B981)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Destination Dropoff',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      custAddress,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGrabSearchingView(bool isDark) {
    final pickupCode = _currentOrder.lastOrderNo ?? '#${_currentOrder.id}';
    final custAddress = _currentOrder.deliveryAddressDetail.isNotEmpty
        ? _currentOrder.deliveryAddressDetail
        : (_currentOrder.customerAddress ?? 'Customer Destination');
    final customerName = _currentOrder.customerName.isNotEmpty
        ? _currentOrder.customerName
        : 'Customer';
    final customerAvatar = _currentOrder.customerAvatar;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1. Sleek Top Indeterminate Progress Line (No orange!)
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            minHeight: 2.5,
            backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFFCE7F3),
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
        const SizedBox(height: 12),

        // 2. Grab Header: Status Title + Elapsed Time (No Lalamove badge!)
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Finding nearby courier...',
              style: GoogleFonts.poppins(
                fontSize: 17.5,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 3),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF10B981),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'Elapsed: ${_formatTimer(_searchSeconds)} • Est: ~2 mins',
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 14),

        // 3. Grab-Style Route Timeline (No background container box)
        _buildGrabRouteCard(isDark, pickupCode, custAddress),

        // Subtle divider separating route from vehicle & fare
        Divider(
          height: 20,
          thickness: 0.7,
          color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
        ),

        // 4. Vehicle & Fee Row (No background box & NO orange color!)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  PhosphorIconsFill.moped,
                  size: 18,
                  color: isDark ? Colors.white70 : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Motorcycle Express',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const Spacer(),
              Text(
                '฿${_currentOrder.deliveryFee?.toStringAsFixed(2) ?? '130.00'}',
                style: GoogleFonts.poppins(
                  fontSize: 16.5,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 5. Cancel Search Button (ONLY section with a solid background container)
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: () => _confirmCancelSearch(),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark
                  ? const Color(0xFF334155)
                  : const Color(0xFFF1F5F9),
              foregroundColor: const Color(0xFFEF4444),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(
                  color: isDark ? const Color(0xFF475569) : const Color(0xFFE2E8F0),
                  width: 0.9,
                ),
              ),
            ),
            icon: const Icon(PhosphorIconsRegular.xCircle, size: 19, color: Color(0xFFEF4444)),
            label: Text(
              'Cancel Courier Search',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFEF4444),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGrabAssignedView(bool isDark) {
    final isArrived = _lifecycleState == LalamoveLifecycleState.arrived;
    final driverName = _driverName ?? _currentOrder.riderName ?? 'Lalamove Courier';
    final driverPhone = _driverPhone ?? _currentOrder.riderPhone;
    final vehiclePlate = _driverPlate ?? ((_currentOrder.vehicleNo != null && _currentOrder.vehicleNo!.trim().isNotEmpty)
        ? _currentOrder.vehicleNo!.trim()
        : 'Express');
    final pickupCode = _currentOrder.lastOrderNo ?? '#${_currentOrder.id}';
    final shortOrderNo = _formatShortOrderNo(pickupCode);
    final customerName = _currentOrder.customerName.isNotEmpty
        ? _currentOrder.customerName
        : 'Customer';
    final customerAvatar = _currentOrder.customerAvatar;
    final custAddress = _currentOrder.deliveryAddressDetail.isNotEmpty
        ? _currentOrder.deliveryAddressDetail
        : (_currentOrder.customerAddress ?? '');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1. Status Header & ETA Headline
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isArrived ? 'Courier has arrived!' : 'Courier is heading to store',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: isArrived
                          ? const Color(0xFF10B981)
                          : (isDark ? Colors.white : const Color(0xFF0F172A)),
                    ),
                  ),
                  const SizedBox(height: 2),
                  if (isArrived)
                    Text(
                      'Waiting at store pickup point',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF10B981),
                      ),
                    )
                  else
                    ShaderMask(
                      blendMode: BlendMode.srcIn,
                      shaderCallback: (bounds) => AppColors.primaryGradient.createShader(
                        Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                      ),
                      child: Text(
                        'Arriving in ~3 minutes',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5.5),
              decoration: BoxDecoration(
                gradient: isArrived
                    ? const LinearGradient(
                        colors: [Color(0xFF10B981), Color(0xFF059669)],
                      )
                    : AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: (isArrived ? const Color(0xFF10B981) : const Color(0xFFED3973))
                        .withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                isArrived ? 'At Store' : 'On The Way',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // 2. Grab-Style Driver Card (Clean White Style)
        _buildGrabDriverCard(
          isDark: isDark,
          driverName: driverName,
          driverPhone: driverPhone,
        ),
        const SizedBox(height: 12),

        // 3. Order & Customer Verification Card (Clean White Style)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isArrived
                  ? const Color(0xFFA7F3D0)
                  : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Order Number Row
              Row(
                children: [
                  Icon(
                    PhosphorIconsFill.receipt,
                    color: isArrived ? const Color(0xFF10B981) : AppColors.primary,
                    size: 19,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Order No: ',
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : const Color(0xFF64748B),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      shortOrderNo,
                      style: GoogleFonts.poppins(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: pickupCode));
                      AppDialog.showToast(context, 'Order No copied: $pickupCode');
                    },
                    child: const Icon(PhosphorIconsRegular.copy, size: 17, color: AppColors.primary),
                  ),
                ],
              ),
              Divider(
                height: 16,
                thickness: 0.7,
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
              // Customer Info Row (Avatar + Name + Dropoff summary)
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withValues(alpha: 0.12),
                    ),
                    child: ClipOval(
                      child: (customerAvatar != null && customerAvatar.trim().isNotEmpty)
                          ? Image.network(
                              customerAvatar,
                              width: 36,
                              height: 36,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _buildFallbackCustomerAvatar(size: 36),
                            )
                          : _buildFallbackCustomerAvatar(size: 36),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Customer: ',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                customerName,
                                style: GoogleFonts.poppins(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        if (custAddress.isNotEmpty)
                          Text(
                            custAddress,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: isDark ? Colors.white70 : const Color(0xFF475569),
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // 4. Action Button: Full Width Call Courier
        if (driverPhone != null && driverPhone.trim().isNotEmpty)
          SizedBox(
            width: double.infinity,
            height: 46,
            child: PrimaryGradientButton(
              onPressed: () => _callRider(driverPhone),
              borderRadius: 12,
              gradient: AppColors.primaryGradient,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(PhosphorIconsFill.phoneCall, color: Colors.white, size: 17),
                  const SizedBox(width: 8),
                  Text(
                    'Call Courier ($driverPhone)',
                    style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildGrabDeliveringView(bool isDark) {
    final driverName = _driverName ?? _currentOrder.riderName ?? 'Lalamove Courier';
    final driverPhone = _driverPhone ?? _currentOrder.riderPhone;
    final vehiclePlate = _driverPlate ?? ((_currentOrder.vehicleNo != null && _currentOrder.vehicleNo!.trim().isNotEmpty)
        ? _currentOrder.vehicleNo!.trim()
        : 'Express');
    final custAddress = _currentOrder.deliveryAddressDetail.isNotEmpty
        ? _currentOrder.deliveryAddressDetail
        : (_currentOrder.customerAddress ?? 'Customer Destination');
    final customerName = _currentOrder.customerName.isNotEmpty
        ? _currentOrder.customerName
        : 'Customer';
    final customerAvatar = _currentOrder.customerAvatar;
    final pickupCode = _currentOrder.lastOrderNo ?? '#${_currentOrder.id}';
    final shortOrderNo = _formatShortOrderNo(pickupCode);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1. Status Header & Headline
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order Out for Delivery',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  ShaderMask(
                    blendMode: BlendMode.srcIn,
                    shaderCallback: (bounds) => AppColors.primaryGradient.createShader(
                      Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                    ),
                    child: Text(
                      'Courier is en route to customer',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5.5),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFED3973).withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                'Delivering',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // 2. Grab-Style Driver Card (Moved to the TOP)
        _buildGrabDriverCard(
          isDark: isDark,
          driverName: driverName,
          driverPhone: driverPhone,
        ),
        const SizedBox(height: 12),

        // 3. Dropoff Destination & Order Card (Clean White Style)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order Number Row
              Row(
                children: [
                  const Icon(
                    PhosphorIconsFill.receipt,
                    color: AppColors.primary,
                    size: 19,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Order No: ',
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : const Color(0xFF64748B),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      shortOrderNo,
                      style: GoogleFonts.poppins(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: pickupCode));
                      AppDialog.showToast(context, 'Order No copied: $pickupCode');
                    },
                    child: const Icon(PhosphorIconsRegular.copy, size: 17, color: AppColors.primary),
                  ),
                ],
              ),
              Divider(
                height: 16,
                thickness: 0.7,
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
              // Dropoff Customer & Address Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withValues(alpha: 0.12),
                    ),
                    child: ClipOval(
                      child: (customerAvatar != null && customerAvatar.trim().isNotEmpty)
                          ? Image.network(
                              customerAvatar,
                              width: 36,
                              height: 36,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _buildFallbackCustomerAvatar(size: 36),
                            )
                          : _buildFallbackCustomerAvatar(size: 36),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(PhosphorIconsFill.mapPin, color: Color(0xFFE11D48), size: 16),
                            const SizedBox(width: 4),
                            Text(
                              'Dropoff: ',
                              style: GoogleFonts.poppins(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                customerName,
                                style: GoogleFonts.poppins(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          custAddress,
                          style: GoogleFonts.poppins(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white70 : const Color(0xFF475569),
                            height: 1.35,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
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

  void _confirmCancelSearch() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            const Icon(PhosphorIconsFill.warningCircle, color: Color(0xFFEF4444), size: 22),
            const SizedBox(width: 8),
            Text(
              'Stop Searching?',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to stop searching for a Lalamove rider? The courier search will be cancelled.',
          style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF64748B)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Keep Searching',
              style: GoogleFonts.poppins(color: const Color(0xFF64748B), fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _handleCancelSearch();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: Text(
              'Stop Search',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleCancelSearch() async {
    _searchTimer?.cancel();
    setState(() {
      _lifecycleState = LalamoveLifecycleState.rejected;
      _driverName = null;
      _driverPhone = null;
      _driverPlate = null;
    });

    _syncMapStateToWebView();

    try {
      // 1. Cancel real Lalamove order on server / real Lalamove API
      final res = await OrderService().cancelDelivery(_currentOrder.id.toString());
      if (res['success'] != true) {
        // Fallback simulation webhook if running in sandbox/simulation
        final dio = Dio();
        await dio.post(
          '${EnvConfig.apiBaseUrl}/webhooks/lalamove/simulate',
          data: {
            'orderId': _currentOrder.id,
            'status': 'REJECTED',
          },
        );
      }
    } catch (_) {
      try {
        final dio = Dio();
        await dio.post(
          '${EnvConfig.apiBaseUrl}/webhooks/lalamove/simulate',
          data: {
            'orderId': _currentOrder.id,
            'status': 'REJECTED',
          },
        );
      } catch (_) {}
    }

    if (mounted) {
      AppDialog.showToast(context, 'Courier search cancelled with Lalamove', isError: false);
    }
  }

  Future<void> _handleFindNewCourier() async {
    setState(() {
      _lifecycleState = LalamoveLifecycleState.searching;
      _driverName = null;
      _driverPhone = null;
      _driverPlate = null;
      _searchSeconds = 0;
    });
    _startSearchTimerIfNeeded();
    _syncMapStateToWebView();

    try {
      final res = await OrderService().dispatchWithProvider(_currentOrder.id.toString(), provider: 'LALAMOVE');
      if (res['success'] == true) {
        if (mounted) {
          AppDialog.showToast(context, 'Searching for Lalamove courier...', isError: false);
        }
      } else {
        _simulateSandboxStatus('SEARCHING');
      }
    } catch (_) {
      _simulateSandboxStatus('SEARCHING');
    }
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
        case 'go_to_orders_tab':
          return 'အော်ဒါစာရင်းသို့ သွားမည်';
        case 'delivered':
          return 'ပို့ဆောင်ပြီး';
        case 'order_delivered_successfully':
          return 'အော်ဒါ အောင်မြင်စွာ ပို့ဆောင်ပြီးပါပြီ!';
        case 'package_safely_delivered':
          return 'ဝယ်ယူသူထံ ပစ္စည်း အောင်မြင်စွာ ပို့ဆောင်ပြီးပါပြီ။';
        case 'delivered_just_now':
          return 'ယခုလေးတင် ပို့ဆောင်ပြီးစီးခဲ့သည်';
        case 'order_number':
          return 'အော်ဒါ နံပါတ်';
        case 'delivery_fee':
          return 'ပို့ဆောင်ခ';
        case 'delivered_to':
          return 'လက်ခံသူ -';
      }
    } else if (lang == 'th') {
      switch (key) {
        case 'go_to_orders_tab':
          return 'ไปที่รายการออเดอร์';
        case 'delivered':
          return 'จัดส่งแล้ว';
        case 'order_delivered_successfully':
          return 'จัดส่งออเดอร์เรียบร้อยแล้ว!';
        case 'package_safely_delivered':
          return 'จัดส่งพัสดุถึงลูกค้าอย่างปลอดภัยแล้ว';
        case 'delivered_just_now':
          return 'เพิ่งจัดส่งสำเร็จเมื่อสักครู่';
        case 'order_number':
          return 'หมายเลขคำสั่งซื้อ';
        case 'delivery_fee':
          return 'ค่าจัดส่ง';
        case 'delivered_to':
          return 'จัดส่งถึง';
      }
    }
    return fallback;
  }

  void _finishAndReturnToOrdersTab() {
    HapticFeedback.lightImpact();
    Navigator.of(context).popUntil((route) => route.isFirst);
    OrdersTabNavigation.returnToOrdersTab?.call('DELIVERED');
  }

  // ══════════════════════════════════════════════════════════════════════════
  // FULL-SCREEN CELEBRATORY DELIVERED VIEW (NO MAP VIEW, PRIMARY GRADIENT THEME)
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildDeliveredFullScreenView(bool isDark) {
    final pickupCode = _currentOrder.lastOrderNo ?? '#${_currentOrder.id}';
    final shortOrderNo = _formatShortOrderNo(pickupCode);
    final customerName = _currentOrder.customerName.isNotEmpty
        ? _currentOrder.customerName
        : 'Customer';
    final customerAvatar = _currentOrder.customerAvatar;
    final custAddress = _currentOrder.deliveryAddressDetail.isNotEmpty
        ? _currentOrder.deliveryAddressDetail
        : (_currentOrder.customerAddress ?? '');
    final driverName = _driverName ?? _currentOrder.riderName ?? 'Lalamove Courier';
    final cleanDriverName = driverName.replaceAll('🛵', '').trim();
    final vehiclePlate = _driverPlate ?? ((_currentOrder.vehicleNo != null && _currentOrder.vehicleNo!.trim().isNotEmpty)
        ? _currentOrder.vehicleNo!.trim()
        : 'Express');
    final deliveryFee = _currentOrder.deliveryFee?.toStringAsFixed(2) ?? '130.00';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _finishAndReturnToOrdersTab();
      },
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        body: SafeArea(
          child: Column(
            children: [
              // Top Minimalist App Bar with Close Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: _finishAndReturnToOrdersTab,
                      child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        PhosphorIconsBold.x,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        size: 20,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFED3973).withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFED3973).withValues(alpha: 0.25),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: Color(0xFFED3973),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _safeTranslate('delivered', 'Delivered'),
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFED3973),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                child: Column(
                  children: [
                    const SizedBox(height: 10),

                    // 1. Beautiful Animated Success Hero Icon in Primary Gradient Theme
                    const _AnimatedDeliverySuccessIcon(),

                    const SizedBox(height: 22),

                    // 2. Headline & Subtitle with Primary Gradient Accent
                    ShaderMask(
                      blendMode: BlendMode.srcIn,
                      shaderCallback: (bounds) => AppColors.primaryGradient.createShader(
                        Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                      ),
                      child: Text(
                        _safeTranslate('order_delivered_successfully', 'Order Delivered Successfully!'),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _safeTranslate('package_safely_delivered', 'Package was safely delivered to customer.'),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white70 : const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Delivery Verified Timestamp Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            PhosphorIconsRegular.checkCircle,
                            size: 15,
                            color: Color(0xFFED3973),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _safeTranslate('delivered_just_now', 'Delivered Just Now'),
                            style: GoogleFonts.poppins(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // 3. Receipt & Delivery Verification Card
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Order Header Row
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(7),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFED3973).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  PhosphorIconsFill.receipt,
                                  color: Color(0xFFED3973),
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _safeTranslate('order_number', 'Order Number'),
                                    style: GoogleFonts.poppins(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF64748B),
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Text(
                                        shortOrderNo,
                                        style: GoogleFonts.poppins(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      GestureDetector(
                                        onTap: () {
                                          Clipboard.setData(ClipboardData(text: pickupCode));
                                          AppDialog.showToast(context, 'Order No copied: $pickupCode');
                                        },
                                        child: const Icon(
                                          PhosphorIconsRegular.copy,
                                          size: 15,
                                          color: Color(0xFFED3973),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const Spacer(),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    _safeTranslate('delivery_fee', 'Delivery Fee'),
                                    style: GoogleFonts.poppins(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF64748B),
                                    ),
                                  ),
                                  ShaderMask(
                                    blendMode: BlendMode.srcIn,
                                    shaderCallback: (bounds) => AppColors.primaryGradient.createShader(
                                      Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                                    ),
                                    child: Text(
                                      '฿$deliveryFee',
                                      style: GoogleFonts.poppins(
                                        fontSize: 16.5,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),

                          Divider(
                            height: 24,
                            thickness: 0.7,
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                          ),

                          // Customer Destination Row
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFFED3973).withValues(alpha: 0.12),
                                ),
                                child: ClipOval(
                                  child: (customerAvatar != null && customerAvatar.trim().isNotEmpty)
                                      ? Image.network(
                                          customerAvatar,
                                          width: 38,
                                          height: 38,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => const Center(
                                            child: Icon(
                                              PhosphorIconsFill.user,
                                              size: 18,
                                              color: Color(0xFFED3973),
                                            ),
                                          ),
                                        )
                                      : const Center(
                                          child: Icon(
                                            PhosphorIconsFill.user,
                                            size: 18,
                                            color: Color(0xFFED3973),
                                          ),
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
                                        const Icon(
                                          PhosphorIconsFill.mapPin,
                                          color: Color(0xFFED3973),
                                          size: 14,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${_safeTranslate('delivered_to', 'Delivered to')} $customerName',
                                          style: GoogleFonts.poppins(
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w700,
                                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      custAddress.isNotEmpty ? custAddress : 'Destination address verified',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w400,
                                        height: 1.35,
                                        color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          Divider(
                            height: 24,
                            thickness: 0.7,
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                          ),

                          // Courier Row with Pink Moped Courier Avatar
                          Row(
                            children: [
                              _buildFallbackDriverIcon(isDark),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      cleanDriverName.isNotEmpty ? '$cleanDriverName 🛵' : 'Lalamove Courier 🛵',
                                      style: GoogleFonts.poppins(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w700,
                                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        const Icon(
                                          PhosphorIconsRegular.motorcycle,
                                          size: 13,
                                          color: Color(0xFF64748B),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Lalamove Express Delivery ($vehiclePlate)',
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            color: const Color(0xFF64748B),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    if (widget.isSandbox) ...[
                      const SizedBox(height: 16),
                      TextButton.icon(
                        onPressed: () => _simulateSandboxStatus('SEARCHING'),
                        icon: const Icon(PhosphorIconsRegular.arrowsClockwise, size: 14, color: AppColors.primary),
                        label: Text(
                          'Sandbox: Reset to Searching',
                          style: GoogleFonts.poppins(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // Pinned Bottom Action Button with Adjusted Modern UI
            Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                10,
                20,
                MediaQuery.of(context).padding.bottom + 16,
              ),
              child: _buildAdjustedDoneButton(context),
            ),
          ],
        ),
      ),
    ),
  );
  }

  // ── ADJUSTED GO TO ORDERS TAB BUTTON UI ──
  Widget _buildAdjustedDoneButton(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 54,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFED3973).withValues(alpha: 0.38),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _finishAndReturnToOrdersTab,
          borderRadius: BorderRadius.circular(18),
          splashColor: Colors.white24,
          highlightColor: Colors.white10,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    PhosphorIconsBold.receipt,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                _safeTranslate('go_to_orders_tab', 'Go to Orders Tab'),
                style: GoogleFonts.poppins(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                PhosphorIconsBold.arrowRight,
                color: Colors.white70,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRejectedStateCard() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF2F2),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFFEE2E2)),
          ),
          child: Row(
            children: [
              const Icon(PhosphorIconsFill.xCircle, color: Color(0xFFEF4444), size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Courier search cancelled',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF991B1B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Search stopped. You can find a new courier or deliver via shop rider.',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: const Color(0xFFB91C1C),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _handleFindNewCourier(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                icon: const Icon(PhosphorIconsFill.arrowsClockwise, size: 16),
                label: const Text('Find New Courier', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                icon: const Icon(PhosphorIconsFill.moped, size: 16, color: Color(0xFF0F172A)),
                label: const Text('Shop Driver', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// ANIMATED SUCCESS ICON IN PRIMARY GRADIENT THEME (NO GREEN THEME)
// ══════════════════════════════════════════════════════════════════════════
class _AnimatedDeliverySuccessIcon extends StatefulWidget {
  const _AnimatedDeliverySuccessIcon();

  @override
  State<_AnimatedDeliverySuccessIcon> createState() => _AnimatedDeliverySuccessIconState();
}

class _AnimatedDeliverySuccessIconState extends State<_AnimatedDeliverySuccessIcon>
    with TickerProviderStateMixin {
  late AnimationController _entranceController;
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _ripple1Animation;
  late Animation<double> _ripple2Animation;

  @override
  void initState() {
    super.initState();
    // 1. Spring-like bounce entrance
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: Curves.elasticOut,
      ),
    );

    // 2. Continuous breathing & radiating ripple
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();

    _pulseAnimation = Tween<double>(begin: 0.96, end: 1.04).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    _ripple1Animation = Tween<double>(begin: 0.7, end: 1.45).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: const Interval(0.0, 0.85, curve: Curves.easeOut),
      ),
    );

    _ripple2Animation = Tween<double>(begin: 0.7, end: 1.6).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
      ),
    );

    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      height: 180,
      child: AnimatedBuilder(
        animation: Listenable.merge([_entranceController, _pulseController]),
        builder: (context, child) {
          final entranceScale = _scaleAnimation.value;
          final pulse = _pulseAnimation.value;
          final ripple1Progress = _ripple1Animation.value;
          final ripple2Progress = _ripple2Animation.value;
          final ripple1Opacity = ((1.45 - ripple1Progress) / (1.45 - 0.7)).clamp(0.0, 1.0) * 0.45;
          final ripple2Opacity = ((1.6 - ripple2Progress) / (1.6 - 0.7)).clamp(0.0, 1.0) * 0.30;

          return Stack(
            alignment: Alignment.center,
            children: [
              // Outer Ripple 2 (Primary Gradient Hue)
              Transform.scale(
                scale: entranceScale * ripple2Progress,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFED3973).withValues(alpha: ripple2Opacity * 0.4),
                    border: Border.all(
                      color: const Color(0xFFED3973).withValues(alpha: ripple2Opacity),
                      width: 1.5,
                    ),
                  ),
                ),
              ),

              // Outer Ripple 1 (Amber / Gold Accent Hue)
              Transform.scale(
                scale: entranceScale * ripple1Progress,
                child: Container(
                  width: 95,
                  height: 95,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFED3973).withValues(alpha: ripple1Opacity * 0.5),
                    border: Border.all(
                      color: const Color(0xFFEFA240).withValues(alpha: ripple1Opacity),
                      width: 2,
                    ),
                  ),
                ),
              ),

              // Soft Glow Backdrop
              Transform.scale(
                scale: entranceScale * pulse,
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFED3973).withValues(alpha: 0.18),
                  ),
                ),
              ),

              // Floating Sparkle Chips (Primary Gradient Accent)
              Positioned(
                top: 18,
                right: 32,
                child: Transform.scale(
                  scale: entranceScale * (pulse * 0.9),
                  child: const Icon(
                    PhosphorIconsFill.sparkle,
                    color: Color(0xFFEFA240),
                    size: 20,
                  ),
                ),
              ),
              Positioned(
                bottom: 24,
                left: 28,
                child: Transform.scale(
                  scale: entranceScale * (1.1 / pulse),
                  child: const Icon(
                    PhosphorIconsFill.sparkle,
                    color: Color(0xFFED3973),
                    size: 16,
                  ),
                ),
              ),
              Positioned(
                top: 36,
                left: 36,
                child: Transform.scale(
                  scale: entranceScale,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEFA240),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 32,
                right: 36,
                child: Transform.scale(
                  scale: entranceScale,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFFED3973),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),

              // Center Primary Gradient Success Checkmark Circle
              Transform.scale(
                scale: entranceScale * pulse,
                child: Container(
                  width: 86,
                  height: 86,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.primaryGradient,
                    border: Border.all(
                      color: Colors.white,
                      width: 4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFED3973).withValues(alpha: 0.48),
                        blurRadius: 26,
                        spreadRadius: 2,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      PhosphorIconsBold.check,
                      color: Colors.white,
                      size: 42,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
