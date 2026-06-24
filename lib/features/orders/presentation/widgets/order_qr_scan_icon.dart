import 'package:flutter/material.dart';
import 'package:my_shop/features/orders/presentation/screens/order_qr_scanner_screen.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

class OrderQrScanIcon extends StatelessWidget {
  final Color? color;

  const OrderQrScanIcon({super.key, this.color});

  static Future<void> openScanner(BuildContext context) {
    return Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => const OrderQrScannerScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () => openScanner(context),
      icon: Icon(PhosphorIconsRegular.qrCode, color: color ?? Theme.of(context).iconTheme.color, size: 26),
    );
  }
}
