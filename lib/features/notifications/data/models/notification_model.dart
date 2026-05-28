import 'package:intl/intl.dart';

enum NotificationMainType {
  order,
  unknown;

  static NotificationMainType fromString(String? value) {
    if (value == null) return NotificationMainType.unknown;
    switch (value.toUpperCase()) {
      case 'ORDER':
        return NotificationMainType.order;
      default:
        return NotificationMainType.unknown;
    }
  }
}

enum NotificationSubType {
  pendingOrder,
  canceledOrder,
  paymentSlipRequestOrder,
  awaitingApprovalOrder,
  paymentVerifiedOrder,
  cookingOrder,
  onTheWayOrder,
  deliveredOrder,
  revisedOrder,
  unknown;

  static NotificationSubType fromString(String? value) {
    if (value == null) return NotificationSubType.unknown;
    switch (value.toUpperCase()) {
      case 'PENDING_ORDER':
        return NotificationSubType.pendingOrder;
      case 'CANCELED_ORDER':
        return NotificationSubType.canceledOrder;
      case 'PAYMENT_SLIP_REQUEST_ORDER':
        return NotificationSubType.paymentSlipRequestOrder;
      case 'AWAITING_APPROVAL_ORDER':
        return NotificationSubType.awaitingApprovalOrder;
      case 'PAYMENT_VERIFIED_ORDER':
        return NotificationSubType.paymentVerifiedOrder;
      case 'COOKING_ORDER':
        return NotificationSubType.cookingOrder;
      case 'ON_THE_WAY_ORDER':
        return NotificationSubType.onTheWayOrder;
      case 'DELIVERED_ORDER':
        return NotificationSubType.deliveredOrder;
      case 'REVISED_ORDER':
        return NotificationSubType.revisedOrder;
      default:
        return NotificationSubType.unknown;
    }
  }

  bool get isNewOrder => this == NotificationSubType.pendingOrder;
  bool get isOrderRelated => this != NotificationSubType.unknown;
}

class NotificationModel {
  final int id;
  final String title;
  final String message;
  final NotificationMainType mainType;
  final NotificationSubType subType;
  final int? orderId;
  final Map<String, dynamic>? data;
  final DateTime createdAt;
  final bool isRead;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.mainType,
    required this.subType,
    this.orderId,
    this.data,
    required this.createdAt,
    required this.isRead,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as int? ?? 0,
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      mainType: NotificationMainType.fromString(json['mainType']?.toString()),
      subType: NotificationSubType.fromString(json['subType']?.toString()),
      orderId: json['orderId'] as int?,
      data: json['data'] is Map
          ? Map<String, dynamic>.from(json['data'] as Map)
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString())
          : DateTime.now(),
      isRead: json['isRead'] as bool? ?? false,
    );
  }

  String get displayTitle => title;
  String get displayBody => message;

  /// Legacy aliases used by notification_page.
  String get body => message;

  String get timeAgo {
    final difference = DateTime.now().difference(createdAt);
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    return DateFormat('dd MMM').format(createdAt);
  }

  /// Legacy compatibility for notification_page deep links.
  NotificationType get type {
    if (subType.isNewOrder) return NotificationType.newOrder;
    if (subType == NotificationSubType.canceledOrder) {
      return NotificationType.orderStatus;
    }
    return NotificationType.orderStatus;
  }

  int? get referenceId => orderId;
}

/// Legacy enum kept for notification_page icon routing.
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

class NotificationListResponse {
  final List<NotificationModel> items;
  final int totalCount;
  final int totalPages;
  final int size;
  final int page;

  NotificationListResponse({
    required this.items,
    required this.totalCount,
    required this.totalPages,
    required this.size,
    required this.page,
  });

  /// Legacy alias.
  List<NotificationModel> get content => items;
  int get number => page;
  bool get isEmpty => items.isEmpty;

  factory NotificationListResponse.fromJson(Map<String, dynamic> json) {
    final List<dynamic> rawItems = json['items'] ?? json['content'] ?? [];
    return NotificationListResponse(
      items: rawItems
          .map((e) => NotificationModel.fromJson(
                Map<String, dynamic>.from(e as Map),
              ))
          .toList(),
      totalCount: json['totalCount'] as int? ?? json['totalElements'] as int? ?? 0,
      totalPages: json['totalPages'] as int? ?? 0,
      size: json['size'] as int? ?? 20,
      page: json['page'] as int? ?? json['number'] as int? ?? 0,
    );
  }
}
