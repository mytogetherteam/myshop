import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../data/models/order_model.dart';
import '../screens/orders_screen.dart';
import '../screens/order_detail_screen.dart';
import 'status_progress_indicator.dart';
import 'package:my_shop/core/presentation/widgets/animated_ellipsis_text.dart';
import 'package:my_shop/core/presentation/widgets/primary_gradient_button.dart';
import 'package:my_shop/core/presentation/widgets/gradient_widgets.dart';
import 'package:my_shop/core/localization/app_localizations.dart';

class OrderCard extends StatelessWidget {
  final OrderModel order;
  final bool isPaymentTab;
  final bool isDeliveryTab;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onRefresh;
  final ValueChanged<String>? onStatusChanged;

  const OrderCard({
    super.key,
    required this.order,
    this.isPaymentTab = false,
    this.isDeliveryTab = false,
    this.margin,
    this.onRefresh,
    this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: (Theme.of(context).brightness == Brightness.dark ? Theme.of(context).cardColor : (Theme.of(context).brightness == Brightness.dark ? Theme.of(context).cardColor : const Color(0xFFF1F5F9)))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () async {
            final result = await Navigator.push(
              context,
              PageRouteBuilder(
                settings: RouteSettings(name: 'order_detail_${order.id}'),
                pageBuilder: (context, animation, secondaryAnimation) => OrderDetailScreen(order: order),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  const begin = Offset(1.0, 0.0);
                  const end = Offset.zero;
                  const curve = Curves.easeOut;
                  var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                  return SlideTransition(position: animation.drive(tween), child: child);
                },
                reverseTransitionDuration: Duration.zero,
              ),
            );
            if (context.mounted) {
              onRefresh?.call();
              if (result != null && result is String) {
                onStatusChanged?.call(result);
              }
              final state = context.findAncestorStateOfType<OrdersScreenState>();
              if (state != null) {
                state.refreshAll();
                if (result != null && result is String) {
                  state.switchToStatus(result);
                }
              }
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '#${order.lastOrderNo}',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context).textTheme.bodyLarge?.color,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          GradientText(
                            order.statusName,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    GradientText(
                      order.displayTotalAmount,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      _getTimeAgo(order.createdAt, context),
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                if (order.status == 'CANCELED')
                  _buildCancellationBox(context)
                else
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 600),
                    child: StatusProgressIndicator(
                      key: ValueKey('${order.status}_${order.isVerified}'),
                      status: order.status,
                      isPickup: order.isPickupFulfillment,
                      isVerifiedDelivery: (order.isVerified ||
                              order.isLalamoveDelivery ||
                              order.isOmisePayment) &&
                          order.isDeliveryFulfillment,
                    ),
                  ),
                SizedBox(height: 16),
                ...order.items.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '${item.quantity}x ${item.displayName}',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                      ),
                    )),
                SizedBox(height: 16),
                Divider(color: Theme.of(context).dividerColor.withValues(alpha: 0.3), height: 1),
                SizedBox(height: 16),
                _buildActionButtons(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCancellationBox(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF4C0519) : (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF4C0519) : const Color(0xFFFFF1F2))),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFECDD3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(PhosphorIconsFill.smileySad, color: Color(0xFFEF4444), size: 20),
              SizedBox(width: 8),
              Text(
                t?.translate('order_cancelled') ?? 'Order Cancelled',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFBE123C),
                ),
              ),
            ],
          ),
          if (order.cancelReason != null && order.cancelReason!.isNotEmpty) ...[
            SizedBox(height: 8),
            Text(
              order.cancelReason!,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF9F1239),
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final t = AppLocalizations.of(context);
    bool isInformational = order.status == 'DELIVERED' || order.status == 'CANCELED';
    
    if (isInformational) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () async {
            final result = await Navigator.push(
              context,
              PageRouteBuilder(
                settings: RouteSettings(name: 'order_detail_${order.id}'),
                pageBuilder: (context, animation, secondaryAnimation) => OrderDetailScreen(order: order),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  const begin = Offset(1.0, 0.0);
                  const end = Offset.zero;
                  const curve = Curves.easeOut;
                  var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                  return SlideTransition(position: animation.drive(tween), child: child);
                },
                reverseTransitionDuration: Duration.zero,
              ),
            );
            if (context.mounted) {
              onRefresh?.call();
              if (result != null && result is String) {
                onStatusChanged?.call(result);
              }
              final state = context.findAncestorStateOfType<OrdersScreenState>();
              state?.refreshAll();
              if (result != null && result is String) {
                state?.switchToStatus(result);
              }
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF334155) : (Theme.of(context).brightness == Brightness.dark ? Theme.of(context).cardColor : (Theme.of(context).brightness == Brightness.dark ? Theme.of(context).cardColor : const Color(0xFFF1F5F9))),
            foregroundColor: Theme.of(context).textTheme.bodyLarge?.color ?? (Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF1E293B)),
            minimumSize: const Size(double.infinity, 54),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            t?.translate('view_details') ?? 'View Details',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    String mainButtonText = t?.translate('view_details') ?? 'View order';
    bool isMainButtonEnabled = true;
    IconData? mainButtonIcon;

    switch (order.status) {
      case 'AWAITING_APPROVAL':
        mainButtonText = t?.translate('check_payment') ?? 'Check Payment';
        break;
      case 'PAYMENT_SLIP_REQUESTED':
        if (order.isOmisePayment) {
          mainButtonText = 'Awaiting Direct Payment';
          isMainButtonEnabled = false;
          mainButtonIcon = Icons.payment_outlined;
        } else {
          mainButtonText = t?.translate('waiting_payment') ?? 'Waiting for Payment';
          isMainButtonEnabled = false;
          mainButtonIcon = Icons.access_time_outlined;
        }
        break;
      case 'PAYMENT_VERIFIED':
        mainButtonText = (order.isVerified || order.isOmisePayment)
            ? (t?.translate('accept_and_start_cooking') ?? 'Accept & Cook')
            : (t?.translate('accept_order_to_cook') ?? 'Accept order to cook');
        mainButtonIcon = PhosphorIconsFill.cookingPot;
        break;
      case 'COOKING':
        if (order.isPickupFulfillment) {
          mainButtonText =
              t?.translate('mark_ready_for_pickup') ?? 'Ready for Pickup';
        } else {
          final rawReady = t?.translate('ready_and_find_rider');
          final lang = LocalizationService.instance.localeNotifier.value.languageCode;
          final fallbackReady = (lang == 'my')
              ? 'အဆင်သင့်ဖြစ်ပြီ Rider ရှာမည်'
              : (lang == 'th' ? 'พร้อมแล้วและค้นหาไรเดอร์' : 'Ready & Find Rider');
          final readyText = (rawReady != null && rawReady.isNotEmpty && rawReady != 'ready_and_find_rider')
              ? rawReady
              : fallbackReady;
          mainButtonText = (order.isVerified || order.isLalamoveDelivery)
              ? readyText
              : (t?.translate('picked_up_rider') ?? 'Picked Up by Rider');
        }
        break;
      case 'READY_FOR_PICKUP':
        if (order.isPickupFulfillment) {
          mainButtonText = t?.translate('verify_pickup') ?? 'Verify Pickup';
        } else if (order.isVerified || order.isLalamoveDelivery) {
          final rawRider = t?.translate('request_rider');
          final lang = LocalizationService.instance.localeNotifier.value.languageCode;
          final fallbackRider = (lang == 'my')
              ? 'Rider ခေါ်မည်'
              : (lang == 'th' ? 'เรียกรถส่ง' : 'Request Rider');
          final riderText = (rawRider != null && rawRider.isNotEmpty && rawRider != 'request_rider')
              ? rawRider
              : fallbackRider;
          final rawTrack = t?.translate('track_live_delivery');
          final fallbackTrack = (lang == 'my')
              ? 'ပို့ဆောင်မှု တိုက်ရိုက်ကြည့်ရှုမည် 📍'
              : (lang == 'th' ? 'ติดตามการจัดส่งแบบสด 📍' : 'Track Live Delivery 📍');
          final trackText = (rawTrack != null && rawTrack.isNotEmpty && rawTrack != 'track_live_delivery')
              ? '$rawTrack 📍'
              : fallbackTrack;
          mainButtonText = (order.trackingUrl != null && order.trackingUrl!.trim().isNotEmpty)
              ? trackText
              : riderText;
        } else {
          mainButtonText = t?.translate('picked_up_rider') ?? 'Picked Up by Rider';
        }
        break;
      case 'ON_THE_WAY':
        mainButtonText = (isDeliveryTab || order.isVerified || order.isLalamoveDelivery)
            ? (t?.translate('check_delivery') ?? 'Check Delivery')
            : (t?.translate('tab_delivered') ?? 'Delivered');
        break;
      case 'REVISED':
        mainButtonText = t?.translate('view_details') ?? 'View Details';
        break;
    }

    return Row(
      children: [
        Expanded(
          child: PrimaryGradientButton(
            onPressed: isMainButtonEnabled ? () async {
              final result = await Navigator.push(
                context,
                PageRouteBuilder(
                  settings: RouteSettings(name: 'order_detail_${order.id}'),
                  pageBuilder: (context, animation, secondaryAnimation) => OrderDetailScreen(order: order),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                    const begin = Offset(1.0, 0.0);
                    const end = Offset.zero;
                    const curve = Curves.easeOut;
                    var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                    return SlideTransition(position: animation.drive(tween), child: child);
                  },
                  reverseTransitionDuration: Duration.zero,
                ),
              );
              if (context.mounted) {
                onRefresh?.call();
                if (result != null && result is String) {
                  onStatusChanged?.call(result);
                }
                final state = context.findAncestorStateOfType<OrdersScreenState>();
                state?.refreshAll();
                if (result != null && result is String) {
                  state?.switchToStatus(result);
                }
              }
            } : null,
            height: 54,
            borderRadius: 12,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (mainButtonIcon != null) ...[
                  Icon(mainButtonIcon, size: 16, color: Colors.white),
                  SizedBox(width: 6),
                ],
                if (isMainButtonEnabled)
                  Flexible(
                    child: Text(
                      mainButtonText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                  )
                else
                  Flexible(
                    child: AnimatedEllipsisText(
                      text: mainButtonText,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _getTimeAgo(DateTime dateTime, BuildContext context) {
    final t = AppLocalizations.of(context);
    final difference = DateTime.now().difference(dateTime);
    if (difference.inMinutes < 1) return t?.translate('just_now') ?? 'Just Now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}${t?.translate('mins_ago') ?? ' min(s) ago'}';
    if (difference.inHours < 24) return '${difference.inHours}${t?.translate('hours_ago') ?? ' hr(s) ago'}';
    return DateFormat('dd MMM').format(dateTime);
  }
}