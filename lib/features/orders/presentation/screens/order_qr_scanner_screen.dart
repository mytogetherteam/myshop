import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:my_shop/core/localization/app_localizations.dart';
import 'package:my_shop/core/presentation/widgets/app_dialog.dart';
import 'package:my_shop/core/presentation/widgets/back_title_app_bar.dart';
import 'package:my_shop/core/presentation/widgets/custom_loading_indicator.dart';
import 'package:my_shop/core/utils/app_colors.dart';
import 'package:my_shop/core/utils/order_qr_parser.dart';
import 'package:my_shop/features/orders/data/services/order_service.dart';
import 'package:my_shop/features/orders/presentation/screens/order_detail_screen.dart';
import 'package:my_shop/features/orders/presentation/screens/pickup_complete_screen.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

class OrderQrScannerScreen extends StatefulWidget {
  const OrderQrScannerScreen({super.key});

  @override
  State<OrderQrScannerScreen> createState() => _OrderQrScannerScreenState();
}

class _OrderQrScannerScreenState extends State<OrderQrScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: const [BarcodeFormat.qrCode],
  );

  bool _isProcessing = false;
  bool _cameraGranted = false;
  bool _permissionChecked = false;

  @override
  void initState() {
    super.initState();
    _ensureCameraPermission();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _ensureCameraPermission() async {
    var status = await Permission.camera.status;
    if (!status.isGranted) {
      status = await Permission.camera.request();
    }

    if (!mounted) return;
    setState(() {
      _cameraGranted = status.isGranted;
      _permissionChecked = true;
    });
  }

  Future<void> _handleBarcode(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final rawValue = capture.barcodes
        .map((barcode) => barcode.rawValue)
        .whereType<String>()
        .map((value) => value.trim())
        .firstWhere((value) => value.isNotEmpty, orElse: () => '');

    if (rawValue.isEmpty) return;

    final orderId = OrderQrParser.parseOrderId(rawValue);
    final t = AppLocalizations.of(context);

    if (orderId == null) {
      AppDialog.showToast(
        context,
        t?.translate('invalid_order_qr') ?? 'Invalid order QR code.',
        isError: true,
      );
      return;
    }

    setState(() => _isProcessing = true);
    await _controller.stop();

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: CustomLoadingIndicator(size: 40, color: Colors.white),
      ),
    );

    final order = await OrderService().getOrderDetail(orderId);

    if (!mounted) return;
    Navigator.pop(context); // Close loading

    if (order == null) {
      setState(() => _isProcessing = false);
      await _controller.start();
      if (!mounted) return;
      AppDialog.showToast(
        context,
        t?.translate('could_not_find_order_details') ??
            'Could not find order details.',
        isError: true,
      );
      return;
    }

    final navigator = Navigator.of(context);
    navigator.pop(); // Close scanner

    if (order.status.toUpperCase() == 'PICKED_UP') {
      AppDialog.showToast(
        context,
        t?.translate('order_already_picked_up') ??
            'This order has already been picked up.',
      );
      return;
    }

    if (isPickupReadyForQrConfirm(order)) {
      await navigator.push(
        PageRouteBuilder(
          settings: RouteSettings(name: 'pickup_verify_${order.id}'),
          pageBuilder: (context, animation, secondaryAnimation) =>
              PickupCompleteScreen(order: order),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeOut;
            final tween = Tween(
              begin: begin,
              end: end,
            ).chain(CurveTween(curve: curve));
            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
          reverseTransitionDuration: Duration.zero,
        ),
      );
      return;
    }

    await navigator.push(
      PageRouteBuilder(
        settings: RouteSettings(name: 'order_detail_${order.id}'),
        pageBuilder: (context, animation, secondaryAnimation) =>
            OrderDetailScreen(order: order),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeOut;
          final tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: curve));
          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  Future<void> _toggleTorch() async {
    await _controller.toggleTorch();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: BackTitleAppBar(
        title: t?.translate('scan_order_qr') ?? 'Scan Order QR',
        actions: [
          if (_cameraGranted)
            IconButton(
              onPressed: _toggleTorch,
              icon: ValueListenableBuilder<MobileScannerState>(
                valueListenable: _controller,
                builder: (context, state, _) {
                  final isOn = state.torchState == TorchState.on;
                  return Icon(
                    isOn
                        ? PhosphorIconsFill.flashlight
                        : PhosphorIconsRegular.flashlight,
                    color: isOn ? AppColors.primary : (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black),
                  );
                },
              ),
            ),
        ],
      ),
      body: _buildBody(t),
    );
  }

  Widget _buildBody(AppLocalizations? t) {
    if (!_permissionChecked) {
      return Center(
        child: CustomLoadingIndicator(size: 40, color: Colors.white),
      );
    }

    if (!_cameraGranted) {
      return _PermissionDeniedView(
        message: t?.translate('camera_permission_required') ??
            'Camera permission is required to scan order QR codes.',
        onRetry: _ensureCameraPermission,
        retryLabel: t?.translate('retry') ?? 'Retry',
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        MobileScanner(
          controller: _controller,
          onDetect: _handleBarcode,
        ),
        IgnorePointer(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.45),
                  Colors.transparent,
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.55),
                ],
                stops: const [0, 0.25, 0.75, 1],
              ),
            ),
          ),
        ),
        Center(
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Theme.of(context).cardColor, width: 3),
            ),
          ),
        ),
        Positioned(
          left: 24,
          right: 24,
          bottom: 40,
          child: Text(
            t?.translate('scan_order_qr_hint') ??
                'Point your camera at the order QR code',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: Theme.of(context).cardColor,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        if (_isProcessing)
          Container(
            color: Colors.black.withValues(alpha: 0.35),
            child: Center(
              child: CustomLoadingIndicator(size: 40, color: Colors.white),
            ),
          ),
      ],
    );
  }
}

class _PermissionDeniedView extends StatelessWidget {
  final String message;
  final String retryLabel;
  final VoidCallback onRetry;

  const _PermissionDeniedView({
    required this.message,
    required this.retryLabel,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              PhosphorIconsRegular.cameraSlash,
              color: Colors.white70,
              size: 56,
            ),
            SizedBox(height: 20),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: Theme.of(context).cardColor,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 24),
            TextButton(
              onPressed: onRetry,
              child: Text(
                retryLabel,
                style: GoogleFonts.poppins(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
