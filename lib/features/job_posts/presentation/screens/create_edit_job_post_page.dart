import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_shop/core/localization/app_localizations.dart';
import 'package:my_shop/core/presentation/widgets/app_dialog.dart';
import 'package:my_shop/core/presentation/widgets/back_title_app_bar.dart';
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
    if (link.isEmpty) {
      return null;
    }
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
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      await _scrollToField(_titleFieldKey, _titleFocusNode);
      return;
    }

    final description = _descriptionController.text.trim();
    if (description.isEmpty) {
      await _scrollToField(_descriptionFieldKey, _descriptionFocusNode);
      return;
    }

    final salaryRangeError = _validateSalaryRange(t);
    if (salaryRangeError != null) {
      await _scrollToField(_salaryMaxFieldKey, _salaryMaxFocusNode);
      return;
    }

    final contactError = _validateContact(t);
    if (contactError != null) {
      await _scrollToField(_contactPhoneFieldKey, _contactPhoneFocusNode);
      return;
    }

    final applyLinkError = _validateApplyLink(t);
    if (applyLinkError != null) {
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
    return Scaffold(
      appBar: BackTitleAppBar(
        title: t?.translate(_isEditing ? 'edit_job_post' : 'create_job_post') ??
            (_isEditing ? 'Edit Job Post' : 'Create Job Post'),
      ),
      body: Form(
        key: _formKey,
        autovalidateMode:
            _showValidationErrors
                ? AutovalidateMode.always
                : AutovalidateMode.disabled,
        child: ListView(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            _buildLabel(t?.translate('job_title') ?? 'Job Title'),
            TextFormField(
              key: _titleFieldKey,
              controller: _titleController,
              focusNode: _titleFocusNode,
              maxLength: 150,
              decoration: _inputDecoration(
                t?.translate('job_title_hint') ?? 'e.g., Barista (Full Time)',
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
            _buildLabel(t?.translate('job_description') ?? 'Description'),
            TextFormField(
              key: _descriptionFieldKey,
              controller: _descriptionController,
              focusNode: _descriptionFocusNode,
              maxLines: 5,
              maxLength: 5000,
              decoration: _inputDecoration(
                t?.translate('job_description_hint') ??
                    'Describe responsibilities and requirements',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return t?.translate('job_validation_description') ??
                      'Please enter a description';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildLabel(t?.translate('job_type') ?? 'Job Type'),
            SegmentedButton<JobType>(
              segments: [
                ButtonSegment(
                  value: JobType.fullTime,
                  label: Text(t?.translate('job_full_time') ?? 'Full Time'),
                ),
                ButtonSegment(
                  value: JobType.partTime,
                  label: Text(t?.translate('job_part_time') ?? 'Part Time'),
                ),
              ],
              selected: {_jobType},
              onSelectionChanged: (selection) {
                setState(() => _jobType = selection.first);
              },
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildLabel(
                    t?.translate('salary_negotiable') ?? 'Salary Negotiable',
                  ),
                ),
                PrimaryGradientSwitch(
                  value: _salaryNegotiable,
                  onChanged: (value) {
                    setState(() => _salaryNegotiable = value);
                  },
                ),
              ],
            ),
            if (!_salaryNegotiable) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      key: _salaryMinFieldKey,
                      controller: _salaryMinController,
                      focusNode: _salaryMinFocusNode,
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration(
                        t?.translate('salary_min') ?? 'Min (THB)',
                      ),
                      validator: (_) => _validateSalaryRange(t),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      key: _salaryMaxFieldKey,
                      controller: _salaryMaxController,
                      focusNode: _salaryMaxFocusNode,
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration(
                        t?.translate('salary_max') ?? 'Max (THB)',
                      ),
                      validator: (_) => _validateSalaryRange(t),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 20),
            _buildLabel(t?.translate('contact_phone') ?? 'Contact Phone'),
            TextFormField(
              key: _contactPhoneFieldKey,
              controller: _contactPhoneController,
              focusNode: _contactPhoneFocusNode,
              keyboardType: TextInputType.phone,
              maxLength: 11,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(11),
              ],
              decoration: _inputDecoration(
                t?.translate('enter_phone_number') ?? 'Enter Phone Number',
              ),
              validator: (_) => _validateContact(t),
            ),
            const SizedBox(height: 16),
            _buildLabel(t?.translate('apply_link') ?? 'Apply Link'),
            TextFormField(
              key: _applyLinkFieldKey,
              controller: _applyLinkController,
              focusNode: _applyLinkFocusNode,
              keyboardType: TextInputType.url,
              decoration: _inputDecoration('https://forms.gle/...'),
              validator: (_) => _validateApplyLink(t),
            ),
            const SizedBox(height: 20),
            _buildLabel(t?.translate('closing_date') ?? 'Closing Date'),
            OutlinedButton.icon(
              onPressed: _pickClosingDate,
              icon: const PhosphorIcon(PhosphorIconsRegular.calendarBlank),
              label: Text(
                _closingDate == null
                    ? (t?.translate('select_closing_date') ??
                        'Select closing date (optional)')
                    : MaterialLocalizations.of(context)
                        .formatMediumDate(_closingDate!),
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                alignment: Alignment.centerLeft,
              ),
            ),
            if (_closingDate != null)
              TextButton(
                onPressed: () => setState(() => _closingDate = null),
                child: Text(t?.translate('clear_date') ?? 'Clear date'),
              ),
            if (_isEditing) ...[
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _buildLabel(
                      t?.translate('job_status_active') ?? 'Active',
                    ),
                  ),
                  PrimaryGradientSwitch(
                    value: _isActive,
                    onChanged: (value) => setState(() => _isActive = value),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 28),
            PrimaryGradientButton(
              onPressed: _isSaving ? null : _save,
              isLoading: _isSaving,
              child: Text(
                t?.translate(_isEditing ? 'save_changes' : 'create_job_post') ??
                    (_isEditing ? 'Save Changes' : 'Create Job Post'),
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.onSurface,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
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
    );
  }
}
