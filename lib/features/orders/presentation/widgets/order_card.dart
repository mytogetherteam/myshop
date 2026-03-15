import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../data/models/order_model.dart';
import '../screens/order_detail_screen.dart';
import 'status_progress_indicator.dart';

class OrderCard extends StatelessWidget {
  final OrderModel order;

  const OrderCard({super.key, required this.order});

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
          onTap: () => Navigator.push(
            context,
            CupertinoPageRoute(
              settings: RouteSettings(name: 'order_detail_${order.id}'),
              builder: (_) => OrderDetailScreen(order: order),
            ),
          ),
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
                        Text(
                          order.statusName,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFFED3A72),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      order.displayTotalAmount,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFED3A72),
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
                    const SizedBox(width: 4),
                    Icon(PhosphorIcons.moped(), size: 14, color: const Color(0xFFED3A72)),
                    const SizedBox(width: 4),
                    Text(
                      order.deliveryType == 'DELIVERY' ? 'Delivery' : 'Pickup',
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
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Customer requested cancellation',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFFE11D48),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Customer change their mind before preparation started',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: const Color(0xFFF43F5E),
            ),
          ),
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
          onPressed: () => Navigator.push(
            context,
            CupertinoPageRoute(
              settings: RouteSettings(name: 'order_detail_${order.id}'),
              builder: (_) => OrderDetailScreen(order: order),
            ),
          ),
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
    Color mainButtonColor = const Color(0xFFED3A72);
    Color mainButtonTextColor = Colors.white;
    bool isMainButtonEnabled = true;
    IconData? mainButtonIcon;

    switch (order.status) {
      case 'PAYMENT_UPLOADED':
        mainButtonText = 'Check Payment';
        break;
      case 'PAYMENT_SLIP_REQUESTED':
        mainButtonText = 'Waiting for payment';
        mainButtonColor = const Color(0xFFF1F5F9);
        mainButtonTextColor = const Color(0xFFD97706); // Amber/Orange as in image
        isMainButtonEnabled = false;
        mainButtonIcon = Icons.access_time_outlined;
        break;
      case 'PREPARING':
        mainButtonText = 'Picked Up by Rider';
        break;
      case 'ON_THE_WAY':
        mainButtonText = 'Delivered';
        break;
    }

    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFED3A72),
              side: const BorderSide(color: Color(0xFFFEE2E2)),
              backgroundColor: const Color(0xFFFFF1F2),
              minimumSize: const Size(0, 54),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: isMainButtonEnabled ? () => Navigator.push(
              context,
              CupertinoPageRoute(
                settings: RouteSettings(name: 'order_detail_${order.id}'),
                builder: (_) => OrderDetailScreen(order: order),
              ),
            ) : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: mainButtonColor,
              foregroundColor: mainButtonTextColor,
              disabledBackgroundColor: mainButtonColor,
              disabledForegroundColor: mainButtonTextColor,
              minimumSize: const Size(0, 54),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (mainButtonIcon != null) ...[
                  Icon(mainButtonIcon, size: 18),
                  const SizedBox(width: 8),
                ],
                Text(
                  mainButtonText,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
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
