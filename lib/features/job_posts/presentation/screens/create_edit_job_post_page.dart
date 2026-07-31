import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_shop/core/localization/app_localizations.dart';
import 'package:my_shop/core/presentation/widgets/app_dialog.dart';
import 'package:my_shop/core/presentation/widgets/primary_gradient_button.dart';
import 'package:my_shop/core/presentation/widgets/primary_gradient_switch.dart';
import 'package:my_shop/core/utils/app_colors.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../data/models/job_post_model.dart';
import '../../data/services/job_post_service.dart';

class CreateEditJobPostPage extends StatefulWidget {
  final JobPostModel? job;

  const CreateEditJobPostPage({super.key, this.job});

  @override
  State<CreateEditJobPostPage> createState() => _CreateEditJobPostPageState();
}

class _CreateEditJobPostPageState extends State<CreateEditJobPostPage> {
  final _formKey = GlobalKey<FormState>();
  final JobPostService _service = JobPostService();
  final _scrollController = ScrollController();
  final _titleFieldKey = GlobalKey();
  final _descriptionFieldKey = GlobalKey();
  final _salaryMinFieldKey = GlobalKey();
  final _salaryMaxFieldKey = GlobalKey();
  final _contactPhoneFieldKey = GlobalKey();
  final _applyLinkFieldKey = GlobalKey();

  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _salaryMinController;
  late final TextEditingController _salaryMaxController;
  late final TextEditingController _applyLinkController;
  late final TextEditingController _contactPhoneController;
  late final FocusNode _titleFocusNode;
  late final FocusNode _descriptionFocusNode;
  late final FocusNode _salaryMinFocusNode;
  late final FocusNode _salaryMaxFocusNode;
  late final FocusNode _contactPhoneFocusNode;
  late final FocusNode _applyLinkFocusNode;

  JobType _jobType = JobType.fullTime;
  bool _salaryNegotiable = false;
  bool _isActive = true;
  DateTime? _closingDate;
  bool _isSaving = false;
  bool _showValidationErrors = false;

  bool get _isEditing => widget.job != null;

  @override
  void initState() {
    super.initState();
    final job = widget.job;
    _titleController = TextEditingController(text: job?.title ?? '');
    _descriptionController = TextEditingController(text: job?.description ?? '');
    _salaryMinController = TextEditingController(
      text: job?.salaryMin?.toString() ?? '',
    );
    _salaryMaxController = TextEditingController(
      text: job?.salaryMax?.toString() ?? '',
    );
    _applyLinkController = TextEditingController(text: job?.applyLink ?? '');
    _contactPhoneController =
        TextEditingController(text: job?.contactPhone ?? '');
    _titleFocusNode = FocusNode();
    _descriptionFocusNode = FocusNode();
    _salaryMinFocusNode = FocusNode();
    _salaryMaxFocusNode = FocusNode();
    _contactPhoneFocusNode = FocusNode();
    _applyLinkFocusNode = FocusNode();
    if (job != null) {
      _jobType = job.jobType;
      _salaryNegotiable = job.salaryNegotiable;
      _isActive = job.isActive;
      _closingDate = job.closingDate;
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _salaryMinController.dispose();
    _salaryMaxController.dispose();
    _applyLinkController.dispose();
    _contactPhoneController.dispose();
    _titleFocusNode.dispose();
    _descriptionFocusNode.dispose();
    _salaryMinFocusNode.dispose();
    _salaryMaxFocusNode.dispose();
    _contactPhoneFocusNode.dispose();
    _applyLinkFocusNode.dispose();
    super.dispose();
  }

  int? _parseSalary(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    return int.tryParse(trimmed.replaceAll(',', ''));
  }

  String? _validateSalaryRange(AppLocalizations? t) {
    if (_salaryNegotiable) return null;
    final min = _parseSalary(_salaryMinController.text);
    final max = _parseSalary(_salaryMaxController.text);
    if (min != null && max != null && max < min) {
      return t?.translate('job_validation_salary_range') ??
          'Maximum salary must be greater than or equal to minimum.';
    }
    return null;
  }

  String? _validateContact(AppLocalizations? t) {
    final phone = _contactPhoneController.text.trim();
    if (phone.isEmpty) {
      return t?.translate('job_validation_contact') ??
          'Please enter a contact phone number.';
    }
    final digitsOnly = phone.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.length < 9 || digitsOnly.length > 11) {
      return t?.translate('job_validation_phone') ??
          'Phone number must be 9 to 11 digits.';
    }
    return null;
  }

  String? _validateApplyLink(AppLocalizations? t) {
    final link = _applyLinkController.text.trim();
    if (link.isEmpty) return null;
    final uri = Uri.tryParse(link);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      return t?.translate('job_validation_link') ??
          'Apply link must be a valid URL (https://...).';
    }
    return null;
  }

  Future<void> _scrollToField(GlobalKey key, FocusNode focusNode) async {
    final context = key.currentContext;
    if (context != null) {
      await Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        alignment: 0.2,
      );
    }
    focusNode.requestFocus();
  }

  Future<void> _focusFirstInvalidField(AppLocalizations? t) async {
    if (_titleController.text.trim().isEmpty) {
      await _scrollToField(_titleFieldKey, _titleFocusNode);
      return;
    }
    if (_descriptionController.text.trim().isEmpty) {
      await _scrollToField(_descriptionFieldKey, _descriptionFocusNode);
      return;
    }
    if (_validateSalaryRange(t) != null) {
      await _scrollToField(_salaryMaxFieldKey, _salaryMaxFocusNode);
      return;
    }
    if (_validateContact(t) != null) {
      await _scrollToField(_contactPhoneFieldKey, _contactPhoneFocusNode);
      return;
    }
    if (_validateApplyLink(t) != null) {
      await _scrollToField(_applyLinkFieldKey, _applyLinkFocusNode);
    }
  }

  Future<void> _pickClosingDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _closingDate ?? now.add(const Duration(days: 30)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 2)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _closingDate = picked);
    }
  }

  Future<void> _save() async {
    final t = AppLocalizations.of(context);
    setState(() => _showValidationErrors = true);
    if (!_formKey.currentState!.validate()) {
      await _focusFirstInvalidField(t);
      return;
    }

    final draft = JobPostModel(
      id: widget.job?.id ?? 0,
      shopId: widget.job?.shopId ?? 0,
      title: _titleController.text,
      description: _descriptionController.text,
      jobType: _jobType,
      salaryNegotiable: _salaryNegotiable,
      salaryMin: _salaryNegotiable ? null : _parseSalary(_salaryMinController.text),
      salaryMax: _salaryNegotiable ? null : _parseSalary(_salaryMaxController.text),
      applyLink: _applyLinkController.text.trim().isEmpty
          ? null
          : _applyLinkController.text.trim(),
      contactPhone: _contactPhoneController.text.trim().isEmpty
          ? null
          : _contactPhoneController.text.trim(),
      status: _isActive ? JobPostStatus.active : JobPostStatus.inactive,
      closingDate: _closingDate,
    );

    setState(() => _isSaving = true);
    try {
      if (_isEditing) {
        await _service.updateJobPost(widget.job!.id, draft);
      } else {
        await _service.createJobPost(draft);
      }
      if (!mounted) return;
      AppDialog.showToast(
        context,
        t?.translate(_isEditing ? 'job_post_updated' : 'job_post_created') ??
            (_isEditing ? 'Job post updated' : 'Job post created'),
      );
      Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        AppDialog.showToast(
          context,
          t?.translate('failed_save_job_post') ?? 'Failed to save job post',
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B1120) : const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF0B1120) : const Color(0xFFF1F5F9),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              shape: BoxShape.circle,
            ),
            child: PhosphorIcon(
              PhosphorIconsRegular.arrowLeft,
              size: 18,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          t?.translate(_isEditing ? 'edit_job_post' : 'create_job_post') ??
              (_isEditing ? 'Edit Job Post' : 'Create Job Post'),
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        autovalidateMode: _showValidationErrors
            ? AutovalidateMode.always
            : AutovalidateMode.disabled,
        child: ListView(
          controller: _scrollController,
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 8,
            bottom: 24 + MediaQuery.of(context).viewInsets.bottom,
          ),
          children: [
            // ── Section: Job Info ──────────────────────────────────
            _buildSectionHeader(
              t?.translate('item_information') ?? 'Job Information',
              PhosphorIconsRegular.briefcase,
            ),
            _buildFormCard([
              _buildFieldLabel(t?.translate('job_title') ?? 'Job Title', required: true),
              TextFormField(
                key: _titleFieldKey,
                controller: _titleController,
                focusNode: _titleFocusNode,
                maxLength: 150,
                style: GoogleFonts.poppins(fontSize: 14),
                decoration: _inputDecoration(
                  t?.translate('job_title_hint') ?? 'e.g., Barista (Full Time)',
                  icon: PhosphorIconsRegular.identificationCard,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return t?.translate('job_validation_title') ??
                        'Please enter a job title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildFieldLabel(t?.translate('job_description') ?? 'Description', required: true),
              TextFormField(
                key: _descriptionFieldKey,
                controller: _descriptionController,
                focusNode: _descriptionFocusNode,
                maxLines: 5,
                maxLength: 5000,
                style: GoogleFonts.poppins(fontSize: 14),
                decoration: _inputDecoration(
                  t?.translate('job_description_hint') ??
                      'Describe responsibilities and requirements',
                  icon: PhosphorIconsRegular.textAlignLeft,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return t?.translate('job_validation_description') ??
                        'Please enter a description';
                  }
                  return null;
                },
              ),
            ]),

            // ── Section: Job Type ──────────────────────────────────
            _buildSectionHeader(
              t?.translate('job_type') ?? 'Job Type',
              PhosphorIconsRegular.clock,
            ),
            _buildFormCard([
              Row(
                children: [
                  Expanded(
                    child: _buildJobTypeButton(
                      label: t?.translate('job_full_time') ?? 'Full Time',
                      icon: PhosphorIconsFill.clock,
                      selected: _jobType == JobType.fullTime,
                      onTap: () => setState(() => _jobType = JobType.fullTime),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildJobTypeButton(
                      label: t?.translate('job_part_time') ?? 'Part Time',
                      icon: PhosphorIconsFill.clockCountdown,
                      selected: _jobType == JobType.partTime,
                      onTap: () => setState(() => _jobType = JobType.partTime),
                    ),
                  ),
                ],
              ),
            ]),

            // ── Section: Salary ────────────────────────────────────
            _buildSectionHeader(
              t?.translate('pricing') ?? 'Salary',
              PhosphorIconsRegular.currencyDollar,
            ),
            _buildFormCard([
              _buildSwitchRow(
                label: t?.translate('salary_negotiable') ?? 'Salary Negotiable',
                icon: PhosphorIconsRegular.handshake,
                value: _salaryNegotiable,
                onChanged: (v) => setState(() => _salaryNegotiable = v),
              ),
              if (!_salaryNegotiable) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFieldLabel(t?.translate('salary_min') ?? 'Min (THB)'),
                          TextFormField(
                            key: _salaryMinFieldKey,
                            controller: _salaryMinController,
                            focusNode: _salaryMinFocusNode,
                            keyboardType: TextInputType.number,
                            style: GoogleFonts.poppins(fontSize: 14),
                            decoration: _inputDecoration('0', icon: PhosphorIconsRegular.currencyDollar),
                            validator: (_) => _validateSalaryRange(t),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFieldLabel(t?.translate('salary_max') ?? 'Max (THB)'),
                          TextFormField(
                            key: _salaryMaxFieldKey,
                            controller: _salaryMaxController,
                            focusNode: _salaryMaxFocusNode,
                            keyboardType: TextInputType.number,
                            style: GoogleFonts.poppins(fontSize: 14),
                            decoration: _inputDecoration('0', icon: PhosphorIconsRegular.currencyDollar),
                            validator: (_) => _validateSalaryRange(t),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ]),

            // ── Section: Contact ───────────────────────────────────
            _buildSectionHeader(
              t?.translate('contact_location') ?? 'Contact',
              PhosphorIconsRegular.phone,
            ),
            _buildFormCard([
              _buildFieldLabel(t?.translate('contact_phone') ?? 'Contact Phone', required: true),
              TextFormField(
                key: _contactPhoneFieldKey,
                controller: _contactPhoneController,
                focusNode: _contactPhoneFocusNode,
                keyboardType: TextInputType.phone,
                maxLength: 11,
                style: GoogleFonts.poppins(fontSize: 14),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(11),
                ],
                decoration: _inputDecoration(
                  t?.translate('enter_phone_number') ?? 'Enter Phone Number',
                  icon: PhosphorIconsRegular.phone,
                ),
                validator: (_) => _validateContact(t),
              ),
              const SizedBox(height: 16),
              _buildFieldLabel(t?.translate('apply_link') ?? 'Apply Link (Optional)'),
              TextFormField(
                key: _applyLinkFieldKey,
                controller: _applyLinkController,
                focusNode: _applyLinkFocusNode,
                keyboardType: TextInputType.url,
                style: GoogleFonts.poppins(fontSize: 14),
                decoration: _inputDecoration(
                  'https://forms.gle/...',
                  icon: PhosphorIconsRegular.link,
                ),
                validator: (_) => _validateApplyLink(t),
              ),
            ]),

            // ── Section: Schedule ──────────────────────────────────
            _buildSectionHeader(
              t?.translate('closing_date') ?? 'Schedule',
              PhosphorIconsRegular.calendarBlank,
            ),
            _buildFormCard([
              _buildFieldLabel(t?.translate('closing_date') ?? 'Closing Date (Optional)'),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: _pickClosingDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF0B1120)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Theme.of(context).dividerColor),
                  ),
                  child: Row(
                    children: [
                      ShaderMask(
                        blendMode: BlendMode.srcIn,
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [AppColors.primary, Color(0xFFFB923C)],
                        ).createShader(bounds),
                        child: const PhosphorIcon(
                          PhosphorIconsRegular.calendarBlank,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _closingDate == null
                              ? (t?.translate('select_closing_date') ?? 'Select closing date (optional)')
                              : MaterialLocalizations.of(context).formatMediumDate(_closingDate!),
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: _closingDate == null
                                ? Theme.of(context).textTheme.bodySmall?.color
                                : Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                      ),
                      if (_closingDate != null)
                        GestureDetector(
                          onTap: () => setState(() => _closingDate = null),
                          child: const PhosphorIcon(
                            PhosphorIconsRegular.x,
                            size: 16,
                            color: Colors.red,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ]),

            // ── Section: Status (Edit only) ────────────────────────
            if (_isEditing) ...[
              _buildSectionHeader(
                t?.translate('status') ?? 'Status',
                PhosphorIconsRegular.toggleLeft,
              ),
              _buildFormCard([
                _buildSwitchRow(
                  label: t?.translate('job_status_active') ?? 'Active',
                  icon: PhosphorIconsRegular.checkCircle,
                  value: _isActive,
                  onChanged: (v) => setState(() => _isActive = v),
                  subtitle: _isActive
                      ? (t?.translate('job_status_active') ?? 'Job is visible to applicants')
                      : (t?.translate('job_status_closed') ?? 'Job is hidden from applicants'),
                ),
              ]),
            ],

            const SizedBox(height: 28),

            // ── Save Button ────────────────────────────────────────
            PrimaryGradientButton(
              onPressed: _isSaving ? null : _save,
              isLoading: _isSaving,
              height: 56,
              borderRadius: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  PhosphorIcon(
                    _isEditing ? PhosphorIconsRegular.floppyDisk : PhosphorIconsRegular.plus,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    t?.translate(_isEditing ? 'save_changes' : 'create_job_post') ??
                        (_isEditing ? 'Save Changes' : 'Create Job Post'),
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ── UI helpers ─────────────────────────────────────────────────────────────

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
      child: Row(
        children: [
          ShaderMask(
            blendMode: BlendMode.srcIn,
            shaderCallback: (bounds) => const LinearGradient(
              colors: [AppColors.primary, Color(0xFFFB923C)],
            ).createShader(bounds),
            child: PhosphorIcon(icon, size: 16, color: Colors.white),
          ),
          const SizedBox(width: 6),
          Text(
            title.toUpperCase(),
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard(List<Widget> children) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildFieldLabel(String text, {bool required = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: text,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
            if (required)
              const TextSpan(
                text: ' *',
                style: TextStyle(
                  color: Color(0xFFED3973),
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildJobTypeButton({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(
                  colors: [AppColors.primary, Color(0xFFFB923C)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: selected
              ? null
              : (Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF0B1120)
                  : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(12),
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
        child: Column(
          children: [
            PhosphorIcon(
              icon,
              size: 22,
              color: selected ? Colors.white : AppColors.outline,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchRow({
    required String label,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
    String? subtitle,
  }) {
    return Row(
      children: [
        ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) => const LinearGradient(
            colors: [AppColors.primary, Color(0xFFFB923C)],
          ).createShader(bounds),
          child: PhosphorIcon(icon, size: 18, color: Colors.white),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
            ],
          ),
        ),
        PrimaryGradientSwitch(value: value, onChanged: onChanged),
      ],
    );
  }

  InputDecoration _inputDecoration(String hint, {IconData? icon}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.poppins(
        fontSize: 14,
        color: Theme.of(context).textTheme.bodySmall?.color,
      ),
      prefixIcon: icon != null
          ? Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: ShaderMask(
                blendMode: BlendMode.srcIn,
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [AppColors.primary, Color(0xFFFB923C)],
                ).createShader(bounds),
                child: PhosphorIcon(icon, size: 18, color: Colors.white),
              ),
            )
          : null,
      prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 40),
      filled: true,
      fillColor: isDark ? const Color(0xFF0B1120) : const Color(0xFFF1F5F9),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Theme.of(context).dividerColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Theme.of(context).dividerColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFED3973)),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }
}
