import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:my_shop/core/utils/app_colors.dart';
import 'package:my_shop/core/presentation/widgets/app_dialog.dart';
import '../../../profile/data/models/support_info_model.dart';

import 'package:my_shop/core/presentation/widgets/back_title_app_bar.dart';
import 'package:my_shop/core/localization/app_localizations.dart';

class HelpSupportPage extends StatefulWidget {
  const HelpSupportPage({super.key});

  @override
  State<HelpSupportPage> createState() => _HelpSupportPageState();
}

class _HelpSupportPageState extends State<HelpSupportPage> {
  SupportInfoModel? _supportInfo;

  @override
  void initState() {
    super.initState();
    _supportInfo = const SupportInfoModel(email: 'support@mytogether.org');
  }

  Future<void> _launch(Uri uri) async {
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && mounted) {
        final t = AppLocalizations.of(context);
        AppDialog.showToast(context, t?.translate('could_not_open_link') ?? 'Could not open this link', isError: true);
      }
    } catch (e) {
      if (mounted) {
        final t = AppLocalizations.of(context);
        AppDialog.showToast(context, t?.translate('could_not_open_link') ?? 'Could not open this link', isError: true);
      }
    }
  }

  void _launchEmail(String email) =>
      _launch(Uri(scheme: 'mailto', path: email, query: 'subject=MyShop Support Request'));

  void _launchPhone(String phone) =>
      _launch(Uri(scheme: 'tel', path: phone));

  void _launchUrl(String url) =>
      _launch(Uri.parse(url.startsWith('http') ? url : 'https://$url'));

  void _launchWhatsapp(String number) {
    final cleaned = number.replaceAll(RegExp(r'[^0-9]'), '');
    _launch(Uri.parse('https://wa.me/$cleaned'));
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: BackTitleAppBar(
        title: t?.translate('help_support') ?? 'Help & Support',
      ),
      body: _buildContent(),
    );
  }



  Widget _buildContent() {
    final info = _supportInfo;
    final t = AppLocalizations.of(context);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      children: [
        // Header card
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  PhosphorIconsRegular.headset,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t?.translate('we_are_here_to_help') ?? 'We\'re here to help!',
                      style: GoogleFonts.poppins(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      info?.workingHours ?? (t?.translate('contact_us_anytime') ?? 'Contact us anytime'),
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 28),

        if (info == null || !info.hasAnyContact) ...[
          _buildEmptyState(),
        ] else ...[
          _buildSectionLabel(t?.translate('contact_us') ?? 'Contact Us'),
          const SizedBox(height: 12),
          if (info.email?.isNotEmpty ?? false)
            _buildContactTile(
              icon: PhosphorIconsRegular.envelope,
              label: t?.translate('email_support') ?? 'Email Support',
              value: info.email!,
              onTap: () => _launchEmail(info.email!),
            ),
          if (info.phone?.isNotEmpty ?? false)
            _buildContactTile(
              icon: PhosphorIconsRegular.phone,
              label: t?.translate('phone_hotline') ?? 'Phone / Hotline',
              value: info.phone!,
              onTap: () => _launchPhone(info.phone!),
            ),
          if (info.whatsapp?.isNotEmpty ?? false)
            _buildContactTile(
              icon: PhosphorIconsRegular.whatsappLogo,
              label: t?.translate('whatsapp') ?? 'WhatsApp',
              value: info.whatsapp!,
              color: const Color(0xFF25D366),
              onTap: () => _launchWhatsapp(info.whatsapp!),
            ),
          if (info.line?.isNotEmpty ?? false)
            _buildContactTile(
              icon: PhosphorIconsRegular.chatCircle,
              label: t?.translate('line') ?? 'LINE',
              value: info.line!,
              color: const Color(0xFF06C755),
              onTap: () => _launchUrl('https://line.me/R/ti/p/${info.line}'),
            ),
          if (info.facebook?.isNotEmpty ?? false)
            _buildContactTile(
              icon: PhosphorIconsRegular.facebookLogo,
              label: t?.translate('facebook') ?? 'Facebook',
              value: info.facebook!,
              color: const Color(0xFF1877F2),
              onTap: () => _launchUrl(info.facebook!),
            ),
          if (info.website?.isNotEmpty ?? false)
            _buildContactTile(
              icon: PhosphorIconsRegular.globe,
              label: t?.translate('website') ?? 'Website',
              value: info.website!,
              onTap: () => _launchUrl(info.website!),
            ),
        ],

      ],
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.poppins(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF94A3B8),
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _buildContactTile({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
    Color? color,
  }) {
    final tileColor = color ?? AppColors.primary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: tileColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: tileColor, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              PhosphorIconsRegular.arrowSquareOut,
              size: 18,
              color: tileColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final t = AppLocalizations.of(context);
    return Column(
      children: [
        const SizedBox(height: 32),
        Icon(
          PhosphorIconsRegular.smiley,
          size: 56,
          color: const Color(0xFFCBD5E1),
        ),
        const SizedBox(height: 16),
        Text(
          t?.translate('support_not_configured') ?? 'Support info not configured yet',
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF94A3B8),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          t?.translate('check_back_later') ?? 'Please check back later.',
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: const Color(0xFFCBD5E1),
          ),
        ),
      ],
    );
  }
}
