import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:my_shop/core/utils/app_colors.dart';
import 'package:my_shop/core/presentation/widgets/custom_loading_indicator.dart';
import '../../data/models/announcement_model.dart';
import '../../data/repositories/announcement_repository.dart';
import '../widgets/announcement_detail_sheet.dart';

class AnnouncementsPage extends StatefulWidget {
  const AnnouncementsPage({super.key});

  @override
  State<AnnouncementsPage> createState() => _AnnouncementsPageState();
}

class _AnnouncementsPageState extends State<AnnouncementsPage> {
  final AnnouncementRepository _repository = AnnouncementRepository();
  final List<AnnouncementModel> _items = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  int _currentPage = 0;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _currentPage = 0;
        _items.clear();
        _isLoading = true;
        _hasMore = true;
      });
    }

    try {
      final newItems = await _repository.getAnnouncements(page: _currentPage);
      setState(() {
        if (newItems.length < 20) {
          _hasMore = false;
        }
        _items.addAll(newItems);
        _isLoading = false;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  void _loadMore() {
    if (!_isLoadingMore && _hasMore) {
      setState(() {
        _isLoadingMore = true;
        _currentPage++;
      });
      _load();
    }
  }

  Future<void> _openDetail(AnnouncementModel item) async {
    if (!item.isRead) {
      await _repository.markAsRead(item.id);
      setState(() {
        final idx = _items.indexWhere((i) => i.id == item.id);
        if (idx != -1) {
          _items[idx] = item.copyWith(isRead: true);
        }
      });
    }
    if (mounted) {
      await AnnouncementDetailSheet.show(context, item);
    }
  }

  Future<void> _dismiss(AnnouncementModel item) async {
    setState(() {
      _items.removeWhere((i) => i.id == item.id);
    });
    // Add logic here if backend supports deleting individual announcements
  }

  Future<void> _markAllAsRead() async {
    final previous = List<AnnouncementModel>.from(_items);
    setState(() {
      for (int i = 0; i < _items.length; i++) {
        if (!_items[i].isRead) {
          _items[i] = _items[i].copyWith(isRead: true);
        }
      }
    });

    final success = await _repository.markAllAsRead();
    if (!success && mounted) {
      setState(() {
        _items.clear();
        _items.addAll(previous);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_items.any((n) => !n.isRead))
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              child: TextButton(
                onPressed: _markAllAsRead,
                child: const Text('Mark all as read'),
              ),
            ),
          ),
        Expanded(
          child: _isLoading
              ? const Center(child: CustomLoadingIndicator(size: 40))
              : _items.isEmpty
                  ? _buildEmptyState()
                  : NotificationListener<ScrollNotification>(
                      onNotification: (ScrollNotification scrollInfo) {
                        if (scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent && _hasMore) {
                          _loadMore();
                        }
                        return true;
                      },
                      child: RefreshIndicator(
                        color: AppColors.primary,
                        onRefresh: () => _load(refresh: true),
                        child: ListView.builder(
                          itemCount: _items.length + (_hasMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == _items.length) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: CustomLoadingIndicator(size: 24),
                                ),
                              );
                            }
                            return _buildItem(_items[index]);
                          },
                        ),
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildItem(AnnouncementModel item) {
    final hasImage = item.imageUrl != null && item.imageUrl!.isNotEmpty;
    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        margin: const EdgeInsets.fromLTRB(16, 6, 16, 6),
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) => _dismiss(item),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => _openDetail(item),
            child: Opacity(
              opacity: item.isRead ? 0.75 : 1.0,
              child: Container(
                height: 150,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _buildItemBackground(hasImage, item),
                    DecoratedBox(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black87,
                          ],
                          stops: [0.25, 1.0],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              if (!item.isRead)
                                Container(
                                  width: 8,
                                  height: 8,
                                  margin: const EdgeInsets.only(right: 8),
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              Expanded(
                                child: Text(
                                  _formatDate(item.createdAt),
                                  style: GoogleFonts.poppins(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Text(
                            item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.message,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              color: Colors.white.withValues(alpha: 0.92),
                              fontSize: 13,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildItemBackground(bool hasImage, AnnouncementModel item) {
    if (hasImage) {
      return CachedNetworkImage(
        fadeInDuration: Duration.zero, 
        fadeOutDuration: Duration.zero,
        imageUrl: item.imageUrl!,
        fit: BoxFit.cover,
        placeholder: (context, url) => _buildFallbackBackground(),
        errorWidget: (context, url, error) => _buildFallbackBackground(),
      );
    }
    return _buildFallbackBackground();
  }

  Widget _buildFallbackBackground() {
    return DecoratedBox(
      decoration: BoxDecoration(color: AppColors.primary),
      child: Align(
        alignment: Alignment.topRight,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Icon(
            PhosphorIconsRegular.megaphone,
            size: 56,
            color: Colors.white.withValues(alpha: 0.25),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              PhosphorIconsRegular.megaphone,
              size: 64,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Announcements',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You will see new updates here.',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM d, yyyy').format(date);
  }
}
