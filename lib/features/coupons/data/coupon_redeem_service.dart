import 'package:dio/dio.dart';
import 'package:my_shop/core/network/api_client.dart';

/// A BUY / GET item attached to a coupon (mainly for BUY_X_GET_FREE coupons),
/// so staff know what to ring up / give for free.
class ShopCouponItem {
  final String type; // BUY | GET
  final int menuItemId;
  final String name;
  final int quantity;

  const ShopCouponItem({
    required this.type,
    required this.menuItemId,
    required this.name,
    this.quantity = 1,
  });

  factory ShopCouponItem.fromJson(Map<String, dynamic> json) => ShopCouponItem(
        type: json['type']?.toString() ?? 'GET',
        menuItemId: (json['menuItemId'] as num?)?.toInt() ?? 0,
        name: json['name']?.toString() ?? '',
        quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      );

  bool get isGet => type.toUpperCase() == 'GET';
}

/// A coupon the scanned customer can still claim in-store.
class ShopEligibleCoupon {
  final int id;
  final String code;
  final String name;
  final String? description;
  final String promotionType; // BUY_X_GET_DISCOUNT | BUY_X_GET_FREE
  final String? discountType; // PERCENTAGE | FIXED_AMOUNT
  final double discountValue;
  final String target; // ALL | EARLY_BIRD
  final List<ShopCouponItem> items;

  const ShopEligibleCoupon({
    required this.id,
    required this.code,
    required this.name,
    this.description,
    required this.promotionType,
    this.discountType,
    this.discountValue = 0,
    this.target = 'ALL',
    this.items = const [],
  });

  factory ShopEligibleCoupon.fromJson(Map<String, dynamic> json) =>
      ShopEligibleCoupon(
        id: (json['id'] as num?)?.toInt() ?? 0,
        code: json['code']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        description: json['description']?.toString(),
        promotionType:
            json['promotionType']?.toString() ?? 'BUY_X_GET_DISCOUNT',
        discountType: json['discountType']?.toString(),
        discountValue: (json['discountValue'] as num?)?.toDouble() ?? 0,
        target: json['target']?.toString() ?? 'ALL',
        items: (json['items'] as List?)
                ?.whereType<Map>()
                .map((e) =>
                    ShopCouponItem.fromJson(Map<String, dynamic>.from(e)))
                .toList() ??
            const [],
      );

  bool get isFreeItem => promotionType.toUpperCase() == 'BUY_X_GET_FREE';
  bool get isPercentage => (discountType ?? '').toUpperCase() == 'PERCENTAGE';
  bool get isEarlyBird => target.toUpperCase() == 'EARLY_BIRD';
  List<ShopCouponItem> get freeItems => items.where((i) => i.isGet).toList();
}

/// Result of scanning a customer's redeem QR: their verified id plus the
/// coupons they can still claim at this shop.
class ScanResult {
  final int userId;
  final List<ShopEligibleCoupon> coupons;
  final String message;

  const ScanResult({
    required this.userId,
    required this.coupons,
    this.message = '',
  });
}

/// Thrown when scan/redeem fails, carrying the backend's message so the UI can
/// tell the admin exactly what went wrong (expired QR, already used, etc.).
class CouponRedeemException implements Exception {
  final String message;
  const CouponRedeemException(this.message);
  @override
  String toString() => message;
}

/// Talks to the shop-facing coupon redemption endpoints for the in-store flow:
///   1. scan the customer's rotating QR → list the coupons they can claim,
///   2. apply (mark used) the chosen coupon.
/// The shop is derived server-side from the admin's auth, so it isn't sent.
class CouponRedeemService {
  CouponRedeemService._();
  static final CouponRedeemService instance = CouponRedeemService._();

  Future<ScanResult> scan({
    required int userId,
    required String token,
  }) async {
    try {
      final response = await ApiClient().dio.post(
        '${ApiClient.apiPrefix}/coupons/scan',
        data: {'userId': userId, 'token': token},
      );
      final body = response.data;
      final map = body is Map ? Map<String, dynamic>.from(body) : null;
      final data = map?['data'] is Map
          ? Map<String, dynamic>.from(map!['data'] as Map)
          : null;
      final coupons = (data?['coupons'] as List?)
              ?.whereType<Map>()
              .map((e) =>
                  ShopEligibleCoupon.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          const <ShopEligibleCoupon>[];
      return ScanResult(
        userId: (data?['userId'] as num?)?.toInt() ?? userId,
        coupons: coupons,
        message: map?['message']?.toString() ?? '',
      );
    } on DioException catch (e) {
      throw CouponRedeemException(_messageFromDio(e));
    }
  }

  /// Marks the chosen coupon used for the scanned customer. Returns the
  /// backend's success message.
  Future<String> apply({
    required int userId,
    required String couponCode,
  }) async {
    try {
      final response = await ApiClient().dio.post(
        '${ApiClient.apiPrefix}/coupons/apply',
        data: {'userId': userId, 'couponCode': couponCode},
      );
      final body = response.data;
      final map = body is Map ? Map<String, dynamic>.from(body) : null;
      return map?['message']?.toString() ?? 'Coupon redeemed.';
    } on DioException catch (e) {
      throw CouponRedeemException(_messageFromDio(e));
    }
  }

  String _messageFromDio(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['message'] != null) {
      return data['message'].toString();
    }
    if (data is String && data.isNotEmpty) return data;
    return e.message ?? 'Something went wrong. Please try again.';
  }
}
