import 'package:flutter/material.dart';
import '../../core/constants/constants.dart';
import '../../core/utils/size_config.dart';
import '../../core/services/api_service.dart';

class CreateSocialPostPage extends StatefulWidget {
  const CreateSocialPostPage({super.key});

  @override
  State<CreateSocialPostPage> createState() => _CreateSocialPostPageState();
}

class _CreateSocialPostPageState extends State<CreateSocialPostPage> {
  final TextEditingController _controller = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please write something to share')),
      );
      return;
    }

    final token = await ApiService.getToken();
    if (token == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to post')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final result = await ApiService.createSocialPost(content: text);
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (result['error'] != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: ${result['error']}')),
      );
      return;
    }

    Navigator.of(context).pop(true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Submitted! Your post is pending admin approval.'),
        duration: Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Create Post'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        actions: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.w),
            child: TextButton(
              onPressed: _isSubmitting ? null : _submit,
              child: _isSubmitting
                  ? SizedBox(
                      width: 18.w,
                      height: 18.w,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        color: GoalioColors.greenAccent,
                      ),
                    )
                  : const Text(
                      'Post',
                      style: TextStyle(
                        color: GoalioColors.greenAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: GoalioColors.greenAccent.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12.w),
                border: Border.all(
                  color: GoalioColors.greenAccent.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      color: GoalioColors.greenAccent, size: 20.w),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      'Posts are reviewed by an admin before going live.',
                      style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black87,
                        fontSize: 13.sp,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),
            Expanded(
              child: TextField(
                controller: _controller,
                maxLines: null,
                expands: true,
                maxLength: 2000,
                textAlignVertical: TextAlignVertical.top,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: 16.sp,
                ),
                decoration: InputDecoration(
                  hintText: "What's on your mind?",
                  hintStyle: TextStyle(
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16.w),
                    borderSide: BorderSide(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.1),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16.w),
                    borderSide: BorderSide(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.1),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16.w),
                    borderSide: const BorderSide(
                      color: GoalioColors.greenAccent,
                      width: 1.5,
                    ),
                  ),
                  contentPadding: EdgeInsets.all(16.w),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
