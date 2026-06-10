// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:my_shop/core/localization/app_localizations.dart';
import 'package:my_shop/core/data/services/image_upload_service.dart';
import 'package:my_shop/core/network/multipart_file_helper.dart';
import 'package:my_shop/core/presentation/widgets/custom_loading_indicator.dart';
import 'package:my_shop/core/presentation/widgets/fullscreen_image_viewer.dart';
import 'package:my_shop/core/presentation/widgets/custom_search_dropdown.dart';
import 'package:my_shop/core/presentation/widgets/primary_gradient_button.dart';
import 'package:my_shop/features/profile/data/models/shop_profile_model.dart';
import 'package:my_shop/features/profile/data/services/profile_service.dart';
import 'package:my_shop/core/data/models/master_data_model.dart';
import 'package:my_shop/core/data/services/master_data_service.dart';
import 'package:my_shop/core/presentation/widgets/app_dialog.dart';
import '../widgets/image_action_sheet.dart';
import '../widgets/logo_picker_sheet.dart';
import '../widgets/shop_profile_image_header.dart';
import '../widgets/form_section.dart';
import '../widgets/language_text_field.dart';
import '../widgets/shop_location_section.dart';
import '../widgets/amenities_dietary_section.dart';
import '../widgets/phone_numbers_section.dart';
import '../widgets/price_range_section.dart';
import '../widgets/cuisine_types_section.dart';

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
  late final TextEditingController _mapsLinkCtrl;

  double? _latitude;
  double? _longitude;

  late bool _hasParking;
  late bool _hasWifi;
  late bool _deliveryEnabled;
  late bool _isHalal;
  late bool _isVegetarian;
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
      if (_currentProfile!.cityId != null) {
        _selectedCity = _cities.firstWhere(
          (c) => c.id == _currentProfile!.cityId,
        );
        if (_selectedCity != null) {
          _fetchDistricts(_selectedCity!.id);
        }
      } else if (_currentProfile!.cityEn != null &&
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
        if (_currentProfile?.districtId != null) {
          try {
            _selectedDistrict = _districts.firstWhere(
              (d) => d.id == _currentProfile!.districtId,
            );
          } catch (_) {}
        } else if (_currentProfile?.districtEn != null &&
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

  bool _didInitLocale = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didInitLocale) {
      final locale = Localizations.localeOf(context).languageCode;
      String userLang = 'EN';
      if (locale == 'my') {
        userLang = 'MM';
      } else if (locale == 'th') {
        userLang = 'TH';
      }
      setState(() {
        _nameLang = userLang;
        _descLang = userLang;
        _addressLang = userLang;
      });
      _didInitLocale = true;
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
    final phones = phoneString
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (phones.isEmpty) {
      _phoneControllers = [TextEditingController()];
    } else {
      _phoneControllers = phones
          .map((ph) => TextEditingController(text: ph))
          .toList();
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
    _mapsLinkCtrl = TextEditingController(text: p?.googleMapsLink ?? '');

    _latitude = p?.latitude;
    _longitude = p?.longitude;

    _hasParking = p?.hasParking ?? false;
    _hasWifi = p?.hasWifi ?? false;
    _deliveryEnabled = p?.deliveryEnabled ?? false;
    _isHalal = p?.isHalal ?? false;
    _isVegetarian = p?.isVegetarian ?? false;

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
    final phones = (p.phone ?? '')
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (phones.isEmpty) {
      _phoneControllers = [TextEditingController()];
    } else {
      _phoneControllers = phones
          .map((ph) => TextEditingController(text: ph))
          .toList();
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
    _mapsLinkCtrl.text = p.googleMapsLink ?? '';

    _latitude = p.latitude;
    _longitude = p.longitude;
    _hasParking = p.hasParking;
    _hasWifi = p.hasWifi;
    _deliveryEnabled = p.deliveryEnabled;
    _isHalal = p.isHalal;
    _isVegetarian = p.isVegetarian;

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
    final t = AppLocalizations.of(context);
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Image.asset('assets/images/app_logo.png', width: 24, height: 24),
            const SizedBox(width: 8),
            Text(
              t?.translate('discard_changes_title') ?? 'Discard changes?',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ],
        ),
        content: Text(
          t?.translate('discard_changes_content') ?? 'You have unsaved changes. Do you want to discard them?',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: const Color(0xFF475569),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              t?.translate('continue_editing') ?? 'Continue Editing',
              style: GoogleFonts.poppins(
                color: const Color(0xFF475569),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              t?.translate('discard') ?? 'Discard',
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
    AppDialog.showToast(context, message, isError: true);
  }

  bool _validate() {
    final t = AppLocalizations.of(context);
    if (_nameEnCtrl.text.trim().isEmpty &&
        _nameMmCtrl.text.trim().isEmpty &&
        _nameThCtrl.text.trim().isEmpty) {
      _scrollToKey(_nameKey);
      _showError(t?.translate('shop_name_required') ?? 'Please Enter at Least One Shop Name');
      return false;
    }
    if (_selectedCategory == null) {
      _scrollToKey(_categoryKey);
      _showError(t?.translate('category_required') ?? 'Category Is Required');
      return false;
    }
    if (_selectedSubcategory == null) {
      _scrollToKey(_subCategoryKey);
      _showError(t?.translate('subcategory_required') ?? 'SubCategory Is Required');
      return false;
    }
    if (_selectedCuisineTypes.isEmpty) {
      _scrollToKey(_cuisineTypeKey);
      _showError(t?.translate('cuisine_type_required') ?? 'At Least One Cuisine Type Is Required');
      return false;
    }
    final validPhones = _phoneControllers
        .where((c) => c.text.trim().isNotEmpty)
        .toList();
    if (validPhones.isEmpty) {
      _scrollToKey(_phoneKey);
      _showError(t?.translate('phone_number_required') ?? 'At Least One Phone Number Is Required');
      return false;
    }
    if (_addressEnCtrl.text.trim().isEmpty) {
      // Switch to EN tab if not already on it so the user sees the empty field
      if (_addressLang != 'EN') setState(() => _addressLang = 'EN');
      _scrollToKey(_addressKey);
      _showError(t?.translate('street_address_en_required') ?? 'Street Address (EN) Is Required');
      return false;
    }
    final minAmount = double.tryParse(_minAmountCtrl.text.trim());
    if (minAmount != null && minAmount > 999999.9) {
      _showError(t?.translate('min_order_amount_too_large') ?? 'Minimum Order Amount Is Too Large');
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
      'phone': _phoneControllers
          .map((c) => c.text.trim())
          .where((t) => t.isNotEmpty)
          .join(','),
      'email': _emailCtrl.text,
      'addressEn': _addressEnCtrl.text,
      'addressMm': _addressMmCtrl.text,
      'addressTh': _addressThCtrl.text,
      'districtId': _selectedDistrict?.id,
      'districtEn': _selectedDistrict?.nameEn ?? _districtCtrl.text,
      'districtMm': _selectedDistrict?.nameMm ?? _districtCtrl.text,
      'districtTh': _selectedDistrict?.nameTh ?? _districtCtrl.text,
      'shopCategoryId': _selectedCategory?.id,
      'categoryEn': _selectedCategory?.nameEn ?? _catEnCtrl.text,
      'categoryMm': _selectedCategory?.nameMm ?? _catMmCtrl.text,
      'categoryTh': _selectedCategory?.nameTh ?? _catThCtrl.text,
      'shopSubCategoryId': _selectedSubcategory?.id,
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
      'deliveryEnabled': _deliveryEnabled,
      'isHalal': _isHalal,
      'isVegetarian': _isVegetarian,
      'pricePreference': _priceRange == 0
          ? 'LOW'
          : (_priceRange == 1 ? 'MEDIUM' : 'HIGH'),
      'maxItemQuantityPerOrder': int.tryParse(_maxQtyCtrl.text) ?? 10,
      'minOrderAmount': double.tryParse(_minAmountCtrl.text) ?? 0.0,
      'baseDeliveryFee': _currentProfile?.baseDeliveryFee ?? 0.0,
      'googleMapsLink': _mapsLinkCtrl.text,
      'cityId': _selectedCity?.id,
      'logoUrl': _currentProfile?.logoUrl,
      'coverUrl': _currentProfile?.coverUrl,
    };

    if (_pickedCover != null) {
      payload['coverPhoto'] = await multipartFileFromXFile(_pickedCover!);
    }

    if (_pickedLogo != null) {
      payload['logoPhoto'] = await multipartFileFromXFile(_pickedLogo!);
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
      final t = AppLocalizations.of(context);
      AppDialog.showToast(context, t?.translate('profile_saved_success') ?? 'Profile saved successfully!');
      Navigator.pop(context, true);
    } else {
      setState(() => _isSaving = false);
      final t = AppLocalizations.of(context);
      AppDialog.showToast(
        context,
        t?.translate('profile_saved_failed') ?? 'Failed to save profile. Please try again.',
        isError: true,
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

    final t = AppLocalizations.of(context);
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
                  t?.translate('no_data_found') ?? 'No Data Found',
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
      searchHintText: t?.translate('search_hint') ?? 'Search...',
      itemLabelBuilder: (item) => item.displayName,
      onChanged: onChanged,
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: Text(
            t?.translate('edit_profile') ?? 'Edit Profile',
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
            ShopProfileImageHeader(
              pickedCover: _pickedCover,
              pickedLogo: _pickedLogo,
              coverUrl: _currentProfile?.coverUrl,
              logoUrl: _currentProfile?.logoUrl,
              shopName: _nameEnCtrl.text.isNotEmpty
                  ? _nameEnCtrl.text
                  : (_currentProfile?.nameEn ?? 'Shop Name'),
              onPickCover: _pickCover,
              onPickLogo: _pickLogo,
            ),

            const SizedBox(height: 20),

            FormSection(
              key: _nameKey,
              label: t?.translate('shop_name_label') ?? 'Shop Name',
              child: LanguageTextField(
                selectedLang: _nameLang,
                onLangChanged: (l) => setState(() => _nameLang = l),
                controller: _nameLang == 'EN'
                    ? _nameEnCtrl
                    : _nameLang == 'MM'
                    ? _nameMmCtrl
                    : _nameThCtrl,
                hint: t?.translate('enter_shop_name_hint') ?? 'Enter shop name',
                enabled: true,
                maxLength: 100,
                onChanged: _markChanged,
              ),
            ),
            const SizedBox(height: 32),
            FormSection(
              key: _categoryKey,
              label: t?.translate('category') ?? 'Category',
              required: true,
              child: _buildDropdown(
                t?.translate('select_category') ?? 'Select Category',
                _selectedCategory,
                _categories,
                t?.translate('choose_category') ?? 'Choose Category',
                (v) => setState(() {
                  _selectedCategory = v;
                  _markChanged();
                }),
              ),
            ),
            const SizedBox(height: 32),
            FormSection(
              key: _subCategoryKey,
              label: t?.translate('sub_category') ?? 'SubCategory',
              required: true,
              child: _buildDropdown(
                t?.translate('select_subcategory') ?? 'Select SubCategory',
                _selectedSubcategory,
                _subcategories,
                t?.translate('choose_subcategory') ?? 'Choose SubCategory',
                (v) => setState(() {
                  _selectedSubcategory = v;
                  _markChanged();
                }),
              ),
            ),
            const SizedBox(height: 32),
            CuisineTypesSection(
              key: _cuisineTypeKey,
              cuisineTypes: _cuisineTypes,
              initialSelectedCuisineTypes: _selectedCuisineTypes,
              onChanged: (selected) {
                _selectedCuisineTypes = selected;
                _markChanged();
              },
            ),
            const SizedBox(height: 32),

            FormSection(
              label: t?.translate('description') ?? 'Description',
              child: LanguageTextField(
                selectedLang: _descLang,
                onLangChanged: (l) => setState(() => _descLang = l),
                controller: _descLang == 'EN'
                    ? _descEnCtrl
                    : _descLang == 'MM'
                    ? _descMmCtrl
                    : _descThCtrl,
                hint: t?.translate('enter_description_hint') ?? 'Enter Description',
                maxLines: 3,
                maxLength: 500,
                onChanged: _markChanged,
              ),
            ),
            const SizedBox(height: 32),

            PhoneNumbersSection(
              key: _phoneKey,
              phoneControllers: _phoneControllers,
              onMarkChanged: _markChanged,
            ),
            const SizedBox(height: 32),

            FormSection(
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

            ShopLocationSection(
              key: _addressKey,
              addressLang: _addressLang,
              onAddressLangChanged: (l) => setState(() => _addressLang = l),
              addressEnCtrl: _addressEnCtrl,
              addressMmCtrl: _addressMmCtrl,
              addressThCtrl: _addressThCtrl,
              selectedCity: _selectedCity,
              cities: _cities,
              selectedDistrict: _selectedDistrict,
              districts: _districts,
              onCityChanged: (v) => setState(() {
                _selectedCity = v;
                if (v != null) {
                  _cityCtrl.text = v.nameEn ?? '';
                  _selectedDistrict = null;
                  _fetchDistricts(v.id);
                }
                _markChanged();
              }),
              onDistrictChanged: (v) => setState(() {
                _selectedDistrict = v;
                if (v != null) {
                  _districtCtrl.text = v.nameEn ?? '';
                }
                _markChanged();
              }),
              onMarkChanged: _markChanged,
            ),
            const SizedBox(height: 32),

             AmenitiesAndDietarySection(
               hasParking: _hasParking,
               hasWifi: _hasWifi,
               deliveryEnabled: _deliveryEnabled,
               isHalal: _isHalal,
               isVegetarian: _isVegetarian,
               onChanged: (parking, wifi, delivery, halal, vegetarian) {
                 _hasParking = parking;
                 _hasWifi = wifi;
                 _deliveryEnabled = delivery;
                 _isHalal = halal;
                 _isVegetarian = vegetarian;
                 _markChanged();
               },
             ),
             const SizedBox(height: 32),

             PriceRangeSection(
              initialPriceRange: _priceRange,
              onChanged: (v) {
                _priceRange = v;
                _markChanged();
              },
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
                child: PrimaryGradientButton(
                  onPressed: _save,
                  isLoading: _isSaving,
                  text: t?.translate('save') ?? 'Save',
                  height: 64,
                  borderRadius: 18,
                ),
              ),
            ),
          ),
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
      builder: (_) => ImageActionSheet(
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
    final t = AppLocalizations.of(context);
    final coverUrl = _currentProfile?.coverUrl;
    final hasImage =
        _pickedCover != null || (coverUrl != null && coverUrl.isNotEmpty);

    if (hasImage) {
      _showImageActionSheet(
        title: t?.translate('cover_photo_label') ?? 'Cover Photo',
        imageUrl: _pickedCover == null ? coverUrl : null,
        imagePath: _pickedCover?.path,
        onChange: _openCoverPicker,
      );
    } else {
      _openCoverPicker();
    }
  }

  Future<void> _openCoverPicker() async {
    final t = AppLocalizations.of(context);
    final result = await ImageUploadService().pickFromGallery();
    if (result.permanentlyDenied && mounted) {
      _showSettingsDialog();
      return;
    }
    if (result.isTooLarge) {
      if (!mounted) return;
      AppDialog.showToast(
        context,
        t?.translate('image_size_limit_msg') ?? 'Image Size Must Be Less Than 1MB',
        isError: true,
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
    final t = AppLocalizations.of(context);
    final logoUrl = _currentProfile?.logoUrl;
    final hasImage =
        _pickedLogo != null || (logoUrl != null && logoUrl.isNotEmpty);

    if (hasImage) {
      _showImageActionSheet(
        title: t?.translate('profile_picture_label') ?? 'Profile Picture',
        imageUrl: _pickedLogo == null ? logoUrl : null,
        imagePath: _pickedLogo?.path,
        onChange: _openLogoPicker,
      );
    } else {
      _openLogoPicker();
    }
  }

  Future<void> _openLogoPicker() async {
    final t = AppLocalizations.of(context);
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => LogoPickerSheet(
        onGallery: () async {
          Navigator.pop(context);
          final r = await ImageUploadService().pickFromGallery();
          if (r.isTooLarge) {
            if (!mounted) return;
            AppDialog.showToast(
              context,
              t?.translate('image_size_limit_msg') ?? 'Image Size Must Be Less Than 1MB',
              isError: true,
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
            AppDialog.showToast(
              context,
              t?.translate('image_size_limit_msg') ?? 'Image Size Must Be Less Than 1MB',
              isError: true,
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
    final t = AppLocalizations.of(context);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          t?.translate('permission_required') ?? 'Permission Required',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        content: Text(
          t?.translate('photo_library_permission_msg') ?? 'Photo library access is required. Please enable it in Settings.',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: const Color(0xFF475569),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              t?.translate('cancel') ?? 'Cancel',
              style: GoogleFonts.poppins(color: const Color(0xFF475569)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              t?.translate('open_settings') ?? 'Open Settings',
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
}
