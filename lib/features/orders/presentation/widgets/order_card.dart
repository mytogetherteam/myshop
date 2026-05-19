import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../data/models/order_model.dart';
import '../../data/services/order_service.dart';
import '../screens/orders_screen.dart';
import '../screens/order_detail_screen.dart';
import 'status_progress_indicator.dart';
import 'package:my_shop/core/presentation/widgets/animated_ellipsis_text.dart';
import 'package:my_shop/core/presentation/widgets/primary_gradient_button.dart';
import 'package:my_shop/core/presentation/widgets/gradient_widgets.dart';
import 'package:my_shop/core/presentation/widgets/app_dialog.dart';

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
                      _getTimeAgo(order.createdAt),
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (order.status == 'CANCELLED')
                  _buildCancellationBox()
                else
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 600),
                    child: StatusProgressIndicator(
                      key: ValueKey(order.status),
                      status: order.status,
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

  Widget _buildCancellationBox() {
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
                'Order Cancelled',
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
    bool isInformational = order.status == 'DELIVERED' || order.status == 'CANCELLED';
    
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
            if (result != null && result is String && context.mounted) {
              context.findAncestorStateOfType<OrdersScreenState>()?.switchToStatus(result);
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
            'View Details',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    String mainButtonText = 'View order';
    bool isMainButtonEnabled = true;
    IconData? mainButtonIcon;

    switch (order.status) {
      case 'PAYMENT_UPLOADED':
        mainButtonText = 'Check Payment';
        break;
      case 'CONFIRMED':
      case 'PAYMENT_SLIP_REQUESTED':
        mainButtonText = 'Waiting for payment';
        isMainButtonEnabled = false;
        mainButtonIcon = Icons.access_time_outlined;
        break;
      case 'PREPARING':
        mainButtonText = 'Picked Up by Rider';
        break;
      case 'ON_THE_WAY':
        mainButtonText = isDeliveryTab ? 'Check Delivery' : 'Delivered';
        break;
      case 'READY_FOR_PICKUP':
        mainButtonText = isDeliveryTab ? 'Check Delivery' : 'Mark as Delivered';
        break;
    }

    final bool canCancel = !isPaymentTab && 
                          order.status != 'CONFIRMED' && 
                          order.status != 'PREPARING' && 
                          order.status != 'ON_THE_WAY' &&
                          order.status != 'DELIVERED' &&
                          order.status != 'CANCELLED';

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
              child: const GradientText(
                'Cancel',
                style: TextStyle(
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
              if (result != null && result is String && context.mounted) {
                context.findAncestorStateOfType<OrdersScreenState>()?.switchToStatus(result);
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
                  Text(
                    mainButtonText,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Colors.white,
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
    final TextEditingController reasonController = TextEditingController();

    showModalBottomSheet(
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
                controller: reasonController,
                maxLines: 3,
                autofocus: true,
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
                      onPressed: () => Navigator.pop(context),
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
                      onPressed: () async {
                        final reason = reasonController.text.trim();
                        Navigator.pop(context); // Close bottom sheet
                        final success = await OrderService().cancelOrder(
                          order.id, 
                          reason.isEmpty ? null : reason
                        );
                        if (context.mounted) {
                          AppDialog.showToast(context, success ? 'Order cancelled' : 'Failed to cancel order', isError: !success);
                        }
                      },
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
  }

  String _getTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    return DateFormat('dd MMM').format(dateTime);
  }
}
