import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';
import 'package:my_shop/core/presentation/widgets/custom_loading_indicator.dart';
import 'package:my_shop/features/categories/data/services/category_service.dart';
import 'package:my_shop/core/presentation/widgets/primary_gradient_button.dart';
import 'package:my_shop/core/presentation/widgets/app_dialog.dart';

class CreateCategoryScreen extends StatefulWidget {
  const CreateCategoryScreen({super.key});

  @override
  State<CreateCategoryScreen> createState() => _CreateCategoryScreenState();
}

class _CreateCategoryScreenState extends State<CreateCategoryScreen> {
  final CategoryService _categoryService = CategoryService();

  final TextEditingController _nameEnController = TextEditingController();
  final TextEditingController _nameMmController = TextEditingController();
  final TextEditingController _nameThController = TextEditingController();
  String _nameLang = 'EN';



  List<Map<String, dynamic>> _gallery = [];
  int _selectedGalleryIndex = 0;

  bool _isSaving = false;
  bool _isLoadingData = true;

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    setState(() => _isLoadingData = true);
    final results = await Future.wait([
      _categoryService.getCategoryGallery(),
    ]);

    if (mounted) {
      setState(() {
        _gallery = results[0] ?? [];
        _isLoadingData = false;
      });
    }
  }

  @override
  void dispose() {
    _nameEnController.dispose();
    _nameMmController.dispose();
    _nameThController.dispose();
    super.dispose();
  }

  Future<void> _saveCategory() async {
    if (_nameEnController.text.isEmpty &&
        _nameMmController.text.isEmpty &&
        _nameThController.text.isEmpty) {
      AppDialog.showToast(context, 'Please enter at least one category name', isError: true);
      return;
    }

    setState(() => _isSaving = true);

    final payload = {
      'nameEn': _nameEnController.text,
      'nameMm': _nameMmController.text,
      'nameTh': _nameThController.text,
      'imageUrl': _gallery.isNotEmpty
          ? _gallery[_selectedGalleryIndex]['imageUrl']
          : null,

      'isActive': true,
      'displayOrder': 1,
    };

    final success = await _categoryService.createCategory(payload);

    if (mounted) {
      if (success) {
        AppDialog.showToast(context, 'Successfully requested');
        Navigator.of(context).pop(true);
      } else {
        setState(() => _isSaving = false);
        AppDialog.showToast(context, 'Failed to create category', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Create Category',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1E293B),
          ),
        ),
        centerTitle: false,
        actions: const [SizedBox(width: 8)],
      ),
      body: _isLoadingData
          ? const Center(child: CustomLoadingIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CREATE NEW CATEGORY',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFCBD5E1),
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 20),



                      // Icon Gallery
                      Text(
                        'Choose icon',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildIconGallery(),
                      const SizedBox(height: 24),

                      // Name Lang Switcher
                      Text(
                        'Category name',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildLangField(
                        selectedLang: _nameLang,
                        onLangChanged: (l) => setState(() => _nameLang = l),
                        controller: _nameLang == 'EN'
                            ? _nameEnController
                            : _nameLang == 'MM'
                            ? _nameMmController
                            : _nameThController,
                        hint: 'Enter category name',
                      ),
                    ],
                  ),
                ),
              ],
            ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Colors.black.withValues(alpha: 0.05)),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: PrimaryGradientButton(
              onPressed: _saveCategory,
              isLoading: _isSaving,
              text: 'Create Category',
              height: 56,
              borderRadius: 16,
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildIconGallery() {
    if (_gallery.isEmpty) {
      return const Text(
        'No icons available',
        style: TextStyle(fontSize: 12, color: Colors.grey),
      );
    }

    return SizedBox(
      height: 60,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _gallery.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final isSelected = _selectedGalleryIndex == index;
          return GestureDetector(
            onTap: () => setState(() => _selectedGalleryIndex = index),
            child: Container(
              width: 60,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFFED3973)
                      : const Color(0xFFE2E8F0),
                  width: 2,
                ),
              ),
              child: Image.network(
                _gallery[index]['imageUrl'],
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.restaurant,
                  size: 24,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLangField({
    required String selectedLang,
    required ValueChanged<String> onLangChanged,
    required TextEditingController controller,
    required String hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: ['EN', 'MM', 'TH'].map((lang) {
            final selected = selectedLang == lang;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => onLangChanged(lang),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: selected ? const Color(0xFFED3973) : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selected
                          ? const Color(0xFFED3973)
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Text(
                    lang,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: selected ? Colors.white : const Color(0xFF64748B),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: controller,
          maxLength: 100,
          decoration: InputDecoration(
            counterText: '',
            hintText: hint,
            hintStyle: GoogleFonts.poppins(color: const Color(0xFFCBD5E1)),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }
}
