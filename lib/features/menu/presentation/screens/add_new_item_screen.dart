import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AddNewItemScreen extends StatefulWidget {
  const AddNewItemScreen({super.key});

  @override
  State<AddNewItemScreen> createState() => _AddNewItemScreenState();
}

class _AddNewItemScreenState extends State<AddNewItemScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _itemNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  String? _selectedCategory = 'Recommended';
  String? _selectedAddOnCategory = 'Create New Category';

  @override
  void dispose() {
    _itemNameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Add new items',
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                _buildImageUploadSection(),
                const SizedBox(height: 24),
                _buildSectionLabel('BASIC INFORMATION'),
                const SizedBox(height: 16),
                _buildFieldLabel('Item Name'),
                _buildTextField(
                  controller: _itemNameController,
                  hint: 'Traditional Mohinga',
                ),
                const SizedBox(height: 20),
                _buildFieldLabel('Description'),
                _buildTextField(
                  controller: _descriptionController,
                  hint: 'Describe the dish, ingredients, flavor...',
                  maxLines: 4,
                ),
                const SizedBox(height: 20),
                _buildFieldLabel('Select Category'),
                _buildDropdown(
                  value: _selectedCategory,
                  items: ['Recommended', 'Main Course', 'Appetizer', 'Dessert'],
                  onChanged: (val) => setState(() => _selectedCategory = val),
                ),
                const SizedBox(height: 20),
                _buildFieldLabel('Price'), // Image says "Pirce", using "Price" for correctness
                _buildVariantItem(name: 'Pork', price: '75', isRemovable: true, isPricePink: true),
                const SizedBox(height: 12),
                _buildVariantItem(name: 'Variant name', price: '00', isRemovable: false),
                const SizedBox(height: 12),
                _buildAddVariantButton(),
                const SizedBox(height: 32),
                _buildAddOnSection(),
                const SizedBox(height: 40),
                _buildSaveButton(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageUploadSection() {
    // In a real app, this would check if an image is selected
    bool hasImage = true; 

    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(24),
        image: hasImage ? const DecorationImage(
          image: NetworkImage('https://images.unsplash.com/photo-1512621776951-a57141f2eefd?q=80&w=2070&auto=format&fit=crop'),
          fit: BoxFit.cover,
        ) : null,
        border: hasImage ? null : Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1.5,
          style: BorderStyle.solid, 
        ),
      ),
      child: Stack(
        children: [
          if (!hasImage)
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
                  const SizedBox(height: 16),
                  Text(
                    'Tap to upload',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'or take a photo of your receipt',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          if (hasImage)
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.refresh,
                  color: Color(0xFF1E293B),
                  size: 20,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF94A3B8),
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _buildFieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: const Color(0xFF64748B),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF1E293B)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(color: const Color(0xFF94A3B8), fontSize: 13),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
          borderSide: const BorderSide(color: Color(0xFFED3973), width: 1),
        ),
      ),
    );
  }

  Widget _buildVariantItem({
    required String name, 
    required String price, 
    required bool isRemovable,
    bool isPricePink = false,
  }) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Text(
              name,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: name == 'Variant name' ? const Color(0xFF94A3B8) : const Color(0xFF1E293B),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '฿',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isPricePink ? const Color(0xFFED3973) : const Color(0xFF1E293B),
                  ),
                ),
                Text(
                  price,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: isPricePink ? const Color(0xFFED3973) : (price == '00' ? const Color(0xFF94A3B8) : const Color(0xFF1E293B)),
                    fontWeight: isPricePink ? FontWeight.w500 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (isRemovable) ...[
          const SizedBox(width: 8),
          Container(
            height: 52,
            width: 58,
            decoration: BoxDecoration(
              color: const Color(0xFFE15252),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.delete_outline, color: Colors.white, size: 24),
          ),
        ],
      ],
    );
  }

  Widget _buildAddOnSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionLabel('ADD ON'),
          const SizedBox(height: 16),
          _buildFieldLabel('Select Add_on Category'),
          _buildDropdown(
            value: _selectedAddOnCategory,
            items: ['Create New Category', 'Drink', 'Side Dish'],
            onChanged: (val) => setState(() => _selectedAddOnCategory = val),
          ),
          const SizedBox(height: 20),
          _buildFieldLabel('Add_on list'),
          _buildAddOnListItem(name: 'Extra meat', price: '+ 25'),
          const SizedBox(height: 12),
          _buildAddOnListItem(name: 'Egg', price: '+ 15'),
          const SizedBox(height: 12),
          _buildAddOnListItem(name: 'Variant name', price: '+0000', isHint: true),
          const SizedBox(height: 16),
          _buildAddNewOptionsButton(),
        ],
      ),
    );
  }

  Widget _buildAddOnListItem({required String name, required String price, bool isHint = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              name,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: isHint ? const Color(0xFF94A3B8) : const Color(0xFF1E293B),
              ),
            ),
          ),
          Text(
            '฿ $price',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isHint ? const Color(0xFF94A3B8) : const Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF64748B)),
          onChanged: onChanged,
          items: items.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(
                value,
                style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF1E293B)),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildAddVariantButton() {
    return TextButton.icon(
      onPressed: () {},
      icon: const Icon(Icons.add, size: 20, color: Color(0xFFED3973)),
      label: Text(
        'Add variant',
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: const Color(0xFFED3973),
        ),
      ),
      style: TextButton.styleFrom(
        padding: EdgeInsets.zero,
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  Widget _buildAddNewOptionsButton() {
    return TextButton.icon(
      onPressed: () {},
      icon: const Icon(Icons.add, size: 20, color: Color(0xFFED3973)),
      label: Text(
        'Add new options',
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: const Color(0xFFED3973),
        ),
      ),
      style: TextButton.styleFrom(
        padding: EdgeInsets.zero,
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: () {
          if (_formKey.currentState?.validate() ?? false) {
            // Save logic
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFED3973),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Text(
          'Save',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
