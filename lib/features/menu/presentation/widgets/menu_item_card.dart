import 'package:flutter/material.dart';
import 'package:my_shop/core/presentation/widgets/primary_gradient_switch.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/models/menu_item_model.dart';
import '../../../../core/presentation/widgets/global_modal.dart';
import '../../../../core/presentation/widgets/confirmation_sheet.dart';
import '../../../../core/presentation/widgets/status_badge.dart';
import '../../../../core/utils/price_formatter.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../../core/presentation/widgets/gradient_widgets.dart';

class MenuItemCard extends StatefulWidget {
  final MenuItemModel item;
  final ValueChanged<bool>? onAvailabilityChanged;
  final ValueChanged<bool>? onPublishStatusChanged;
  final VoidCallback? onTap;

  const MenuItemCard({
    super.key,
    required this.item,
    this.onAvailabilityChanged,
    this.onPublishStatusChanged,
    this.onTap,
  });

  @override
  State<MenuItemCard> createState() => _MenuItemCardState();
}

class _MenuItemCardState extends State<MenuItemCard> {
  late bool _inStock;
  late bool _isPublished;

  @override
  void initState() {
    super.initState();
    _inStock = widget.item.isAvailable;
    _isPublished = widget.item.publishStatus == 'PUBLISHED';
  }

  @override
  void didUpdateWidget(MenuItemCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.isAvailable != widget.item.isAvailable) {
      _inStock = widget.item.isAvailable;
    }
    if (oldWidget.item.publishStatus != widget.item.publishStatus) {
      _isPublished = widget.item.publishStatus == 'PUBLISHED';
    }
  }

  @override
  Widget build(BuildContext context) {
    final String status = widget.item.pendingStatus?.toUpperCase() ?? '';
    final bool isRejected = status == 'REJECTED';
    final bool isPending =
        status != '' &&
        status != 'APPROVED' &&
        status != 'PUBLISHED' &&
        !isRejected;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isRejected
              ? AppColors.errorLight
              : (isPending ? AppColors.outlineVariant : Colors.transparent),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: isPending ? null : widget.onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Item Image
                Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: widget.item.imageUrl != null
                            ? Image.network(
                                widget.item.imageUrl!,
                                width: 76,
                                height: 76,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    _buildPlaceholderImage(),
                              )
                            : _buildPlaceholderImage(),
                      ),
                    ),
                    if (widget.item.imageUrl != null)
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: const GradientWidget(
                            child: Icon(
                              Icons.refresh_rounded,
                              size: 10,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 16),
                // Content
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.item.displayName,
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.onSurface,
                                  ),
                                ),
                                if (widget.item.nameMm != null &&
                                    widget.item.nameMm!.isNotEmpty &&
                                    widget.item.nameMm != widget.item.nameEn)
                                  Text(
                                    widget.item.nameMm!,
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.onSurfaceVariant,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (isPending || isRejected)
                            StatusBadge(status: widget.item.pendingStatus),
                        ],
                      ),
                      if (isRejected && widget.item.rejectReason != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            widget.item.rejectReason!,
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: AppColors.error,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          if (widget.item.originalPrice != null &&
                              widget.item.price > 0 &&
                              widget.item.originalPrice! >
                                  widget.item.price) ...[
                            Text(
                              widget.item.originalPrice!.toFormattedPrice(
                                currency: widget.item.currency ?? '฿',
                              ),
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppColors.outline,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                            const SizedBox(width: 8),
                            GradientText(
                              widget.item.price.toFormattedPrice(
                                currency: widget.item.currency ?? '฿',
                              ),
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ] else if (widget.item.price > 0)
                            GradientText(
                              widget.item.price.toFormattedPrice(
                                currency: widget.item.currency ?? '฿',
                              ),
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            )
                          else if (widget.item.originalPrice != null &&
                              widget.item.originalPrice! > 0)
                            GradientText(
                              widget.item.originalPrice!.toFormattedPrice(
                                currency: widget.item.currency ?? '฿',
                              ),
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (!isPending && !isRejected) ...[
                  const SizedBox(width: 12),
                  _buildActionSwitches(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: 76,
      height: 76,
      color: AppColors.surfaceVariant,
      child: const Icon(Icons.fastfood_rounded, color: AppColors.outline, size: 28),
    );
  }

  Widget _buildActionSwitches() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _buildSwitch(
          value: _isPublished,
          label: _isPublished ? 'Published' : 'Draft',
          onChanged: (value) {
            GlobalModal.show(
              context: context,
              child: ConfirmationSheet(
                title: value ? 'Publish Item?' : 'Un-publish Item?',
                message: value
                    ? 'This item will be visible to customers on the app.'
                    : 'This item will be hidden from customers and saved as a draft.',
                confirmLabel: value ? 'Publish' : 'Un-publish',
                confirmColor: value
                    ? AppColors.primary
                    : AppColors.onSurfaceVariant,
                onConfirm: () {
                  setState(() => _isPublished = value);
                  widget.onPublishStatusChanged?.call(value);
                },
              ),
            );
          },
          activeColor: AppColors.primary,
        ),
        const SizedBox(height: 12),
        _buildSwitch(
          value: _inStock,
          label: _inStock ? 'Available' : 'Unavailable',
          onChanged: (value) {
            GlobalModal.show(
              context: context,
              child: ConfirmationSheet(
                title: value ? 'Mark as Available?' : 'Mark as Unavailable?',
                message: value
                    ? 'This item will be available for customers to order.'
                    : 'This item will be hidden or marked as unavailable for customers.',
                confirmLabel: value ? 'Mark Available' : 'Mark Unavailable',
                confirmColor: value
                    ? AppColors.primary
                    : AppColors.error,
                onConfirm: () {
                  setState(() => _inStock = value);
                  widget.onAvailabilityChanged?.call(value);
                },
              ),
            );
          },
          activeColor: AppColors.primary,
        ),
      ],
    );
  }

  Widget _buildSwitch({
    required bool value,
    required String label,
    required ValueChanged<bool> onChanged,
    required Color activeColor,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        PrimaryGradientSwitch(
          value: value,
          onChanged: onChanged,
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: value ? activeColor : AppColors.outline,
          ),
        ),
      ],
    );
  }
}
