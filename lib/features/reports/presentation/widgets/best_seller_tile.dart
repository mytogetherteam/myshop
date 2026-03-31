import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BestSellerTile extends StatefulWidget {
  final int rank;
  final String name;
  final int soldCount;
  final double progress; // 0.0 to 1.0
  final bool isTopThree;

  const BestSellerTile({
    super.key,
    required this.rank,
    required this.name,
    required this.soldCount,
    required this.progress,
    this.isTopThree = false,
  });

  @override
  State<BestSellerTile> createState() => _BestSellerTileState();
}

class _BestSellerTileState extends State<BestSellerTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    // Stagger by rank so bars appear one after another
    Future.delayed(
      Duration(milliseconds: 80 + (widget.rank - 1) * 120),
      () {
        if (mounted) _controller.forward();
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    widget.rank.toString(),
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF1E293B),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.name,
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF1E293B),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Text(
                "${widget.soldCount} sold",
                style: GoogleFonts.poppins(
                  color: const Color(0xFF94A3B8),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 6,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(3),
            ),
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, _) {
                return FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor:
                      (widget.progress.clamp(0.0, 1.0) * _animation.value),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: widget.isTopThree
                            ? [
                                const Color(0xFFED3A72),
                                const Color(0xFFFBB042),
                              ]
                            : [
                                const Color(0xFF94A3B8),
                                const Color(0xFFCBD5E1),
                              ],
                      ),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
