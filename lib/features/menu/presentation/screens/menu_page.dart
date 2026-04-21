import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_shop/core/presentation/widgets/custom_loading_indicator.dart';
import '../widgets/quick_action_cards.dart';
import '../widgets/menu_item_card.dart';
import 'add_new_item_screen.dart';
import '../../data/services/menu_service.dart';
import '../../data/models/menu_item_model.dart';
import '../../data/models/menu_category_model.dart';
import 'package:my_shop/core/presentation/widgets/skeleton.dart';

class MenuPage extends StatefulWidget {
  const MenuPage({super.key});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> with AutomaticKeepAliveClientMixin {
  final MenuService _menuService = MenuService();
  List<MenuCategoryModel> _categories = [];
  List<MenuItemModel> _items = [];
  MenuCategoryModel? _selectedCategory;
  bool _isLoadingCategories = true;
  bool _isLoadingItems = true;

  int _currentPage = 1;
  bool _hasMore = true;
  bool _isLoadingMoreItems = false;
  final ScrollController _scrollController = ScrollController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoadingMoreItems && _hasMore) {
        _fetchMoreItems();
      }
    }
  }

  Future<void> _fetchCategories() async {
    setState(() => _isLoadingCategories = true);
    final categories = await _menuService.getCategories();
    if (mounted) {
      setState(() {
        _categories = [
          MenuCategoryModel(id: 0, nameEn: 'All Categories', nameMm: 'All Categories', nameTh: 'All Categories', updatedAt: DateTime.now()),
          ...categories ?? [],
          MenuCategoryModel(id: 9999, nameEn: 'Other', nameMm: 'Other', nameTh: 'Other', updatedAt: DateTime.now()),
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

  Future<void> _fetchItems({bool refresh = true}) async {
    if (_selectedCategory == null) return;
    
    if (refresh) {
      setState(() {
        _isLoadingItems = true;
        _currentPage = 1;
        _hasMore = true;
      });
    }
    
    // If id is 0, fetch all items, otherwise filter by categoryId
    final int? filterId = _selectedCategory!.id == 0 ? null : _selectedCategory!.id;
    final items = await _menuService.getMenuItems(
      categoryId: filterId,
      page: _currentPage,
      limit: 20,
    );
    
    if (mounted) {
      setState(() {
        if (refresh) {
          _items = items ?? [];
        } else {
          if (items != null) {
            _items.addAll(items);
          }
        }
        _hasMore = items != null && items.length == 20;
        _isLoadingItems = false;
      });
    }
  }

  Future<void> _fetchMoreItems() async {
    setState(() => _isLoadingMoreItems = true);
    _currentPage++;
    await _fetchItems(refresh: false);
    if (mounted) {
      setState(() => _isLoadingMoreItems = false);
    }
  }

  void _onCategoryChanged(MenuCategoryModel? category) {
    if (category == null || category.id == _selectedCategory?.id) return;
    setState(() {
      _selectedCategory = category;
      _items = []; // Clear current items while loading
    });
    _fetchItems(refresh: true);
  }

  Future<void> _toggleItemAvailability(MenuItemModel item, bool available) async {
    final success = await _menuService.toggleAvailability(item.id, available);
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update availability'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      // Revert if failed
      _fetchItems(refresh: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header removed, handled by global AppBar
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  await _fetchCategories();
                },
                color: const Color(0xFFED3A72),
                child: SingleChildScrollView(
                  controller: _scrollController,
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
                        _buildSkeletonList()
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
                      if (_isLoadingMoreItems)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: CustomLoadingIndicator(size: 24, color: Color(0xFFED3A72)),
                          ),
                        ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
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
              return MenuItemCard(
                item: item,
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddNewItemScreen(item: item),
                    ),
                  );
                  if (result == true) {
                    _fetchItems(refresh: true);
                  }
                },
                onAvailabilityChanged: (available) {
                  _toggleItemAvailability(item, available);
                },
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

  Widget _buildSkeletonList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Skeleton
              const Skeleton(width: 72, height: 72),
              const SizedBox(width: 16),
              // Text Content Skeleton
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Skeleton(width: 120, height: 16),
                        Skeleton(width: 32, height: 16),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Skeleton(width: double.infinity, height: 12),
                    const SizedBox(height: 4),
                    const Skeleton(width: 150, height: 12),
                    const SizedBox(height: 12),
                    const Skeleton(width: 60, height: 14),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
