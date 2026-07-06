import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_shop/core/utils/app_colors.dart';
import 'package:my_shop/features/menu/presentation/screens/menu_page.dart';
import 'package:my_shop/features/orders/presentation/screens/orders_screen.dart';
import 'package:my_shop/features/chat/presentation/screens/chat_page.dart';

import 'package:my_shop/features/profile/presentation/screens/profile_page.dart';
import 'package:my_shop/features/reports/presentation/screens/report_page.dart';
import 'package:my_shop/features/orders/data/models/order_model.dart';
import 'package:my_shop/features/orders/presentation/widgets/new_order_dialog.dart';
import 'package:my_shop/features/orders/presentation/widgets/order_warning_dialog.dart';
import 'package:my_shop/features/orders/presentation/widgets/order_cancelled_dialog.dart';
import 'package:my_shop/features/orders/presentation/screens/order_detail_screen.dart';
import 'package:my_shop/core/network/websocket_service.dart';
import 'package:my_shop/features/chat/data/services/chat_unread_controller.dart';
import 'package:my_shop/features/notifications/presentation/widgets/notification_badge_icon.dart';
import 'package:my_shop/features/orders/presentation/widgets/order_qr_scan_icon.dart';
import 'package:flutter/services.dart';
import 'package:my_shop/core/presentation/widgets/app_bar_title_with_logo.dart';
import 'package:my_shop/core/utils/app_logger.dart';
import 'dart:async';
import 'package:my_shop/core/localization/app_localizations.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';
import 'package:my_shop/core/notifications/notification_service.dart';
import 'package:my_shop/core/presentation/widgets/primary_gradient_button.dart';
import 'package:my_shop/core/data/services/storage_service.dart';
import 'package:my_shop/features/orders/data/services/order_service.dart';
import 'package:my_shop/core/presentation/widgets/phone_setup_guide_sheet.dart';

enum MainTab { order, menu, report, chat, profile }

/// Lets deep order/pickup flows return to the Orders tab after completion.
class OrdersTabNavigation {
  static void Function(String status)? returnToOrdersTab;
}

class MainNavigationScreen extends StatefulWidget {
  final int initialIndex;
  const MainNavigationScreen({super.key, this.initialIndex = 0});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late int _currentIndex;
  late final Map<MainTab, Widget> _pageInstances;
  bool _isOperationAdmin = false;
  
  List<MainTab> get _activeTabs {
    return [
      MainTab.order,
      MainTab.menu,
      if (!_isOperationAdmin) MainTab.report,
      MainTab.chat,
      MainTab.profile,
    ];
  }
  StreamSubscription? _socketSubscription;
  StreamSubscription? _notificationSubscription;
  StreamSubscription? _shopAutoPausedSubscription;
  AudioPlayer? _alertAudioPlayer;
  Timer? _vibrationTimer;
  late final AppLifecycleListener _lifecycleListener;

  final GlobalKey<OrdersScreenState> _ordersKey =
      GlobalKey<OrdersScreenState>();
  final GlobalKey<MenuPageState> _menuKey = GlobalKey<MenuPageState>();
  final GlobalKey<ReportPageState> _reportKey = GlobalKey<ReportPageState>();
  final GlobalKey<ChatPageState> _chatKey = GlobalKey<ChatPageState>();
  final GlobalKey<ProfilePageState> _profileKey = GlobalKey<ProfilePageState>();
  final List<bool> _visited = [false, false, false, false, false];
  bool _isIncomingOrderDialogOpen = false;


  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _visited[_currentIndex] = true;
    _pageInstances = {
      MainTab.order: OrdersScreen(key: _ordersKey),
      MainTab.menu: MenuPage(key: _menuKey),
      MainTab.report: ReportPage(key: _reportKey),
      MainTab.chat: ChatPage(key: _chatKey),
      MainTab.profile: ProfilePage(key: _profileKey),
    };
    
    _loadUserInfo();

    // IMPORTANT: Register listener FIRST so we never miss events fired during
    // the very first WebSocket connection/subscription handshake.
    _setupWebSocketListener();
    ChatUnreadController.instance.start();
    OrdersTabNavigation.returnToOrdersTab = _returnToOrdersTab;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      PhoneSetupGuideSheet.showIfNeeded(context);
    });

    // Connect AFTER listener is ready (post-frame ensures widget is mounted
    // and the stream listener is active before any events can arrive).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      WebSocketService().connect();
      _checkMissedOrders();
    });

    // Reconnect WS + refresh orders whenever app comes back from background.
    _lifecycleListener = AppLifecycleListener(
      onResume: _onAppResumed,
    );

    _shopAutoPausedSubscription = NotificationService.shopAutoPausedStream.stream.listen((_) {
      _showAutoPausedDialog();
    });
  }

  Future<void> _loadUserInfo() async {
    final userInfo = await StorageService.instance.getUserInfo();
    if (mounted && userInfo != null) {
      if (userInfo.role == 'OperationAdmin') {
        setState(() {
          _isOperationAdmin = true;
          // If we somehow were on an out-of-bounds index, reset to 0
          if (_currentIndex >= _activeTabs.length) {
            _currentIndex = 0;
            _visited[_currentIndex] = true;
          }
        });
      }
    }
  }

  /// Called when the app returns from background (minimize, screen-off, etc.).
  /// Re-establishes the WebSocket and does a full re-sync so both devices
  /// always reflect the latest order state even after missing WS events.
  Future<void> _onAppResumed() async {
    AppLogger.realtime('[Lifecycle] App resumed — reconnecting WS & syncing orders');
    await WebSocketService().connect(force: true);
    if (mounted) {
      _ordersKey.currentState?.refresh();
      _ordersKey.currentState?.syncCounts();
      // Check for any missed/auto-cancelled orders since last session
      _checkMissedOrders();
    }
  }

  void _returnToOrdersTab(String status) {
    if (_currentIndex != 0) {
      setState(() => _currentIndex = 0);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ordersKey.currentState?.refresh();
      _ordersKey.currentState?.switchToStatus(status);
    });
  }

  Future<void> _checkMissedOrders() async {
    if (!mounted) return;
    final data = await OrderService().getMissedRevenueToday();
    if (!mounted || data == null) return;

    final missedCount = data['missedCount'] as int? ?? 0;
    if (missedCount == 0) return;

    final rawOrders = data['orders'] as List<dynamic>? ?? [];
    List<dynamic> newMissedOrders = [];

    if (NotificationService.pendingMissedOrderCheck) {
      // User tapped the canceled order notification. Show all missed orders today.
      newMissedOrders = rawOrders;
      NotificationService.pendingMissedOrderCheck = false; // Reset the flag
    } else {
      // Only show warning for orders canceled AFTER the last time the user saw this dialog
      final lastCheckMs = await StorageService.instance.getLastMissedOrderCheckMs();
      newMissedOrders = rawOrders.where((o) {
        final canceledAt = DateTime.tryParse(o['canceledAt']?.toString() ?? o['updatedAt']?.toString() ?? '');
        if (canceledAt == null) return false;
        return canceledAt.millisecondsSinceEpoch > lastCheckMs;
      }).toList();
    }

    if (!mounted || newMissedOrders.isEmpty) return;

    final lostRevenue = newMissedOrders.fold<num>(
      0, (sum, o) => sum + ((o['totalAmount'] as num?) ?? 0),
    );

    _showMissedOrderWarningModal(newMissedOrders.length, lostRevenue.toInt());
  }

  void _showMissedOrderWarningModal(int count, int lostRevenue) {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 32,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Red warning header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFE11D48), Color(0xFFFF4D6D)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  children: [
                    const Text('⚠️', style: TextStyle(fontSize: 40)),
                    const SizedBox(height: 8),
                    Text(
                      'Order လွတ်သွားပြီ!',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'App ကို ကြည့်မနေတဲ့အချိန် Order $count ခု Cancel ဖြစ်သွားပါသည်',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              // Body
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Revenue lost chip
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF1F2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFFCDD2)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('💸', style: TextStyle(fontSize: 20)),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ဆုံးရှုံးသွားသော ငွေ',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: const Color(0xFF9F1239),
                                ),
                              ),
                              Text(
                                '${lostRevenue.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',')} MMK',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFFE11D48),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '📱 App ကို အမြဲဖွင့်ထားပြီး Notification Sound ကြည့်ပါ။ Order ဝင်လာတာနဲ့ ချက်ချင်း Response ပေးပါ!',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          await StorageService.instance.setLastMissedOrderCheckMs(
                            DateTime.now().millisecondsSinceEpoch,
                          );
                          if (ctx.mounted) Navigator.pop(ctx);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE11D48),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'သိပါပြီ — ဆက်လက် ကြိုးစားမည်',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAutoPausedDialog() {
    if (!mounted) return;
    Vibration.vibrate(duration: 1000);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Text('🚨', style: TextStyle(fontSize: 28)),
            const SizedBox(width: 8),
            Text(
              'Shop Auto-Paused',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 18),
            ),
          ],
        ),
        content: Text(
          'You missed 3 orders today and your shop was automatically taken offline to protect users.\n\nPlease turn your shop back online if you are ready to receive orders.',
          style: GoogleFonts.poppins(fontSize: 14, height: 1.5),
        ),
        actions: [
          PrimaryGradientButton(
            text: 'I am ready',
            onPressed: () {
              Navigator.pop(context);
              // Jump to Profile to toggle status, or handle directly here
              setState(() => _currentIndex = _activeTabs.indexOf(MainTab.profile));
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    if (OrdersTabNavigation.returnToOrdersTab == _returnToOrdersTab) {
      OrdersTabNavigation.returnToOrdersTab = null;
    }
    _socketSubscription?.cancel();
    _notificationSubscription?.cancel();
    _shopAutoPausedSubscription?.cancel();
    _alertAudioPlayer?.dispose();
    _vibrationTimer?.cancel();
    _lifecycleListener.dispose();
    super.dispose();
  }

  Future<void> _playAlertSoundIfNotViewing(String orderId) async {
    final routeName = 'order_detail_$orderId';
    bool isAlreadyOnThisOrder = false;
    Navigator.popUntil(context, (route) {
      if (route.settings.name == routeName) {
        isAlreadyOnThisOrder = true;
      }
      return true; // Don't actually pop anything
    });

    if (!isAlreadyOnThisOrder) {
      if (NotificationService.justClickedNotification) {
        return; // User just clicked notification, skip duplicate sound
      }

      try {
        _alertAudioPlayer?.stop();
        _alertAudioPlayer?.dispose();
        _alertAudioPlayer = AudioPlayer();
        await _alertAudioPlayer?.setReleaseMode(ReleaseMode.loop);
        await _alertAudioPlayer?.play(AssetSource('alert/alert.mp3'));
        _startVibrationLoop();
      } catch (e) {
        AppLogger.realtime('Audio play error: $e');
      }
    }
  }

  void _startVibrationLoop() {
    _stopVibrationLoop();
    _vibrationTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (await Vibration.hasVibrator() == true) {
        Vibration.vibrate(duration: 1000);
      }
    });
  }

  void _stopVibrationLoop() {
    _vibrationTimer?.cancel();
    _vibrationTimer = null;
    Vibration.cancel();
  }

  void _stopAlertSound() {
    _alertAudioPlayer?.stop();
    _alertAudioPlayer?.dispose();
    _alertAudioPlayer = null;
    _stopVibrationLoop();
    NotificationService().cancelNotification(99999);
  }

  void _setupWebSocketListener() {
    AppLogger.realtime('MainNavigation: setting up listener');
    
    _notificationSubscription = NotificationService.orderAcknowledgedStream.stream.listen((_) {
      AppLogger.realtime('MainNavigation: Order acknowledged via FCM push. Stopping alerts.');
      _stopAlertSound();
      if (!mounted) return;
      if (_isIncomingOrderDialogOpen && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    });

    _socketSubscription = WebSocketService().orderUpdates.listen((event) async {
      AppLogger.realtime(
        'MainNavigation event: ${event['type']}, msg: ${event['message']}',
      );

      final dynamic rawOrder = event['order'];
      final dynamic rawMsg = event['message'];
      final String? msg = rawMsg?.toString();

      final String? type = event['type']?.toString();

      if (type == 'ORDER_ACKNOWLEDGED') {
        AppLogger.realtime('MainNavigation: Order acknowledged by another admin. Stopping alerts.');
        _stopAlertSound();
        if (!mounted) return;
        if (_isIncomingOrderDialogOpen && Navigator.canPop(context)) {
          Navigator.pop(context); // Close NewOrderDialog if open
        }
        return;
      }

      if (rawOrder != null) {
        final orderData = OrderModel.fromJson(rawOrder);

        if (mounted) {
          final String status = orderData.status.toUpperCase();
          final String? lowerMsg = msg?.toLowerCase();
          final bool isTwoMinWarning =
              lowerMsg != null &&
              (lowerMsg.contains('2 min') || lowerMsg.contains('2 မိနစ်'));

          AppLogger.realtime(
            'MainNavigation logic check -> status: $status, isTwoMin: $isTwoMinWarning',
          );

          if (isTwoMinWarning) {
            AppLogger.realtime('MainNavigation: triggering OrderWarningDialog (2-min)');
            HapticFeedback.vibrate();
            _playAlertSoundIfNotViewing(orderData.id.toString());
            await showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => OrderWarningDialog(
                message: msg!,
                order: orderData,
                onTakeAction: () {
                  Navigator.pop(context);
                  _navigateToOrderDetail(orderData);
                },
              ),
            );
            _stopAlertSound();
          } else if (status == 'PENDING' ||
              status == 'NEW' ||
              event['type'] == 'NEW_ORDER') {
            AppLogger.realtime('MainNavigation: triggering NewOrderDialog');
            HapticFeedback.heavyImpact();
            _playAlertSoundIfNotViewing(orderData.id.toString());
            _isIncomingOrderDialogOpen = true;
            await showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => NewOrderDialog(
                order: orderData,
                onViewOrder: () {
                  Navigator.pop(context);
                  _navigateToOrderDetail(orderData);
                },
              ),
            );
            _isIncomingOrderDialogOpen = false;
            _stopAlertSound();
          } else if (status == 'CANCELED') {
            AppLogger.realtime('MainNavigation: triggering OrderCancelledDialog');
            _stopAlertSound();
            HapticFeedback.vibrate();
            // Close any currently open dialog (e.g. NewOrderDialog)
            if (_isIncomingOrderDialogOpen && Navigator.canPop(context)) {
              Navigator.pop(context);
            }
            await showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => OrderCancelledDialog(
                order: orderData,
                onViewOrder: () {
                  Navigator.pop(context);
                  _navigateToOrderDetail(orderData);
                },
              ),
            );
          } else if (msg != null && msg.trim().isNotEmpty) {
            // Generic warning for other status updates with messages
            AppLogger.realtime('MainNavigation: triggering OrderWarningDialog (generic)');
            HapticFeedback.vibrate();
            _playAlertSoundIfNotViewing(orderData.id.toString());
            await showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => OrderWarningDialog(
                message: msg,
                order: orderData,
                onTakeAction: () {
                  Navigator.pop(context);
                  _navigateToOrderDetail(orderData);
                },
              ),
            );
            _stopAlertSound();
          }
        }
      }
    });
  }

  Future<void> _navigateToOrderDetail(OrderModel order) async {
    final routeName = 'order_detail_${order.id}';

    // Check if we are already viewing this order
    bool isAlreadyOnThisOrder = false;
    Navigator.popUntil(context, (route) {
      if (route.settings.name == routeName) {
        isAlreadyOnThisOrder = true;
      }
      return true; // Don't actually pop anything
    });

    if (isAlreadyOnThisOrder) {
      AppLogger.realtime('Already viewing order ${order.id}, skipping navigation.');
      return;
    }

    final result = await Navigator.push(
      context,
      PageRouteBuilder(
        settings: RouteSettings(name: routeName),
        pageBuilder: (context, animation, secondaryAnimation) =>
            OrderDetailScreen(order: order),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeOut;
          var tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: curve));
          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
        reverseTransitionDuration: Duration.zero,
      ),
    );

    if (result != null && result is String) {
      if (_currentIndex != 0) {
        setState(() => _currentIndex = 0);
      }
      // Wait for build if we just switched tab
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _ordersKey.currentState?.switchToStatus(result);
      });
    }
  }



  Widget _buildGradientItem(IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ShaderMask(
        shaderCallback: (Rect bounds) {
          return AppColors.primaryGradient.createShader(bounds);
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PhosphorIcon(icon, size: 28, color: Colors.white),
            SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInactiveItem(IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PhosphorIcon(icon, size: 28, color: Theme.of(context).textTheme.bodySmall?.color),
          SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
        ],
      ),
    );
  }



  /// Overlays the live unread-chat count on top of the Chat tab icon.
  Widget _withChatBadge(Widget child) {
    return ValueListenableBuilder<int>(
      valueListenable: ChatUnreadController.instance.unread,
      builder: (context, count, _) {
        return Stack(
          clipBehavior: Clip.none,
          children: [
            child,
            if (count > 0)
              Positioned(
                right: -2,
                top: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: Color(0xFFED3973),
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    count > 99 ? '99+' : '$count',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  String _getTabTitle(MainTab tab, AppLocalizations? t) {
    switch (tab) {
      case MainTab.order: return t?.translate('order') ?? 'Order';
      case MainTab.menu: return t?.translate('menu') ?? 'Menu';
      case MainTab.report: return t?.translate('report') ?? 'Report';
      case MainTab.chat: return t?.translate('chat') ?? 'Chat';
      case MainTab.profile: return t?.translate('profile') ?? 'Profile';
    }
  }

  BottomNavigationBarItem _buildNavItem(MainTab tab, AppLocalizations? t) {
    final title = _getTabTitle(tab, t);
    switch (tab) {
      case MainTab.order:
        return BottomNavigationBarItem(
          icon: _buildInactiveItem(PhosphorIconsRegular.cookingPot, title),
          activeIcon: _buildGradientItem(PhosphorIconsFill.cookingPot, title),
          label: title,
        );
      case MainTab.menu:
        return BottomNavigationBarItem(
          icon: _buildInactiveItem(PhosphorIconsRegular.forkKnife, title),
          activeIcon: _buildGradientItem(PhosphorIconsFill.forkKnife, title),
          label: title,
        );
      case MainTab.report:
        return BottomNavigationBarItem(
          icon: _buildInactiveItem(PhosphorIconsRegular.listHeart, title),
          activeIcon: _buildGradientItem(PhosphorIconsFill.listHeart, title),
          label: title,
        );
      case MainTab.chat:
        return BottomNavigationBarItem(
          icon: _withChatBadge(_buildInactiveItem(PhosphorIconsRegular.chatCircle, title)),
          activeIcon: _withChatBadge(_buildGradientItem(PhosphorIconsFill.chatCircle, title)),
          label: title,
        );
      case MainTab.profile:
        return BottomNavigationBarItem(
          icon: _buildInactiveItem(PhosphorIconsRegular.storefront, title),
          activeIcon: _buildGradientItem(PhosphorIconsFill.storefront, title),
          label: title,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final activeTabs = _activeTabs;
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        title: AppBarTitleWithLogo(title: _getTabTitle(activeTabs[_currentIndex], t)),
        actions: const [
          OrderQrScanIcon(),
          NotificationBadgeIcon(),
          SizedBox(width: 8),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: activeTabs.asMap().entries.map((entry) {
          final int idx = entry.key;
          final MainTab tab = entry.value;
          return _visited[idx] ? _pageInstances[tab]! : const SizedBox.shrink();
        }).toList(),
      ),

      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
        onTap: (index) {
          HapticFeedback.lightImpact();
          if (_currentIndex == index) {
            final tab = activeTabs[index];
            switch (tab) {
              case MainTab.order:
                _ordersKey.currentState?.refresh();
                break;
              case MainTab.menu:
                _menuKey.currentState?.refresh();
                break;
              case MainTab.report:
                _reportKey.currentState?.refresh();
                break;
              case MainTab.chat:
                _chatKey.currentState?.refresh();
                break;
              case MainTab.profile:
                _profileKey.currentState?.refresh();
                break;
            }
          }
          setState(() {
            _currentIndex = index;
            _visited[index] = true;
          });
        },
        backgroundColor: Theme.of(context).cardColor,
        selectedItemColor: const Color(0xFFED3973),
        unselectedItemColor: (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
        showSelectedLabels: false,
        showUnselectedLabels: false,
        selectedFontSize: 0,
        unselectedFontSize: 0,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        items: activeTabs.map((tab) => _buildNavItem(tab, t)).toList(),
      ),
      ),
    );
  }

  /*
  Widget _buildAnalyticsButton() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AnalyticsPage()),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.all(1.2),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              PhosphorIcon(
                PhosphorIconsFill.chartPieSlice,
                size: 14,
                color: Color(0xFFED3973),
              ),
              SizedBox(width: 4),
              Text(
                "Analytics",
                style: GoogleFonts.poppins(
                  color: const Color(0xFFED3973),
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  */
}
