// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:my_shop/features/profile/data/services/profile_service.dart';
import '../../../../core/presentation/widgets/custom_loading_indicator.dart';
import 'package:my_shop/features/main_navigation/presentation/screens/main_navigation_screen.dart';
import 'package:my_shop/core/presentation/widgets/primary_gradient_button.dart';
import 'package:my_shop/core/utils/app_colors.dart';
import 'package:my_shop/core/presentation/widgets/gradient_widgets.dart';

class OperatingHoursPage extends StatefulWidget {
  const OperatingHoursPage({super.key});

  @override
  State<OperatingHoursPage> createState() => _OperatingHoursPageState();
}

class _DayHours {
  bool isClosed;
  TimeOfDay openTime;
  TimeOfDay closeTime;

  _DayHours({
    this.isClosed = false,
    TimeOfDay? openTime,
    TimeOfDay? closeTime,
  })  : openTime = openTime ?? const TimeOfDay(hour: 9, minute: 0),
        closeTime = closeTime ?? const TimeOfDay(hour: 21, minute: 0);

  _DayHours copyWith({bool? isClosed, TimeOfDay? openTime, TimeOfDay? closeTime}) {
    return _DayHours(
      isClosed: isClosed ?? this.isClosed,
      openTime: openTime ?? this.openTime,
      closeTime: closeTime ?? this.closeTime,
    );
  }
}

class _OperatingHoursPageState extends State<OperatingHoursPage> {
  bool _hasChanges = false;
  bool _isSaving = false;
  bool _isLoadingHours = true;
  String? _loadError;

  // API uses 1-based dayOfWeek: 1=Mon, 2=Tue, 3=Wed, 4=Thu, 5=Fri, 6=Sat, 7=Sun
  // _hours index 0 = dayOfWeek 1 (Monday) ... index 6 = dayOfWeek 7 (Sunday)
  final List<String> _days = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
  ];
  late List<_DayHours> _hours;

  final ProfileService _profileService = ProfileService();

  @override
  void initState() {
    super.initState();
    // Default: all days open 09:00–21:00
    _hours = List.generate(
      7,
      (_) => _DayHours(
        isClosed: false,
        openTime: const TimeOfDay(hour: 9, minute: 0),
        closeTime: const TimeOfDay(hour: 21, minute: 0),
      ),
    );
    _fetchOperatingHours();
  }

  Future<void> _fetchOperatingHours() async {
    setState(() {
      _isLoadingHours = true;
      _loadError = null;
    });

    try {
      final hoursList = await _profileService.getOperatingHours();
      if (!mounted) return;

      if (hoursList.isNotEmpty) {
        final newHours = List.generate(
          7,
          (_) => _DayHours(
            isClosed: false,
            openTime: const TimeOfDay(hour: 9, minute: 0),
            closeTime: const TimeOfDay(hour: 21, minute: 0),
          ),
        );

        for (final h in hoursList) {
          // dayOfWeek 1=Mon...7=Sun → index = dayOfWeek - 1
          final idx = h.dayOfWeek - 1;
          if (idx >= 0 && idx < 7) {
            newHours[idx] = _DayHours(
              isClosed: h.isClosed,
              openTime: TimeOfDay(hour: h.openingTime.hour, minute: h.openingTime.minute),
              closeTime: TimeOfDay(hour: h.closingTime.hour, minute: h.closingTime.minute),
            );
          }
        }

        setState(() {
          _hours = newHours;
          _isLoadingHours = false;
        });
      } else {
        setState(() => _isLoadingHours = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingHours = false;
          _loadError = 'Failed to load operating hours.';
        });
      }
    }
  }

  void _markChanged() {
    if (!_hasChanges) setState(() => _hasChanges = true);
  }

  String _formatTime(TimeOfDay t) {
    final hour = t.hour.toString().padLeft(2, '0');
    final minute = t.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _toApiTimeString(TimeOfDay t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m:00';
  }

  Future<void> _pickTime(int dayIndex, bool isOpen) async {
    final current = isOpen ? _hours[dayIndex].openTime : _hours[dayIndex].closeTime;
    final picked = await showTimePicker(
      context: context,
      initialTime: current,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: AppColors.primary),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isOpen) {
          _hours[dayIndex] = _hours[dayIndex].copyWith(openTime: picked);
        } else {
          _hours[dayIndex] = _hours[dayIndex].copyWith(closeTime: picked);
        }
      });
      _markChanged();
    }
  }

  void _copyToAllDays(int sourceIndex) {
    setState(() {
      for (int i = 0; i < _hours.length; i++) {
        if (i != sourceIndex) {
          _hours[i] = _DayHours(
            isClosed: _hours[sourceIndex].isClosed,
            openTime: _hours[sourceIndex].openTime,
            closeTime: _hours[sourceIndex].closeTime,
          );
        }
      }
    });
    _markChanged();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${_days[sourceIndex]}\'s hours copied to all days',
          style: GoogleFonts.poppins(fontSize: 13),
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Image.asset('assets/images/app_logo.png', width: 24, height: 24),
            const SizedBox(width: 8),
            Text('Discard changes?', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16)),
          ],
        ),
        content: Text(
          'You have unsaved changes. Do you want to discard them?',
          style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF475569)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Continue Editing', style: GoogleFonts.poppins(color: const Color(0xFF475569), fontWeight: FontWeight.w500)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: GradientText('Discard', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);

    // Build payload with 1-based dayOfWeek and multiple time formats for compatibility
    final activeHours = <Map<String, dynamic>>[];
    for (int i = 0; i < _hours.length; i++) {
      final oh = _hours[i];
      final timeStrOpen = _toApiTimeString(oh.openTime);
      final timeStrClose = _toApiTimeString(oh.closeTime);
      final timeObjOpen = {
        'hour': oh.openTime.hour,
        'minute': oh.openTime.minute,
        'second': 0,
        'nano': 0
      };
      final timeObjClose = {
        'hour': oh.closeTime.hour,
        'minute': oh.closeTime.minute,
        'second': 0,
        'nano': 0
      };

      activeHours.add({
        'dayOfWeek': i + 1, // 1=Mon...7=Sun
        'openTime': timeStrOpen,
        'openingTime': timeStrOpen, // Send both keys just in case
        'closeTime': timeStrClose,
        'closingTime': timeStrClose, // Send both keys just in case
        'openTimeObj': timeObjOpen, // Some backends want the object
        'closeTimeObj': timeObjClose,
        'isClosed': oh.isClosed,
      });
    }

    final payload = {'activeHours': activeHours};

    final response = await _profileService.updateOperatingHours(payload);
    final bool isSuccess = response['success'] == true;

    if (!context.mounted) return;

    if (isSuccess) {
      setState(() {
        _isSaving = false;
        _hasChanges = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Operating hours saved successfully!'),
          backgroundColor: AppColors.primary,
        ),
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const MainNavigationScreen(initialIndex: 3)),
        (route) => false,
      );
    } else {
      setState(() => _isSaving = false);
      final errorMessage = response['message'] ?? 'Failed to save operating hours. Please try again.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () async {
              final shouldPop = await _onWillPop();
              if (shouldPop && context.mounted) Navigator.of(context).pop();
            },
          ),
          title: Text(
            'Operating Hours',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1E293B),
            ),
          ),
          centerTitle: false,
          actions: const [SizedBox(width: 8)],
        ),
        body: _isLoadingHours
            ? const Center(child: CustomLoadingIndicator())
            : _loadError != null
                ? _buildErrorState()
                : _buildContent(),
        bottomNavigationBar: _isLoadingHours
            ? null
            : SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: PrimaryGradientButton(
                      onPressed: _save,
                      isLoading: _isSaving,
                      text: 'Save',
                      height: 56,
                      borderRadius: 16,
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Color(0xFFEF4444)),
            const SizedBox(height: 16),
            Text(
              _loadError!,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: const Color(0xFF1E293B)),
            ),
            const SizedBox(height: 24),
            PrimaryGradientButton(
              onPressed: _fetchOperatingHours,
              text: 'Retry',
              height: 48,
              borderRadius: 12,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        const SizedBox(height: 16),
        // Day rows
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            children: List.generate(_days.length, (i) {
              final day = _days[i];
              final h = _hours[i];
              final isLast = i == _days.length - 1;
              return Column(
                children: [
                  Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      childrenPadding: EdgeInsets.zero,
                      title: Row(
                        children: [
                          SizedBox(
                            width: 100,
                            child: Text(
                              day,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1E293B),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              h.isClosed
                                  ? 'Closed'
                                  : '${_formatTime(h.openTime)} – ${_formatTime(h.closeTime)}',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: h.isClosed ? AppColors.primary : const Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ],
                      ),
                      trailing: PhosphorIcon(
                        PhosphorIconsRegular.caretDown,
                        size: 16,
                        color: const Color(0xFF94A3B8),
                      ),
                      children: [
                        Container(
                          color: const Color(0xFFF8FAFC),
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                          child: Column(
                            children: [
                              if (!h.isClosed) ...[
                                _TimePickerRow(
                                  label: 'Open',
                                  time: h.openTime,
                                  onTap: () => _pickTime(i, true),
                                ),
                                const SizedBox(height: 10),
                                _TimePickerRow(
                                  label: 'Close',
                                  time: h.closeTime,
                                  onTap: () => _pickTime(i, false),
                                ),
                                const SizedBox(height: 12),
                              ],
                              Row(
                                children: [
                                  Icon(
                                    h.isClosed ? Icons.add_circle_outline : Icons.remove_circle_outline,
                                    size: 18,
                                    color: h.isClosed ? const Color(0xFF10B981) : AppColors.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: () {
                                      setState(() => _hours[i] = _hours[i].copyWith(isClosed: !h.isClosed));
                                      _markChanged();
                                    },
                                    child: Text(
                                      h.isClosed ? 'Set hours for this day' : 'Mark as closed',
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: h.isClosed ? const Color(0xFF10B981) : AppColors.primary,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  InkWell(
                                    borderRadius: BorderRadius.circular(6),
                                    onTap: () => _copyToAllDays(i),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      child: Row(
                                        children: [
                                          const PhosphorIcon(PhosphorIconsRegular.copy, size: 14, color: Color(0xFF64748B)),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Copy to all',
                                            style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF64748B)),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isLast)
                    const Divider(height: 1, color: Color(0xFFE2E8F0), indent: 16, endIndent: 16),
                ],
              );
            }),
          ),
        ),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Changes are saved when you tap the Save button.',
            style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF94A3B8)),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}

class _TimePickerRow extends StatelessWidget {
  final String label;
  final TimeOfDay time;
  final VoidCallback onTap;

  const _TimePickerRow({required this.label, required this.time, required this.onTap});

  String _fmt(TimeOfDay t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF64748B), fontWeight: FontWeight.w500),
            ),
            const Spacer(),
            Text(
              _fmt(time),
              style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B)),
            ),
            const SizedBox(width: 8),
            const PhosphorIcon(PhosphorIconsRegular.clock, size: 16, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }
}
