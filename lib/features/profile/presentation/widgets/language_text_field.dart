import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_shop/core/utils/app_colors.dart';

class LanguageTextField extends StatelessWidget {
  final String selectedLang;
  final ValueChanged<String> onLangChanged;
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final String? requiredLang;
  final bool enabled;
  final int? maxLength;
  final VoidCallback? onChanged;

  const LanguageTextField({
    super.key,
    required this.selectedLang,
    required this.onLangChanged,
    required this.controller,
    required this.hint,
    this.maxLines = 1,
    this.requiredLang,
    this.enabled = true,
    this.maxLength,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: ['EN', 'MM', 'TH'].map((lang) {
            final selected = selectedLang == lang;
            final isRequired = requiredLang == lang;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => onLangChanged(lang),
                child: Container(
                  constraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    gradient: selected ? AppColors.primaryGradient : null,
                    color: selected ? null : (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : Colors.white),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: selected
                          ? Colors.transparent
                          : Theme.of(context).dividerColor,
                    ),
                  ),
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: lang,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: selected
                                ? Colors.white
                                : (Theme.of(context).brightness == Brightness.dark ? const Color(0xFFCBD5E1) : const Color(0xFF64748B)),
                          ),
                        ),
                        if (isRequired)
                          TextSpan(
                            text: ' *',
                            style: TextStyle(
                              color: selected
                                  ? Colors.white
                                  : const Color(0xFFED3973),
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        SizedBox(height: 16),
        TextField(
          controller: controller,
          maxLines: maxLines,
          maxLength: maxLength,
          enabled: enabled,
          onChanged: onChanged != null ? (_) => onChanged!() : null,
          decoration: InputDecoration(
            counterText: '',
            hintText: hint,
            hintStyle: GoogleFonts.poppins(
              color: const Color(0xFFCBD5E1),
              fontSize: 14,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            filled: true,
            fillColor: Theme.of(context).brightness == Brightness.dark ? Theme.of(context).cardColor : Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Theme.of(context).dividerColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Theme.of(context).dividerColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: Color(0xFFED3973),
                width: 1.5,
              ),
            ),
            suffixIcon: ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (context, value, child) {
                if (value.text.isEmpty) return const SizedBox.shrink();
                return IconButton(
                  icon: Icon(Icons.clear, color: (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)), size: 20),
                  onPressed: () {
                    controller.clear();
                    if (onChanged != null) onChanged!();
                  },
                );
              },
            ),
          ),
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Theme.of(context).textTheme.bodyLarge?.color,
            height: selectedLang == 'MM' ? 1.5 : 1.2,
            letterSpacing: selectedLang == 'MM' ? 0.3 : null,
          ),
        ),
      ],
    );
  }
}
