import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:my_shop/core/presentation/widgets/gradient_widgets.dart';
import 'package:my_shop/core/localization/app_localizations.dart';
import 'form_section.dart';

class PhoneNumbersSection extends StatefulWidget {
  final List<TextEditingController> phoneControllers;
  final VoidCallback onMarkChanged;

  const PhoneNumbersSection({
    super.key,
    required this.phoneControllers,
    required this.onMarkChanged,
  });

  @override
  State<PhoneNumbersSection> createState() => _PhoneNumbersSectionState();
}

class _PhoneNumbersSectionState extends State<PhoneNumbersSection> {
  Widget _buildTextField(
    TextEditingController ctrl,
    String hint, {
    IconData? icon,
    bool enabled = true,
    int? maxLength,
  }) {
    return TextField(
      controller: ctrl,
      enabled: enabled,
      maxLength: maxLength,
      onChanged: (_) => widget.onMarkChanged(),
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
        prefixIcon: icon != null
            ? PhosphorIcon(icon, size: 18, color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF94A3B8) : const Color(0xFF94A3B8))
            : null,
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
          borderSide: BorderSide(color: Color(0xFFED3973), width: 1.5),
        ),
        suffixIcon: ValueListenableBuilder<TextEditingValue>(
          valueListenable: ctrl,
          builder: (context, value, child) {
            if (value.text.isEmpty) return const SizedBox.shrink();
            return IconButton(
              icon: Icon(Icons.clear, color: (Theme.of(context).brightness == Brightness.dark ? Theme.of(context).dividerColor : const Color(0xFF94A3B8)), size: 20),
              onPressed: () {
                ctrl.clear();
                widget.onMarkChanged();
              },
            );
          },
        ),
      ),
      style: GoogleFonts.poppins(fontSize: 14, color: (Theme.of(context).brightness == Brightness.dark ? Colors.white : (Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF1E293B)))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return FormSection(
      label: t?.translate('phone_numbers') ?? 'Phone Numbers',
      required: true,
      child: Column(
        children: [
          for (int i = 0; i < widget.phoneControllers.length; i++)
            Padding(
              padding: EdgeInsets.only(
                bottom: i < widget.phoneControllers.length - 1 ? 12.0 : 0,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      widget.phoneControllers[i],
                      '+95 9 XXX XXX XXX',
                      icon: PhosphorIconsRegular.phone,
                      maxLength: 20,
                    ),
                  ),
                  if (widget.phoneControllers.length > 1 ||
                      i == widget.phoneControllers.length - 1)
                    SizedBox(width: 8),
                  if (widget.phoneControllers.length > 1)
                    IconButton(
                      onPressed: () {
                        setState(() {
                          widget.phoneControllers[i].dispose();
                          widget.phoneControllers.removeAt(i);
                          widget.onMarkChanged();
                        });
                      },
                      icon: Icon(
                        PhosphorIconsRegular.minusCircle,
                        color: Color(0xFFEF4444),
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  if (widget.phoneControllers.length > 1 &&
                      i == widget.phoneControllers.length - 1)
                    SizedBox(width: 8),
                  if (i == widget.phoneControllers.length - 1)
                    IconButton(
                      onPressed: () {
                        setState(() {
                          widget.phoneControllers.add(
                            TextEditingController(),
                          );
                          widget.onMarkChanged();
                        });
                      },
                      icon: const GradientWidget(
                        child: Icon(
                          PhosphorIconsRegular.plusCircle,
                        ),
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
