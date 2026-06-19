import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_shop/core/presentation/widgets/app_logo.dart';
import 'package:my_shop/core/presentation/widgets/primary_gradient_button.dart';
import 'package:my_shop/core/utils/app_colors.dart';
import 'package:my_shop/core/presentation/widgets/app_dialog.dart';
import 'package:my_shop/features/auth/data/services/auth_service.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:my_shop/core/presentation/widgets/global_modal.dart';
import 'package:my_shop/features/profile/presentation/widgets/language_selector_sheet.dart';
import 'package:my_shop/core/localization/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _shopNameController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  bool _isLoading = false;
  bool _agreeToTerms = false;

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
    _shopNameController.dispose();
    _ownerNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (!_agreeToTerms) {
      final t = AppLocalizations.of(context);
      AppDialog.showToast(context, t?.translate('please_agree_terms') ?? 'Please agree to the Terms of Service and Privacy Policy', isError: true);
      return;
    }
    
    setState(() {
      _isLoading = true;
    });

    final response = await AuthService.instance.registerShop(
      shopName: _shopNameController.text.trim(),
      ownerName: _ownerNameController.text.trim(),
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim(),
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (response.success) {
      final t = AppLocalizations.of(context);
      AppDialog.showSuccessDialog(
        context,
        message: t?.translate('registration_success') ?? 'Application submitted successfully! Our team will contact you shortly to verify and activate your shop account.',
        onDone: () => Navigator.pop(context),
      );
    } else {
      final t = AppLocalizations.of(context);
      AppDialog.showToast(context, response.message ?? (t?.translate('registration_failed') ?? 'Registration failed'), isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 24),
              child: _buildLanguageFab(),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Logo
                    const Center(child: AppLogo(size: 72)),

                    const SizedBox(height: 32),

                    // Welcome text
                    Text(
                      t?.translate('register_title') ?? 'Become a Partner 🚀',
                      style: GoogleFonts.poppins(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      t?.translate('register_subtitle') ?? 'Apply now to open your online shop and reach more customers.',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[600],
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Shop Name
                    _buildLabel(t?.translate('shop_name') ?? 'Shop Name'),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _shopNameController,
                      hint: t?.translate('shop_name_hint') ?? 'e.g., My Awesome Shop',
                      icon: Icons.storefront_outlined,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return t?.translate('please_enter_shop_name') ?? 'Please enter your shop name';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    // Owner Name
                    _buildLabel(t?.translate('owner_name') ?? 'Owner Name'),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _ownerNameController,
                      hint: t?.translate('owner_name_hint') ?? 'Enter your full name',
                      icon: Icons.person_outline_rounded,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return t?.translate('please_enter_owner_name') ?? 'Please enter owner name';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    // Phone Number
                    _buildLabel(t?.translate('phone_number') ?? 'Phone Number'),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _phoneController,
                      hint: t?.translate('phone_hint') ?? 'e.g., 09xxxxxxxxx',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return t?.translate('please_enter_phone') ?? 'Please enter your phone number';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    // Email (Optional)
                    _buildLabel(t?.translate('email_optional') ?? 'Email Address (Optional)'),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _emailController,
                      hint: t?.translate('username_email_hint') ?? 'admin@shop.com',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                    ),

                    const SizedBox(height: 24),

                    // Privacy Policy & Terms Checkbox
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: Checkbox(
                            value: _agreeToTerms,
                            activeColor: AppColors.primary,
                            onChanged: (val) {
                              setState(() {
                                _agreeToTerms = val ?? false;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () async {
                              final uri = Uri.parse('https://mytogether.org/privacy-policy/shop');
                              try {
                                await launchUrl(
                                  uri,
                                  mode: kIsWeb
                                      ? LaunchMode.platformDefault
                                      : LaunchMode.inAppBrowserView,
                                );
                              } catch (e) {
                                debugPrint('Could not launch $uri');
                              }
                            },
                            child: ShaderMask(
                              shaderCallback: (bounds) => AppColors.primaryGradient.createShader(bounds),
                              child: Text(
                                t?.translate('terms_and_privacy') ?? 'I agree to the Terms of Service and Privacy Policy',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: Colors.white,
                                  decoration: TextDecoration.underline,
                                  decorationColor: Colors.white,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Register Button
                    PrimaryGradientButton(
                      text: t?.translate('submit_application') ?? 'Submit Application',
                      isLoading: _isLoading,
                      onPressed: _handleRegister,
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      style: GoogleFonts.poppins(fontSize: 15, color: Colors.black),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 14),
        prefixIcon: Icon(icon, color: Colors.grey[500], size: 20),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey[200]!, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey[200]!, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        suffixIcon: ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (context, value, child) {
            if (value.text.isEmpty) return const SizedBox.shrink();
            return IconButton(
              icon: const Icon(Icons.clear, color: Colors.grey, size: 20),
              onPressed: () {
                controller.clear();
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildLanguageFab() {
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const PhosphorIcon(PhosphorIconsRegular.globe, color: Colors.black87, size: 20),
                const SizedBox(width: 8),
                Text(
                  langCode,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(width: 4),
                const PhosphorIcon(PhosphorIconsRegular.caretDown, color: Colors.black54, size: 16),
              ],
            ),
          ),
        );
      },
    );
  }
}
