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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B1120) : const Color(0xFFF1F5F9),
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
            // ── Header Banner ───────────────────────────────────────
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, Color(0xFFFB923C)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const PhosphorIcon(
                        PhosphorIconsFill.briefcase,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t?.translate('job_posts') ?? 'Job Posts',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            '${_items.length} ${t?.translate('job_posts') ?? 'Posts'}',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w400,
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Search Bar ──────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0 : 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    style: GoogleFonts.poppins(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: t?.translate('search_job_posts') ?? 'Search job posts…',
                      hintStyle: GoogleFonts.poppins(
                        color: Theme.of(context).textTheme.bodySmall?.color,
                        fontSize: 14,
                      ),
                      prefixIcon: const PhosphorIcon(
                        PhosphorIconsRegular.magnifyingGlass,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: AppColors.primary.withValues(alpha: 0.5),
                        ),
                      ),
                      filled: false,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
              ),
            ),

            // ── Filter Chips ────────────────────────────────────────
            SliverToBoxAdapter(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    _GradientFilterChip(
                      label: t?.translate('filter_all') ?? 'All',
                      selected: _selectedJobType == null && _selectedStatus == null,
                      onTap: () => _onFilterChanged(clearAll: true),
                    ),
                    const SizedBox(width: 8),
                    _GradientFilterChip(
                      label: t?.translate('job_full_time') ?? 'Full Time',
                      icon: PhosphorIconsRegular.clock,
                      selected: _selectedJobType == JobType.fullTime,
                      onTap: () => _onFilterChanged(jobType: JobType.fullTime),
                    ),
                    const SizedBox(width: 8),
                    _GradientFilterChip(
                      label: t?.translate('job_part_time') ?? 'Part Time',
                      icon: PhosphorIconsRegular.clockCountdown,
                      selected: _selectedJobType == JobType.partTime,
                      onTap: () => _onFilterChanged(jobType: JobType.partTime),
                    ),
                    const SizedBox(width: 8),
                    _GradientFilterChip(
                      label: t?.translate('job_status_active') ?? 'Active',
                      icon: PhosphorIconsRegular.checkCircle,
                      selected: _selectedStatus == JobPostStatus.active,
                      onTap: () => _onFilterChanged(status: JobPostStatus.active),
                    ),
                    const SizedBox(width: 8),
                    _GradientFilterChip(
                      label: t?.translate('job_status_closed') ?? 'Closed',
                      icon: PhosphorIconsRegular.xCircle,
                      selected: _selectedStatus == JobPostStatus.inactive,
                      onTap: () => _onFilterChanged(status: JobPostStatus.inactive),
                    ),
                  ],
                ),
              ),
            ),

            // ── List ────────────────────────────────────────────────
            if (_isLoading)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => _buildSkeletonCard(),
                    childCount: 5,
                  ),
                ),
              )
            else if (_items.isEmpty)
              SliverFillRemaining(
                child: EmptyState(
                  icon: const PhosphorIcon(
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
                          return Padding(
                            padding: const EdgeInsets.all(16),
                            child: Center(
                              child: CircularProgressIndicator(color: AppColors.primary),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      }
                      if (index == _items.length - 1 && !_isLoadingMore && _hasMore) {
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Skeleton(height: 16, width: 200),
          SizedBox(height: 10),
          Skeleton(height: 12, width: 130),
          SizedBox(height: 10),
          Row(children: [
            Skeleton(height: 24, width: 80),
            SizedBox(width: 8),
            Skeleton(height: 24, width: 70),
          ]),
        ],
      ),
    );
  }

  Widget _buildJobCard(JobPostModel job) {
    final t = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateFmt = DateFormat('d MMM yyyy');
    final isActive = job.isActive;

    final jobTypeLabel = job.jobType == JobType.fullTime
        ? (t?.translate('job_full_time') ?? 'Full Time')
        : (t?.translate('job_part_time') ?? 'Part Time');
    final statusLabel = isActive
        ? (t?.translate('job_status_active') ?? 'Active')
        : (t?.translate('job_status_closed') ?? 'Closed');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive
              ? AppColors.primary.withValues(alpha: 0.15)
              : Theme.of(context).dividerColor.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _openForm(job),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left icon
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: isActive
                            ? const LinearGradient(
                                colors: [AppColors.primary, Color(0xFFFB923C)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        color: isActive ? null : AppColors.outline.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: PhosphorIcon(
                        PhosphorIconsFill.briefcase,
                        color: isActive ? Colors.white : AppColors.outline,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            job.title,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: Theme.of(context).textTheme.bodyLarge?.color,
                            ),
                          ),
                          if (job.closingDate != null) ...[
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                PhosphorIcon(
                                  PhosphorIconsRegular.calendarBlank,
                                  size: 12,
                                  color: Theme.of(context).textTheme.bodySmall?.color,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${t?.translate('closing_date') ?? 'Closing'}: ${dateFmt.format(job.closingDate!.toLocal())}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    color: Theme.of(context).textTheme.bodySmall?.color,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    // Action menu
                    _buildPopupMenu(job, t),
                  ],
                ),
                const SizedBox(height: 12),
                // Chips row
                Row(
                  children: [
                    _buildGradientChip(
                      jobTypeLabel,
                      job.jobType == JobType.fullTime
                          ? PhosphorIconsRegular.clock
                          : PhosphorIconsRegular.clockCountdown,
                      gradient: true,
                    ),
                    const SizedBox(width: 8),
                    _buildStatusChip(statusLabel, isActive),
                    if (job.salaryMin != null || job.salaryMax != null) ...[
                      const SizedBox(width: 8),
                      _buildSalaryChip(job),
                    ] else if (job.salaryNegotiable) ...[
                      const SizedBox(width: 8),
                      _buildGradientChip(
                        t?.translate('salary_negotiable') ?? 'Negotiable',
                        PhosphorIconsRegular.handshake,
                        gradient: false,
                        color: const Color(0xFF059669),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPopupMenu(JobPostModel job, AppLocalizations? t) {
    return PopupMenuButton<String>(
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
      icon: PhosphorIcon(
        PhosphorIconsRegular.dotsThree,
        color: Theme.of(context).textTheme.bodySmall?.color,
        size: 22,
      ),
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'edit',
          child: Row(children: [
            const PhosphorIcon(PhosphorIconsRegular.pencil, size: 16),
            const SizedBox(width: 8),
            Text(t?.translate('edit') ?? 'Edit', style: GoogleFonts.poppins()),
          ]),
        ),
        if (job.isActive)
          PopupMenuItem(
            value: 'close',
            child: Row(children: [
              const PhosphorIcon(PhosphorIconsRegular.xCircle, size: 16),
              const SizedBox(width: 8),
              Text(t?.translate('close_position') ?? 'Close', style: GoogleFonts.poppins()),
            ]),
          ),
        PopupMenuItem(
          value: 'delete',
          child: Row(children: [
            const PhosphorIcon(PhosphorIconsRegular.trash, size: 16, color: Colors.red),
            const SizedBox(width: 8),
            Text(
              t?.translate('delete') ?? 'Delete',
              style: GoogleFonts.poppins(color: Colors.red),
            ),
          ]),
        ),
      ],
    );
  }

  Widget _buildGradientChip(String label, IconData icon, {required bool gradient, Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        gradient: gradient
            ? LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.12),
                  const Color(0xFFFB923C).withValues(alpha: 0.10),
                ],
              )
            : null,
        color: gradient ? null : (color ?? AppColors.primary).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PhosphorIcon(icon, size: 12, color: gradient ? AppColors.primary : (color ?? AppColors.primary)),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: gradient ? AppColors.primary : (color ?? AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String label, bool isActive) {
    final color = isActive ? const Color(0xFF059669) : AppColors.outline;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSalaryChip(JobPostModel job) {
    final fmt = NumberFormat('#,###');
    String salaryText = '';
    if (job.salaryMin != null && job.salaryMax != null) {
      salaryText = '฿${fmt.format(job.salaryMin)}-${fmt.format(job.salaryMax)}';
    } else if (job.salaryMin != null) {
      salaryText = '฿${fmt.format(job.salaryMin)}+';
    } else if (job.salaryMax != null) {
      salaryText = '฿${fmt.format(job.salaryMax)}';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF059669).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        salaryText,
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF059669),
        ),
      ),
    );
  }
}

// ── Premium Gradient Filter Chip ─────────────────────────────────────────────

class _GradientFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  const _GradientFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(
                  colors: [AppColors.primary, Color(0xFFFB923C)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: selected ? null : (isDark ? const Color(0xFF1E293B) : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? Colors.transparent : Theme.of(context).dividerColor,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              PhosphorIcon(
                icon!,
                size: 13,
                color: selected ? Colors.white : AppColors.outline,
              ),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: selected ? Colors.white : Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
