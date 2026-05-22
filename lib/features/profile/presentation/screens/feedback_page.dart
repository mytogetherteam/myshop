import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:my_shop/core/presentation/widgets/primary_gradient_button.dart';
import 'package:my_shop/core/presentation/widgets/app_dialog.dart';
import 'package:my_shop/core/localization/app_localizations.dart';
import '../../data/models/feedback_model.dart';
import '../../data/services/feedback_service.dart';
import 'package:intl/intl.dart';

class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  final FeedbackService _feedbackService = FeedbackService();
  List<FeedbackModel> _feedbacks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFeedbacks();
  }

  Future<void> _loadFeedbacks() async {
    setState(() => _isLoading = true);
    final feedbacks = await _feedbackService.getFeedbacks();
    if (mounted) {
      setState(() {
        _feedbacks = feedbacks;
        _isLoading = false;
      });
    }
  }

  void _showSubmitFeedbackDialog() {
    showDialog(
      context: context,
      builder: (context) => const SubmitFeedbackDialog(),
    ).then((submitted) {
      if (submitted == true) {
        _loadFeedbacks();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          t?.translate('feedback') ?? 'Feedback',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1E293B),
          ),
        ),
        centerTitle: false,
      ),
      body: _isLoading
          ? const Center(child: CupertinoActivityIndicator())
          : _feedbacks.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      PhosphorIcon(
                        PhosphorIconsRegular.chatCircleText,
                        size: 64,
                        color: const Color(0xFFCBD5E1),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        t?.translate('no_feedback_yet') ?? 'No feedback yet',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadFeedbacks,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(24),
                    itemCount: _feedbacks.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final feedback = _feedbacks[index];
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              feedback.description,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: const Color(0xFF1E293B),
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              DateFormat('MMM d, yyyy').format(feedback.createdAt),
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: const Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showSubmitFeedbackDialog,
        backgroundColor: const Color(0xFFED3973),
        icon: const PhosphorIcon(PhosphorIconsRegular.plus, color: Colors.white),
        label: Text(
          t?.translate('submit_feedback') ?? 'Submit Feedback',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class SubmitFeedbackDialog extends StatefulWidget {
  const SubmitFeedbackDialog({super.key});

  @override
  State<SubmitFeedbackDialog> createState() => _SubmitFeedbackDialogState();
}

class _SubmitFeedbackDialogState extends State<SubmitFeedbackDialog> {
  final _feedbackController = TextEditingController();
  final _feedbackService = FeedbackService();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final t = AppLocalizations.of(context);
    final text = _feedbackController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSubmitting = true);

    final success = await _feedbackService.createFeedback(text);

    if (!mounted) return;

    setState(() => _isSubmitting = false);

    if (success) {
      AppDialog.showToast(
        context,
        t?.translate('feedback_submitted') ?? 'Feedback submitted successfully',
      );
      Navigator.pop(context, true);
    } else {
      AppDialog.showToast(
        context,
        t?.translate('failed_submit_feedback') ?? 'Failed to submit feedback',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t?.translate('submit_feedback') ?? 'Submit Feedback',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _feedbackController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: t?.translate('feedback_hint') ?? 'Tell us what you think...',
                hintStyle: GoogleFonts.poppins(
                  color: const Color(0xFF94A3B8),
                  fontSize: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFED3973)),
                ),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                    child: Text(
                      t?.translate('cancel') ?? 'Cancel',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: PrimaryGradientButton(
                    onPressed: _isSubmitting ? null : _submit,
                    text: t?.translate('submit') ?? 'Submit',
                    isLoading: _isSubmitting,
                    height: 48,
                    borderRadius: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
