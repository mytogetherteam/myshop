import 'package:flutter/material.dart';
import 'package:my_shop/core/presentation/widgets/custom_search_dropdown.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_shop/core/utils/app_colors.dart';
import 'package:my_shop/core/presentation/widgets/custom_loading_indicator.dart';
import '../widgets/quick_action_cards.dart';
import '../widgets/menu_item_card.dart';
import 'add_new_item_screen.dart';
import '../../data/services/menu_service.dart';
import '../../data/models/menu_item_model.dart';
import '../../data/models/menu_category_model.dart';
import 'package:my_shop/core/presentation/widgets/skeleton.dart';
import 'package:my_shop/core/presentation/widgets/app_dialog.dart';
import 'package:my_shop/core/localization/app_localizations.dart';

class MenuPage extends StatefulWidget {
  const MenuPage({super.key});

  @override
  State<MenuPage> createState() => MenuPageState();
}

class MenuPageState extends State<MenuPage> with AutomaticKeepAliveClientMixin {
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
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoadingMoreItems && _hasMore) {
        _fetchMoreItems();
      }
    }
  }

  Future<void> refresh() async {
    await _fetchCategories(forceRefresh: true);
  }

  Future<void> _fetchCategories({bool forceRefresh = false}) async {
    setState(() => _isLoadingCategories = true);
    final categories = await _menuService.getCategories(
      forceRefresh: forceRefresh,
    );

    if (mounted) {
      final t = AppLocalizations.of(context);
      setState(() {
        _categories = [
          MenuCategoryModel(
            id: 0,
            nameEn: t?.translate('all_categories') ?? 'All Categories',
            nameMm: t?.translate('all_categories') ?? 'All Categories',
            nameTh: t?.translate('all_categories') ?? 'All Categories',
          ),
          ...categories ?? [],
        ];
        _isLoadingCategories = false;
        if (_categories.isNotEmpty) {
          _selectedCategory = _categories.first;
          _fetchItems(refresh: true);
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
    final int? filterId = _selectedCategory!.id == 0
        ? null
        : _selectedCategory!.id;
    final items = await _menuService.getMenuItems(
      categoryId: filterId,
      page: _currentPage,
      limit: 20,
      forceRefresh: refresh,
    );

    if (mounted) {
      setState(() {
        if (refresh) {
          _items = items ?? [];
        } else {
          _items.addAll(items ?? []);
        }

        // Debug logging
        for (var item in _items) {
          debugPrint(
            'DEBUG: Item: ${item.nameEn}, Status: ${item.pendingStatus}',
          );
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

  Future<void> _toggleItemAvailability(
    MenuItemModel item,
    bool available,
  ) async {
    final success = await _menuService.toggleAvailability(item.id, available);
    if (!success && mounted) {
      final t = AppLocalizations.of(context);
      AppDialog.showToast(
        context,
        t?.translate('failed_update_availability') ?? 'Failed to update availability',
        isError: true,
      );
      // Revert if failed
      _fetchItems(refresh: true);
    }
  }

  Future<void> _toggleItemPublishStatus(
    MenuItemModel item,
    bool isPublished,
  ) async {
    final newStatus = isPublished ? 'PUBLISHED' : 'UNPUBLISHED';
    final success = await _menuService.toggleMenuItemPublishStatus(
      item.id,
      newStatus,
    );
    if (!success && mounted) {
      final t = AppLocalizations.of(context);
      AppDialog.showToast(
        context,
        t?.translate('failed_update_publish') ?? 'Failed to update publish status',
        isError: true,
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
                onRefresh: refresh,
                color: AppColors.primary,

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
                          children: [Expanded(child: _buildCategoryDropdown())],
                        ),
                      ),
                      const SizedBox(height: 24),
                      QuickActionCards(onRefresh: refresh),
                      const SizedBox(height: 24),
                      // Menu Sections
                      if (_isLoadingCategories || _isLoadingItems)
                        _buildSkeletonList()
                      else if (_items.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(40.0),
                            child: Text(
                              AppLocalizations.of(context)?.translate('no_items_found') ?? 'No items found',
                              style: GoogleFonts.poppins(
                                color: const Color(0xFF94A3B8),
                              ),
                            ),
                          ),
                        )
                      else
                        ..._buildMenuSections(),
                      if (_isLoadingMoreItems)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: CustomLoadingIndicator(
                              size: 24,
                              color: AppColors.primary,
                            ),
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

  Widget _buildCategorySection(String title, List<MenuItemModel> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Text(
            title,
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
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
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
              onPublishStatusChanged: (isPublished) {
                _toggleItemPublishStatus(item, isPublished);
              },
            );
          },
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  List<Widget> _buildMenuSections() {
    // Group items by category ID
    final Map<int, List<MenuItemModel>> itemsByCategoryId = {};
    final List<MenuItemModel> uncategorizedItems = [];

    for (var item in _items) {
      final categoryId = item.menuCategoryId;
      if (categoryId == null) {
        uncategorizedItems.add(item);
      } else {
        final hasCategory = _categories.any(
          (c) => c.id == categoryId && c.id != 0,
        );
        if (hasCategory) {
          itemsByCategoryId.putIfAbsent(categoryId, () => []).add(item);
        } else {
          uncategorizedItems.add(item);
        }
      }
    }

    final List<Widget> sections = [];

    // Iterate through categories in their exact custom-sorted order
    for (var category in _categories) {
      if (category.id == 0) continue; // Skip 'All Categories' virtual category

      final categoryItems = itemsByCategoryId[category.id];
      if (categoryItems != null && categoryItems.isNotEmpty) {
        sections.add(
          _buildCategorySection(category.displayName, categoryItems),
        );
      }
    }

    // Add fallback section for uncategorized/orphan items
    if (uncategorizedItems.isNotEmpty) {
      final t = AppLocalizations.of(context);
      sections.add(_buildCategorySection(t?.translate('other') ?? 'Other', uncategorizedItems));
    }

    return sections;
  }

  Widget _buildCategoryDropdown() {
    return CustomSearchDropdown<MenuCategoryModel>(
      items: _categories,
      value: _selectedCategory,
      itemLabelBuilder: (category) => category.displayName,
      onChanged: _onCategoryChanged,
      hintText: AppLocalizations.of(context)?.translate('select_category') ?? 'Select Category',
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
