import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:my_shop/core/presentation/widgets/primary_gradient_switch.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../data/models/menu_item_model.dart';
import '../../../../core/presentation/widgets/global_modal.dart';
import '../../../../core/presentation/widgets/confirmation_sheet.dart';

import '../../../../core/utils/price_formatter.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../../core/presentation/widgets/gradient_widgets.dart';
import 'package:my_shop/core/localization/app_localizations.dart';

/// MenuItemCard — Full-page list style (no card shadow/border).
/// ════════════════════════════════════════════════════════════════
/// Design decisions:
///  • Edge-to-edge row with a thin Divider separator (like iOS Settings /
///    WhatsApp contact lists) — no floating card, no margin, no shadow.
///  • Image is a compact 56 × 56 rounded square on the LEFT.
///  • Name + Myanmar name + price occupy the CENTER flex area.
///  • Publish & Available toggles stay on the RIGHT in a compact column.
///  • Unavailable items are shown at 50 % opacity so the merchant can
///    quickly spot "dead" items without scanning status text.
///  • A subtle left-accent bar (2 px) uses the primary gradient when the
///    item is published & available — instant visual health cue.
///  • InkWell covers the whole row for a large, comfortable tap target.
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

  // ─── helpers ────────────────────────────────────────────────────────────
  bool get _isActive => _isPublished && _inStock;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Opacity(
      // Dim unavailable / draft items so active ones pop visually.
      opacity: _isActive ? 1.0 : 0.52,
      child: Material(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            widget.onTap?.call();
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Left accent bar ──────────────────────────────────
                    _buildAccentBar(),

                    // ── Thumbnail ────────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      child: _buildThumbnail(),
                    ),

                    // ── Name / price ─────────────────────────────────────
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: _buildInfo(),
                      ),
                    ),

                    // ── Action switches ──────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      child: _buildActionSwitches(),
                    ),
                  ],
                ),
              ),

              // ── Thin divider (edge-to-edge minus left accent bar) ────
              Padding(
                padding: const EdgeInsets.only(left: 2),
                child: Divider(
                  height: 1,
                  thickness: 0.6,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.07)
                      : const Color(0xFFE2E8F0),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── 2-px left accent bar ───────────────────────────────────────────────
  Widget _buildAccentBar() {
    return Container(
      width: 3,
      decoration: BoxDecoration(
        gradient: _isActive
            ? AppColors.primaryGradient
            : const LinearGradient(
                colors: [Colors.transparent, Colors.transparent],
              ),
      ),
    );
  }

  // ── 56 × 56 rounded thumbnail ──────────────────────────────────────────
  Widget _buildThumbnail() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: widget.item.imageUrl != null &&
              widget.item.imageUrl!.isNotEmpty
          ? CachedNetworkImage(
              imageUrl: widget.item.imageUrl!,
              width: 56,
              height: 56,
              memCacheWidth: 150,
              memCacheHeight: 150,
              fit: BoxFit.cover,
              placeholder: (_, __) => _buildPlaceholder(),
              errorWidget: (_, __, ___) => _buildPlaceholder(),
            )
          : _buildPlaceholder(),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 56,
      height: 56,
      color: AppColors.surfaceVariant,
      child: Icon(
        Icons.fastfood_rounded,
        color: AppColors.outline,
        size: 22,
      ),
    );
  }

  // ── Name + Myanmar name + price ────────────────────────────────────────
  Widget _buildInfo() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // English / primary name
        Text(
          widget.item.displayName,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.poppins(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).textTheme.bodyLarge?.color ??
                AppColors.onSurface,
            height: 1.3,
          ),
        ),

        // Myanmar name (secondary, only when different)
        if (widget.item.nameMm != null &&
            widget.item.nameMm!.isNotEmpty &&
            widget.item.nameMm != widget.item.nameEn) ...[
          const SizedBox(height: 1),
          Text(
            widget.item.nameMm!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 10.5,
              fontWeight: FontWeight.w400,
              color: Theme.of(context).textTheme.bodySmall?.color ??
                  AppColors.onSurfaceVariant,
              height: 1.3,
            ),
          ),
        ],

        const SizedBox(height: 5),

        // Price row
        _buildPriceRow(),
      ],
    );
  }

  Widget _buildPriceRow() {
    final hasDiscount = widget.item.originalPrice != null &&
        widget.item.price > 0 &&
        widget.item.originalPrice! > widget.item.price;

    if (hasDiscount) {
      return Row(
        children: [
          Text(
            widget.item.originalPrice!.toFormattedPrice(
              currency: widget.item.currency ?? 'K',
            ),
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w400,
              color: AppColors.outline,
              decoration: TextDecoration.lineThrough,
            ),
          ),
          const SizedBox(width: 6),
          GradientText(
            widget.item.price.toFormattedPrice(
              currency: widget.item.currency ?? 'K',
            ),
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      );
    }

    final displayPrice = widget.item.price > 0
        ? widget.item.price
        : widget.item.originalPrice;

    if (displayPrice != null && displayPrice > 0) {
      return GradientText(
        displayPrice.toFormattedPrice(
          currency: widget.item.currency ?? 'K',
        ),
        style: GoogleFonts.poppins(
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
        ),
      );
    }

    return const SizedBox.shrink();
  }

  // ── Publish + Available switches in a compact column ──────────────────
  Widget _buildActionSwitches() {
    final t = AppLocalizations.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _buildSwitch(
          value: _isPublished,
          label: _isPublished
              ? (t?.translate('published') ?? 'Published')
              : (t?.translate('draft') ?? 'Draft'),
          onChanged: (value) {
            HapticFeedback.lightImpact();
            GlobalModal.show(
              context: context,
              child: ConfirmationSheet(
                title: value
                    ? (t?.translate('publish_item') ?? 'Publish Item?')
                    : (t?.translate('unpublish_item') ?? 'Un-publish Item?'),
                message: value
                    ? (t?.translate('publish_item_desc') ??
                        'This item will be visible to customers on the app.')
                    : (t?.translate('unpublish_item_desc') ??
                        'This item will be hidden from customers and saved as a draft.'),
                confirmLabel: value
                    ? (t?.translate('publish') ?? 'Publish')
                    : (t?.translate('unpublish') ?? 'Un-publish'),
                confirmColor:
                    value ? AppColors.primary : AppColors.onSurfaceVariant,
                onConfirm: () {
                  setState(() => _isPublished = value);
                  widget.onPublishStatusChanged?.call(value);
                },
              ),
            );
          },
          activeColor: AppColors.primary,
        ),
        const SizedBox(height: 8),
        _buildSwitch(
          value: _inStock,
          label: _inStock
              ? (t?.translate('available') ?? 'Available')
              : (t?.translate('unavailable') ?? 'Unavailable'),
          onChanged: (value) {
            HapticFeedback.lightImpact();
            GlobalModal.show(
              context: context,
              child: ConfirmationSheet(
                title: value
                    ? (t?.translate('mark_available') ?? 'Mark as Available?')
                    : (t?.translate('mark_unavailable') ??
                        'Mark as Unavailable?'),
                message: value
                    ? (t?.translate('mark_available_desc') ??
                        'This item will be available for customers to order.')
                    : (t?.translate('mark_unavailable_desc') ??
                        'This item will be hidden or marked as unavailable for customers.'),
                confirmLabel: value
                    ? (t?.translate('mark_available_btn') ?? 'Mark Available')
                    : (t?.translate('mark_unavailable_btn') ??
                        'Mark Unavailable'),
                confirmColor: value ? AppColors.primary : AppColors.error,
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
        PrimaryGradientSwitch(value: value, onChanged: onChanged),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 8.5,
            fontWeight: FontWeight.w600,
            color: value ? activeColor : AppColors.outline,
          ),
        ),
      ],
    );
  }
}
