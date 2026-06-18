import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_shop/core/localization/app_localizations.dart';
import 'package:my_shop/core/presentation/widgets/keyboard_padding_wrapper.dart';

class CancelOrderDialog extends StatefulWidget {
  final Future<bool> Function(String reason) onConfirm;

  const CancelOrderDialog({
    super.key,
    required this.onConfirm,
  });

  @override
  State<CancelOrderDialog> createState() => _CancelOrderDialogState();
}

class _CancelOrderDialogState extends State<CancelOrderDialog> {
  late final TextEditingController _reasonController;

  @override
  void initState() {
    super.initState();
    _reasonController = TextEditingController();
  }

  @override
  void dispose() {
    // Delay disposal to ensure TextField has fully unmounted and 
    // won't attempt to access a disposed controller during exit animation.
    final controllerToDispose = _reasonController;
    Future.delayed(const Duration(milliseconds: 500), () {
      controllerToDispose.dispose();
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return KeyboardPaddingWrapper(
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                t?.translate('cancel_order') ?? 'Cancel Order',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                t?.translate('cancel_order_confirm') ??
                    'Are you sure you want to cancel this order? This action cannot be undone.',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                t?.translate('cancel_reason') ?? 'Reason for Cancellation',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF475569),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _reasonController,
                maxLines: 3,
                style: GoogleFonts.poppins(fontSize: 14),
                decoration: InputDecoration(
                  hintText: t?.translate('cancel_reason_hint') ?? 'Enter reason here...',
                  hintStyle: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[400]),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        FocusScope.of(context).unfocus();
                        Future.delayed(const Duration(milliseconds: 300), () {
                          if (mounted) {
                            Navigator.pop(context);
                          }
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      child: Text(
                        t?.translate('no_go_back') ?? 'No, Go Back',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        FocusScope.of(context).unfocus();
                        final reason = _reasonController.text.trim();
                        final success = await widget.onConfirm(reason);
                        if (success && mounted) {
                          // Wait for keyboard to close before popping to avoid unmount crashes
                          await Future.delayed(const Duration(milliseconds: 300));
                          if (mounted) {
                            Navigator.pop(context);
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        t?.translate('yes_cancel_order') ?? 'Yes, Cancel Order',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
