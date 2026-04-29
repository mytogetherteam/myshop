import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/models/menu_item_model.dart';
import '../../../../core/presentation/widgets/global_modal.dart';
import '../../../../core/presentation/widgets/confirmation_sheet.dart';
import '../../../../core/presentation/widgets/status_badge.dart';

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
    final bool isPending = widget.item.id == 0 ||
        widget.item.pendingStatus == 'PENDING_APPROVAL' ||
        widget.item.pendingStatus == 'PENDING';
    final bool isRejected = widget.item.pendingStatus == 'REJECTED';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: InkWell(
              onTap: isPending ? null : widget.onTap,
              splashColor: Colors.black.withValues(alpha: 0.02),
              highlightColor: Colors.black.withValues(alpha: 0.01),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: isPending || isRejected ? const EdgeInsets.all(8) : EdgeInsets.zero,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: isRejected ? const Color(0xFFFEF2F2).withValues(alpha: 0.5) : (isPending ? const Color(0xFFF8FAFC) : Colors.transparent),
                  border: Border.all(
                    color: isRejected ? const Color(0xFFEF4444).withValues(alpha: 0.3) : (isPending ? const Color(0xFFE2E8F0) : Colors.transparent),
                    width: (isRejected || isPending) ? 1 : 0,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Item Image
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: widget.item.imageUrl != null
                              ? Image.network(
                                  widget.item.imageUrl!,
                                  width: 72,
                                  height: 72,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      _buildPlaceholderImage(),
                                )
                              : _buildPlaceholderImage(),
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
                                  BoxShadow(color: Colors.black12, blurRadius: 4),
                                ],
                              ),
                              child: const Icon(
                                Icons.refresh_rounded,
                                size: 12,
                                color: Color(0xFFED3A72),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    // Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              Text(
                                widget.item.displayName,
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF1E293B),
                                ),
                              ),
                              if (isPending)
                                const StatusBadge(status: 'PENDING_APPROVAL')
                              else if (isRejected)
                                const StatusBadge(status: 'REJECTED'),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.item.displayDescription,
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w400,
                              color: const Color(0xFF94A3B8),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              if (widget.item.originalPrice != null &&
                                  widget.item.originalPrice! >
                                      widget.item.price) ...[
                                Text(
                                  '${widget.item.originalPrice!.toInt()} THB',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF94A3B8),
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                              Text(
                                '${widget.item.price.toInt()} THB',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFFED3A72),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (!isPending && !isRejected) ...[
            const SizedBox(width: 16),
            _buildActionSwitches(),
          ],
        ],
      ),
    );

  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: 72,
      height: 72,
      color: const Color(0xFFF8FAFC),
      child: const Icon(Icons.fastfood, color: Color(0xFFCBD5E1), size: 28),
    );
  }


  Widget _buildActionSwitches() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
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
                confirmColor:
                    value ? const Color(0xFFED3A72) : const Color(0xFF64748B),
                onConfirm: () {
                  setState(() => _isPublished = value);
                  widget.onPublishStatusChanged?.call(value);
                },
              ),
            );
          },
          activeColor: const Color(0xFFED3A72),
        ),
        const SizedBox(height: 12),
        _buildSwitch(
          value: _inStock,
          label: _inStock ? 'In stock' : 'Out of Stock',
          onChanged: (value) {
            GlobalModal.show(
              context: context,
              child: ConfirmationSheet(
                title: value ? 'Mark as In Stock?' : 'Mark as Out of Stock?',
                message: value
                    ? 'This item will be available for customers to order.'
                    : 'This item will be hidden or marked as unavailable for customers.',
                confirmLabel: value ? 'Mark In Stock' : 'Mark Out of Stock',
                confirmColor:
                    value ? const Color(0xFFED3A72) : const Color(0xFFEF4444),
                onConfirm: () {
                  setState(() => _inStock = value);
                  widget.onAvailabilityChanged?.call(value);
                },
              ),
            );
          },
          activeColor: const Color(0xFFED3A72),
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
        SizedBox(
          height: 24,
          child: Transform.scale(
            scale: 0.8,
            child: Switch(
              value: value,
              onChanged: onChanged,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              activeThumbColor: Colors.white,
              activeTrackColor: activeColor,
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: const Color(0xFFE2E8F0),
              trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: value ? activeColor : const Color(0xFF94A3B8),
          ),
        ),
      ],
    );
  }

}
