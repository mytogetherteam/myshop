import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_shop/core/utils/app_colors.dart';
import 'package:my_shop/core/presentation/widgets/skeleton.dart';
import '../widgets/menu_item_card.dart';
import 'package:my_shop/core/presentation/widgets/app_dialog.dart';
import 'package:my_shop/core/utils/app_logger.dart';
import '../../data/services/menu_service.dart';
import '../../data/models/menu_item_model.dart';
import '../../data/models/menu_category_model.dart';
import 'add_new_item_screen.dart';
import 'dart:async';
import 'package:my_shop/core/localization/app_localizations.dart';

class ManageShopMenuPage extends StatefulWidget {
  const ManageShopMenuPage({super.key});

  @override
  State<ManageShopMenuPage> createState() => _ManageShopMenuPageState();
}

class _ManageShopMenuPageState extends State<ManageShopMenuPage> {
  final MenuService _menuService = MenuService();
  final List<MenuItemModel> _items = [];
  List<MenuItemModel> _filteredItems = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _page =
      0; // or 1 depending on backend, let's assume 0-indexed as per spring standard or 1-indexed. The original code used `limit: 100` but no page. I'll use `page: 0`.
  final int _limit = 20;

  final TextEditingController _searchCtrl = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _debounce;
  bool _isSearching = false;

  List<MenuCategoryModel> _categories = [];
  final Map<int, GlobalKey> _categoryKeys = {};
  final List<dynamic> _listItems = [];

  @override
  void initState() {
    super.initState();
    _page =
        0; // The original getMenuItems defaults to page=1 if not specified, I'll pass 0 or 1. Let's use 0. If backend is 1-indexed, it might return empty for 0. Let's use 1 as default in menu_service was 1.
    _page = 1;
    _fetchItems(isRefresh: true);
    _prefetchMasterData();
    _searchCtrl.addListener(_onSearchChanged);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoadingMore && _hasMore) {
        _fetchItems();
      }
    }
  }

  Future<void> refresh() async {
    await _fetchItems(isRefresh: true);
    await _prefetchMasterData();
  }

  Future<void> _prefetchMasterData() async {
    try {
      final results = await Future.wait([
        _menuService.getCategories(forceRefresh: false),
        _menuService.getMasterCategories(),
        _menuService.getMenuTags(),
      ]);
      if (mounted) {
        setState(() {
          _categories = (results[0] as List<MenuCategoryModel>?) ?? [];
          _buildListItems();
        });
      }
      AppLogger.lifecycle('ManageShopMenuPage: master data pre-fetched');
    } catch (e) {
      AppLogger.error('ManageShopMenuPage: failed to pre-fetch master data', e);
    }
  }

  Future<void> _fetchItems({bool isRefresh = false}) async {
    if (isRefresh) {
      _page = 1;
      _hasMore = true;
      if (mounted) setState(() => _isLoading = true);
    } else {
      if (mounted) setState(() => _isLoadingMore = true);
    }

    try {
      final fetchedItems = await _menuService.getMenuItems(
        categoryId: null,
        limit: _limit,
        page: _page,
        forceRefresh: isRefresh,
      );

      if (mounted) {
        setState(() {
          if (isRefresh) {
            _items.clear();
          }
          if (fetchedItems != null) {
            _items.addAll(fetchedItems);
            _hasMore = fetchedItems.length == _limit;
            if (_hasMore) _page++;
          } else {
            _hasMore = false;
          }
          _applyFilter();
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      AppLogger.error('ManageShopMenuPage: failed to fetch items', e);
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() {
        _applyFilter();
      });
    });
  }

  void _applyFilter() {
    final query = _searchCtrl.text.toLowerCase();
    if (query.isEmpty) {
      _filteredItems = List.from(_items);
    } else {
      _filteredItems = _items.where((item) {
        return item.displayName.toLowerCase().contains(query) ||
            (item.displayDescription.toLowerCase().contains(query));
      }).toList();
    }
    _buildListItems();
  }

  void _buildListItems() {
    _listItems.clear();
    _categoryKeys.clear();

    if (_categories.isEmpty || _filteredItems.isEmpty) {
      _listItems.addAll(_filteredItems);
      return;
    }

    for (int i = 0; i < _categories.length; i++) {
      final category = _categories[i];
      final itemsInCategory = _filteredItems
          .where((item) => item.menuCategoryId == category.id)
          .toList();

      if (itemsInCategory.isNotEmpty) {
        _categoryKeys[i] = GlobalKey();
        _listItems.add(category);
        _listItems.addAll(itemsInCategory);
      }
    }

    final knownCategoryIds = _categories.map((c) => c.id).toSet();
    final uncategorized = _filteredItems
        .where((item) => !knownCategoryIds.contains(item.menuCategoryId))
        .toList();
    if (uncategorized.isNotEmpty) {
      _listItems.addAll(uncategorized);
    }
  }

  Future<void> _toggleItemAvailability(
    MenuItemModel item,
    bool available,
  ) async {
    final index = _filteredItems.indexWhere((i) => i.id == item.id);
    final globalIndex = _items.indexWhere((i) => i.id == item.id);
    if (index == -1 || globalIndex == -1) return;

    // Optimistic Update
    setState(() {
      final updatedItem = item.copyWith(isAvailable: available);
      _filteredItems[index] = updatedItem;
      _items[globalIndex] = updatedItem;
    });

    final success = await _menuService.toggleAvailability(item.id, available);

    if (!success && mounted) {
      // Revert on failure
      setState(() {
        final revertedItem = item.copyWith(isAvailable: !available);
        _filteredItems[index] = revertedItem;
        _items[globalIndex] = revertedItem;
      });
      final t = AppLocalizations.of(context);
      AppDialog.showToast(
        context,
        t?.translate('failed_update_availability') ??
            'Failed to Update Availability',
        isError: true,
      );
    }
  }

  Future<void> _toggleItemPublishStatus(
    MenuItemModel item,
    bool isPublished,
  ) async {
    final index = _filteredItems.indexWhere((i) => i.id == item.id);
    final globalIndex = _items.indexWhere((i) => i.id == item.id);
    if (index == -1 || globalIndex == -1) return;

    final newStatus = isPublished ? 'PUBLISHED' : 'DRAFT';

    // Optimistic Update
    setState(() {
      final updatedItem = item.copyWith(publishStatus: newStatus);
      _filteredItems[index] = updatedItem;
      _items[globalIndex] = updatedItem;
    });

    final success = await _menuService.toggleMenuItemPublishStatus(
      item.id,
      newStatus,
    );

    if (!success && mounted) {
      // Revert on failure
      setState(() {
        final revertedItem = item.copyWith(publishStatus: item.publishStatus);
        _filteredItems[index] = revertedItem;
        _items[globalIndex] = revertedItem;
      });
      final t = AppLocalizations.of(context);
      AppDialog.showToast(
        context,
        t?.translate('failed_update_publish') ??
            'Failed to Update Publish Status',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? Theme.of(context).cardColor
          : Colors.white,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(gradient: AppColors.primaryGradient),
        ),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (_isSearching) {
              setState(() {
                _isSearching = false;
                _searchCtrl.clear();
              });
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _isSearching
              ? TextField(
                  key: const ValueKey('searchField'),
                  controller: _searchCtrl,
                  autofocus: true,
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 16),
                  decoration: InputDecoration(
                    hintText:
                        t?.translate('search_menu_items') ??
                        'Search menu items...',
                    hintStyle: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                  ),
                )
              : Text(
                  t?.translate('manage_shop_menu') ?? 'Manage Shop Menu',
                  key: const ValueKey('titleText'),
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
        ),
        centerTitle: false,
        actions: [
          if (!_isSearching) ...[
            IconButton(
              constraints: const BoxConstraints(),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              icon: Icon(Icons.search, color: Colors.white),
              onPressed: () => setState(() => _isSearching = true),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddNewItemScreen(),
                    ),
                  );
                  if (result == true) _fetchItems(isRefresh: true);
                },
                child: Text(
                  t?.translate('create') ?? '+ Create',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
          if (_isSearching)
            IconButton(
              icon: Icon(Icons.close, color: Colors.white),
              onPressed: () {
                setState(() {
                  _isSearching = false;
                  _searchCtrl.clear();
                });
              },
            ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Menu List
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _isLoading
                  ? _buildSkeletonList(key: const ValueKey('loading'))
                  : _filteredItems.isEmpty
                  ? _buildEmptyState(key: const ValueKey('empty'))
                  : RefreshIndicator(
                      key: const ValueKey('data'),
                      onRefresh: () => _fetchItems(isRefresh: true),
                      color: AppColors.primary,
                      child: ListView.builder(
                        controller: _scrollController,
                        // No extra horizontal padding — items are edge-to-edge.
                        padding: EdgeInsets.only(
                          bottom: MediaQuery.paddingOf(context).bottom + 20,
                        ),
                        itemCount: _listItems.length + (_isLoadingMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _listItems.length) {
                            return const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: AppColors.primary,
                                ),
                              ),
                            );
                          }

                          final item = _listItems[index];

                          // ── Category section header ────────────────────
                          if (item is MenuCategoryModel) {
                            final catIndex = _categories.indexOf(item);
                            final isDark =
                                Theme.of(context).brightness == Brightness.dark;
                            return Container(
                              key: _categoryKeys[catIndex],
                              padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
                              // Slightly tinted background to visually
                              // separate section headers from list rows.
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.04)
                                  : const Color(0xFFF8FAFC),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      item.displayName,
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.6,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                  // Item count badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      '${_filteredItems.where((i) => i.menuCategoryId == item.id).length}',
                                      style: GoogleFonts.poppins(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          // ── Menu item row ─────────────────────────────
                          if (item is MenuItemModel) {
                            return MenuItemCard(
                              item: item,
                              onTap: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        AddNewItemScreen(item: item),
                                  ),
                                );
                                if (result == true) {
                                  _fetchItems(isRefresh: true);
                                }
                              },
                              onAvailabilityChanged: (available) {
                                _toggleItemAvailability(item, available);
                              },
                              onPublishStatusChanged: (isPublished) {
                                _toggleItemPublishStatus(item, isPublished);
                              },
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({Key? key}) {
    final t = AppLocalizations.of(context);
    return Center(
      key: key,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.fastfood_outlined, size: 64, color: Color(0xFFCBD5E1)),
          SizedBox(height: 16),
          Text(
            t?.translate('no_items_found') ?? 'No menu items found',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
          SizedBox(height: 8),
          Text(
            _searchCtrl.text.isNotEmpty
                ? (t?.translate('try_different_search') ??
                      'Try a Different Search Query')
                : (t?.translate('start_adding_items') ??
                      'Start Adding Items to Your Shop Menu'),
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: (Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF94A3B8)
                  : const Color(0xFF64748B)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonList({Key? key}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListView.builder(
      key: key,
      itemCount: 10,
      padding: EdgeInsets.zero,
      itemBuilder: (context, index) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  // Left accent bar placeholder
                  const SizedBox(width: 3),
                  const SizedBox(width: 12),
                  // Thumbnail
                  const Skeleton(width: 56, height: 56),
                  const SizedBox(width: 12),
                  // Text lines
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Skeleton(width: 130, height: 13),
                        SizedBox(height: 6),
                        Skeleton(width: 90, height: 11),
                        SizedBox(height: 6),
                        Skeleton(width: 70, height: 12),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Switch column placeholders
                  Column(
                    children: const [
                      Skeleton(width: 44, height: 24),
                      SizedBox(height: 10),
                      Skeleton(width: 44, height: 24),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 3),
              child: Divider(
                height: 1,
                thickness: 0.6,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.07)
                    : const Color(0xFFE2E8F0),
              ),
            ),
          ],
        );
      },
    );
  }
}
