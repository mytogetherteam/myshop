import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:my_shop/core/presentation/widgets/custom_loading_indicator.dart';
import 'package:my_shop/core/data/services/image_upload_service.dart';
import 'package:my_shop/core/presentation/widgets/custom_search_dropdown.dart';
import '../../data/models/menu_item_model.dart';
import '../../data/models/menu_category_model.dart';
import '../../data/services/menu_service.dart';
import 'package:my_shop/core/presentation/widgets/skeleton.dart';
import 'package:my_shop/core/data/models/master_data_model.dart';
import 'package:my_shop/core/presentation/widgets/global_modal.dart';
// import 'package:my_shop/core/presentation/widgets/success_sheet.dart';
import 'package:my_shop/core/presentation/widgets/confirmation_sheet.dart';

class AddNewItemScreen extends StatefulWidget {
  final MenuItemModel? item;

  const AddNewItemScreen({super.key, this.item});

  @override
  State<AddNewItemScreen> createState() => _AddNewItemScreenState();
}

class _AddNewItemScreenState extends State<AddNewItemScreen> {
  final MenuService _menuService = MenuService();
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

  // GlobalKeys for scroll-to-error
  final _nameKey = GlobalKey();
  final _masterCategoryKey = GlobalKey();
  final _categoryKey = GlobalKey();
  final _mealTypesKey = GlobalKey();
  final _tagsKey = GlobalKey();
  final _priceKey = GlobalKey();

  // Controllers
  late final TextEditingController _nameController;
  late final TextEditingController _nameMmController;
  late final TextEditingController _nameThController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _descriptionMmController;
  late final TextEditingController _descriptionThController;

  late final TextEditingController _priceController;
  late final TextEditingController _originalPriceController;
  late final TextEditingController _stockQuantityController;
  late final TextEditingController _displayOrderController;
  late final TextEditingController _discountAmountController;
  late final TextEditingController _discountPercentController;

  String _currency = '฿';

  List<MenuCategoryModel> _categories = [];
  MenuCategoryModel? _selectedCategory;

  // Master Data
  List<MasterDataModel> _masterItems = [];
  MasterDataModel? _selectedMasterItem;
  List<MasterDataModel> _masterCategories = [];
  MasterDataModel? _selectedMasterCategory;
  List<MasterDataModel> _menuTags = [];
  List<int> _selectedTagIds = [];

  // Meal Types
  final List<String> _mealTypeOptions = ['BREAKFAST', 'LUNCH', 'DINNER'];
  List<String> _selectedMealTypes = [];

  // Boolean Properties mapped to Tags
  bool _isPopular = false;
  bool _isRecommended = false;
  bool _isSpicy = false;
  bool _isVegetarian = false;
  bool _isHotDeal = false;
  bool _isCombo = false;
  bool _isAvailable = true;

  bool _isLoadingData = true;
  bool _isSaving = false;
  String? _priceWarning;

  // Image state
  XFile? _pickedImage;

  // Real state for dynamic variants and add-ons
  List<MenuItemVariantModel> _variants = [];
  List<MenuItemOptionGroupModel> _optionGroups = [];

  // UI States
  String _selectedItemInfoLang = 'EN';
  final Map<int, String> _variantLangs = {};
  final Map<int, String> _addonLangs = {};

  // Persistent controllers for dynamic forms
  final Map<int, TextEditingController> _variantNameCtrls = {};
  final Map<int, TextEditingController> _variantPriceCtrls = {};
  final Map<int, TextEditingController> _addonGroupNameCtrls = {};
  final Map<String, TextEditingController> _addonOptionNameCtrls = {};
  final Map<String, TextEditingController> _addonOptionPriceCtrls = {};
  final Map<int, TextEditingController> _comboQtyCtrls = {};

  List<MenuComboComponentModel> _comboComponents = [];
  List<MenuItemModel> _availableItems = [];



  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _nameController = TextEditingController(text: item?.nameEn ?? '');
    _nameMmController = TextEditingController(text: item?.nameMm ?? '');
    _nameThController = TextEditingController(text: item?.nameTh ?? '');

    _descriptionController = TextEditingController(
      text: item?.descriptionEn ?? item?.description ?? '',
    );
    _descriptionMmController = TextEditingController(
      text: item?.descriptionMm ?? '',
    );
    _descriptionThController = TextEditingController(
      text: item?.descriptionTh ?? '',
    );

    _priceController = TextEditingController(
      text: (item?.price == null || item?.price == 0.0) ? '' : item?.price.toString(),
    );
    _originalPriceController = TextEditingController(
      text: (item?.originalPrice == null || item?.originalPrice == 0.0) ? '' : item?.originalPrice.toString(),
    );
    _stockQuantityController = TextEditingController(
      text: (item?.stockQuantity == null || item?.stockQuantity == 0) ? '' : item?.stockQuantity.toString(),
    );
    _displayOrderController = TextEditingController(
      text: item?.displayOrder?.toString() ?? '0',
    );
    _discountAmountController = TextEditingController(
      text: (item?.discountAmount == null || item?.discountAmount == 0.0) ? '' : item?.discountAmount.toString(),
    );
    _discountPercentController = TextEditingController(
      text: (item?.discountPercentage == null || item?.discountPercentage == 0.0) ? '' : item?.discountPercentage.toString(),
    );

    if (item?.currency != null && item!.currency!.isNotEmpty) {
      _currency = item.currency!;
    }

    if (item != null) {
      _isPopular = item.isPopular;
      _isRecommended = item.isRecommended;
      _isSpicy = item.isSpicy;
      _isVegetarian = item.isVegetarian;
      _isHotDeal = item.isHotDeal;
      _isCombo = item.isCombo;
      _isAvailable = item.isAvailable;

      _selectedTagIds = List.from(item.tagIds);
      _selectedMealTypes = List.from(item.mealTypes);
      _variants = List.from(item.variants);
      _optionGroups = List.from(item.optionGroups);
      _comboComponents = List.from(item.components);
    }

    _fetchAllData();
  }

  Future<void> _fetchAllData() async {
    setState(() => _isLoadingData = true);
    try {
      final results = await Future.wait<dynamic>([
        _menuService.getCategories(forceRefresh: true),
        _menuService.getMasterCategories(forceRefresh: true),
        _menuService.getMasterMenuItems(),
        _menuService.getMenuTags(),
        _menuService.getMenuItems(limit: 1000), // Fetch items for combo components
      ]);

      final categories = results[0] as List<MenuCategoryModel>?;
      final mCategories = results[1] as List<MasterDataModel>?;
      final mItems = results[2] as List<MasterDataModel>?;
      final tags = results[3] as List<MasterDataModel>?;
      final allItems = results[4] as List<MenuItemModel>?;

      if (mounted) {
        setState(() {
          _categories = categories ?? [];
          _masterCategories = mCategories ?? [];
          _masterItems = mItems ?? [];
          _menuTags = tags ?? [];
          _availableItems = allItems ?? [];

          final item = widget.item;
          if (item != null) {
            if (_categories.isNotEmpty) {
              try {
                _selectedCategory = _categories.firstWhere(
                  (c) => c.id == item.menuCategoryId,
                );
              } catch (_) {
                _selectedCategory = _categories.first;
              }
            }
            if (_masterCategories.isNotEmpty && item.masterCategoryId != null) {
              try {
                _selectedMasterCategory = _masterCategories.firstWhere(
                  (c) => c.id == item.masterCategoryId,
                );
              } catch (_) {}
            }
            if (_masterItems.isNotEmpty && item.masterItemId != null) {
              try {
                _selectedMasterItem = _masterItems.firstWhere(
                  (i) => i.id == item.masterItemId,
                );
              } catch (_) {}
            }
          } else if (_categories.isNotEmpty) {
            _selectedCategory = _categories.first;
          }
          _isLoadingData = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching data: $e');
      if (mounted) setState(() => _isLoadingData = false);
    }
  }

  void _validatePrices() {
    final originalPriceText = _originalPriceController.text.replaceAll(',', '');
    final discountPriceText = _priceController.text.replaceAll(',', '');

    final originalPrice = double.tryParse(originalPriceText) ?? 0;
    final discountPrice = double.tryParse(discountPriceText) ?? 0;

    setState(() {
      if (discountPrice > originalPrice && originalPrice > 0) {
        _priceWarning = 'Discount price cannot be greater than original price';
      } else {
        _priceWarning = null;
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _nameController.dispose();
    _nameMmController.dispose();
    _nameThController.dispose();
    _descriptionController.dispose();
    _descriptionMmController.dispose();
    _descriptionThController.dispose();
    _priceController.dispose();
    _originalPriceController.dispose();
    _stockQuantityController.dispose();
    _displayOrderController.dispose();
    _discountAmountController.dispose();
    _discountPercentController.dispose();
    for (final c in _variantNameCtrls.values) { c.dispose(); }
    for (final c in _variantPriceCtrls.values) { c.dispose(); }
    for (final c in _addonGroupNameCtrls.values) { c.dispose(); }
    for (final c in _addonOptionNameCtrls.values) { c.dispose(); }
    for (final c in _addonOptionPriceCtrls.values) { c.dispose(); }
    for (final c in _comboQtyCtrls.values) { c.dispose(); }
    super.dispose();
  }

  void _scrollToKey(GlobalKey key) {
    final context = key.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        alignment: 0.1,
      );
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    // Additional validations — scroll to first error
    if (_nameController.text.trim().isEmpty) {
      _scrollToKey(_nameKey);
      _showError('Item Name (EN) is required');
      return;
    }
    if (_selectedMasterCategory == null) {
      _scrollToKey(_masterCategoryKey);
      _showError('Master Category is required');
      return;
    }
    if (_selectedCategory == null) {
      _scrollToKey(_categoryKey);
      _showError('Category is required');
      return;
    }
    if (_selectedMealTypes.isEmpty) {
      _scrollToKey(_mealTypesKey);
      _showError('At least one Meal Type is required');
      return;
    }
    if (_selectedTagIds.isEmpty &&
        !_isPopular &&
        !_isVegetarian &&
        !_isSpicy &&
        !_isCombo &&
        !_isRecommended &&
        !_isHotDeal) {
      _scrollToKey(_tagsKey);
      _showError('At least one Tag is required');
      return;
    }
    final opText = _originalPriceController.text.replaceAll(',', '');
    if (opText.isEmpty || (double.tryParse(opText) ?? 0) <= 0) {
      _scrollToKey(_priceKey);
      _showError('Original Price is required and must be greater than 0');
      return;
    }

    if (_priceWarning != null) {
      _scrollToKey(_priceKey);
      _showError(_priceWarning!);
      return;
    }

    // Final price check
    final priceVal = double.tryParse(_priceController.text.replaceAll(',', '')) ?? 0;
    final originalPriceVal = double.tryParse(_originalPriceController.text.replaceAll(',', '')) ?? 0;
    final discountAmountVal = double.tryParse(_discountAmountController.text.replaceAll(',', '')) ?? 0;

    if (priceVal > 999999.9 || originalPriceVal > 999999.9 || discountAmountVal > 999999.9) {
      _scrollToKey(_priceKey);
      _showError('Price too large');
      return;
    }

    setState(() => _isSaving = true);

    final payload = {
      'nameEn': _nameController.text,
      'nameMm': _nameMmController.text,
      'nameTh': _nameThController.text,
      'descriptionEn': _descriptionController.text,
      'descriptionMm': _descriptionMmController.text,
      'descriptionTh': _descriptionThController.text,
      'price':
          double.tryParse(_priceController.text.replaceAll(',', '')) ?? 0.0,
      'originalPrice': double.tryParse(
        _originalPriceController.text.replaceAll(',', ''),
      ),
      'discountAmount':
          double.tryParse(_discountAmountController.text.replaceAll(',', '')) ??
          0.0,
      'discountPercentage':
          double.tryParse(_discountPercentController.text) ?? 0.0,
      'currency': _currency,
      'stockQuantity': int.tryParse(_stockQuantityController.text) ?? 0,
      'displayOrder': int.tryParse(_displayOrderController.text) ?? 0,
      'categoryId': _selectedCategory?.id,
      'menuCategoryId': _selectedCategory?.id,
      'masterCategoryId': _selectedMasterCategory?.id,
      'masterItemId': _selectedMasterItem?.id,
      'tagIds': _selectedTagIds,
      'mealTypes': _selectedMealTypes,

      'isAvailable': _isAvailable,
      'isPopular': _isPopular,
      'isVegetarian': _isVegetarian,
      'isSpicy': _isSpicy,
      'isRecommended': _isRecommended,
      'isHotDeal': _isHotDeal,
      'isCombo': _isCombo,

      'imageUrl': widget.item?.imageUrl, // Keep existing URL if no new image
      'optionGroups': _optionGroups.map((o) => o.toJson()).toList(),
      'variants': _variants.map((v) => v.toJson()).toList(),
      'components': _isCombo
          ? _comboComponents.map((c) => c.toJson()).toList()
          : [],
    };

    bool success;
    File? imageFile;
    if (_pickedImage != null) {
      imageFile = File(_pickedImage!.path);
    }

    if (widget.item != null) {
      success = await _menuService.updateMenuItem(
        widget.item!.id,
        payload,
        image: imageFile,
      );
    } else {
      success = await _menuService.createMenuItem(payload, image: imageFile);
    }

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully requested'),
            backgroundColor: Color(0xFFED3A72),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save item'),
            backgroundColor: Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  Future<bool> _deleteItem() async {
    if (widget.item == null) return false;
    setState(() => _isSaving = true);
    final success = await _menuService.deleteMenuItem(widget.item!.id);
    if (mounted) {
      setState(() => _isSaving = false);
    }
    return success;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFEF4444),
      ),
    );
  }

  String? _priceValidator(String? value) {
    if (value == null || value.isEmpty) return null;
    final cleanValue = value.replaceAll(',', '');
    final price = double.tryParse(cleanValue);
    if (price != null && price > 999999.9) {
      return 'Price too large';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {},
      child: Scaffold(
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
            widget.item == null ? 'Create Item' : 'Edit Item',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1E293B),
            ),
          ),
          centerTitle: false,
        ),
        body: _isLoadingData
            ? _buildSkeletonForm()
            : SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
                      if (widget.item?.pendingStatus == 'REJECTED' && widget.item?.rejectReason != null)
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 24),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF2F2),
                            border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Rejected',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFFEF4444),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                widget.item!.rejectReason!,
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: const Color(0xFFEF4444),
                                ),
                              ),
                            ],
                          ),
                        ),
                      _buildImageUploadSection(),
                      const SizedBox(height: 32),

                      // Item Information Section
                      _buildSectionTitle('ITEM INFORMATION'),
                      const SizedBox(height: 16),
                      _buildLanguagePills(
                        selectedLang: _selectedItemInfoLang,
                        onChanged: (val) =>
                            setState(() => _selectedItemInfoLang = val),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(key: _nameKey, child: _buildItemInfoFields()),
                      const SizedBox(height: 16),
                      const SizedBox(height: 16),
                      const SizedBox(height: 16),
                      _buildDropdownField<MasterDataModel>(
                        key: _masterCategoryKey,
                        label: 'Master Category',
                        value: _selectedMasterCategory,
                        items: _masterCategories,
                        hint: 'Search master categories...',
                        isRequired: true,
                        onChanged: (val) =>
                            setState(() => _selectedMasterCategory = val),
                      ),
                      const SizedBox(height: 16),
                      _buildDropdownField<MenuCategoryModel>(
                        key: _categoryKey,
                        label: 'Category',
                        value: _selectedCategory,
                        items: _categories,
                        hint: 'Search categories...',
                        isRequired: true,
                        onChanged: (val) =>
                            setState(() => _selectedCategory = val),
                        showClearIcon: true,
                        onClear: () => setState(() => _selectedCategory = null),
                      ),
                      const SizedBox(height: 32),

                      // Categorization Section
                      _buildSectionTitle('CATEGORIZATION'),
                      const SizedBox(height: 16),
                      SizedBox(key: _mealTypesKey, child: _buildMealTypesSelection()),
                      const SizedBox(height: 24),
                      SizedBox(key: _tagsKey, child: _buildTagsSelection()),
                      const SizedBox(height: 32),

                      // Pricing Section
                      SizedBox(key: _priceKey, child: _buildSectionTitle('PRICING')),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              'Original Price',
                              _originalPriceController,
                              hint: '0.00',
                              keyboardType: TextInputType.number,
                              isRequired: true,
                              prefixText: '฿ ',
                              textAlign: TextAlign.right,
                              onChanged: (_) => _validatePrices(),
                              validator: _priceValidator,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTextField(
                              'Discount Price',
                              _priceController,
                              hint: '0.00',
                              keyboardType: TextInputType.number,
                              prefixText: '฿ ',
                              textAlign: TextAlign.right,
                              onChanged: (_) => _validatePrices(),
                              validator: _priceValidator,
                            ),
                          ),
                        ],
                      ),
                      if (_priceWarning != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _priceWarning!,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: const Color(0xFFEF4444),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                      const SizedBox(height: 32),

                      // Properties Section
                      _buildSectionTitle('PROPERTIES'),
                      const SizedBox(height: 16),
                      _buildPropertiesSection(),
                      const SizedBox(height: 32),

                      // Variants Section
                      _buildSectionTitle('VARIANTS'),
                      const SizedBox(height: 16),
                      ..._variants.asMap().entries.map(
                        (entry) => _buildVariantCard(entry.value, entry.key),
                      ),
                      _buildOutlinedButton('+ Add Variant', _addNewVariant),
                      const SizedBox(height: 32),

                      // Add On Section
                      _buildSectionTitle('ADD-ONS'),
                      const SizedBox(height: 16),
                      ..._optionGroups.asMap().entries.map(
                        (entry) =>
                            _buildOptionGroupCard(entry.value, entry.key),
                      ),
                      _buildOutlinedButton('+ Add Add-on', _addNewOptionGroup),

                      if (_isCombo) ...[
                        const SizedBox(height: 32),
                        _buildSectionTitle('COMBO COMPONENTS'),
                        const SizedBox(height: 16),
                        ..._comboComponents.asMap().entries.map(
                          (entry) =>
                              _buildComboComponentCard(entry.value, entry.key),
                        ),
                        _buildOutlinedButton(
                          '+ Add Component',
                          _addNewComboComponent,
                        ),
                      ],

                      if (widget.item != null) ...[
                        const SizedBox(height: 24),
                        Center(
                          child: TextButton.icon(
                            onPressed: () {
                              GlobalModal.show(
                                context: context,
                                child: ConfirmationSheet(
                                  title: 'Delete Item?',
                                  message: 'Are you sure you want to delete "${widget.item!.displayName}"? This action cannot be undone.',
                                  confirmLabel: 'Delete',
                                  confirmColor: const Color(0xFFEF4444),
                                  onConfirm: () async {
                                    bool success = await _deleteItem();
                                    if (!context.mounted) return;
                                    if (success) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Successfully deleted'),
                                          backgroundColor: Color(0xFFED3A72),
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                      Navigator.of(context).pop(true);
                                    }
                                  },
                                ),
                              );
                            },
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Color(0xFFEF4444),
                            ),
                            label: Text(
                              'Delete menu item',
                              style: GoogleFonts.poppins(
                                color: const Color(0xFFEF4444),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 100), // Padding for bottom button
                    ],
                  ),
                ),
              ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(color: Colors.black.withValues(alpha: 0.05)),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              child: _buildSaveButton(),
            ),
          ),
        ),
      ),
    );
  }

  void _addNewVariant() {
    setState(() {
      _variants.add(
        MenuItemVariantModel(
          id: 0,
          nameEn: '',
          price: 0.0,
          isAvailable: true,
          displayOrder: 0,
        ),
      );
    });
  }

  void _addNewOptionGroup() {
    setState(() {
      _optionGroups.add(
        MenuItemOptionGroupModel(
          id: 0,
          nameEn: '',
          isAvailable: true,
          minSelection: 0,
          maxSelection: 0,
          displayOrder: 0,
          options: [
            MenuItemOptionModel(id: 0, nameEn: '', price: 0.0, displayOrder: 0),
          ],
        ),
      );
    });
  }

  void _addNewComboComponent() {
    setState(() {
      _comboComponents.add(
        MenuComboComponentModel(
          includedItemId: 0,
          quantity: 1,
          displayOrder: _comboComponents.length,
        ),
      );
    });
  }

  void _removeComboComponent(int index) {
    setState(() {
      _comboComponents.removeAt(index);
      _comboQtyCtrls[index]?.dispose();
      _comboQtyCtrls.remove(index);

      // Shift subsequent controllers up by 1
      for (int i = index + 1; i <= _comboComponents.length; i++) {
        if (_comboQtyCtrls.containsKey(i)) {
          _comboQtyCtrls[i - 1] = _comboQtyCtrls.remove(i)!;
        }
      }
    });
  }

  /*
  void _addNewOptionToGroup(int groupIndex) {
    setState(() {
      final opts = List<MenuItemOptionModel>.from(
        _optionGroups[groupIndex].options,
      );
      opts.add(
        MenuItemOptionModel(id: 0, nameEn: '', price: 0.0, displayOrder: 0),
      );
      _optionGroups[groupIndex] = _optionGroups[groupIndex].copyWith(
        options: opts,
      );
    });
  }
  */

  void _removeVariant(int index) {
    setState(() {
      _variants.removeAt(index);
      _variantNameCtrls[index]?.dispose();
      _variantPriceCtrls[index]?.dispose();
      _variantNameCtrls.remove(index);
      _variantPriceCtrls.remove(index);
      
      // Shift subsequent controllers up by 1
      for (int i = index + 1; i <= _variants.length; i++) {
        if (_variantNameCtrls.containsKey(i)) {
          _variantNameCtrls[i - 1] = _variantNameCtrls.remove(i)!;
        }
        if (_variantPriceCtrls.containsKey(i)) {
          _variantPriceCtrls[i - 1] = _variantPriceCtrls.remove(i)!;
        }
        if (_variantLangs.containsKey(i)) {
          _variantLangs[i - 1] = _variantLangs.remove(i)!;
        }
      }
    });
  }

  void _removeOptionGroup(int index) {
    setState(() {
      final group = _optionGroups.removeAt(index);
      _addonGroupNameCtrls[index]?.dispose();
      _addonGroupNameCtrls.remove(index);
      
      // Dispose all option controllers for this group
      for (int oIndex = 0; oIndex < group.options.length; oIndex++) {
        _addonOptionNameCtrls['$index-$oIndex']?.dispose();
        _addonOptionPriceCtrls['$index-$oIndex']?.dispose();
        _addonOptionNameCtrls.remove('$index-$oIndex');
        _addonOptionPriceCtrls.remove('$index-$oIndex');
      }

      // Shift subsequent group controllers up by 1
      for (int i = index + 1; i <= _optionGroups.length; i++) {
        if (_addonGroupNameCtrls.containsKey(i)) {
          _addonGroupNameCtrls[i - 1] = _addonGroupNameCtrls.remove(i)!;
        }
        if (_addonLangs.containsKey(i)) {
          _addonLangs[i - 1] = _addonLangs.remove(i)!;
        }
        // Shift option controllers for this group
        final nextGroup = i <= _optionGroups.length ? _optionGroups[i - 1] : null;
        if (nextGroup != null) {
          for (int oIndex = 0; oIndex < nextGroup.options.length; oIndex++) {
            if (_addonOptionNameCtrls.containsKey('$i-$oIndex')) {
              _addonOptionNameCtrls['${i - 1}-$oIndex'] = _addonOptionNameCtrls.remove('$i-$oIndex')!;
            }
            if (_addonOptionPriceCtrls.containsKey('$i-$oIndex')) {
              _addonOptionPriceCtrls['${i - 1}-$oIndex'] = _addonOptionPriceCtrls.remove('$i-$oIndex')!;
            }
          }
        }
      }
    });
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: GoogleFonts.poppins(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF94A3B8),
        letterSpacing: 1.2,
      ),
    );
  }

  /*
  Widget _buildMasterItemSelection() {
    return _buildDropdownField<MasterDataModel>(
      label: 'Master Item',
      value: _selectedMasterItem,
      items: _masterItems,
      hint: 'Search master items...',
      onChanged: (val) {
        setState(() => _selectedMasterItem = val);
      },
    );
  }
  */

  Widget _buildPropertiesSection() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          _buildPropertySwitch(
            'Available',
            _isAvailable,
            (v) => setState(() => _isAvailable = v),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          _buildPropertySwitch(
            'Popular',
            _isPopular,
            (v) => setState(() => _isPopular = v),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          _buildPropertySwitch(
            'Recommended',
            _isRecommended,
            (v) => setState(() => _isRecommended = v),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          _buildPropertySwitch(
            'Combo Set',
            _isCombo,
            (v) => setState(() => _isCombo = v),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          _buildPropertySwitch(
            'Vegetarian',
            _isVegetarian,
            (v) => setState(() => _isVegetarian = v),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          _buildPropertySwitch(
            'Spicy',
            _isSpicy,
            (v) => setState(() => _isSpicy = v),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          _buildPropertySwitch(
            'Hot Deal',
            _isHotDeal,
            (v) => setState(() => _isHotDeal = v),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertySwitch(
    String label,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF1E293B),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: const Color(0xFFED3A72),
            activeTrackColor: const Color(0xFFED3A72).withValues(alpha: 0.2),
          ),
        ],
      ),
    );
  }

  Widget _buildItemInfoFields() {
    TextEditingController nameCtrl;
    TextEditingController descCtrl;
    if (_selectedItemInfoLang == 'MM') {
      nameCtrl = _nameMmController;
      descCtrl = _descriptionMmController;
    } else if (_selectedItemInfoLang == 'TH') {
      nameCtrl = _nameThController;
      descCtrl = _descriptionThController;
    } else {
      nameCtrl = _nameController;
      descCtrl = _descriptionController;
    }

    return Column(
      children: [
        _buildTextField(
          'Item Name ($_selectedItemInfoLang)',
          nameCtrl,
          hint: 'Enter item name',
          isRequired: _selectedItemInfoLang == 'EN',
          maxLength: 100,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          'Description ($_selectedItemInfoLang)',
          descCtrl,
          hint: 'Enter description',
          isMultiline: true,
          maxLength: 500,
        ),
      ],
    );
  }

  Widget _buildLanguagePills({
    required String selectedLang,
    required ValueChanged<String> onChanged,
  }) {
    final languages = ['EN', 'MM', 'TH'];
    return Row(
      children: languages.map((lang) {
        final isSelected = lang == selectedLang;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: InkWell(
            onTap: () => onChanged(lang),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFED3973) : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected
                      ? Colors.transparent
                      : const Color(0xFFE2E8F0),
                ),
              ),
              child: Text(
                lang,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : const Color(0xFF64748B),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildVariantCard(MenuItemVariantModel variant, int index) {
    final lang = _variantLangs[index] ?? 'EN';

    final nameText = lang == 'MM'
        ? variant.nameMm
        : (lang == 'TH' ? variant.nameTh : variant.nameEn);
    final nameCtrl = _variantNameCtrls.putIfAbsent(
      index,
      () => TextEditingController(text: nameText),
    );
    // Always sync from model — fixes stale text after deletion+index shift
    if (nameCtrl.text != (nameText ?? '')) {
      nameCtrl.text = nameText ?? '';
    }

    final priceText = variant.price == 0.0 ? '' : variant.price.toString();
    final priceCtrl = _variantPriceCtrls.putIfAbsent(
      index,
      () => TextEditingController(text: priceText),
    );
    if (priceCtrl.text != priceText) {
      priceCtrl.text = priceText;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Variant #${index + 1}',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Color(0xFFEF4444),
                    size: 20,
                  ),
                  onPressed: () => _removeVariant(index),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLanguagePills(
                  selectedLang: lang,
                  onChanged: (val) =>
                      setState(() => _variantLangs[index] = val),
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  'Variant Name ($lang)',
                  nameCtrl,
                  maxLength: 100,
                  onChanged: (v) {
                    final currentVariant = _variants[index];
                    _variants[index] = MenuItemVariantModel(
                      id: currentVariant.id,
                      price: currentVariant.price,
                      nameEn: lang == 'EN' ? v : currentVariant.nameEn,
                      nameMm: lang == 'MM' ? v : currentVariant.nameMm,
                      nameTh: lang == 'TH' ? v : currentVariant.nameTh,
                      isAvailable: currentVariant.isAvailable,
                      displayOrder: currentVariant.displayOrder,
                    );
                  },
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  'Price',
                  priceCtrl,
                  keyboardType: TextInputType.number,
                  validator: _priceValidator,
                  onChanged: (v) {
                    final currentVariant = _variants[index];
                    _variants[index] = MenuItemVariantModel(
                      id: currentVariant.id,
                      price: double.tryParse(v) ?? 0.0,
                      nameEn: currentVariant.nameEn,
                      nameMm: currentVariant.nameMm,
                      nameTh: currentVariant.nameTh,
                      isAvailable: currentVariant.isAvailable,
                      displayOrder: currentVariant.displayOrder,
                    );
                  },
                ),
                const SizedBox(height: 16),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text(
                      'Available',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    const Spacer(),
                    Switch(
                      value: variant.isAvailable,
                      onChanged: (v) {
                        setState(() {
                          final currentVariant = _variants[index];
                          _variants[index] = MenuItemVariantModel(
                            id: currentVariant.id,
                            price: currentVariant.price,
                            nameEn: currentVariant.nameEn,
                            nameMm: currentVariant.nameMm,
                            nameTh: currentVariant.nameTh,
                            isAvailable: v,
                            displayOrder: currentVariant.displayOrder,
                          );
                        });
                      },
                      activeThumbColor: const Color(0xFFED3A72),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComboComponentCard(
    MenuComboComponentModel component,
    int index,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Component #${index + 1}',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  color: Color(0xFFEF4444),
                  size: 20,
                ),
                onPressed: () => _removeComboComponent(index),
              ),
            ],
          ),
          _buildTextField(
            'Quantity',
            () {
              final qtyText = component.quantity.toString();
              final qtyCtrl = _comboQtyCtrls.putIfAbsent(
                index,
                () => TextEditingController(text: qtyText),
              );
              // Always sync from model
              if (qtyCtrl.text != qtyText) {
                qtyCtrl.text = qtyText;
              }
              return qtyCtrl;
            }(),
            keyboardType: TextInputType.number,
            onChanged: (v) {
              final currentComp = _comboComponents[index];
              _comboComponents[index] = MenuComboComponentModel(
                includedItemId: currentComp.includedItemId,
                quantity: int.tryParse(v) ?? 1,
                displayOrder: currentComp.displayOrder,
                includedItemNameEn: currentComp.includedItemNameEn,
              );
            },
          ),
          const SizedBox(height: 16),
          _buildDropdownField<MenuItemModel>(
            label: 'Included Item',
            value: () {
              try {
                return _availableItems.firstWhere(
                  (i) => i.id == component.includedItemId,
                );
              } catch (_) {
                return null;
              }
            }(),
            items: _availableItems,
            hint: 'Select an item...',
            isRequired: true,
            onChanged: (val) {
              setState(() {
                final currentComp = _comboComponents[index];
                _comboComponents[index] = MenuComboComponentModel(
                  includedItemId: val?.id ?? 0,
                  quantity: currentComp.quantity,
                  displayOrder: currentComp.displayOrder,
                  includedItemNameEn: val?.nameEn ?? '',
                );
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOptionGroupCard(MenuItemOptionGroupModel group, int index) {
    final lang = _addonLangs[index] ?? 'EN';

    final groupNameText = lang == 'MM'
        ? group.nameMm
        : (lang == 'TH' ? group.nameTh : group.nameEn);
    final groupNameCtrl = _addonGroupNameCtrls.putIfAbsent(
      index,
      () => TextEditingController(text: groupNameText),
    );
    if (groupNameCtrl.text != groupNameText && groupNameText != null && groupNameText.isNotEmpty) {
      groupNameCtrl.text = groupNameText;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Add-on: ${group.displayName.isEmpty ? "New Add-on" : group.displayName}',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Color(0xFFEF4444),
                    size: 20,
                  ),
                  onPressed: () => _removeOptionGroup(index),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLanguagePills(
                  selectedLang: lang,
                  onChanged: (val) => setState(() => _addonLangs[index] = val),
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  'Add-on Name ($lang)',
                  groupNameCtrl,
                  maxLength: 100,
                  onChanged: (v) {
                    final currentGroup = _optionGroups[index];
                    final newNameEn = lang == 'EN' ? v : currentGroup.nameEn;
                    final newNameMm = lang == 'MM' ? v : currentGroup.nameMm;
                    final newNameTh = lang == 'TH' ? v : currentGroup.nameTh;

                    List<MenuItemOptionModel> newOptions = currentGroup.options;
                    if (currentGroup.options.length == 1) {
                      newOptions = [
                        currentGroup.options[0].copyWith(
                          nameEn: newNameEn,
                          nameMm: newNameMm,
                          nameTh: newNameTh,
                        )
                      ];
                    }

                    _optionGroups[index] = currentGroup.copyWith(
                      nameEn: newNameEn,
                      nameMm: newNameMm,
                      nameTh: newNameTh,
                      options: newOptions,
                    );
                  },
                ),
                const SizedBox(height: 16),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Available',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Switch(
                            value: group.isAvailable,
                            onChanged: (v) {
                              setState(() {
                                final currentGroup = _optionGroups[index];
                                _optionGroups[index] = currentGroup.copyWith(
                                  isAvailable: v,
                                );
                              });
                            },
                            activeThumbColor: const Color(0xFFED3A72),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
                const SizedBox(height: 16),
                ...group.options.asMap().entries.map((optEntry) {
                  final opt = optEntry.value;
                  final oIndex = optEntry.key;

                  final optNameText = lang == 'MM'
                      ? opt.nameMm
                      : (lang == 'TH' ? opt.nameTh : opt.nameEn);
                  final optNameCtrl = _addonOptionNameCtrls.putIfAbsent(
                    '$index-$oIndex',
                    () => TextEditingController(text: optNameText),
                  );
                  // Always sync from model — fixes stale text after deletion+index shift
                  if (optNameCtrl.text != (optNameText ?? '')) {
                    optNameCtrl.text = optNameText ?? '';
                  }

                  final optPriceText = opt.price == 0.0 ? '' : opt.price.toString();
                  final optPriceCtrl = _addonOptionPriceCtrls.putIfAbsent(
                    '$index-$oIndex',
                    () => TextEditingController(text: optPriceText),
                  );
                  if (optPriceCtrl.text != optPriceText) {
                    optPriceCtrl.text = optPriceText;
                  }
                  return Column(
                    children: [
                      if (group.options.length > 1)
                        _buildTextField(
                          'Add-on Name ($lang)',
                          optNameCtrl,
                          maxLength: 100,
                          onChanged: (v) {
                            final currentGroup = _optionGroups[index];
                            final currentOpt = currentGroup.options[oIndex];
                            final newOpts = List<MenuItemOptionModel>.from(
                              currentGroup.options,
                            );
                            newOpts[oIndex] = currentOpt.copyWith(
                              nameEn: lang == 'EN' ? v : currentOpt.nameEn,
                              nameMm: lang == 'MM' ? v : currentOpt.nameMm,
                              nameTh: lang == 'TH' ? v : currentOpt.nameTh,
                            );
                            _optionGroups[index] = currentGroup.copyWith(
                              options: newOpts,
                            );
                          },
                        ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        'Price',
                        optPriceCtrl,
                        keyboardType: TextInputType.number,
                        validator: _priceValidator,
                        onChanged: (v) {
                          final currentGroup = _optionGroups[index];
                          final currentOpt = currentGroup.options[oIndex];
                          final newOpts = List<MenuItemOptionModel>.from(
                            currentGroup.options,
                          );
                          newOpts[oIndex] = currentOpt.copyWith(
                            price: double.tryParse(v) ?? 0.0,
                          );
                          _optionGroups[index] = currentGroup.copyWith(
                            options: newOpts,
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      const SizedBox(height: 16),
                    ],
                  );
                }),

              ],
            ),
          ),
        ],
      ),
    );
  }

  /*
  Widget _buildDropdownFieldStr({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    bool isRequired = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1E293B),
              ),
            ),
            if (isRequired)
              Text(
                ' *',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFED3973),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              items: items
                  .map(
                    (item) => DropdownMenuItem(
                      value: item,
                      child: Text(
                        item,
                        style: GoogleFonts.poppins(fontSize: 14),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
  */

  Widget _buildDropdownField<T>({
    Key? key,
    required String label,
    required T? value,
    required List<T> items,
    required String hint,
    required ValueChanged<T?> onChanged,
    bool showClearIcon = false,
    VoidCallback? onClear,
    bool isRequired = false,
  }) {
    String labelFor(T item) {
      if (item is MasterDataModel) return item.displayName;
      if (item is MenuCategoryModel) return item.displayName;
      if (item is MenuItemModel) return item.nameEn ?? item.displayName;
      return item.toString();
    }

    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1E293B),
              ),
            ),
            if (isRequired)
              Text(
                ' *',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFED3973),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: CustomSearchDropdown<T>(
                items: items,
                value: value,
                hintText: hint,
                searchHintText: 'Search $label...',
                itemLabelBuilder: labelFor,
                onChanged: onChanged,
              ),
            ),
            if (showClearIcon && value != null) ...[
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(
                  Icons.close,
                  size: 18,
                  color: Color(0xFF94A3B8),
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: onClear,
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    String? hint,
    bool isMultiline = false,
    ValueChanged<String>? onChanged,
    bool isRequired = false,
    String? Function(String?)? validator,
    String? prefixText,
    TextAlign textAlign = TextAlign.start,
    TextInputType? keyboardType,
    int? maxLength,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1E293B),
              ),
            ),
            if (isRequired)
              Text(
                ' *',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFED3973),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: isMultiline ? 4 : 1,
          maxLength: maxLength,
          keyboardType: keyboardType,
          onChanged: onChanged,
          validator: validator,
          textAlign: textAlign,
          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500),
          inputFormatters:
              keyboardType == TextInputType.number
                  ? [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    _NumberThousandSeparatorFormatter(),
                  ]
                  : null,
          decoration: InputDecoration(
            prefixText: prefixText,
            prefixStyle: GoogleFonts.poppins(
              color: const Color(0xFF1E293B),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            hintText: hint,
            hintStyle: GoogleFonts.poppins(
              color: const Color(0xFF94A3B8),
              fontSize: 13,
            ),
            filled: true,
            fillColor: Colors.white,
            counterText: '', // Hide the counter for a cleaner look
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFED3973)),
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }

  Widget _buildTagsSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildSectionLabel('Discovery Tags'),
            Text(
              ' *',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFED3973),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 10,
          children: [
            _buildCustomChip(
              label: 'Best Seller',
              selected: _isPopular,
              onTap: () => setState(() => _isPopular = !_isPopular),
            ),
            _buildCustomChip(
              label: 'Vegetarian',
              selected: _isVegetarian,
              onTap: () => setState(() => _isVegetarian = !_isVegetarian),
            ),
            _buildCustomChip(
              label: 'Spicy',
              selected: _isSpicy,
              onTap: () => setState(() => _isSpicy = !_isSpicy),
            ),
            _buildCustomChip(
              label: 'Combo',
              selected: _isCombo,
              onTap: () => setState(() => _isCombo = !_isCombo),
            ),
            _buildCustomChip(
              label: 'Recommended',
              selected: _isRecommended,
              onTap: () => setState(() => _isRecommended = !_isRecommended),
            ),
            _buildCustomChip(
              label: 'Hot Deal',
              selected: _isHotDeal,
              onTap: () => setState(() => _isHotDeal = !_isHotDeal),
            ),
            ..._menuTags.map((tag) {
              final isSelected = _selectedTagIds.contains(tag.id);
              return _buildCustomChip(
                label: tag.displayName,
                selected: isSelected,
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedTagIds.remove(tag.id);
                    } else {
                      _selectedTagIds.add(tag.id);
                    }
                  });
                },
              );
            }),
            _buildCustomChip(label: 'Other', selected: false, onTap: () {}),
          ],
        ),
      ],
    );
  }

  Widget _buildMealTypesSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildSectionLabel('Meal Types'),
            Text(
              ' *',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFED3973),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 10,
          children: [
            ..._mealTypeOptions.map((type) {
              final isSelected = _selectedMealTypes.contains(type);
              return _buildCustomChip(
                label: type,
                selected: isSelected,
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedMealTypes.remove(type);
                    } else {
                      _selectedMealTypes.add(type);
                    }
                  });
                },
              );
            }),
            _buildCustomChip(label: 'Other', selected: false, onTap: () {}),
          ],
        ),
      ],
    );
  }

  Widget _buildCustomChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFED3A72) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? Colors.transparent : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected)
              const Padding(
                padding: EdgeInsets.only(right: 6),
                child: Icon(Icons.check, color: Colors.white, size: 14),
              ),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: selected ? Colors.white : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOutlinedButton(String label, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: const Color(0xFFFEF2F2),
          side: const BorderSide(color: Color(0xFFFEE2E2), width: 1.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (label.startsWith('+'))
              const Padding(padding: EdgeInsets.only(right: 6)),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFED3A72),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _handleSave,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFED3A72),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: _isSaving
            ? const CustomLoadingIndicator(size: 24, color: Colors.white)
            : Text(
                widget.item == null ? 'Create Item' : 'Update Item',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  Widget _buildImageUploadSection() {
    final existingUrl = widget.item?.imageUrl;

    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        width: double.infinity,
        height: 200,
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: _pickedImage == null && existingUrl == null
              ? Border.all(color: const Color(0xFFE2E8F0), width: 1.5)
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (_pickedImage != null)
                kIsWeb
                    ? Image.network(_pickedImage!.path, fit: BoxFit.cover)
                    : Image.file(File(_pickedImage!.path), fit: BoxFit.cover)
              else if (existingUrl != null && existingUrl.isNotEmpty)
                CachedNetworkImage(
                  imageUrl: existingUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) =>
                      const Center(child: CustomLoadingIndicator(size: 24)),
                  errorWidget: (context, url, error) => const Icon(Icons.error),
                )
              else
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.camera_alt_outlined,
                        color: Color(0xFFED3973),
                        size: 32,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Tap to upload',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                ),
              if (_pickedImage != null ||
                  (existingUrl != null && existingUrl.isNotEmpty))
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Colors.black12, blurRadius: 4),
                      ],
                    ),
                    child: const Icon(
                      Icons.refresh_rounded,
                      size: 20,
                      color: Color(0xFFED3973),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final result = await ImageUploadService().pickFromGallery();
    
    if (result.isTooLarge) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Image size must be less than 1MB'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (result.file != null) {
      setState(() => _pickedImage = result.file);
    }
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.poppins(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF1E293B),
      ),
    );
  }

  Widget _buildSkeletonForm() {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Skeleton(width: double.infinity, height: 200),
          SizedBox(height: 16),
          Skeleton(width: 150, height: 16),
          SizedBox(height: 8),
          Skeleton(width: double.infinity, height: 50),
        ],
      ),
    );
  }
}

class _NumberThousandSeparatorFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;

    final String cleanText = newValue.text.replaceAll(',', '');
    final double? value = double.tryParse(cleanText);

    if (value == null) return newValue;

    final parts = cleanText.split('.');
    final formatter = NumberFormat('#,###');
    String formatted = formatter.format(double.parse(parts[0]));

    if (parts.length > 1) {
      formatted += '.${parts[1]}';
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
