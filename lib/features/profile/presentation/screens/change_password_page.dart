import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../data/services/profile_service.dart';
import '../../../../core/presentation/widgets/skeleton.dart';
import '../../../../core/presentation/widgets/primary_gradient_button.dart';
import 'package:my_shop/core/presentation/widgets/app_dialog.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _profileService = ProfileService();

  bool _isCurrentPasswordVisible = false;
  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;
  bool _isPageLoading = true;

  @override
  void initState() {
    super.initState();
    _initializePage();
  }

  Future<void> _initializePage() async {
    // Simulate initial loading to show skeleton
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) {
      setState(() {
        _isPageLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleChangePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _profileService.changePassword(
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
        confirmPassword: _confirmPasswordController.text,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        AppDialog.showToast(context, result['message'] ?? 'Password changed successfully');
        Navigator.pop(context);
      } else {
        AppDialog.showToast(context, result['message'] ?? 'Failed to change password', isError: true);
      }
    } catch (e) {
      if (!mounted) return;
      AppDialog.showToast(context, 'An error occurred. Please try again.', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Change Password',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1E293B),
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: _isPageLoading 
                    ? _buildSkeletons()
                    : Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildPasswordField(
                              label: 'Current Password',
                              controller: _currentPasswordController,
                              isVisible: _isCurrentPasswordVisible,
                              onToggleVisibility: () {
                                setState(() => _isCurrentPasswordVisible = !_isCurrentPasswordVisible);
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your current password';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),
                            _buildPasswordField(
                              label: 'New Password',
                              controller: _newPasswordController,
                              isVisible: _isNewPasswordVisible,
                              onToggleVisibility: () {
                                setState(() => _isNewPasswordVisible = !_isNewPasswordVisible);
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a new password';
                                }
                                if (value.length < 8) {
                                  return 'Password must be at least 8 characters';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),
                            _buildPasswordField(
                              label: 'Confirm New Password',
                              controller: _confirmPasswordController,
                              isVisible: _isConfirmPasswordVisible,
                              onToggleVisibility: () {
                                setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible);
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please confirm your new password';
                                }
                                if (value != _newPasswordController.text) {
                                  return 'Passwords do not match';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: PrimaryGradientButton(
                  onPressed: _handleChangePassword,
                  isLoading: _isLoading,
                  text: 'Change Password',
                  height: 56,
                  borderRadius: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required bool isVisible,
    required VoidCallback onToggleVisibility,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF475569),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: !isVisible,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: const Color(0xFF1E293B),
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: 'Enter your password',
            hintStyle: GoogleFonts.poppins(
              fontSize: 14,
              color: const Color(0xFFCBD5E1),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFED3973), width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.red),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.red, width: 1.5),
            ),
            suffixIcon: IconButton(
              icon: PhosphorIcon(
                isVisible ? PhosphorIconsRegular.eye : PhosphorIconsRegular.eyeSlash,
                size: 20,
                color: const Color(0xFF94A3B8),
              ),
              onPressed: onToggleVisibility,
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildSkeletons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(3, (index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Skeleton(height: 18, width: 120),
              const SizedBox(height: 8),
              Skeleton(height: 48, width: double.infinity, borderRadius: 10),
            ],
          ),
        );
      }),
    );
  }
}
