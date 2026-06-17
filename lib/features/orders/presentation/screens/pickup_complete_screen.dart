import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_shop/core/localization/app_localizations.dart';
import 'package:my_shop/core/presentation/widgets/app_dialog.dart';
import 'package:my_shop/core/presentation/widgets/back_title_app_bar.dart';
import 'package:my_shop/core/presentation/widgets/primary_gradient_button.dart';
import 'package:my_shop/core/utils/app_colors.dart';
import 'package:my_shop/features/orders/data/models/order_model.dart';
import 'package:my_shop/features/orders/data/services/order_service.dart';
import 'package:my_shop/features/orders/presentation/screens/pickup_success_screen.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

/// Lightweight confirmation screen shown after scanning a pickup order QR.
class PickupCompleteScreen extends StatefulWidget {
  final OrderModel order;

  const PickupCompleteScreen({super.key, required this.order});

  @override
  State<PickupCompleteScreen> createState() => _PickupCompleteScreenState();
}

class _PickupCompleteScreenState extends State<PickupCompleteScreen> {
  bool _isSubmitting = false;

  OrderModel get _order => widget.order;

  Future<void> _confirmPickup() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    final result = await OrderService().confirmPickup(_order.id.toString());
    if (!mounted) return;

    final success = result['success'] == true;
    if (!success) {
      setState(() => _isSubmitting = false);
      AppDialog.showToast(
        context,
        result['details']?.toString() ??
            (AppLocalizations.of(context)?.translate('operation_failed') ??
                'Operation failed. Please try again.'),
        isError: true,
      );
      return;
    }

    await Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => PickupSuccessScreen(
          orderNo: _order.lastOrderNo,
          customerName: _order.customerName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: BackTitleAppBar(
        title: t?.translate('confirm_pickup') ?? 'Confirm Pickup',
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HeaderCard(order: _order, t: t),
                  const SizedBox(height: 16),
                  Text(
                    t?.translate('items') ?? 'Items',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ..._order.items.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 32,
                            child: Text(
                              '${item.quantity}×',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF475569),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.displayName,
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF1E293B),
                                  ),
                                ),
                                if (item.specialInstructions != null &&
                                    item.specialInstructions!.isNotEmpty)
                                  Text(
                                    '${t?.translate('note') ?? 'Note'}: ${item.specialInstructions}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic,
                                      color: const Color(0xFF64748B),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Text(
                            item.displayPrice,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Divider(height: 24, color: Color(0xFFE2E8F0)),
                  if (_order.deliveryFee > 0) ...[
                    _SummaryRow(
                      label: t?.translate('delivery_fee') ?? 'Delivery Fee',
                      value: _order.displayDeliveryFee,
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (_order.waitingTimeMinutes > 0) ...[
                    _SummaryRow(
                      label: t?.translate('est_prep_time') ?? 'Est. Prep Time',
                      value:
                          '${_order.waitingTimeMinutes} ${t?.translate('mins') ?? 'mins'}',
                    ),
                    const SizedBox(height: 8),
                  ],
                  _SummaryRow(
                    label: t?.translate('total') ?? 'Total',
                    value: _order.displayTotalAmount,
                    emphasized: true,
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Colors.black.withValues(alpha: 0.05)),
              ),
            ),
            child: PrimaryGradientButton(
              onPressed: _isSubmitting ? null : _confirmPickup,
              isLoading: _isSubmitting,
              height: 56,
              borderRadius: 14,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    PhosphorIconsRegular.shoppingBag,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    t?.translate('confirm_pickup') ?? 'Confirm Pickup',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
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
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final OrderModel order;
  final AppLocalizations? t;

  const _HeaderCard({required this.order, required this.t});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDF2F8),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  t?.translate('pickup') ?? 'Pickup',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                order.statusLabel ?? order.status,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'MT-${order.lastOrderNo}',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            order.customerName,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool emphasized;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: emphasized ? 15 : 13,
            fontWeight: emphasized ? FontWeight.w600 : FontWeight.w500,
            color: emphasized ? const Color(0xFF1E293B) : const Color(0xFF64748B),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: emphasized ? 16 : 13,
            fontWeight: emphasized ? FontWeight.w700 : FontWeight.w500,
            color: emphasized ? AppColors.primary : const Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }
}
