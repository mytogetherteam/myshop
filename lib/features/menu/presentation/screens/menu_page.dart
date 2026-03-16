import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/menu_header.dart';
import '../widgets/quick_action_cards.dart';
import '../widgets/menu_item_card.dart';
import 'add_new_item_screen.dart';
import '../../data/services/menu_service.dart';
import '../../data/models/menu_item_model.dart';
import '../../data/models/menu_category_model.dart';

class MenuPage extends StatefulWidget {
  const MenuPage({super.key});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  final MenuService _menuService = MenuService();
  List<MenuCategoryModel> _categories = [];
  List<MenuItemModel> _items = [];
  MenuCategoryModel? _selectedCategory;
  bool _isLoadingCategories = true;
  bool _isLoadingItems = true;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    setState(() => _isLoadingCategories = true);
    final categories = await _menuService.getCategories();
    if (mounted) {
      setState(() {
        _categories = [
          MenuCategoryModel(id: 0, nameEn: 'All Categories', nameMm: 'All Categories', nameTh: 'All Categories'),
          ...categories ?? []
        ];
        _isLoadingCategories = false;
        if (_categories.isNotEmpty) {
          _selectedCategory = _categories.first;
          _fetchItems();
        } else {
          _isLoadingItems = false;
        }
      });
    }
  }

  Future<void> _fetchItems() async {
    if (_selectedCategory == null) return;
    setState(() => _isLoadingItems = true);
    
    // If id is 0, fetch all items, otherwise filter by categoryId
    final int? filterId = _selectedCategory!.id == 0 ? null : _selectedCategory!.id;
    final items = await _menuService.getMenuItems(categoryId: filterId);
    
    if (mounted) {
      setState(() {
        _items = items ?? [];
        _isLoadingItems = false;
      });
    }
  }

  void _onCategoryChanged(MenuCategoryModel? category) {
    if (category == null || category.id == _selectedCategory?.id) return;
    setState(() {
      _selectedCategory = category;
      _items = []; // Clear current items while loading
    });
    _fetchItems();
  }

  Future<void> _toggleItemAvailability(MenuItemModel item, bool available) async {
    final success = await _menuService.toggleAvailability(item.id, available);
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update availability')),
      );
      // Revert if failed
      _fetchItems();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const MenuHeader(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  await _fetchCategories();
                },
                color: const Color(0xFFED3A72),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
                      // Dropdown / Selection Section
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildCategoryDropdown(),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(Icons.search, color: Color(0xFF1E293B), size: 24),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      const QuickActionCards(),
                      const SizedBox(height: 24),
                      // Menu Sections
                      if (_isLoadingCategories || _isLoadingItems)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(40.0),
                            child: CircularProgressIndicator(color: Color(0xFFED3A72)),
                          ),
                        )
                      else if (_items.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(40.0),
                            child: Text(
                              'No items found',
                              style: GoogleFonts.poppins(color: const Color(0xFF94A3B8)),
                            ),
                          ),
                        )
                      else
                        ..._buildMenuSections(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddNewItemScreen(),
            ),
          );
          if (result == true) {
            _fetchItems();
          }
        },
        backgroundColor: const Color(0xFFED3A72),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }

  List<Widget> _buildMenuSections() {
    // Group items by category name
    final Map<String, List<MenuItemModel>> groupedItems = {};
    
    for (var item in _items) {
      final categoryName = _categories.firstWhere(
        (c) => c.id == item.categoryId,
        orElse: () => MenuCategoryModel(id: item.categoryId ?? -1, nameEn: 'Other', nameMm: 'Other', nameTh: 'Other'),
      ).displayName;
      
      if (!groupedItems.containsKey(categoryName)) {
        groupedItems[categoryName] = [];
      }
      groupedItems[categoryName]!.add(item);
    }

    return groupedItems.entries.map((entry) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Text(
              entry.key,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1E293B),
              ),
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: entry.value.length,
            itemBuilder: (context, index) {
              final item = entry.value[index];
              return InkWell(
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddNewItemScreen(item: item),
                    ),
                  );
                  if (result == true) {
                    _fetchItems();
                  }
                },
                child: MenuItemCard(
                  item: item,
                  onAvailabilityChanged: (available) {
                    _toggleItemAvailability(item, available);
                  },
                ),
              );
            },
          ),
          const SizedBox(height: 12),
        ],
      );
    }).toList();
  }

  Widget _buildCategoryDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<MenuCategoryModel>(
          value: _selectedCategory,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF1E293B), size: 24),
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: const Color(0xFF1E293B),
          ),
          hint: Text(
            'Select Category',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: const Color(0xFF94A3B8),
            ),
          ),
          items: _categories.map((category) {
            return DropdownMenuItem<MenuCategoryModel>(
              value: category,
              child: Text(category.displayName),
            );
          }).toList(),
          onChanged: _onCategoryChanged,
        ),
      ),
    );
  }
}
