class SalesSummaryModel {
  final double revenue;
  final String revenueTrend;
  final int orders;
  final double avgOrderValue;
  final int cancelledCount;
  final int itemsSold;
  final int avgWaitTime;

  SalesSummaryModel({
    required this.revenue,
    required this.revenueTrend,
    required this.orders,
    required this.avgOrderValue,
    required this.cancelledCount,
    required this.itemsSold,
    required this.avgWaitTime,
  });

  factory SalesSummaryModel.fromJson(Map<String, dynamic> json) {
    return SalesSummaryModel(
      revenue: (json['revenue'] as num).toDouble(),
      revenueTrend: json['revenueTrend'] as String,
      orders: json['orders'] as int,
      avgOrderValue: (json['avgOrderValue'] as num).toDouble(),
      cancelledCount: json['cancelledCount'] as int,
      itemsSold: json['itemsSold'] as int,
      avgWaitTime: json['avgWaitTime'] as int,
    );
  }
}

class BestSellerModel {
  final int id;
  final String name;
  final int soldCount;
  final String? imageUrl;

  BestSellerModel({
    required this.id,
    required this.name,
    required this.soldCount,
    this.imageUrl,
  });

  factory BestSellerModel.fromJson(Map<String, dynamic> json) {
    return BestSellerModel(
      id: json['id'] as int,
      name: json['name'] as String,
      soldCount: json['soldCount'] as int,
      imageUrl: json['imageUrl'] as String?,
    );
  }
}

class OrderHistoryModel {
  final int id;
  final String orderNumber;
  final DateTime createdAt;
  final String status;
  final double totalAmount;
  final String? userName;

  OrderHistoryModel({
    required this.id,
    required this.orderNumber,
    required this.createdAt,
    required this.status,
    required this.totalAmount,
    this.userName,
  });

  factory OrderHistoryModel.fromJson(Map<String, dynamic> json) {
    return OrderHistoryModel(
      id: json['id'] as int,
      orderNumber: json['orderNumber'] ?? "ORD-${json['id']}",
      createdAt: DateTime.parse(json['createdAt'] as String),
      status: json['status'] as String,
      totalAmount: (json['totalAmount'] as num).toDouble(),
      userName: json['user']?['name'] as String?,
    );
  }
}
