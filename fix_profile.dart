import 'dart:io';

void main() {
  final file = File('/Applications/XAMPP/xamppfiles/htdocs/MyTogether/myshop/lib/features/profile/presentation/screens/edit_shop_profile_page.dart');
  var content = file.readAsStringSync();

  // 1. Add imports
  if (!content.contains("import 'package:my_shop/core/data/models/master_data_model.dart';")) {
    content = content.replaceFirst("import 'package:my_shop/features/profile/data/services/profile_service.dart';", "import 'package:my_shop/features/profile/data/services/profile_service.dart';\nimport 'package:my_shop/core/data/models/master_data_model.dart';\nimport 'package:my_shop/core/data/services/master_data_service.dart';");
  }

  // 2. Add state vars
  final stateVars = '''
  ShopProfileModel? _currentProfile;

  List<MasterDataModel> _categories = [];
  List<MasterDataModel> _subcategories = [];
  List<MasterDataModel> _cities = [];

  MasterDataModel? _selectedCategory;
  MasterDataModel? _selectedSubcategory;
  MasterDataModel? _selectedCity;
  
  final MasterDataService _masterDataService = MasterDataService();
''';
  content = content.replaceFirst("ShopProfileModel? _currentProfile;", stateVars);

  // 3. Add fetch logic
  final fetchLogic = '''
  Future<void> _fetchMasterData() async {
    final futures = await Future.wait([
      _masterDataService.getShopCategories(),
      _masterDataService.getShopSubcategories(),
      _masterDataService.getCities(),
    ]);

    if (mounted) {
      setState(() {
        _categories = futures[0] ?? [];
        _subcategories = futures[1] ?? [];
        _cities = futures[2] ?? [];
        _setSelectedMasterData();
      });
    }
  }

  void _setSelectedMasterData() {
    if (_currentProfile == null) return;
    
    try {
      if (_currentProfile!.categoryId != null) {
        _selectedCategory = _categories.firstWhere((c) => c.id == _currentProfile!.categoryId);
      } else if (_currentProfile!.categoryEn != null) {
        _selectedCategory = _categories.firstWhere((c) => c.nameEn == _currentProfile!.categoryEn);
      }
    } catch (_) {}

    try {
      if (_currentProfile!.subCategoryId != null) {
        _selectedSubcategory = _subcategories.firstWhere((c) => c.id == _currentProfile!.subCategoryId);
      } else if (_currentProfile!.subCategoryEn != null) {
        _selectedSubcategory = _subcategories.firstWhere((c) => c.nameEn == _currentProfile!.subCategoryEn);
      }
    } catch (_) {}

    try {
      if (_currentProfile!.cityEn != null && _currentProfile!.cityEn!.isNotEmpty) {
        _selectedCity = _cities.firstWhere((c) => c.nameEn == _currentProfile!.cityEn);
      }
    } catch (_) {}
  }

  @override
''';
  content = content.replaceFirst("  @override", fetchLogic);

  // 4. Call fetch logic in initState
  content = content.replaceFirst(
    "_initializeFields(_currentProfile);",
    "_initializeFields(_currentProfile);\n    _fetchMasterData();"
  );

  // 5. Update _loadProfile to set selected master data
  content = content.replaceFirst(
    "_updateControllerTexts(profile);",
    "_updateControllerTexts(profile);\n          _setSelectedMasterData();"
  );

  // 6. Add _buildDropdown helper
  final buildDropdownMsg = '''
  Widget _buildDropdown(
    String label,
    MasterDataModel? value,
    List<MasterDataModel> items,
    String hint,
    ValueChanged<MasterDataModel?> onChanged,
  ) {
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
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<MasterDataModel>(
              value: value,
              isExpanded: true,
              hint: Text(hint, style: GoogleFonts.poppins(color: const Color(0xFF94A3B8), fontSize: 13)),
              items: items.map((c) {
                return DropdownMenuItem(
                  value: c,
                  child: Text(c.displayName, style: GoogleFonts.poppins(fontSize: 14)),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────
''';
  content = content.replaceFirst("  // ── Build ────────────────────────────────────────────────────────────────", buildDropdownMsg);

  file.writeAsStringSync(content);
}
