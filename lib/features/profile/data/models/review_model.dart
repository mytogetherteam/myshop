class ReviewModel {
  final String id;
  final String userName;
  final String? userProfileUrl;
  final double rating;
  final String comment;
  final DateTime createdAt;
  final bool isVerified;

  ReviewModel({
    required this.id,
    required this.userName,
    this.userProfileUrl,
    required this.rating,
    required this.comment,
    required this.createdAt,
    this.isVerified = false,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: json['id'] as String,
      userName: json['user_name'] as String,
      userProfileUrl: json['user_profile_url'] as String?,
      rating: (json['rating'] as num).toDouble(),
      comment: json['comment'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      isVerified: json['is_verified'] as bool? ?? false,
    );
  }
}

class ReviewSummaryModel {
  final double averageRating;
  final int totalRatings;
  final Map<int, int> ratingDistribution; // 1 to 5 stars

  ReviewSummaryModel({
    required this.averageRating,
    required this.totalRatings,
    required this.ratingDistribution,
  });

  factory ReviewSummaryModel.fromJson(Map<String, dynamic> json) {
    return ReviewSummaryModel(
      averageRating: (json['average_rating'] as num).toDouble(),
      totalRatings: json['total_ratings'] as int,
      ratingDistribution: (json['rating_distribution'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(int.parse(key), value as int),
      ),
    );
  }
}
