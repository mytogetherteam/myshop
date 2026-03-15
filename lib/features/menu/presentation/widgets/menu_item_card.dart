import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MenuItemCard extends StatefulWidget {
  final String title;
  final double originalPrice;
  final double discountedPrice;
  final String imageUrl;
  final bool initialInStock;

  const MenuItemCard({
    super.key,
    required this.title,
    required this.originalPrice,
    required this.discountedPrice,
    required this.imageUrl,
    this.initialInStock = true,
  });

  @override
  State<MenuItemCard> createState() => _MenuItemCardState();
}

class _MenuItemCardState extends State<MenuItemCard> {
  late bool _inStock;

  @override
  void initState() {
    super.initState();
    _inStock = widget.initialInStock;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Item Image
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(
              widget.imageUrl,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 80,
                height: 80,
                color: Colors.grey[200],
                child: const Icon(Icons.fastfood, color: Colors.grey, size: 30),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Content
          Expanded(
            child: SizedBox(
              height: 80, // Matches image height for alignment
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          widget.title,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1E293B),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textHeightBehavior: const TextHeightBehavior(
                            applyHeightToFirstAscent: false,
                          ),
                        ),
                      ),
                      _buildInStockSwitch(),
                    ],
                  ),
                  Text(
                    '${widget.originalPrice.toInt()}',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFED3A72),
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

  Widget _buildInStockSwitch() {
    return SizedBox(
      width: 60, // Fixed width to prevent layout jumps
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Transform.scale(
            scale: 0.75, // Slightly smaller switch
            child: SizedBox(
              height: 32,
              child: Switch(
                value: _inStock,
                onChanged: (value) => setState(() => _inStock = value),
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
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 9, // Slightly smaller text
              fontWeight: FontWeight.w500,
              color: _inStock ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
            ),
          ),
        ],
      ),
    );
  }
}
