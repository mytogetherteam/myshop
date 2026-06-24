import 'package:flutter/material.dart';
import 'package:my_shop/core/utils/app_colors.dart';
import 'package:my_shop/core/localization/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:intl/intl.dart';
import 'package:my_shop/core/presentation/widgets/gradient_widgets.dart';
import '../../data/models/review_model.dart';

class ReviewSummaryWidget extends StatelessWidget {
  final ReviewSummaryModel summary;

  const ReviewSummaryWidget({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border.symmetric(
          horizontal: BorderSide(color: Theme.of(context).dividerColor, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t?.translate('customer_ratings_reviews') ?? 'Customer Ratings & Reviews',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          SizedBox(height: 16),
          _buildAverageRating(context),
          SizedBox(height: 24),
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
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            SizedBox(width: 8),
            Text(
              t?.translate('out_of_5') ?? 'Out of 5',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            SizedBox(width: 8),
            Row(
              children: List.generate(5, (index) {
                return GradientWidget(
                  child: PhosphorIcon(
                    index < summary.averageRating.floor()
                        ? PhosphorIconsFill.star
                        : PhosphorIconsRegular.star,
                    color: Colors.white,
                    size: 24,
                  ),
                );
              }),
            ),
          ],
        ),
        SizedBox(height: 4),
        Text(
          t?.translate('ratings_label') != null
              ? '${_formatNumber(summary.totalRatings)} ${t?.translate('ratings_label')}'
              : '${_formatNumber(summary.totalRatings)} ratings',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Theme.of(context).textTheme.bodySmall?.color,
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
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: Theme.of(context).dividerColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: percentage,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12),
              SizedBox(
                width: 80,
                child: Text(
                  '${(percentage * 100).toInt()}% (${_formatNumber(count)})',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodySmall?.color,
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