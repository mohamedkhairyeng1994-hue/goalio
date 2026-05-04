import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/constants.dart';
import '../../core/models/story.dart';
import '../../core/services/api_service.dart';
import '../../core/services/repositories/stories_repository.dart';
import '../../core/utils/size_config.dart';
import 'story_viewer_page.dart';

/// Horizontal rail of circular story tiles shown on the home screen.
/// First tile is "Add Your Story" — opens an image picker, uploads to backend,
/// and shows a "pending approval" snackbar. Other tiles open the story viewer.
///
/// Pass [refreshTrigger] from the parent to refetch on pull-to-refresh — the
/// rail listens for value changes and re-runs [_load] each time.
class StoriesRail extends StatefulWidget {
  final Listenable? refreshTrigger;

  const StoriesRail({super.key, this.refreshTrigger});

  @override
  State<StoriesRail> createState() => _StoriesRailState();
}

class _StoriesRailState extends State<StoriesRail> {
  static const String _viewedPrefsKey = 'viewed_story_ids';
  // Cap how many tiles we keep client-side after filtering out viewed stories.
  // Server returns up to 200 active stories, so this leaves headroom for the
  // viewed-filter to discard plenty without leaving the rail empty.
  static const int _maxTiles = 50;

  List<Story> _stories = const [];
  // IDs the current device has already watched. Server-side stories expire in
  // 24h so this set stays small without explicit pruning.
  Set<int> _viewedIds = {};
  bool _isUploading = false;

  // Brand color used for the active ring. Matches the accent everywhere else
  // in the app. Viewed stories use a muted grey so the user can see at a
  // glance which ones are new.
  static const Color _ringColor = GoalioColors.greenAccent;

  @override
  void initState() {
    super.initState();
    _load();
    widget.refreshTrigger?.addListener(_load);
  }

  @override
  void didUpdateWidget(covariant StoriesRail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshTrigger != widget.refreshTrigger) {
      oldWidget.refreshTrigger?.removeListener(_load);
      widget.refreshTrigger?.addListener(_load);
    }
  }

  @override
  void dispose() {
    widget.refreshTrigger?.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    final results = await Future.wait([
      StoriesRepository.fetchAll(),
      _readViewedIds(),
    ]);
    if (!mounted) return;

    final allStories = results[0] as List<Story>;
    final viewed = results[1] as Set<int>;

    // Drop stories the user has already seen and cap the rail at 50 tiles.
    final unseen = <Story>[];
    for (final s in allStories) {
      if (!viewed.contains(s.id)) {
        unseen.add(s);
        if (unseen.length >= _maxTiles) break;
      }
    }

    setState(() {
      _stories = unseen;
      _viewedIds = viewed;
    });
  }

  Future<Set<int>> _readViewedIds() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_viewedPrefsKey) ?? const <String>[];
    return raw.map((s) => int.tryParse(s) ?? -1).where((n) => n > 0).toSet();
  }

  Future<void> _markViewed(int storyId) async {
    if (_viewedIds.contains(storyId)) return;
    setState(() => _viewedIds = {..._viewedIds, storyId});
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _viewedPrefsKey,
      _viewedIds.map((i) => i.toString()).toList(),
    );
  }

  Future<void> _pickAndUpload() async {
    final token = await ApiService.getToken();
    if (!mounted) return;
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to add a story')),
      );
      return;
    }

    final picker = ImagePicker();
    final XFile? file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1280,
      imageQuality: 85,
    );
    if (file == null || !mounted) return;

    setState(() => _isUploading = true);
    final result = await ApiService.createStory(filePath: file.path);
    if (!mounted) return;
    setState(() => _isUploading = false);

    if (result['error'] != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: ${result['error']}')),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Story submitted! Pending admin approval.'),
        duration: Duration(seconds: 4),
      ),
    );
  }

  void _openViewer(int index) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StoryViewerPage(
          stories: _stories,
          initialIndex: index,
          onView: (storyId) => _markViewed(storyId),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      height: 92.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 2.h),
        itemCount: _stories.length + 1,
        itemBuilder: (ctx, i) {
          if (i == 0) return _buildAddTile(isDark);
          final story = _stories[i - 1];
          return _buildStoryTile(story, i - 1, isDark);
        },
      ),
    );
  }

  // Sizing tokens — tweak these two to resize the whole rail.
  static const double _tileSize = 56;   // diameter of the avatar circle (in .w units)
  static const double _labelWidth = 64; // capped label width so long names ellipsize

  Widget _buildAddTile(bool isDark) {
    return Padding(
      padding: EdgeInsetsDirectional.only(end: 10.w),
      child: GestureDetector(
        onTap: _isUploading ? null : _pickAndUpload,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: _tileSize.w,
              height: _tileSize.w,
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: _ringColor, width: 2),
              ),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.05),
                ),
                child: _isUploading
                    ? Padding(
                        padding: EdgeInsets.all(14.w),
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          color: GoalioColors.greenAccent,
                        ),
                      )
                    : Icon(
                        Icons.add,
                        size: 22.w,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
              ),
            ),
            SizedBox(height: 4.h),
            SizedBox(
              width: _labelWidth.w,
              child: Text(
                'Your Story',
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10.5.sp,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoryTile(Story story, int index, bool isDark) {
    final mediaUrl = story.mediaUrl;
    final label = story.displayLabel;
    final isViewed = _viewedIds.contains(story.id);

    // Muted grey for viewed stories — same neutral that works in either theme.
    final Color tileBorderColor = isViewed
        ? (isDark ? Colors.white24 : Colors.black26)
        : _ringColor;

    return Padding(
      padding: EdgeInsetsDirectional.only(end: 10.w),
      child: GestureDetector(
        onTap: () => _openViewer(index),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: _tileSize.w,
              height: _tileSize.w,
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: tileBorderColor, width: 2),
              ),
              child: ClipOval(
                child: mediaUrl.isEmpty
                    ? Container(color: Colors.black26)
                    : Image.network(
                        mediaUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.black26,
                          child: Icon(Icons.broken_image,
                              color: Colors.white54, size: 18.w),
                        ),
                      ),
              ),
            ),
            SizedBox(height: 4.h),
            SizedBox(
              width: _labelWidth.w,
              child: Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10.5.sp,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

