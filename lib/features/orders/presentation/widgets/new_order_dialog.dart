import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_shop/features/orders/data/models/order_model.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'dart:async';
import 'package:my_shop/core/network/websocket_service.dart';
import 'package:my_shop/core/presentation/widgets/primary_gradient_button.dart';
import 'package:my_shop/features/orders/data/services/order_service.dart';
import 'package:my_shop/core/notifications/notification_service.dart';

class NewOrderDialog extends StatefulWidget {
  final OrderModel order;
  final VoidCallback onViewOrder;

  const NewOrderDialog({
    super.key,
    required this.order,
    required this.onViewOrder,
  });

  @override
  State<NewOrderDialog> createState() => _NewOrderDialogState();
}

class _NewOrderDialogState extends State<NewOrderDialog> {
  StreamSubscription? _wsSubscription;

  @override
  void initState() {
    super.initState();
    _wsSubscription = WebSocketService().orderUpdates.listen((event) {
      final orderId = event['orderId']?.toString() ?? event['order']?['id']?.toString();
      final status = event['order']?['status']?.toString() ?? event['status']?.toString();
      final type = event['type']?.toString();
      
      if (orderId == widget.order.id.toString()) {
        if (type == 'ORDER_ACKNOWLEDGED' || status?.toUpperCase() == 'CANCELED') {
          if (mounted) {
            NotificationService.stopGlobalAlert();
            NotificationService().cancelNotification(99999);
            Navigator.of(context).maybePop();
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _wsSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      clipBehavior: Clip.antiAlias,
      insetPadding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              Container(
                height: 110,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFF06292), Color(0xFFFF8A65)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Opacity(
                  opacity: 0.15,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (i) => Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(8, (j) => Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Icon(
                          _getFoodIcon(i * 8 + j),
                          color: Theme.of(context).cardColor,
                          size: 20,
                        ),
                      )),
                    )),
                  ),
                ),
              ),
              Positioned(
                bottom: -35,
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Center(
                    child: _RingingBell(),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 45),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                Text(
                  'New Order Received!',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '#${widget.order.lastOrderNo}',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Just now',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                      ),
                    ),
                    SizedBox(width: 8),
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Color(0xFFCBD5E1),
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(
                      widget.order.isDeliveryFulfillment
                          ? PhosphorIconsRegular.moped
                          : PhosphorIconsRegular.shoppingBag,
                      size: 16,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                    SizedBox(width: 4),
                    Text(
                      widget.order.isDeliveryFulfillment ? 'Delivery' : 'Pickup',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 24),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.25,
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemCount: widget.order.items.length,
                    itemBuilder: (context, index) {
                      final item = widget.order.items[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 20,
                              child: Text(
                                '${item.quantity}',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Theme.of(context).textTheme.bodySmall?.color,
                                ),
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                item.displayName,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Theme.of(context).textTheme.bodyLarge?.color,
                                ),
                              ),
                            ),
                            SizedBox(width: 12),
                            Text(
                              item.displayPrice,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Theme.of(context).textTheme.bodyMedium?.color,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(color: Theme.of(context).dividerColor.withValues(alpha: 0.3), thickness: 1.5),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        widget.order.deliveryType == 'NORMAL' 
                            ? 'Est Total' 
                            : 'Total',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                    ),
                    Text(
                      widget.order.displayTotalAmount,
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFED3973),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 24),
                PrimaryGradientButton(
                  onPressed: () {
                    OrderService().acknowledgeOrder(widget.order.id.toString());
                    widget.onViewOrder();
                  },
                  text: 'View Order',
                  height: 56,
                  borderRadius: 16,
                ),
                SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getFoodIcon(int index) {
    const icons = [
      PhosphorIconsRegular.coffee,
      PhosphorIconsRegular.pizza,
      PhosphorIconsRegular.hamburger,
      PhosphorIconsRegular.cookingPot,
      PhosphorIconsRegular.cookie,
      PhosphorIconsRegular.iceCream,
      PhosphorIconsRegular.egg,
      PhosphorIconsRegular.brandy,
    ];
    return icons[index % icons.length];
  }
}

class _RingingBell extends StatefulWidget {
  const _RingingBell();

  @override
  State<_RingingBell> createState() => _RingingBellState();
}

class _RingingBellState extends State<_RingingBell> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: -0.15, end: 0.15).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.rotate(
          angle: _animation.value,
          child: Icon(
            PhosphorIconsFill.bell,
            color: Color(0xFFED3973),
            size: 32,
          ),
        );
      },
    );
  }
}
