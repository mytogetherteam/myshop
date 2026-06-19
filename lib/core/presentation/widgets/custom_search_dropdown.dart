import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomSearchDropdown<T> extends StatefulWidget {
  final List<T> items;
  final T? value;
  final String hintText;
  final String searchHintText;
  final String Function(T) itemLabelBuilder;
  final void Function(T?) onChanged;
  final bool isExpanded;

  const CustomSearchDropdown({
    super.key,
    required this.items,
    this.value,
    this.hintText = 'Select Option',
    this.searchHintText = 'Search...',
    required this.itemLabelBuilder,
    required this.onChanged,
    this.isExpanded = true,
  });

  @override
  State<CustomSearchDropdown<T>> createState() => _CustomSearchDropdownState<T>();
}

class _CustomSearchDropdownState<T> extends State<CustomSearchDropdown<T>> {
  void _showBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return _SearchBottomSheet<T>(
          items: widget.items,
          initialValue: widget.value,
          searchHintText: widget.searchHintText,
          itemLabelBuilder: widget.itemLabelBuilder,
          onSelected: (value) {
            widget.onChanged(value);
            Navigator.pop(context);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _showBottomSheet,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE2E8F0)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: widget.isExpanded ? MainAxisSize.max : MainAxisSize.min,
          children: [
            Expanded(
              child: Text(
                widget.value != null
                    ? widget.itemLabelBuilder(widget.value as T)
                    : widget.hintText,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: widget.value != null
                      ? const Color(0xFF1E293B)
                      : const Color(0xFF94A3B8),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down,
              color: Color(0xFF1E293B),
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchBottomSheet<T> extends StatefulWidget {
  final List<T> items;
  final T? initialValue;
  final String searchHintText;
  final String Function(T) itemLabelBuilder;
  final void Function(T) onSelected;

  const _SearchBottomSheet({
    required this.items,
    this.initialValue,
    required this.searchHintText,
    required this.itemLabelBuilder,
    required this.onSelected,
  });

  @override
  State<_SearchBottomSheet<T>> createState() => _SearchBottomSheetState<T>();
}

class _SearchBottomSheetState<T> extends State<_SearchBottomSheet<T>> {
  late List<T> _filteredItems;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filteredItems = widget.items;
    _searchController.addListener(_filterItems);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterItems() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredItems = widget.items.where((item) {
        return widget.itemLabelBuilder(item).toLowerCase().contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          // Drag Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
              ),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: widget.searchHintText,
                  hintStyle: GoogleFonts.poppins(
                    color: const Color(0xFF94A3B8),
                    fontSize: 14,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Color(0xFF94A3B8),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // List
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: _filteredItems.length,
              separatorBuilder: (context, index) => const Divider(
                height: 1,
                color: Color(0xFFF1F5F9),
                indent: 20,
                endIndent: 20,
              ),
              itemBuilder: (context, index) {
                final item = _filteredItems[index];
                final label = widget.itemLabelBuilder(item);
                final isSelected = item == widget.initialValue;

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 4,
                  ),
                  title: Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      color: isSelected
                          ? const Color(0xFFED3973)
                          : const Color(0xFF1E293B),
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                  onTap: () => widget.onSelected(item),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
