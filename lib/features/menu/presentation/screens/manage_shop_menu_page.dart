import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_shop/core/presentation/widgets/skeleton.dart';
import '../widgets/menu_item_card.dart';
import '../../data/services/menu_service.dart';
import '../../data/models/menu_item_model.dart';
import 'add_new_item_screen.dart';
import 'dart:async';

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
      await Future.wait([
        _menuService.getCategories(forceRefresh: false),
        _menuService.getMasterCategories(forceRefresh: false),
        _menuService.getMasterMenuItems(),
        _menuService.getMenuTags(),
      ]);
      debugPrint('[ManageShopMenuPage] Master data pre-fetched successfully');
    } catch (e) {
      debugPrint('[ManageShopMenuPage] Error pre-fetching master data: $e');
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
            
            // Debug logging
            for (var item in fetchedItems) {
              debugPrint('DEBUG: ManageShop: Item: ${item.nameEn}, Status: ${item.pendingStatus}');
            }

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
      debugPrint('[ManageShopMenuPage] Error fetching items: $e');
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update availability'),
          backgroundColor: Color(0xFFEF4444),
        ),
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

    final success =
        await _menuService.toggleMenuItemPublishStatus(item.id, newStatus);

    if (!success && mounted) {
      // Revert on failure
      setState(() {
        final revertedItem = item.copyWith(publishStatus: item.publishStatus);
        _filteredItems[index] = revertedItem;
        _items[globalIndex] = revertedItem;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update publish status'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Manage Shop Menu',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1E293B),
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
              ),
              child: TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'Search menu items...',
                  hintStyle: GoogleFonts.poppins(
                    fontSize: 14,
                    color: const Color(0xFF94A3B8),
                  ),
                  border: InputBorder.none,
                  icon: const Icon(
                    Icons.search,
                    color: Color(0xFF64748B),
                    size: 22,
                  ),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchCtrl.clear();
                            // clearing instantly triggers listener which debounces
                          },
                        )
                      : null,
                ),
              ),
            ),
          ),

          // Total count
          if (!_isLoading)
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 20, bottom: 16),
              child: Text(
                'Total Items: ${_filteredItems.length}',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF64748B),
                ),
              ),
            ),

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
                      color: const Color(0xFFED3973),
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.only(bottom: 100),
                        itemCount:
                            _filteredItems.length + (_isLoadingMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _filteredItems.length) {
                            return const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xFFED3973),
                                ),
                              ),
                            );
                          }
                          final item = _filteredItems[index];
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
                              if (result == true) _fetchItems(isRefresh: true);
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
                    ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddNewItemScreen()),
          );
          if (result == true) _fetchItems(isRefresh: true);
        },
        backgroundColor: const Color(0xFFED3973),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildEmptyState({Key? key}) {
    return Center(
      key: key,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.fastfood_outlined,
            size: 64,
            color: Color(0xFFCBD5E1),
          ),
          const SizedBox(height: 16),
          Text(
            'No menu items found',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchCtrl.text.isNotEmpty
                ? 'Try a different search query'
                : 'Start adding items to your shop menu',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonList({Key? key}) {
    return ListView.builder(
      key: key,
      itemCount: 8,
      padding: const EdgeInsets.symmetric(vertical: 0),
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              const Skeleton(width: 72, height: 72),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Skeleton(width: 140, height: 16),
                    SizedBox(height: 8),
                    Skeleton(width: double.infinity, height: 12),
                    SizedBox(height: 4),
                    Skeleton(width: 100, height: 12),
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
