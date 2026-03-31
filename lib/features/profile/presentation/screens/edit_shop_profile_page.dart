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
import 'package:my_shop/core/network/api_client.dart';
import 'package:my_shop/core/presentation/widgets/custom_loading_indicator.dart';
import 'package:my_shop/core/presentation/widgets/fullscreen_image_viewer.dart';
import 'package:my_shop/features/profile/data/models/shop_profile_model.dart';
import 'package:my_shop/features/profile/data/services/profile_service.dart';

class EditShopProfilePage extends StatefulWidget {
  final ShopProfileModel? shopProfile;
  const EditShopProfilePage({super.key, this.shopProfile});

  @override
  State<EditShopProfilePage> createState() => _EditShopProfilePageState();
}

class _EditShopProfilePageState extends State<EditShopProfilePage> {
  bool _hasChanges = false;
  bool _isSaving = false;

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
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _addressEnCtrl;
  late final TextEditingController _addressMmCtrl;
  late final TextEditingController _addressThCtrl;
  late final TextEditingController _districtCtrl;
  late final TextEditingController _cityCtrl;

  double? _latitude;
  double? _longitude;

  late bool _hasParking;
  late bool _hasWifi;
  late bool _hasDelivery;
  late bool _isHalal;
  late bool _isVegetarian;
  late int _priceRange;

  @override
  void initState() {
    super.initState();
    final p = widget.shopProfile;

    _nameEnCtrl = TextEditingController(text: p?.nameEn ?? '');
    _nameMmCtrl = TextEditingController(text: p?.nameMm ?? '');
    _nameThCtrl = TextEditingController(text: p?.nameTh ?? '');
    _descEnCtrl = TextEditingController(text: p?.descriptionEn ?? '');
    _descMmCtrl = TextEditingController(text: p?.descriptionMm ?? '');
    _descThCtrl = TextEditingController(text: p?.descriptionTh ?? '');
    _phoneCtrl = TextEditingController(text: p?.phone ?? '');
    _emailCtrl = TextEditingController(text: p?.email ?? '');
    _addressEnCtrl = TextEditingController(text: p?.addressEn ?? '');
    _addressMmCtrl = TextEditingController(text: p?.addressMm ?? '');
    _addressThCtrl = TextEditingController(text: p?.addressTh ?? '');
    _districtCtrl = TextEditingController(text: p?.districtEn ?? '');
    _cityCtrl = TextEditingController(text: p?.cityEn ?? '');

    _latitude = p?.latitude;
    _longitude = p?.longitude;

    _hasParking = p?.hasParking ?? false;
    _hasWifi = p?.hasWifi ?? false;
    _hasDelivery = p?.hasDelivery ?? false;
    _isHalal = p?.isHalal ?? false;
    _isVegetarian = p?.isVegetarian ?? false;

    _priceRange = 1;
    if (p?.pricePreference == 'LOW') _priceRange = 0;
    if (p?.pricePreference == 'HIGH') _priceRange = 2;
  }

  @override
  void dispose() {
    for (final c in [
      _nameEnCtrl,
      _nameMmCtrl,
      _nameThCtrl,
      _descEnCtrl,
      _descMmCtrl,
      _descThCtrl,
      _phoneCtrl,
      _emailCtrl,
      _addressEnCtrl,
      _addressMmCtrl,
      _addressThCtrl,
      _districtCtrl,
      _cityCtrl,
    ]) {
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

  Future<void> _save() async {
    setState(() => _isSaving = true);

    String pricePref = 'MEDIUM';
    if (_priceRange == 0) pricePref = 'LOW';
    if (_priceRange == 2) pricePref = 'HIGH';

    if (_pickedCover != null) {
      try {
        final formData = FormData.fromMap({
          'cover': kIsWeb
              ? MultipartFile.fromBytes(
                  await _pickedCover!.readAsBytes(),
                  filename: _pickedCover!.name,
                )
              : await MultipartFile.fromFile(
                  _pickedCover!.path,
                  filename: _pickedCover!.name,
                ),
        });
        await ApiClient().dio.post('/api/shop/profile/cover', data: formData);
      } catch (e) {
        debugPrint('Cover upload error: $e');
      }
    }

    if (_pickedLogo != null) {
      try {
        final formData = FormData.fromMap({
          'logo': kIsWeb
              ? MultipartFile.fromBytes(
                  await _pickedLogo!.readAsBytes(),
                  filename: _pickedLogo!.name,
                )
              : await MultipartFile.fromFile(
                  _pickedLogo!.path,
                  filename: _pickedLogo!.name,
                ),
        });
        await ApiClient().dio.post('/api/shop/profile/logo', data: formData);
      } catch (e) {
        debugPrint('Logo upload error: $e');
      }
    }

    final payload = {
      'nameEn': _nameEnCtrl.text,
      'nameMm': _nameMmCtrl.text,
      'nameTh': _nameThCtrl.text,
      'descriptionEn': _descEnCtrl.text,
      'descriptionMm': _descMmCtrl.text,
      'descriptionTh': _descThCtrl.text,
      'phone': _phoneCtrl.text,
      'email': _emailCtrl.text,
      'addressEn': _addressEnCtrl.text,
      'addressMm': _addressMmCtrl.text,
      'addressTh': _addressThCtrl.text,
      'districtEn': _districtCtrl.text,
      'districtMm': _districtCtrl.text,
      'districtTh': _districtCtrl.text,
      'cityEn': _cityCtrl.text,
      'cityMm': _cityCtrl.text,
      'cityTh': _cityCtrl.text,
      'latitude': _latitude ?? 16.8409,
      'longitude': _longitude ?? 96.1735,
      'hasParking': _hasParking,
      'hasWifi': _hasWifi,
      'hasDelivery': _hasDelivery,
      'isHalal': _isHalal,
      'isVegetarian': _isVegetarian,
      'pricePreference': pricePref,
    };

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

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
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
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            // ── FIXED: Hero cover + floating info card ──────────────────
            _buildCoverLogoUpload(),

            const SizedBox(height: 20),

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
            const SizedBox(height: 16),

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
            const SizedBox(height: 16),

            _buildSection(
              label: 'Phone Number',
              child: _buildTextField(
                _phoneCtrl,
                '+95 9 XXX XXX XXX',
                icon: PhosphorIconsRegular.phone,
              ),
            ),
            const SizedBox(height: 16),

            _buildSection(
              label: 'Email',
              child: _buildTextField(
                _emailCtrl,
                'shop@example.com',
                icon: PhosphorIconsRegular.envelope,
              ),
            ),
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
            const SizedBox(height: 16),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _buildSection(
                      label: 'District',
                      child: _buildTextField(_districtCtrl, 'District'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSection(
                      label: 'City',
                      child: _buildTextField(_cityCtrl, 'City'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

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
    final coverUrl = widget.shopProfile?.coverUrl;
    final logoUrl = widget.shopProfile?.logoUrl;
    final shopName = _nameEnCtrl.text.isNotEmpty
        ? _nameEnCtrl.text
        : (widget.shopProfile?.nameEn ?? 'Shop Name');

    return Column(
      children: [
        // ── Hero image (tap to change cover) ─────────────────────────────
        GestureDetector(
          onTap: _pickCover,
          child: SizedBox(
            height: 240,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Image or gradient fallback
                if (_pickedCover != null)
                  kIsWeb
                      ? Image.network(_pickedCover!.path, fit: BoxFit.cover)
                      : Image.file(File(_pickedCover!.path), fit: BoxFit.cover)
                else if (coverUrl != null && coverUrl.isNotEmpty)
                  CachedNetworkImage(
                    imageUrl: coverUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, _) => _buildCoverGradient(),
                    errorWidget: (_, _, _) => _buildCoverGradient(),
                  )
                else
                  _buildCoverGradient(),

                // Dark overlay at top for status bar/back button contrast
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

                // Camera hint overlay when no cover photo
                if (_pickedCover == null &&
                    (coverUrl == null || coverUrl.isEmpty))
                  Container(
                    color: Colors.black.withValues(alpha: 0.2),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.25),
                              shape: BoxShape.circle,
                            ),
                            child: const PhosphorIcon(
                              PhosphorIconsRegular.camera,
                              size: 26,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tap to add cover photo',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 13,
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

        Transform.translate(
          offset: const Offset(0, -20),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 20,
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
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
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
                                placeholder: (_, _) => _buildLogoPlaceholder(),
                                errorWidget: (_, _, _) =>
                                    _buildLogoPlaceholder(),
                              )
                            : _buildLogoPlaceholder(),
                      ),
                    ),
                    // Camera badge
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
              // Shop name
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
    final coverUrl = widget.shopProfile?.coverUrl;
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
    if (result.file != null) {
      setState(() {
        _pickedCover = result.file;
        _hasChanges = true;
      });
    }
  }

  Future<void> _pickLogo() async {
    final logoUrl = widget.shopProfile?.logoUrl;
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
    required String label,
    required Widget child,
    EdgeInsets? padding,
  }) {
    return Padding(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 8),
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
        const SizedBox(height: 8),
        Row(
          children: ['EN', 'MM', 'TH'].map((lang) {
            final selected = selectedLang == lang;
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
                  child: Text(
                    lang,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: selected ? Colors.white : const Color(0xFF64748B),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          onChanged: (_) => _markChanged(),
          decoration: InputDecoration(
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
  }) {
    return TextField(
      controller: ctrl,
      onChanged: (_) => _markChanged(),
      decoration: InputDecoration(
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
