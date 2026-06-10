import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:my_shop/core/presentation/widgets/back_title_app_bar.dart';
import 'package:my_shop/core/localization/app_localizations.dart';
import '../../data/models/review_model.dart';
import '../../data/services/review_service.dart';
import '../widgets/review_card.dart';
import '../widgets/review_summary_widget.dart';
import '../widgets/review_skeleton.dart';

class ReviewsPage extends StatefulWidget {
  const ReviewsPage({super.key});

  @override
  State<ReviewsPage> createState() => _ReviewsPageState();
}

class _ReviewsPageState extends State<ReviewsPage> {
  final ReviewService _reviewService = ReviewService();
  final ScrollController _scrollController = ScrollController();
  
  ReviewSummaryModel? _summary;
  List<ReviewModel> _reviews = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      final summary = await _reviewService.getReviewSummary();
      final reviews = await _reviewService.getReviews(page: 1);
      
      if (mounted) {
        setState(() {
          _summary = summary;
          _reviews = reviews;
          _isLoading = false;
          _hasMore = reviews.length >= 10;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoadingMore && _hasMore) {
        _loadMoreReviews();
      }
    }
  }

  Future<void> _loadMoreReviews() async {
    setState(() => _isLoadingMore = true);
    try {
      final nextPage = _currentPage + 1;
      final newReviews = await _reviewService.getReviews(page: nextPage);
      
      if (mounted) {
        setState(() {
          _reviews.addAll(newReviews);
          _currentPage = nextPage;
          _isLoadingMore = false;
          _hasMore = newReviews.length >= 10;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: BackTitleAppBar(title: t?.translate('reviews') ?? 'Reviews'),
      body: _isLoading 
        ? const ReviewSkeleton()
        : _buildContent(),
    );
  }

  Widget _buildEmptyState(AppLocalizations? t) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: const BoxDecoration(
              color: Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              PhosphorIconsRegular.chatCenteredText,
              size: 40,
              color: Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            t?.translate('no_reviews_yet') ?? 'No Reviews Yet',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            t?.translate('no_reviews_desc') ??
                'Customer reviews will appear here once you receive them.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: const Color(0xFF64748B),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final t = AppLocalizations.of(context);
    return RefreshIndicator(
      onRefresh: _loadInitialData,
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _reviews.length + 1, // +1 for the summary or loader
        itemBuilder: (context, index) {
          if (index == 0) {
            return Column(
              children: [
                if (_summary != null) ReviewSummaryWidget(summary: _summary!),
                const SizedBox(height: 24),
                if (_reviews.isEmpty)
                  _buildEmptyState(t)
                else ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      t?.translate('recent_reviews') ?? 'Recent Reviews',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ],
            );
          }
          
          final reviewIndex = index - 1;
          if (reviewIndex < _reviews.length) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: ReviewCard(review: _reviews[reviewIndex]),
            );
          }

          // Bottom loading indicator
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: _hasMore 
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFED3973)),
                    ),
                  )
                : Text(
                    t?.translate('no_more_reviews') ?? 'No More Reviews',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: const Color(0xFF64748B),
                    ),
                  ),
            ),
          );
        },
      ),
    );
  }
}
