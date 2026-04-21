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
  late TextEditingController _nameController;
  final List<Map<String, dynamic>> _icons = [
    {'path': 'assets/images/Category.png', 'color': Color(0xFFFFF7ED)},
    {'path': 'assets/images/Salad.png', 'color': Color(0xFFF0FDF4)},
    {'path': 'assets/images/Soup.png', 'color': Color(0xFFF0FDFA)},
    {'path': 'assets/images/Dessert.png', 'color': Color(0xFFFFF1F2)},
    {'path': 'assets/images/Noodle.png', 'color': Color(0xFFF0F9FF)},
    {'path': 'assets/images/Drink.png', 'color': Color(0xFFFFFAF1)},
  ];
  
  late int _selectedIconIndex;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category.displayName);
    _selectedIconIndex = _icons.indexWhere((icon) => icon['path'] == widget.category.imageUrl);
    if (_selectedIconIndex == -1) _selectedIconIndex = 0;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _updateCategory() async {
    if (_nameController.text.isEmpty) return;

    setState(() => _isSaving = true);
    final success = await _categoryService.updateCategory(widget.category.id, {
      'nameEn': _nameController.text,
      'imageUrl': _icons[_selectedIconIndex]['path'],
    });

    if (mounted) {
      if (success) {
        Navigator.pop(context, true);
      } else {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update category'),
            backgroundColor: Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  Future<void> _deleteCategory() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: const Text('Are you sure you want to delete this category?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await _categoryService.deleteCategory(widget.category.id);
      if (mounted) {
        if (success) {
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to delete category'),
              backgroundColor: Color(0xFFEF4444),
            ),
          );
        }
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
          'Edit Category',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1E293B),
          ),
        ),
        centerTitle: false,
      ),
      body: Padding(
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
                    'CREATE NEW CATEGORY',
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
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      hintText: 'eg: Today\'s Recommendation',
                      hintStyle: GoogleFonts.poppins(color: const Color(0xFFCBD5E1)),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
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
            const Spacer(),
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
                        'Save',
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
    );
  }
}
