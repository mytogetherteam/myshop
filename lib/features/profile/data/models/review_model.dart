class ReviewModel {
  final String id;
  final String userName;
  final String? userProfileUrl;
  final double rating;
  final String comment;
  final DateTime createdAt;
  final bool isVerified;
  final String? reply;
  final DateTime? replyCreatedAt;

  ReviewModel({
    required this.id,
    required this.userName,
    this.userProfileUrl,
    required this.rating,
    required this.comment,
    required this.createdAt,
    this.isVerified = false,
    this.reply,
    this.replyCreatedAt,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    // Backend exposes the shop reply as `shopReply` / `shopRepliedAt`.
    // Older keys (`reply` / `replyCreatedAt`) are kept as a fallback.
    final replyText = (json['shopReply'] ?? json['reply']) as String?;
    final replyAt = json['shopRepliedAt'] ?? json['replyCreatedAt'];
    return ReviewModel(
      id: json['id'].toString(),
      userName: json['user']?['name'] ?? json['userName'] ?? 'Anonymous',
      userProfileUrl: json['userProfileUrl'] as String?,
      rating: (json['rating'] as num).toDouble(),
      comment: json['comment'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
      isVerified: json['isVerified'] as bool? ?? false,
      reply: (replyText != null && replyText.isEmpty) ? null : replyText,
      replyCreatedAt:
          replyAt != null ? DateTime.parse(replyAt as String) : null,
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
    final dist = json['ratingDistribution'] as Map<String, dynamic>;
    return ReviewSummaryModel(
      averageRating: (json['averageRating'] as num).toDouble(),
      totalRatings: json['totalRatings'] as int,
      ratingDistribution: dist.map(
        (key, value) => MapEntry(int.parse(key), value as int),
      ),
    );
  }
}
