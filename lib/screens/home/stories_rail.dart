import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/constants.dart';
import '../../core/models/story.dart';
import '../../core/services/repositories/stories_repository.dart';
import '../../core/utils/size_config.dart';
import 'story_viewer_page.dart';

/// Horizontal rail of circular story tiles shown on the home screen.
/// Tiles open the story viewer. Stories themselves are admin-published.
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
  // Stories are cached locally so the rail can paint instantly on cold start
  // and survive transient API failures, instead of going blank until the
  // network call returns.
  static const String _cachePrefsKey = 'cached_stories_v1';

  List<Story> _stories = const [];
  // IDs the device has watched. Drives the rail order (unseen tiles first,
  // viewed tiles pushed to the end) and the muted-ring styling. Stories
  // expire in 24h server-side so this set stays small without explicit pruning.
  Set<int> _viewedIds = {};

  // Brand color used for the active ring. Viewed stories use a muted grey.
  static const Color _ringColor = GoalioColors.greenAccent;

  // Server stories partitioned so unseen come first, then viewed — both
  // halves keep their server (newest-first) order.
  List<Story> get _orderedStories {
    final unseen = <Story>[];
    final seen = <Story>[];
    for (final s in _stories) {
      (_viewedIds.contains(s.id) ? seen : unseen).add(s);
    }
    return [...unseen, ...seen];
  }

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
    // Stale-while-revalidate. On the first call (state still empty) paint
    // whatever we have in local cache so the rail isn't blank while the
    // network request flies. On subsequent calls (pull-to-refresh) we already
    // have rows on screen, so skip the cache hop and go straight to the wire.
    if (_stories.isEmpty) {
      final cached = await _readCachedStories();
      final viewedIds = await _readViewedIds();
      if (mounted && cached.isNotEmpty) {
        setState(() {
          // Drop client-side-expired rows defensively — the server already
          // filters them, but cache could outlive their TTL.
          _stories = cached.where((s) => !s.isExpired).toList();
          _viewedIds = viewedIds;
        });
      }
    }

    final fresh = await StoriesRepository.fetchAll();
    final viewedIds = await _readViewedIds();
    if (!mounted) return;

    // Empty server response can mean "genuinely no stories" or "API blip"
    // (the repo swallows errors and returns []). Either way, don't wipe
    // what we already painted — the next refresh will recover.
    if (fresh.isEmpty) {
      setState(() => _viewedIds = viewedIds);
      return;
    }

    setState(() {
      _stories = fresh;
      _viewedIds = viewedIds;
    });
    await _writeCachedStories(fresh);
  }

  Future<List<Story>> _readCachedStories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cachePrefsKey);
      if (raw == null || raw.isEmpty) return const [];
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map((m) => Story.fromJson(Map<String, dynamic>.from(m)))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> _writeCachedStories(List<Story> stories) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(stories.map((s) => s.toJson()).toList());
      await prefs.setString(_cachePrefsKey, encoded);
    } catch (_) {
      // Cache writes are best-effort.
    }
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

  void _openViewer(List<Story> ordered, int index) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StoryViewerPage(
          stories: ordered,
          initialIndex: index,
          onView: _markViewed,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ordered = _orderedStories;
    return SizedBox(
      height: 92.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 2.h),
        itemCount: ordered.length,
        itemBuilder: (ctx, i) {
          final story = ordered[i];
          return _buildStoryTile(story, i, isDark, ordered);
        },
      ),
    );
  }

  // Sizing tokens — tweak these two to resize the whole rail.
  static const double _tileSize = 56;   // diameter of the avatar circle (in .w units)
  static const double _labelWidth = 64; // capped label width so long names ellipsize

  Widget _buildStoryTile(Story story, int index, bool isDark, List<Story> ordered) {
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
        onTap: () => _openViewer(ordered, index),
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

