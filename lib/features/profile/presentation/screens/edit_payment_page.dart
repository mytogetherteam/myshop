import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:my_shop/core/data/services/image_upload_service.dart';
import '../../data/models/payment_method.dart';
import '../widgets/password_confirmation_sheet.dart';
import '../../../../core/presentation/widgets/global_modal.dart';

class EditPaymentPage extends StatefulWidget {
  final PaymentMethod paymentMethod;
  const EditPaymentPage({super.key, required this.paymentMethod});

  @override
  State<EditPaymentPage> createState() => _EditPaymentPageState();
}

class _EditPaymentPageState extends State<EditPaymentPage> {
  final Map<String, XFile?> _pickedImages = {};

  Future<void> _pickImage(String paymentId) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                'Upload Item Photo',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: const Color(0xFF1E293B),
                ),
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: Color(0xFFED3973)),
              title: Text('Choose from Gallery', style: GoogleFonts.poppins()),
              onTap: () async {
                Navigator.pop(context);
                final result = await ImageUploadService().pickFromGallery();
                if (result.file != null) {
                  setState(() => _pickedImages[paymentId] = result.file);
                }
              },
            ),
            const Divider(height: 1, indent: 56),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined, color: Color(0xFFED3973)),
              title: Text('Take a Photo', style: GoogleFonts.poppins()),
              onTap: () async {
                Navigator.pop(context);
                final result = await ImageUploadService().pickFromCamera();
                if (result.file != null) {
                  setState(() => _pickedImages[paymentId] = result.file);
                }
              },
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Cancel', style: GoogleFonts.poppins()),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Edit payment',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: _buildPaymentItem(widget.paymentMethod),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Colors.black.withValues(alpha: 0.05)),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: SizedBox(
              width: double.infinity,
              height: 64,
              child: ElevatedButton(
                onPressed: () {
                  GlobalModal.show(
                    context: context,
                    child: const PasswordConfirmationSheet(),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFED3973),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFFED3973).withValues(alpha: 0.6),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Update Payment Method',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Changes will take effect after verified',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentItem(PaymentMethod pm) {
    final pickedImage = _pickedImages[pm.id];
    final hasImage = pickedImage != null || pm.qrUrl.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Image.network(pm.logoUrl, width: 24, height: 24, errorBuilder: (_, __, ___) => const Icon(Icons.payment, size: 24)),
              const SizedBox(width: 12),
              Text(
                pm.name,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Stack(
            children: [
              GestureDetector(
                onTap: () => _pickImage(pm.id),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFF1F5F9)),
                  ),
                  child: Center(
                    child: !hasImage
                        ? CustomPaint(
                            painter: DashedBorderPainter(),
                            child: Container(
                              width: double.infinity,
                              height: 250,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(color: const Color(0xFFED3973).withOpacity(0.1)),
                                      color: Colors.white,
                                    ),
                                    child: const Icon(Icons.add_a_photo_outlined, size: 32, color: Color(0xFFED3973)),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Tap to upload',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF1E293B),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'or take a photo of your receipt',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: const Color(0xFF94A3B8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: pickedImage != null
                                ? (kIsWeb
                                    ? Image.network(pickedImage.path, width: double.infinity, height: 250, fit: BoxFit.cover)
                                    : Image.file(File(pickedImage.path), width: double.infinity, height: 250, fit: BoxFit.cover))
                                : Image.network(
                                    pm.qrUrl,
                                    width: double.infinity,
                                    height: 250,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      width: double.infinity,
                                      height: 250,
                                      color: Colors.grey[100],
                                      child: const Icon(Icons.qr_code, size: 64, color: Colors.grey),
                                    ),
                                  ),
                          ),
                  ),
                ),
              ),
              if (hasImage)
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () => _pickImage(pm.id),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.refresh_rounded,
                        size: 24,
                        color: Color(0xFFED3973),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashWidth;
  final double dashSpace;
  final double borderRadius;

  DashedBorderPainter({
    this.color = const Color(0xFFCBD5E1),
    this.strokeWidth = 1.5,
    this.dashWidth = 5,
    this.dashSpace = 3,
    this.borderRadius = 16,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Radius.circular(borderRadius),
      ));

    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        canvas.drawPath(
          metric.extractPath(distance, distance + dashWidth),
          paint,
        );
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
