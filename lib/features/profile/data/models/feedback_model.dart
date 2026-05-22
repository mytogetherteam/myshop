class FeedbackModel {
  final int id;
  final String description;
  final DateTime createdAt;

  FeedbackModel({
    required this.id,
    required this.description,
    required this.createdAt,
  });

  factory FeedbackModel.fromJson(Map<String, dynamic> json) {
    return FeedbackModel(
      id: json['id'] as int,
      description: json['description'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
