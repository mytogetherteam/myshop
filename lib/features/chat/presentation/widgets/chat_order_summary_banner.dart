import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_shop/core/localization/app_localizations.dart';
import 'package:my_shop/core/utils/app_colors.dart';
import 'package:my_shop/features/orders/data/models/order_model.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

class ChatOrderSummaryBanner extends StatefulWidget {
  final OrderModel? order;
  final String? fallbackOrderNo;
  final bool isLoading;
  final VoidCallback? onRetry;
  final VoidCallback? onViewDetails;

  const ChatOrderSummaryBanner({
    super.key,
    required this.order,
    this.fallbackOrderNo,
    this.isLoading = false,
    this.onRetry,
    this.onViewDetails,
  });

  @override
  State<ChatOrderSummaryBanner> createState() => _ChatOrderSummaryBannerState();
}

class _ChatOrderSummaryBannerState extends State<ChatOrderSummaryBanner> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    if (widget.isLoading) {
      return _buildShell(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 12),
              Text(
                t?.translate('loading_order_info') ?? 'Loading order info...',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final order = widget.order;
    if (order == null) {
      return _buildShell(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.fallbackOrderNo != null
                      ? 'Order ${widget.fallbackOrderNo}'
                      : (t?.translate('order_info_unavailable') ??
                          'Order info unavailable'),
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ),
              if (widget.onRetry != null)
                TextButton(
                  onPressed: widget.onRetry,
                  child: Text(
                    t?.translate('retry') ?? 'Retry',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    final itemPreview = order.items
        .map((item) => '${item.quantity}× ${item.displayName}')
        .join(', ');

    return _buildShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      PhosphorIconsRegular.receipt,
                      size: 18,
                      color: Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.lastOrderNo.isNotEmpty
                              ? order.lastOrderNo
                              : 'Order #${order.id}',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _expanded
                              ? (order.statusLabel ?? order.status)
                              : '${order.items.length} ${t?.translate('items') ?? 'items'} · ${order.displayTotalAmount}',
                          maxLines: _expanded ? 1 : 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                        if (!_expanded && itemPreview.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            itemPreview,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: const Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(
                    _expanded
                        ? PhosphorIconsRegular.caretUp
                        : PhosphorIconsRegular.caretDown,
                    size: 16,
                    color: const Color(0xFF94A3B8),
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _StatusChip(label: order.statusLabel ?? order.status),
                  const SizedBox(height: 12),
                  ...order.items.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 28,
                            alignment: Alignment.topCenter,
                            child: Text(
                              '${item.quantity}×',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
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
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF1E293B),
                                  ),
                                ),
                                if (item.secondaryName != null)
                                  Text(
                                    item.secondaryName!,
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: const Color(0xFF94A3B8),
                                    ),
                                  ),
                                if (item.options.isNotEmpty)
                                  Text(
                                    item.options
                                        .map((opt) => opt.name)
                                        .join(', '),
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: const Color(0xFF64748B),
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
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF475569),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        t?.translate('total') ?? 'Total',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      Text(
                        order.displayTotalAmount,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  if (widget.onViewDetails != null) ...[
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: widget.onViewDetails,
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          t?.translate('view_details') ?? 'View Details',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildShell({required Widget child}) {
    return Material(
      color: Colors.white,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
        ),
        child: child,
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;

  const _StatusChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF475569),
        ),
      ),
    );
  }
}
