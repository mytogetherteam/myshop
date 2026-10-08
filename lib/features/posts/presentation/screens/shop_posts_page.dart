import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_shop/core/localization/app_localizations.dart';
import 'package:my_shop/core/presentation/widgets/app_dialog.dart';
import 'package:my_shop/core/presentation/widgets/confirmation_sheet.dart';
import 'package:my_shop/core/presentation/widgets/global_modal.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../data/models/shop_post.dart';
import '../../data/services/shop_posts_service.dart';
import 'create_shop_post_page.dart';
import 'shop_post_preview_page.dart';

class ShopPostsPage extends StatefulWidget {
  const ShopPostsPage({super.key});

  @override
  State<ShopPostsPage> createState() => _ShopPostsPageState();
}

class _ShopPostsPageState extends State<ShopPostsPage> {
  final _service = ShopPostsService();
  final _posts = <ShopPost>[];
  final _scroll = ScrollController();
  bool _loading = true;
  bool _loadingMore = false;
  int _page = 1;
  int _totalPages = 1;
  int _generation = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _load(reset: true);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  String _t(String key, String fallback) {
    return AppLocalizations.of(context)?.translate(key) ?? fallback;
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 240) {
      _load();
    }
  }

  Future<void> _load({bool reset = false}) async {
    if (reset) {
      _generation += 1;
      _page = 1;
      _totalPages = 1;
    } else if (_loading || _loadingMore || _page > _totalPages) {
      return;
    }
    final generation = _generation;
    final page = _page;
    setState(() {
      if (reset) {
        _loading = true;
        _error = null;
      } else {
        _loadingMore = true;
      }
    });
    try {
      final result = await _service.listOwn(page: page);
      if (!mounted || generation != _generation) return;
      setState(() {
        if (reset) _posts.clear();
        _posts.addAll(result.items);
        _totalPages = result.totalPages;
        _page = page + 1;
        _loading = false;
        _loadingMore = false;
      });
    } catch (_) {
      if (!mounted || generation != _generation) return;
      setState(() {
        _loading = false;
        _loadingMore = false;
        _error = _t('posts_load_failed', 'Could not load posts.');
      });
    }
  }

  Future<void> _openCreate() async {
    final created = await Navigator.push<bool>(
      context,
      CupertinoPageRoute(builder: (_) => const CreateShopPostPage()),
    );
    if (created == true) _load(reset: true);
  }

  Future<void> _openPreview(int index) async {
    final changed = await Navigator.push<bool>(
      context,
      CupertinoPageRoute(
        builder: (_) => ShopPostPreviewPage(
          posts: List<ShopPost>.of(_posts),
          initialIndex: index,
        ),
      ),
    );
    if (changed == true) _load(reset: true);
  }

  void _confirmDelete(ShopPost post) {
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
            setState(() => _posts.removeWhere((item) => item.id == post.id));
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
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _t('my_posts', 'My posts'),
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
        actions: [
          TextButton.icon(
            onPressed: _openCreate,
            icon: const Icon(PhosphorIconsRegular.plus, size: 18),
            label: Text(_t('new_post', 'New post')),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null && _posts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!, style: GoogleFonts.poppins()),
                      const SizedBox(height: 12),
                      TextButton(onPressed: () => _load(reset: true), child: const Text('Retry')),
                    ],
                  ),
                )
              : _posts.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _t('posts_empty', 'No posts yet. Share a photo or video from your shop.'),
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(color: Colors.grey[700]),
                            ),
                            const SizedBox(height: 16),
                            FilledButton(
                              onPressed: _openCreate,
                              child: Text(_t('new_post', 'New post')),
                            ),
                          ],
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () => _load(reset: true),
                      child: GridView.builder(
                        controller: _scroll,
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(12),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                        ),
                        itemCount: _posts.length,
                        itemBuilder: (context, index) {
                          final post = _posts[index];
                          final media = post.primary;
                          return Stack(
                            fit: StackFit.expand,
                            children: [
                              GestureDetector(
                                onTap: () => _openPreview(index),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      media == null
                                          ? ColoredBox(
                                              color: const Color(0xFFEEEEEE),
                                              child: Padding(
                                                padding: const EdgeInsets.all(8),
                                                child: Center(
                                                  child: (post.content ?? '').trim().isEmpty
                                                      ? const Icon(PhosphorIconsRegular.textAa)
                                                      : Text(
                                                          post.content!.trim(),
                                                          textAlign: TextAlign.center,
                                                          maxLines: 5,
                                                          overflow: TextOverflow.ellipsis,
                                                          style: GoogleFonts.poppins(
                                                            fontSize: 11,
                                                            fontWeight: FontWeight.w600,
                                                          ),
                                                        ),
                                                ),
                                              ),
                                            )
                                          : media.isVideo &&
                                                  (media.thumbnailUrl == null ||
                                                      media.thumbnailUrl!.isEmpty)
                                              ? const ColoredBox(
                                                  color: Colors.black87,
                                                  child: Icon(
                                                    PhosphorIconsFill.play,
                                                    color: Colors.white,
                                                  ),
                                                )
                                              : CachedNetworkImage(
                                                  imageUrl: media.isVideo
                                                      ? media.previewUrl
                                                      : media.url,
                                                  fit: BoxFit.cover,
                                                  errorWidget: (_, _, _) =>
                                                      const ColoredBox(
                                                    color: Colors.black87,
                                                    child: Icon(
                                                      PhosphorIconsFill.play,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                      if (post.hasVideo)
                                        const Positioned(
                                          left: 6,
                                          bottom: 6,
                                          child: Icon(
                                            PhosphorIconsFill.playCircle,
                                            color: Colors.white,
                                            size: 22,
                                          ),
                                        ),
                                      if (!post.isActive)
                                        Positioned(
                                          left: 6,
                                          top: 6,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.black54,
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              _t('posts_hidden', 'Hidden'),
                                              style: GoogleFonts.poppins(
                                                color: Colors.white,
                                                fontSize: 10,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 0,
                                top: 0,
                                child: IconButton(
                                  visualDensity: VisualDensity.compact,
                                  onPressed: () => _confirmDelete(post),
                                  icon: const Icon(
                                    PhosphorIconsRegular.trash,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                  style: IconButton.styleFrom(
                                    backgroundColor: Colors.black45,
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
    );
  }
}
