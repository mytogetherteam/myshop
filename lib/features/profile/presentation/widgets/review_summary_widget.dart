import 'package:flutter/material.dart';
import 'package:my_shop/core/utils/app_colors.dart';
import 'package:my_shop/core/localization/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:intl/intl.dart';
import '../../data/models/review_model.dart';

class ReviewSummaryWidget extends StatelessWidget {
  final ReviewSummaryModel summary;

  const ReviewSummaryWidget({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
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
            t?.translate('customer_ratings_reviews') ?? 'Customer ratings & reviews',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),
          _buildAverageRating(context),
          const SizedBox(height: 24),
          _buildRatingDistribution(context),
        ],
      ),
    );
  }

  Widget _buildAverageRating(BuildContext context) {
    final t = AppLocalizations.of(context);
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
              t?.translate('out_of_5') ?? 'out of 5',
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
          t?.translate('ratings_label') != null
              ? '${_formatNumber(summary.totalRatings)} ${t?.translate('ratings_label')}'
              : '${_formatNumber(summary.totalRatings)} ratings',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _buildRatingDistribution(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Column(
      children: [5, 4, 3, 2, 1].map((star) {
        final count = summary.ratingDistribution[star] ?? 0;
        final percentage = summary.totalRatings > 0 ? count / summary.totalRatings : 0.0;
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              SizedBox(
                width: 70,
                child: Text(
                  t?.translate('stars_label') != null
                      ? '$star ${t?.translate('stars_label')}'
                      : '$star stars',
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
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
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
