import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../data/services/profile_service.dart';
import '../../../../core/presentation/widgets/skeleton.dart';
import '../../../../core/presentation/widgets/primary_gradient_button.dart';
import 'package:my_shop/core/presentation/widgets/app_dialog.dart';
import 'package:my_shop/core/presentation/widgets/back_title_app_bar.dart';
import 'package:my_shop/core/localization/app_localizations.dart';

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
  final bool _isPageLoading = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleChangePassword() async {
    final t = AppLocalizations.of(context);
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
        AppDialog.showToast(context, result['message'] ?? (t?.translate('password_changed_success') ?? 'Password changed successfully'));
        Navigator.pop(context);
      } else {
        AppDialog.showToast(context, result['message'] ?? (t?.translate('failed_change_password') ?? 'Failed to change password'), isError: true);
      }
    } catch (e) {
      if (!mounted) return;
      AppDialog.showToast(context, t?.translate('error_occurred_try_again') ?? 'An error occurred. Please try again.', isError: true);
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
    final t = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: BackTitleAppBar(
        title: t?.translate('change_password') ?? 'Change Password',
      ),
      body: SafeArea(
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
                        label: t?.translate('current_password') ?? 'Current Password',
                        controller: _currentPasswordController,
                        isVisible: _isCurrentPasswordVisible,
                        onToggleVisibility: () {
                          setState(() => _isCurrentPasswordVisible = !_isCurrentPasswordVisible);
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return t?.translate('please_enter_current_password') ?? 'Please enter your current password';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      _buildPasswordField(
                        label: t?.translate('new_password') ?? 'New Password',
                        controller: _newPasswordController,
                        isVisible: _isNewPasswordVisible,
                        onToggleVisibility: () {
                          setState(() => _isNewPasswordVisible = !_isNewPasswordVisible);
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return t?.translate('please_enter_new_password') ?? 'Please enter a new password';
                          }
                          if (value.length < 8) {
                            return t?.translate('password_min_length') ?? 'Password must be at least 8 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      _buildPasswordField(
                        label: t?.translate('confirm_new_password') ?? 'Confirm New Password',
                        controller: _confirmPasswordController,
                        isVisible: _isConfirmPasswordVisible,
                        onToggleVisibility: () {
                          setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible);
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return t?.translate('please_confirm_new_password') ?? 'Please confirm your new password';
                          }
                          if (value != _newPasswordController.text) {
                            return t?.translate('passwords_do_not_match') ?? 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
        ),
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
              height: 56,
              child: PrimaryGradientButton(
                onPressed: _handleChangePassword,
                isLoading: _isLoading,
                text: t?.translate('change_password') ?? 'Change Password',
                height: 56,
                borderRadius: 16,
              ),
            ),
          ),
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
    final t = AppLocalizations.of(context);
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
            hintText: t?.translate('enter_password_hint') ?? 'Enter your password',
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
