import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:my_shop/core/presentation/widgets/primary_gradient_switch.dart';
import 'package:my_shop/core/localization/app_localizations.dart';
import 'form_section.dart';

class AmenitiesAndDietarySection extends StatefulWidget {
  final bool hasParking;
  final bool hasWifi;
  final bool hasDelivery;
  final bool isHalal;
  final bool isVegetarian;
  final Function(
    bool parking,
    bool wifi,
    bool delivery,
    bool halal,
    bool vegetarian,
  ) onChanged;

  const AmenitiesAndDietarySection({
    super.key,
    required this.hasParking,
    required this.hasWifi,
    required this.hasDelivery,
    required this.isHalal,
    required this.isVegetarian,
    required this.onChanged,
  });

  @override
  State<AmenitiesAndDietarySection> createState() =>
      _AmenitiesAndDietarySectionState();
}

class _AmenitiesAndDietarySectionState extends State<AmenitiesAndDietarySection> {
  late bool _hasParking;
  late bool _hasWifi;
  late bool _hasDelivery;
  late bool _isHalal;
  late bool _isVegetarian;

  @override
  void initState() {
    super.initState();
    _hasParking = widget.hasParking;
    _hasWifi = widget.hasWifi;
    _hasDelivery = widget.hasDelivery;
    _isHalal = widget.isHalal;
    _isVegetarian = widget.isVegetarian;
  }

  void _notify() {
    widget.onChanged(
      _hasParking,
      _hasWifi,
      _hasDelivery,
      _isHalal,
      _isVegetarian,
    );
  }

  Widget _buildToggleRow({
    required IconData icon,
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF64748B)),
          const SizedBox(width: 12),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF1E293B),
            ),
          ),
          const Spacer(),
          PrimaryGradientSwitch(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FormSection(
          label: t?.translate('amenities') ?? 'Amenities',
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                _buildToggleRow(
                  icon: PhosphorIconsRegular.car,
                  label: t?.translate('parking') ?? 'Parking',
                  value: _hasParking,
                  onChanged: (v) {
                    setState(() => _hasParking = v);
                    _notify();
                  },
                ),
                const Divider(height: 1, indent: 48),
                _buildToggleRow(
                  icon: PhosphorIconsRegular.wifiHigh,
                  label: t?.translate('wifi') ?? 'WiFi',
                  value: _hasWifi,
                  onChanged: (v) {
                    setState(() => _hasWifi = v);
                    _notify();
                  },
                ),
                const Divider(height: 1, indent: 48),
                _buildToggleRow(
                  icon: PhosphorIconsRegular.motorcycle,
                  label: t?.translate('delivery') ?? 'Delivery',
                  value: _hasDelivery,
                  onChanged: (v) {
                    setState(() => _hasDelivery = v);
                    _notify();
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 32),
        FormSection(
          label: t?.translate('dietary_tags') ?? 'Dietary Tags',
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                _buildToggleRow(
                  icon: PhosphorIconsRegular.moon,
                  label: t?.translate('halal') ?? 'Halal',
                  value: _isHalal,
                  onChanged: (v) {
                    setState(() => _isHalal = v);
                    _notify();
                  },
                ),
                const Divider(height: 1, indent: 48),
                _buildToggleRow(
                  icon: PhosphorIconsRegular.leaf,
                  label: t?.translate('vegetarian') ?? 'Vegetarian',
                  value: _isVegetarian,
                  onChanged: (v) {
                    setState(() => _isVegetarian = v);
                    _notify();
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
