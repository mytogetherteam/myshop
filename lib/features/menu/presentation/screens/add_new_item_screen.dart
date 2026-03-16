import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
  
  // Controllers
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;
  
  List<MenuCategoryModel> _categories = [];
  MenuCategoryModel? _selectedCategory;
  bool _isLoadingCategories = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item?.nameEn ?? widget.item?.nameMm ?? widget.item?.nameTh ?? '');
    _descriptionController = TextEditingController(text: widget.item?.descriptionEn ?? widget.item?.description ?? '');
    _priceController = TextEditingController(text: widget.item?.price.toString() ?? '');
    
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    setState(() => _isLoadingCategories = true);
    final categories = await _menuService.getCategories();
    if (mounted) {
      setState(() {
        _categories = categories ?? [];
        _isLoadingCategories = false;
        if (widget.item != null && _categories.isNotEmpty) {
          try {
            _selectedCategory = _categories.firstWhere(
              (c) => c.id == widget.item?.categoryId,
            );
          } catch (_) {
            _selectedCategory = _categories.isNotEmpty ? _categories.first : null;
          }
        } else if (_categories.isNotEmpty) {
          _selectedCategory = _categories.first;
        }
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSaving = true);
    
    final payload = {
      'nameEn': _nameController.text,
      'descriptionEn': _descriptionController.text,
      'price': double.tryParse(_priceController.text) ?? 0.0,
      'categoryId': _selectedCategory?.id,
      'isAvailable': widget.item?.isAvailable ?? true,
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
          SnackBar(
            content: Text(widget.item != null ? 'Item updated successfully' : 'Item created successfully'),
            backgroundColor: const Color(0xFF22C55E),
          ),
        );
        Navigator.pop(context, true); // Return true to indicate change
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1E293B), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.item != null ? widget.item!.displayName : 'Add new items',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1E293B),
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoadingCategories 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFFED3973)))
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
                  
                  // Basic Information Section
                  _buildSectionTitle('BASIC INFORMATION'),
                  const SizedBox(height: 16),
                  _buildTextField('Item Name', _nameController, hint: 'Enter item name'),
                  const SizedBox(height: 16),
                  _buildTextField('Description', _descriptionController, hint: 'What is your menu description?', isMultiline: true),
                  const SizedBox(height: 16),
                  _buildCategoryDropdown(),
                  const SizedBox(height: 16),
                  _buildTextField('Main Price', _priceController, hint: 'Enter price (e.g. 100)', keyboardType: TextInputType.number),
                  
                  const SizedBox(height: 32),
                  
                  // Variants Section (Static for now as per design placeholder)
                  _buildSectionTitle('VARIANT'),
                  const SizedBox(height: 16),
                  _buildVariantItem('Chicken Zinger Burger', '75'),
                  _buildVariantItem('Beef Patty Burger', '115'),
                  TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                    child: Text(
                      '+ Add Variant',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFED3973),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Add On Section
                  _buildSectionTitle('ADD ON'),
                  const SizedBox(height: 16),
                  _buildAddOnSection(),
                  
                  const SizedBox(height: 40),
                  _buildSaveButton(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF94A3B8),
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildImageUploadSection() {
    String? imageUrl = widget.item?.imageUrl;

    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(24),
        image: imageUrl != null ? DecorationImage(
          image: NetworkImage(imageUrl),
          fit: BoxFit.cover,
        ) : null,
        border: imageUrl != null ? null : Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1.5,
          style: BorderStyle.solid, 
        ),
      ),
      child: Stack(
        children: [
          if (imageUrl == null)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFED3973).withValues(alpha: 0.1), width: 1),
                      color: Colors.white,
                    ),
                    child: const Icon(
                      Icons.camera_alt_outlined,
                      color: Color(0xFFED3973),
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Tap to upload',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'or take a photo of your receipt',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
          Positioned(
            right: 16,
            bottom: 16,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.refresh, color: Color(0xFFED3973), size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {String? hint, bool isMultiline = false, TextInputType? keyboardType}) {
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
          maxLines: isMultiline ? 3 : 1,
          keyboardType: keyboardType,
          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.poppins(color: const Color(0xFF94A3B8), fontSize: 13),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            prefixIcon: keyboardType == TextInputType.number 
              ? Padding(
                  padding: const EdgeInsets.only(left: 16, right: 8, top: 14),
                  child: Text('฿', style: GoogleFonts.poppins(color: const Color(0xFF94A3B8), fontSize: 14, fontWeight: FontWeight.w600)),
                )
              : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter $label';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildCategoryDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category',
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
            child: DropdownButton<MenuCategoryModel>(
              value: _selectedCategory,
              isExpanded: true,
              hint: Text('Select category', style: GoogleFonts.poppins(color: const Color(0xFF94A3B8), fontSize: 13)),
              items: _categories.map((c) {
                return DropdownMenuItem(
                  value: c,
                  child: Text(c.displayName, style: GoogleFonts.poppins(fontSize: 14)),
                );
              }).toList(),
              onChanged: (value) => setState(() => _selectedCategory = value),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVariantItem(String name, String price) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0), width: 0.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: const Color(0xFF64748B)),
                  ),
                  Row(
                    children: [
                      Text(
                        '฿ ',
                        style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: const Color(0xFF94A3B8)),
                      ),
                      Text(
                        price,
                        style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFFED3973)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFED3973),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.delete_outline, color: Colors.white, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildAddOnSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('Select Add_on Category'),
        const SizedBox(height: 8),
        _buildDropdownContainer(
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: 'Create New Category',
              isExpanded: true,
              style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF1E293B)),
              items: ['Create New Category'].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (_) {},
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildSectionLabel('Add_on list'),
        const SizedBox(height: 8),
        _buildAddOnItem('Extra Cheese', '10'),
        _buildAddOnItem('Bacon Strips', '35'),
        const SizedBox(height: 12),
        _buildVariantItem('Add_on name', '0000'),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () {},
          style: TextButton.styleFrom(padding: EdgeInsets.zero),
          child: Text(
            '+ Add new options',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: const Color(0xFFED3973),
            ),
          ),
        ),
      ],
    );
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

  Widget _buildDropdownContainer({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }

  Widget _buildAddOnItem(String name, String price) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 0.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              name,
              style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF64748B)),
            ),
            Row(
              children: [
                Text(
                  '฿ ',
                  style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: const Color(0xFF94A3B8)),
                ),
                Text(
                  price,
                  style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B)),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.delete_outline, color: Color(0xFFEF4444), size: 18),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isSaving ? null : _handleSave,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFED3973),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: _isSaving 
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : Text(
                  widget.item != null ? 'Update' : 'Save',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
          ),
        ),
        if (widget.item != null) ...[
          const SizedBox(height: 12),
          Text(
            'Changes will take effect tomorrow',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF94A3B8),
            ),
          ),
        ],
      ],
    );
  }
}
