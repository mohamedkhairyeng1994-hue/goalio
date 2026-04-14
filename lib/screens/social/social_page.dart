import 'dart:async';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../core/constants/constants.dart';
import '../../core/utils/size_config.dart';
import '../../core/services/api_service.dart';
import 'package:share_plus/share_plus.dart';

/// Returns a human-readable relative time string (e.g. "3h ago", "Yesterday")
String _relativeTime(String? isoString) {
  if (isoString == null) return '';
  try {
    final dt = DateTime.parse(isoString).toLocal();
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  } catch (_) {
    return '';
  }
}

Map<String, dynamic> _normalisePost(Map<String, dynamic> post) {
  // Database might return 1/0 for boolean fields
  final rawIsLiked = post['isLiked'];
  if (rawIsLiked is int) {
    post['isLiked'] = rawIsLiked == 1;
  } else if (rawIsLiked == null) {
    post['isLiked'] = false;
  } else {
    post['isLiked'] = rawIsLiked == true;
  }

  post['time'] = _relativeTime(post['created_at']?.toString());
  
  post['likesCount'] = (post['likesCount'] ?? 0) is int
      ? (post['likesCount'] ?? 0)
      : int.tryParse(post['likesCount'].toString()) ?? 0;
      
  post['commentsCount'] = (post['commentsCount'] ?? 0) is int
      ? (post['commentsCount'] ?? 0)
      : int.tryParse(post['commentsCount'].toString()) ?? 0;
      
  return post;
}

class SocialPage extends StatefulWidget {
  const SocialPage({super.key});

  @override
  State<SocialPage> createState() => SocialPageState();
}

class SocialPageState extends State<SocialPage> {
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> _posts = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;
  int _newestId = 0;          // ID of the most recent post we have loaded
  int _newPostsCount = 0;     // How many new posts found silently
  String _error = '';

  Timer? _silentTimer;

  // ── Life-cycle ─────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _initialLoad();
    _scrollController.addListener(_onScroll);
    // Silent poll every 30 seconds
    _silentTimer = Timer.periodic(const Duration(seconds: 30), (_) => _silentPoll());
  }

  @override
  void dispose() {
    _silentTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  // ── Scroll ─────────────────────────────────────────────────
  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 250 &&
        !_isLoadingMore &&
        _hasMore) {
      _loadNextPage();
    }
  }

  // ── Initial load ───────────────────────────────────────────
  Future<void> _initialLoad() async {
    setState(() { _isLoading = true; _error = ''; });
    try {
      final result = await ApiService.getSocialPostsPaged(page: 1, limit: 10);
      final posts = (result['data'] as List<Map<String, dynamic>>)
          .map(_normalisePost).toList();
      setState(() {
        _posts = posts;
        _hasMore = result['next_page_url'] != null;
        _currentPage = 1;
        _isLoading = false;
        _newestId = posts.isNotEmpty ? (posts.first['id'] as int? ?? 0) : 0;
      });
    } catch (_) {
      setState(() { _error = 'Failed to load posts'; _isLoading = false; });
    }
  }

  // ── Load next page (scroll to bottom) ─────────────────────
  Future<void> _loadNextPage() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);
    try {
      final result = await ApiService.getSocialPostsPaged(
          page: _currentPage + 1, limit: 10);
      final newPosts = (result['data'] as List<Map<String, dynamic>>)
          .map(_normalisePost).toList();
      setState(() {
        _posts.addAll(newPosts);
        _hasMore = result['next_page_url'] != null;
        _currentPage++;
        _isLoadingMore = false;
      });
    } catch (_) {
      setState(() => _isLoadingMore = false);
    }
  }

  // ── Silent background poll ─────────────────────────────────
  Future<void> _silentPoll() async {
    if (_newestId == 0) return;
    final newPosts = await ApiService.getSocialPostsSince(_newestId);
    if (newPosts.isEmpty || !mounted) return;
    setState(() {
      _newPostsCount += newPosts.length;
      // Prepend silently without resetting list
      _posts.insertAll(0, newPosts.map(_normalisePost));
      _newestId = _posts.first['id'] as int? ?? _newestId;
    });
  }

  // ── Pull-to-refresh (manual) ───────────────────────────────
  Future<void> _pullRefresh() async {
    setState(() { _newPostsCount = 0; });
    await _initialLoad();
  }

  // ── Jump to top and clear banner ───────────────────────────
  void _jumpToTop() {
    _scrollController.animateTo(0,
        duration: const Duration(milliseconds: 400), curve: Curves.easeOut);
    setState(() => _newPostsCount = 0);
  }

  // ── Public reset (called from main nav) ───────────────────
  void resetState() {
    _newPostsCount = 0;
    _jumpToTop();
    _initialLoad();
  }

  // ── Like toggle ─────────────────────────────────────────────
  Future<void> _toggleLike(int index) async {
    final postId = _posts[index]['id'];
    final originalIsLiked = _posts[index]['isLiked'] ?? false;
    final originalLikesCount = _posts[index]['likesCount'] ?? 0;

    // Check auth
    final token = await ApiService.getToken();
    if (token == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please login to like posts')),
        );
      }
      return;
    }

    // Optimistic UI update
    setState(() {
      _posts[index]['isLiked'] = !originalIsLiked;
      _posts[index]['likesCount'] = originalLikesCount + (!originalIsLiked ? 1 : -1);
    });

    final result = await ApiService.toggleSocialPostLike(postId);
    
    if (!mounted) return;

    if (result == null) {
      // Revert if failed (find current index in case list shifted)
      final currentIndex = _posts.indexWhere((p) => p['id'] == postId);
      if (currentIndex != -1) {
        setState(() {
          _posts[currentIndex]['isLiked'] = originalIsLiked;
          _posts[currentIndex]['likesCount'] = originalLikesCount;
        });
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update like. Please try again.')),
        );
      }
    } else {
      // Sync exact count (find current index)
      final currentIndex = _posts.indexWhere((p) => p['id'] == postId);
      if (currentIndex != -1) {
        setState(() {
          _posts[currentIndex]['likesCount'] = result['likesCount'];
          final rawLiked = result['isLiked'];
          _posts[currentIndex]['isLiked'] = (rawLiked is int) ? (rawLiked == 1) : (rawLiked == true);
        });
      }
    }
  }

  // ── Share Post ──────────────────────────────────────────────
  void _sharePost(BuildContext context, Map<String, dynamic> post) {
    final box = context.findRenderObject() as RenderBox?;
    final content = post['content'] ?? '';
    final source = post['sourceName'] ?? 'Goalio';
    final mediaUrl = post['mediaUrl'];
    
    String shareText = '$content\n\nShared via $source';
    if (mediaUrl != null && mediaUrl.isNotEmpty) {
      shareText += '\nView media: $mediaUrl';
    }
    
    Share.share(
      shareText,
      subject: 'Check out this post on Goalio',
      sharePositionOrigin: (box != null && box.hasSize && !box.size.isEmpty) 
          ? box.localToGlobal(Offset.zero) & box.size 
          : null,
    );
  }

  // ── Build ───────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        titleSpacing: 0,
        title: Padding(
          padding: EdgeInsetsDirectional.only(start: 0, end: 16.w),
          child: const Text(
            'Social',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: GoalioColors.greenAccent,
              letterSpacing: 1.2,
            ),
          ),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: false,
      ),
      body: _buildBody(isDark),
    );
  }

  Widget _buildBody(bool isDark) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: GoalioColors.greenAccent));
    }

    if (_error.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.redAccent, size: 48.w),
            SizedBox(height: 16.h),
            Text(_error, style: TextStyle(color: isDark ? Colors.white70 : Colors.black87)),
            SizedBox(height: 16.h),
            ElevatedButton(
              onPressed: _initialLoad,
              style: ElevatedButton.styleFrom(backgroundColor: GoalioColors.greenAccent),
              child: const Text('Retry', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    if (_posts.isEmpty) {
      return Center(
        child: Text(
          'No social posts available right now.',
          style: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
        ),
      );
    }

    return Stack(
      children: [
        // Main feed
        RefreshIndicator(
          onRefresh: _pullRefresh,
          color: GoalioColors.greenAccent,
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          displacement: 60,
          child: ListView.builder(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.only(bottom: 100.h, top: 8.h),
            itemCount: _posts.length + (_isLoadingMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == _posts.length) {
                return Padding(
                  padding: EdgeInsets.symmetric(vertical: 24.h),
                  child: Center(
                    child: SizedBox(
                      width: 26.w,
                      height: 26.w,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: GoalioColors.greenAccent,
                      ),
                    ),
                  ),
                );
              }
              return _buildPostCard(_posts[index], index, isDark);
            },
          ),
        ),

        // "New posts" floating banner
        if (_newPostsCount > 0)
          Positioned(
            top: 12.h,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: _jumpToTop,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 10.h),
                  decoration: BoxDecoration(
                    color: GoalioColors.greenAccent,
                    borderRadius: BorderRadius.circular(30.w),
                    boxShadow: [
                      BoxShadow(
                        color: GoalioColors.greenAccent.withOpacity(0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.arrow_upward_rounded, color: Colors.black, size: 16.w),
                      SizedBox(width: 6.w),
                      Text(
                        '$_newPostsCount new post${_newPostsCount > 1 ? 's' : ''}',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 13.sp,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPostCard(Map<String, dynamic> post, int index, bool isDark) {
    final bool isEmbed = post['mediaType'] == 'embed' || (post['mediaType'] == 'video' && (post['embedHtml'] as String? ?? '').isNotEmpty);
    final bool hasMedia = (post['mediaType'] != 'text' && post['mediaUrl'] != null) || isEmbed;
    final bool isVideo = post['mediaType'] == 'video';

    // Calculate dynamic video height based on 16:9 aspect ratio
    final double screenWidth = MediaQuery.of(context).size.width;
    final double horizontalPadding = 64.w; // 16w per margin + 16w per padding (both sides)
    final double contentWidth = screenWidth - horizontalPadding;
    final double videoHeight = contentWidth * 9 / 16;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20.w),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.08)
              : Colors.black.withOpacity(0.05),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header (Source Logo, Source Name, Time)
          Row(
            children: [
              _buildSourceLogo(post),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            post['sourceName'],
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.bold,
                              fontSize: 15.sp,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (post['isVerified'] == true) ... [
                          SizedBox(width: 4.w),
                          Icon(Icons.verified, color: GoalioColors.blueAccent, size: 14.w),
                        ]
                      ],
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      post['time'] ?? '',
                      style: TextStyle(
                        color: isDark ? Colors.white54 : Colors.black54,
                        fontSize: 12.sp,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),

          // 2. Content
          if ((post['content'] as String? ?? '').isNotEmpty)
            _ExpandableText(
              text: post['content'] ?? '',
              style: TextStyle(
                color: isDark ? Colors.white.withOpacity(0.9) : Colors.black87,
                fontSize: 14.sp,
                height: 1.4,
              ),
            ),
          SizedBox(height: 12.h),

          // 3. Media
          if (isEmbed) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(16.w),
              child: _EmbeddedPostWidget(
                htmlContent: post['embedHtml'] ?? '',
                height: isVideo ? videoHeight : ((post['embedHeight'] as num?)?.toDouble() ?? 300.0),
              ),
            ),
            SizedBox(height: 16.h),
          ] else if (hasMedia) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(16.w),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (post['mediaUrl'] != null &&
                      post['mediaUrl'].toString().isNotEmpty)
                    Image.network(
                      post['mediaUrl'],
                    width: double.infinity,
                    fit: BoxFit.fitWidth,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        width: double.infinity,
                        height: 200.h,
                        color: isDark ? Colors.white10 : Colors.black12,
                        alignment: Alignment.center,
                        child: CircularProgressIndicator(
                          color: GoalioColors.greenAccent,
                          strokeWidth: 2,
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: double.infinity,
                      height: 180.h,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white10 : Colors.black12,
                        borderRadius: BorderRadius.circular(16.w),
                      ),
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.broken_image_outlined,
                              color: isDark ? Colors.white38 : Colors.black38,
                              size: 40.w),
                          SizedBox(height: 8.h),
                          Text('Image unavailable',
                              style: TextStyle(
                                  color: isDark ? Colors.white38 : Colors.black38,
                                  fontSize: 12.sp)),
                        ],
                      ),
                    ),
                  ),
                  if (isVideo)
                    Container(
                      padding: EdgeInsets.all(14.w),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.55),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.play_arrow_rounded,
                          color: Colors.white, size: 36.w),
                    ),
                ],
              ),
            ),
            SizedBox(height: 16.h),
          ],


          // 4. Action Bar (Like, Comment, Share)
          Divider(color: isDark ? Colors.white10 : Colors.black12, height: 1),
          SizedBox(height: 8.h),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildActionButton(
                  icon: post['isLiked'] ? Icons.favorite : Icons.favorite_border,
                  label: _formatCount(post['likesCount']),
                  color: post['isLiked'] ? Colors.redAccent : (isDark ? Colors.white60 : Colors.black54),
                  onTap: () => _toggleLike(index),
                ),
                _buildActionButton(
                  icon: Icons.chat_bubble_outline,
                  label: _formatCount(post['commentsCount']),
                  color: isDark ? Colors.white60 : Colors.black54,
                  onTap: () => _showCommentsSheet(context, isDark, post, index),
                ),
                Builder(
                  builder: (btnContext) => _buildActionButton(
                    icon: Icons.share_outlined,
                    label: 'Share',
                    color: isDark ? Colors.white60 : Colors.black54,
                    onTap: () => _sharePost(btnContext, post),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8.w),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20.w),
            SizedBox(width: 8.w),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 13.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatCount(dynamic rawCount) {
    final count = rawCount is int ? rawCount : int.tryParse(rawCount.toString()) ?? 0;
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
  }

  void _showCommentsSheet(BuildContext context, bool isDark, Map<String, dynamic> post, int index) async {
    // Check auth
    final token = await ApiService.getToken();
    if (token == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please login to comment')),
        );
      }
      return;
    }

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.w)),
      ),
      builder: (context) {
        return _CommentsSheet(
          post: post,
          isDark: isDark,
          onCommentAdded: () {
            // Find current index of this post by ID
            final targetPostId = post['id'];
            final currentIndex = _posts.indexWhere((p) => p['id'] == targetPostId);
            if (currentIndex != -1) {
              setState(() {
                _posts[currentIndex]['commentsCount'] = (_posts[currentIndex]['commentsCount'] ?? 0) + 1;
              });
            }
          },
        );
      },
    );
  }

  Widget _buildSourceLogo(Map<String, dynamic> post) {
    final String? logoUrl = post['sourceLogo'];
    if (logoUrl != null && logoUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8.w),
        child: Image.network(
          logoUrl,
          width: 40.w,
          height: 40.w,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildSourcePlaceholder(post),
        ),
      );
    }
    return _buildSourcePlaceholder(post);
  }

  Widget _buildSourcePlaceholder(Map<String, dynamic> post) {
    return Container(
      width: 40.w,
      height: 40.w,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.w),
        color: GoalioColors.greenAccent.withOpacity(0.2),
      ),
      child: Icon(Icons.person, color: GoalioColors.greenAccent, size: 22.w),
    );
  }
}

class _ExpandableText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final int maxLines;

  const _ExpandableText({
    Key? key,
    required this.text,
    required this.style,
    this.maxLines = 4,
  }) : super(key: key);

  @override
  State<_ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<_ExpandableText> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _isExpanded = !_isExpanded),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        alignment: Alignment.topCenter,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.text,
              style: widget.style,
              maxLines: _isExpanded ? null : widget.maxLines,
              overflow: _isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
            ),
            if (!_isExpanded && widget.text.length > 100)
              Padding(
                padding: EdgeInsets.only(top: 4.h),
                child: Text(
                  'See more...',
                  style: TextStyle(
                    color: GoalioColors.greenAccent,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _EmbeddedPostWidget extends StatefulWidget {
  final String htmlContent;
  final double height;
  const _EmbeddedPostWidget({Key? key, required this.htmlContent, required this.height}) : super(key: key);

  @override
  State<_EmbeddedPostWidget> createState() => _EmbeddedPostWidgetState();
}

class _EmbeddedPostWidgetState extends State<_EmbeddedPostWidget> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setUserAgent('Mozilla/5.0 (Linux; Android 10; SM-G975F) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/80.0.3987.149 Mobile Safari/537.36')
      ..loadHtmlString(_buildHtml(widget.htmlContent), baseUrl: 'https://goalio.app/');
  }

  String _buildHtml(String content) {
    return '''
      <!DOCTYPE html>
      <html>
      <head>
        <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
        <style>
          body { 
            margin: 0; 
            padding: 0; 
            overflow: hidden; 
            background-color: transparent; 
            display: flex;
            justify-content: center;
            align-items: center;
          }
          iframe, ._scorebatEmbeddedPlayerW_ { 
            width: 100% !important; 
            height: 100vh !important;
            border-radius: 12px; 
          }
        </style>
      </head>
      <body>
        $content
      </body>
      </html>
    ''';
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: WebViewWidget(controller: _controller),
    );
  }
}

class _CommentsSheet extends StatefulWidget {
  final Map<String, dynamic> post;
  final bool isDark;
  final VoidCallback onCommentAdded;

  const _CommentsSheet({
    Key? key,
    required this.post,
    required this.isDark,
    required this.onCommentAdded,
  }) : super(key: key);

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  final TextEditingController _commentController = TextEditingController();
  List<Map<String, dynamic>> _comments = [];
  bool _isLoading = true;
  bool _isPosting = false;
  Map<String, dynamic>? _replyingTo;
  
  final ScrollController _scrollController = ScrollController();
  int _currentPage = 1;
  bool _hasMore = false;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _fetchComments();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 100 &&
        !_isLoadingMore &&
        _hasMore) {
      _loadMoreComments();
    }
  }

  Future<void> _fetchComments() async {
    final result = await ApiService.getSocialPostComments(widget.post['id'], page: 1, limit: 10);
    setState(() {
      _comments = result['data'];
      _hasMore = result['next_page_url'] != null;
      _currentPage = 1;
      _isLoading = false;
    });
  }

  Future<void> _loadMoreComments() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);
    
    final result = await ApiService.getSocialPostComments(
      widget.post['id'], 
      page: _currentPage + 1, 
      limit: 10
    );
    
    setState(() {
      _comments.addAll(result['data']);
      _hasMore = result['next_page_url'] != null;
      _currentPage++;
      _isLoadingMore = false;
    });
  }

  Future<void> _postComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;
    
    setState(() => _isPosting = true);
    
    final newComment = await ApiService.addSocialPostComment(
      widget.post['id'], 
      text,
      parentId: _replyingTo?['id'],
    );
    if (newComment != null) {
      _commentController.clear();
      setState(() {
        if (_replyingTo != null) {
          // If it was a reply, find the parent and add it to its replies list
          final parentId = _replyingTo!['id'];
          final parentIndex = _comments.indexWhere((c) => c['id'] == parentId);
          if (parentIndex != -1) {
            _comments[parentIndex]['replies'] = [
              ...(List.from(_comments[parentIndex]['replies'] ?? [])),
              newComment
            ];
          }
        } else {
          // Top level comment
          _comments.insert(0, newComment);
        }
        _replyingTo = null; // Clear reply state
      });
      widget.onCommentAdded();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to post comment. Please try again.')),
        );
      }
    }
    
    setState(() => _isPosting = false);
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    
    return Container(
      decoration: BoxDecoration(
        color: widget.isDark ? const Color(0xFF121212) : Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.w)),
      ),
      padding: EdgeInsets.only(bottom: bottomInset),
      height: MediaQuery.of(context).size.height * 0.8,
      child: Column(
        children: [
          // Handle/Indicator
          SizedBox(height: 12.h),
          Container(
            width: 36.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: widget.isDark ? Colors.white24 : Colors.black12,
              borderRadius: BorderRadius.circular(2.w),
            ),
          ),
          
          // Header
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Comments',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w800,
                    color: widget.isDark ? Colors.white : Colors.black87,
                  ),
                ),
                if (!_isLoading) ...[
                  SizedBox(width: 8.w),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                    decoration: BoxDecoration(
                      color: GoalioColors.greenAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12.w),
                    ),
                    child: Text(
                      '${_comments.length}',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                        color: GoalioColors.greenAccent,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          Divider(height: 1, color: widget.isDark ? Colors.white10 : Colors.black12),
          
          // Body
          Expanded(
            child: _isLoading 
              ? Center(child: CircularProgressIndicator(color: GoalioColors.greenAccent, strokeWidth: 3))
              : _comments.isEmpty 
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat_bubble_outline_rounded, size: 48.w, color: widget.isDark ? Colors.white24 : Colors.black12),
                      SizedBox(height: 16.h),
                      Text(
                        'No comments yet',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w500,
                          color: widget.isDark ? Colors.white38 : Colors.black38,
                        ),
                      ),
                      Text(
                        'Be the first to share your thoughts!',
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: widget.isDark ? Colors.white24 : Colors.black26,
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 16.h),
                    itemCount: _comments.length + (_isLoadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _comments.length) {
                        return Padding(
                          padding: EdgeInsets.symmetric(vertical: 16.h),
                          child: Center(
                            child: SizedBox(
                              width: 20.w,
                              height: 20.w,
                              child: CircularProgressIndicator(strokeWidth: 2, color: GoalioColors.greenAccent),
                            ),
                          ),
                        );
                      }
                      final c = _comments[index];
                      return _buildCommentItem(c);
                    },
                  ),
          ),
          
          // Replying to Indicator
          if (_replyingTo != null)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
              color: GoalioColors.greenAccent.withOpacity(0.1),
              child: Row(
                children: [
                  Icon(Icons.reply_rounded, size: 16.w, color: GoalioColors.greenAccent),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      'Replying to ${_replyingTo!['user']?['fullname'] ?? 'User'}',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                        color: GoalioColors.greenAccent,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, size: 16.w, color: GoalioColors.greenAccent),
                    onPressed: () => setState(() => _replyingTo = null),
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
          
          // Input Section
          Container(
            padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 24.h),
            decoration: BoxDecoration(
              color: widget.isDark ? const Color(0xFF1A1A1A) : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: widget.isDark ? Colors.white.withOpacity(0.07) : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(28.w),
                      border: Border.all(
                        color: widget.isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
                      ),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 18.w),
                    child: TextField(
                      controller: _commentController,
                      style: TextStyle(fontSize: 14.sp, color: widget.isDark ? Colors.white : Colors.black87),
                      decoration: InputDecoration(
                        hintText: 'Add a comment...',
                        hintStyle: TextStyle(color: widget.isDark ? Colors.white38 : Colors.black38, fontSize: 14.sp),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 12.h),
                      ),
                      maxLines: 4,
                      minLines: 1,
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                _isPosting 
                  ? SizedBox(
                      width: 24.w, 
                      height: 24.w, 
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: GoalioColors.greenAccent)
                    )
                  : GestureDetector(
                      onTap: _postComment,
                      child: Container(
                        padding: EdgeInsets.all(12.w),
                        decoration: BoxDecoration(
                          color: GoalioColors.greenAccent,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.send_rounded, color: Colors.white, size: 20.w),
                      ),
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildCommentItem(Map<String, dynamic> c, {bool isReply = false}) {
    final user = c['user'] ?? {};
    final timeStr = _relativeTime(c['created_at']?.toString());
    final replies = (c['replies'] as List?) ?? [];

    return Padding(
      padding: EdgeInsets.only(bottom: 20.h, left: isReply ? 44.w : 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: GoalioColors.greenAccent.withOpacity(0.3),
                    width: isReply ? 1.0 : 1.5,
                  ),
                ),
                child: CircleAvatar(
                  radius: isReply ? 14.w : 18.w,
                  backgroundImage: NetworkImage(
                    user['avatarUrl'] ?? 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(user['fullname'] ?? 'U')}&background=00e676&color=fff'
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          user['fullname'] ?? 'User',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: isReply ? 13.sp : 14.sp,
                            color: widget.isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          timeStr,
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: widget.isDark ? Colors.white38 : Colors.black38,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4.h),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                      decoration: BoxDecoration(
                        color: widget.isDark 
                          ? (isReply ? Colors.white12 : Colors.white.withOpacity(0.05)) 
                          : (isReply ? Colors.grey.shade200 : Colors.grey.shade100),
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(16.w),
                          bottomLeft: Radius.circular(16.w),
                          bottomRight: Radius.circular(16.w),
                        ),
                      ),
                      child: Text(
                        c['comment'] ?? '',
                        style: TextStyle(
                          height: 1.4,
                          fontSize: 14.sp,
                          color: widget.isDark ? Colors.white.withOpacity(0.9) : Colors.black87,
                        ),
                      ),
                    ),
                    
                    if (!isReply) 
                      Padding(
                        padding: EdgeInsets.only(top: 6.h, left: 4.w),
                        child: GestureDetector(
                          onTap: () => setState(() => _replyingTo = c),
                          child: Text(
                            'Reply',
                            style: TextStyle(
                              color: GoalioColors.greenAccent,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          
          // Render replies
          if (replies.isNotEmpty)
            ...replies.map((r) => _buildCommentItem(r as Map<String, dynamic>, isReply: true)).toList(),
        ],
      ),
    );
  }
}
