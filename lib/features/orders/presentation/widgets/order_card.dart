import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../data/models/order_model.dart';
import '../../data/services/order_service.dart';
import '../screens/orders_screen.dart';
import '../screens/order_detail_screen.dart';
import 'status_progress_indicator.dart';
import 'package:my_shop/core/presentation/widgets/animated_ellipsis_text.dart';
import 'package:my_shop/core/presentation/widgets/primary_gradient_button.dart';
import 'package:my_shop/core/presentation/widgets/gradient_widgets.dart';
import 'package:my_shop/core/presentation/widgets/app_dialog.dart';
import 'package:my_shop/core/localization/app_localizations.dart';
import 'package:my_shop/core/presentation/widgets/keyboard_padding_wrapper.dart';
import 'package:my_shop/features/orders/presentation/widgets/cancel_order_dialog.dart';

class OrderCard extends StatelessWidget {
  final OrderModel order;
  final bool isPaymentTab;
  final bool isDeliveryTab;

  const OrderCard({
    super.key,
    required this.order,
    this.isPaymentTab = false,
    this.isDeliveryTab = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
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
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '#${order.lastOrderNo}',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1E293B),
                          ),
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
                    GradientText(
                      order.displayTotalAmount,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      _getTimeAgo(order.createdAt, context),
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (order.status == 'CANCELED')
                  _buildCancellationBox(context)
                else
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 600),
                    child: StatusProgressIndicator(
                      key: ValueKey(order.status),
                      status: order.status,
                      isPickup: order.isPickupFulfillment,
                    ),
                  ),
                const SizedBox(height: 16),
                ...order.items.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '${item.quantity}x ${item.displayName}',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: const Color(0xFF475569),
                        ),
                      ),
                    )),
                const SizedBox(height: 16),
                const Divider(color: Color(0xFFF1F5F9), height: 1),
                const SizedBox(height: 16),
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
        color: const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFECDD3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(PhosphorIconsFill.smileySad, color: Color(0xFFEF4444), size: 20),
              const SizedBox(width: 8),
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
            const SizedBox(height: 8),
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
              final state = context.findAncestorStateOfType<OrdersScreenState>();
              state?.refreshAll();
              if (result != null && result is String) {
                state?.switchToStatus(result);
              }
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFF1F5F9),
            foregroundColor: const Color(0xFF1E293B),
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
        mainButtonText = t?.translate('waiting_payment') ?? 'Waiting for Payment';
        isMainButtonEnabled = false;
        mainButtonIcon = Icons.access_time_outlined;
        break;
      case 'PAYMENT_VERIFIED':
        mainButtonText = t?.translate('accept_order_to_cook') ?? 'Accept order to cook';
        break;
      case 'COOKING':
        if (order.isPickupFulfillment) {
          mainButtonText =
              t?.translate('mark_ready_for_pickup') ?? 'Ready for Pickup';
        } else {
          mainButtonText = t?.translate('picked_up_rider') ?? 'Picked Up by Rider';
        }
        break;
      case 'READY_FOR_PICKUP':
        mainButtonText = t?.translate('verify_pickup') ?? 'Verify Pickup';
        break;
      case 'ON_THE_WAY':
        mainButtonText = isDeliveryTab ? (t?.translate('check_delivery') ?? 'Check Delivery') : (t?.translate('tab_delivered') ?? 'Delivered');
        break;
      case 'REVISED':
        mainButtonText = t?.translate('view_details') ?? 'View Details';
        break;
    }

    final bool canCancel = order.status == 'PENDING' ||
        order.status == 'REVISED' ||
        order.status == 'PAYMENT_SLIP_REQUESTED';

    return Row(
      children: [
        if (canCancel) ...[
          Expanded(
            child: OutlinedButton(
              onPressed: () => _showCancelDialog(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFED3973),
                side: const BorderSide(color: Color(0xFFFEE2E2)),
                backgroundColor: const Color(0xFFFFF1F2),
                minimumSize: const Size(0, 54),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: GradientText(
                t?.translate('cancel') ?? 'Cancel',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          flex: isPaymentTab ? 1 : 2,
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
                  Icon(mainButtonIcon, size: 18, color: Colors.white),
                  const SizedBox(width: 8),
                ],
                if (isMainButtonEnabled)
                  Flexible(
                    child: Text(
                      mainButtonText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                  )
                else
                  AnimatedEllipsisText(
                    text: mainButtonText,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: Colors.white,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showCancelDialog(BuildContext context) {
    final t = AppLocalizations.of(context);
    final staticMediaQuery = MediaQuery.of(context).copyWith(viewInsets: EdgeInsets.zero);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => MediaQuery(
        data: staticMediaQuery,
        child: CancelOrderDialog(
          onConfirm: (reason) async {
            final result = await OrderService().cancelOrder(
              order.id,
              reason.isEmpty ? null : reason,
            );
            final success = result['success'] == true;
            if (context.mounted) {
              AppDialog.showToast(
                context,
                success
                    ? (t?.translate('order_cancelled_success') ?? 'Order Cancelled')
                    : (t?.translate('order_cancelled_fail') ?? 'Failed to Cancel Order'),
                isError: !success,
              );
            }
            return success;
          },
        ),
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime, BuildContext context) {
    final t = AppLocalizations.of(context);
    final difference = DateTime.now().difference(dateTime);
    if (difference.inMinutes < 1) return t?.translate('just_now') ?? 'Just Now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}${t?.translate('mins_ago') ?? 'M Ago'}';
    if (difference.inHours < 24) return '${difference.inHours}${t?.translate('hours_ago') ?? 'H Ago'}';
    return DateFormat('dd MMM').format(dateTime);
  }
}
