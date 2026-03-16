import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

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
  bool _hasChanges = false;

  final List<String> _days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
  late List<_DayHours> _hours;

  @override
  void initState() {
    super.initState();
    _hours = [
      _DayHours(openTime: const TimeOfDay(hour: 9, minute: 0), closeTime: const TimeOfDay(hour: 22, minute: 0)),
      _DayHours(openTime: const TimeOfDay(hour: 9, minute: 0), closeTime: const TimeOfDay(hour: 22, minute: 0)),
      _DayHours(openTime: const TimeOfDay(hour: 9, minute: 0), closeTime: const TimeOfDay(hour: 22, minute: 0)),
      _DayHours(openTime: const TimeOfDay(hour: 9, minute: 0), closeTime: const TimeOfDay(hour: 22, minute: 0)),
      _DayHours(openTime: const TimeOfDay(hour: 9, minute: 0), closeTime: const TimeOfDay(hour: 22, minute: 0)),
      _DayHours(openTime: const TimeOfDay(hour: 9, minute: 0), closeTime: const TimeOfDay(hour: 22, minute: 0)),
      _DayHours(isClosed: true, openTime: const TimeOfDay(hour: 9, minute: 0), closeTime: const TimeOfDay(hour: 22, minute: 0)),
    ];
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
        backgroundColor: const Color(0xFF1E293B),
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

  void _save() {
    setState(() => _hasChanges = false);
    Navigator.of(context).pop();
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
          title: Text(
            'Operating Hours',
            style: GoogleFonts.poppins(
              color: const Color(0xFF1E293B),
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const PhosphorIcon(PhosphorIconsRegular.arrowLeft, size: 24, color: Color(0xFF1E293B)),
            onPressed: () async {
              final shouldPop = await _onWillPop();
              if (shouldPop && mounted) Navigator.of(context).pop();
            },
          ),
          actions: [
            TextButton(
              onPressed: _save,
              child: Text(
                'Save',
                style: GoogleFonts.poppins(
                  color: const Color(0xFFED3973),
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(1),
            child: Divider(height: 1, color: Color(0xFFE2E8F0)),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            const SizedBox(height: 16),
            // Open/Closed banner
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _isOpen ? const Color(0xFFECFDF5) : const Color(0xFFFFF1F2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isOpen ? const Color(0xFF10B981) : const Color(0xFFED3973),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    PhosphorIcon(
                      _isOpen ? PhosphorIconsRegular.storefront : PhosphorIconsRegular.door,
                      size: 24,
                      color: _isOpen ? const Color(0xFF10B981) : const Color(0xFFED3973),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isOpen ? 'Shop is Open' : 'Shop is Closed',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: _isOpen ? const Color(0xFF065F46) : const Color(0xFFBE123C),
                            ),
                          ),
                          Text(
                            'Toggle to change status immediately',
                            style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _isOpen,
                      activeThumbColor: const Color(0xFF10B981),
                      inactiveThumbColor: const Color(0xFFED3973),
                      onChanged: (v) {
                        setState(() => _isOpen = v);
                        _markChanged();
                      },
                    ),
                  ],
                ),
              ),
            ),
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
