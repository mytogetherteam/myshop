import 'dart:async';
import '../models/review_model.dart';

class ReviewService {
  Future<ReviewSummaryModel> getReviewSummary() async {
    // Mock latency
    await Future.delayed(const Duration(seconds: 1));
    
    return ReviewSummaryModel(
      averageRating: 4.6,
      totalRatings: 9615,
      ratingDistribution: {
        5: 7971,
        4: 861,
        3: 241,
        2: 80,
        1: 462,
      },
    );
  }

  Future<List<ReviewModel>> getReviews({int page = 1, int limit = 10}) async {
    // Mock latency
    await Future.delayed(const Duration(seconds: 1));

    final startTime = DateTime.now().subtract(const Duration(days: 60));
    
    return List.generate(limit, (index) {
      final id = ((page - 1) * limit + index).toString();
      final rating = (index % 5 == 0) ? 4.0 : 5.0;
      final isLongText = index % 3 == 0;
      
      return ReviewModel(
        id: id,
        userName: 'Customer $id',
        rating: rating,
        comment: isLongText 
            ? 'I recently needed some help setting up my online account, and the support I received was thorough and efficient. It only took one interaction to answer all my questions, and they provided me with additional help articles to reference in the future! I\'ll definitely recommend their services.'
            : 'Great service and quality products! Highly recommended.',
        createdAt: startTime.add(Duration(days: index)),
        isVerified: true,
      );
    });
  }
}
