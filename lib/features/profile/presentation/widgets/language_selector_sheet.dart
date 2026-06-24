import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:my_shop/core/utils/app_colors.dart';
import 'package:my_shop/core/localization/app_localizations.dart';

class LanguageSelectorSheet extends StatelessWidget {
  const LanguageSelectorSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final currentLang = LocalizationService.instance.localeNotifier.value.languageCode;
    final t = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  t?.translate('language') ?? 'Language',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                InkWell(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).dividerColor.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: PhosphorIcon(
                      PhosphorIconsRegular.x,
                      size: 20,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16),
          _buildLanguageOption(
            context,
            code: 'en',
            name: 'English',
            isSelected: currentLang == 'en',
          ),
          _buildLanguageOption(
            context,
            code: 'my',
            name: 'မြန်မာ (Myanmar)',
            isSelected: currentLang == 'my',
          ),
          _buildLanguageOption(
            context,
            code: 'th',
            name: 'ไทย (Thai)',
            isSelected: currentLang == 'th',
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }

  Widget _buildLanguageOption(
    BuildContext context, {
    required String code,
    required String name,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: () async {
        await LocalizationService.instance.changeLanguage(code);
        if (context.mounted) {
          Navigator.pop(context);
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.05) : Theme.of(context).cardColor,
          border: Border(
            bottom: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.3), width: 1),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                name,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? AppColors.primary : Theme.of(context).textTheme.bodyLarge?.color ?? (Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF1E293B)),
                ),
              ),
            ),
            if (isSelected)
              PhosphorIcon(
                PhosphorIconsFill.checkCircle,
                color: AppColors.primary,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}