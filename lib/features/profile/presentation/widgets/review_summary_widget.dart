import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:intl/intl.dart';
import '../../data/models/review_model.dart';

class ReviewSummaryWidget extends StatelessWidget {
  final ReviewSummaryModel summary;

  const ReviewSummaryWidget({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border.symmetric(
          horizontal: BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Customer ratings & reviews',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),
          _buildAverageRating(),
          const SizedBox(height: 24),
          _buildRatingDistribution(),
        ],
      ),
    );
  }

  Widget _buildAverageRating() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              summary.averageRating.toStringAsFixed(1),
              style: GoogleFonts.poppins(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'out of 5',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(width: 8),
            Row(
              children: List.generate(5, (index) {
                return PhosphorIcon(
                  index < summary.averageRating.floor()
                      ? PhosphorIconsFill.star
                      : PhosphorIconsRegular.star,
                  color: const Color(0xFFFFB800),
                  size: 24,
                );
              }),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '${_formatNumber(summary.totalRatings)} ratings',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _buildRatingDistribution() {
    return Column(
      children: [5, 4, 3, 2, 1].map((star) {
        final count = summary.ratingDistribution[star] ?? 0;
        final percentage = summary.totalRatings > 0 ? count / summary.totalRatings : 0.0;
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              SizedBox(
                width: 50,
                child: Text(
                  '$star stars',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: const Color(0xFF1E293B),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: percentage,
                    minHeight: 8,
                    backgroundColor: const Color(0xFFE2E8F0),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFED3973)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 80,
                child: Text(
                  '${(percentage * 100).toInt()}% (${_formatNumber(count)})',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  String _formatNumber(int number) {
    return NumberFormat('#,###').format(number);
  }
}
