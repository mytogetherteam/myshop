import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:my_shop/core/presentation/widgets/custom_loading_indicator.dart';
import '../../data/models/menu_item_model.dart';
import '../../data/models/menu_category_model.dart';
import '../../data/services/menu_service.dart';

class AddNewItemScreen extends StatefulWidget {
  final MenuItemModel? item;

  const AddNewItemScreen({super.key, this.item});

  @override
  State<AddNewItemScreen> createState() => _AddNewItemScreenState();
}

class _AddNewItemScreenState extends State<AddNewItemScreen> {
  final MenuService _menuService = MenuService();
  final _formKey = GlobalKey<FormState>();
  
  String _selectedLang = 'EN';

  // Multi-language Controllers
  final TextEditingController _nameEnController = TextEditingController();
  final TextEditingController _nameMmController = TextEditingController();
  final TextEditingController _nameThController = TextEditingController();
  
  final TextEditingController _descEnController = TextEditingController();
  final TextEditingController _descMmController = TextEditingController();
  final TextEditingController _descThController = TextEditingController();
  
  // Numeric/Technical Controllers
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _originalPriceController = TextEditingController();
  final TextEditingController _discountAmountController = TextEditingController();
  final TextEditingController _discountPercentController = TextEditingController();
  final TextEditingController _stockController = TextEditingController();
  
  final List<MenuCategoryModel> _categories = [];
  final List<Map<String, dynamic>> _availableTags = [];
  final List<int> _selectedTagIds = [];
  bool _isLoadingCategories = true;
  bool _isLoadingTags = true;
  
  String _selectedCurrency = 'THB';
  final List<String> _currencies = ['THB', 'USD', 'MMK'];

  // Master Selections
  int? _selectedMasterCategoryId;
  String? _selectedMasterCategoryName;
  int? _selectedMasterItemId;
  String? _selectedMasterItemName;

  // --- Master Category mock data ---
  static const List<Map<String, dynamic>> _masterCategories = [
    {'id': 1192, 'nameEn': 'BBQ'},
    {'id': 31,   'nameEn': 'Noodle'},
    {'id': 32,   'nameEn': 'Meal'},
    {'id': 33,   'nameEn': 'Soup'},
    {'id': 34,   'nameEn': 'Salad'},
    {'id': 35,   'nameEn': 'Drink'},
    {'id': 36,   'nameEn': 'Rice'},
    {'id': 37,   'nameEn': 'Curry'},
    {'id': 38,   'nameEn': 'Snack'},
    {'id': 39,   'nameEn': 'Steamed'},
    {'id': 40,   'nameEn': 'Grill'},
    {'id': 629,  'nameEn': 'Biryani'},
    {'id': 30,   'nameEn': 'Fried'},
    {'id': 29,   'nameEn': 'Dessert'},
    {'id': 0,    'nameEn': 'Other'},
  ];

  // --- Master Item mock data ---
  static const List<Map<String, dynamic>> _masterItems = [
    {'id': 75,  'nameEn': 'Deep Fries White Onion Ring'},
    {'id': 76,  'nameEn': 'Homemade Caesar Salad With Bread Croutons'},
    {'id': 77,  'nameEn': 'Mixed Green Vegetable Salad With Cove C Homemade Lemon Dressing'},
    {'id': 78,  'nameEn': 'Greek Style Fruit Salad'},
    {'id': 79,  'nameEn': 'Panna Cotta'},
    {'id': 80,  'nameEn': 'Caramisu'},
    {'id': 81,  'nameEn': 'Coconut Caramel'},
    {'id': 82,  'nameEn': 'Candy Soda'},
    {'id': 83,  'nameEn': 'Cove C Berry Cloud Smoothie'},
    {'id': 84,  'nameEn': 'Hojicha Latte'},
    {'id': 85,  'nameEn': 'Chocolate'},
    {'id': 86,  'nameEn': 'Thai Tea'},
    {'id': 87,  'nameEn': 'Matcha Latte'},
    {'id': 88,  'nameEn': 'Clear Matcha'},
    {'id': 89,  'nameEn': 'Coconut Matcha'},
    {'id': 90,  'nameEn': 'Expresso'},
    {'id': 91,  'nameEn': 'Piccolo'},
    {'id': 92,  'nameEn': 'Flat White'},
    {'id': 93,  'nameEn': 'Americano'},
    {'id': 94,  'nameEn': 'Latte'},
  ];
  
  MenuCategoryModel? _selectedCategory;
  bool _isSaving = false;

  // Image state
  XFile? _pickedImage;

  // Boolean Flags
  bool _isAvailable = true;
  bool _isPopular = false;
  bool _isRecommended = false;
  bool _isVegetarian = false;
  bool _isSpicy = false;
  bool _isHotDeal = false;
  bool _isCombo = false;

  // Meal Types
  final List<String> _selectedMealTypes = [];
  final List<String> _allMealTypes = ['BREAKFAST', 'LUNCH', 'DINNER', 'Other'];

  // Complex Dynamic Lists
  final List<MenuItemVariantModel> _variants = [];
  final List<MenuItemOptionGroupModel> _optionGroups = [];

  @override
  void initState() {
    super.initState();
    _initializeData();
    _fetchCategories();
    _fetchTags();
  }

  void _initializeData() {
    if (widget.item != null) {
      final item = widget.item!;
      _nameEnController.text = item.nameEn ?? '';
      _nameMmController.text = item.nameMm ?? '';
      _nameThController.text = item.nameTh ?? '';
      
      _descEnController.text = item.descriptionEn ?? '';
      _descMmController.text = item.descriptionMm ?? '';
      _descThController.text = item.descriptionTh ?? '';
      
      _priceController.text = item.price.toString();
      _originalPriceController.text = item.originalPrice?.toString() ?? '';
      _discountAmountController.text = item.discountAmount?.toString() ?? '';
      _discountPercentController.text = item.discountPercentage?.toString() ?? '';
      _stockController.text = item.stockQuantity?.toString() ?? '100';
      _selectedMasterItemId = item.masterItemId;
      _selectedMasterCategoryId = item.masterCategoryId;
      // Resolve display names from mock data
      if (_selectedMasterCategoryId != null) {
        _selectedMasterCategoryName = _masterCategories
            .firstWhere((c) => c['id'] == _selectedMasterCategoryId, orElse: () => {'nameEn': 'Category #$_selectedMasterCategoryId'})['nameEn'] as String?;
      }
      if (_selectedMasterItemId != null) {
        _selectedMasterItemName = _masterItems
            .firstWhere((m) => m['id'] == _selectedMasterItemId, orElse: () => {'nameEn': 'Item #$_selectedMasterItemId'})['nameEn'] as String?;
      }
      _selectedTagIds.addAll(item.tagIds);
      
      _selectedCurrency = item.currency ?? 'THB';
      _isAvailable = item.isAvailable;
      _isPopular = item.isPopular;
      _isRecommended = item.isRecommended;
      _isVegetarian = item.isVegetarian;
      _isSpicy = item.isSpicy;
      _isHotDeal = item.isHotDeal;
      _isCombo = item.isCombo;
      
      _selectedMealTypes.addAll(item.mealTypes);
      _variants.addAll(item.variants);
      _optionGroups.addAll(item.optionGroups);
    }
  }

  Future<void> _fetchCategories() async {
    setState(() => _isLoadingCategories = true);
    final categories = await _menuService.getCategories();
    if (mounted) {
      setState(() {
        _categories.addAll(categories ?? []);
        _isLoadingCategories = false;
        
        // Append "Other"
        if (_categories.isNotEmpty) {
          _categories.add(MenuCategoryModel(
            id: 9999, 
            nameEn: 'Other', 
            nameMm: 'Other', 
            nameTh: 'Other', 
            updatedAt: DateTime.now()
          ));
        }

        if (widget.item != null && _categories.isNotEmpty) {
          try {
            _selectedCategory = _categories.firstWhere((c) => c.id == widget.item?.categoryId);
          } catch (_) {
            _selectedCategory = _categories.isNotEmpty ? _categories.first : null;
          }
        } else if (_categories.isNotEmpty) {
          _selectedCategory = _categories.first;
        }
      });
    }
  }

  Future<void> _fetchTags() async {
    setState(() => _isLoadingTags = true);
    // Mock fetch
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      setState(() {
        _availableTags.addAll([
          {'id': 1, 'name': 'New Arrival'},
          {'id': 2, 'name': 'Best Seller'},
          {'id': 3, 'name': 'Gluten Free'},
          {'id': 0, 'name': 'Other'},
        ]);
        _isLoadingTags = false;
      });
    }
  }

  @override
  void dispose() {
    _nameEnController.dispose();
    _nameMmController.dispose();
    _nameThController.dispose();
    _descEnController.dispose();
    _descMmController.dispose();
    _descThController.dispose();
    _priceController.dispose();
    _originalPriceController.dispose();
    _discountAmountController.dispose();
    _discountPercentController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    if (_nameEnController.text.isEmpty && _nameMmController.text.isEmpty && _nameThController.text.isEmpty) {
      _showToast('Please enter at least one name', isError: true);
      return;
    }

    setState(() => _isSaving = true);
    String? imageUrl = widget.item?.imageUrl;
    if (_pickedImage != null) {
      imageUrl = _pickedImage!.path;
    }

    final payload = {
      'nameEn': _nameEnController.text,
      'nameMm': _nameMmController.text,
      'nameTh': _nameThController.text,
      'descriptionEn': _descEnController.text,
      'descriptionMm': _descMmController.text,
      'descriptionTh': _descThController.text,
      'price': double.tryParse(_priceController.text) ?? 0.0,
      'originalPrice': double.tryParse(_originalPriceController.text) ?? 0.0,
      'discountAmount': double.tryParse(_discountAmountController.text) ?? 0.0,
      'discountPercentage': double.tryParse(_discountPercentController.text) ?? 0.0,
      'categoryId': _selectedCategory?.id,
      'stockQuantity': int.tryParse(_stockController.text) ?? 0,
      'tagIds': _selectedTagIds,
      'masterItemId': _selectedMasterItemId,
      'masterCategoryId': _selectedMasterCategoryId,
      'currency': _selectedCurrency,
      'isPopular': _isPopular,
      'isRecommended': _isRecommended,
      'isVegetarian': _isVegetarian,
      'isSpicy': _isSpicy,
      'isHotDeal': _isHotDeal,
      'isCombo': _isCombo,
      'imageUrl': imageUrl,
      'mealTypes': _selectedMealTypes,
      'variants': _variants.map((v) => v.toJson()).toList(),
      'optionGroups': _optionGroups.map((o) => o.toJson()).toList(),
    };

    bool success;
    if (widget.item != null) {
      success = await _menuService.updateMenuItem(widget.item!.id, payload);
    } else {
      success = await _menuService.createMenuItem(payload);
    }

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        _showToast(widget.item != null ? 'Item updated successfully' : 'Item created successfully');
        Navigator.pop(context, true);
      } else {
        _showToast('Failed to save item', isError: true);
      }
    }
  }

  Future<void> _deleteItem() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete Item', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: Text('Are you sure you want to delete this item? This action cannot be undone.', style: GoogleFonts.poppins()),
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
      setState(() => _isSaving = true);
      final success = await _menuService.deleteMenuItem(widget.item!.id);
      if (mounted) {
        setState(() => _isSaving = false);
        if (success) {
          _showToast('Item deleted successfully');
          Navigator.pop(context, true);
        } else {
          _showToast('Failed to delete item', isError: true);
        }
      }
    }
  }

  void _showToast(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white)),
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
          widget.item != null ? 'Edit Item' : 'Add New Item',
          style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B)),
        ),
        centerTitle: false,
      ),
      body: _isLoadingCategories 
        ? const Center(child: CustomLoadingIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildImageUploadSection(),
                  const SizedBox(height: 32),
                  
                  _buildSectionTitle('ITEM INFORMATION'),
                  const SizedBox(height: 16),
                  _buildLangSwitcher(),
                  const SizedBox(height: 16),
                  _buildMainNameField(),
                  const SizedBox(height: 16),
                  _buildMainDescriptionField(),
                  const SizedBox(height: 16),
                  _buildSearchableField(
                    label: 'Master Category',
                    value: _selectedMasterCategoryName,
                    placeholder: 'Search master categories...',
                    onTap: () => _showSearchableSelect<Map<String, dynamic>>(
                      title: 'Master Category',
                      items: _masterCategories,
                      labelMapper: (c) => c['nameEn'] as String,
                      onSelected: (c) => setState(() {
                        _selectedMasterCategoryId = c['id'] as int;
                        _selectedMasterCategoryName = c['nameEn'] as String;
                      }),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSearchableField(
                    label: 'Category',
                    value: _selectedCategory?.displayName,
                    placeholder: 'Select category',
                    onTap: () => _showSearchableSelect<MenuCategoryModel>(
                      title: 'Select Category',
                      items: _categories,
                      labelMapper: (c) => c.displayName,
                      onSelected: (c) => setState(() => _selectedCategory = c),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildTagSelection(),
                  
                  const SizedBox(height: 32),
                  _buildSectionTitle('PRICING & STOCK'),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _buildTextField('Price', _priceController, hint: '0.00', keyboardType: TextInputType.number)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildCurrencyDropdown()),
                    ],
                  ),
                   const SizedBox(height: 16),
                   Row(
                     children: [
                       Expanded(child: _buildTextField('Original Price', _originalPriceController, hint: '0.00', keyboardType: TextInputType.number)),
                       const SizedBox(width: 16),
                       Expanded(child: _buildTextField('Stock Quantity', _stockController, hint: '100', keyboardType: TextInputType.number)),
                     ],
                   ),
                   const SizedBox(height: 16),
                   Row(
                     children: [
                       Expanded(child: _buildTextField('Discount Amount', _discountAmountController, hint: '0.00', keyboardType: TextInputType.number)),
                       const SizedBox(width: 16),
                       Expanded(child: _buildTextField('Discount %', _discountPercentController, hint: '0', keyboardType: TextInputType.number)),
                     ],
                   ),




                  const SizedBox(height: 32),

                  const SizedBox(height: 32),
                  _buildSectionTitle('PROPERTIES'),
                  const SizedBox(height: 16),
                  _buildPropertyToggles(),

                  const SizedBox(height: 32),
                  _buildSectionTitle('VARIANTS'),
                  const SizedBox(height: 8),
                  _buildVariantsSection(),
                  
                  const SizedBox(height: 32),
                  _buildSectionTitle('ADD-ONS'),
                  const SizedBox(height: 8),
                  _buildOptionGroupsSection(),
                  
                  if (widget.item != null) ...[
                    const SizedBox(height: 24),
                    TextButton.icon(
                      onPressed: _isSaving ? null : _deleteItem,
                      icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444)),
                      label: Text(
                        'Delete item',
                        style: GoogleFonts.poppins(
                          color: const Color(0xFFEF4444),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
      bottomNavigationBar: !_isLoadingCategories
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: _buildSaveButton(),
              ),
            )
          : null,
    );
  }

  // --- UI Components ---

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF94A3B8), letterSpacing: 1.0),
    );
  }

  InputDecoration _buildInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.poppins(color: const Color(0xFF94A3B8), fontSize: 13),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFED3A72), width: 1.5)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFEF4444))),
      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5)),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {String? hint, bool isMultiline = false, TextInputType? keyboardType, Function(String)? onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B))),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: isMultiline ? 3 : 1,
          keyboardType: keyboardType,
          onChanged: onChanged,
          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500),
          decoration: _buildInputDecoration(hint ?? ''),
        ),
      ],
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
              child: Text(lang, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: isSelected ? Colors.white : const Color(0xFF64748B))),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMealTypeChips() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Meal Types', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B))),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: _allMealTypes.map((type) {
            final isSelected = _selectedMealTypes.contains(type);
            return FilterChip(
              label: Text(type, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: isSelected ? Colors.white : const Color(0xFF64748B))),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) _selectedMealTypes.add(type);
                  else _selectedMealTypes.remove(type);
                });
              },
              selectedColor: const Color(0xFFED3A72),
              checkmarkColor: Colors.white,
              backgroundColor: const Color(0xFFF8FAFC),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: isSelected ? const Color(0xFFED3A72) : const Color(0xFFE2E8F0))),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCurrencyDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Currency', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B))),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedCurrency,
          isExpanded: true,
          decoration: _buildInputDecoration(''),
          items: _currencies.map((c) => DropdownMenuItem(value: c, child: Text(c, style: GoogleFonts.poppins(fontSize: 14)))).toList(),
          onChanged: (v) => setState(() => _selectedCurrency = v!),
        ),
      ],
    );
  }

  Widget _buildSearchableField({required String label, String? value, required String placeholder, required VoidCallback onTap}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B))),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value ?? placeholder,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: value != null ? FontWeight.w500 : FontWeight.w400,
                      color: value != null ? const Color(0xFF1E293B) : const Color(0xFF94A3B8),
                    ),
                  ),
                ),
                if (value != null)
                  GestureDetector(
                    onTap: () {
                      if (label == 'Category') setState(() => _selectedCategory = null);
                      else if (label == 'Master Category') setState(() => _selectedMasterCategoryId = null);
                      else if (label == 'Master Item') setState(() => _selectedMasterItemId = null);
                    },
                    child: const Icon(Icons.close, size: 16, color: Color(0xFF94A3B8)),
                  )
                else
                  const Icon(Icons.keyboard_arrow_down, size: 20, color: Color(0xFF94A3B8)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showSearchableSelect<T>({
    required String title,
    required List<T> items,
    required String Function(T) labelMapper,
    required Function(T) onSelected,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _SearchSelectorSheet<T>(
        title: title,
        items: items,
        labelMapper: labelMapper,
        onSelected: onSelected,
      ),
    );
  }

  Widget _buildTagSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('CATEGORIZATION'),
        const SizedBox(height: 16),
        _buildMealTypeChips(),
        const SizedBox(height: 24),
        Text('Discovery Tags', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B))),
        const SizedBox(height: 8),
        _isLoadingTags 
          ? const Center(child: Padding(padding: EdgeInsets.all(8.0), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))))
          : Wrap(
            spacing: 8,
            runSpacing: 4,
            children: _availableTags.map((tag) {
              final id = tag['id'] as int;
              final isSelected = _selectedTagIds.contains(id);
              return FilterChip(
                label: Text(tag['nameEn'] ?? tag['name'], style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: isSelected ? Colors.white : const Color(0xFF64748B))),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) _selectedTagIds.add(id);
                    else _selectedTagIds.remove(id);
                  });
                },
                selectedColor: const Color(0xFFED3A72),
                checkmarkColor: Colors.white,
                backgroundColor: const Color(0xFFF8FAFC),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: isSelected ? const Color(0xFFED3A72) : const Color(0xFFE2E8F0))),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildPropertyToggles() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(
        children: [
          _buildToggleRow('Available', _isAvailable, (v) => setState(() => _isAvailable = v)),
          const Divider(),
          _buildToggleRow('Popular', _isPopular, (v) => setState(() => _isPopular = v)),
          const Divider(),
          _buildToggleRow('Recommended', _isRecommended, (v) => setState(() => _isRecommended = v)),
          const Divider(),
          _buildToggleRow('Combo Set', _isCombo, (v) => setState(() => _isCombo = v)),
          const Divider(),
          _buildToggleRow('Vegetarian', _isVegetarian, (v) => setState(() => _isVegetarian = v)),
          const Divider(),
          _buildToggleRow('Spicy', _isSpicy, (v) => setState(() => _isSpicy = v)),
          const Divider(),
          _buildToggleRow('Hot Deal', _isHotDeal, (v) => setState(() => _isHotDeal = v)),
        ],
      ),
    );
  }

  Widget _buildToggleRow(String label, bool value, Function(bool) onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFF1E293B))),
        Switch(value: value, onChanged: onChanged, activeColor: const Color(0xFFED3A72)),
      ],
    );
  }

  Widget _buildVariantsSection() {
    return Column(
      children: [
        ..._variants.asMap().entries.map((entry) {
          final index = entry.key;
          final v = entry.value;
          return _buildDynamicItemCard(
            title: 'Variant #${index + 1}',
            onDelete: () => setState(() => _variants.removeAt(index)),
            child: Column(
              children: [
                _buildTextField('Variant Name (EN)', TextEditingController(text: v.nameEn), onChanged: (val) {
                  final map = v.toJson();
                  map['nameEn'] = val;
                  _variants[index] = MenuItemVariantModel.fromJson(map);
                }),
                const SizedBox(height: 8),
                _buildTextField('Variant Name (MM)', TextEditingController(text: v.nameMm), onChanged: (val) {
                  final map = v.toJson();
                  map['nameMm'] = val;
                  _variants[index] = MenuItemVariantModel.fromJson(map);
                }),
                const SizedBox(height: 8),
                _buildTextField('Variant Name (TH)', TextEditingController(text: v.nameTh), onChanged: (val) {
                  final map = v.toJson();
                  map['nameTh'] = val;
                  _variants[index] = MenuItemVariantModel.fromJson(map);
                }),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildTextField('Price', TextEditingController(text: v.price.toString()), keyboardType: TextInputType.number, 
                      onChanged: (val) {
                        final map = v.toJson();
                        map['price'] = double.tryParse(val) ?? 0.0;
                        _variants[index] = MenuItemVariantModel.fromJson(map);
                      })),
                  ],
                ),
              ],
            ),
          );
        }),
        _buildAddButton('Add Variant', () {
          setState(() {
            _variants.add(MenuItemVariantModel(id: DateTime.now().millisecondsSinceEpoch, price: 0.0, displayOrder: 1));
          });
        }),
      ],
    );
  }

  Widget _buildOptionGroupsSection() {
    return Column(
      children: [
        ..._optionGroups.asMap().entries.map((entry) {
          final gIndex = entry.key;
          final g = entry.value;
          return _buildDynamicItemCard(
            title: 'Add-on: ${g.displayName.isEmpty ? "New Add-on" : g.displayName}',
            onDelete: () => setState(() => _optionGroups.removeAt(gIndex)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTextField('Add-on Name (EN)', TextEditingController(text: g.nameEn), onChanged: (val) {
                  final map = g.toJson();
                  map['nameEn'] = val;
                  _optionGroups[gIndex] = MenuItemOptionGroupModel.fromJson(map);
                }),
                const SizedBox(height: 8),
                _buildTextField('Add-on Name (MM)', TextEditingController(text: g.nameMm), onChanged: (val) {
                  final map = g.toJson();
                  map['nameMm'] = val;
                  _optionGroups[gIndex] = MenuItemOptionGroupModel.fromJson(map);
                }),
                const SizedBox(height: 8),
                _buildTextField('Add-on Name (TH)', TextEditingController(text: g.nameTh), onChanged: (val) {
                  final map = g.toJson();
                  map['nameTh'] = val;
                  _optionGroups[gIndex] = MenuItemOptionGroupModel.fromJson(map);
                }),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildTextField('Price', TextEditingController(text: g.price.toString()), keyboardType: TextInputType.number, 
                      onChanged: (val) => _updateGroup(gIndex, {'price': double.tryParse(val) ?? 0.0}))),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(),
                ...g.options.asMap().entries.map((oEntry) => _buildOptionItem(gIndex, oEntry.key, oEntry.value)),
                _buildAddButton('Add Item', () {
                  final map = g.toJson();
                  final options = List<Map<String, dynamic>>.from(map['options'] ?? []);
                  options.add(MenuItemOptionModel(id: DateTime.now().millisecondsSinceEpoch, price: 0.0, displayOrder: 1).toJson());
                  map['options'] = options;
                  setState(() => _optionGroups[gIndex] = MenuItemOptionGroupModel.fromJson(map));
                }, small: true),
              ],
            ),
          );
        }),
        _buildAddButton('Add Add-on', () {
          setState(() => _optionGroups.add(MenuItemOptionGroupModel(id: DateTime.now().millisecondsSinceEpoch, options: [], displayOrder: 1)));
        }),
      ],
    );
  }

  Widget _buildOptionItem(int gIndex, int oIndex, MenuItemOptionModel o) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  children: [
                    _buildBareTextField(o.nameEn, (val) => _updateOption(gIndex, oIndex, {'nameEn': val}), 'Item name (EN)'),
                    _buildBareTextField(o.nameMm, (val) => _updateOption(gIndex, oIndex, {'nameMm': val}), 'Item name (MM)'),
                    _buildBareTextField(o.nameTh, (val) => _updateOption(gIndex, oIndex, {'nameTh': val}), 'Item name (TH)'),
                  ],
                ),
              ),
              IconButton(icon: const Icon(Icons.close, size: 18, color: Color(0xFFEF4444)), onPressed: () => _removeOption(gIndex, oIndex)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _buildBareTextField(o.price.toString(), (val) => _updateOption(gIndex, oIndex, {'price': double.tryParse(val)}), 'Price', keyboard: TextInputType.number)),
            ],
          ),
        ],
      ),
    );
  }

  void _updateGroup(int index, Map<String, dynamic> updates) {
    final map = _optionGroups[index].toJson();
    map.addAll(updates);
    setState(() => _optionGroups[index] = MenuItemOptionGroupModel.fromJson(map));
  }

  void _updateOption(int gIndex, int oIndex, Map<String, dynamic> updates) {
    final map = _optionGroups[gIndex].toJson();
    final options = List<Map<String, dynamic>>.from(map['options']);
    options[oIndex].addAll(updates);
    setState(() => _optionGroups[gIndex] = MenuItemOptionGroupModel.fromJson(map));
  }

  void _removeOption(int gIndex, int oIndex) {
    final map = _optionGroups[gIndex].toJson();
    final options = List<Map<String, dynamic>>.from(map['options']);
    options.removeAt(oIndex);
    map['options'] = options;
    setState(() => _optionGroups[gIndex] = MenuItemOptionGroupModel.fromJson(map));
  }

  Widget _buildBareTextField(String? initial, Function(String) onChanged, String hint, {TextInputType keyboard = TextInputType.text}) {
    return TextFormField(initialValue: initial, onChanged: onChanged, keyboardType: keyboard, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500), decoration: InputDecoration(hintText: hint, isDense: true, border: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade200))));
  }

  Widget _buildDynamicItemCard({required String title, required Widget child, required VoidCallback onDelete}) {
    return Container(margin: const EdgeInsets.only(bottom: 16), padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE2E8F0))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(title, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)), IconButton(icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444), size: 20), onPressed: onDelete)]), const SizedBox(height: 8), child]));
  }

  Widget _buildAddButton(String label, VoidCallback onTap, {bool small = false}) {
    return InkWell(onTap: onTap, child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), decoration: BoxDecoration(color: const Color(0xFFED3A72).withOpacity(0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFED3A72).withOpacity(0.2))), child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.add, size: 16, color: Color(0xFFED3A72)), const SizedBox(width: 8), Text(label, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFFED3A72)))])));
  }

  Widget _buildImageUploadSection() {
    ImageProvider? imageProvider;
    if (_pickedImage != null) {
      imageProvider = FileImage(File(_pickedImage!.path));
    } else if (widget.item?.imageUrl != null && widget.item!.imageUrl!.isNotEmpty) {
      final url = widget.item!.imageUrl!;
      if (url.startsWith('http')) {
        imageProvider = CachedNetworkImageProvider(url);
      } else {
        imageProvider = FileImage(File(url));
      }
    }

    return GestureDetector(
      onTap: () async {
        final image = await ImagePicker().pickImage(source: ImageSource.gallery);
        if (image != null) setState(() => _pickedImage = image);
      },
      child: Container(
        width: double.infinity,
        height: 200,
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
          image: imageProvider != null ? DecorationImage(image: imageProvider, fit: BoxFit.cover) : null,
        ),
        child: imageProvider == null
            ? const Center(child: Icon(Icons.camera_alt_outlined, color: Color(0xFFED3A72), size: 32))
            : null,
      ),
    );
  }

  Widget _buildMainNameField() {
    TextEditingController controller = _selectedLang == 'EN' ? _nameEnController : (_selectedLang == 'MM' ? _nameMmController : _nameThController);
    return _buildTextField('Item Name ($_selectedLang)', controller, hint: 'Enter name');
  }

  Widget _buildMainDescriptionField() {
    TextEditingController controller = _selectedLang == 'EN' ? _descEnController : (_selectedLang == 'MM' ? _descMmController : _descThController);
    return _buildTextField('Description ($_selectedLang)', controller, hint: 'Enter description', isMultiline: true);
  }

  Widget _buildSaveButton() {
    return SizedBox(width: double.infinity, height: 56, child: ElevatedButton(onPressed: _isSaving ? null : _handleSave, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFED3A72), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0), child: _isSaving ? const CustomLoadingIndicator(size: 24, color: Colors.white) : Text(widget.item != null ? 'Update Item' : 'Create Item', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white))));
  }
}

class _SearchSelectorSheet<T> extends StatefulWidget {
  final String title;
  final List<T> items;
  final String Function(T) labelMapper;
  final Function(T) onSelected;

  const _SearchSelectorSheet({
    required this.title,
    required this.items,
    required this.labelMapper,
    required this.onSelected,
  });

  @override
  State<_SearchSelectorSheet<T>> createState() => _SearchSelectorSheetState<T>();
}

class _SearchSelectorSheetState<T> extends State<_SearchSelectorSheet<T>> {
  final TextEditingController _searchCtrl = TextEditingController();
  List<T> _filteredItems = [];

  @override
  void initState() {
    super.initState();
    _filteredItems = List.from(widget.items);
  }

  void _onSearch(String val) {
    setState(() {
      _filteredItems = widget.items.where((item) => widget.labelMapper(item).toLowerCase().contains(val.toLowerCase())).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40, height: 4, 
            decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(widget.title, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B))),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _onSearch,
              decoration: InputDecoration(
                hintText: 'Search...',
                prefixIcon: const Icon(Icons.search, size: 20, color: Color(0xFF94A3B8)),
                hintStyle: GoogleFonts.poppins(color: const Color(0xFF94A3B8)),
                filled: true, 
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              itemCount: _filteredItems.length,
              separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
              itemBuilder: (context, index) {
                final item = _filteredItems[index];
                final label = widget.labelMapper(item);
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(label, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFF1E293B))),
                  trailing: const Icon(Icons.chevron_right, size: 16, color: Color(0xFF94A3B8)),
                  onTap: () {
                    widget.onSelected(item);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
