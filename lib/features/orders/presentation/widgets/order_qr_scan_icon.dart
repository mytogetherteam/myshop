import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:my_shop/features/orders/presentation/screens/order_qr_scanner_screen.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

class OrderQrScanIcon extends StatelessWidget {
  final Color color;

  const OrderQrScanIcon({super.key, this.color = const Color(0xFF1E293B)});

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) return const SizedBox.shrink();

    return IconButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const OrderQrScannerScreen()),
        );
      },
      icon: Icon(PhosphorIconsRegular.qrCode, color: color, size: 26),
    );
  }
}
