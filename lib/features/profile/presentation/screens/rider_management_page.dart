import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:my_shop/core/data/services/storage_service.dart';
import 'package:my_shop/core/presentation/widgets/primary_gradient_button.dart';
import 'package:my_shop/core/presentation/widgets/global_modal.dart';
import 'package:my_shop/core/presentation/widgets/app_dialog.dart';
import 'package:my_shop/core/localization/app_localizations.dart';
import 'package:my_shop/features/profile/data/services/rider_service.dart';
import 'package:my_shop/features/profile/data/models/rider_model.dart';
import 'package:my_shop/core/presentation/widgets/image_picker_widget.dart';
import 'package:my_shop/core/utils/app_colors.dart';

class RiderManagementPage extends StatefulWidget {
  const RiderManagementPage({super.key});

  @override
  State<RiderManagementPage> createState() => _RiderManagementPageState();
}

class _RiderManagementPageState extends State<RiderManagementPage> {
  final RiderService _riderService = RiderService();
  bool _isLoading = true;
  List<Rider> _riders = [];
  int? _shopId;
  int? _userId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    _shopId = await StorageService.instance.getSelectedShopId();
    final userInfo = await StorageService.instance.getUserInfo();
    _userId = userInfo?.id;

    if (_shopId != null) {
      _riders = await _riderService.getRiders();
    }
    
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _showRiderForm([Rider? rider]) {
    if (_shopId == null || _userId == null) return;
    GlobalModal.show(
      context: context,
      child: _RiderFormSheet(
        rider: rider,
        shopId: _shopId!,
        userId: _userId!,
        onSaved: () {
          Navigator.pop(context);
          _loadData();
        },
      ),
    );
  }

  Future<void> _deleteRider(int riderId) async {
    final t = AppLocalizations.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t?.translate('delete_rider') ?? 'Delete Rider'),
        content: Text(t?.translate('delete_rider_confirm') ?? 'Are you sure you want to delete this rider?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t?.translate('cancel') ?? 'Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              t?.translate('delete') ?? 'Delete',
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      final success = await _riderService.deleteRider(riderId);
      if (success) {
        if (mounted) {
          AppDialog.showToast(context, t?.translate('rider_deleted') ?? 'Rider deleted successfully');
          _loadData();
        }
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
          AppDialog.showToast(context, t?.translate('failed_delete_rider') ?? 'Failed to delete rider', isError: true);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          t?.translate('rider_management') ?? 'Rider Management',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1E293B),
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: PhosphorIcon(PhosphorIconsRegular.plus, color: AppColors.primary),
            onPressed: () => _showRiderForm(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CupertinoActivityIndicator())
          : _riders.isEmpty
              ? _buildEmptyState(t)
              : RefreshIndicator(
                  onRefresh: _loadData,
                  color: AppColors.primary,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _riders.length,
                    itemBuilder: (context, index) {
                      final rider = _riders[index];
                      return _buildRiderCard(rider);
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState(AppLocalizations? t) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          PhosphorIcon(
            PhosphorIconsRegular.users,
            size: 64,
            color: const Color(0xFFCBD5E1),
          ),
          const SizedBox(height: 16),
          Text(
            t?.translate('no_riders_found') ?? 'No riders found',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            t?.translate('add_rider_desc') ?? 'Add a rider to manage deliveries.',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiderCard(Rider rider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
          child: rider.image != null && rider.image!.isNotEmpty
              ? ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: rider.image!,
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const CupertinoActivityIndicator(radius: 8),
                    errorWidget: (context, url, error) => PhosphorIcon(PhosphorIconsRegular.user, color: AppColors.primary),
                  ),
                )
              : PhosphorIcon(PhosphorIconsRegular.user, color: AppColors.primary),
        ),
        title: Text(
          rider.name,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1E293B),
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (rider.phoneNumber != null && rider.phoneNumber!.isNotEmpty)
              Text(
                rider.phoneNumber!,
                style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF64748B)),
              ),
            if (rider.licensePlate != null && rider.licensePlate!.isNotEmpty)
              Text(
                'Plate: ${rider.licensePlate}',
                style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF64748B)),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const PhosphorIcon(PhosphorIconsRegular.pencilSimple, color: Color(0xFF64748B), size: 20),
              onPressed: () => _showRiderForm(rider),
            ),
            IconButton(
              icon: const PhosphorIcon(PhosphorIconsRegular.trash, color: Colors.red, size: 20),
              onPressed: () => _deleteRider(rider.id),
            ),
          ],
        ),
      ),
    );
  }
}

class _RiderFormSheet extends StatefulWidget {
  final Rider? rider;
  final int shopId;
  final int userId;
  final VoidCallback onSaved;

  const _RiderFormSheet({
    this.rider,
    required this.shopId,
    required this.userId,
    required this.onSaved,
  });

  @override
  State<_RiderFormSheet> createState() => _RiderFormSheetState();
}

class _RiderFormSheetState extends State<_RiderFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _licensePlateController = TextEditingController();
  bool _isLoading = false;
  final RiderService _riderService = RiderService();
  XFile? _pickedImage;

  @override
  void initState() {
    super.initState();
    if (widget.rider != null) {
      _nameController.text = widget.rider!.name;
      _phoneController.text = widget.rider!.phoneNumber ?? '';
      _licensePlateController.text = widget.rider!.licensePlate ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _licensePlateController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final data = {
      'name': _nameController.text,
      'phoneNumber': _phoneController.text,
      'licensePlate': _licensePlateController.text,
      'shopId': widget.shopId,
      'userId': widget.userId,
    };

    final File? imageFile = _pickedImage != null ? File(_pickedImage!.path) : null;

    bool success = false;
    if (widget.rider == null) {
      final newRider = await _riderService.createRider(data, image: imageFile);
      success = newRider != null;
    } else {
      final updatedRider = await _riderService.updateRider(widget.rider!.id, data, image: imageFile);
      success = updatedRider != null;
    }

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        widget.onSaved();
      } else {
        final t = AppLocalizations.of(context);
        AppDialog.showToast(context, t?.translate('failed_save_rider') ?? 'Failed to save rider', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final isEditing = widget.rider != null;

    return Padding(
      // Ensure padding at bottom for keyboard
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Align(
              alignment: Alignment.center,
              child: Container(
                width: 44,
                height: 5,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
            ),
            Text(
              isEditing 
                  ? (t?.translate('edit_rider') ?? 'Edit Rider')
                  : (t?.translate('add_rider') ?? 'Add Rider'),
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.center,
              child: ImagePickerWidget(
                imageUrl: widget.rider?.image,
                shape: ImagePickerShape.circle,
                width: 80,
                height: 80,
                onImageSelected: (file) {
                  setState(() => _pickedImage = file);
                },
              ),
            ),
            const SizedBox(height: 24),
            _buildTextField(
              controller: _nameController,
              label: t?.translate('name') ?? 'Name',
              hint: t?.translate('enter_rider_name') ?? 'Enter rider name',
              validator: (value) => value == null || value.isEmpty ? 'Required field' : null,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _phoneController,
              label: t?.translate('phone_number') ?? 'Phone Number',
              hint: t?.translate('enter_phone_number') ?? 'Enter phone number',
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _licensePlateController,
              label: t?.translate('license_plate') ?? 'License Plate',
              hint: t?.translate('enter_license_plate') ?? 'Enter license plate',
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: PrimaryGradientButton(
                onPressed: _isLoading ? null : _handleSave,
                isLoading: _isLoading,
                text: t?.translate('save') ?? 'Save',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF475569),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: const Color(0xFF1E293B),
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.poppins(
              fontSize: 14,
              color: const Color(0xFF94A3B8),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
              borderSide: BorderSide(color: AppColors.primary, width: 1.5),
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }
}
