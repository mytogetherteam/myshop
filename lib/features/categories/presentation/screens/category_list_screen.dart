import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_shop/core/presentation/widgets/skeleton.dart';
import 'package:my_shop/features/menu/data/models/menu_category_model.dart';
import 'package:my_shop/features/categories/data/services/category_service.dart';
import 'create_category_screen.dart';
import 'edit_category_screen.dart';

class CategoryListScreen extends StatefulWidget {
  const CategoryListScreen({super.key});

  @override
  State<CategoryListScreen> createState() => _CategoryListScreenState();
}

class _CategoryListScreenState extends State<CategoryListScreen> {
  final CategoryService _categoryService = CategoryService();
  List<MenuCategoryModel> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
    _prefetchCategoryData();
  }

  /// Pre-fetch master data and gallery icons for the category creation/edit screen
  Future<void> _prefetchCategoryData() async {
    try {
      await Future.wait([
        _categoryService.getMasterCategories(),
        _categoryService.getCategoryGallery(),
      ]);
      debugPrint('[CategoryListScreen] Category master data pre-fetched');
    } catch (e) {
      debugPrint('[CategoryListScreen] Error pre-fetching category data: $e');
    }
  }


  Future<void> refresh() async {
    await _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    setState(() => _isLoading = true);
    final categories = await _categoryService.getCategories(forceRefresh: true);
    if (mounted) {
      setState(() {
        _categories = categories ?? [];
        _isLoading = false;
      });
    }
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      final item = _categories.removeAt(oldIndex);
      _categories.insert(newIndex, item);
    });
    
    // Proactively send reorder request to backend
    _categoryService.reorderCategories(_categories.map((c) => c.id).toList());
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
          'Category',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1E293B),
          ),
        ),
        centerTitle: false,
        actions: const [
          SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchCategories,
        color: const Color(0xFFED3A72),
        child: _isLoading ? _buildSkeletonList() : _buildCategoryList(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateCategoryScreen()),
          );
          if (result == true) _fetchCategories();
        },
        backgroundColor: const Color(0xFFED3A72),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildCategoryList() {
    if (_categories.isEmpty) {
      return Center(
        child: Text(
          'No categories found',
          style: GoogleFonts.poppins(color: const Color(0xFF94A3B8)),
        ),
      );
    }

    return ReorderableListView.builder(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 100),
      itemCount: _categories.length,
      onReorder: _onReorder,
      buildDefaultDragHandles: false,
      proxyDecorator: (child, index, animation) {
        return AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            final double scale = lerpDouble(1, 1.02, animation.value)!;
            final double elevation = lerpDouble(0, 6, animation.value)!;
            return Transform.scale(
              scale: scale,
              child: Material(
                elevation: elevation,
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                child: child,
              ),
            );
          },
          child: child,
        );
      },
      itemBuilder: (context, index) {
        final category = _categories[index];
        return Padding(
          key: ValueKey(category.id),
          padding: const EdgeInsets.only(bottom: 12),
          child: _CategoryCard(
            category: category,
            index: index,
            onEdit: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditCategoryScreen(category: category),
                ),
              );
              if (result == true) _fetchCategories();
            },
          ),
        );
      },
    );
  }

  Widget _buildSkeletonList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFF1F5F9)),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Skeleton(width: 24, height: 24), // Drag handle placeholder
                const SizedBox(width: 12),
                const Skeleton(width: 50, height: 50, borderRadius: 12), // Icon placeholder
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Skeleton(width: 120, height: 16),
                      const SizedBox(height: 8),
                      const Skeleton(width: 60, height: 12),
                    ],
                  ),
                ),
                const Skeleton(width: 32, height: 32, borderRadius: 8), // Edit icon placeholder
              ],
            ),
          ),
        );
      },
    );
  }

  double? lerpDouble(num a, num b, double t) => a + (b - a) * t;
}

class _CategoryCard extends StatelessWidget {
  final MenuCategoryModel category;
  final VoidCallback onEdit;
  final int index;

  const _CategoryCard({
    required this.category,
    required this.onEdit,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFF1F5F9)),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          ReorderableDragStartListener(
            index: index,
            child: Container(
              color: Colors.transparent,
              padding: const EdgeInsets.only(top: 8, bottom: 8, right: 8, left: 0),
              child: const Icon(Icons.drag_indicator, color: Color(0xFF94A3B8), size: 24),
            ),
          ),
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _getCategoryColor(category.nameEn),
              borderRadius: BorderRadius.circular(16),
            ),
            child: category.imageUrl != null && category.imageUrl!.startsWith('assets/')
                ? Image.asset(
                    category.imageUrl!,
                    width: 32,
                    height: 32,
                    fit: BoxFit.contain,
                  )
                : Image.network(
                    category.imageUrl ?? '',
                    width: 32,
                    height: 32,
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.restaurant, size: 20, color: Color(0xFF94A3B8)),
                  ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.displayName,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                Text(
                  '${category.itemCount} items',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onEdit,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Icon(Icons.edit_note_rounded, color: Color(0xFF1E293B), size: 24),
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String? name) {
    switch (name?.toLowerCase()) {
      case 'main dish':
        return const Color(0xFFFFF7ED);
      case 'drinks':
        return const Color(0xFFF0F9FF);
      case 'soup':
        return const Color(0xFFF0FDFA);
      case 'dessert':
        return const Color(0xFFFFF1F2);
      case 'salad':
        return const Color(0xFFF0FDF4);
      default:
        return const Color(0xFFF8FAFC);
    }
  }
}
