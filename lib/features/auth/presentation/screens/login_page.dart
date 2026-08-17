import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_shop/core/presentation/widgets/phone_setup_guide_sheet.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:my_shop/core/presentation/widgets/app_logo.dart';
import 'package:my_shop/core/notifications/notification_service.dart';
import 'package:my_shop/features/auth/data/services/auth_service.dart';
import '../../../../core/network/websocket_service.dart';
import '../../../../core/presentation/widgets/primary_gradient_button.dart';
import 'package:my_shop/core/utils/app_colors.dart';
import 'package:my_shop/core/presentation/widgets/app_dialog.dart';
import 'package:my_shop/core/utils/app_version.dart';
import 'package:my_shop/features/auth/presentation/screens/register_page.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:my_shop/core/presentation/widgets/global_modal.dart';
import 'package:my_shop/features/profile/presentation/widgets/language_selector_sheet.dart';
import 'package:my_shop/core/localization/app_localizations.dart';
import 'package:my_shop/core/presentation/widgets/gradient_widgets.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;

  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await AuthService.instance.login(
        usernameOrEmail: _identifierController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;

      if (response.success) {
        WebSocketService().connect();
        await NotificationService().registerDevice();
        if (!kIsWeb && Platform.isAndroid) {
          FlutterBackgroundService().startService();
          if (mounted) {
            await PhoneSetupGuideSheet.show(context);
          }
        }
        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed('/home');
      } else {
        final t = AppLocalizations.of(context);
        _showError(response.details ?? response.message ?? (t?.translate('login_failed') ?? 'Login failed'));
      }
    } catch (e) {
      if (!mounted) return;
      final t = AppLocalizations.of(context);
      _showError('${t?.translate('unexpected_error') ?? 'An unexpected error occurred'}: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showError(String message) {
    AppDialog.showToast(context, message, isError: true);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.grey[100],
      body: Stack(
        children: [
          // Banner Image Background
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 320,
            child: Image.asset(
              'assets/images/ChatGPT Image Aug 8, 2026, 12_46.png',
              fit: BoxFit.cover,
            ),
          ),
          
          // Main Scrollable Content
          SafeArea(
            bottom: false,
            child: Stack(
              children: [
                FadeTransition(
                  opacity: _fadeAnim,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: Column(
                      children: [
                        // Space for the header image
                        const SizedBox(height: 180),
                        
                        // The main login card
                        Expanded(
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(32),
                                topRight: Radius.circular(32),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 24,
                                  offset: const Offset(0, -8),
                                ),
                              ],
                            ),
                            child: SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(28, 0, 28, 32),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Logo overlapping the top of the card
                                    Stack(
                                      clipBehavior: Clip.none,
                                      alignment: Alignment.topCenter,
                                      children: [
                                        const SizedBox(width: double.infinity, height: 60),
                                        Positioned(
                                          top: -44,
                                          child: Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: Theme.of(context).cardColor,
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withValues(alpha: 0.08),
                                                  blurRadius: 16,
                                                  offset: const Offset(0, 8),
                                                ),
                                              ],
                                            ),
                                            child: const AppLogo(size: 72),
                                          ),
                                        ),
                                      ],
                                    ),
                                    
                                    // Welcome Text
                                    Center(
                                      child: Text(
                                        t?.translate('login_title') ?? 'Shop Admin Login',
                                        style: GoogleFonts.poppins(
                                          fontSize: 24,
                                          fontWeight: FontWeight.w700,
                                          color: Theme.of(context).textTheme.bodyLarge?.color,
                                          letterSpacing: -0.5,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Center(
                                      child: Text(
                                        t?.translate('login_subtitle') ?? 'Manage your shop efficiently',
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          color: Theme.of(context).textTheme.bodyMedium?.color,
                                        ),
                                      ),
                                    ),
                                    
                                    const SizedBox(height: 48),
                                    
                                    // Username / Email field
                                    _buildLabel(t?.translate('username_or_email') ?? 'Username or Email'),
                                    const SizedBox(height: 8),
                                    _buildTextField(
                                      controller: _identifierController,
                                      hint: t?.translate('username_email_hint') ?? 'admin@shop.com',
                                      icon: PhosphorIconsRegular.user,
                                      validator: (v) {
                                        if (v == null || v.trim().isEmpty) {
                                          return t?.translate('please_enter_username_email') ?? 'Please enter your username or email';
                                        }
                                        return null;
                                      },
                                    ),
                                    
                                    const SizedBox(height: 24),
                                    
                                    // Password field
                                    _buildLabel(t?.translate('password') ?? 'Password'),
                                    const SizedBox(height: 8),
                                    _buildTextField(
                                      controller: _passwordController,
                                      hint: t?.translate('enter_your_password') ?? 'Enter your password',
                                      icon: PhosphorIconsRegular.lockKey,
                                      obscure: _obscurePassword,
                                      suffixWidget: IconButton(
                                        icon: Icon(
                                          _obscurePassword
                                              ? PhosphorIconsRegular.eyeClosed
                                              : PhosphorIconsRegular.eye,
                                          color: AppColors.outline,
                                          size: 22,
                                        ),
                                        onPressed: () => setState(
                                          () => _obscurePassword = !_obscurePassword,
                                        ),
                                      ),
                                      validator: (v) {
                                        if (v == null || v.isEmpty) {
                                          return t?.translate('please_enter_password') ?? 'Please enter your password';
                                        }
                                        return null;
                                      },
                                    ),
                                    
                                    const SizedBox(height: 40),
                                    
                                    // Login Button
                                    _buildLoginButton(),
                                    
                                    const SizedBox(height: 32),
                                    
                                    // Register Link
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          t?.translate('no_account') ?? "Don't have a shop account? ",
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            color: Theme.of(context).textTheme.bodyMedium?.color,
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => const RegisterPage(),
                                              ),
                                            );
                                          },
                                          child: GradientText(
                                            t?.translate('apply_now') ?? "Apply Now",
                                            style: GoogleFonts.poppins(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    
                                    const SizedBox(height: 40),
                                    
                                    // Version Info
                                    Center(
                                      child: Text(
                                        AppVersion.fullVersion,
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          color: AppColors.outline,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Language FAB
                Positioned(
                  top: 8,
                  right: 24,
                  child: _buildLanguageFab(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).textTheme.bodyLarge?.color,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? suffixWidget,
    String? Function(String?)? validator,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      validator: validator,
      style: GoogleFonts.poppins(
        fontSize: 15, 
        color: Theme.of(context).textTheme.bodyLarge?.color,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(
          color: AppColors.outline, 
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        prefixIcon: ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) => AppColors.primaryGradient.createShader(bounds),
          child: Icon(icon, size: 22),
        ),
        suffixIcon: suffixWidget ?? ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (context, value, child) {
            if (value.text.isEmpty) return const SizedBox.shrink();
            return IconButton(
              icon: Icon(PhosphorIconsRegular.xCircle, color: AppColors.outline, size: 20),
              onPressed: () {
                controller.clear();
              },
            );
          },
        ),
        filled: true,
        fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0), 
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    final t = AppLocalizations.of(context);
    return PrimaryGradientButton(
      text: t?.translate('login_btn') ?? 'Login to Dashboard',
      isLoading: _isLoading,
      onPressed: _handleLogin,
    );
  }

  Widget _buildLanguageFab() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return ValueListenableBuilder<Locale>(
      valueListenable: LocalizationService.instance.localeNotifier,
      builder: (context, locale, _) {
        String langCode = locale.languageCode.toUpperCase();
        if (locale.languageCode == 'my') langCode = 'MM';

        return GestureDetector(
          onTap: () {
            GlobalModal.show(
              context: context,
              child: const LanguageSelectorSheet(),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B).withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : Colors.grey[200]!,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  PhosphorIconsRegular.globe, 
                  color: isDark ? Colors.white : Colors.black87, 
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  langCode,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  PhosphorIconsRegular.caretDown, 
                  color: isDark ? Colors.grey[400] : Colors.grey[600], 
                  size: 14,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
