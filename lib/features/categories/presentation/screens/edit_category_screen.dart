import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';
import 'package:my_shop/core/presentation/widgets/custom_loading_indicator.dart';
import 'package:my_shop/features/menu/data/models/menu_category_model.dart';
import 'package:my_shop/features/categories/data/services/category_service.dart';
import 'package:my_shop/core/presentation/widgets/primary_gradient_button.dart';
import 'package:my_shop/core/presentation/widgets/global_modal.dart';
import 'package:my_shop/core/presentation/widgets/confirmation_sheet.dart';
import 'package:my_shop/core/presentation/widgets/app_dialog.dart';
import 'package:my_shop/core/localization/app_localizations.dart';


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
      AppDialog.showToast(context, AppLocalizations.of(context)?.translate('please_enter_category_name') ?? 'Please Enter at Least One Category Name', isError: true);
      return;
    }

    GlobalModal.show(
      context: context,
      child: ConfirmationSheet(
        title: AppLocalizations.of(context)?.translate('update_category_title') ?? 'Update Category?',
        message: AppLocalizations.of(context)?.translate('update_category_confirm') ?? 'Are you sure you want to save the changes to this category?',
        confirmLabel: AppLocalizations.of(context)?.translate('update') ?? 'Update',
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
        AppDialog.showToast(context, AppLocalizations.of(context)?.translate('successfully_uploaded') ?? 'Successfully Uploaded');
        Navigator.of(context).pop(true);
      } else {
        setState(() => _isSaving = false);
        AppDialog.showToast(context, AppLocalizations.of(context)?.translate('failed_update_category') ?? 'Failed to Update Category', isError: true);
      }
    }
  }

  Future<void> _deleteCategory() async {
    GlobalModal.show(
      context: context,
      child: ConfirmationSheet(
        title: AppLocalizations.of(context)?.translate('delete_category_title') ?? 'Delete Category?',
        message:
            AppLocalizations.of(context)?.translate('delete_category_confirm') ?? 'Are you sure you want to delete this category? This action cannot be undone.',
        confirmLabel: AppLocalizations.of(context)?.translate('delete') ?? 'Delete',
        confirmColor: const Color(0xFFEF4444),
        onConfirm: () async {
          final success =
              await _categoryService.deleteCategory(widget.category.id);
          if (mounted) {
            if (success) {
              Navigator.pop(context, true);
            } else {
              AppDialog.showToast(context, AppLocalizations.of(context)?.translate('failed_delete_category') ?? 'Failed to Delete Category', isError: true);
            }
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark ? Theme.of(context).cardColor : Colors.white,
      appBar: AppBar(
        backgroundColor: Theme.of(context).brightness == Brightness.dark ? Theme.of(context).cardColor : Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          AppLocalizations.of(context)?.translate('edit_category') ?? 'Edit Category',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        centerTitle: false,
        actions: const [SizedBox(width: 8)],
      ),
      body: _isLoadingData
          ? Center(child: CustomLoadingIndicator())
          : ListView(
              padding: const EdgeInsets.all(24.0),
              children: [

                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
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
                        (AppLocalizations.of(context)?.translate('edit_category') ?? 'EDIT CATEGORY').toUpperCase(),
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFCBD5E1),
                          letterSpacing: 0.8,
                        ),
                      ),
                      SizedBox(height: 20),



                      // Icon Gallery
                      Text(
                        AppLocalizations.of(context)?.translate('choose_icon') ?? 'Choose Icon',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                      SizedBox(height: 12),
                      _buildIconGallery(),
                      SizedBox(height: 24),

                      // Name Lang Switcher
                      Text(
                        AppLocalizations.of(context)?.translate('category_name') ?? 'Category Name',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                      SizedBox(height: 12),
                      _buildLangField(
                        selectedLang: _nameLang,
                        onLangChanged: (l) => setState(() => _nameLang = l),
                        controller: _nameLang == 'EN'
                            ? _nameEnController
                            : _nameLang == 'MM'
                            ? _nameMmController
                            : _nameThController,
                        hint: AppLocalizations.of(context)?.translate('enter_category_name') ?? 'Enter Category Name',
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24),
                TextButton.icon(
                  onPressed: _deleteCategory,
                  icon: Icon(
                    Icons.delete_outline,
                    color: Color(0xFFEF4444),
                  ),
                  label: Text(
                    AppLocalizations.of(context)?.translate('delete_category') ?? 'Delete Category',
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
          color: Theme.of(context).cardColor,
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
              text: AppLocalizations.of(context)?.translate('update') ?? 'Update Category',
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
      return Text(
        AppLocalizations.of(context)?.translate('no_icons_available') ?? 'No Icons Available',
        style: TextStyle(fontSize: 12, color: Colors.grey),
      );
    }

    return SizedBox(
      height: 60,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _gallery.length,
        separatorBuilder: (context, index) => SizedBox(width: 12),
        itemBuilder: (context, index) {
          final isSelected = _selectedGalleryIndex == index;
          return GestureDetector(
            onTap: () => setState(() => _selectedGalleryIndex = index),
            child: Container(
              width: 60,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFFED3973)
                      : Theme.of(context).dividerColor,
                  width: 2,
                ),
              ),
              child: Image.network(
                _gallery[index]['imageUrl'].toString(),
                errorBuilder: (context, error, stackTrace) => Icon(
                  Icons.restaurant,
                  size: 24,
                  color: (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
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
                    color: selected ? const Color(0xFFED3973) : (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF0F172A) : Colors.white),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selected
                          ? const Color(0xFFED3973)
                          : Theme.of(context).dividerColor,
                    ),
                  ),
                  child: Text(
                    lang,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: selected ? Colors.white : (Theme.of(context).brightness == Brightness.dark ? const Color(0xFFCBD5E1) : const Color(0xFF64748B)),
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
          maxLength: 100,
          style: GoogleFonts.poppins(color: Theme.of(context).textTheme.bodyLarge?.color),
          decoration: InputDecoration(
            counterText: '',
            hintText: hint,
            hintStyle: GoogleFonts.poppins(color: (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF94A3B8) : const Color(0xFFCBD5E1))),
            filled: true,
            fillColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            suffixIcon: ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (context, value, child) {
                if (value.text.isEmpty) return const SizedBox.shrink();
                return IconButton(
                  icon: Icon(Icons.clear, color: Colors.grey, size: 20),
                  onPressed: () {
                    controller.clear();
                  },
                );
              },
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
