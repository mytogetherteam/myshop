import 'dart:convert';

/// The user identity carried by a customer's redeem QR.
class CouponQrPayload {
  final int userId;
  final String token;

  const CouponQrPayload({required this.userId, required this.token});
}

/// Extracts the `{ userId, token }` payload from a scanned customer redeem QR.
///
/// The customer app encodes the rotating redeem token issued by
/// `POST /api/user/coupons/redeem-token` as JSON, e.g.
/// `{"userId":42,"token":"<hex>"}`. Returns null when the QR is not a coupon
/// redeem code (so the caller can fall back to the order-pickup parser).
class CouponQrParser {
  CouponQrParser._();

  static CouponQrPayload? parse(String? raw) {
    if (raw == null) return null;
    final trimmed = raw.trim();
    if (!trimmed.startsWith('{')) return null;

    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is! Map) return null;
      final map = Map<String, dynamic>.from(decoded);

      final userId = _toInt(map['userId'] ?? map['user_id']);
      final token = map['token']?.toString().trim();
      if (userId == null || userId <= 0) return null;
      if (token == null || token.length < 8) return null;

      return CouponQrPayload(userId: userId, token: token);
    } catch (_) {
      return null;
    }
  }

  static int? _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim());
    return null;
  }
}
