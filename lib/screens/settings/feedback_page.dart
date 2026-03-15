import 'package:flutter/material.dart';
import '../../core/services/api_service.dart';
import '../../core/utils/messages.dart';
import '../../core/constants/constants.dart';
import '../../core/utils/size_config.dart';
import '../../l10n/app_localizations.dart';

class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  final TextEditingController _contentController = TextEditingController();
  String _type = 'suggestion';
  bool _isSubmitting = false;

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _submitFeedback() async {
    final content = _contentController.text.trim();
    if (content.isEmpty) {
      GoalioMessages.showWarning(
        context,
        AppLocalizations.of(context)!.pleaseEnterFeedback,
      );
      return;
    }

    if (content.length < 5) {
      GoalioMessages.showWarning(
        context,
        AppLocalizations.of(context)!.feedbackTooShort,
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final success = await ApiService.sendFeedback(
        type: _type,
        content: content,
      );

      if (mounted) {
        if (success) {
          GoalioMessages.showSuccess(
            context,
            AppLocalizations.of(context)!.feedbackSentSuccess,
          );
          Navigator.pop(context);
        } else {
          GoalioMessages.showError(
            context,
            AppLocalizations.of(context)!.feedbackSentError,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        GoalioMessages.showError(context, "Error: $e");
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(l10n.feedbackAndSuggestions),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.feedbackDescription,
              style: TextStyle(
                fontSize: 14.sp,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
            SizedBox(height: 24.h),
            
            // Type Selection
            Text(
              l10n.feedbackType,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16.sp,
                color: GoalioColors.greenAccent,
              ),
            ),
            SizedBox(height: 12.h),
            Row(
              children: [
                _buildTypeChip(l10n.suggestion, 'suggestion'),
                SizedBox(width: 12.w),
                _buildTypeChip(l10n.complaint, 'complaint'),
              ],
            ),
            SizedBox(height: 32.h),

            // Content Field
            Text(
              l10n.feedbackContent,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16.sp,
                color: GoalioColors.greenAccent,
              ),
            ),
            SizedBox(height: 12.h),
            TextField(
              controller: _contentController,
              maxLines: 6,
              maxLength: 1000,
              decoration: InputDecoration(
                hintText: l10n.feedbackHint,
                filled: true,
                fillColor: Theme.of(context).cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.w),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.all(16.w),
                counterStyle: TextStyle(
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
            ),
            SizedBox(height: 40.h),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 54.h,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitFeedback,
                style: ElevatedButton.styleFrom(
                  backgroundColor: GoalioColors.greenAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.w),
                  ),
                  elevation: 0,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        l10n.submit,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeChip(String label, String value) {
    final isSelected = _type == value;
    return GestureDetector(
      onTap: () => setState(() => _type = value),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: isSelected ? GoalioColors.greenAccent : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20.w),
          border: Border.all(
            color: isSelected ? GoalioColors.greenAccent : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Theme.of(context).textTheme.bodyMedium?.color,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
