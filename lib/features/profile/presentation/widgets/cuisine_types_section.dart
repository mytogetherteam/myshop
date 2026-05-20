import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_shop/core/data/models/master_data_model.dart';
import 'package:my_shop/core/utils/app_colors.dart';
import 'form_section.dart';

class CuisineTypesSection extends StatefulWidget {
  final List<MasterDataModel> cuisineTypes;
  final List<MasterDataModel> initialSelectedCuisineTypes;
  final ValueChanged<List<MasterDataModel>> onChanged;

  const CuisineTypesSection({
    super.key,
    required this.cuisineTypes,
    required this.initialSelectedCuisineTypes,
    required this.onChanged,
  });

  @override
  State<CuisineTypesSection> createState() => _CuisineTypesSectionState();
}

class _CuisineTypesSectionState extends State<CuisineTypesSection> {
  late List<MasterDataModel> _selectedCuisineTypes;

  @override
  void initState() {
    super.initState();
    _selectedCuisineTypes = List.from(widget.initialSelectedCuisineTypes);
  }

  @override
  Widget build(BuildContext context) {
    return FormSection(
      label: 'Cuisine Types',
      required: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: widget.cuisineTypes.map((c) {
            final isSelected = _selectedCuisineTypes.contains(c);
            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedCuisineTypes.remove(c);
                  } else {
                    _selectedCuisineTypes.add(c);
                  }
                });
                widget.onChanged(_selectedCuisineTypes);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  gradient: isSelected ? AppColors.primaryGradient : null,
                  color: isSelected ? null : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? Colors.transparent : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isSelected)
                      const Padding(
                        padding: EdgeInsets.only(right: 6),
                        child: Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                    Text(
                      c.displayName,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected ? Colors.white : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
