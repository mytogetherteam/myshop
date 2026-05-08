import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';
import 'package:my_shop/core/presentation/widgets/custom_loading_indicator.dart';
import 'package:my_shop/features/menu/data/models/menu_category_model.dart';
import 'package:my_shop/features/categories/data/services/category_service.dart';
import 'package:my_shop/core/presentation/widgets/primary_gradient_button.dart';
import 'package:my_shop/core/presentation/widgets/global_modal.dart';
import 'package:my_shop/core/presentation/widgets/success_sheet.dart';
import 'package:my_shop/core/presentation/widgets/confirmation_sheet.dart';
import 'package:my_shop/core/presentation/widgets/app_dialog.dart';


class EditCategoryScreen extends StatefulWidget {
  final MenuCategoryModel category;

  const EditCategoryScreen({super.key, required this.category});

  @override
  State<EditCategoryScreen> createState() => _EditCategoryScreenState();
}

class _EditCategoryScreenState extends State<EditCategoryScreen> {
  final CategoryService _categoryService = CategoryService();

  late final TextEditingController _nameEnController;
  late final TextEditingController _nameMmController;
  late final TextEditingController _nameThController;
  String _nameLang = 'EN';



  List<Map<String, dynamic>> _gallery = [];
  int _selectedGalleryIndex = 0;

  bool _isSaving = false;
  bool _isLoadingData = true;

  @override
  void initState() {
    super.initState();
    _nameEnController = TextEditingController(
      text: widget.category.nameEn ?? '',
    );
    _nameMmController = TextEditingController(
      text: widget.category.nameMm ?? '',
    );
    _nameThController = TextEditingController(
      text: widget.category.nameTh ?? '',
    );

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

        // Find existing icon in gallery
        if (widget.category.imageUrl != null) {
          _selectedGalleryIndex = _gallery.indexWhere(
            (icon) => icon['imageUrl'] == widget.category.imageUrl,
          );
          if (_selectedGalleryIndex == -1) _selectedGalleryIndex = 0;
        }

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

  Future<void> _updateCategory() async {
    if (_nameEnController.text.isEmpty &&
        _nameMmController.text.isEmpty &&
        _nameThController.text.isEmpty) {
      AppDialog.showToast(context, 'Please enter at least one category name', isError: true);
      return;
    }

    GlobalModal.show(
      context: context,
      child: ConfirmationSheet(
        title: 'Update Category?',
        message: 'Are you sure you want to save the changes to this category?',
        confirmLabel: 'Update',
        onConfirm: _performUpdate,
      ),
    );
  }

  Future<void> _performUpdate() async {
    setState(() => _isSaving = true);

    final payload = {
      'nameEn': _nameEnController.text,
      'nameMm': _nameMmController.text,
      'nameTh': _nameThController.text,
      'imageUrl': _gallery.isNotEmpty
          ? _gallery[_selectedGalleryIndex]['imageUrl']
          : null,

      'isActive': widget.category.isActive,
      'displayOrder': 1,
    };

    final success = await _categoryService.updateCategory(
      widget.category.id,
      payload,
    );

    if (mounted) {
      if (success) {
        AppDialog.showToast(context, 'Successfully requested');
        Navigator.of(context).pop(true);
      } else {
        setState(() => _isSaving = false);
        AppDialog.showToast(context, 'Failed to update category', isError: true);
      }
    }
  }

  Future<void> _deleteCategory() async {
    GlobalModal.show(
      context: context,
      child: ConfirmationSheet(
        title: 'Delete Category?',
        message:
            'Are you sure you want to delete this category? This action cannot be undone.',
        confirmLabel: 'Delete',
        confirmColor: const Color(0xFFEF4444),
        onConfirm: () async {
          final success =
              await _categoryService.deleteCategory(widget.category.id);
          if (mounted) {
            if (success) {
              Navigator.pop(context, true);
            } else {
              AppDialog.showToast(context, 'Failed to delete category', isError: true);
            }
          }
        },
      ),
    );
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
          'Edit Category',
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
              padding: const EdgeInsets.all(24.0),
              children: [
                if (widget.category.pendingStatus == 'REJECTED' && widget.category.rejectReason != null)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 24),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Rejected',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFFEF4444),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.category.rejectReason!,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: const Color(0xFFEF4444),
                          ),
                        ),
                      ],
                    ),
                  ),
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
                        'EDIT CATEGORY',
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
                const SizedBox(height: 24),
                TextButton.icon(
                  onPressed: _deleteCategory,
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Color(0xFFEF4444),
                  ),
                  label: Text(
                    'Delete category',
                    style: GoogleFonts.poppins(
                      color: const Color(0xFFEF4444),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
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
              onPressed: _updateCategory,
              isLoading: _isSaving,
              text: 'Update Category',
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
                _gallery[index]['imageUrl'].toString(),
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
