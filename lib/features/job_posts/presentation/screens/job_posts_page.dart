import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:my_shop/core/localization/app_localizations.dart';
import 'package:my_shop/core/presentation/widgets/app_dialog.dart';
import 'package:my_shop/core/presentation/widgets/back_title_app_bar.dart';
import 'package:my_shop/core/presentation/widgets/empty_state.dart';
import 'package:my_shop/core/presentation/widgets/skeleton.dart';
import 'package:my_shop/core/presentation/widgets/skeleton_list.dart';
import 'package:my_shop/core/utils/app_colors.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../data/models/job_post_model.dart';
import '../../data/services/job_post_service.dart';
import 'create_edit_job_post_page.dart';

class JobPostsPage extends StatefulWidget {
  const JobPostsPage({super.key});

  @override
  State<JobPostsPage> createState() => _JobPostsPageState();
}

class _JobPostsPageState extends State<JobPostsPage> {
  final JobPostService _service = JobPostService();
  final TextEditingController _searchController = TextEditingController();
  final List<JobPostModel> _items = [];
  Timer? _searchDebounce;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  int _currentPage = 1;
  bool _hasMore = true;
  String _searchQuery = '';
  JobType? _selectedJobType;
  JobPostStatus? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _load(refresh: true);
  }

  Future<void> _load({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _currentPage = 1;
        _hasMore = true;
        _isLoading = true;
        if (refresh) _items.clear();
      });
    }

    try {
      final result = await _service.getJobPosts(
        page: _currentPage,
        search: _searchQuery.isEmpty ? null : _searchQuery,
        jobType: _selectedJobType,
        status: _selectedStatus,
      );
      if (!mounted) return;
      setState(() {
        if (refresh) {
          _items
            ..clear()
            ..addAll(result.items);
        } else {
          _items.addAll(result.items);
        }
        _hasMore = result.hasMore;
        _isLoading = false;
        _isLoadingMore = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  Future<void> _refresh() => _load(refresh: true);

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      if (_searchQuery == value.trim()) return;
      setState(() => _searchQuery = value.trim());
      _refresh();
    });
  }

  void _onFilterChanged({JobType? jobType, JobPostStatus? status, bool clearAll = false}) {
    setState(() {
      if (clearAll) {
        _selectedJobType = null;
        _selectedStatus = null;
      } else {
        if (jobType != null) _selectedJobType = jobType;
        if (status != null) _selectedStatus = status;
      }
    });
    _refresh();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _loadMore() {
    if (_isLoadingMore || !_hasMore) return;
    setState(() {
      _isLoadingMore = true;
      _currentPage++;
    });
    _load();
  }

  Future<void> _openForm([JobPostModel? job]) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CreateEditJobPostPage(job: job),
      ),
    );
    if (changed == true) _refresh();
  }

  Future<void> _closeJob(JobPostModel job) async {
    final t = AppLocalizations.of(context);
    final confirm = await AppDialog.showConfirm(
      context,
      title: t?.translate('close_position') ?? 'Close Position',
      message: t?.translate('close_position_confirm') ??
          'This job will be hidden from users. You can reopen it later.',
      confirmLabel: t?.translate('close_position') ?? 'Close Position',
      cancelLabel: t?.translate('cancel') ?? 'Cancel',
    );
    if (confirm != true) return;

    try {
      final updated = await _service.updateJobPost(
        job.id,
        job.copyWith(status: JobPostStatus.inactive),
      );
      if (!mounted) return;
      if (updated != null) {
        AppDialog.showToast(
          context,
          t?.translate('job_post_closed') ?? 'Position closed',
        );
        _refresh();
      }
    } catch (_) {}
  }

  Future<void> _deleteJob(JobPostModel job) async {
    final t = AppLocalizations.of(context);
    final confirm = await AppDialog.showConfirm(
      context,
      title: t?.translate('delete_job_post') ?? 'Delete Job Post',
      message: t?.translate('delete_job_post_confirm') ??
          'Are you sure you want to delete this job post?',
      confirmLabel: t?.translate('delete') ?? 'Delete',
      cancelLabel: t?.translate('cancel') ?? 'Cancel',
    );
    if (confirm != true) return;

    setState(() => _isLoading = true);
    final success = await _service.deleteJobPost(job.id);
    if (!mounted) return;
    if (success) {
      AppDialog.showToast(
        context,
        t?.translate('job_post_deleted') ?? 'Job post deleted',
      );
      _refresh();
    } else {
      setState(() => _isLoading = false);
      AppDialog.showToast(
        context,
        t?.translate('failed_delete_job_post') ?? 'Failed to delete job post',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      appBar: BackTitleAppBar(
        title: t?.translate('job_posts') ?? 'Job Posts',
        actions: [GradientAddIconButton(onPressed: () => _openForm())],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: AppColors.primary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: t?.translate('search_job_posts') ??
                        'Search job posts…',
                    prefixIcon: PhosphorIcon(
                      PhosphorIconsRegular.magnifyingGlass,
                      color: AppColors.outline,
                      size: 20,
                    ),
                    filled: true,
                    fillColor: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF1E293B)
                        : const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Theme.of(context).dividerColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Theme.of(context).dividerColor),
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Row(
                  children: [
                    _FilterChip(
                      label: t?.translate('filter_all') ?? 'All',
                      selected:
                          _selectedJobType == null && _selectedStatus == null,
                      onTap: () => _onFilterChanged(clearAll: true),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: t?.translate('job_full_time') ?? 'Full Time',
                      selected: _selectedJobType == JobType.fullTime,
                      onTap: () => _onFilterChanged(jobType: JobType.fullTime),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: t?.translate('job_part_time') ?? 'Part Time',
                      selected: _selectedJobType == JobType.partTime,
                      onTap: () => _onFilterChanged(jobType: JobType.partTime),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: t?.translate('job_status_active') ?? 'Active',
                      selected: _selectedStatus == JobPostStatus.active,
                      onTap: () =>
                          _onFilterChanged(status: JobPostStatus.active),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: t?.translate('job_status_closed') ?? 'Closed',
                      selected: _selectedStatus == JobPostStatus.inactive,
                      onTap: () =>
                          _onFilterChanged(status: JobPostStatus.inactive),
                    ),
                  ],
                ),
              ),
            ),
            if (_isLoading)
              SliverFillRemaining(
                child: SkeletonList(
                  itemCount: 6,
                  itemBuilder: (_, _) => _buildSkeletonCard(),
                ),
              )
            else if (_items.isEmpty)
              SliverFillRemaining(
                child: EmptyState(
                  icon: PhosphorIcon(
                    PhosphorIconsRegular.briefcase,
                    size: 64,
                    color: AppColors.iconDisabled,
                  ),
                  title: t?.translate('no_job_posts') ?? 'No Job Posts Yet',
                  subtitle: t?.translate('no_job_posts_desc') ??
                      'Create a job post to find staff for your shop.',
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index >= _items.length) {
                        if (_isLoadingMore) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        return const SizedBox.shrink();
                      }
                      if (index == _items.length - 1 &&
                          !_isLoadingMore &&
                          _hasMore) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          _loadMore();
                        });
                      }
                      return _buildJobCard(_items[index]);
                    },
                    childCount: _items.length + (_isLoadingMore ? 1 : 0),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Skeleton(height: 16, width: 180),
          SizedBox(height: 8),
          Skeleton(height: 12, width: 120),
          SizedBox(height: 8),
          Skeleton(height: 12, width: 90),
        ],
      ),
    );
  }

  Widget _buildJobCard(JobPostModel job) {
    final t = AppLocalizations.of(context);
    final dateFmt = DateFormat('d MMM yyyy');
    final jobTypeLabel = job.jobType == JobType.fullTime
        ? (t?.translate('job_full_time') ?? 'Full Time')
        : (t?.translate('job_part_time') ?? 'Part Time');
    final statusLabel = job.isActive
        ? (t?.translate('job_status_active') ?? 'Active')
        : (t?.translate('job_status_closed') ?? 'Closed');
    final statusColor =
        job.isActive ? const Color(0xFF059669) : AppColors.outline;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _openForm(job),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        job.title,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        switch (value) {
                          case 'edit':
                            _openForm(job);
                            break;
                          case 'close':
                            if (job.isActive) _closeJob(job);
                            break;
                          case 'delete':
                            _deleteJob(job);
                            break;
                        }
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          value: 'edit',
                          child: Text(t?.translate('edit') ?? 'Edit'),
                        ),
                        if (job.isActive)
                          PopupMenuItem(
                            value: 'close',
                            child: Text(
                              t?.translate('close_position') ?? 'Close Position',
                            ),
                          ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Text(
                            t?.translate('delete') ?? 'Delete',
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _chip(jobTypeLabel, AppColors.primary),
                    _chip(statusLabel, statusColor),
                  ],
                ),
                if (job.closingDate != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    '${t?.translate('closing_date') ?? 'Closing date'}: ${dateFmt.format(job.closingDate!.toLocal())}',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppColors.outline,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: selected ? Colors.white : AppColors.onSurface,
          ),
        ),
      ),
    );
  }
}
