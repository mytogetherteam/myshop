import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:my_shop/core/data/services/storage_service.dart';
import 'dart:convert';
import '../../data/models/payment_method.dart';
import '../../data/services/payment_service.dart';
import '../widgets/password_confirmation_sheet.dart';
import '../widgets/payment_success_sheet.dart';
import '../../../../core/presentation/widgets/global_modal.dart';
import '../../../../core/presentation/widgets/custom_loading_indicator.dart';
import '../../../../core/data/services/image_upload_service.dart';

class EditPaymentPage extends StatefulWidget {
  final PaymentMethod paymentMethod;
  const EditPaymentPage({super.key, required this.paymentMethod});

  @override
  State<EditPaymentPage> createState() => _EditPaymentPageState();
}

class _EditPaymentPageState extends State<EditPaymentPage> {
  final PaymentService _paymentService = PaymentService();
  final Map<String, XFile?> _pickedImages = {};

  late final TextEditingController _accountNameCtrl;
  late final TextEditingController _accountNumberCtrl;
  late final TextEditingController _displayOrderCtrl;
  late bool _isActive;
  bool _isSaving = false;
  bool _isLoading = false;
  PaymentMethod? _currentPayment;

  @override
  void initState() {
    super.initState();
    _currentPayment = widget.paymentMethod;
    _accountNameCtrl = TextEditingController(
      text: _currentPayment?.accountName ?? '',
    );
    _accountNumberCtrl = TextEditingController(
      text: _currentPayment?.accountNumber ?? '',
    );
    _displayOrderCtrl = TextEditingController(
      text: (_currentPayment?.displayOrder ?? 0).toString(),
    );
    _isActive = _currentPayment?.isActive ?? true;

    _loadLatestDetails();
  }

  @override
  void dispose() {
    _accountNameCtrl.dispose();
    _accountNumberCtrl.dispose();
    _displayOrderCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadLatestDetails() async {
    setState(() => _isLoading = true);
    final detail = await _paymentService.getPaymentMethodDetail(
      widget.paymentMethod.id,
    );
    if (detail != null && mounted) {
      setState(() {
        _currentPayment = detail;
        _accountNameCtrl.text = detail.accountName;
        _accountNumberCtrl.text = detail.accountNumber;
        _displayOrderCtrl.text = detail.displayOrder.toString();
        _isActive = detail.isActive;
        _isLoading = false;
      });
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleUpdate() async {
    setState(() => _isSaving = true);

    int? shopId = _currentPayment?.shopId;
    if (shopId == null || shopId == 0) {
      shopId = await StorageService.instance.getSelectedShopId();
    }

    final requestData = {
      "paymentMethodId":
          _currentPayment?.paymentMethodId ??
          widget.paymentMethod.paymentMethodId,
      "displayOrder": int.tryParse(_displayOrderCtrl.text) ?? 0,
      "isActive": _isActive,
      "shopId": shopId,
      "paymentMethodName":
          _currentPayment?.paymentMethodName ??
          widget.paymentMethod.paymentMethodName,
      "paymentMethodCode":
          _currentPayment?.paymentMethodCode ??
          widget.paymentMethod.paymentMethodCode,
      "accountNumber": _accountNumberCtrl.text.trim(),
      "accountName": _accountNameCtrl.text.trim(),
      "id": _currentPayment?.id ?? widget.paymentMethod.id,
    };

    debugPrint('PAYMENT UPDATE DATA: ${jsonEncode(requestData)}');

    File? qrPhoto;
    final pickedFile = _pickedImages[_currentPayment?.id.toString()];
    if (pickedFile != null) {
      qrPhoto = File(pickedFile.path);
    }

    final result = await _paymentService.updatePaymentMethod(
      paymentTypeId: widget.paymentMethod.id,
      requestData: requestData,
      qrPhoto: qrPhoto,
    );

    if (mounted) {
      setState(() => _isSaving = false);
      if (result['success'] == true) {
        GlobalModal.show(
          context: context,
          child: PaymentSuccessSheet(
            onDone: () {
              Navigator.pop(context); // Close modal
              Navigator.pop(context, true); // Go back with refresh signal
            },
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['message'] ?? 'Failed to update payment method',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

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
                'Upload QR Photo',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: const Color(0xFF1E293B),
                ),
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(
                Icons.photo_library_outlined,
                color: Color(0xFFED3973),
              ),
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
              leading: const Icon(
                Icons.camera_alt_outlined,
                color: Color(0xFFED3973),
              ),
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
      body: _isLoading
          ? const Center(child: CustomLoadingIndicator())
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: _buildForm(),
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
                onPressed: _isSaving
                    ? null
                    : () {
                        GlobalModal.show(
                          context: context,
                          child: PasswordConfirmationSheet(
                            onConfirm: (password) {
                              Navigator.pop(context); // Close sheet
                              _handleUpdate();
                            },
                          ),
                        );
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFED3973),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(
                    0xFFED3973,
                  ).withValues(alpha: 0.6),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: _isSaving
                    ? const CustomLoadingIndicator(
                        size: 24,
                        color: Colors.white,
                      )
                    : Column(
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
                              color: Colors.white.withValues(alpha: 0.9),
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

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPaymentIconAndName(),
        const SizedBox(height: 24),
        _buildImagePicker(),
        const SizedBox(height: 32),
        _buildSectionTitle('Account Details'),
        const SizedBox(height: 16),
        _buildInputField(
          label: 'Account Name',
          controller: _accountNameCtrl,
          hint: 'e.g. John Doe',
          icon: PhosphorIconsRegular.user,
        ),
        const SizedBox(height: 20),
        _buildInputField(
          label: 'Account Number',
          controller: _accountNumberCtrl,
          hint: 'e.g. 123456789',
          icon: PhosphorIconsRegular.hash,
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _buildInputField(
                label: 'Display Order',
                controller: _displayOrderCtrl,
                hint: '0',
                icon: PhosphorIconsRegular.sortAscending,
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(child: _buildStatusToggle()),
          ],
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildPaymentIconAndName() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFF1F5F9)),
          ),
          child: Icon(
            _getPaymentIcon(_currentPayment?.paymentMethodCode ?? ''),
            size: 24,
            color: const Color(0xFF475569),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          _currentPayment?.paymentMethodName ?? '',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  IconData _getPaymentIcon(String code) {
    final upper = code.toUpperCase();
    if (upper.contains('PROMPT') || upper.contains('QR')) {
      return PhosphorIconsRegular.qrCode;
    } else if (upper.contains('BANK') || upper.contains('TRANSFER')) {
      return PhosphorIconsRegular.bank;
    } else if (upper.contains('WALLET') || upper.contains('MONEY')) {
      return PhosphorIconsRegular.wallet;
    } else if (upper.contains('CARD') ||
        upper.contains('CREDIT') ||
        upper.contains('DEBIT')) {
      return PhosphorIconsRegular.creditCard;
    }
    return PhosphorIconsRegular.currencyCircleDollar;
  }

  Widget _buildImagePicker() {
    final pickedImage = _pickedImages[_currentPayment?.id.toString()];
    final hasImage =
        pickedImage != null ||
        (_currentPayment?.qrImageUrl.isNotEmpty ?? false);

    return Stack(
      children: [
        GestureDetector(
          onTap: () => _pickImage(_currentPayment!.id.toString()),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: pickedImage != null
                  ? (kIsWeb
                        ? Image.network(
                            pickedImage.path,
                            width: double.infinity,
                            height: 250,
                            fit: BoxFit.cover,
                          )
                        : Image.file(
                            File(pickedImage.path),
                            width: double.infinity,
                            height: 250,
                            fit: BoxFit.cover,
                          ))
                  : (_currentPayment?.qrImageUrl.isNotEmpty ?? false
                        ? Image.network(
                            _currentPayment!.qrImageUrl,
                            width: double.infinity,
                            height: 250,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stack) =>
                                _buildPlaceholder(),
                          )
                        : _buildPlaceholder()),
            ),
          ),
        ),
        if (hasImage)
          Positioned(
            top: 12,
            right: 12,
            child: GestureDetector(
              onTap: () => _pickImage(_currentPayment!.id.toString()),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                ),
                child: const Icon(
                  Icons.refresh_rounded,
                  size: 20,
                  color: Color(0xFFED3973),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: double.infinity,
      height: 250,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.add_a_photo_outlined,
            size: 40,
            color: Color(0xFF94A3B8),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap to upload QR Code',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF94A3B8),
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF475569),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: GoogleFonts.poppins(fontSize: 15),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, size: 20, color: const Color(0xFF94A3B8)),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFFED3973),
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusToggle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Status',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF475569),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Text(
                'Is Active',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const Spacer(),
              CupertinoSwitch(
                value: _isActive,
                activeTrackColor: const Color(0xFFED3973),
                onChanged: (v) => setState(() => _isActive = v),
              ),
            ],
          ),
        ),
      ],
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
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          Radius.circular(borderRadius),
        ),
      );

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
