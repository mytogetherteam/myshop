// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:my_shop/features/profile/data/models/shop_profile_model.dart';
import 'package:my_shop/features/profile/data/services/profile_service.dart';
import '../../../../core/presentation/widgets/custom_loading_indicator.dart';
import 'package:my_shop/features/main_navigation/presentation/screens/main_navigation_screen.dart';

class OperatingHoursPage extends StatefulWidget {
  final ShopProfileModel? shopProfile;
  const OperatingHoursPage({super.key, this.shopProfile});

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
        closeTime = closeTime ?? const TimeOfDay(hour: 22, minute: 0);

  _DayHours copyWith({bool? isClosed, TimeOfDay? openTime, TimeOfDay? closeTime}) {
    return _DayHours(
      isClosed: isClosed ?? this.isClosed,
      openTime: openTime ?? this.openTime,
      closeTime: closeTime ?? this.closeTime,
    );
  }
}

class _OperatingHoursPageState extends State<OperatingHoursPage> {
  bool _isOpen = true;
  bool _isTogglingStatus = false;
  bool _hasChanges = false;
  bool _isSaving = false;

  final List<String> _days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
  late List<_DayHours> _hours;

  final ProfileService _profileService = ProfileService();

  @override
  void initState() {
    super.initState();
    final profile = widget.shopProfile;
    _isOpen = profile?.isOpen ?? true; // Default to true in demo if not set
    
    // Initialize with default 9am-10pm closed all over
    _hours = List.generate(7, (index) => _DayHours(isClosed: true, openTime: const TimeOfDay(hour: 9, minute: 0), closeTime: const TimeOfDay(hour: 22, minute: 0)));

    if (profile != null && profile.operatingHours.isNotEmpty) {
      for (final h in profile.operatingHours) {
        if (h.dayOfWeek >= 0 && h.dayOfWeek <= 6) {
          _hours[h.dayOfWeek] = _DayHours(
            isClosed: h.isClosed,
            openTime: TimeOfDay(hour: h.openingTime.hour, minute: h.openingTime.minute),
            closeTime: TimeOfDay(hour: h.closingTime.hour, minute: h.closingTime.minute),
          );
        }
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

  Future<void> _pickTime(int dayIndex, bool isOpen) async {
    final current = isOpen ? _hours[dayIndex].openTime : _hours[dayIndex].closeTime;
    final picked = await showTimePicker(
      context: context,
      initialTime: current,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFFED3973)),
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
        backgroundColor: const Color(0xFFED3A72),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Discard changes?', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16)),
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
            child: Text('Discard', style: GoogleFonts.poppins(color: const Color(0xFFED3973), fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    
    final activeHours = [];
    for (int i = 0; i < _hours.length; i++) {
        final oh = _hours[i];
        activeHours.add({
            'dayOfWeek': i,
            'openTime': {
                'hour': oh.openTime.hour,
                'minute': oh.openTime.minute,
                'second': 0,
                'nano': 0
            },
            'closeTime': {
                'hour': oh.closeTime.hour,
                'minute': oh.closeTime.minute,
                'second': 0,
                'nano': 0
            },
            'isClosed': oh.isClosed
        });
    }
    
    final payload = {
      'activeHours': activeHours
    };

    final success = await _profileService.updateOperatingHours(payload);
    
    if (!context.mounted) return;

    if (success) {
      setState(() {
          _isSaving = false;
          _hasChanges = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Operating hours saved successfully',
            style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          backgroundColor: const Color(0xFFED3973),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(20),
        ),
      );
      // Simply pop back with true result to signal refresh
      Navigator.pop(context, true);
    } else {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to save operating hours. Please try again.',
            style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(20),
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
          actions: const [
            SizedBox(width: 8),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            const SizedBox(height: 16),
            _buildSectionTitle('Active Status'),
            const SizedBox(height: 16),
            // Open/Closed banner
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _isOpen ? const Color(0xFF10B981) : const Color(0xFFED3973),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (_isOpen ? const Color(0xFF10B981) : const Color(0xFFED3973)).withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: (_isOpen ? const Color(0xFF10B981) : const Color(0xFFED3973)).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: PhosphorIcon(
                        _isOpen ? PhosphorIconsRegular.storefront : PhosphorIconsRegular.door,
                        size: 24,
                        color: _isOpen ? const Color(0xFF10B981) : const Color(0xFFED3973),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isOpen ? 'Currently Open' : 'Currently Closed',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: const Color(0xFF1E293B),
                            ),
                          ),
                          Text(
                            'Toggle to update real-time status',
                            style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                    _isTogglingStatus
                        ? const CustomLoadingIndicator(size: 24, color: Color(0xFFED3973))
                        : Switch(
                            value: _isOpen,
                            activeColor: const Color(0xFFED3973),
                            onChanged: (v) async {
                              setState(() => _isTogglingStatus = true);
                              final success = await _profileService.toggleShopStatus(v);
                              if (context.mounted) {
                                if (success) {
                                  setState(() {
                                    _isOpen = v;
                                    _isTogglingStatus = false;
                                  });
                                } else {
                                  setState(() => _isTogglingStatus = false);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Failed to change shop status.',
                                        style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500),
                                      ),
                                      backgroundColor: const Color(0xFFEF4444),
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      margin: const EdgeInsets.all(20),
                                    ),
                                  );
                                }
                              }
                            },
                          ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            _buildSectionTitle('Weekly Schedule'),
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
                                    color: h.isClosed ? const Color(0xFFED3973) : const Color(0xFF64748B),
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
                                    // Open time row
                                    _TimePickerRow(
                                      label: 'Open',
                                      time: h.openTime,
                                      onTap: () => _pickTime(i, true),
                                    ),
                                    const SizedBox(height: 10),
                                    // Close time row
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
                                        color: h.isClosed ? const Color(0xFF10B981) : const Color(0xFFED3973),
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
                                            color: h.isClosed ? const Color(0xFF10B981) : const Color(0xFFED3973),
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
            // Save hint
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Changes are saved when you tap the Save button.',
                style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF94A3B8)),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFED3973),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: _isSaving 
                  ? const CustomLoadingIndicator(size: 24, color: Colors.white)
                  : Text(
                      'Save',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF94A3B8),
          letterSpacing: 1.0,
        ),
      ),
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
