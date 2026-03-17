import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class RevenueCard extends StatelessWidget {
  final String revenue;
  final String trend;
  final String orders;
  final String avgOrder;
  final String cancelled;

  const RevenueCard({
    super.key,
    required this.revenue,
    required this.trend,
    required this.orders,
    required this.avgOrder,
    required this.cancelled,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFFED3A72), Color(0xFFFBB042)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFED3A72).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background food icons
          Positioned(
            right: -10,
            bottom: 40,
            child: Opacity(
              opacity: 0.15,
              child: PhosphorIcon(
                PhosphorIconsFill.bowlFood,
                size: 100,
                color: Colors.white,
              ),
            ),
          ),
          Positioned(
            right: -20,
            top: -10,
            child: Opacity(
              opacity: 0.15,
              child: PhosphorIcon(
                PhosphorIconsFill.hamburger,
                size: 80,
                color: Colors.white,
              ),
            ),
          ),
          Positioned(
            right: 10,
            bottom: -20,
            child: Opacity(
              opacity: 0.15,
              child: PhosphorIcon(
                PhosphorIconsFill.brandy,
                size: 90,
                color: Colors.white,
              ),
            ),
          ),
          
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Today's Revenue",
                style: GoogleFonts.poppins(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "฿ $revenue",
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                   const PhosphorIcon(
                    PhosphorIconsRegular.arrowUp,
                    size: 14,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    trend,
                    style: GoogleFonts.poppins(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatItem("Orders", orders),
                  _buildStatItem("Avg Order", "฿ $avgOrder"),
                  _buildStatItem("Cancelled", cancelled),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
