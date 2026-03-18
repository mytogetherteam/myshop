import 'package:intl/intl.dart';

enum NotificationType {
  orderStatus,
  newOrder,
  urgentPending,
  unknown;

  static NotificationType fromString(String? value) {
    if (value == null) return NotificationType.unknown;
    try {
      return NotificationType.values.firstWhere(
        (e) => e.name.toUpperCase() == value.toUpperCase(),
        orElse: () => NotificationType.unknown,
      );
    } catch (_) {
      return NotificationType.unknown;
    }
  }
}

class NotificationModel {
  final int id;
  final String title;
  final String body;
  final String? titleMm;
  final String? bodyMm;
  final NotificationType type;
  final int? referenceId;
  final String? imageUrl;
  final DateTime sentAt;
  final DateTime? readAt;
  final bool isRead;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    this.titleMm,
    this.bodyMm,
    required this.type,
    this.referenceId,
    this.imageUrl,
    required this.sentAt,
    this.readAt,
    required this.isRead,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ?? 0,
      title: json['titleEn'] ?? json['title'] ?? '',
      body: json['bodyEn'] ?? json['body'] ?? '',
      titleMm: json['titleMm'],
      bodyMm: json['bodyMm'],
      type: NotificationType.fromString(json['type']),
      referenceId: json['referenceId'],
      imageUrl: json['imageUrl'],
      sentAt: DateTime.parse(json['sentAt'] ?? DateTime.now().toIso8601String()),
      readAt: json['readAt'] != null ? DateTime.parse(json['readAt']) : null,
      isRead: json['read'] ?? false,
    );
  }

  String get displayTitle => titleMm != null && titleMm!.isNotEmpty ? '$title\n$titleMm' : title;
  String get displayBody => bodyMm != null && bodyMm!.isNotEmpty ? '$body\n$bodyMm' : body;
  
  String get timeAgo {
    final difference = DateTime.now().difference(sentAt);
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    return DateFormat('dd MMM').format(sentAt);
  }
}

class NotificationListResponse {
  final List<NotificationModel> content;
  final int totalPages;
  final int totalElements;
  final int size;
  final int number;
  final bool isEmpty;

  NotificationListResponse({
    required this.content,
    required this.totalPages,
    required this.totalElements,
    required this.size,
    required this.number,
    required this.isEmpty,
  });

  factory NotificationListResponse.fromJson(Map<String, dynamic> json) {
    final List<dynamic> content = json['content'] ?? [];
    return NotificationListResponse(
      content: content.map((e) => NotificationModel.fromJson(e)).toList(),
      totalPages: json['totalPages'] ?? 0,
      totalElements: json['totalElements'] ?? 0,
      size: json['size'] ?? 0,
      number: json['number'] ?? 0,
      isEmpty: json['empty'] ?? true,
    );
  }
}
