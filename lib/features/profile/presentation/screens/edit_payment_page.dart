import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_shop/core/presentation/widgets/primary_gradient_switch.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:my_shop/core/presentation/widgets/confirmation_sheet.dart';
import 'package:my_shop/core/presentation/widgets/global_modal.dart';
import 'package:my_shop/features/profile/data/models/payment_method.dart';
import 'package:my_shop/features/profile/data/services/payment_service.dart';
import 'package:my_shop/core/data/services/storage_service.dart';
import 'package:image_picker/image_picker.dart';


import 'package:my_shop/core/presentation/widgets/primary_gradient_button.dart';
import '../widgets/password_confirmation_sheet.dart';
import '../../../../core/presentation/widgets/custom_loading_indicator.dart';
import '../../../../core/data/services/image_upload_service.dart';
import 'package:my_shop/core/utils/app_colors.dart';
import 'package:my_shop/core/presentation/widgets/gradient_widgets.dart';
import 'package:my_shop/core/presentation/widgets/app_dialog.dart';
import 'package:my_shop/core/localization/app_localizations.dart';

class EditPaymentPage extends StatefulWidget {
  final PaymentMethod paymentMethod;
  const EditPaymentPage({super.key, required this.paymentMethod});

  @override
  State<EditPaymentPage> createState() => _EditPaymentPageState();
}

class _EditPaymentPageState extends State<EditPaymentPage> {
  final PaymentService _paymentService = PaymentService();
  final Map<String, XFile?> _pickedImages = {};
  final _scrollController = ScrollController();

  // GlobalKeys for scroll-to-error
  final _qrImageKey = GlobalKey();
  final _accountNameKey = GlobalKey();
  final _accountNumberKey = GlobalKey();

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
    _scrollController.dispose();
    _accountNameCtrl.dispose();
    _accountNumberCtrl.dispose();
    _displayOrderCtrl.dispose();
    super.dispose();
  }

  void _scrollToKey(GlobalKey key) {
    final context = key.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        alignment: 0.1,
      );
    }
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

  bool _isFormValid() {
    final accountName = _accountNameCtrl.text.trim();
    final accountNumber = _accountNumberCtrl.text.trim();
    final pickedImage = _pickedImages[_currentPayment?.id.toString()];
    final hasExistingImage = _currentPayment?.qrImageUrl.isNotEmpty ?? false;
    final hasImage = pickedImage != null || hasExistingImage;
    final t = AppLocalizations.of(context);

    if (!hasImage) {
      _scrollToKey(_qrImageKey);
      AppDialog.showToast(context, t?.translate('qr_image_required') ?? 'QR Image is required', isError: true);
      return false;
    }

    if (accountName.isEmpty) {
      _scrollToKey(_accountNameKey);
      AppDialog.showToast(context, t?.translate('account_name_required') ?? 'Account Name is required', isError: true);
      return false;
    }

    if (accountNumber.isEmpty) {
      _scrollToKey(_accountNumberKey);
      AppDialog.showToast(context, t?.translate('account_number_required') ?? 'Account Number is required', isError: true);
      return false;
    }

    return true;
  }

  Future<void> _handleUpdate() async {
    final t = AppLocalizations.of(context);
    GlobalModal.show(
      context: context,
      child: ConfirmationSheet(
        title: t?.translate('update_payment_title') ?? 'Update Payment',
        message: t?.translate('update_payment_confirm') ?? 'Are you sure you want to update this payment method?',
        confirmLabel: t?.translate('yes_update') ?? 'Yes, Update',
        onConfirm: () async {
          await _performUpdate();
        },
      ),
    );
  }

  Future<void> _performUpdate() async {
    int? shopId = _currentPayment?.shopId;
    if (shopId == null || shopId == 0) {
      shopId = await StorageService.instance.getSelectedShopId();
    }

    final requestData = {
      "paymentMethodId":
          _currentPayment?.paymentMethodId ??
          widget.paymentMethod.paymentMethodId,
      "displayOrder": 1,
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
      final t = AppLocalizations.of(context);
      if (result['success'] == true) {
        AppDialog.showToast(context, t?.translate('successfully_requested') ?? 'Successfully requested');
        Navigator.of(context).pop(true);
      } else {
        AppDialog.showToast(context, result['message'] ?? (t?.translate('failed_update_payment') ?? 'Failed to update payment method'), isError: true);
      }
    }
  }

  Future<void> _pickImage(String paymentId) async {
    final t = AppLocalizations.of(context);
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
                t?.translate('upload_qr_photo') ?? 'Upload QR Photo',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: const Color(0xFF1E293B),
                ),
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const GradientWidget(
                child: Icon(
                  Icons.photo_library_outlined,
                ),
              ),
              title: Text(t?.translate('choose_from_gallery') ?? 'Choose from Gallery', style: GoogleFonts.poppins()),
              onTap: () async {
                Navigator.pop(context);
                final result = await ImageUploadService().pickFromGallery();
                if (result.isTooLarge) {
                  if (mounted) {
                    AppDialog.showToast(context, t?.translate('image_size_limit_msg') ?? 'Image size must be less than 1MB', isError: true);
                  }
                  return;
                }
                if (result.file != null) {
                  setState(() => _pickedImages[paymentId] = result.file);
                }
              },
            ),
            const Divider(height: 1, indent: 56),
            ListTile(
              leading: const GradientWidget(
                child: Icon(
                  Icons.camera_alt_outlined,
                ),
              ),
              title: Text(t?.translate('take_photo') ?? 'Take a Photo', style: GoogleFonts.poppins()),
              onTap: () async {
                Navigator.pop(context);
                final result = await ImageUploadService().pickFromCamera();
                if (result.isTooLarge) {
                  if (mounted) {
                    AppDialog.showToast(context, t?.translate('image_size_limit_msg') ?? 'Image size must be less than 1MB', isError: true);
                  }
                  return;
                }
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
                  child: Text(t?.translate('cancel') ?? 'Cancel', style: GoogleFonts.poppins()),
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
          AppLocalizations.of(context)?.translate('edit_payment') ?? 'Edit payment',
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
                    controller: _scrollController,
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        _buildForm(),
                      ],
                    ),
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
              child: PrimaryGradientButton(
                onPressed: () {
                  if (!_isFormValid()) return;
                  GlobalModal.show(
                    context: context,
                    child: PasswordConfirmationSheet(
                      onConfirm: (password) {
                        Navigator.pop(context);
                        _handleUpdate();
                      },
                    ),
                  );
                },
                isLoading: _isSaving,
                height: 64,
                borderRadius: 18,
                child: Text(
                  AppLocalizations.of(context)?.translate('update_payment_method') ?? 'Update Payment Method',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    final t = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPaymentIconAndName(),
        const SizedBox(height: 24),
        SizedBox(key: _qrImageKey, child: _buildImagePicker()),
        const SizedBox(height: 32),
        _buildSectionTitle(t?.translate('account_details') ?? 'Account Details'),
        const SizedBox(height: 16),
        _buildInputField(
          key: _accountNameKey,
          label: t?.translate('account_name') ?? 'Account Name',
          controller: _accountNameCtrl,
          hint: t?.translate('john_doe_hint') ?? 'e.g. John Doe',
          icon: PhosphorIconsRegular.user,
          maxLength: 100,
        ),
        const SizedBox(height: 20),
        _buildInputField(
          key: _accountNumberKey,
          label: t?.translate('account_number') ?? 'Account Number',
          controller: _accountNumberCtrl,
          hint: t?.translate('account_number_hint') ?? 'e.g. 123456789',
          icon: PhosphorIconsRegular.hash,
          maxLength: 50,
        ),
        const SizedBox(height: 20),
        _buildStatusToggle(),
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
                            _currentPayment!.fullQrImageUrl,
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
                  color: AppColors.primary,
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
            AppLocalizations.of(context)?.translate('tap_to_upload_qr') ?? 'Tap to upload QR Code',
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
    Key? key,
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int? maxLength,
  }) {
    return Column(
      key: key,
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
          maxLength: maxLength,
          style: GoogleFonts.poppins(fontSize: 15),
          decoration: InputDecoration(
            counterText: '',
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
                color: AppColors.primary,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusToggle() {
    final t = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t?.translate('status') ?? 'Status',
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
                t?.translate('is_active') ?? 'Is Active',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const Spacer(),
              PrimaryGradientSwitch(
                value: _isActive,
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
