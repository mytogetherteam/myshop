import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:my_shop/core/presentation/widgets/custom_loading_indicator.dart';
import 'package:my_shop/core/data/services/image_upload_service.dart';
import 'package:my_shop/core/network/api_client.dart';
import '../../data/models/menu_item_model.dart';
import '../../data/models/menu_category_model.dart';
import '../../data/services/menu_service.dart';
import 'package:my_shop/core/presentation/widgets/skeleton.dart';
import 'package:my_shop/core/data/models/master_data_model.dart';

class AddNewItemScreen extends StatefulWidget {
  final MenuItemModel? item;

  const AddNewItemScreen({super.key, this.item});

  @override
  State<AddNewItemScreen> createState() => _AddNewItemScreenState();
}

class _AddNewItemScreenState extends State<AddNewItemScreen> {
  final MenuService _menuService = MenuService();
  final _formKey = GlobalKey<FormState>();
  
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
  
  String _currency = 'THB';
  
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

  // Image state
  XFile? _pickedImage;

  // Real state for dynamic variants and add-ons
  List<MenuItemVariantModel> _variants = [];
  List<MenuItemOptionGroupModel> _optionGroups = [];

  // UI States
  String _selectedItemInfoLang = 'EN';
  final Map<int, String> _variantLangs = {};
  final Map<int, String> _addonLangs = {};

  final List<String> _currencies = ['THB', 'USD', 'MMK'];

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _nameController = TextEditingController(text: item?.nameEn ?? '');
    _nameMmController = TextEditingController(text: item?.nameMm ?? '');
    _nameThController = TextEditingController(text: item?.nameTh ?? '');
    
    _descriptionController = TextEditingController(text: item?.descriptionEn ?? item?.description ?? '');
    _descriptionMmController = TextEditingController(text: item?.descriptionMm ?? '');
    _descriptionThController = TextEditingController(text: item?.descriptionTh ?? '');
    
    _priceController = TextEditingController(text: item?.price.toString() ?? '');
    _originalPriceController = TextEditingController(text: item?.originalPrice?.toString() ?? '');
    _stockQuantityController = TextEditingController(text: item?.stockQuantity?.toString() ?? '');
    _displayOrderController = TextEditingController(text: item?.displayOrder?.toString() ?? '0');
    _discountAmountController = TextEditingController(text: '0.00'); 
    _discountPercentController = TextEditingController(text: '0');
    
    if (item?.currency != null && item!.currency!.isNotEmpty) {
      if (_currencies.contains(item.currency)) {
         _currency = item.currency!;
      }
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
    }
    
    _fetchAllData();
  }

  Future<void> _fetchAllData() async {
    setState(() => _isLoadingData = true);
    try {
      final results = await Future.wait<dynamic>([
        _menuService.getCategories(),
        _menuService.getMasterCategories(),
        _menuService.getMasterMenuItems(),
        _menuService.getMenuTags(),
      ]);

      final categories = results[0] as List<MenuCategoryModel>?;
      final mCategories = results[1] as List<MasterDataModel>?;
      final mItems = results[2] as List<MasterDataModel>?;
      final tags = results[3] as List<MasterDataModel>?;

      if (mounted) {
        setState(() {
          _categories = categories ?? [];
          _masterCategories = mCategories ?? [];
          _masterItems = mItems ?? [];
          _menuTags = tags ?? [];

          final item = widget.item;
          if (item != null) {
            if (_categories.isNotEmpty) {
              try {
                _selectedCategory = _categories.firstWhere((c) => c.id == item.categoryId);
              } catch (_) {
                _selectedCategory = _categories.first;
              }
            }
            if (_masterCategories.isNotEmpty && item.masterCategoryId != null) {
              try {
                _selectedMasterCategory = _masterCategories.firstWhere((c) => c.id == item.masterCategoryId);
              } catch (_) {}
            }
            if (_masterItems.isNotEmpty && item.masterItemId != null) {
              try {
                _selectedMasterItem = _masterItems.firstWhere((i) => i.id == item.masterItemId);
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

  @override
  void dispose() {
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
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSaving = true);
    String? uploadedImageUrl;

    if (_pickedImage != null) {
      try {
        final formData = FormData.fromMap({
          'image': kIsWeb
            ? MultipartFile.fromBytes(await _pickedImage!.readAsBytes(), filename: _pickedImage!.name)
            : await MultipartFile.fromFile(_pickedImage!.path, filename: _pickedImage!.name),
        });
        
        final response = await ApiClient().dio.post('/api/menu/items/upload', data: formData);
        if (response.statusCode == 200 || response.statusCode == 201) {
          uploadedImageUrl = response.data['url'];
        }
      } catch (e) {
        debugPrint('Item image upload error: $e');
      }
    }

    final payload = {
      'nameEn': _nameController.text,
      'nameMm': _nameMmController.text,
      'nameTh': _nameThController.text,
      'descriptionEn': _descriptionController.text,
      'descriptionMm': _descriptionMmController.text,
      'descriptionTh': _descriptionThController.text,
      'price': double.tryParse(_priceController.text) ?? 0.0,
      'originalPrice': double.tryParse(_originalPriceController.text),
      'currency': _currency,
      'stockQuantity': int.tryParse(_stockQuantityController.text) ?? 0,
      'displayOrder': int.tryParse(_displayOrderController.text) ?? 0,
      'categoryId': _selectedCategory?.id,
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
      
      'imageUrl': uploadedImageUrl ?? widget.item?.imageUrl,
      'optionGroups': _optionGroups.map((o) => o.toJson()).toList(),
      'variants': _variants.map((v) => v.toJson()).toList(),
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item stored successfully'), backgroundColor: Color(0xFFED3A72)),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save item'), backgroundColor: Color(0xFFEF4444)),
        );
      }
    }
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
            'Edit Item',
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
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    _buildImageUploadSection(),
                    const SizedBox(height: 32),
                    
                    // Item Information Section
                    _buildSectionTitle('ITEM INFORMATION'),
                    const SizedBox(height: 16),
                    _buildMasterItemSelection(),
                    const SizedBox(height: 16),
                    _buildLanguagePills(
                      selectedLang: _selectedItemInfoLang,
                      onChanged: (val) => setState(() => _selectedItemInfoLang = val),
                    ),
                    const SizedBox(height: 16),
                    _buildItemInfoFields(),
                    const SizedBox(height: 16),
                    _buildDropdownField<MasterDataModel>(
                      label: 'Master Category',
                      value: _selectedMasterCategory,
                      items: _masterCategories,
                      hint: 'Search master categories...',
                      onChanged: (val) => setState(() => _selectedMasterCategory = val),
                    ),
                    const SizedBox(height: 16),
                    _buildDropdownField<MenuCategoryModel>(
                      label: 'Category',
                      value: _selectedCategory,
                      items: _categories,
                      hint: 'Search categories...',
                      onChanged: (val) => setState(() => _selectedCategory = val),
                      showClearIcon: true,
                      onClear: () => setState(() => _selectedCategory = null),
                    ),
                    const SizedBox(height: 32),
                    
                    // Categorization Section
                    _buildSectionTitle('CATEGORIZATION'),
                    const SizedBox(height: 16),
                    _buildMealTypesSelection(),
                    const SizedBox(height: 24),
                    _buildTagsSelection(),
                    const SizedBox(height: 32),

                    // Pricing & Stock Section
                    _buildSectionTitle('PRICING & STOCK'),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _buildTextField('Price', _priceController, hint: '0.00', keyboardType: TextInputType.number)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildDropdownFieldStr(
                          label: 'Currency',
                          value: _currency,
                          items: _currencies,
                          onChanged: (v) => setState(() => _currency = v ?? 'THB'),
                        )),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _buildTextField('Original Price', _originalPriceController, hint: '0.00', keyboardType: TextInputType.number)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildTextField('Stock Quantity', _stockQuantityController, hint: '100', keyboardType: TextInputType.number)),
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
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _buildTextField('Display Order', _displayOrderController, hint: '0', keyboardType: TextInputType.number)),
                        const SizedBox(width: 16),
                        const Spacer(),
                      ],
                    ),
                    const SizedBox(height: 32),
                    
                    // Properties Section
                    _buildSectionTitle('PROPERTIES'),
                    const SizedBox(height: 16),
                    _buildPropertiesSection(),
                    const SizedBox(height: 32),

                    // Variants Section
                    _buildSectionTitle('VARIANTS'),
                    const SizedBox(height: 16),
                    ..._variants.asMap().entries.map((entry) => _buildVariantCard(entry.value, entry.key)),
                    _buildOutlinedButton('+ Add Variant', _addNewVariant),
                    const SizedBox(height: 32),
                    
                    // Add On Section
                    _buildSectionTitle('ADD-ONS'),
                    const SizedBox(height: 16),
                    ..._optionGroups.asMap().entries.map((entry) => _buildOptionGroupCard(entry.value, entry.key)),
                    _buildOutlinedButton('+ Add Add-on', _addNewOptionGroup),
                    
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
      _variants.add(MenuItemVariantModel(
        id: 0,
        nameEn: '',
        price: 0.0,
        isAvailable: true,
        displayOrder: 0,
      ));
    });
  }

  void _addNewOptionGroup() {
    setState(() {
      _optionGroups.add(MenuItemOptionGroupModel(
        id: 0,
        nameEn: '',
        isRequired: false,
        minSelection: 0,
        maxSelection: 0,
        displayOrder: 0,
        options: [MenuItemOptionModel(id: 0, nameEn: '', price: 0.0, displayOrder: 0)],
      ));
    });
  }

  void _addNewOptionToGroup(int groupIndex) {
    setState(() {
      final opts = List<MenuItemOptionModel>.from(_optionGroups[groupIndex].options);
      opts.add(MenuItemOptionModel(id: 0, nameEn: '', price: 0.0, displayOrder: 0));
      _optionGroups[groupIndex] = MenuItemOptionGroupModel(
        id: _optionGroups[groupIndex].id,
        nameEn: _optionGroups[groupIndex].nameEn,
        nameMm: _optionGroups[groupIndex].nameMm,
        nameTh: _optionGroups[groupIndex].nameTh,
        isRequired: _optionGroups[groupIndex].isRequired,
        minSelection: _optionGroups[groupIndex].minSelection,
        maxSelection: _optionGroups[groupIndex].maxSelection,
        displayOrder: _optionGroups[groupIndex].displayOrder,
        options: opts,
      );
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

  Widget _buildMasterItemSelection() {
    return _buildDropdownField<MasterDataModel>(
      label: 'Master Item',
      value: _selectedMasterItem,
      items: _masterItems,
      hint: 'Search master items...',
      onChanged: (val) async {
        setState(() => _selectedMasterItem = val);
        if (val != null) {
          // Potentially fetch details to pre-fill
          final details = await _menuService.getMasterMenuItemDetail(val.id);
          if (details != null && mounted) {
             setState(() {
               _nameController.text = details.nameEn ?? _nameController.text;
               _nameMmController.text = details.nameMm ?? _nameMmController.text;
               _nameThController.text = details.nameTh ?? _nameThController.text;
               _descriptionController.text = details.descriptionEn ?? details.description ?? _descriptionController.text;
               _descriptionMmController.text = details.descriptionMm ?? _descriptionMmController.text;
               _descriptionThController.text = details.descriptionTh ?? _descriptionThController.text;
               _priceController.text = details.price.toString();
             });
          }
        }
      },
    );
  }

  Widget _buildPropertiesSection() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          _buildPropertySwitch('Available', _isAvailable, (v) => setState(() => _isAvailable = v)),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          _buildPropertySwitch('Popular', _isPopular, (v) => setState(() => _isPopular = v)),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          _buildPropertySwitch('Recommended', _isRecommended, (v) => setState(() => _isRecommended = v)),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          _buildPropertySwitch('Combo Set', _isCombo, (v) => setState(() => _isCombo = v)),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          _buildPropertySwitch('Vegetarian', _isVegetarian, (v) => setState(() => _isVegetarian = v)),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          _buildPropertySwitch('Spicy', _isSpicy, (v) => setState(() => _isSpicy = v)),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          _buildPropertySwitch('Hot Deal', _isHotDeal, (v) => setState(() => _isHotDeal = v)),
        ],
      ),
    );
  }

  Widget _buildPropertySwitch(String label, bool value, ValueChanged<bool> onChanged) {
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
            activeColor: const Color(0xFFED3A72),
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
        _buildTextField('Item Name ($_selectedItemInfoLang)', nameCtrl, hint: 'Enter item name'),
        const SizedBox(height: 16),
        _buildTextField('Description ($_selectedItemInfoLang)', descCtrl, hint: 'Enter description', isMultiline: true),
      ],
    );
  }

  Widget _buildLanguagePills({required String selectedLang, required ValueChanged<String> onChanged}) {
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
                  color: isSelected ? Colors.transparent : const Color(0xFFE2E8F0),
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
    
    final nameCtrl = TextEditingController(
      text: lang == 'MM' ? variant.nameMm : (lang == 'TH' ? variant.nameTh : variant.nameEn)
    );
    final priceCtrl = TextEditingController(text: variant.price.toString());

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
                Text('Variant #${index + 1}', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B))),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444), size: 20),
                  onPressed: () => setState(() => _variants.removeAt(index)),
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
                  onChanged: (val) => setState(() => _variantLangs[index] = val),
                ),
                const SizedBox(height: 16),
                _buildTextField('Variant Name ($lang)', nameCtrl, onChanged: (v) {
                  _variants[index] = MenuItemVariantModel(
                    id: variant.id, price: variant.price,
                    nameEn: lang == 'EN' ? v : variant.nameEn,
                    nameMm: lang == 'MM' ? v : variant.nameMm,
                    nameTh: lang == 'TH' ? v : variant.nameTh,
                    isAvailable: variant.isAvailable,
                    displayOrder: variant.displayOrder,
                  );
                }),
                const SizedBox(height: 16),
                _buildTextField('Price', priceCtrl, keyboardType: TextInputType.number, onChanged: (v) {
                  _variants[index] = MenuItemVariantModel(
                    id: variant.id, price: double.tryParse(v) ?? 0.0,
                    nameEn: variant.nameEn, nameMm: variant.nameMm, nameTh: variant.nameTh,
                    isAvailable: variant.isAvailable,
                    displayOrder: variant.displayOrder,
                  );
                }),
                const SizedBox(height: 16),
                _buildTextField('Display Order', TextEditingController(text: variant.displayOrder?.toString() ?? '0'), keyboardType: TextInputType.number, onChanged: (v) {
                  _variants[index] = MenuItemVariantModel(
                    id: variant.id, price: variant.price,
                    nameEn: variant.nameEn, nameMm: variant.nameMm, nameTh: variant.nameTh,
                    isAvailable: variant.isAvailable,
                    displayOrder: int.tryParse(v) ?? 0,
                  );
                }),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text('Available', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B))),
                    const Spacer(),
                    Switch(
                      value: variant.isAvailable,
                      onChanged: (v) {
                        setState(() {
                          _variants[index] = MenuItemVariantModel(
                            id: variant.id, price: variant.price,
                            nameEn: variant.nameEn, nameMm: variant.nameMm, nameTh: variant.nameTh,
                            isAvailable: v, displayOrder: variant.displayOrder,
                          );
                        });
                      },
                      activeColor: const Color(0xFFED3A72),
                    ),
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildOptionGroupCard(MenuItemOptionGroupModel group, int index) {
    final lang = _addonLangs[index] ?? 'EN';
    
    final groupNameCtrl = TextEditingController(
      text: lang == 'MM' ? group.nameMm : (lang == 'TH' ? group.nameTh : group.nameEn)
    );

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
                Text('Add-on: ${group.displayName.isEmpty ? "New Add-on" : group.displayName}', 
                  style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B))),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444), size: 20),
                  onPressed: () => setState(() => _optionGroups.removeAt(index)),
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
                _buildTextField('Add-on Name ($lang)', groupNameCtrl, onChanged: (v) {
                  _optionGroups[index] = MenuItemOptionGroupModel(
                    id: group.id,
                    nameEn: lang == 'EN' ? v : group.nameEn,
                    nameMm: lang == 'MM' ? v : group.nameMm,
                    nameTh: lang == 'TH' ? v : group.nameTh,
                    isRequired: group.isRequired,
                    minSelection: group.minSelection,
                    maxSelection: group.maxSelection,
                    displayOrder: group.displayOrder,
                    options: group.options,
                  );
                }),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField('Min Selection', TextEditingController(text: group.minSelection?.toString() ?? '0'), keyboardType: TextInputType.number, onChanged: (v) {
                        _optionGroups[index] = MenuItemOptionGroupModel(
                          id: group.id, nameEn: group.nameEn, nameMm: group.nameMm, nameTh: group.nameTh,
                          isRequired: group.isRequired, minSelection: int.tryParse(v) ?? 0,
                          maxSelection: group.maxSelection, displayOrder: group.displayOrder, options: group.options,
                        );
                      }),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTextField('Max Selection', TextEditingController(text: group.maxSelection?.toString() ?? '0'), keyboardType: TextInputType.number, onChanged: (v) {
                        _optionGroups[index] = MenuItemOptionGroupModel(
                          id: group.id, nameEn: group.nameEn, nameMm: group.nameMm, nameTh: group.nameTh,
                          isRequired: group.isRequired, minSelection: group.minSelection,
                          maxSelection: int.tryParse(v) ?? 0, displayOrder: group.displayOrder, options: group.options,
                        );
                      }),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField('Display Order', TextEditingController(text: group.displayOrder?.toString() ?? '0'), keyboardType: TextInputType.number, onChanged: (v) {
                        _optionGroups[index] = MenuItemOptionGroupModel(
                          id: group.id, nameEn: group.nameEn, nameMm: group.nameMm, nameTh: group.nameTh,
                          isRequired: group.isRequired, minSelection: group.minSelection,
                          maxSelection: group.maxSelection, displayOrder: int.tryParse(v) ?? 0, options: group.options,
                        );
                      }),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Required', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B))),
                          const SizedBox(height: 4),
                          Switch(
                            value: group.isRequired,
                            onChanged: (v) {
                              setState(() {
                                _optionGroups[index] = MenuItemOptionGroupModel(
                                  id: group.id, nameEn: group.nameEn, nameMm: group.nameMm, nameTh: group.nameTh,
                                  isRequired: v, minSelection: group.minSelection,
                                  maxSelection: group.maxSelection, displayOrder: group.displayOrder, options: group.options,
                                );
                              });
                            },
                            activeColor: const Color(0xFFED3A72),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const SizedBox(height: 16),
                ...group.options.asMap().entries.map((optEntry) {
                   final opt = optEntry.value;
                   final oIndex = optEntry.key;
                   
                   final optNameCtrl = TextEditingController(
                     text: lang == 'MM' ? opt.nameMm : (lang == 'TH' ? opt.nameTh : opt.nameEn)
                   );
                   final optPriceCtrl = TextEditingController(text: opt.price.toString());
                   return Column(
                     children: [
                       if (oIndex > 0) const Divider(height: 24, color: Color(0xFFE2E8F0)),
                       if (group.options.length > 1) 
                         _buildTextField('Option Name ($lang)', optNameCtrl, onChanged: (v) {
                            final newOpts = List<MenuItemOptionModel>.from(group.options);
                            newOpts[oIndex] = MenuItemOptionModel(
                              id: opt.id, price: opt.price,
                              nameEn: lang == 'EN' ? v : opt.nameEn,
                              nameMm: lang == 'MM' ? v : opt.nameMm,
                              nameTh: lang == 'TH' ? v : opt.nameTh,
                            );
                             _optionGroups[index] = MenuItemOptionGroupModel(
                               id: group.id, nameEn: group.nameEn, nameMm: group.nameMm, nameTh: group.nameTh,
                               isRequired: group.isRequired, minSelection: group.minSelection,
                               maxSelection: group.maxSelection, displayOrder: group.displayOrder,
                               options: newOpts,
                             );
                         }),
                       if (group.options.length > 1) const SizedBox(height: 16),
                        _buildTextField('Price', optPriceCtrl, keyboardType: TextInputType.number, onChanged: (v) {
                           final newOpts = List<MenuItemOptionModel>.from(group.options);
                           newOpts[oIndex] = MenuItemOptionModel(
                             id: opt.id, price: double.tryParse(v) ?? 0.0,
                             nameEn: opt.nameEn, nameMm: opt.nameMm, nameTh: opt.nameTh,
                             displayOrder: opt.displayOrder, linkedMenuItemId: opt.linkedMenuItemId,
                           );
                           _optionGroups[index] = MenuItemOptionGroupModel(
                             id: group.id, nameEn: group.nameEn, nameMm: group.nameMm, nameTh: group.nameTh,
                             isRequired: group.isRequired, minSelection: group.minSelection,
                             maxSelection: group.maxSelection, displayOrder: group.displayOrder,
                             options: newOpts,
                           );
                        }),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField('Display Order', TextEditingController(text: opt.displayOrder?.toString() ?? '0'), keyboardType: TextInputType.number, onChanged: (v) {
                                final newOpts = List<MenuItemOptionModel>.from(group.options);
                                newOpts[oIndex] = MenuItemOptionModel(
                                  id: opt.id, price: opt.price, nameEn: opt.nameEn, nameMm: opt.nameMm, nameTh: opt.nameTh,
                                  displayOrder: int.tryParse(v) ?? 0, linkedMenuItemId: opt.linkedMenuItemId,
                                );
                                _optionGroups[index] = MenuItemOptionGroupModel(
                                  id: group.id, nameEn: group.nameEn, nameMm: group.nameMm, nameTh: group.nameTh,
                                  isRequired: group.isRequired, minSelection: group.minSelection,
                                  maxSelection: group.maxSelection, displayOrder: group.displayOrder, options: newOpts,
                                );
                              }),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildTextField('Linked Item ID', TextEditingController(text: opt.linkedMenuItemId?.toString() ?? ''), keyboardType: TextInputType.number, onChanged: (v) {
                                final newOpts = List<MenuItemOptionModel>.from(group.options);
                                newOpts[oIndex] = MenuItemOptionModel(
                                  id: opt.id, price: opt.price, nameEn: opt.nameEn, nameMm: opt.nameMm, nameTh: opt.nameTh,
                                  displayOrder: opt.displayOrder, linkedMenuItemId: int.tryParse(v),
                                );
                                _optionGroups[index] = MenuItemOptionGroupModel(
                                  id: group.id, nameEn: group.nameEn, nameMm: group.nameMm, nameTh: group.nameTh,
                                  isRequired: group.isRequired, minSelection: group.minSelection,
                                  maxSelection: group.maxSelection, displayOrder: group.displayOrder, options: newOpts,
                                );
                              }),
                            ),
                          ],
                        ),
                     ],
                   );
                }).toList(),
                const SizedBox(height: 16),
                const Divider(height: 24, color: Color(0xFFFEE2E2)), 
                _buildOutlinedButton('+ Add Item', () => _addNewOptionToGroup(index)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildDropdownFieldStr({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B)),
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
              items: items.map((item) => DropdownMenuItem(value: item, child: Text(item, style: GoogleFonts.poppins(fontSize: 14)))).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField<T>({
    required String label,
    required T? value,
    required List<T> items,
    required String hint,
    required ValueChanged<T?> onChanged,
    bool showClearIcon = false,
    VoidCallback? onClear,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B)),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<T>(
                    value: value,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF94A3B8)),
                    hint: Text(hint, style: GoogleFonts.poppins(color: const Color(0xFF94A3B8), fontSize: 13)),
                    items: items.map((item) {
                      String name = '';
                      if (item is MasterDataModel) name = item.displayName;
                      if (item is MenuCategoryModel) name = item.displayName;
                      return DropdownMenuItem<T>(
                        value: item,
                        child: Text(name, style: GoogleFonts.poppins(fontSize: 14)),
                      );
                    }).toList(),
                    onChanged: onChanged,
                  ),
                ),
              ),
              if (showClearIcon && value != null)
                IconButton(
                  icon: const Icon(Icons.close, size: 18, color: Color(0xFF94A3B8)),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: onClear,
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {String? hint, bool isMultiline = false, TextInputType? keyboardType, ValueChanged<String>? onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: isMultiline ? 4 : 1,
          keyboardType: keyboardType,
          onChanged: onChanged,
          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.poppins(color: const Color(0xFF94A3B8), fontSize: 13),
            filled: true,
            fillColor: Colors.white,
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
          validator: (value) {
            return null; 
          },
        ),
      ],
    );
  }

  Widget _buildTagsSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('Discovery Tags'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 10,
          children: [
            _buildCustomChip(label: 'Best Seller', selected: _isPopular, onTap: () => setState(() => _isPopular = !_isPopular)),
            _buildCustomChip(label: 'Vegetarian', selected: _isVegetarian, onTap: () => setState(() => _isVegetarian = !_isVegetarian)),
            _buildCustomChip(label: 'Spicy', selected: _isSpicy, onTap: () => setState(() => _isSpicy = !_isSpicy)),
            _buildCustomChip(label: 'Combo', selected: _isCombo, onTap: () => setState(() => _isCombo = !_isCombo)),
            _buildCustomChip(label: 'Recommended', selected: _isRecommended, onTap: () => setState(() => _isRecommended = !_isRecommended)),
            _buildCustomChip(label: 'Hot Deal', selected: _isHotDeal, onTap: () => setState(() => _isHotDeal = !_isHotDeal)),
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
            }).toList(),
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
        _buildSectionLabel('Meal Types'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 10,
          children: _mealTypeOptions.map((type) {
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
          }).toList() + [
            _buildCustomChip(label: 'Other', selected: false, onTap: () {}),
          ],
        ),
      ],
    );
  }

  Widget _buildCustomChip({required String label, required bool selected, required VoidCallback onTap}) {
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (label.startsWith('+')) const Padding(
              padding: EdgeInsets.only(right: 6),
            ),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        child: _isSaving 
          ? const CustomLoadingIndicator(size: 24, color: Colors.white)
          : Text(
              'Update Item',
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
                  placeholder: (context, url) => const Center(child: CustomLoadingIndicator(size: 24)),
                  errorWidget: (context, url, error) => const Icon(Icons.error),
                )
              else
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.camera_alt_outlined, color: Color(0xFFED3973), size: 32),
                      const SizedBox(height: 12),
                      Text('Tap to upload', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B))),
                    ],
                  ),
                ),
              if (_pickedImage != null || (existingUrl != null && existingUrl.isNotEmpty))
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                    ),
                    child: const Icon(Icons.refresh_rounded, size: 20, color: Color(0xFFED3973)),
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
