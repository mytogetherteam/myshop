import 'package:flutter/material.dart';
import 'package:my_shop/core/data/models/master_data_model.dart';
import 'package:my_shop/core/presentation/widgets/custom_search_dropdown.dart';
import 'form_section.dart';
import 'language_text_field.dart';

class ShopLocationSection extends StatelessWidget {
  final String addressLang;
  final ValueChanged<String> onAddressLangChanged;
  final TextEditingController addressEnCtrl;
  final TextEditingController addressMmCtrl;
  final TextEditingController addressThCtrl;
  final MasterDataModel? selectedCity;
  final List<MasterDataModel> cities;
  final MasterDataModel? selectedDistrict;
  final List<MasterDataModel> districts;
  final ValueChanged<MasterDataModel?> onCityChanged;
  final ValueChanged<MasterDataModel?> onDistrictChanged;
  final VoidCallback onMarkChanged;

  const ShopLocationSection({
    super.key,
    required this.addressLang,
    required this.onAddressLangChanged,
    required this.addressEnCtrl,
    required this.addressMmCtrl,
    required this.addressThCtrl,
    required this.selectedCity,
    required this.cities,
    required this.selectedDistrict,
    required this.districts,
    required this.onCityChanged,
    required this.onDistrictChanged,
    required this.onMarkChanged,
  });

  Widget _buildDropdown(
    String label,
    MasterDataModel? value,
    List<MasterDataModel> items,
    String hint,
    ValueChanged<MasterDataModel?> onChanged,
  ) {
    final List<MasterDataModel> safeItems = List.from(items);
    if (value != null && !safeItems.contains(value)) {
      safeItems.add(value);
    }

    if (safeItems.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<MasterDataModel>(
            value: null,
            isExpanded: true,
            hint: Text(
              hint,
              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
            ),
            items: [
              DropdownMenuItem<MasterDataModel>(
                value: null,
                enabled: false,
                child: Text(
                  'No data found',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ),
            ],
            onChanged: null,
          ),
        ),
      );
    }

    return CustomSearchDropdown<MasterDataModel>(
      items: safeItems,
      value: value,
      hintText: hint,
      searchHintText: 'Search...',
      itemLabelBuilder: (item) => item.displayName,
      onChanged: onChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FormSection(
          label: 'Street Address',
          required: true,
          child: LanguageTextField(
            selectedLang: addressLang,
            onLangChanged: onAddressLangChanged,
            controller: addressLang == 'EN'
                ? addressEnCtrl
                : addressLang == 'MM'
                ? addressMmCtrl
                : addressThCtrl,
            hint: 'Enter street address',
            requiredLang: 'EN',
            maxLength: 255,
            onChanged: onMarkChanged,
          ),
        ),
        const SizedBox(height: 32),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: FormSection(
                  label: 'City',
                  padding: EdgeInsets.zero,
                  child: _buildDropdown(
                    'Select City',
                    selectedCity,
                    cities,
                    'Choose city',
                    onCityChanged,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FormSection(
                  label: 'District',
                  padding: EdgeInsets.zero,
                  child: _buildDropdown(
                    'Select District',
                    selectedDistrict,
                    districts,
                    'Choose district',
                    onDistrictChanged,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
