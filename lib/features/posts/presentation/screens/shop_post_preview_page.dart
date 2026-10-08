import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_shop/core/localization/app_localizations.dart';
import 'package:my_shop/core/presentation/widgets/app_dialog.dart';
import 'package:my_shop/core/presentation/widgets/confirmation_sheet.dart';
import 'package:my_shop/core/presentation/widgets/global_modal.dart';
import 'package:video_player/video_player.dart';

import '../../data/models/shop_post.dart';
import '../../data/services/shop_posts_service.dart';

/// Vertical preview of this shop's posts, opened on purpose from the grid.
class ShopPostPreviewPage extends StatefulWidget {
  final List<ShopPost> posts;
  final int initialIndex;

  const ShopPostPreviewPage({
    super.key,
    required this.posts,
    required this.initialIndex,
  });

  @override
  State<ShopPostPreviewPage> createState() => _ShopPostPreviewPageState();
}

class _ShopPostPreviewPageState extends State<ShopPostPreviewPage> {
  late final PageController _pageController;
  late List<ShopPost> _posts;
  late int _index;
  final _service = ShopPostsService();
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    _posts = List<ShopPost>.of(widget.posts);
    _index = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  String _t(String key, String fallback) {
    return AppLocalizations.of(context)?.translate(key) ?? fallback;
  }

  Future<void> _confirmDelete(int index) async {
    final post = _posts[index];
    GlobalModal.show(
      context: context,
      child: ConfirmationSheet(
        title: _t('posts_delete_title', 'Delete this post?'),
        message: _t('posts_delete_message', 'This removes the post from the customer app.'),
        confirmLabel: _t('posts_delete', 'Delete'),
        confirmColor: Colors.red,
        onConfirm: () async {
          try {
            await _service.delete(post.id);
            if (!mounted) return;
            _posts.removeAt(index);
            if (_posts.isEmpty) {
              if (mounted) {
                AppDialog.showToast(context, _t('posts_deleted', 'Post deleted.'));
                Navigator.of(context).pop(true);
              }
              return;
            }
            final next = index.clamp(0, _posts.length - 1);
            if (_pageController.hasClients &&
                (_pageController.page ?? 0) >= _posts.length) {
              _pageController.jumpToPage(next);
            }
            setState(() {
              _changed = true;
              _index = next;
            });
            AppDialog.showToast(context, _t('posts_deleted', 'Post deleted.'));
          } catch (_) {
            if (!mounted) return;
            AppDialog.showToast(
              context,
              _t('posts_delete_failed', 'Could not delete this post.'),
              isError: true,
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.of(context).pop(_changed);
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.vertical,
              itemCount: _posts.length,
              onPageChanged: (index) => setState(() => _index = index),
              itemBuilder: (context, index) {
                final post = _posts[index];
                return _PreviewSlide(
                  key: ValueKey(post.id),
                  post: post,
                  active: index == _index,
                );
              },
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () {
                        if (_posts.isEmpty) return;
                        _confirmDelete(_index.clamp(0, _posts.length - 1));
                      },
                      icon: const Icon(Icons.delete_outline, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

class _PreviewSlide extends StatefulWidget {
  final ShopPost post;
  final bool active;

  const _PreviewSlide({super.key, required this.post, required this.active});

  @override
  State<_PreviewSlide> createState() => _PreviewSlideState();
}

class _PreviewSlideState extends State<_PreviewSlide> {
  VideoPlayerController? _video;
  int _mediaIndex = 0;
  int _videoToken = 0;
  bool _videoFailed = false;

  ShopPostMedia? get _current {
    if (widget.post.media.isEmpty) return null;
    return widget.post.media[_mediaIndex.clamp(0, widget.post.media.length - 1)];
  }

  @override
  void initState() {
    super.initState();
    _openVideo();
  }

  @override
  void didUpdateWidget(_PreviewSlide oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.active == widget.active) return;
    if (!widget.active) {
      _video?.pause();
      return;
    }
    if (_video != null && _video!.value.isInitialized) {
      _video!.play();
      return;
    }
    _openVideo();
  }

  @override
  void dispose() {
    _video?.dispose();
    super.dispose();
  }

  Future<void> _openVideo() async {
    final token = ++_videoToken;
    final media = _current;
    final previous = _video;
    _video = null;
    await previous?.dispose();
    if (!mounted || token != _videoToken) return;
    if (media == null || !media.isVideo || media.url.isEmpty || !widget.active) {
      setState(() => _videoFailed = false);
      return;
    }
    final controller = VideoPlayerController.networkUrl(Uri.parse(media.url));
    _video = controller;
    try {
      await controller.initialize();
      if (!mounted || token != _videoToken || !widget.active) {
        await controller.dispose();
        if (identical(_video, controller)) _video = null;
        return;
      }
      await controller.setLooping(true);
      await controller.play();
      setState(() => _videoFailed = false);
    } catch (_) {
      await controller.dispose();
      if (identical(_video, controller)) _video = null;
      if (mounted && token == _videoToken) {
        setState(() => _videoFailed = true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = _current;
    final caption = widget.post.content?.trim() ?? '';
    return Stack(
      fit: StackFit.expand,
      children: [
        if (media == null)
          const ColoredBox(color: Colors.black)
        else if (media.isVideo)
          _video != null && _video!.value.isInitialized
              ? FittedBox(
                  fit: BoxFit.contain,
                  child: SizedBox(
                    width: _video!.value.size.width,
                    height: _video!.value.size.height,
                    child: VideoPlayer(_video!),
                  ),
                )
              : Center(
                  child: _videoFailed || !widget.active
                      ? const Icon(Icons.play_circle_fill, color: Colors.white70, size: 64)
                      : const CircularProgressIndicator(color: Colors.white),
                )
        else
          CachedNetworkImage(
            imageUrl: media.url,
            fit: BoxFit.contain,
            errorWidget: (_, _, _) => const Icon(Icons.broken_image, color: Colors.white54, size: 48),
          ),
        if (widget.post.media.length > 1)
          Positioned(
            top: 100,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < widget.post.media.length; i++)
                  GestureDetector(
                    onTap: () {
                      setState(() => _mediaIndex = i);
                      _openVideo();
                    },
                    child: Container(
                      width: i == _mediaIndex ? 16 : 6,
                      height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        color: i == _mediaIndex ? Colors.white : Colors.white38,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        if (caption.isNotEmpty)
          Positioned(
            left: 16,
            right: 16,
            bottom: 36,
            child: Text(
              caption,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                shadows: const [Shadow(color: Colors.black54, blurRadius: 8)],
              ),
            ),
          ),
      ],
    );
  }
}
