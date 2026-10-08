import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:my_shop/core/localization/app_localizations.dart';
import 'package:my_shop/core/presentation/widgets/app_dialog.dart';
import 'package:my_shop/core/utils/app_colors.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../data/services/shop_posts_service.dart';

class CreateShopPostPage extends StatefulWidget {
  const CreateShopPostPage({super.key});

  @override
  State<CreateShopPostPage> createState() => _CreateShopPostPageState();
}

class _CreateShopPostPageState extends State<CreateShopPostPage> {
  final _caption = TextEditingController();
  final _picker = ImagePicker();
  final _service = ShopPostsService();
  final List<XFile> _media = [];
  bool _submitting = false;

  bool get _canPublish =>
      _media.isNotEmpty || _caption.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _caption.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _caption.dispose();
    super.dispose();
  }

  String _t(String key, String fallback) {
    return AppLocalizations.of(context)?.translate(key) ?? fallback;
  }

  Future<void> _pick(ImageSource source, {bool video = false}) async {
    if (_media.length >= 10) {
      AppDialog.showToast(context, _t('posts_max_media', 'You can add up to 10 photos or videos.'), isError: true);
      return;
    }
    try {
      if (video) {
        final file = await _picker.pickVideo(
          source: source,
          maxDuration: const Duration(seconds: 60),
        );
        if (file != null) setState(() => _media.add(file));
        return;
      }
      if (source == ImageSource.gallery) {
        final remaining = 10 - _media.length;
        final files = await _picker.pickMultiImage(imageQuality: 85, limit: remaining);
        if (files.isEmpty) return;
        setState(() => _media.addAll(files.take(remaining)));
        return;
      }
      final file = await _picker.pickImage(source: source, imageQuality: 85);
      if (file != null) setState(() => _media.add(file));
    } catch (_) {
      if (!mounted) return;
      AppDialog.showToast(context, _t('posts_pick_failed', 'Could not pick media. Try again.'), isError: true);
    }
  }

  Future<void> _submit() async {
    if (!_canPublish || _submitting) {
      if (!_canPublish) {
        AppDialog.showToast(
          context,
          _t('posts_need_content', 'Add a caption or at least one photo or video.'),
          isError: true,
        );
      }
      return;
    }
    setState(() => _submitting = true);
    try {
      await _service.create(
        content: _caption.text,
        mediaPaths: _media.map((file) => file.path).toList(),
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _submitting = false);
      AppDialog.showToast(
        context,
        _t('posts_publish_failed', 'Could not publish. Check your connection.'),
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _t('new_post', 'New post'),
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
        actions: [
          TextButton(
            onPressed: _submitting ? null : _submit,
            child: _submitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    _t('posts_publish', 'Publish'),
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      color: _canPublish ? AppColors.primary : Colors.grey,
                    ),
                  ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          TextField(
            controller: _caption,
            maxLines: 5,
            maxLength: 5000,
            decoration: InputDecoration(
              hintText: _t('posts_caption_hint', 'Write a caption...'),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _t('posts_add_media', 'Add photo or video'),
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _PickButton(
                icon: PhosphorIconsRegular.images,
                label: _t('posts_gallery', 'Gallery'),
                onTap: () => _pick(ImageSource.gallery),
              ),
              const SizedBox(width: 10),
              _PickButton(
                icon: PhosphorIconsRegular.camera,
                label: _t('posts_camera', 'Camera'),
                onTap: () => _pick(ImageSource.camera),
              ),
              const SizedBox(width: 10),
              _PickButton(
                icon: PhosphorIconsRegular.videoCamera,
                label: _t('posts_video', 'Video'),
                onTap: () => _pick(ImageSource.camera, video: true),
              ),
            ],
          ),
          if (_media.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var i = 0; i < _media.length; i++)
                  Chip(
                    label: Text(
                      _media[i].name,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onDeleted: () => setState(() => _media.removeAt(i)),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _PickButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PickButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label, overflow: TextOverflow.ellipsis),
      ),
    );
  }
}
