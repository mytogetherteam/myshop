import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'package:my_shop/core/network/websocket_service.dart';
import 'package:my_shop/core/utils/app_colors.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:my_shop/core/presentation/widgets/app_dialog.dart';
import 'package:my_shop/features/profile/data/models/shop_profile_model.dart';
import 'package:my_shop/features/profile/data/services/profile_service.dart';
import 'package:my_shop/features/reports/data/services/report_service.dart';
import 'package:my_shop/features/orders/data/models/order_model.dart';
import 'package:my_shop/features/orders/data/services/order_service.dart';
import 'package:my_shop/features/orders/presentation/screens/focus_mode_order_list_screen.dart';
import 'package:my_shop/core/localization/app_localizations.dart';
import 'package:my_shop/core/presentation/widgets/global_modal.dart';
import 'package:my_shop/features/profile/presentation/widgets/language_selector_sheet.dart';

/// Stage metadata model for the Kitchen Order Dashboard.
class _DashboardStage {
  final String key;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color primaryColor;
  final List<Color> gradientColors;

  const _DashboardStage({
    required this.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.primaryColor,
    required this.gradientColors,
  });
}

/// Kitchen Focus Mode Screen (Dashboard Style).
/// Professional, live POS/Kitchen display:
/// - Pure dashboard overview with all states visible directly on screen
/// - No top tab/scroll row; no order cards on this main page
/// - Tapping any state section navigates to the list view styled identically to the Order Page
/// - Live WebSocket sync, screen wake-lock, and sound alerts
class OrderFocusModeScreen extends StatefulWidget {
  final bool isEmbedded;
  const OrderFocusModeScreen({super.key, this.isEmbedded = false});

  @override
  State<OrderFocusModeScreen> createState() => OrderFocusModeScreenState();
}

class OrderFocusModeScreenState extends State<OrderFocusModeScreen> {
  final OrderService _orderService = OrderService();
  final ProfileService _profileService = ProfileService();
  final ReportService _reportService = ReportService();

  ShopProfileModel? _shopProfile;

  // Delivery toggle status
  bool _deliveryEnabled = true;
  bool _isTogglingDelivery = false;

  // Today's counts for completed and cancelled orders
  int _todayCompletedCount = 0;
  int _todayCanceledCount = 0;

  final Map<String, int> _stageCounts = {
    'ALL': 0,
    'NEW': 0,
    'PAYMENT': 0,
    'PREPARING': 0,
    'READY_FOR_PICKUP': 0,
    'DELIVERING': 0,
    'DELIVERED': 0,
    'CANCELED': 0,
  };

  bool _isRefreshing = false;

  // Audio, Vibration & Keep-Awake
  AudioPlayer? _audioPlayer;
  bool _isSoundEnabled = true;
  StreamSubscription? _socketSubscription;
  Timer? _tickerTimer;
  DateTime _currentTime = DateTime.now();

  // New incoming order banner alert
  OrderModel? _latestAlertOrder;
  Timer? _alertDismissTimer;

  // Dashboard Stages Configuration (5 active order states)
  static const List<_DashboardStage> _stages = [
    _DashboardStage(
      key: 'NEW',
      title: 'New Orders',
      subtitle: 'To Accept',
      icon: PhosphorIconsFill.bellRinging,
      primaryColor: Color(0xFFEF4444),
      gradientColors: [Color(0xFFEF4444), Color(0xFFDC2626)],
    ),
    _DashboardStage(
      key: 'PAYMENT',
      title: 'Payment',
      subtitle: 'Direct / Auto',
      icon: PhosphorIconsFill.creditCard,
      primaryColor: Color(0xFFF59E0B),
      gradientColors: [Color(0xFFF59E0B), Color(0xFFD97706)],
    ),
    _DashboardStage(
      key: 'PREPARING',
      title: 'In Kitchen',
      subtitle: 'Cooking',
      icon: PhosphorIconsFill.cookingPot,
      primaryColor: Color(0xFFF97316),
      gradientColors: [Color(0xFFF97316), Color(0xFFEA580C)],
    ),
    _DashboardStage(
      key: 'READY_FOR_PICKUP',
      title: 'Ready',
      subtitle: 'Bagged & Ready',
      icon: PhosphorIconsFill.forkKnife,
      primaryColor: Color(0xFF10B981),
      gradientColors: [Color(0xFF10B981), Color(0xFF059669)],
    ),
    _DashboardStage(
      key: 'DELIVERING',
      title: 'On The Way',
      subtitle: 'Rider Dispatched',
      icon: PhosphorIconsFill.moped,
      primaryColor: Color(0xFF06B6D4),
      gradientColors: [Color(0xFF06B6D4), Color(0xFF0284C7)],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initScreenAwakeAndAudio();
    _setupWebSocketListener();
    _startClockTicker();
    _fetchStageCounts();
    _loadShopProfile();
  }

  Future<void> _loadShopProfile() async {
    try {
      final profile = await _profileService.getShopProfile();
      if (mounted && profile != null) {
        if (!profile.isVerified) {
          if (!widget.isEmbedded) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Focus Mode is only available for verified shops.'),
                backgroundColor: Colors.red,
              ),
            );
            Navigator.of(context).pop();
            return;
          }
        }
        setState(() {
          _shopProfile = profile;
          _deliveryEnabled = profile.deliveryEnabled;
        });
      }
    } catch (_) {}
  }

  Future<void> _toggleDelivery(bool nextState) async {
    if (_isTogglingDelivery) return;
    setState(() => _isTogglingDelivery = true);

    try {
      final success = await _profileService.toggleDeliveryStatus(nextState);
      if (mounted) {
        if (success) {
          setState(() {
            _deliveryEnabled = nextState;
            _isTogglingDelivery = false;
          });

          try {
            if (nextState) {
              FlutterBackgroundService().startService();
            } else {
              FlutterBackgroundService().invoke('stopService');
            }
          } catch (_) {}

          AppDialog.showToast(
            context,
            nextState ? 'Delivery & Pick up enabled' : 'Delivery & Pick up paused',
          );

          _loadShopProfile();
        } else {
          setState(() => _isTogglingDelivery = false);
          AppDialog.showToast(
            context,
            'Failed to update delivery status',
            isError: true,
          );
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isTogglingDelivery = false);
        AppDialog.showToast(
          context,
          'Failed to update delivery status',
          isError: true,
        );
      }
    }
  }

  Future<void> _initScreenAwakeAndAudio() async {
    try {
      await WakelockPlus.enable();
    } catch (_) {}

    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _isSoundEnabled = prefs.getBool('focus_mode_sound_enabled') ?? true;
      });
    }
  }

  void _startClockTicker() {
    _tickerTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });
  }

  void _setupWebSocketListener() {
    _socketSubscription = WebSocketService().orderUpdates.listen((event) {
      if (!mounted) return;
      if (event['order'] != null) {
        try {
          final order = OrderModel.fromJson(event['order']);
          _handleLiveOrderUpdate(order);
        } catch (_) {}
      }
    });
  }

  void _handleLiveOrderUpdate(OrderModel order) {
    final status = order.status.toUpperCase();
    if (status == 'PENDING' || status == 'NEW') {
      _playNewOrderAlert(order);
    }
    _fetchStageCounts();
  }

  Future<void> _playNewOrderAlert(OrderModel order) async {
    setState(() {
      _latestAlertOrder = order;
    });

    _alertDismissTimer?.cancel();
    _alertDismissTimer = Timer(const Duration(seconds: 10), () {
      if (mounted) {
        setState(() => _latestAlertOrder = null);
      }
    });

    if (!_isSoundEnabled) return;

    try {
      _audioPlayer?.stop();
      _audioPlayer?.dispose();
      _audioPlayer = AudioPlayer();
      await _audioPlayer?.play(AssetSource('alert/alert.mp3'));
      Vibration.vibrate(duration: 600);
    } catch (_) {}
  }

  Future<void> _toggleSound() async {
    final nextState = !_isSoundEnabled;
    setState(() => _isSoundEnabled = nextState);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('focus_mode_sound_enabled', nextState);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            nextState ? '🔔 Kitchen Sound Alerts ON' : '🔕 Kitchen Sound Muted',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _fetchStageCounts() async {
    if (!mounted) return;
    setState(() => _isRefreshing = true);

    // Fetch Today's Completed and Cancelled counts for footer
    _fetchTodayCompletedAndCanceledCounts();

    try {
      final counts = await _orderService.getOrderTabCounts();
      if (counts != null && mounted) {
        int activeTotal = (counts['NEW'] ?? 0) +
            (counts['PAYMENT'] ?? 0) +
            (counts['PREPARING'] ?? 0) +
            (counts['READY_FOR_PICKUP'] ?? 0) +
            (counts['DELIVERING'] ?? 0);

        setState(() {
          counts.forEach((key, val) {
            if (_stageCounts.containsKey(key)) {
              _stageCounts[key] = val;
            }
          });
          _stageCounts['ALL'] = activeTotal;
          _isRefreshing = false;
        });
        return;
      }
    } catch (_) {}

    // Fallback: batch fetch
    const tabs = [
      'NEW',
      'PAYMENT',
      'PREPARING',
      'READY_FOR_PICKUP',
      'DELIVERING',
      'DELIVERED',
      'CANCELED',
    ];

    try {
      final results = await Future.wait(
        tabs.map((tab) => _orderService.getOrders(tab: tab, page: 1, size: 1)),
      );

      if (mounted) {
        setState(() {
          int activeTotal = 0;
          for (int i = 0; i < tabs.length; i++) {
            final res = results[i];
            if (res != null) {
              final count = res.total;
              _stageCounts[tabs[i]] = count;
              if (['NEW', 'PAYMENT', 'PREPARING', 'READY_FOR_PICKUP', 'DELIVERING'].contains(tabs[i])) {
                activeTotal += count;
              }
            }
          }
          _stageCounts['ALL'] = activeTotal;
          _isRefreshing = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  /// Fetches the count of Completed and Cancelled orders specifically for Today.
  Future<void> _fetchTodayCompletedAndCanceledCounts() async {
    try {
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final summary = await _reportService.getSummary(start: todayStart, end: now);
      if (summary != null && mounted) {
        setState(() {
          _todayCompletedCount = summary.orders;
          _todayCanceledCount = summary.cancelledCount;
        });
        return;
      }
    } catch (_) {}

    // Fallback: Query recent delivered and canceled orders and count only today's
    try {
      final now = DateTime.now();
      final results = await Future.wait([
        _orderService.getOrders(tab: 'DELIVERED', page: 1, size: 50),
        _orderService.getOrders(tab: 'CANCELED', page: 1, size: 50),
      ]);

      if (mounted) {
        final deliveredOrders = results[0]?.orders ?? [];
        final canceledOrders = results[1]?.orders ?? [];

        int todayDelivered = deliveredOrders.where((o) {
          final dt = o.updatedAt.toLocal();
          return dt.year == now.year && dt.month == now.month && dt.day == now.day;
        }).length;

        int todayCanceled = canceledOrders.where((o) {
          final dt = o.updatedAt.toLocal();
          return dt.year == now.year && dt.month == now.month && dt.day == now.day;
        }).length;

        setState(() {
          _todayCompletedCount = todayDelivered;
          _todayCanceledCount = todayCanceled;
        });
      }
    } catch (_) {}
  }

  /// Open the order list view for the tapped stage with identical style to Order Page
  Future<void> _openStageOrders(String stageKey) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FocusModeOrderListScreen(
          initialStage: stageKey,
          isSoundEnabled: _isSoundEnabled,
          onSoundToggle: _toggleSound,
        ),
      ),
    );

    // Refresh stage counts when returning to the dashboard
    if (mounted) {
      _fetchStageCounts();
    }
  }

  void refresh() {
    _fetchStageCounts();
  }

  void refreshAll() {
    _fetchStageCounts();
  }

  void syncCounts() {
    _fetchStageCounts();
  }

  void switchToStatus(String status) {
    _fetchStageCounts();
    final upper = status.toUpperCase();
    String? stage;
    if (upper == 'PENDING' || upper == 'NEW' || upper == 'REVISED') {
      stage = 'NEW';
    } else if (['PAYMENT_SLIP_REQUESTED', 'AWAITING_APPROVAL', 'PAYMENT_VERIFIED', 'PAYMENT'].contains(upper)) {
      stage = 'PAYMENT';
    } else if (upper == 'COOKING' || upper == 'PREPARING') {
      stage = 'PREPARING';
    } else if (upper == 'READY_FOR_PICKUP' || upper == 'READY') {
      stage = 'READY_FOR_PICKUP';
    } else if (upper == 'ON_THE_WAY' || upper == 'DELIVERING') {
      stage = 'DELIVERING';
    } else if (upper == 'DELIVERED') {
      stage = 'DELIVERED';
    } else if (upper == 'CANCELED' || upper == 'CANCELLED') {
      stage = 'CANCELED';
    }
    if (stage != null && mounted) {
      _openStageOrders(stage);
    }
  }

  void _exitFocusMode() {
    try {
      WakelockPlus.disable();
    } catch (_) {}
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    try {
      WakelockPlus.disable();
    } catch (_) {}
    _socketSubscription?.cancel();
    _tickerTimer?.cancel();
    _alertDismissTimer?.cancel();
    _audioPlayer?.dispose();
    super.dispose();
  }

  // ──────────────────────────────────────────────
  // UI Builder
  // ──────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: themeBg,
        body: Column(
          children: [
            // 1. Sleek Kitchen Command Bar (extends behind transparent status bar)
            _buildKitchenTopBar(),

            // 2. High-urgency incoming alert banner
            if (_latestAlertOrder != null) _buildAlertBanner(),

            // 3. Main Dashboard Body with Bottom Float Bar (No top scroll row, No order cards list)
            Expanded(
              child: SafeArea(
                top: false,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isTablet = constraints.maxWidth >= 600;
                    final hasFooterOrders = (_todayCompletedCount + _todayCanceledCount) > 0;
                    return Stack(
                      children: [
                        // Scrollable Dashboard Content
                        Positioned.fill(
                          child: RefreshIndicator(
                            color: AppColors.primary,
                            onRefresh: _fetchStageCounts,
                            child: _buildDashboardContent(
                              isTablet,
                              isDark,
                              hasFooterOrders: hasFooterOrders,
                            ),
                          ),
                        ),

                        // Bottom Floating Pill: Completed & Cancelled orders (Hidden when no orders)
                        if (hasFooterOrders)
                          Positioned(
                            left: 16,
                            right: 16,
                            bottom: 12,
                            child: Center(
                              child: _buildFloatingBottomBar(isDark),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────
  // 1. Header Command Bar
  // ──────────────────────────────────────────────

  Widget _buildKitchenTopBar() {
    final clockFormat = DateFormat('hh:mm a');
    final dateFormat = DateFormat('EEE, d MMM');

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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              // Left: App Logo + Clock & Date
              Expanded(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Image.asset(
                        'assets/images/app_logo2.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          clockFormat.format(_currentTime),
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.3,
                          ),
                        ),
                        Text(
                          dateFormat.format(_currentTime),
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Right: Action Buttons (Awake badge removed)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Refresh / Sync Button
                  _buildTopBtn(
                    tooltip: 'Sync Dashboard Counts',
                    onTap: _fetchStageCounts,
                    icon: _isRefreshing
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const PhosphorIcon(
                            PhosphorIconsRegular.arrowsClockwise,
                            color: Colors.white,
                            size: 17,
                          ),
                  ),
                  const SizedBox(width: 6),

                  // Sound Toggle Button
                  _buildTopBtn(
                    tooltip: _isSoundEnabled ? 'Mute Kitchen Sound' : 'Enable Kitchen Sound',
                    onTap: _toggleSound,
                    icon: PhosphorIcon(
                      _isSoundEnabled ? PhosphorIconsFill.speakerHigh : PhosphorIconsFill.speakerSlash,
                      color: Colors.white,
                      size: 17,
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
                  if (!widget.isEmbedded) ...[
                    const SizedBox(width: 8),

                    // Exit / Close Button (Cross icon only, professional style)
                    Tooltip(
                      message: 'Exit Focus Mode',
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: _exitFocusMode,
                          child: Container(
                            width: 32,
                            height: 32,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: PhosphorIcon(
                              PhosphorIconsBold.x,
                              size: 14,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
        ],
      ),
    ),
  ),
);
}

  Widget _buildTopBtn({
    required Widget icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.22),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
            ),
            child: icon,
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────
  // 2. Incoming Alert Banner
  // ──────────────────────────────────────────────

  Widget _buildAlertBanner() {
    final order = _latestAlertOrder!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFEF4444), Color(0xFFF97316)],
        ),
      ),
      child: Row(
        children: [
          const PhosphorIcon(PhosphorIconsFill.bellRinging, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'NEW ORDER #${order.lastOrderNo} ARRIVED! (${order.items.length} items)',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          InkWell(
            onTap: () {
              setState(() => _latestAlertOrder = null);
              _openStageOrders('NEW');
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'VIEW',
                style: GoogleFonts.poppins(
                  color: const Color(0xFFEF4444),
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: () => setState(() => _latestAlertOrder = null),
            child: const PhosphorIcon(PhosphorIconsRegular.x, color: Colors.white, size: 16),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────
  // 3. Full-Screen Dashboard Grid (No Scroll Row, No Order Cards)
  // ──────────────────────────────────────────────

  Widget _buildDashboardContent(
    bool isTablet,
    bool isDark, {
    required bool hasFooterOrders,
  }) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(14, 12, 14, hasFooterOrders ? 76 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Shop Identity Header (Shop Logo + Name + Live Status + Delivery ON/OFF)
          _buildShopIdentityHeader(isDark),
          const SizedBox(height: 14),

          // 2. Dashboard Grid showing all states directly on the screen
          _buildDashboardGrid(isTablet, isDark),
        ],
      ),
    );
  }

  String _currentLang() {
    return LocalizationService.instance.localeNotifier.value.languageCode;
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

  String _getStageSubtitle(String key) {
    final lang = _currentLang();
    if (lang == 'my') {
      switch (key) {
        case 'NEW':
          return 'လက်ခံရန်';
        case 'PAYMENT':
          return 'တိုက်ရိုက်ပေးချေမှု';
        case 'PREPARING':
          return 'ချက်ပြုတ်နေဆဲ';
        case 'READY_FOR_PICKUP':
          return 'အသင့်ဖြစ်ပြီ';
        case 'DELIVERING':
          return 'ပို့ဆောင်နေဆဲ';
      }
    } else if (lang == 'th') {
      switch (key) {
        case 'NEW':
          return 'รอดำเนินการ';
        case 'PAYMENT':
          return 'ชำระเงินอัตโนมัติ';
        case 'PREPARING':
          return 'กำลังทำอาหาร';
        case 'READY_FOR_PICKUP':
          return 'พร้อมรับ';
        case 'DELIVERING':
          return 'กำลังจัดส่ง';
      }
    }
    switch (key) {
      case 'NEW':
        return 'To Accept';
      case 'PAYMENT':
        return 'Direct / Auto';
      case 'PREPARING':
        return 'Cooking';
      case 'READY_FOR_PICKUP':
        return 'Bagged & Ready';
      case 'DELIVERING':
        return 'Rider Dispatched';
      default:
        return '';
    }
  }

  String _getDeliveryStatusText(bool enabled) {
    final lang = _currentLang();
    if (lang == 'my') {
      return enabled ? 'အော်ဒါများလက်ခံနေသည်' : 'ပို့ဆောင်မှုခေတ္တရပ်ထားသည်';
    } else if (lang == 'th') {
      return enabled ? 'เปิดรับออเดอร์' : 'หยุดรับออเดอร์ชั่วคราว';
    }
    return enabled ? 'Accepting Orders' : 'Delivery Paused';
  }

  String _getDeliveryToggleText(bool enabled) {
    final lang = _currentLang();
    if (lang == 'my') {
      return enabled ? 'DELIVERY ON' : 'DELIVERY OFF';
    } else if (lang == 'th') {
      return enabled ? 'เปิดเดลิเวอรี่' : 'ปิดเดลิเวอรี่';
    }
    return enabled ? 'DELIVERY ON' : 'DELIVERY OFF';
  }

  String _getDeliverySubtitle(bool enabled) {
    final lang = _currentLang();
    if (lang == 'my') {
      return enabled ? 'ဆိုင်ဖွင့်ထားပါသည်' : 'ဆိုင်ပိတ်ထားပါသည်';
    } else if (lang == 'th') {
      return enabled ? 'ร้านเปิดรับออเดอร์' : 'ร้านปิดให้บริการ';
    }
    return enabled ? 'Store is open for orders' : 'Store is currently offline';
  }

  String _getDeliveryHeaderTitle() {
    final lang = _currentLang();
    if (lang == 'my') return 'ပို့ဆောင်မှုနှင့် ဆိုင်မှလာယူခြင်း';
    if (lang == 'th') return 'เดลิเวอรี่ & รับที่ร้าน';
    return 'Delivery & Pickup';
  }

  String _getCompletedTodayText(int count) {
    final lang = _currentLang();
    if (lang == 'my') return 'ယနေ့ပြီးစီး $count ခု';
    if (lang == 'th') return 'สำเร็จวันนี้ $count';
    return '$count Completed Today';
  }

  String _getCanceledTodayText(int count) {
    final lang = _currentLang();
    if (lang == 'my') return 'ယနေ့ပယ်ဖျက် $count ခု';
    if (lang == 'th') return 'ยกเลิกวันนี้ $count';
    return '$count Cancelled Today';
  }

  /// Shop Identity Header shown below top bar, above top section
  Widget _buildShopIdentityHeader(bool isDark) {
    final logoUrl = _shopProfile?.logoUrl;
    final shopName = _shopProfile?.displayName ?? 'My Shop';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.transparent : Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            spreadRadius: 0,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Shop Info Row: Logo + Shop Full Name (Takes full width, no truncation!)
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Shop Logo with profile tab header circular gradient & border style
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    width: 2,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(2.5),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.primary.withValues(alpha: 0.1),
                          const Color(0xFFFB923C).withValues(alpha: 0.1),
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: ClipOval(
                      child: logoUrl != null && logoUrl.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: logoUrl,
                              fit: BoxFit.cover,
                              placeholder: (_, _) => Center(
                                child: PhosphorIcon(
                                  PhosphorIconsFill.storefront,
                                  size: 20,
                                  color: AppColors.primary,
                                ),
                              ),
                              errorWidget: (_, _, _) => Center(
                                child: PhosphorIcon(
                                  PhosphorIconsFill.storefront,
                                  size: 20,
                                  color: AppColors.primary,
                                ),
                              ),
                            )
                          : Center(
                              child: PhosphorIcon(
                                PhosphorIconsFill.storefront,
                                size: 20,
                                color: AppColors.primary,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Shop Full Name & Real-time Status (Expands to full remaining width)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: shopName,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                              letterSpacing: -0.3,
                              height: 1.25,
                            ),
                          ),
                          if (_shopProfile?.isVerified == true)
                            const WidgetSpan(
                              alignment: PlaceholderAlignment.middle,
                              child: Padding(
                                padding: EdgeInsets.only(left: 6),
                                child: Tooltip(
                                  message: 'Verified Shop',
                                  child: PhosphorIcon(
                                    PhosphorIconsFill.sealCheck,
                                    size: 18,
                                    color: Color(0xFF38BDF8),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.visible,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: _deliveryEnabled ? AppColors.primaryGradient : null,
                            color: _deliveryEnabled ? null : const Color(0xFF94A3B8),
                            boxShadow: [
                              if (_deliveryEnabled)
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.5),
                                  blurRadius: 4,
                                  spreadRadius: 1,
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _getDeliveryStatusText(_deliveryEnabled),
                          style: GoogleFonts.poppins(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: _deliveryEnabled
                                ? (isDark ? const Color(0xFFFDBA74) : AppColors.primary)
                                : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Hairline divider
          Container(
            height: 1,
            color: isDark ? const Color(0xFF334155).withValues(alpha: 0.7) : const Color(0xFFF1F5F9),
          ),

          const SizedBox(height: 10),

          // 2. Delivery Service Strip: Service description & Primary Gradient Toggle Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      gradient: _deliveryEnabled ? AppColors.primaryGradient : null,
                      color: _deliveryEnabled
                          ? null
                          : (isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: PhosphorIcon(
                        PhosphorIconsFill.moped,
                        size: 16,
                        color: _deliveryEnabled
                            ? Colors.white
                            : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 9),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _getDeliveryHeaderTitle(),
                        style: GoogleFonts.poppins(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B),
                        ),
                      ),
                      Text(
                        _getDeliverySubtitle(_deliveryEnabled),
                        style: GoogleFonts.poppins(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w400,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Delivery ON / OFF Toggle Button with Primary Gradient
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(22),
                  onTap: _isTogglingDelivery
                      ? null
                      : () {
                          HapticFeedback.lightImpact();
                          _toggleDelivery(!_deliveryEnabled);
                        },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      gradient: _deliveryEnabled ? AppColors.primaryGradient : null,
                      color: _deliveryEnabled
                          ? null
                          : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        if (_deliveryEnabled)
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_isTogglingDelivery)
                          const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        else
                          Text(
                            _getDeliveryToggleText(_deliveryEnabled),
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: _deliveryEnabled
                                  ? Colors.white
                                  : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569)),
                              letterSpacing: 0.4,
                            ),
                          ),
                        const SizedBox(width: 8),
                        // Animated Switch Knob
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 15,
                          height: 15,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _deliveryEnabled
                                ? Colors.white
                                : (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 2,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Container(
                              width: 5,
                              height: 5,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _deliveryEnabled
                                    ? AppColors.primary
                                    : (isDark ? const Color(0xFF1E293B) : Colors.white),
                              ),
                            ),
                          ),
                        ),
                      ],
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

  /// Dashboard Grid displaying active states in a balanced, beautiful multi-column layout
  Widget _buildDashboardGrid(bool isTablet, bool isDark) {
    final columns = isTablet ? 5 : 2;

    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 10.0;
        final totalSpacing = spacing * (columns - 1);
        final cardWidth = (constraints.maxWidth - totalSpacing) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: List.generate(_stages.length, (index) {
            final stage = _stages[index];
            final isFullWidth = !isTablet && index == _stages.length - 1 && _stages.length % 2 != 0;
            return SizedBox(
              width: isFullWidth ? constraints.maxWidth : cardWidth,
              child: _buildDashboardCard(stage, isDark, isFullWidth: isFullWidth),
            );
          }),
        );
      },
    );
  }

  /// Individual Dashboard State Card
  Widget _buildDashboardCard(_DashboardStage stage, bool isDark, {bool isFullWidth = false}) {
    final count = _stageCounts[stage.key] ?? 0;
    final isUrgentStage = (stage.key == 'NEW' || stage.key == 'PAYMENT') && count > 0;
    final cardBg = Theme.of(context).cardColor;

    final countBadge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: count > 0
            ? stage.primaryColor
            : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(12),
        boxShadow: count > 0
            ? [
                BoxShadow(
                  color: stage.primaryColor.withValues(alpha: 0.35),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Text(
        '$count',
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: count > 0
              ? Colors.white
              : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
        ),
      ),
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _openStageOrders(stage.key),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(20),
            border: isUrgentStage
                ? Border.all(
                    color: stage.primaryColor.withValues(alpha: 0.5),
                    width: 1.5,
                  )
                : (count > 0
                    ? Border.all(
                        color: stage.primaryColor.withValues(alpha: 0.15),
                        width: 1.0,
                      )
                    : null),
            boxShadow: [
              if (isUrgentStage)
                BoxShadow(
                  color: stage.primaryColor.withValues(alpha: 0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                )
              else if (count > 0)
                BoxShadow(
                  color: stage.primaryColor.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              else
                BoxShadow(
                  color: isDark ? Colors.transparent : Colors.black.withValues(alpha: 0.04),
                  blurRadius: 16,
                  spreadRadius: 0,
                  offset: const Offset(0, 6),
                ),
            ],
          ),
          child: isFullWidth
              ? Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: stage.primaryColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Center(
                        child: PhosphorIcon(
                          stage.icon,
                          size: 20,
                          color: stage.primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _getStageTitle(stage.key, stage.title, context),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _getStageSubtitle(stage.key),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: isUrgentStage
                                  ? stage.primaryColor
                                  : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    countBadge,
                    const SizedBox(width: 8),
                    PhosphorIcon(
                      PhosphorIconsRegular.caretRight,
                      size: 14,
                      color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Top Row: Stage Icon + Large Count Badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: stage.primaryColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: Center(
                            child: PhosphorIcon(
                              stage.icon,
                              size: 20,
                              color: stage.primaryColor,
                            ),
                          ),
                        ),
                        countBadge,
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Title
                    Text(
                      _getStageTitle(stage.key, stage.title, context),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),

                    // Subtitle & Tap Arrow
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _getStageSubtitle(stage.key),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: isUrgentStage
                                  ? stage.primaryColor
                                  : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                            ),
                          ),
                        ),
                        PhosphorIcon(
                          PhosphorIconsRegular.caretRight,
                          size: 13,
                          color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                        ),
                      ],
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  /// Floating bottom pill for Completed and Cancelled orders (Today's counts only)
  Widget _buildFloatingBottomBar(bool isDark) {
    final deliveredCount = _todayCompletedCount;
    final canceledCount = _todayCanceledCount;

    if (deliveredCount == 0 && canceledCount == 0) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.transparent : Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (deliveredCount > 0)
            // Completed button
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _openStageOrders('DELIVERED'),
                borderRadius: BorderRadius.circular(18),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFF10B981),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xFF10B981),
                              blurRadius: 4,
                              spreadRadius: 0.5,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 7),
                      Text(
                        _getCompletedTodayText(deliveredCount),
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
                        ),
                      ),
                      const SizedBox(width: 4),
                      PhosphorIcon(
                        PhosphorIconsRegular.caretRight,
                        size: 12,
                        color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          if (deliveredCount > 0 && canceledCount > 0)
            // Divider Line
            Container(
              height: 14,
              width: 1,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
            ),

          if (canceledCount > 0)
            // Cancelled button
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _openStageOrders('CANCELED'),
                borderRadius: BorderRadius.circular(18),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFFEF4444),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xFFEF4444),
                              blurRadius: 4,
                              spreadRadius: 0.5,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 7),
                      Text(
                        _getCanceledTodayText(canceledCount),
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
                        ),
                      ),
                      const SizedBox(width: 4),
                      PhosphorIcon(
                        PhosphorIconsRegular.caretRight,
                        size: 12,
                        color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
