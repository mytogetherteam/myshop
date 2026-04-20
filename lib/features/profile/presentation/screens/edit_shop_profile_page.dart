// ignore_for_file: deprecated_member_use, use_build_context_synchronously
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:my_shop/features/profile/data/models/shop_profile_model.dart';
import 'package:my_shop/features/profile/data/services/profile_service.dart';
import 'package:my_shop/core/data/services/image_upload_service.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/presentation/widgets/custom_loading_indicator.dart';
import '../../../../core/presentation/widgets/fullscreen_image_viewer.dart';
import '../../../../core/data/thailand_address_data.dart';

class EditShopProfilePage extends StatefulWidget {
  final ShopProfileModel? shopProfile;
  const EditShopProfilePage({super.key, this.shopProfile});

  @override
  State<EditShopProfilePage> createState() => _EditShopProfilePageState();
}

class _EditShopProfilePageState extends State<EditShopProfilePage> {
  final ProfileService _profileService = ProfileService();
  bool _isLoading = true;
  bool _isSaving = false;
  bool _hasChanges = false;

  ShopProfileModel? _currentProfile;
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _addressEnCtrl = TextEditingController();
  final _addressMmCtrl = TextEditingController();
  final _addressThCtrl = TextEditingController();
  final _districtCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _mapsLinkCtrl = TextEditingController();
  
  final _nameEnCtrl = TextEditingController();
  final _nameMmCtrl = TextEditingController();
  final _nameThCtrl = TextEditingController();
  final _descEnCtrl = TextEditingController();
  final _descMmCtrl = TextEditingController();
  final _descThCtrl = TextEditingController();
  final _catEnCtrl = TextEditingController();
  final _catMmCtrl = TextEditingController();
  final _catThCtrl = TextEditingController();
  final _subCatEnCtrl = TextEditingController();
  final _subCatMmCtrl = TextEditingController();
  final _subCatThCtrl = TextEditingController();

  // --- Category & Sub-category dropdown data ---
  static const List<Map<String, dynamic>> _shopCategories = [
    {'id': 14, 'nameEn': 'Cafe', 'nameMm': 'Cafe', 'nameTh': ''},
    {'id': 17, 'nameEn': 'test ak', 'nameMm': 'tst', 'nameTh': 'adfasdf'},
    {'id': 19, 'nameEn': 'test', 'nameMm': 'test', 'nameTh': 'test'},
    {'id': 15, 'nameEn': 'Restaurant', 'nameMm': 'Restaurant', 'nameTh': ''},
    {'id': 20, 'nameEn': 'testing_Pyae_shop_category_update', 'nameMm': 'testing_Pyae_shop_category', 'nameTh': 'testing_Pyae_shop_category'},
    {'id': 21, 'nameEn': '-', 'nameMm': '-', 'nameTh': ''},
    {'id': 22, 'nameEn': 'Street Food', 'nameMm': 'Street Food', 'nameTh': ''},
    {'id': 23, 'nameEn': 'Bar', 'nameMm': 'Bar', 'nameTh': ''},
  ];

  static const List<Map<String, dynamic>> _shopSubCategories = [
    {'id': 7,  'categoryId': 15, 'nameEn': 'ကြက်ဆီထမင်း',             'nameMm': 'ကြက်ဆီထမင်း',             'nameTh': ''},
    {'id': 6,  'categoryId': 14, 'nameEn': 'Cake & Coffee',              'nameMm': 'Cake & Coffee',              'nameTh': ''},
    {'id': 9,  'categoryId': 20, 'nameEn': 'testing_Pyae_shop_sub_category', 'nameMm': 'testing_Pyae_shop_sub_category', 'nameTh': 'testing_Pyae_shop_sub_category'},
    {'id': 14, 'categoryId': 14, 'nameEn': 'Cake & Coffee',              'nameMm': 'Cake & Coffee',              'nameTh': ''},
    {'id': 15, 'categoryId': 21, 'nameEn': '-',                          'nameMm': '-',                          'nameTh': '-'},
    {'id': 16, 'categoryId': 15, 'nameEn': 'Myanmar Restaurants',        'nameMm': 'Myanmar Restaurants',        'nameTh': ''},
    {'id': 17, 'categoryId': 15, 'nameEn': 'Bumese Restaurant',          'nameMm': 'Bumese Restaurant',          'nameTh': ''},
    {'id': 18, 'categoryId': 15, 'nameEn': 'Shan Food',                  'nameMm': 'Shan Food',                  'nameTh': ''},
    {'id': 19, 'categoryId': 15, 'nameEn': 'Shan Specialist',            'nameMm': 'Shan Specialist',            'nameTh': ''},
    {'id': 20, 'categoryId': 15, 'nameEn': 'Noodle Special',             'nameMm': 'Noodle Special',             'nameTh': ''},
    {'id': 21, 'categoryId': 15, 'nameEn': 'Burmese Restaurant',         'nameMm': 'Burmese Restaurant',         'nameTh': ''},
    {'id': 22, 'categoryId': 15, 'nameEn': 'Traditional Burmese Food',   'nameMm': 'Traditional Burmese Food',   'nameTh': ''},
    {'id': 23, 'categoryId': 15, 'nameEn': 'Chinese & Burmese Restaurant','nameMm': 'Chinese & Burmese Restaurant','nameTh': ''},
  ];

  int? _selectedCategoryId;
  int? _selectedSubCategoryId;
  final _baseFeeCtrl = TextEditingController();
  final _minAmountCtrl = TextEditingController();
  final _maxQtyCtrl = TextEditingController();

  String _nameLang = 'EN';
  String _descLang = 'EN';
  String _addressLang = 'EN';

  XFile? _pickedCover;
  XFile? _pickedLogo;

  bool _hasParking = false;
  bool _hasWifi = false;
  bool _hasDelivery = false;
  bool _isHalal = false;
  bool _isVegetarian = false;
  bool _deliveryEnabled = false;
  int _priceRange = 1;
  double? _latitude;
  double? _longitude;


  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    // Pre-populate with passed-in profile immediately (no flicker)
    if (widget.shopProfile != null && _isLoading) {
      _populateForm(widget.shopProfile!);
    }
    // Then fetch fresh copy from SharedPreferences (picks up latest saves)
    try {
      final profile = await _profileService.getShopProfile();
      if (profile != null && mounted) {
        setState(() => _populateForm(profile));
      } else if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _populateForm(ShopProfileModel profile) {
    _currentProfile = profile;
    _phoneCtrl.text = profile.phone ?? '';
    _emailCtrl.text = profile.email ?? '';
    _addressEnCtrl.text = profile.addressEn ?? '';
    _addressMmCtrl.text = profile.addressMm ?? '';
    _addressThCtrl.text = profile.addressTh ?? '';
    _districtCtrl.text = profile.districtEn ?? '';
    _cityCtrl.text = profile.cityEn ?? '';
    _mapsLinkCtrl.text = profile.googleMapsLink ?? '';
    _nameEnCtrl.text = profile.nameEn ?? '';
    _nameMmCtrl.text = profile.nameMm ?? '';
    _nameThCtrl.text = profile.nameTh ?? '';
    _descEnCtrl.text = profile.descriptionEn ?? '';
    _descMmCtrl.text = profile.descriptionMm ?? '';
    _descThCtrl.text = profile.descriptionTh ?? '';
    _catEnCtrl.text = profile.categoryEn ?? '';
    _catMmCtrl.text = profile.categoryMm ?? '';
    _catThCtrl.text = profile.categoryTh ?? '';
    _subCatEnCtrl.text = profile.subCategoryEn ?? '';
    _subCatMmCtrl.text = profile.subCategoryMm ?? '';
    _subCatThCtrl.text = profile.subCategoryTh ?? '';
    // Pre-select category/sub-category from saved EN name
    final savedCatEn = profile.categoryEn ?? '';
    final savedSubEn = profile.subCategoryEn ?? '';
    if (savedCatEn.isNotEmpty) {
      final match = _shopCategories.firstWhere(
        (c) => (c['nameEn'] as String).toLowerCase() == savedCatEn.toLowerCase(),
        orElse: () => const {},
      );
      if (match.isNotEmpty) _selectedCategoryId = match['id'] as int?;
    }
    if (savedSubEn.isNotEmpty && _selectedCategoryId != null) {
      final match = _shopSubCategories.firstWhere(
        (s) => s['categoryId'] == _selectedCategoryId &&
               (s['nameEn'] as String).toLowerCase() == savedSubEn.toLowerCase(),
        orElse: () => const {},
      );
      if (match.isNotEmpty) _selectedSubCategoryId = match['id'] as int?;
    }
    _baseFeeCtrl.text = profile.baseDeliveryFee.toString();
    _minAmountCtrl.text = profile.minOrderAmount.toString();
    _maxQtyCtrl.text = profile.maxItemQuantityPerOrder.toString();
    _hasParking = profile.hasParking;
    _hasWifi = profile.hasWifi;
    _hasDelivery = profile.hasDelivery;
    _isHalal = profile.isHalal;
    _isVegetarian = profile.isVegetarian;
    _deliveryEnabled = profile.deliveryEnabled;
    _latitude = profile.latitude;
    _longitude = profile.longitude;
    if (profile.pricePreference == 'LOW') _priceRange = 0;
    else if (profile.pricePreference == 'MEDIUM') _priceRange = 1;
    else if (profile.pricePreference == 'HIGH') _priceRange = 2;
    _isLoading = false;
  }

  void _markChanged() {
    if (!_hasChanges) setState(() => _hasChanges = true);
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;
    final should = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Discard Changes?', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text('You have unsaved changes. Do you want to discard them?', style: GoogleFonts.poppins()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Discard', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    return should ?? false;
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    
    final payload = {
      'nameEn': _nameEnCtrl.text,
      'nameMm': _nameMmCtrl.text,
      'nameTh': _nameThCtrl.text,
      'descriptionEn': _descEnCtrl.text,
      'descriptionMm': _descMmCtrl.text,
      'descriptionTh': _descThCtrl.text,
      'categoryEn': _catEnCtrl.text,
      'categoryMm': _catMmCtrl.text,
      'categoryTh': _catThCtrl.text,
      'subCategoryEn': _subCatEnCtrl.text,
      'subCategoryMm': _subCatMmCtrl.text,
      'subCategoryTh': _subCatThCtrl.text,
      'phone': _phoneCtrl.text,
      'email': _emailCtrl.text,
      'addressEn': _addressEnCtrl.text,
      'addressMm': _addressMmCtrl.text,
      'addressTh': _addressThCtrl.text,
      'districtEn': _districtCtrl.text,
      'cityEn': _cityCtrl.text,
      'googleMapsLink': _mapsLinkCtrl.text,
      'baseDeliveryFee': double.tryParse(_baseFeeCtrl.text) ?? 0.0,
      'minOrderAmount': double.tryParse(_minAmountCtrl.text) ?? 0.0,
      'maxItemQuantityPerOrder': int.tryParse(_maxQtyCtrl.text) ?? 10,
      'hasParking': _hasParking,
      'hasWifi': _hasWifi,
      'hasDelivery': _hasDelivery,
      'isHalal': _isHalal,
      'isVegetarian': _isVegetarian,
      'deliveryEnabled': _deliveryEnabled,
      'pricePreference': _priceRange == 0 ? 'LOW' : (_priceRange == 1 ? 'MEDIUM' : 'HIGH'),
      if (_pickedCover != null) 'coverUrl': _pickedCover!.path,
      if (_pickedLogo != null) 'logoUrl': _pickedLogo!.path,
    };

    final success = await _profileService.updateShopProfile(payload);
    
    if (success && mounted) {
      setState(() {
        _isSaving = false;
        _hasChanges = false;
        _pickedCover = null;
        _pickedLogo = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Profile saved successfully',
            style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          backgroundColor: const Color(0xFFED3973),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(20),
        ),
      );
      Navigator.pop(context, true);
    } else if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to save profile. Please try again.',
            style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(20),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: Text('Edit Profile', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
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
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () async {
              final should = await _onWillPop();
              if (should && mounted) Navigator.pop(context);
            },
          ),
          title: Text(
            'Edit Profile',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1E293B),
            ),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            _buildCoverLogoUpload(),
            const SizedBox(height: 20),

            _buildSectionTitle('Basic Information'),
            const SizedBox(height: 16),
            _buildSection(
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
              ),
            ),
            const SizedBox(height: 24),
            // _buildSection(
            //   label: 'Shop Slug (Read-only)',
            //   child: _buildTextField(
            //     TextEditingController(text: _currentProfile?.slug ?? '-'),
            //     'slug',
            //     icon: PhosphorIconsRegular.link,
            //     enabled: false,
            //   ),
            // ),
            // const SizedBox(height: 24),
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
              ),
            ),
            const SizedBox(height: 32),
            _buildSectionTitle('Category'),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildSearchableField(
                label: 'Shop Category',
                value: _catEnCtrl.text.isNotEmpty ? _catEnCtrl.text : null,
                placeholder: 'Select Category',
                onTap: () => _showSearchableSelect<Map<String, dynamic>>(
                  title: 'Select Category',
                  items: _shopCategories,
                  labelMapper: (c) => c['nameEn'] as String,
                  onSelected: (c) => setState(() {
                    _selectedCategoryId = c['id'] as int;
                    _selectedSubCategoryId = null;
                    _catEnCtrl.text = c['nameEn'] as String;
                    _catMmCtrl.text = c['nameMm'] as String;
                    _catThCtrl.text = c['nameTh'] as String;
                    _subCatEnCtrl.clear();
                    _subCatMmCtrl.clear();
                    _subCatThCtrl.clear();
                    _markChanged();
                  }),
                ),
                onClear: () => setState(() {
                  _selectedCategoryId = null;
                  _selectedSubCategoryId = null;
                  _catEnCtrl.clear();
                  _catMmCtrl.clear();
                  _catThCtrl.clear();
                  _subCatEnCtrl.clear();
                  _subCatMmCtrl.clear();
                  _subCatThCtrl.clear();
                }),
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildSearchableField(
                label: 'Sub-category',
                value: _subCatEnCtrl.text.isNotEmpty ? _subCatEnCtrl.text : null,
                placeholder: _selectedCategoryId == null
                    ? 'Select a category first'
                    : 'Select Sub-category',
                onTap: _selectedCategoryId == null
                    ? () {}
                    : () {
                        final subs = _shopSubCategories
                            .where((s) => s['categoryId'] == _selectedCategoryId)
                            .toList();
                        _showSearchableSelect<Map<String, dynamic>>(
                          title: 'Select Sub-category',
                          items: subs,
                          labelMapper: (s) => s['nameEn'] as String,
                          onSelected: (s) => setState(() {
                            _selectedSubCategoryId = s['id'] as int;
                            _subCatEnCtrl.text = s['nameEn'] as String;
                            _subCatMmCtrl.text = s['nameMm'] as String;
                            _subCatThCtrl.text = s['nameTh'] as String;
                            _markChanged();
                          }),
                        );
                      },
                onClear: _selectedCategoryId == null
                    ? null
                    : () => setState(() {
                          _selectedSubCategoryId = null;
                          _subCatEnCtrl.clear();
                          _subCatMmCtrl.clear();
                          _subCatThCtrl.clear();
                        }),
              ),
            ),
            const SizedBox(height: 32),
            _buildSectionTitle('Contact Details'),
            const SizedBox(height: 16),
            _buildSection(
              label: 'Phone Number',
              child: _buildTextField(
                _phoneCtrl,
                '+95 9 XXX XXX XXX',
                icon: PhosphorIconsRegular.phone,
              ),
            ),
            const SizedBox(height: 24),
            _buildSection(
              label: 'Email Address',
              child: _buildTextField(
                _emailCtrl,
                'shop@example.com',
                icon: PhosphorIconsRegular.envelope,
              ),
            ),
            const SizedBox(height: 32),
            _buildSectionTitle('Location'),
            const SizedBox(height: 16),
            _buildSection(
              label: 'Street Address',
              child: _buildLangField(
                selectedLang: _addressLang,
                onLangChanged: (l) => setState(() => _addressLang = l),
                controller: _addressLang == 'EN'
                    ? _addressEnCtrl
                    : _addressLang == 'MM'
                    ? _addressMmCtrl
                    : _addressThCtrl,
                hint: 'Enter street address',
              ),
            ),
            const SizedBox(height: 24),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _buildSearchableField(
                      label: 'City',
                      value: _cityCtrl.text.isNotEmpty ? _cityCtrl.text : null,
                      placeholder: 'Select City',
                      onTap: () => _showSearchableSelect<String>(
                        title: 'Select City',
                        items: ThailandAddressData.provinces,
                        labelMapper: (c) => c,
                        onSelected: (c) => setState(() {
                          _cityCtrl.text = c;
                          _districtCtrl.clear(); // Clear district on city change
                          _markChanged();
                        }),
                      ),
                      onClear: () => setState(() {
                        _cityCtrl.clear();
                        _districtCtrl.clear();
                      }),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildSearchableField(
                      label: 'District',
                      value: _districtCtrl.text.isNotEmpty ? _districtCtrl.text : null,
                      placeholder: 'Select District',
                      onTap: () {
                        final availableDistricts = ThailandAddressData.districtsByProvince[_cityCtrl.text] ?? [];
                        _showSearchableSelect<String>(
                          title: 'Select District',
                          items: availableDistricts,
                          labelMapper: (d) => d,
                          onSelected: (d) => setState(() {
                            _districtCtrl.text = d;
                            _markChanged();
                          }),
                        );
                      },
                      onClear: () => setState(() => _districtCtrl.clear()),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            _buildSection(
              label: 'Google Maps Link',
              child: _buildTextField(_mapsLinkCtrl, 'Paste Google Maps URL', icon: PhosphorIconsRegular.mapPin),
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
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                   Expanded(
                    child: _buildSmallField(
                      label: 'Base Delivery Fee',
                      controller: _baseFeeCtrl,
                      hint: '0.00',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(child: SizedBox()),
                ],
              ),
            ),
            const SizedBox(height: 32),

            _buildSection(
              label: 'Order Settings',
              child: Column(
                children: [
                  _buildSmallField(
                    label: 'Min Order Amount',
                    controller: _minAmountCtrl,
                    hint: '0.00',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  _buildSmallField(
                    label: 'Max Items per Order',
                    controller: _maxQtyCtrl,
                    hint: '10',
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            _buildSection(
              label: 'Map Location',
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    const PhosphorIcon(
                      PhosphorIconsRegular.mapPin,
                      size: 20,
                      color: Color(0xFFED3973),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_latitude?.toStringAsFixed(4) ?? "16.8409"}° N, '
                            '${_longitude?.toStringAsFixed(4) ?? "96.1735"}° E',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF1E293B),
                            ),
                          ),
                          Text(
                            'Current pin location',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: const Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _markChanged,
                      icon: const PhosphorIcon(
                        PhosphorIconsRegular.pencilSimple,
                        size: 14,
                        color: Color(0xFF475569),
                      ),
                      label: Text(
                        'Reposition',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: const Color(0xFF475569),
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
              top: BorderSide(color: Colors.black.withOpacity(0.05)),
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
                      ? const CustomLoadingIndicator(size: 24, color: Colors.white)
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

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF94A3B8),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSearchableField({
    required String label,
    String? value,
    required String placeholder,
    required VoidCallback onTap,
    VoidCallback? onClear,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1E293B),
          ),
        ),
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
                if (value != null && onClear != null)
                  GestureDetector(
                    onTap: onClear,
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
          Positioned(
            top: 0, left: 0, right: 0,
            height: heroHeight,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
              child: GestureDetector(
                onTap: _pickCover,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                  if (_pickedCover != null)
                    kIsWeb
                        ? Image.network(_pickedCover!.path, fit: BoxFit.cover)
                        : Image.file(File(_pickedCover!.path), fit: BoxFit.cover)
                  else if (coverUrl != null && coverUrl.isNotEmpty)
                    _buildImage(coverUrl, fit: BoxFit.cover, fallback: _buildCoverGradient())
                  else
                    _buildCoverGradient(),

                  Positioned(
                    top: 0, left: 0, right: 0, height: 90,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.35),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),

                  if (_pickedCover == null && (coverUrl == null || coverUrl.isEmpty))
                    Container(
                      color: Colors.black.withOpacity(0.15),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.25),
                                shape: BoxShape.circle,
                              ),
                              child: const PhosphorIcon(PhosphorIconsRegular.camera, size: 28, color: Colors.white),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Tap to add cover photo',
                              style: GoogleFonts.poppins(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
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
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
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
                                    ? Image.network(_pickedLogo!.path, fit: BoxFit.cover)
                                    : Image.file(File(_pickedLogo!.path), fit: BoxFit.cover))
                                : (logoUrl != null && logoUrl.isNotEmpty
                                    ? _buildImage(logoUrl, fit: BoxFit.cover, fallback: _buildLogoPlaceholder())
                                    : _buildLogoPlaceholder()),
                          ),
                        ),
                        Positioned(
                          bottom: 0, right: 0,
                          child: Container(
                            width: 22, height: 22,
                            decoration: BoxDecoration(
                              color: const Color(0xFFED3973),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(Icons.camera_alt, size: 11, color: Colors.white),
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

  Widget _buildImage(String url, {required BoxFit fit, required Widget fallback}) {
    if (url.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: url,
        fit: fit,
        placeholder: (_, _) => fallback,
        errorWidget: (_, _, _) => fallback,
      );
    } else {
      // Local file path
      return kIsWeb
          ? Image.network(url, fit: fit, errorBuilder: (_, __, ___) => fallback)
          : Image.file(File(url), fit: fit, errorBuilder: (_, __, ___) => fallback);
    }
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
        child: PhosphorIcon(PhosphorIconsRegular.storefront, size: 26, color: Colors.white),
      ),
    );
  }

  void _viewImage(String title, {String? url, String? path}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FullscreenImageViewer(title: title, imageUrl: url, imagePath: path),
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
    final hasImage = _pickedCover != null || (coverUrl != null && coverUrl.isNotEmpty);
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
    if (result.file != null) {
      setState(() {
        _pickedCover = result.file;
        _hasChanges = true;
      });
    }
  }

  Future<void> _pickLogo() async {
    final logoUrl = _currentProfile?.logoUrl;
    final hasImage = _pickedLogo != null || (logoUrl != null && logoUrl.isNotEmpty);
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
        title: Text('Permission Required', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16)),
        content: Text('Photo library access is required. Please enable it in Settings.', style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF475569))),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text('Cancel', style: GoogleFonts.poppins(color: const Color(0xFF475569)))),
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text('Open Settings', style: GoogleFonts.poppins(color: const Color(0xFFED3973), fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  Widget _buildSection({required String label, required Widget child, EdgeInsets? padding}) {
    return Padding(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF475569))),
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
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: ['EN', 'MM', 'TH'].map((lang) {
            final selected = selectedLang == lang;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => onLangChanged(lang),
                child: Container(
                  constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: selected ? const Color(0xFFED3973) : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: selected ? const Color(0xFFED3973) : const Color(0xFFE2E8F0)),
                  ),
                  child: Text(lang, style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: selected ? Colors.white : const Color(0xFF64748B))),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: controller,
          maxLines: maxLines,
          onChanged: (_) => _markChanged(),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.poppins(color: const Color(0xFFCBD5E1), fontSize: 14),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFED3973), width: 1.5)),
          ),
          style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF1E293B)),
        ),
      ],
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String hint, {IconData? icon, bool enabled = true}) {
    return TextField(
      controller: ctrl,
      enabled: enabled,
      onChanged: (_) => _markChanged(),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(color: const Color(0xFFCBD5E1), fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        prefixIcon: icon != null ? PhosphorIcon(icon, size: 18, color: const Color(0xFF94A3B8)) : null,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFED3973), width: 1.5)),
      ),
      style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF1E293B)),
    );
  }

  Widget _buildToggleSection({required String title, required List<_ToggleItem> items}) {
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
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  child: Row(
                    children: [
                      PhosphorIcon(item.icon, size: 20, color: const Color(0xFF475569)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          item.label,
                          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFF1E293B)),
                        ),
                      ),
                      SizedBox(
                        height: 24,
                        child: Transform.scale(
                          scale: 0.65,
                          child: Switch(
                            value: item.value,
                            onChanged: item.onChanged,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            thumbColor: WidgetStateProperty.all(Colors.white),
                            trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
                            trackColor: WidgetStateProperty.resolveWith((states) {
                              if (states.contains(WidgetState.selected)) return const Color(0xFFED3973);
                              return const Color(0xFFE2E8F0);
                            }),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (i < items.length - 1)
                  const Divider(height: 1, color: Color(0xFFE2E8F0), indent: 14, endIndent: 14),
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
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: const Color(0xFF64748B)),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          onChanged: (_) => _markChanged(),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.poppins(color: const Color(0xFFCBD5E1), fontSize: 14),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFED3973), width: 1.5)),
          ),
          style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF1E293B)),
        ),
      ],
    );
  }
}

class _ToggleItem {
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _ToggleItem({required this.icon, required this.label, required this.value, required this.onChanged});
}

class _PriceOption extends StatelessWidget {
  final String label;
  final int index;
  final bool selected;
  final VoidCallback onTap;
  const _PriceOption({required this.label, required this.index, required this.selected, required this.onTap});

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
            style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: selected ? Colors.white : const Color(0xFF64748B)),
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
  const _ImageActionSheet({required this.title, required this.onView, required this.onChange});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40, height: 4,
            decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 17, color: const Color(0xFF1E293B))),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.visibility_outlined, color: Color(0xFFED3973)),
            title: Text('View Image', style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
            onTap: onView,
            contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
          ),
          const Divider(height: 1, indent: 64),
          ListTile(
            leading: const Icon(Icons.camera_alt_outlined, color: Color(0xFFED3973)),
            title: Text('Change Image', style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
            onTap: onChange,
            contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: SizedBox(
              width: double.infinity,
              child: TextButton(onPressed: () => Navigator.of(context).pop(), child: Text('Cancel', style: GoogleFonts.poppins(color: const Color(0xFF64748B)))),
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
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40, height: 4,
            decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Text('Update Shop Logo', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 17, color: const Color(0xFF1E293B))),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined, color: Color(0xFFED3973)),
            title: Text('Choose from Gallery', style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
            onTap: onGallery,
            contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
          ),
          const Divider(height: 1, indent: 64),
          ListTile(
            leading: const Icon(Icons.camera_alt_outlined, color: Color(0xFFED3973)),
            title: Text('Take a Photo', style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
            onTap: onCamera,
            contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: SizedBox(
              width: double.infinity,
              child: TextButton(onPressed: () => Navigator.of(context).pop(), child: Text('Cancel', style: GoogleFonts.poppins(color: const Color(0xFF64748B)))),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchSelectorSheet<T> extends StatefulWidget {
  final String title;
  final List<T> items;
  final String Function(T) labelMapper;
  final Function(T) onSelected;
  const _SearchSelectorSheet({required this.title, required this.items, required this.labelMapper, required this.onSelected});

  @override
  State<_SearchSelectorSheet<T>> createState() => _SearchSelectorSheetState<T>();
}

class _SearchSelectorSheetState<T> extends State<_SearchSelectorSheet<T>> {
  late List<T> _filteredItems;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filteredItems = widget.items;
  }

  void _filterItems(String query) {
    setState(() {
      _filteredItems = widget.items.where((item) => widget.labelMapper(item).toLowerCase().contains(query.toLowerCase())).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40, height: 4,
            decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              children: [
                Text(widget.title, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B))),
                const Spacer(),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: TextField(
              controller: _searchController,
              onChanged: _filterItems,
              decoration: InputDecoration(
                hintText: 'Search...',
                hintStyle: GoogleFonts.poppins(color: const Color(0xFF94A3B8)),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF94A3B8)),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.4),
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              itemCount: _filteredItems.length,
              separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
              itemBuilder: (context, index) {
                final item = _filteredItems[index];
                return ListTile(
                  title: Text(widget.labelMapper(item), style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFF1E293B))),
                  onTap: () {
                    widget.onSelected(item);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
