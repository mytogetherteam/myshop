import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_shop/core/localization/app_localizations.dart';
import 'package:my_shop/core/utils/geo_distance.dart';

import '../../data/models/order_model.dart';

/// Warns shop admins when delivery is farther than [GeoDistance.farOrderThresholdKm].
/// Shown on order detail only (not the list card).
class FarOrderDeliveryBanner extends StatelessWidget {
  final OrderModel order;
  final double? shopLatitude;
  final double? shopLongitude;

  const FarOrderDeliveryBanner({
    super.key,
    required this.order,
    this.shopLatitude,
    this.shopLongitude,
  });

  double? get _deliveryKm {
    if (order.orderType.toUpperCase() != 'DELIVERY') return null;
    return GeoDistance.deliveryDistanceKm(
      shopLat: shopLatitude,
      shopLon: shopLongitude,
      deliveryLat: order.lat ?? order.deliveryAddress?.latitude,
      deliveryLon: order.lon ?? order.deliveryAddress?.longitude,
    );
  }

  bool get _isFarOrder {
    final km = _deliveryKm;
    return km != null && km > GeoDistance.farOrderThresholdKm;
  }

  @override
  Widget build(BuildContext context) {
    if (!_isFarOrder) return const SizedBox.shrink();

    final km = _deliveryKm!;
    final t = AppLocalizations.of(context);
    final distance = km.toStringAsFixed(1);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 12, bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF59E0B)),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_on_outlined,
              color: Color(0xFFD97706), size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              (t?.translate('order_far_delivery') ??
                      'Delivery is {distance} km away — outside 6km preferred range')
                  .replaceAll('{distance}', distance),
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF92400E),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
