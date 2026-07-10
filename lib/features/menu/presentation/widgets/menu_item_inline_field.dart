import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_shop/core/utils/app_colors.dart';

class MenuItemInlineField extends StatefulWidget {
  final String? label;
  final String? hint;
  final String value;
  final ValueChanged<String> onChanged;
  final TextInputType? keyboardType;
  final int? maxLength;

  const MenuItemInlineField({
    super.key,
    this.label,
    this.hint,
    required this.value,
    required this.onChanged,
    this.keyboardType,
    this.maxLength,
  });

  @override
  State<MenuItemInlineField> createState() => _MenuItemInlineFieldState();
}

class _MenuItemInlineFieldState extends State<MenuItemInlineField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(MenuItemInlineField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _controller.text) {
      _controller.text = widget.value;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final field = TextFormField(
      controller: _controller,
      maxLength: widget.maxLength,
      keyboardType: widget.keyboardType,
      onChanged: widget.onChanged,
      style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500),
      inputFormatters: widget.keyboardType == TextInputType.number
          ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))]
          : null,
      decoration: InputDecoration(
        hintText: widget.hint,
        hintStyle: GoogleFonts.poppins(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF94A3B8)
              : const Color(0xFF64748B),
          fontSize: 13,
        ),
        filled: true,
        fillColor: Theme.of(context).brightness == Brightness.dark
            ? Theme.of(context).cardColor
            : Colors.white,
        counterText: '',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).dividerColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );

    if (widget.label == null) return field;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label!,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF94A3B8)
                : const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 6),
        field,
      ],
    );
  }
}

class MenuItemSortableRow extends StatelessWidget {
  final Widget child;
  final int index;

  const MenuItemSortableRow({
    super.key,
    required this.child,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ReorderableDragStartListener(
          index: index,
          child: Padding(
            padding: const EdgeInsets.only(top: 10, right: 8),
            child: Icon(
              Icons.drag_indicator,
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF94A3B8)
                  : const Color(0xFF64748B),
              size: 22,
            ),
          ),
        ),
        Expanded(child: child),
      ],
    );
  }
}
