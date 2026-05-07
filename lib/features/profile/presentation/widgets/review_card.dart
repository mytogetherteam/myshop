import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:my_shop/core/utils/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../data/models/review_model.dart';

class ReviewCard extends StatefulWidget {
  final ReviewModel review;

  const ReviewCard({super.key, required this.review});

  @override
  State<ReviewCard> createState() => _ReviewCardState();
}

class _ReviewCardState extends State<ReviewCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 12),
          _buildRatingAndDate(),
          const SizedBox(height: 12),
          _buildComment(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: widget.review.userProfileUrl != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.network(widget.review.userProfileUrl!, fit: BoxFit.cover),
                )
              : Center(
                  child: PhosphorIcon(
                    PhosphorIconsRegular.user,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.review.userName,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E293B),
                ),
              ),
              // User review count removed as per requirement
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRatingAndDate() {
    return Row(
      children: [
        Row(
          children: List.generate(5, (index) {
            return PhosphorIcon(
              index < widget.review.rating.floor()
                  ? PhosphorIconsFill.star
                  : PhosphorIconsRegular.star,
              color: const Color(0xFFFFB800),
              size: 20,
            );
          }),
        ),
        const SizedBox(width: 8),
        Text(
          _getTimeAgo(widget.review.createdAt),
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _buildComment() {
    final textStyle = GoogleFonts.poppins(
      fontSize: 14,
      height: 1.5,
      color: const Color(0xFF1E293B),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final span = TextSpan(text: widget.review.comment, style: textStyle);
        final tp = TextPainter(
          text: span,
          maxLines: 3,
          textDirection: ui.TextDirection.ltr,
        );
        tp.layout(maxWidth: constraints.maxWidth);

        if (tp.didExceedMaxLines && !_isExpanded) {
          return _buildTruncatedComment(textStyle);
        } else {
          return Text(widget.review.comment, style: textStyle);
        }
      },
    );
  }

  Widget _buildTruncatedComment(TextStyle textStyle) {
    const seeMoreText = ' ..... see more';
    final seeMoreStyle = textStyle.copyWith(
      fontWeight: FontWeight.w600,
      color: const Color(0xFF64748B),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final tp = TextPainter(
          text: TextSpan(text: widget.review.comment, style: textStyle),
          maxLines: 3,
          textDirection: ui.TextDirection.ltr,
        );
        tp.layout(maxWidth: constraints.maxWidth);

        // This is a simplified way to find the truncation point
        // In a real app, we might need more complex logic with TextPainter.getPositionForOffset
        final text = widget.review.comment;
        int endIndex = tp.getOffsetBefore(tp.getPositionForOffset(Offset(constraints.maxWidth, tp.height)).offset) ?? text.length;
        
        // Adjust for " ..... see more" length roughly
        endIndex = (endIndex - 15).clamp(0, text.length);

        return RichText(
          text: TextSpan(
            children: [
              TextSpan(text: text.substring(0, endIndex), style: textStyle),
              WidgetSpan(
                alignment: PlaceholderAlignment.baseline,
                baseline: TextBaseline.alphabetic,
                child: GestureDetector(
                  onTap: () => setState(() => _isExpanded = true),
                  child: Text(seeMoreText, style: seeMoreStyle),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _getTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '$months month${months > 1 ? 's' : ''} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }
}
