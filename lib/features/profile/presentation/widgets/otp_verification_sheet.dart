import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_shop/core/data/services/storage_service.dart';
import '../../../../core/presentation/widgets/global_modal.dart';
import 'package:my_shop/core/presentation/widgets/success_sheet.dart';
import '../../../../core/presentation/widgets/primary_gradient_button.dart';
import 'package:my_shop/core/presentation/widgets/app_dialog.dart';

class OtpVerificationSheet extends StatefulWidget {
  const OtpVerificationSheet({super.key});

  @override
  State<OtpVerificationSheet> createState() => _OtpVerificationSheetState();
}

class _OtpVerificationSheetState extends State<OtpVerificationSheet> {
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());
  final List<TextEditingController> _controllers = List.generate(6, (index) => TextEditingController());
  bool _isLoading = false;
  String? _errorMessage;
  String _maskedEmail = 'your email';

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final userInfo = await StorageService.instance.getUserInfo();
    if (userInfo != null && mounted) {
      setState(() {
        _maskedEmail = _maskEmail(userInfo.email);
      });
    }
  }

  String _maskEmail(String email) {
    if (email.isEmpty) return email;
    final parts = email.split('@');
    if (parts.length != 2) return email;
    final name = parts[0];
    final domain = parts[1];
    if (name.length <= 2) return email;
    final maskedName = name.substring(0, 2) + '.' * 9 + name.substring(name.length - 2);
    return '$maskedName@$domain';
  }

  @override
  void dispose() {
    for (var node in _focusNodes) {
      node.dispose();
    }
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onChanged(String value, int index) {
    if (value.isNotEmpty) {
      if (_errorMessage != null) setState(() => _errorMessage = null);
      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
        _handleVerify();
      }
    } else {
      if (index > 0) {
        _focusNodes[index - 1].requestFocus();
      }
    }
  }

  Future<void> _handleVerify() async {
    final otp = _controllers.map((c) => c.text).join();
    if (otp.length < 6) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    if (otp == '000000') {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Invalid code. (Test mode: any other 6 digits work)';
        // Clear inputs on failure
        for (var c in _controllers) {
          c.clear();
        }
        _focusNodes[0].requestFocus();
      });
      return;
    }

    setState(() => _isLoading = false);
    
    // Close OTP sheet
    Navigator.pop(context);

    // Show success sheet
    GlobalModal.show(
      context: context,
      child: const SuccessSheet(),
    );
  }

  Future<void> _handleResend() async {
    AppDialog.showToast(context, 'OTP sent again!');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 32),
        Center(
          child: Text(
            'OTP Verification',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E293B),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'We sent a 6-digit code to \n$_maskedEmail',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: const Color(0xFF64748B),
                height: 1.5,
              ),
            ),
          ),
        ),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(6, (index) => _buildOtpBox(index)),
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 16),
          Center(
            child: Text(
              _errorMessage!,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: PrimaryGradientButton(
            onPressed: _handleVerify,
            isLoading: _isLoading,
            text: 'Verify',
            height: 56,
            borderRadius: 16,
          ),
        ),
        const SizedBox(height: 24),
        Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Didn't receive code? ",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: const Color(0xFF64748B),
                ),
              ),
              GestureDetector(
                onTap: _handleResend,
                child: Text(
                  'Send again',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFED3973),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildOtpBox(int index) {
    return Container(
      width: 48,
      height: 56,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _errorMessage != null 
            ? Colors.red 
            : (_focusNodes[index].hasFocus ? const Color(0xFFED3973) : Colors.transparent),
          width: 2,
        ),
      ),
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(1),
        ],
        style: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF1E293B),
        ),
        decoration: const InputDecoration(
          border: InputBorder.none,
          counterText: '',
        ),
        onChanged: (value) => _onChanged(value, index),
      ),
    );
  }
}
