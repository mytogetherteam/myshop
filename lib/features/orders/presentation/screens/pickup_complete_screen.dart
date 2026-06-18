import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_shop/core/localization/app_localizations.dart';
import 'package:my_shop/core/presentation/widgets/app_dialog.dart';
import 'package:my_shop/core/presentation/widgets/back_title_app_bar.dart';
import 'package:my_shop/core/presentation/widgets/primary_gradient_button.dart';
import 'package:my_shop/core/utils/app_colors.dart';
import 'package:my_shop/features/orders/data/models/order_model.dart';
import 'package:my_shop/features/orders/data/services/order_service.dart';
import 'package:my_shop/features/orders/presentation/screens/pickup_success_screen.dart';
import 'package:my_shop/features/orders/presentation/widgets/order_qr_scan_icon.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

/// Returns true when a scanned pickup order can go to [PickupCompleteScreen].
bool isPickupReadyForQrConfirm(OrderModel order) {
  if (!order.isPickupFulfillment) return false;
  return order.status.toUpperCase() == 'READY_FOR_PICKUP';
}

/// Shop-side screen after scanning a customer pickup QR. Tapping
/// [order_handed_over] marks the order as PICKED_UP on the backend.
class PickupCompleteScreen extends StatefulWidget {
  final OrderModel order;

  const PickupCompleteScreen({super.key, required this.order});

  @override
  State<PickupCompleteScreen> createState() => _PickupCompleteScreenState();
}

class _PickupCompleteScreenState extends State<PickupCompleteScreen> {
  bool _isSubmitting = false;

  Future<void> _confirmHandover() async {
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);
    HapticFeedback.lightImpact();

    final t = AppLocalizations.of(context);
    final result = await OrderService().confirmPickup(
      widget.order.id.toString(),
    );

    if (!mounted) return;

    final success = result['success'] == true;
    if (!success) {
      setState(() => _isSubmitting = false);
      AppDialog.showToast(
        context,
        result['details'] ??
            t?.translate('pickup_handover_failed') ??
            'Failed to mark order as picked up.',
        isError: true,
      );
      return;
    }

    final orderNo = widget.order.lastOrderNo.isNotEmpty
        ? widget.order.lastOrderNo
        : widget.order.id.toString();

    await Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => PickupSuccessScreen(
          orderNo: orderNo,
          customerName: widget.order.customerName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final order = widget.order;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: BackTitleAppBar(
        title: t?.translate('verify_pickup') ?? 'Verify Pickup',
        actions: const [
          OrderQrScanIcon(),
          SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HeaderCard(order: order, t: t),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFBBF7D0)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          PhosphorIconsRegular.info,
                          color: Color(0xFF16A34A),
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            t?.translate('pickup_verify_hint') ??
                                'Hand the order to the customer, then tap Order Handed Over below to complete the pickup.',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: const Color(0xFF166534),
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
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
                  ...order.items.map(
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
                            child: Text(
                              item.displayName,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF1E293B),
                              ),
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
                  if (order.waitingTimeMinutes > 0) ...[
                    _SummaryRow(
                      label: t?.translate('est_prep_time') ?? 'Est. Prep Time',
                      value:
                          '${order.waitingTimeMinutes} ${t?.translate('mins') ?? 'mins'}',
                    ),
                    const SizedBox(height: 8),
                  ],
                  _SummaryRow(
                    label: t?.translate('total') ?? 'Total',
                    value: order.displayTotalAmount,
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
              onPressed: _isSubmitting ? null : _confirmHandover,
              isLoading: _isSubmitting,
              height: 56,
              borderRadius: 14,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (!_isSubmitting) ...[
                    const Icon(
                      PhosphorIconsRegular.check,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                  ],
                  Text(
                    t?.translate('order_handed_over') ?? 'Order Handed Over',
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
            order.lastOrderNo.isNotEmpty
                ? order.lastOrderNo
                : 'MT-${order.id}',
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
