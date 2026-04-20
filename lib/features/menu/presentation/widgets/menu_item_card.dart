import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/models/menu_item_model.dart';

class MenuItemCard extends StatefulWidget {
  final MenuItemModel item;
  final ValueChanged<bool>? onAvailabilityChanged;
  final VoidCallback? onTap;

  const MenuItemCard({
    super.key,
    required this.item,
    this.onAvailabilityChanged,
    this.onTap,
  });

  @override
  State<MenuItemCard> createState() => _MenuItemCardState();
}

class _MenuItemCardState extends State<MenuItemCard> {
  late bool _inStock;

  @override
  void initState() {
    super.initState();
    _inStock = widget.item.isAvailable;
  }

  @override
  void didUpdateWidget(MenuItemCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.isAvailable != widget.item.isAvailable) {
      _inStock = widget.item.isAvailable;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: InkWell(
              onTap: widget.onTap,
              splashColor: Colors.black.withValues(alpha: 0.02),
              highlightColor: Colors.black.withValues(alpha: 0.01),
              borderRadius: BorderRadius.circular(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Item Image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: widget.item.imageUrl != null
                        ? _buildImage(
                            widget.item.imageUrl!,
                            width: 72,
                            height: 72,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => _buildPlaceholderImage(),
                          )
                        : _buildPlaceholderImage(),
                  ),
                  const SizedBox(width: 16),
                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.item.displayName,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1E293B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
                            if (widget.item.originalPrice != null && widget.item.originalPrice! > widget.item.price) ...[
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
          const SizedBox(width: 16),
          _buildInStockSwitch(),
        ],
      ),
    );
  }

  Widget _buildImage(
    String url, {
    required double width,
    required double height,
    required BoxFit fit,
    required Widget Function(BuildContext, Object, StackTrace?) errorBuilder,
  }) {
    if (url.startsWith('http')) {
      return Image.network(
        url,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: errorBuilder,
      );
    } else {
      // Local file path
      return kIsWeb
          ? Image.network(url, width: width, height: height, fit: fit, errorBuilder: errorBuilder)
          : Image.file(File(url), width: width, height: height, fit: fit, errorBuilder: errorBuilder);
    }
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: 72,
      height: 72,
      color: const Color(0xFFF8FAFC),
      child: const Icon(Icons.fastfood, color: Color(0xFFCBD5E1), size: 28),
    );
  }

  Widget _buildInStockSwitch() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        SizedBox(
          height: 24,
          child: Transform.scale(
            scale: 0.65,
            child: Switch(
              value: _inStock,
              onChanged: (value) {
                setState(() => _inStock = value);
                widget.onAvailabilityChanged?.call(value);
              },
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              thumbColor: WidgetStateProperty.all(Colors.white),
              trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
              trackColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return const Color(0xFF22C55E); // Green
                }
                return const Color(0xFFEF4444); // Red
              }),
            ),
          ),
        ),
        Text(
          _inStock ? 'In stock' : 'Out of Stock',
          style: GoogleFonts.poppins(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: _inStock ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
          ),
        ),
      ],
    );
  }
}
