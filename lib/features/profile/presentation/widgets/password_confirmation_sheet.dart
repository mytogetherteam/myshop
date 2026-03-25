import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/presentation/widgets/custom_loading_indicator.dart';
import '../../../../core/presentation/widgets/global_modal.dart';
import 'otp_verification_sheet.dart';

class PasswordConfirmationSheet extends StatefulWidget {
  const PasswordConfirmationSheet({super.key});

  @override
  State<PasswordConfirmationSheet> createState() => _PasswordConfirmationSheetState();
}

class _PasswordConfirmationSheetState extends State<PasswordConfirmationSheet> {
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleUpdate() async {
    if (_passwordController.text.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    if (_passwordController.text.toLowerCase() == 'fail') {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Incorrect password. (Test mode: any other input works)';
      });
      return;
    }

    setState(() => _isLoading = false);
    
    // Close password sheet
    Navigator.pop(context);

    // Show OTP verification sheet
    GlobalModal.show(
      context: context,
      child: const OtpVerificationSheet(),
    );
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
            'Enter your password',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E293B),
            ),
          ),
        ),
        const SizedBox(height: 32),
        Text(
          'Password',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          onChanged: (_) {
            if (_errorMessage != null) setState(() => _errorMessage = null);
          },
          decoration: InputDecoration(
            hintText: '••••••••••••',
            hintStyle: TextStyle(color: Colors.grey[400]),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: _errorMessage != null 
                ? const BorderSide(color: Colors.red, width: 1)
                : BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: _errorMessage != null 
                ? const BorderSide(color: Colors.red, width: 1)
                : BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: _errorMessage != null ? Colors.red : const Color(0xFFED3973),
                width: 1.5,
              ),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: Colors.grey[400],
                size: 20,
              ),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 4),
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
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleUpdate,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFED3973),
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(0xFFED3973).withValues(alpha: 0.6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: _isLoading
                ? const CustomLoadingIndicator(size: 24, color: Colors.white)
                : Text(
                    'Confirm',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
