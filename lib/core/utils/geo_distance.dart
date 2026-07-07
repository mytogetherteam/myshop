import 'dart:math' as math;

/// Great-circle distance helpers (myshop — frontend only).
class GeoDistance {
  GeoDistance._();

  /// Same threshold as the user app confirm dialog (km).
  static const double farOrderThresholdKm = 10.0;

  static double haversineKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadiusKm = 6371.0;
    final dLat = _deg2rad(lat2 - lat1);
    final dLon = _deg2rad(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_deg2rad(lat1)) *
            math.cos(_deg2rad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  static double? deliveryDistanceKm({
    required double? shopLat,
    required double? shopLon,
    required double? deliveryLat,
    required double? deliveryLon,
  }) {
    if (shopLat == null ||
        shopLon == null ||
        deliveryLat == null ||
        deliveryLon == null) {
      return null;
    }
    return haversineKm(shopLat, shopLon, deliveryLat, deliveryLon);
  }

  static double _deg2rad(double deg) => deg * (math.pi / 180.0);
}
