import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:my_shop/core/presentation/widgets/app_dialog.dart';
import 'package:my_shop/core/presentation/widgets/back_title_app_bar.dart';
import 'package:my_shop/core/presentation/widgets/image_picker_widget.dart';
import 'package:my_shop/core/utils/app_colors.dart';
import 'package:my_shop/features/profile/data/models/shop_myday.dart';
import 'package:my_shop/features/profile/data/services/shop_myday_service.dart';

class ShopMyDayPage extends StatefulWidget {
  const ShopMyDayPage({super.key});

  @override
  State<ShopMyDayPage> createState() => _ShopMyDayPageState();
}

class _ShopMyDayPageState extends State<ShopMyDayPage> {
  final ShopMyDayService _service = ShopMyDayService();

  List<ShopMyDay> _items = const [];
  XFile? _selectedPhoto;
  bool _loading = true;
  bool _uploading = false;
  int? _deletingId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _loading = true);
    try {
      final items = await _service.list();
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      AppDialog.showToast(
        context,
        'Could not load MyDay posts. Please try again.',
        isError: true,
      );
    }
  }

  Future<void> _upload() async {
    final photo = _selectedPhoto;
    if (photo == null || _uploading) return;

    setState(() => _uploading = true);
    try {
      final created = await _service.create(photo);
      if (!mounted) return;
      setState(() {
        _items = [created, ..._items];
        _selectedPhoto = null;
        _uploading = false;
      });
      AppDialog.showToast(context, 'MyDay posted successfully.');
    } catch (_) {
      if (!mounted) return;
      setState(() => _uploading = false);
      AppDialog.showToast(
        context,
        'Could not post MyDay. Use an image under 5 MB and try again.',
        isError: true,
      );
    }
  }

  Future<void> _delete(ShopMyDay item) async {
    final confirmed = await AppDialog.showConfirm(
      context,
      title: 'Delete MyDay?',
      message:
          'This photo will disappear immediately for everyone viewing your shop.',
      confirmLabel: 'Delete',
    );
    if (!confirmed || !mounted) return;

    setState(() => _deletingId = item.id);
    try {
      await _service.delete(item.id);
      if (!mounted) return;
      setState(() {
        _items = _items.where((entry) => entry.id != item.id).toList();
        _deletingId = null;
      });
      AppDialog.showToast(context, 'MyDay deleted.');
    } catch (_) {
      if (!mounted) return;
      setState(() => _deletingId = null);
      AppDialog.showToast(
        context,
        'Could not delete MyDay. Please try again.',
        isError: true,
      );
    }
  }

  String _remainingLabel(ShopMyDay item) {
    final remaining = item.timeRemaining;
    if (remaining.inHours > 0) {
      return '${remaining.inHours}h ${remaining.inMinutes.remainder(60)}m left';
    }
    return '${remaining.inMinutes.clamp(0, 59)}m left';
  }

  void _preview(ShopMyDay item) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.92),
      builder: (dialogContext) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: SafeArea(
          child: Stack(
            fit: StackFit.expand,
            children: [
              InteractiveViewer(
                child: CachedNetworkImage(
                  imageUrl: item.imageUrl,
                  fit: BoxFit.contain,
                  errorWidget: (_, _, _) => const Center(
                    child: Icon(
                      Icons.broken_image_outlined,
                      color: Colors.white,
                      size: 48,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton.filled(
                  onPressed: () => Navigator.pop(dialogContext),
                  icon: const Icon(Icons.close),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const BackTitleAppBar(title: 'MyDay'),
      body: RefreshIndicator(
        onRefresh: _load,
        color: AppColors.primary,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
          children: [
            Text(
              'Post a shop story',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Choose one photo. It will appear on your restaurant page for 24 hours.',
              style: GoogleFonts.poppins(
                fontSize: 13,
                height: 1.45,
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
            const SizedBox(height: 18),
            Center(
              child: ImagePickerWidget(
                key: ValueKey(_selectedPhoto?.path ?? 'empty-myday-picker'),
                pickedFile: _selectedPhoto,
                width: 220,
                height: 300,
                borderRadius: 20,
                maxWidth: 1280,
                maxHeight: 1280,
                imageQuality: 90,
                maxFileSizeMB: 5,
                themeGradient: AppColors.primaryGradient,
                onImageSelected: (file) {
                  setState(() => _selectedPhoto = file);
                },
                onImageRemoved: _selectedPhoto == null
                    ? null
                    : () => setState(() => _selectedPhoto = null),
                placeholder: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_photo_alternate_outlined,
                      size: 44,
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Choose photo',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 50,
              child: FilledButton(
                onPressed:
                    _selectedPhoto == null || _uploading ? null : _upload,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor:
                      Theme.of(context).disabledColor.withValues(alpha: 0.15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _uploading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'Post to MyDay',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Active MyDays',
                    style: GoogleFonts.poppins(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                ),
                if (!_loading)
                  Text(
                    '${_items.length} active',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_items.isEmpty)
              _buildEmptyState()
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _items.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.72,
                ),
                itemBuilder: (context, index) =>
                    _buildStoryCard(_items[index]),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 34),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        children: [
          Icon(
            Icons.auto_stories_outlined,
            size: 42,
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
          const SizedBox(height: 10),
          Text(
            'No active MyDays',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Post a photo above to create your first story.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoryCard(ShopMyDay item) {
    final deleting = _deletingId == item.id;
    return Material(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: deleting ? null : () => _preview(item),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: item.imageUrl,
              fit: BoxFit.cover,
              placeholder: (_, _) => Container(
                color: Theme.of(context).dividerColor,
              ),
              errorWidget: (_, _, _) => const Icon(
                Icons.broken_image_outlined,
                size: 42,
              ),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.center,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0xCC000000)],
                ),
              ),
            ),
            Positioned(
              left: 10,
              right: 10,
              bottom: 10,
              child: Text(
                _remainingLabel(item),
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Positioned(
              top: 7,
              right: 7,
              child: IconButton.filled(
                visualDensity: VisualDensity.compact,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black.withValues(alpha: 0.55),
                ),
                onPressed: deleting ? null : () => _delete(item),
                icon: deleting
                    ? const SizedBox(
                        width: 17,
                        height: 17,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.delete_outline, size: 19),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
