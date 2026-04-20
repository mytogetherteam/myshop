import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_shop/core/presentation/widgets/skeleton.dart';
import '../widgets/menu_item_card.dart';
import '../../data/services/menu_service.dart';
import '../../data/models/menu_item_model.dart';
import 'add_new_item_screen.dart';

class ManageShopMenuPage extends StatefulWidget {
  const ManageShopMenuPage({super.key});

  @override
  State<ManageShopMenuPage> createState() => _ManageShopMenuPageState();
}

class _ManageShopMenuPageState extends State<ManageShopMenuPage> {
  final MenuService _menuService = MenuService();
  List<MenuItemModel> _items = [];
  List<MenuItemModel> _filteredItems = [];
  bool _isLoading = true;
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchItems();
    _searchCtrl.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchItems() async {
    setState(() => _isLoading = true);
    try {
      // Fetch all items (categoryId: null)
      final items = await _menuService.getMenuItems(
        categoryId: null,
        limit: 100,
      );
      if (mounted) {
        setState(() {
          _items = items ?? [];
          _filteredItems = items ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('[ManageShopMenuPage] Error fetching items: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onSearchChanged() {
    final query = _searchCtrl.text.toLowerCase();
    setState(() {
      _filteredItems = _items.where((item) {
        return item.displayName.toLowerCase().contains(query) ||
            (item.descriptionEn?.toLowerCase().contains(query) ?? false);
      }).toList();
    });
  }

  Future<void> _toggleItemAvailability(
    MenuItemModel item,
    bool available,
  ) async {
    final success = await _menuService.toggleAvailability(
      item.id,
      available,
    );
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update availability'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      _fetchItems(); // Refresh to revert UI
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
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
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
                    size: 20,
                  ),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () => _searchCtrl.clear(),
                        )
                      : null,
                ),
              ),
            ),
          ),

          // Total count
          if (!_isLoading)
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 20, bottom: 10),
              child: Row(
                children: [
                  Text(
                    'Total Items: ${_filteredItems.length}',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),

          // Menu List
          Expanded(
            child: _isLoading
                ? _buildSkeletonList()
                : _filteredItems.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    onRefresh: _fetchItems,
                    color: const Color(0xFFED3A72),
                    child: ListView.builder(
                      padding: const EdgeInsets.only(bottom: 100),
                      itemCount: _filteredItems.length,
                      itemBuilder: (context, index) {
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
                            if (result == true) _fetchItems();
                          },
                          onAvailabilityChanged: (available) {
                            _toggleItemAvailability(item, available);
                          },
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddNewItemScreen(),
            ),
          );
          if (result == true) _fetchItems();
        },
        backgroundColor: const Color(0xFFED3A72),
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.fastfood_outlined,
            size: 64,
            color: const Color(0xFFCBD5E1),
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

  Widget _buildSkeletonList() {
    return ListView.builder(
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
