// ignore_for_file: use_build_context_synchronously
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:my_shop/core/data/services/image_upload_service.dart';
import 'package:my_shop/core/presentation/widgets/custom_loading_indicator.dart';
import 'package:my_shop/core/presentation/widgets/fullscreen_image_viewer.dart';
import 'package:my_shop/core/presentation/widgets/custom_search_dropdown.dart';
import 'package:my_shop/features/profile/data/models/shop_profile_model.dart';
import 'package:my_shop/features/profile/data/services/profile_service.dart';
import 'package:my_shop/core/data/models/master_data_model.dart';
import 'package:my_shop/core/data/services/master_data_service.dart';


class EditShopProfilePage extends StatefulWidget {
  final ShopProfileModel? shopProfile;
  const EditShopProfilePage({super.key, this.shopProfile});

  @override
  State<EditShopProfilePage> createState() => _EditShopProfilePageState();
}

class _EditShopProfilePageState extends State<EditShopProfilePage> {
  bool _hasChanges = false;
  bool _isSaving = false;
  bool _isLoading = false;
  ShopProfileModel? _currentProfile;

  final _scrollController = ScrollController();

  // GlobalKeys for scroll-to-error
  final _nameKey = GlobalKey();
  final _categoryKey = GlobalKey();
  final _subCategoryKey = GlobalKey();
  final _cuisineTypeKey = GlobalKey();
  final _phoneKey = GlobalKey();
  final _addressKey = GlobalKey();
  final _baseFeeKey = GlobalKey();

  List<MasterDataModel> _categories = [];
  List<MasterDataModel> _subcategories = [];
  List<MasterDataModel> _cities = [];

  MasterDataModel? _selectedCategory;
  MasterDataModel? _selectedSubcategory;
  MasterDataModel? _selectedCity;

  List<MasterDataModel> _cuisineTypes = [];
  List<MasterDataModel> _selectedCuisineTypes = [];

  List<MasterDataModel> _districts = [];
  MasterDataModel? _selectedDistrict;

  final MasterDataService _masterDataService = MasterDataService();

  XFile? _pickedCover;
  XFile? _pickedLogo;

  String _nameLang = 'EN';
  String _descLang = 'EN';
  String _addressLang = 'EN';

  late final TextEditingController _nameEnCtrl;
  late final TextEditingController _nameMmCtrl;
  late final TextEditingController _nameThCtrl;
  late final TextEditingController _descEnCtrl;
  late final TextEditingController _descMmCtrl;
  late final TextEditingController _descThCtrl;
  List<TextEditingController> _phoneControllers = [];
  late final TextEditingController _emailCtrl;
  late final TextEditingController _addressEnCtrl;
  late final TextEditingController _addressMmCtrl;
  late final TextEditingController _addressThCtrl;
  late final TextEditingController _districtCtrl;
  late final TextEditingController _cityCtrl;

  late final TextEditingController _catEnCtrl;
  late final TextEditingController _catMmCtrl;
  late final TextEditingController _catThCtrl;
  late final TextEditingController _subCatEnCtrl;
  late final TextEditingController _subCatMmCtrl;
  late final TextEditingController _subCatThCtrl;

  // New Controllers
  late final TextEditingController _maxQtyCtrl;
  late final TextEditingController _minAmountCtrl;
  late final TextEditingController _baseFeeCtrl;
  late final TextEditingController _mapsLinkCtrl;

  double? _latitude;
  double? _longitude;

  late bool _hasParking;
  late bool _hasWifi;
  late bool _hasDelivery;
  late bool _isHalal;
  late bool _isVegetarian;
  late bool _deliveryEnabled;
  late int _priceRange;

  Future<void> _fetchMasterData() async {
    final futures = await Future.wait([
      _masterDataService.getShopCategories(),
      _masterDataService.getShopSubcategories(),
      _masterDataService.getCities(),
      _masterDataService.getCuisineTypes(),
    ]);

    if (mounted) {
      setState(() {
        _categories = futures[0] ?? [];
        _subcategories = futures[1] ?? [];
        _cities = futures[2] ?? [];
        _cuisineTypes = futures[3] ?? [];
        _setSelectedMasterData();
      });
    }
  }

  void _setSelectedMasterData() {
    if (_currentProfile == null) return;

    try {
      if (_currentProfile!.categoryId != null) {
        _selectedCategory = _categories.firstWhere(
          (c) => c.id == _currentProfile!.categoryId,
        );
      } else if (_currentProfile!.categoryEn != null) {
        _selectedCategory = _categories.firstWhere(
          (c) => c.nameEn == _currentProfile!.categoryEn,
        );
      }
    } catch (_) {}

    try {
      if (_currentProfile!.subCategoryId != null) {
        _selectedSubcategory = _subcategories.firstWhere(
          (c) => c.id == _currentProfile!.subCategoryId,
        );
      } else if (_currentProfile!.subCategoryEn != null) {
        _selectedSubcategory = _subcategories.firstWhere(
          (c) => c.nameEn == _currentProfile!.subCategoryEn,
        );
      }
    } catch (_) {}

    try {
      if (_currentProfile!.cityEn != null &&
          _currentProfile!.cityEn!.isNotEmpty) {
        _selectedCity = _cities.firstWhere(
          (c) => c.nameEn == _currentProfile!.cityEn,
        );
        if (_selectedCity != null) {
          _fetchDistricts(_selectedCity!.id);
        }
      }
    } catch (_) {}

    try {
      if (_currentProfile!.cuisineTypeIds.isNotEmpty) {
        _selectedCuisineTypes = _cuisineTypes
            .where((c) => _currentProfile!.cuisineTypeIds.contains(c.id))
            .toList();
      }
    } catch (_) {}
  }

  Future<void> _fetchDistricts(int cityId) async {
    final fetched = await _masterDataService.getDistricts(cityId);
    if (mounted) {
      setState(() {
        _districts = fetched ?? [];
        if (_currentProfile?.districtEn != null &&
            _currentProfile!.districtEn!.isNotEmpty) {
          try {
            _selectedDistrict = _districts.firstWhere(
              (d) => d.nameEn == _currentProfile!.districtEn,
            );
          } catch (_) {}
        }
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _currentProfile = widget.shopProfile;
    _initializeFields(_currentProfile);

    _fetchMasterData();

    if (_currentProfile == null) {
      _loadProfile();
    }
  }

  void _initializeFields(ShopProfileModel? p) {
    _nameEnCtrl = TextEditingController(text: p?.nameEn ?? '');
    _nameMmCtrl = TextEditingController(text: p?.nameMm ?? '');
    _nameThCtrl = TextEditingController(text: p?.nameTh ?? '');
    _descEnCtrl = TextEditingController(text: p?.descriptionEn ?? '');
    _descMmCtrl = TextEditingController(text: p?.descriptionMm ?? '');
    _descThCtrl = TextEditingController(text: p?.descriptionTh ?? '');
    
    final phoneString = p?.phone ?? '';
    final phones = phoneString.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    if (phones.isEmpty) {
      _phoneControllers = [TextEditingController()];
    } else {
      _phoneControllers = phones.map((ph) => TextEditingController(text: ph)).toList();
    }

    _emailCtrl = TextEditingController(text: p?.email ?? '');
    _addressEnCtrl = TextEditingController(text: p?.addressEn ?? '');
    _addressMmCtrl = TextEditingController(text: p?.addressMm ?? '');
    _addressThCtrl = TextEditingController(text: p?.addressTh ?? '');
    _districtCtrl = TextEditingController(text: p?.districtEn ?? '');
    _cityCtrl = TextEditingController(text: p?.cityEn ?? '');

    _catEnCtrl = TextEditingController(text: p?.categoryEn ?? '');
    _catMmCtrl = TextEditingController(text: p?.categoryMm ?? '');
    _catThCtrl = TextEditingController(text: p?.categoryTh ?? '');
    _subCatEnCtrl = TextEditingController(text: p?.subCategoryEn ?? '');
    _subCatMmCtrl = TextEditingController(text: p?.subCategoryMm ?? '');
    _subCatThCtrl = TextEditingController(text: p?.subCategoryTh ?? '');

    _maxQtyCtrl = TextEditingController(
      text: (p?.maxItemQuantityPerOrder ?? 10).toString(),
    );
    _minAmountCtrl = TextEditingController(
      text: (p?.minOrderAmount ?? 0.0).toString(),
    );
    _baseFeeCtrl = TextEditingController(
      text: (p?.baseDeliveryFee ?? 0.0).toString(),
    );
    _mapsLinkCtrl = TextEditingController(text: p?.googleMapsLink ?? '');

    _latitude = p?.latitude;
    _longitude = p?.longitude;

    _hasParking = p?.hasParking ?? false;
    _hasWifi = p?.hasWifi ?? false;
    _hasDelivery = p?.hasDelivery ?? false;
    _isHalal = p?.isHalal ?? false;
    _isVegetarian = p?.isVegetarian ?? false;
    _deliveryEnabled = p?.deliveryEnabled ?? false;

    _priceRange = 1;
    if (p?.pricePreference == 'LOW') {
      _priceRange = 0;
    }
    if (p?.pricePreference == 'HIGH') {
      _priceRange = 2;
    }
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final profile = await ProfileService().getShopProfile();
      if (profile != null && mounted) {
        setState(() {
          _currentProfile = profile;
          _updateControllerTexts(profile);
          _setSelectedMasterData();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _updateControllerTexts(ShopProfileModel p) {
    _nameEnCtrl.text = p.nameEn ?? '';
    _nameMmCtrl.text = p.nameMm ?? '';
    _nameThCtrl.text = p.nameTh ?? '';
    _descEnCtrl.text = p.descriptionEn ?? '';
    _descMmCtrl.text = p.descriptionMm ?? '';
    _descThCtrl.text = p.descriptionTh ?? '';

    for (var c in _phoneControllers) {
      c.dispose();
    }
    final phones = (p.phone ?? '').split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    if (phones.isEmpty) {
      _phoneControllers = [TextEditingController()];
    } else {
      _phoneControllers = phones.map((ph) => TextEditingController(text: ph)).toList();
    }

    _emailCtrl.text = p.email ?? '';
    _addressEnCtrl.text = p.addressEn ?? '';
    _addressMmCtrl.text = p.addressMm ?? '';
    _addressThCtrl.text = p.addressTh ?? '';
    _districtCtrl.text = p.districtEn ?? '';
    _cityCtrl.text = p.cityEn ?? '';
    _catEnCtrl.text = p.categoryEn ?? '';
    _catMmCtrl.text = p.categoryMm ?? '';
    _catThCtrl.text = p.categoryTh ?? '';
    _subCatEnCtrl.text = p.subCategoryEn ?? '';
    _subCatMmCtrl.text = p.subCategoryMm ?? '';
    _subCatThCtrl.text = p.subCategoryTh ?? '';
    _maxQtyCtrl.text = p.maxItemQuantityPerOrder.toString();
    _minAmountCtrl.text = p.minOrderAmount.toString();
    _baseFeeCtrl.text = p.baseDeliveryFee.toString();
    _mapsLinkCtrl.text = p.googleMapsLink ?? '';

    _latitude = p.latitude;
    _longitude = p.longitude;
    _hasParking = p.hasParking;
    _hasWifi = p.hasWifi;
    _hasDelivery = p.hasDelivery;
    _isHalal = p.isHalal;
    _isVegetarian = p.isVegetarian;
    _deliveryEnabled = p.deliveryEnabled;

    if (p.pricePreference == 'LOW') {
      _priceRange = 0;
    } else if (p.pricePreference == 'HIGH') {
      _priceRange = 2;
    } else {
      _priceRange = 1;
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    for (final c in [
      _nameEnCtrl,
      _nameMmCtrl,
      _nameThCtrl,
      _descEnCtrl,
      _descMmCtrl,
      _descThCtrl,
      _emailCtrl,
      _addressEnCtrl,
      _addressMmCtrl,
      _addressThCtrl,
      _districtCtrl,
      _cityCtrl,
      _maxQtyCtrl,
      _minAmountCtrl,
      _baseFeeCtrl,
      _mapsLinkCtrl,
    ]) {
      c.dispose();
    }
    for (final c in _phoneControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _markChanged() {
    if (!_hasChanges) setState(() => _hasChanges = true);
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Discard changes?',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        content: Text(
          'You have unsaved changes. Do you want to discard them?',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: const Color(0xFF475569),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Continue Editing',
              style: GoogleFonts.poppins(
                color: const Color(0xFF475569),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Discard',
              style: GoogleFonts.poppins(
                color: const Color(0xFFED3973),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _scrollToKey(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        alignment: 0.1,
      );
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFEF4444),
      ),
    );
  }

  bool _validate() {
    if (_nameEnCtrl.text.trim().isEmpty) {
      _scrollToKey(_nameKey);
      _showError('Shop Name (EN) is required');
      return false;
    }
    if (_selectedCategory == null) {
      _scrollToKey(_categoryKey);
      _showError('Category is required');
      return false;
    }
    if (_selectedSubcategory == null) {
      _scrollToKey(_subCategoryKey);
      _showError('Sub-category is required');
      return false;
    }
    if (_selectedCuisineTypes.isEmpty) {
      _scrollToKey(_cuisineTypeKey);
      _showError('At least one Cuisine Type is required');
      return false;
    }
    final validPhones = _phoneControllers.where((c) => c.text.trim().isNotEmpty).toList();
    if (validPhones.isEmpty) {
      _scrollToKey(_phoneKey);
      _showError('At least one Phone Number is required');
      return false;
    }
    if (_addressEnCtrl.text.trim().isEmpty) {
      // Switch to EN tab if not already on it so the user sees the empty field
      if (_addressLang != 'EN') setState(() => _addressLang = 'EN');
      _scrollToKey(_addressKey);
      _showError('Street Address (EN) is required');
      return false;
    }
    final baseFee = double.tryParse(_baseFeeCtrl.text.trim());
    if (baseFee == null || baseFee < 0) {
      _scrollToKey(_baseFeeKey);
      _showError('Base Delivery Fee must be a valid non-negative number');
      return false;
    }
    if (baseFee > 999999.9) {
      _scrollToKey(_baseFeeKey);
      _showError('Price too large');
      return false;
    }

    final minAmount = double.tryParse(_minAmountCtrl.text.trim());
    if (minAmount != null && minAmount > 999999.9) {
      _showError('Minimum Order Amount is too large');
      return false;
    }
    return true;
  }

  Future<void> _save() async {
    if (!_validate()) return;
    setState(() => _isSaving = true);

    final payload = {
      'nameEn': _nameEnCtrl.text,
      'nameMm': _nameMmCtrl.text,
      'nameTh': _nameThCtrl.text,
      'descriptionEn': _descEnCtrl.text,
      'descriptionMm': _descMmCtrl.text,
      'descriptionTh': _descThCtrl.text,
      'phone': _phoneControllers.map((c) => c.text.trim()).where((t) => t.isNotEmpty).join(','),
      'email': _emailCtrl.text,
      'addressEn': _addressEnCtrl.text,
      'addressMm': _addressMmCtrl.text,
      'addressTh': _addressThCtrl.text,
      'districtId': _selectedDistrict?.id,
      'districtEn': _selectedDistrict?.nameEn ?? _districtCtrl.text,
      'districtMm': _selectedDistrict?.nameMm ?? _districtCtrl.text,
      'districtTh': _selectedDistrict?.nameTh ?? _districtCtrl.text,
      'categoryId': _selectedCategory?.id,
      'categoryEn': _selectedCategory?.nameEn ?? _catEnCtrl.text,
      'categoryMm': _selectedCategory?.nameMm ?? _catMmCtrl.text,
      'categoryTh': _selectedCategory?.nameTh ?? _catThCtrl.text,
      'subCategoryId': _selectedSubcategory?.id,
      'subCategoryEn': _selectedSubcategory?.nameEn ?? _subCatEnCtrl.text,
      'subCategoryMm': _selectedSubcategory?.nameMm ?? _subCatMmCtrl.text,
      'subCategoryTh': _selectedSubcategory?.nameTh ?? _subCatThCtrl.text,
      'cuisineTypeIds': _selectedCuisineTypes.map((c) => c.id).toList(),
      'cityEn': _selectedCity?.nameEn ?? _cityCtrl.text,
      'cityMm': _selectedCity?.nameMm ?? _cityCtrl.text,
      'cityTh': _selectedCity?.nameTh ?? _cityCtrl.text,
      'latitude': _latitude ?? 16.8409,
      'longitude': _longitude ?? 96.1735,
      'hasParking': _hasParking,
      'hasWifi': _hasWifi,
      'hasDelivery': _hasDelivery,
      'isHalal': _isHalal,
      'isVegetarian': _isVegetarian,
      'pricePreference': _priceRange == 0
          ? 'LOW'
          : (_priceRange == 1 ? 'MEDIUM' : 'HIGH'),
      'maxItemQuantityPerOrder': int.tryParse(_maxQtyCtrl.text) ?? 10,
      'minOrderAmount': double.tryParse(_minAmountCtrl.text) ?? 0.0,
      'baseDeliveryFee': double.tryParse(_baseFeeCtrl.text) ?? 0.0,
      'deliveryEnabled': _deliveryEnabled,
      'googleMapsLink': _mapsLinkCtrl.text,
      'cityId': _selectedCity?.id,
      'logoUrl': _currentProfile?.logoUrl,
      'coverUrl': _currentProfile?.coverUrl,
    };

    if (_pickedCover != null) {
      payload['coverPhoto'] = kIsWeb
          ? MultipartFile.fromBytes(
              await _pickedCover!.readAsBytes(),
              filename: _pickedCover!.name,
            )
          : await MultipartFile.fromFile(
              _pickedCover!.path,
              filename: _pickedCover!.name,
            );
    }

    if (_pickedLogo != null) {
      payload['logoPhoto'] = kIsWeb
          ? MultipartFile.fromBytes(
              await _pickedLogo!.readAsBytes(),
              filename: _pickedLogo!.name,
            )
          : await MultipartFile.fromFile(
              _pickedLogo!.path,
              filename: _pickedLogo!.name,
            );
    }

    final success = await ProfileService().updateShopProfile(payload);

    if (!context.mounted) return;

    if (success) {
      setState(() {
        _hasChanges = false;
        _isSaving = false;
        _pickedCover = null;
        _pickedLogo = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile saved successfully!'),
          backgroundColor: Color(0xFFED3A72),
        ),
      );
      Navigator.pop(context, true);
    } else {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to save profile. Please try again.'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
    }
  }

  Widget _buildDropdown(
    String label,
    MasterDataModel? value,
    List<MasterDataModel> items,
    String hint,
    ValueChanged<MasterDataModel?> onChanged,
  ) {
    final List<MasterDataModel> safeItems = List.from(items);
    if (value != null && !safeItems.contains(value)) {
      safeItems.add(value);
    }

    if (safeItems.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<MasterDataModel>(
            value: null,
            isExpanded: true,
            hint: Text(
              hint,
              style: GoogleFonts.poppins(
                color: const Color(0xFF94A3B8),
                fontSize: 13,
              ),
            ),
            items: [
              DropdownMenuItem<MasterDataModel>(
                value: null,
                enabled: false,
                child: Text(
                  'No data found',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
              ),
            ],
            onChanged: null,
          ),
        ),
      );
    }

    return CustomSearchDropdown<MasterDataModel>(
      items: safeItems,
      value: value,
      hintText: hint,
      searchHintText: 'Search...',
      itemLabelBuilder: (item) => item.displayName,
      onChanged: onChanged,
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: Text(
            'Edit Profile',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF1E293B),
          elevation: 0,
        ),
        body: const Center(child: CustomLoadingIndicator()),
      );
    }

    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final should = await _onWillPop();
        if (should && context.mounted) Navigator.pop(context);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: Padding(
            padding: const EdgeInsets.all(8),
            child: GestureDetector(
              onTap: () async {
                final should = await _onWillPop();
                if (should && context.mounted) Navigator.pop(context);
              },
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_back,
                  color: Colors.black,
                  size: 20,
                ),
              ),
            ),
          ),
        ),
        body: ListView(
          controller: _scrollController,
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            // ── FIXED: Hero cover + floating info card ──────────────────
            _buildCoverLogoUpload(),

            const SizedBox(height: 20),

            _buildSection(
              key: _nameKey,
              label: 'Shop Name',
              child: _buildLangField(
                selectedLang: _nameLang,
                onLangChanged: (l) => setState(() => _nameLang = l),
                controller: _nameLang == 'EN'
                    ? _nameEnCtrl
                    : _nameLang == 'MM'
                    ? _nameMmCtrl
                    : _nameThCtrl,
                hint: 'Enter shop name',
                enabled: true,
                maxLength: 100,
              ),
            ),
            const SizedBox(height: 32),
            _buildSection(
              key: _categoryKey,
              label: 'Category',
              required: true,
              child: _buildDropdown(
                'Select Category',
                _selectedCategory,
                _categories,
                'Choose category',
                (v) => setState(() {
                  _selectedCategory = v;
                  _markChanged();
                }),
              ),
            ),
            const SizedBox(height: 32),
            _buildSection(
              key: _subCategoryKey,
              label: 'Sub-category',
              required: true,
              child: _buildDropdown(
                'Select Sub-category',
                _selectedSubcategory,
                _subcategories,
                'Choose sub-category',
                (v) => setState(() {
                  _selectedSubcategory = v;
                  _markChanged();
                }),
              ),
            ),
            const SizedBox(height: 32),
            _buildSection(
              key: _cuisineTypeKey,
              label: 'Cuisine Types',
              required: true,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _cuisineTypes.map((c) {
                    final isSelected = _selectedCuisineTypes.contains(c);
                    return FilterChip(
                      label: Text(
                        c.displayName,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF475569),
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: const Color(0xFFED3973),
                      backgroundColor: Colors.white,
                      checkmarkColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isSelected
                              ? const Color(0xFFED3973)
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedCuisineTypes.add(c);
                          } else {
                            _selectedCuisineTypes.remove(c);
                          }
                          _markChanged();
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 32),

            _buildSection(
              label: 'Description',
              child: _buildLangField(
                selectedLang: _descLang,
                onLangChanged: (l) => setState(() => _descLang = l),
                controller: _descLang == 'EN'
                    ? _descEnCtrl
                    : _descLang == 'MM'
                    ? _descMmCtrl
                    : _descThCtrl,
                hint: 'Enter description',
                maxLines: 3,
                maxLength: 500,
              ),
            ),
            const SizedBox(height: 32),

            _buildSection(
              key: _phoneKey,
              label: 'Phone Numbers',
              required: true,
              child: Column(
                children: [
                  for (int i = 0; i < _phoneControllers.length; i++)
                    Padding(
                      padding: EdgeInsets.only(bottom: i < _phoneControllers.length - 1 ? 12.0 : 0),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              _phoneControllers[i],
                              '+95 9 XXX XXX XXX',
                              icon: PhosphorIconsRegular.phone,
                              maxLength: 20,
                            ),
                          ),
                          if (_phoneControllers.length > 1 || i == _phoneControllers.length - 1)
                            const SizedBox(width: 8),
                          if (_phoneControllers.length > 1)
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  _phoneControllers[i].dispose();
                                  _phoneControllers.removeAt(i);
                                  _markChanged();
                                });
                              },
                              icon: const Icon(PhosphorIconsRegular.minusCircle, color: Color(0xFFEF4444)),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          if (_phoneControllers.length > 1 && i == _phoneControllers.length - 1)
                            const SizedBox(width: 8),
                          if (i == _phoneControllers.length - 1)
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  _phoneControllers.add(TextEditingController());
                                  _markChanged();
                                });
                              },
                              icon: const Icon(PhosphorIconsRegular.plusCircle, color: Color(0xFFED3973)),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            _buildSection(
              label: 'Email',
              child: _buildTextField(
                _emailCtrl,
                'shop@example.com',
                icon: PhosphorIconsRegular.envelope,
                enabled: false,
                maxLength: 100,
              ),
            ),
            const SizedBox(height: 32),

            _buildSection(
              key: _addressKey,
              label: 'Street Address',
              required: true,
              child: _buildLangField(
                selectedLang: _addressLang,
                onLangChanged: (l) => setState(() => _addressLang = l),
                controller: _addressLang == 'EN'
                    ? _addressEnCtrl
                    : _addressLang == 'MM'
                    ? _addressMmCtrl
                    : _addressThCtrl,
                hint: 'Enter street address',
                requiredLang: 'EN',
                maxLength: 255,
              ),
            ),
            const SizedBox(height: 32),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _buildSection(
                      label: 'City',
                      child: _buildDropdown(
                        'Select City',
                        _selectedCity,
                        _cities,
                        'Choose city',
                        (v) => setState(() {
                          _selectedCity = v;
                          if (v != null) {
                            _cityCtrl.text = v.nameEn ?? '';
                            _selectedDistrict = null;
                            _fetchDistricts(v.id);
                          }
                          _markChanged();
                        }),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSection(
                      label: 'District',
                      child: _buildDropdown(
                        'Select District',
                        _selectedDistrict,
                        _districts,
                        'Choose district',
                        (v) => setState(() {
                          _selectedDistrict = v;
                          if (v != null) {
                            _districtCtrl.text = v.nameEn ?? '';
                          }
                          _markChanged();
                        }),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            _buildToggleSection(
              title: 'Standard Delivery Settings',
              items: [
                _ToggleItem(
                  icon: PhosphorIconsRegular.truck,
                  label: 'Enable Standard Delivery',
                  value: _deliveryEnabled,
                  onChanged: (v) => setState(() {
                    _deliveryEnabled = v;
                    _markChanged();
                  }),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Padding(
              key: _baseFeeKey,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _buildSmallField(
                      label: 'Base Delivery Fee',
                      controller: _baseFeeCtrl,
                      hint: '0.00',
                      keyboardType: TextInputType.number,
                      required: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(child: SizedBox()), // Placeholder
                ],
              ),
            ),
            const SizedBox(height: 32),

            const SizedBox(height: 24),

            _buildToggleSection(
              title: 'Amenities',
              items: [
                _ToggleItem(
                  icon: PhosphorIconsRegular.car,
                  label: 'Parking',
                  value: _hasParking,
                  onChanged: (v) {
                    setState(() => _hasParking = v);
                    _markChanged();
                  },
                ),
                _ToggleItem(
                  icon: PhosphorIconsRegular.wifiHigh,
                  label: 'WiFi',
                  value: _hasWifi,
                  onChanged: (v) {
                    setState(() => _hasWifi = v);
                    _markChanged();
                  },
                ),
                _ToggleItem(
                  icon: PhosphorIconsRegular.motorcycle,
                  label: 'Delivery',
                  value: _hasDelivery,
                  onChanged: (v) {
                    setState(() => _hasDelivery = v);
                    _markChanged();
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            _buildToggleSection(
              title: 'Dietary Tags',
              items: [
                _ToggleItem(
                  icon: PhosphorIconsRegular.moon,
                  label: 'Halal',
                  value: _isHalal,
                  onChanged: (v) {
                    setState(() => _isHalal = v);
                    _markChanged();
                  },
                ),
                _ToggleItem(
                  icon: PhosphorIconsRegular.leaf,
                  label: 'Vegetarian',
                  value: _isVegetarian,
                  onChanged: (v) {
                    setState(() => _isVegetarian = v);
                    _markChanged();
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            _buildSection(
              label: 'Price Range',
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    _PriceOption(
                      label: '฿ Budget',
                      index: 0,
                      selected: _priceRange == 0,
                      onTap: () {
                        setState(() => _priceRange = 0);
                        _markChanged();
                      },
                    ),
                    _PriceOption(
                      label: '฿฿ Mid-range',
                      index: 1,
                      selected: _priceRange == 1,
                      onTap: () {
                        setState(() => _priceRange = 1);
                        _markChanged();
                      },
                    ),
                    _PriceOption(
                      label: '฿฿฿ Premium',
                      index: 2,
                      selected: _priceRange == 2,
                      onTap: () {
                        setState(() => _priceRange = 2);
                        _markChanged();
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
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
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: SizedBox(
                width: double.infinity,
                height: 64,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFED3973),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    elevation: 0,
                  ),
                  child: _isSaving
                      ? const CustomLoadingIndicator(
                          size: 24,
                          color: Colors.white,
                        )
                      : Text(
                          'Save',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── FIXED: Cover + Logo upload ────────────────────────────────────────────
  Widget _buildCoverLogoUpload() {
    final coverUrl = _currentProfile?.coverUrl;
    final logoUrl = _currentProfile?.logoUrl;
    final shopName = _nameEnCtrl.text.isNotEmpty
        ? _nameEnCtrl.text
        : (_currentProfile?.nameEn ?? 'Shop Name');

    const heroHeight = 360.0;

    return SizedBox(
      height: heroHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // ── Full hero image ───────────────────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: heroHeight,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(32),
              ),
              child: GestureDetector(
                onTap: _pickCover,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Image or gradient fallback
                    if (_pickedCover != null)
                      kIsWeb
                          ? Image.network(_pickedCover!.path, fit: BoxFit.cover)
                          : Image.file(
                              File(_pickedCover!.path),
                              fit: BoxFit.cover,
                            )
                    else if (coverUrl != null && coverUrl.isNotEmpty)
                      CachedNetworkImage(
                        imageUrl: coverUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, _) => _buildCoverGradient(),
                        errorWidget: (_, _, _) => _buildCoverGradient(),
                      )
                    else
                      _buildCoverGradient(),

                    // Dark overlay at top for back button contrast
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: 90,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.35),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Camera hint when no cover photo
                    if (_pickedCover == null &&
                        (coverUrl == null || coverUrl.isEmpty))
                      Container(
                        color: Colors.black.withValues(alpha: 0.15),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.25),
                                  shape: BoxShape.circle,
                                ),
                                child: const PhosphorIcon(
                                  PhosphorIconsRegular.camera,
                                  size: 28,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Tap to add cover photo',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // ── Floating info card (inside hero image) ──────
          Positioned(
            bottom: 24,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Logo (tap to change)
                  GestureDetector(
                    onTap: _pickLogo,
                    child: Stack(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: _pickedLogo != null
                                ? (kIsWeb
                                      ? Image.network(
                                          _pickedLogo!.path,
                                          fit: BoxFit.cover,
                                        )
                                      : Image.file(
                                          File(_pickedLogo!.path),
                                          fit: BoxFit.cover,
                                        ))
                                : logoUrl != null && logoUrl.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: logoUrl,
                                    fit: BoxFit.cover,
                                    placeholder: (_, _) =>
                                        _buildLogoPlaceholder(),
                                    errorWidget: (_, _, _) =>
                                        _buildLogoPlaceholder(),
                                  )
                                : _buildLogoPlaceholder(),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: const Color(0xFFED3973),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              size: 11,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      shopName,
                      style: GoogleFonts.poppins(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E293B),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoverGradient() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFED3973), Color(0xFFFF8C69)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }

  Widget _buildLogoPlaceholder() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFED3973), Color(0xFFFF8C69)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: PhosphorIcon(
          PhosphorIconsRegular.storefront,
          size: 26,
          color: Colors.white,
        ),
      ),
    );
  }

  // ── Image helpers ─────────────────────────────────────────────────────────

  void _viewImage(String title, {String? url, String? path}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            FullscreenImageViewer(title: title, imageUrl: url, imagePath: path),
      ),
    );
  }

  void _showImageActionSheet({
    required String title,
    String? imageUrl,
    String? imagePath,
    required VoidCallback onChange,
  }) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _ImageActionSheet(
        title: title,
        onView: () {
          Navigator.pop(context);
          _viewImage(title, url: imageUrl, path: imagePath);
        },
        onChange: () {
          Navigator.pop(context);
          onChange();
        },
      ),
    );
  }

  Future<void> _pickCover() async {
    final coverUrl = _currentProfile?.coverUrl;
    final hasImage =
        _pickedCover != null || (coverUrl != null && coverUrl.isNotEmpty);

    if (hasImage) {
      _showImageActionSheet(
        title: 'Cover Photo',
        imageUrl: _pickedCover == null ? coverUrl : null,
        imagePath: _pickedCover?.path,
        onChange: _openCoverPicker,
      );
    } else {
      _openCoverPicker();
    }
  }

  Future<void> _openCoverPicker() async {
    final result = await ImageUploadService().pickFromGallery();
    if (result.permanentlyDenied && mounted) {
      _showSettingsDialog();
      return;
    }
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
      setState(() {
        _pickedCover = result.file;
        _hasChanges = true;
      });
    }
  }

  Future<void> _pickLogo() async {
    final logoUrl = _currentProfile?.logoUrl;
    final hasImage =
        _pickedLogo != null || (logoUrl != null && logoUrl.isNotEmpty);

    if (hasImage) {
      _showImageActionSheet(
        title: 'Profile Picture',
        imageUrl: _pickedLogo == null ? logoUrl : null,
        imagePath: _pickedLogo?.path,
        onChange: _openLogoPicker,
      );
    } else {
      _openLogoPicker();
    }
  }

  Future<void> _openLogoPicker() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _LogoPickerSheet(
        onGallery: () async {
          Navigator.pop(context);
          final r = await ImageUploadService().pickFromGallery();
          if (r.isTooLarge) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Image size must be less than 1MB'),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }
          if (r.file != null && mounted) {
            setState(() {
              _pickedLogo = r.file;
              _hasChanges = true;
            });
          }
        },
        onCamera: () async {
          Navigator.pop(context);
          final r = await ImageUploadService().pickFromCamera();
          if (r.isTooLarge) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Image size must be less than 1MB'),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }
          if (r.file != null && mounted) {
            setState(() {
              _pickedLogo = r.file;
              _hasChanges = true;
            });
          }
        },
      ),
    );
  }

  void _showSettingsDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Permission Required',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        content: Text(
          'Photo library access is required. Please enable it in Settings.',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: const Color(0xFF475569),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: const Color(0xFF475569)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Open Settings',
              style: GoogleFonts.poppins(
                color: const Color(0xFFED3973),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Form helpers ──────────────────────────────────────────────────────────

  Widget _buildSection({
    Key? key,
    required String label,
    required Widget child,
    EdgeInsets? padding,
    bool required = false,
  }) {
    return Padding(
      key: key,
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: label,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF475569),
                  ),
                ),
                if (required)
                  const TextSpan(
                    text: ' *',
                    style: TextStyle(
                      color: Color(0xFFED3973),
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildLangField({
    required String selectedLang,
    required ValueChanged<String> onLangChanged,
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    String? requiredLang,
    bool enabled = true,
    int? maxLength,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: ['EN', 'MM', 'TH'].map((lang) {
            final selected = selectedLang == lang;
            final isRequired = requiredLang == lang;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => onLangChanged(lang),
                child: Container(
                  constraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: selected ? const Color(0xFFED3973) : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: selected
                          ? const Color(0xFFED3973)
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: lang,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: selected
                                ? Colors.white
                                : const Color(0xFF64748B),
                          ),
                        ),
                        if (isRequired)
                          TextSpan(
                            text: ' *',
                            style: TextStyle(
                              color: selected
                                  ? Colors.white
                                  : const Color(0xFFED3973),
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: controller,
          maxLines: maxLines,
          maxLength: maxLength,
          enabled: enabled,
          onChanged: (_) => _markChanged(),
          decoration: InputDecoration(
            counterText: '',
            hintText: hint,
            hintStyle: GoogleFonts.poppins(
              color: const Color(0xFFCBD5E1),
              fontSize: 14,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: Color(0xFFED3973),
                width: 1.5,
              ),
            ),
          ),
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: const Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(
    TextEditingController ctrl,
    String hint, {
    IconData? icon,
    bool enabled = true,
    int? maxLength,
  }) {
    return TextField(
      controller: ctrl,
      enabled: enabled,
      maxLength: maxLength,
      onChanged: (_) => _markChanged(),
      decoration: InputDecoration(
        counterText: '',
        hintText: hint,
        hintStyle: GoogleFonts.poppins(
          color: const Color(0xFFCBD5E1),
          fontSize: 14,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        prefixIcon: icon != null
            ? PhosphorIcon(icon, size: 18, color: const Color(0xFF94A3B8))
            : null,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFED3973), width: 1.5),
        ),
      ),
      style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF1E293B)),
    );
  }

  Widget _buildToggleSection({
    required String title,
    required List<_ToggleItem> items,
  }) {
    return _buildSection(
      label: title,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: items.asMap().entries.map((entry) {
            final i = entry.key;
            final item = entry.value;
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 4,
                  ),
                  child: Row(
                    children: [
                      PhosphorIcon(
                        item.icon,
                        size: 20,
                        color: const Color(0xFF475569),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          item.label,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 24,
                        child: Transform.scale(
                          scale: 0.65,
                          child: Switch(
                            value: item.value,
                            onChanged: item.onChanged,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            thumbColor: WidgetStateProperty.all(Colors.white),
                            trackOutlineColor: WidgetStateProperty.all(
                              Colors.transparent,
                            ),
                            trackColor: WidgetStateProperty.resolveWith((
                              states,
                            ) {
                              if (states.contains(WidgetState.selected)) {
                                return const Color(0xFFED3973);
                              }
                              return const Color(0xFFE2E8F0);
                            }),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (i < items.length - 1)
                  const Divider(
                    height: 1,
                    color: Color(0xFFE2E8F0),
                    indent: 14,
                    endIndent: 14,
                  ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSmallField({
    required String label,
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    bool required = false,
    int? maxLength,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF64748B),
                ),
              ),
              if (required)
                const TextSpan(
                  text: ' *',
                  style: TextStyle(
                    color: Color(0xFFED3972),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        _buildTextFieldWithKeyboard(controller, hint, keyboardType, maxLength: maxLength),
      ],
    );
  }

  Widget _buildTextFieldWithKeyboard(
    TextEditingController ctrl,
    String hint,
    TextInputType keyboardType, {
    int? maxLength,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      maxLength: maxLength,
      onChanged: (_) => _markChanged(),
      decoration: InputDecoration(
        counterText: '',
        hintText: hint,
        hintStyle: GoogleFonts.poppins(
          color: const Color(0xFFCBD5E1),
          fontSize: 14,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFED3973), width: 1.5),
        ),
      ),
      style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF1E293B)),
    );
  }
}

// ── Supporting classes ────────────────────────────────────────────────────────

class _ToggleItem {
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _ToggleItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });
}

class _PriceOption extends StatelessWidget {
  final String label;
  final int index;
  final bool selected;
  final VoidCallback onTap;
  const _PriceOption({
    required this.label,
    required this.index,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFED3973) : Colors.transparent,
            borderRadius: BorderRadius.horizontal(
              left: index == 0 ? const Radius.circular(10) : Radius.zero,
              right: index == 2 ? const Radius.circular(10) : Radius.zero,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : const Color(0xFF64748B),
            ),
          ),
        ),
      ),
    );
  }
}

class _ImageActionSheet extends StatelessWidget {
  final String title;
  final VoidCallback onView;
  final VoidCallback onChange;

  const _ImageActionSheet({
    required this.title,
    required this.onView,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Text(
              title,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 17,
                color: const Color(0xFF1E293B),
              ),
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(
              Icons.visibility_outlined,
              color: Color(0xFFED3973),
            ),
            title: Text(
              'View Image',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
            ),
            onTap: onView,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 4,
            ),
          ),
          const Divider(height: 1, indent: 64),
          ListTile(
            leading: const Icon(
              Icons.camera_alt_outlined,
              color: Color(0xFFED3973),
            ),
            title: Text(
              'Change Image',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
            ),
            onTap: onChange,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 4,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.poppins(color: const Color(0xFF64748B)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LogoPickerSheet extends StatelessWidget {
  final VoidCallback onGallery;
  final VoidCallback onCamera;

  const _LogoPickerSheet({required this.onGallery, required this.onCamera});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Text(
              'Update Shop Logo',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 17,
                color: const Color(0xFF1E293B),
              ),
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(
              Icons.photo_library_outlined,
              color: Color(0xFFED3973),
            ),
            title: Text(
              'Choose from Gallery',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
            ),
            onTap: onGallery,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 4,
            ),
          ),
          const Divider(height: 1, indent: 64),
          ListTile(
            leading: const Icon(
              Icons.camera_alt_outlined,
              color: Color(0xFFED3973),
            ),
            title: Text(
              'Take a Photo',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
            ),
            onTap: onCamera,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 4,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.poppins(color: const Color(0xFF64748B)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
