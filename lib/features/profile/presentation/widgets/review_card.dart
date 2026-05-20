import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:my_shop/core/utils/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../data/models/review_model.dart';
import '../../data/services/review_service.dart';

class ReviewCard extends StatefulWidget {
  final ReviewModel review;

  const ReviewCard({super.key, required this.review});

  @override
  State<ReviewCard> createState() => _ReviewCardState();
}

class _ReviewCardState extends State<ReviewCard>
    with SingleTickerProviderStateMixin {
  final ReviewService _reviewService = ReviewService();
  final TextEditingController _replyController = TextEditingController();
  final FocusNode _replyFocusNode = FocusNode();

  bool _isExpanded = false;
  bool _isReplyOpen = false;
  bool _isSending = false;
  String? _localReply;
  String? _selectedQuickReply;

  late AnimationController _replyAnimController;
  late Animation<double> _replyFadeAnim;
  late Animation<Offset> _replySlideAnim;

  static const List<String> _quickReplies = [
    'Thank you for the review! 🙏',
    'Glad you enjoyed it! 😊',
    'Hope to see you again! 👋',
    "We'll work to improve! 💪",
    'Your feedback means a lot! ❤️',
  ];

  @override
  void initState() {
    super.initState();
    _replyAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _replyFadeAnim = CurvedAnimation(
      parent: _replyAnimController,
      curve: Curves.easeOut,
    );
    _replySlideAnim = Tween<Offset>(
      begin: const Offset(0, -0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _replyAnimController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _replyAnimController.dispose();
    _replyController.dispose();
    _replyFocusNode.dispose();
    super.dispose();
  }

  String get _effectiveReply => _localReply ?? widget.review.reply ?? '';
  bool get _hasReply =>
      _localReply != null ||
      (widget.review.reply != null && widget.review.reply!.isNotEmpty);

  void _openReply() {
    setState(() => _isReplyOpen = true);
    _replyAnimController.forward(from: 0);
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _replyFocusNode.requestFocus();
    });
  }

  void _closeReply() {
    _replyAnimController.reverse().then((_) {
      if (mounted) {
        setState(() {
          _isReplyOpen = false;
          _selectedQuickReply = null;
          _replyController.clear();
        });
      }
    });
    _replyFocusNode.unfocus();
  }

  void _selectQuickReply(String text) {
    setState(() {
      if (_selectedQuickReply == text) {
        // Deselect
        _selectedQuickReply = null;
        _replyController.clear();
      } else {
        _selectedQuickReply = text;
        _replyController.text = text;
        _replyController.selection = TextSelection.fromPosition(
          TextPosition(offset: text.length),
        );
      }
    });
  }

  Future<void> _sendReply() async {
    final text = _replyController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSending = true);
    _replyFocusNode.unfocus();

    try {
      await _reviewService.replyReview(widget.review.id, text);
      if (mounted) {
        // Close the input panel, show the reply inline
        _replyAnimController.reverse().then((_) {
          if (mounted) {
            setState(() {
              _localReply = text;
              _isReplyOpen = false;
              _isSending = false;
              _selectedQuickReply = null;
              _replyController.clear();
            });
          }
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isSending = false);
    }
  }

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
          // Reply section
          if (_hasReply && !_isReplyOpen) ...[
            const SizedBox(height: 12),
            _buildReplyDisplay(),
          ] else if (!_hasReply) ...[
            const SizedBox(height: 12),
            if (!_isReplyOpen) _buildReplyButton(),
            if (_isReplyOpen)
              FadeTransition(
                opacity: _replyFadeAnim,
                child: SlideTransition(
                  position: _replySlideAnim,
                  child: _buildReplyInput(),
                ),
              ),
          ],
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
                  child: Image.network(widget.review.userProfileUrl!,
                      fit: BoxFit.cover),
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

        final text = widget.review.comment;
        int endIndex =
            tp.getOffsetBefore(tp
                        .getPositionForOffset(
                            Offset(constraints.maxWidth, tp.height))
                        .offset) ??
                text.length;
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

  // ─── Reply Button ────────────────────────────────────────────────────────────

  Widget _buildReplyButton() {
    return GestureDetector(
      onTap: _openReply,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE2E8F0)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            PhosphorIcon(
              PhosphorIconsRegular.arrowBendUpLeft,
              size: 15,
              color: AppColors.primary,
            ),
            const SizedBox(width: 6),
            Text(
              'Reply',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Reply Input Panel ───────────────────────────────────────────────────────

  Widget _buildReplyInput() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick reply chips label
          Text(
            'Quick Replies',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 8),
          // Chips — styled same as cuisine types
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _quickReplies.map((label) {
              final isSelected = _selectedQuickReply == label;
              return GestureDetector(
                onTap: () => _selectQuickReply(label),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    gradient:
                        isSelected ? AppColors.primaryGradient : null,
                    color: isSelected ? null : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? Colors.transparent
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isSelected)
                        const Padding(
                          padding: EdgeInsets.only(right: 5),
                          child: Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 13,
                          ),
                        ),
                      Text(
                        label,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          // Text field
          TextField(
            controller: _replyController,
            focusNode: _replyFocusNode,
            minLines: 2,
            maxLines: 4,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: const Color(0xFF1E293B),
            ),
            onChanged: (val) {
              // Deselect chip if text changed manually
              if (_selectedQuickReply != null &&
                  val != _selectedQuickReply) {
                setState(() => _selectedQuickReply = null);
              }
            },
            decoration: InputDecoration(
              hintText: 'Write your reply...',
              hintStyle: GoogleFonts.poppins(
                fontSize: 14,
                color: const Color(0xFFB0BEC5),
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide:
                    const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide:
                    const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                    color: AppColors.primary, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Cancel
              GestureDetector(
                onTap: _isSending ? null : _closeReply,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 9),
                  decoration: BoxDecoration(
                    border:
                        Border.all(color: const Color(0xFFE2E8F0)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Send
              GestureDetector(
                onTap: _isSending ? null : _sendReply,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 9),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _isSending
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white),
                          ),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.send_rounded,
                                color: Colors.white, size: 14),
                            const SizedBox(width: 6),
                            Text(
                              'Send',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Reply Display ───────────────────────────────────────────────────────────

  Widget _buildReplyDisplay() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 3,
                height: 14,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              ShaderMask(
                shaderCallback: (bounds) =>
                    AppColors.primaryGradient.createShader(bounds),
                child: Text(
                  'Your Response',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 11),
            child: Text(
              _effectiveReply,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: const Color(0xFF475569),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
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
