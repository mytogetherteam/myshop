import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:my_shop/core/utils/app_colors.dart';
import 'package:my_shop/core/presentation/widgets/gradient_widgets.dart';
import 'package:my_shop/core/presentation/widgets/primary_gradient_button.dart';
import 'package:my_shop/core/presentation/widgets/primary_gradient_switch.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:my_shop/core/presentation/widgets/custom_loading_indicator.dart';
import 'package:my_shop/core/data/services/image_upload_service.dart';
import 'package:my_shop/core/presentation/widgets/custom_search_dropdown.dart';
import 'package:my_shop/core/presentation/widgets/global_modal.dart';
import '../../data/models/menu_item_model.dart';
import '../../data/models/menu_item_payload.dart';
import '../../data/models/variant_group_mapper.dart';
import '../../data/models/option_group_mapper.dart';
import '../../data/models/menu_category_model.dart';
import '../../data/services/menu_service.dart';
import 'package:my_shop/core/presentation/widgets/skeleton.dart';
import 'package:my_shop/core/data/models/master_data_model.dart';
import 'package:my_shop/core/presentation/widgets/confirmation_sheet.dart';
import 'package:my_shop/core/presentation/widgets/app_dialog.dart';
import 'package:my_shop/core/localization/app_localizations.dart';
import '../widgets/variant_groups_card.dart';
import '../widgets/addon_groups_card.dart';

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
  List<MasterDataModel> _masterCategories = [];
  MasterDataModel? _selectedMasterCategory;
  List<MasterDataModel> _menuTags = [];
  List<int> _selectedTagIds = [];

  // Meal Types
  final List<String> _mealTypeOptions = ['Breakfast', 'Lunch', 'Dinner', 'Other'];
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
  List<MenuItemVariantGroupEditModel> _variantGroups = [];
  List<MenuItemOptionGroupModel> _optionGroups = [];

  // UI States
  String _selectedItemInfoLang = 'EN';

  final Map<int, TextEditingController> _comboQtyCtrls = {};

  List<MenuComboComponentModel> _comboComponents = [];
  List<MenuItemModel> _availableItems = [];

  bool _isLocaleInitialized = false;

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

    final hasDiscount =
        (item?.discountAmount ?? 0) > 0 || (item?.discountPercentage ?? 0) > 0;
    _priceController = TextEditingController(
      text: (!hasDiscount || item?.price == null || item?.price == 0.0)
          ? ''
          : item?.price.toString(),
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
      _variantGroups = VariantGroupMapper.fromMenuItem(item);
      _optionGroups = OptionGroupMapper.fromMenuItem(item);
      _comboComponents = List.from(item.components);
    }

    if (widget.item != null) {
      _loadItemDetail(widget.item!.id);
    }

    _fetchAllData();
  }

  Future<void> _loadItemDetail(int itemId) async {
    final detail = await _menuService.getMenuItemDetail(itemId);
    if (!mounted || detail == null) return;
    setState(() {
      _variantGroups = VariantGroupMapper.fromMenuItem(detail);
      _optionGroups = OptionGroupMapper.fromMenuItem(detail);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isLocaleInitialized) {
      final locale = Localizations.localeOf(context);
      final langCode = locale.languageCode.toUpperCase();
      if (langCode == 'MY' || langCode == 'MM') {
        _selectedItemInfoLang = 'MM';
      } else if (langCode == 'TH') {
        _selectedItemInfoLang = 'TH';
      } else {
        _selectedItemInfoLang = 'EN';
      }
      _isLocaleInitialized = true;
    }
  }

  Future<void> _fetchAllData() async {
    setState(() => _isLoadingData = true);
    try {
      final results = await Future.wait<dynamic>([
        _menuService.getCategories(forceRefresh: true),
        _menuService.getMasterCategories(),
        _menuService.getMenuTags(),
        _menuService.getMenuItems(limit: 1000),
      ]);

      final categories = results[0] as List<MenuCategoryModel>?;
      final mCategories = results[1] as List<MasterDataModel>?;
      final tags = results[2] as List<MasterDataModel>?;
      final allItems = results[3] as List<MenuItemModel>?;

      if (mounted) {
        setState(() {
          _categories = categories ?? [];
          _masterCategories = mCategories ?? [];
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
          } else if (_categories.isNotEmpty) {
            _selectedCategory = _categories.first;
          }
          _isLoadingData = false;
        });

        if (widget.item != null && (widget.item?.imageUrl == null || widget.item!.imageUrl!.isEmpty)) {
          Future.microtask(() => _showNoImageAlertBottomSheet());
        }
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
    HapticFeedback.lightImpact();
    if (!_formKey.currentState!.validate()) return;

    // Additional validations — scroll to first error
    if (_nameController.text.trim().isEmpty) {
      _scrollToKey(_nameKey);
      AppDialog.showToast(context, 'Item Name (EN) is required', isError: true);
      return;
    }
    if (_selectedMasterCategory == null) {
      _scrollToKey(_masterCategoryKey);
      AppDialog.showToast(context, 'Master Category is required', isError: true);
      return;
    }
    if (_selectedCategory == null) {
      _scrollToKey(_categoryKey);
      AppDialog.showToast(context, 'Category is required', isError: true);
      return;
    }
    if (_selectedMealTypes.isEmpty) {
      _scrollToKey(_mealTypesKey);
      AppDialog.showToast(context, 'At least one Meal Type is required', isError: true);
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
      AppDialog.showToast(context, 'At least one Tag is required', isError: true);
      return;
    }
    final opText = _originalPriceController.text.replaceAll(',', '');
    if (opText.isEmpty || (double.tryParse(opText) ?? 0) <= 0) {
      _scrollToKey(_priceKey);
      AppDialog.showToast(context, 'Original Price is required and must be greater than 0', isError: true);
      return;
    }

    if (_priceWarning != null) {
      _scrollToKey(_priceKey);
      AppDialog.showToast(context, _priceWarning!, isError: true);
      return;
    }

    // Final price check
    final priceVal = double.tryParse(_priceController.text.replaceAll(',', '')) ?? 0;
    final originalPriceVal = double.tryParse(_originalPriceController.text.replaceAll(',', '')) ?? 0;
    final discountAmountVal = double.tryParse(_discountAmountController.text.replaceAll(',', '')) ?? 0;

    if (priceVal > 999999.9 || originalPriceVal > 999999.9 || discountAmountVal > 999999.9) {
      _scrollToKey(_priceKey);
      AppDialog.showToast(context, 'Price too large', isError: true);
      return;
    }

    setState(() => _isSaving = true);

    // "Discount Price" is the final selling price. The backend has no price
    // column; it derives the selling price from originalPrice - discountAmount.
    // Convert the entered selling price into a fixed discount amount.
    final computedDiscountAmount =
        (priceVal > 0 && priceVal < originalPriceVal)
        ? originalPriceVal - priceVal
        : 0.0;

    final relationPayload = MenuItemPayloadBuilder.build(
      variantGroups: _variantGroups,
      optionGroups: _optionGroups,
      editingExistingItem: widget.item != null,
    );

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
      'discountAmount': computedDiscountAmount,
      'discountPercentage': 0.0,
      'currency': _currency,
      'stockQuantity': int.tryParse(_stockQuantityController.text) ?? 0,
      'displayOrder': int.tryParse(_displayOrderController.text) ?? 0,
      'categoryId': _selectedCategory?.id,
      'menuCategoryId': _selectedCategory?.id,
      'masterCategoryId': _selectedMasterCategory?.id,
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
      ...relationPayload.toJson(),
      'components': _isCombo
          ? _comboComponents.map((c) => c.toJson()).toList()
          : [],
    };

    bool success;

    if (widget.item != null) {
      success = await _menuService.updateMenuItem(
        widget.item!.id,
        payload,
        imageFile: _pickedImage != null ? File(_pickedImage!.path) : null,
      );
    } else {
      success = await _menuService.createMenuItem(
        payload,
        imageFile: _pickedImage != null ? File(_pickedImage!.path) : null,
      );
    }

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        AppDialog.showToast(
          context,
          AppLocalizations.of(context)?.translate('successfully_uploaded') ??
              'Successfully Uploaded',
        );
        Navigator.of(context).pop(true);
      } else {
        AppDialog.showToast(context, 'Failed to save item', isError: true);
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
    final t = AppLocalizations.of(context);
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {},
      child: Scaffold(
        backgroundColor: Theme.of(context).brightness == Brightness.dark ? Theme.of(context).cardColor : Colors.white,
        appBar: AppBar(
          backgroundColor: Theme.of(context).brightness == Brightness.dark ? Theme.of(context).cardColor : Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            widget.item == null 
                ? (t?.translate('add_new_item') ?? 'Create Item') 
                : (t?.translate('edit_item') ?? 'Edit Item'),
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).textTheme.bodyLarge?.color,
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
                      SizedBox(height: 10),
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
                                  Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'Rejected',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFFEF4444),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
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
                      SizedBox(height: 32),

                      // Item Information Section
                      _buildSectionTitle(t?.translate('item_information') ?? 'Item Information'),
                      SizedBox(height: 16),
                      _buildLanguagePills(
                        selectedLang: _selectedItemInfoLang,
                        onChanged: (val) =>
                            setState(() => _selectedItemInfoLang = val),
                      ),
                      SizedBox(height: 16),
                      SizedBox(key: _nameKey, child: _buildItemInfoFields()),
                      SizedBox(height: 16),
                      SizedBox(height: 16),
                      SizedBox(height: 16),
                      _buildDropdownField<MasterDataModel>(
                        key: _masterCategoryKey,
                        label: t?.translate('master_category') ?? 'Master Category',
                        value: _selectedMasterCategory,
                        items: _masterCategories,
                        hint: t?.translate('search_master_categories') ?? 'Search master categories...',
                        isRequired: true,
                        onChanged: (val) =>
                            setState(() => _selectedMasterCategory = val),
                      ),
                      SizedBox(height: 16),
                      _buildDropdownField<MenuCategoryModel>(
                        key: _categoryKey,
                        label: t?.translate('category') ?? 'Category',
                        value: _selectedCategory,
                        items: _categories,
                        hint: t?.translate('search_categories') ?? 'Search categories...',
                        isRequired: true,
                        onChanged: (val) =>
                            setState(() => _selectedCategory = val),
                        showClearIcon: true,
                        onClear: () => setState(() => _selectedCategory = null),
                      ),
                      SizedBox(height: 32),

                      // Categorization Section
                      _buildSectionTitle(t?.translate('categorization') ?? 'Categorization'),
                      SizedBox(height: 16),
                      SizedBox(key: _mealTypesKey, child: _buildMealTypesSelection()),
                      SizedBox(height: 24),
                      SizedBox(key: _tagsKey, child: _buildTagsSelection()),
                      SizedBox(height: 32),

                      // Pricing Section
                      SizedBox(key: _priceKey, child: _buildSectionTitle(t?.translate('pricing') ?? 'Pricing')),
                      SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              t?.translate('original_price') ?? 'Original Price',
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
                          SizedBox(width: 16),
                          Expanded(
                            child: _buildTextField(
                              t?.translate('discount_price') ?? 'Discount Price',
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
                        SizedBox(height: 8),
                        Text(
                          _priceWarning!,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: const Color(0xFFEF4444),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                      SizedBox(height: 32),

                      // Properties Section
                      _buildSectionTitle(t?.translate('properties') ?? 'Properties'),
                      SizedBox(height: 16),
                      _buildPropertiesSection(),
                      SizedBox(height: 32),

                      // Advanced Customization
                      _buildSectionTitle(
                        t?.translate('advanced_customization') ??
                            'Advanced Customization',
                      ),
                      SizedBox(height: 16),
                      VariantGroupsCard(
                        variantGroups: _variantGroups,
                        isEditMode: widget.item != null,
                        onChange: (groups) =>
                            setState(() => _variantGroups = groups),
                      ),
                      SizedBox(height: 16),
                      AddonGroupsCard(
                        optionGroups: _optionGroups,
                        isEditMode: widget.item != null,
                        onChange: (groups) =>
                            setState(() => _optionGroups = groups),
                      ),

                      if (_isCombo) ...[
                        SizedBox(height: 32),
                        _buildSectionTitle(t?.translate('combo_components') ?? 'Combo Components'),
                        SizedBox(height: 16),
                        ..._comboComponents.asMap().entries.map(
                          (entry) =>
                              _buildComboComponentCard(entry.value, entry.key),
                        ),
                        _buildOutlinedButton(
                          t?.translate('add_component') ?? '+ Add Component',
                          _addNewComboComponent,
                        ),
                      ],

                      if (widget.item != null) ...[
                        SizedBox(height: 24),
                        Center(
                          child: TextButton.icon(
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              GlobalModal.show(
                                context: context,
                                child: ConfirmationSheet(
                                  title: t?.translate('delete_item') ?? 'Delete Item?',
                                  message: t?.translate('delete_item_confirm') ?? 'Are you sure you want to delete this item? This action cannot be undone.',
                                  confirmLabel: t?.translate('delete') ?? 'Delete',
                                  confirmColor: const Color(0xFFEF4444),
                                  onConfirm: () async {
                                    bool success = await _deleteItem();
                                    if (!context.mounted) return;
                                    if (success) {
                                      AppDialog.showToast(context, t?.translate('successfully_deleted') ?? 'Successfully Deleted');
                                      Navigator.of(context).pop(true);
                                    } else {
                                      AppDialog.showToast(context, t?.translate('failed_delete') ?? 'Failed to Delete', isError: true);
                                    }
                                  },
                                ),
                              );
                            },
                            icon: Icon(
                              Icons.delete_outline,
                              color: Color(0xFFEF4444),
                            ),
                            label: Text(
                              t?.translate('delete_menu_item') ?? 'Delete Menu Item',
                              style: GoogleFonts.poppins(
                                color: const Color(0xFFEF4444),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ],

                      SizedBox(height: 100), // Padding for bottom button
                    ],
                  ),
                ),
              ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
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
    HapticFeedback.lightImpact();
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

  Widget _buildSectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: GoogleFonts.poppins(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildPropertiesSection() {
    final t = AppLocalizations.of(context);
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        children: [
          _buildPropertySwitch(
            t?.translate('property_popular') ?? 'Popular',
            _isPopular,
            (v) => setState(() => _isPopular = v),
          ),
          Divider(height: 1, color: Theme.of(context).dividerColor),
          _buildPropertySwitch(
            t?.translate('property_recommended') ?? 'Recommended',
            _isRecommended,
            (v) => setState(() => _isRecommended = v),
          ),
          Divider(height: 1, color: Theme.of(context).dividerColor),
          _buildPropertySwitch(
            t?.translate('property_combo_set') ?? 'Combo Set',
            _isCombo,
            (v) => setState(() => _isCombo = v),
          ),
          Divider(height: 1, color: Theme.of(context).dividerColor),
          _buildPropertySwitch(
            t?.translate('property_vegetarian') ?? 'Vegetarian',
            _isVegetarian,
            (v) => setState(() => _isVegetarian = v),
          ),
          Divider(height: 1, color: Theme.of(context).dividerColor),
          _buildPropertySwitch(
            t?.translate('property_spicy') ?? 'Spicy',
            _isSpicy,
            (v) => setState(() => _isSpicy = v),
          ),
          Divider(height: 1, color: Theme.of(context).dividerColor),
          _buildPropertySwitch(
            t?.translate('property_hot_deal') ?? 'Hot Deal',
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
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          PrimaryGradientSwitch(
            value: value,
            onChanged: onChanged,
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

    final t = AppLocalizations.of(context);

    return Column(
      children: [
        _buildTextField(
          '${t?.translate('item_name') ?? 'Item Name'} ($_selectedItemInfoLang)',
          nameCtrl,
          hint: t?.translate('enter_item_name') ?? 'Enter Item Name',
          isRequired: _selectedItemInfoLang == 'EN',
          maxLength: 100,
        ),
        SizedBox(height: 16),
        _buildTextField(
          '${t?.translate('description') ?? 'Description'} ($_selectedItemInfoLang)',
          descCtrl,
          hint: t?.translate('enter_description') ?? 'Enter Description',
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
                color: isSelected ? null : Colors.white,
                gradient: isSelected ? AppColors.primaryGradient : null,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected
                      ? Colors.transparent
                      : Theme.of(context).dividerColor,
                ),
              ),
              child: Text(
                lang,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : (Theme.of(context).brightness == Brightness.dark ? const Color(0xFFCBD5E1) : const Color(0xFF64748B)),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }


  Widget _buildComboComponentCard(
    MenuComboComponentModel component,
    int index,
  ) {
    final t = AppLocalizations.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${t?.translate('component') ?? 'Component'} #${index + 1}',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.delete_outline,
                  color: Color(0xFFEF4444),
                  size: 20,
                ),
                onPressed: () => _removeComboComponent(index),
              ),
            ],
          ),
          _buildTextField(
            t?.translate('quantity') ?? 'Quantity',
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
          SizedBox(height: 16),
          _buildDropdownField<MenuItemModel>(
            label: t?.translate('included_item') ?? 'Included Item',
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
            hint: t?.translate('select_item') ?? 'Select an item...',
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
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            if (isRequired)
              const GradientText(
                ' *',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
        SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Theme.of(context).dividerColor),
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
      if (item is MenuItemModel) return item.displayName;
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
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            if (isRequired)
              const GradientText(
                ' *',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
        SizedBox(height: 8),
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
              SizedBox(width: 4),
              IconButton(
                icon: Icon(
                  Icons.close,
                  size: 18,
                  color: (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
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
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            if (isRequired)
              const GradientText(
                ' *',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
        SizedBox(height: 8),
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
              color: Theme.of(context).textTheme.bodyLarge?.color,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            hintText: hint,
            hintStyle: GoogleFonts.poppins(
              color: (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
              fontSize: 13,
            ),
            filled: true,
            fillColor: Theme.of(context).brightness == Brightness.dark ? Theme.of(context).cardColor : Colors.white,
            counterText: '', // Hide the counter for a cleaner look
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Theme.of(context).dividerColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Theme.of(context).dividerColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primary),
            ),
            suffixIcon: ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (context, value, child) {
                if (value.text.isEmpty) return const SizedBox.shrink();
                return IconButton(
                  icon: Icon(Icons.clear, color: (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)), size: 20),
                  onPressed: () {
                    controller.clear();
                    if (onChanged != null) onChanged('');
                  },
                );
              },
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
            const GradientText(
              ' *',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
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
            const GradientText(
              ' *',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
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
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: selected ? AppColors.primaryGradient : null,
          color: selected ? null : (Theme.of(context).brightness == Brightness.dark ? Colors.transparent : Colors.white),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? Colors.transparent : Theme.of(context).dividerColor,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected)
              Padding(
                padding: EdgeInsets.only(right: 6),
                child: Icon(Icons.check, color: Theme.of(context).cardColor, size: 14),
              ),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: selected ? Colors.white : (Theme.of(context).brightness == Brightness.dark ? const Color(0xFFCBD5E1) : const Color(0xFF64748B)),
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
        onPressed: () {
          HapticFeedback.lightImpact();
          onPressed();
        },
        style: OutlinedButton.styleFrom(
          backgroundColor: const Color(0xFFFEF2F2),
          side: BorderSide(color: Color(0xFFFEE2E2), width: 1.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (label.startsWith('+'))
              Padding(padding: EdgeInsets.only(right: 6)),
            GradientText(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    final t = AppLocalizations.of(context);
    return PrimaryGradientButton(
      onPressed: _isSaving ? null : _handleSave,
      isLoading: _isSaving,
      text: t?.translate('save') ?? 'Save',
      height: 56,
      borderRadius: 16,
    );
  }

  Widget _buildImageUploadSection() {
    final existingUrl = widget.item?.imageUrl;
    final hasNoImage = _pickedImage == null && (existingUrl == null || existingUrl.isEmpty);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasNoImage) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFECACA)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Color(0xFFEF4444), size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Food items with images attract more customers. Consider uploading a photo.',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: const Color(0xFFEF4444),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 12),
        ],
        GestureDetector(
      onTap: _pickImage,
      child: Container(
        width: double.infinity,
        height: 200,
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: _pickedImage == null && existingUrl == null
              ? Border.all(color: Theme.of(context).dividerColor, width: 1.5)
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: _pickedImage != null
              ? (kIsWeb
                  ? Image.network(_pickedImage!.path, fit: BoxFit.cover)
                  : Image.file(File(_pickedImage!.path), fit: BoxFit.cover))
              : (existingUrl != null && existingUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: existingUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) =>
                          Center(child: CustomLoadingIndicator(size: 24)),
                      errorWidget: (context, url, error) =>
                          Icon(Icons.error),
                    )
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const GradientWidget(
                            child: Icon(
                              Icons.camera_alt_outlined,
                              size: 32,
                            ),
                          ),
                          SizedBox(height: 12),
                          Text(
                            'Tap to upload',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).textTheme.bodyLarge?.color,
                            ),
                          ),
                        ],
                      ),
                    )),
        ),
      ),
    ),
    ],
  );
}

  Future<void> _pickImage() async {
    final result = await ImageUploadService().pickFromGallery();
    
    if (result.isTooLarge) {
      if (!mounted) return;
      AppDialog.showToast(context, 'Image size must be less than 1MB', isError: true);
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
        color: Theme.of(context).textTheme.bodyLarge?.color,
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

  void _showNoImageAlertBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color(0xFFFEF2F2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.image_not_supported_outlined,
                color: Color(0xFFEF4444),
                size: 32,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Missing Image',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Food items with images attract more customers. Consider uploading a photo for this item.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Theme.of(context).textTheme.bodySmall?.color,
                height: 1.5,
              ),
            ),
            SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: PrimaryGradientButton(
                onPressed: () {
                  Navigator.pop(context);
                  _pickImage();
                },
                text: 'Upload Image',
                height: 56,
                borderRadius: 16,
              ),
            ),
            SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  'Maybe Later',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
              ),
            ),
            SizedBox(height: 16),
          ],
        ),
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
