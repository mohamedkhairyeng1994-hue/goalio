import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/constants.dart';
import '../../core/utils/size_config.dart';
import '../../core/services/api_service.dart';

class CreateSocialPostPage extends StatefulWidget {
  const CreateSocialPostPage({super.key});

  @override
  State<CreateSocialPostPage> createState() => _CreateSocialPostPageState();
}

class _CreateSocialPostPageState extends State<CreateSocialPostPage> {
  // Backend cap is 20MB (mimes:jpg,jpeg,png,gif,mp4,mov | max:20480 KB).
  // Mirror it client-side so we reject before the upload starts.
  static const int _maxBytes = 20 * 1024 * 1024;

  final TextEditingController _controller = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  XFile? _media;
  String? _mediaKind; // 'image' | 'video'
  bool _isSubmitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (_isSubmitting) return;
    try {
      final XFile? file = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        imageQuality: 85,
      );
      if (file == null || !mounted) return;
      if (!await _enforceSize(file)) return;
      setState(() {
        _media = file;
        _mediaKind = 'image';
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not pick image: $e')),
      );
    }
  }

  Future<void> _pickVideo() async {
    if (_isSubmitting) return;
    try {
      final XFile? file = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 2),
      );
      if (file == null || !mounted) return;
      if (!await _enforceSize(file)) return;
      setState(() {
        _media = file;
        _mediaKind = 'video';
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not pick video: $e')),
      );
    }
  }

  Future<bool> _enforceSize(XFile file) async {
    final size = await file.length();
    if (size <= _maxBytes) return true;
    if (!mounted) return false;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('File is too large. Max 20 MB.')),
    );
    return false;
  }

  void _removeMedia() {
    setState(() {
      _media = null;
      _mediaKind = null;
    });
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty && _media == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add a caption or attach a photo/video')),
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
    final result = await ApiService.createSocialPost(
      content: text.isEmpty ? null : text,
      mediaPath: _media?.path,
    );
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
            if (_media != null) ...[
              SizedBox(height: 12.h),
              _buildMediaPreview(isDark),
            ],
            SizedBox(height: 12.h),
            _buildAttachBar(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachBar(bool isDark) {
    final disabled = _isSubmitting || _media != null;
    return Row(
      children: [
        Expanded(
          child: _AttachButton(
            icon: Icons.image_outlined,
            label: 'Photo',
            isDark: isDark,
            onTap: disabled ? null : _pickImage,
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: _AttachButton(
            icon: Icons.videocam_outlined,
            label: 'Video',
            isDark: isDark,
            onTap: disabled ? null : _pickVideo,
          ),
        ),
      ],
    );
  }

  Widget _buildMediaPreview(bool isDark) {
    final isVideo = _mediaKind == 'video';
    final filename = _media!.name;

    return Container(
      padding: EdgeInsets.all(8.w),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12.w),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8.w),
            child: SizedBox(
              width: 56.w,
              height: 56.w,
              child: isVideo
                  ? Container(
                      color: Colors.black,
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.play_circle_fill,
                        color: GoalioColors.greenAccent,
                        size: 28.w,
                      ),
                    )
                  : Image.file(
                      File(_media!.path),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.black26,
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.broken_image_outlined,
                          color: Colors.white54,
                          size: 22.w,
                        ),
                      ),
                    ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isVideo ? 'Video attached' : 'Photo attached',
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w600,
                    fontSize: 13.sp,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  filename,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isDark ? Colors.white54 : Colors.black54,
                    fontSize: 11.sp,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Remove',
            onPressed: _isSubmitting ? null : _removeMedia,
            icon: Icon(
              Icons.close_rounded,
              color: isDark ? Colors.white70 : Colors.black54,
              size: 20.w,
            ),
          ),
        ],
      ),
    );
  }
}

class _AttachButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  final VoidCallback? onTap;

  const _AttachButton({
    required this.icon,
    required this.label,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.w),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 12.w),
          decoration: BoxDecoration(
            color: enabled
                ? GoalioColors.greenAccent.withValues(alpha: 0.10)
                : (isDark
                    ? Colors.white.withValues(alpha: 0.04)
                    : Colors.black.withValues(alpha: 0.03)),
            borderRadius: BorderRadius.circular(12.w),
            border: Border.all(
              color: enabled
                  ? GoalioColors.greenAccent.withValues(alpha: 0.4)
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.08)),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: enabled
                    ? GoalioColors.greenAccent
                    : (isDark ? Colors.white38 : Colors.black38),
                size: 20.w,
              ),
              SizedBox(width: 8.w),
              Text(
                label,
                style: TextStyle(
                  color: enabled
                      ? GoalioColors.greenAccent
                      : (isDark ? Colors.white38 : Colors.black38),
                  fontWeight: FontWeight.w700,
                  fontSize: 13.sp,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
