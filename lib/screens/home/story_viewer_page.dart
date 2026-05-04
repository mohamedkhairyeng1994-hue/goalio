import 'package:flutter/material.dart';
import '../../core/models/story.dart';
import '../../core/utils/size_config.dart';

/// Full-screen viewer with auto-advance and tap-to-navigate.
/// Each story plays for 5 seconds; user can tap right/left to skip, or
/// swipe down / press back to close.
class StoryViewerPage extends StatefulWidget {
  final List<Story> stories;
  final int initialIndex;

  /// Fired with the story's `id` each time it becomes the active one (the
  /// initial story on open + every navigation forward/back). Lets the rail
  /// mark stories as "seen" so it can fade their ring next render.
  final void Function(int storyId)? onView;

  const StoryViewerPage({
    super.key,
    required this.stories,
    this.initialIndex = 0,
    this.onView,
  });

  @override
  State<StoryViewerPage> createState() => _StoryViewerPageState();
}

class _StoryViewerPageState extends State<StoryViewerPage>
    with SingleTickerProviderStateMixin {
  static const Duration _storyDuration = Duration(seconds: 5);

  late int _index;
  late AnimationController _progressController;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, widget.stories.length - 1);
    _reportView();
    _progressController = AnimationController(
      vsync: this,
      duration: _storyDuration,
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) _next();
      });
    _progressController.forward();
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  void _reportView() {
    widget.onView?.call(widget.stories[_index].id);
  }

  void _next() {
    if (_index >= widget.stories.length - 1) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _index++);
    _reportView();
    _progressController
      ..reset()
      ..forward();
  }

  void _previous() {
    if (_index == 0) {
      _progressController
        ..reset()
        ..forward();
      return;
    }
    setState(() => _index--);
    _reportView();
    _progressController
      ..reset()
      ..forward();
  }

  @override
  Widget build(BuildContext context) {
    final story = widget.stories[_index];
    final mediaUrl = story.mediaUrl;
    final authorName = story.user?.fullname?.trim();
    final caption = story.caption ?? '';

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapUp: (details) {
          final width = MediaQuery.of(context).size.width;
          if (details.globalPosition.dx < width / 3) {
            _previous();
          } else {
            _next();
          }
        },
        onVerticalDragEnd: (d) {
          if ((d.primaryVelocity ?? 0) > 200) Navigator.of(context).pop();
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Media
            Center(
              child: mediaUrl.isEmpty
                  ? const SizedBox.shrink()
                  : Image.network(
                      mediaUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Center(
                        child: Icon(Icons.broken_image,
                            color: Colors.white54, size: 64),
                      ),
                    ),
            ),

            // Top: progress bars + author
            SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(8.w, 8.h, 8.w, 0),
                child: Column(
                  children: [
                    Row(
                      children: List.generate(widget.stories.length, (i) {
                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 2.w),
                            child: AnimatedBuilder(
                              animation: _progressController,
                              builder: (_, __) {
                                final value = i < _index
                                    ? 1.0
                                    : (i == _index
                                        ? _progressController.value
                                        : 0.0);
                                return ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: value,
                                    minHeight: 3,
                                    backgroundColor: Colors.white24,
                                    valueColor: const AlwaysStoppedAnimation(
                                        Colors.white),
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      }),
                    ),
                    SizedBox(height: 10.h),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 18.w,
                          backgroundColor: Colors.white24,
                          child: Text(
                            ((authorName != null && authorName.isNotEmpty)
                                    ? authorName
                                    : 'U')
                                .substring(0, 1)
                                .toUpperCase(),
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14.sp,
                            ),
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: Text(
                            (authorName != null && authorName.isNotEmpty)
                                ? authorName
                                : 'User',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14.sp,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Caption
            if (caption.isNotEmpty)
              Positioned(
                bottom: 32.h,
                left: 16.w,
                right: 16.w,
                child: Text(
                  caption,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w500,
                    shadows: const [
                      Shadow(blurRadius: 4, color: Colors.black54),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
