import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:my_shop/core/data/services/storage_service.dart';
import 'package:my_shop/features/auth/data/models/auth_models.dart';
import 'package:my_shop/features/auth/data/services/auth_service.dart';
import 'package:my_shop/core/presentation/widgets/back_title_app_bar.dart';
import 'package:my_shop/core/presentation/widgets/global_modal.dart';
import 'package:my_shop/core/presentation/widgets/primary_gradient_button.dart';
import 'package:my_shop/core/network/websocket_service.dart';
import 'package:my_shop/core/presentation/widgets/app_dialog.dart';
import 'package:my_shop/core/localization/app_localizations.dart';
import 'change_password_page.dart';

class AccountSettingsPage extends StatefulWidget {
  const AccountSettingsPage({super.key});

  @override
  State<AccountSettingsPage> createState() => _AccountSettingsPageState();
}

class _AccountSettingsPageState extends State<AccountSettingsPage> {
  UserInfo? _userInfo;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    setState(() => _isLoading = true);
    final info = await StorageService.instance.getUserInfo();
    if (mounted) {
      setState(() {
        _userInfo = info;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleDeleteAccount() async {
    if (_userInfo?.email == null) return;
    GlobalModal.show(
      context: context,
      child: _DeleteAccountFrictionSheet(email: _userInfo!.email),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: BackTitleAppBar(
        title: t?.translate('account_settings') ?? 'Account Settings',
      ),
      body: _isLoading
          ? const Center(child: CupertinoActivityIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  // User info section header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                    child: Text(
                      t?.translate('account_info') ?? 'ACCOUNT INFO',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF94A3B8),
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  // Account detail card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border.symmetric(
                        horizontal: BorderSide(color: Color(0xFFE2E8F0), width: 1),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _userInfo?.email ?? '',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _userInfo?.role ?? t?.translate('admin') ?? 'ADMIN',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF475569),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Actions header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                    child: Text(
                      t?.translate('security') ?? 'SECURITY',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF94A3B8),
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  // Change Password option
                  _buildMenuOption(
                    icon: PhosphorIconsRegular.lock,
                    title: t?.translate('change_password') ?? 'Change Password',
                    onTap: () => Navigator.push(
                      context,
                      CupertinoPageRoute(builder: (_) => const ChangePasswordPage()),
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Subtle Delete Account option
                  _buildDeleteAccountOption(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildMenuOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1),
          ),
        ),
        child: Row(
          children: [
            PhosphorIcon(
              icon,
              size: 24,
              color: const Color(0xFF475569),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF1E293B),
                ),
              ),
            ),
            const PhosphorIcon(
              PhosphorIconsRegular.caretRight,
              size: 18,
              color: Color(0xFF94A3B8),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeleteAccountOption() {
    final t = AppLocalizations.of(context);
    return InkWell(
      onTap: _handleDeleteAccount,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border.symmetric(
            horizontal: BorderSide(color: Color(0xFFF1F5F9), width: 1),
          ),
        ),
        child: Row(
          children: [
            Icon(
              PhosphorIconsRegular.trash,
              size: 24,
              color: Colors.red.shade400,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                t?.translate('delete_account') ?? 'Delete Account',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.red.shade400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeleteAccountFrictionSheet extends StatefulWidget {
  final String email;

  const _DeleteAccountFrictionSheet({required this.email});

  @override
  State<_DeleteAccountFrictionSheet> createState() => _DeleteAccountFrictionSheetState();
}

class _DeleteAccountFrictionSheetState extends State<_DeleteAccountFrictionSheet> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleDelete() async {
    final t = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Step-up verification by logging in
      final authResponse = await AuthService.instance.login(
        usernameOrEmail: widget.email,
        password: _passwordController.text,
      );

      if (!authResponse.success) {
        if (mounted) {
          setState(() => _isLoading = false);
          AppDialog.showToast(
            context,
            t?.translate('incorrect_password') ?? 'Incorrect Password',
            isError: true,
          );
        }
        return;
      }

      // Successfully verified current user! Now delete the account.
      final success = await AuthService.instance.deleteAccount();
      if (!mounted) return;

      if (success) {
        WebSocketService().disconnect();
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      } else {
        setState(() => _isLoading = false);
        AppDialog.showToast(
          context,
          t?.translate('failed_delete_account') ?? 'Failed to delete account. Please try again.',
          isError: true,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        AppDialog.showToast(
          context,
          t?.translate('failed_delete_account') ?? 'Failed to delete account. Please try again.',
          isError: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Handle bar
          Container(
            width: 44,
            height: 5,
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(2.5),
            ),
          ),
          Text(
            t?.translate('delete_account_title') ?? 'Delete Account',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            t?.translate('delete_account_message') ??
                'Are you sure you want to permanently delete your account? This action cannot be undone and all your shop data will be removed.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 15,
              color: const Color(0xFF64748B),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              t?.translate('delete_confirm_password') ?? 'To Confirm, Please Enter Your Password:',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF475569),
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _passwordController,
            obscureText: !_isPasswordVisible,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: const Color(0xFF1E293B),
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: t?.translate('enter_your_password') ?? 'Enter Your Password',
              hintStyle: GoogleFonts.poppins(
                fontSize: 14,
                color: const Color(0xFFCBD5E1),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
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
                borderSide: const BorderSide(color: Colors.red, width: 1.5),
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
                  _isPasswordVisible ? PhosphorIconsRegular.eye : PhosphorIconsRegular.eyeSlash,
                  size: 20,
                  color: const Color(0xFF94A3B8),
                ),
                onPressed: () {
                  setState(() => _isPasswordVisible = !_isPasswordVisible);
                },
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return t?.translate('please_enter_current_password') ?? 'Please enter your password';
              }
              return null;
            },
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 60,
            child: PrimaryGradientButton(
              onPressed: _isLoading ? null : _handleDelete,
              isLoading: _isLoading,
              text: t?.translate('yes_delete_account') ?? 'Yes, Delete Account',
              height: 60,
              borderRadius: 18,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 60,
            child: TextButton(
              onPressed: _isLoading
                  ? null
                  : () {
                      Navigator.pop(context);
                    },
              style: TextButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: Text(
                t?.translate('cancel') ?? 'Cancel',
                style: GoogleFonts.poppins(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF64748B),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
