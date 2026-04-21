import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_shop/core/presentation/widgets/custom_loading_indicator.dart';
import 'package:my_shop/features/menu/data/models/menu_category_model.dart';
import 'package:my_shop/features/categories/data/services/category_service.dart';

class EditCategoryScreen extends StatefulWidget {
  final MenuCategoryModel category;

  const EditCategoryScreen({super.key, required this.category});

  @override
  State<EditCategoryScreen> createState() => _EditCategoryScreenState();
}

class _EditCategoryScreenState extends State<EditCategoryScreen> {
  final CategoryService _categoryService = CategoryService();
  
  // Multi-language controllers
  late TextEditingController _nameEnController;
  late TextEditingController _nameMmController;
  late TextEditingController _nameThController;
  
  String _selectedLang = 'EN';
  
  final List<Map<String, dynamic>> _icons = [
    {'path': 'assets/images/food_3d.png', 'color': const Color(0xFFFFF7ED)},
    {'path': 'assets/images/drinks_3d.png', 'color': const Color(0xFFF0F9FF)},
    {'path': 'assets/images/snacks_3d.png', 'color': const Color(0xFFFFF1F2)},
    {'path': 'assets/images/Category.png', 'color': const Color(0xFFFFFAF1)},
  ];
  
  late int _selectedIconIndex;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameEnController = TextEditingController(text: widget.category.nameEn);
    _nameMmController = TextEditingController(text: widget.category.nameMm);
    _nameThController = TextEditingController(text: widget.category.nameTh);
    
    _selectedIconIndex = _icons.indexWhere((icon) => icon['path'] == widget.category.imageUrl);
    if (_selectedIconIndex == -1) _selectedIconIndex = 0;
  }

  @override
  void dispose() {
    _nameEnController.dispose();
    _nameMmController.dispose();
    _nameThController.dispose();
    super.dispose();
  }

  Future<void> _updateCategory() async {
    if (_nameEnController.text.isEmpty && _nameMmController.text.isEmpty && _nameThController.text.isEmpty) {
      _showToast('Please enter at least one name', isError: true);
      return;
    }

    setState(() => _isSaving = true);
    final success = await _categoryService.updateCategory(widget.category.id, {
      'nameEn': _nameEnController.text,
      'nameMm': _nameMmController.text,
      'nameTh': _nameThController.text,
      'imageUrl': _icons[_selectedIconIndex]['path'],
    });

    if (mounted) {
      if (success) {
        _showToast('Category updated successfully');
        Navigator.pop(context, true);
      } else {
        setState(() => _isSaving = false);
        _showToast('Failed to update category', isError: true);
      }
    }
  }

  Future<void> _deleteCategory() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete Category', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: Text('Are you sure you want to delete this category?', style: GoogleFonts.poppins()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.poppins(color: const Color(0xFF64748B))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: GoogleFonts.poppins(color: const Color(0xFFEF4444), fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await _categoryService.deleteCategory(widget.category.id);
      if (mounted) {
        if (success) {
          _showToast('Category deleted successfully');
          Navigator.pop(context, true);
        } else {
          _showToast('Failed to delete category', isError: true);
        }
      }
    }
  }

  void _showToast(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white),
        ),
        backgroundColor: isError ? const Color(0xFFEF4444) : const Color(0xFFED3A72),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(20),
        duration: const Duration(seconds: 2),
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
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                      'EDIT CATEGORY',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFCBD5E1),
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Choose icon',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 60,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _icons.length,
                        separatorBuilder: (context, index) => const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          final isSelected = _selectedIconIndex == index;
                          return GestureDetector(
                            onTap: () => setState(() => _selectedIconIndex = index),
                            child: Container(
                              width: 60,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _icons[index]['color'],
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected ? const Color(0xFFED3A72) : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              child: Image.asset(
                                _icons[index]['path'],
                                errorBuilder: (context, error, stackTrace) => const Icon(Icons.restaurant, size: 24, color: Color(0xFF94A3B8)),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Category name',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildLangSwitcher(),
                    const SizedBox(height: 16),
                    _buildNameField(),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: _deleteCategory,
                icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444)),
                label: Text(
                  'Delete category',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFFEF4444),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _updateCategory,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFED3A72),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: _isSaving
                      ? const CustomLoadingIndicator(size: 24, color: Colors.white)
                      : Text(
                          'Save changes',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLangSwitcher() {
    return Row(
      children: ['EN', 'MM', 'TH'].map((lang) {
        final isSelected = _selectedLang == lang;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () => setState(() => _selectedLang = lang),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFED3A72) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: isSelected ? const Color(0xFFED3A72) : const Color(0xFFE2E8F0)),
              ),
              child: Text(
                lang,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : const Color(0xFF64748B),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNameField() {
    TextEditingController controller;
    String hint;
    
    switch (_selectedLang) {
      case 'MM':
        controller = _nameMmController;
        hint = 'eg: ယနေ့အထူးအစီအစဉ်';
        break;
      case 'TH':
        controller = _nameThController;
        hint = 'เช่น: เมนูแนะนำวันนี้';
        break;
      default:
        controller = _nameEnController;
        hint = 'eg: Today\'s Recommendation';
    }

    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(color: const Color(0xFFCBD5E1)),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
