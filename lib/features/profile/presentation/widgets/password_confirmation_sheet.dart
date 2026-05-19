import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_shop/core/data/services/storage_service.dart';
import 'package:my_shop/features/auth/data/services/auth_service.dart';
import '../../../../core/presentation/widgets/global_modal.dart';
import '../../../../core/presentation/widgets/primary_gradient_button.dart';
import 'otp_verification_sheet.dart';

class PasswordConfirmationSheet extends StatefulWidget {
  final Function(String password)? onConfirm;
  const PasswordConfirmationSheet({super.key, this.onConfirm});

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
    
    final userInfo = await StorageService.instance.getUserInfo();
    if (userInfo != null) {
      final usernameOrEmail = userInfo.email.isNotEmpty ? userInfo.email : userInfo.username;
      final authResponse = await AuthService.instance.login(
        usernameOrEmail: usernameOrEmail,
        password: _passwordController.text,
      );

      if (!mounted) return;

      if (!authResponse.success) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Incorrect password';
        });
        return;
      }
    } else {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'User info not found';
      });
      return;
    }

    setState(() => _isLoading = false);
    
    if (widget.onConfirm != null) {
      widget.onConfirm!(_passwordController.text);
    } else {
      // Default behavior if no callback provided
      Navigator.pop(context);
      GlobalModal.show(
        context: context,
        child: const OtpVerificationSheet(),
      );
    }
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
          child: PrimaryGradientButton(
            onPressed: _handleUpdate,
            isLoading: _isLoading,
            text: 'Confirm',
            height: 56,
            borderRadius: 16,
          ),
        ),
      ],
    );
  }
}
