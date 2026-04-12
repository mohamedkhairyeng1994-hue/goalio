import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../core/constants/constants.dart';
import '../../core/utils/size_config.dart';

class ForYouPage extends StatefulWidget {
  const ForYouPage({super.key});

  @override
  State<ForYouPage> createState() => ForYouPageState();
}

class ForYouPageState extends State<ForYouPage> {
  final ScrollController _scrollController = ScrollController();

  // Dummy data simulating posts related to favorite teams and leagues,
  // added by system or admin. Includes text, photo, and video simulated posts.
  final List<Map<String, dynamic>> _posts = [
    {
      'id': '1',
      'sourceName': 'Goalio Admin',
      'sourceLogo': 'https://ui-avatars.com/api/?name=Goalio+Admin&background=1E293B&color=34D399',
      'time': '2h ago',
      'content': '[Photo + Text] Real Madrid vs Barcelona! Who will win the El Clásico this weekend? Drop your predictions below! 🔥⚽️ #ElClasico',
      'mediaUrl': 'https://images.unsplash.com/photo-1522778119026-d647f0596c20?auto=format&fit=crop&q=80&w=1000',
      'mediaType': 'image',
      'likesCount': 12400,
      'commentsCount': 324,
      'isLiked': false,
    },
    {
      'id': '2',
      'sourceName': 'YouTube',
      'sourceLogo': 'https://ui-avatars.com/api/?name=YT&background=FF0000&color=fff',
      'time': '3h ago',
      'content': '[Embedded YouTube] Check out these amazing highlights from the Champions League!',
      'mediaType': 'embed',
      'embedHtml': '<iframe width="100%" height="100%" src="https://www.youtube.com/embed/dQw4w9WgXcQ" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" allowfullscreen></iframe>',
      'embedHeight': 220.0,
      'likesCount': 2341,
      'commentsCount': 120,
      'isLiked': false,
    },
    {
      'id': '3',
      'sourceName': 'X.com',
      'sourceLogo': 'https://ui-avatars.com/api/?name=X&background=000&color=fff',
      'time': '5h ago',
      'content': '[Embedded Post from X] Breaking news natively rendered via Twitter SDK.',
      'mediaType': 'embed',
      'embedHtml': '<blockquote class="twitter-tweet" data-theme="dark"><p lang="en" dir="ltr">🚨 Kylian Mbappé to Real Madrid, HERE WE GO! Every document has been signed, sealed and completed. ⚪️🤝🏻<br><br>Real Madrid, set to announce Mbappé as new signing next week after winning the Champions League.<br><br>Mbappé made his decision in February; he can now be considered new Real player. <a href="https://t.co/MMqEp1C0pK">pic.twitter.com/MMqEp1C0pK</a></p>&mdash; Fabrizio Romano (@FabrizioRomano) <a href="https://twitter.com/FabrizioRomano/status/1797289849182310574?ref_src=twsrc%5Etfw">June 2, 2024</a></blockquote> <script async src="https://platform.twitter.com/widgets.js" charset="utf-8"></script>',
      'embedHeight': 420.0,
      'likesCount': 90050,
      'commentsCount': 8121,
      'isLiked': true,
    },
    {
      'id': '4',
      'sourceName': 'Facebook',
      'sourceLogo': 'https://ui-avatars.com/api/?name=FB&background=1877F2&color=fff',
      'time': '1d ago',
      'content': '[Embedded Facebook Post] Official updates embedded natively via Facebook SDK.',
      'mediaType': 'embed',
      'embedHtml': '<div id="fb-root"></div><script async defer crossorigin="anonymous" src="https://connect.facebook.net/en_US/sdk.js#xfbml=1&version=v18.0" nonce="123"></script><div class="fb-post" data-href="https://www.facebook.com/realmadrid/posts/pfbid02u9xQpB9q9U1tY2XW9P48fRWeZbWq9uG3Yn8VpUjU5R" data-width="auto" data-show-text="true"></div>',
      'embedHeight': 350.0,
      'likesCount': 892,
      'commentsCount': 45,
      'isLiked': false,
    }
  ];

  void resetState() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0, 
        duration: const Duration(milliseconds: 300), 
        curve: Curves.easeInOut
      );
    }
  }

  void _toggleLike(int index) {
    setState(() {
      _posts[index]['isLiked'] = !_posts[index]['isLiked'];
      if (_posts[index]['isLiked']) {
        _posts[index]['likesCount']++;
      } else {
        _posts[index]['likesCount']--;
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

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
            'For You',
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
      body: ListView.builder(
        controller: _scrollController,
        padding: EdgeInsets.only(bottom: 100.h, top: 8.h),
        itemCount: _posts.length,
        itemBuilder: (context, index) {
          return _buildPostCard(_posts[index], index, isDark);
        },
      ),
    );
  }

  Widget _buildPostCard(Map<String, dynamic> post, int index, bool isDark) {
    final bool isEmbed = post['mediaType'] == 'embed';
    final bool hasMedia = (post['mediaType'] != 'text' && post['mediaUrl'] != null) || isEmbed;
    final bool isVideo = post['mediaType'] == 'video';

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
              Container(
                width: 40.w,
                height: 40.w,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8.w),
                  color: isDark ? Colors.white10 : Colors.black12,
                  image: DecorationImage(
                    image: NetworkImage(post['sourceLogo']),
                    fit: BoxFit.cover,
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
                          post['sourceName'],
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.bold,
                            fontSize: 15.sp,
                          ),
                        ),
                        if (post['sourceName'] == 'Goalio Admin' || post['sourceName'] == 'Sky Sports' || post['sourceName'] == 'Goal.com') ... [
                          SizedBox(width: 4.w),
                          Icon(Icons.check_circle, color: GoalioColors.blueAccent, size: 14.w),
                        ]
                      ],
                    ),
                    SizedBox(height: 2.h),
                    Row(
                      children: [
                        Text(
                          'Source',
                          style: TextStyle(
                            color: GoalioColors.greenAccent,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          ' • ${post['time']}',
                          style: TextStyle(
                            color: isDark ? Colors.white54 : Colors.black54,
                            fontSize: 12.sp,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.more_vert, color: isDark ? Colors.white54 : Colors.black54),
                iconSize: 20.w,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () {},
              ),
            ],
          ),
          SizedBox(height: 12.h),

          // 2. Content
          Text(
            post['content'],
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
                height: (post['embedHeight'] as num?)?.toDouble() ?? 300.0,
              ),
            ),
            SizedBox(height: 16.h),
          ] else if (hasMedia) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(16.w),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Image.network(
                    post['mediaUrl'],
                    width: double.infinity,
                    height: 200.h,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: double.infinity,
                      height: 200.h,
                      color: isDark ? Colors.white10 : Colors.black12,
                      alignment: Alignment.center,
                      child: Icon(Icons.broken_image, color: isDark ? Colors.white54 : Colors.black54, size: 40.w),
                    ),
                  ),
                  if (isVideo)
                    Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.play_arrow, color: Colors.white, size: 32.w),
                    ),
                  // Optional: duration pill if video
                  if (isVideo)
                     Positioned(
                       bottom: 8.h,
                       right: 8.w,
                       child: Container(
                         padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                         decoration: BoxDecoration(
                           color: Colors.black87,
                           borderRadius: BorderRadius.circular(8.w),
                         ),
                         child: Text(
                           '0:15',
                           style: TextStyle(color: Colors.white, fontSize: 10.sp, fontWeight: FontWeight.bold),
                         ),
                       ),
                     ),
                ],
              ),
            ),
            SizedBox(height: 16.h),
          ],

          // 4. Action Bar (Like, Comment, Share)
          Divider(color: isDark ? Colors.white10 : Colors.black12, height: 1),
          SizedBox(height: 8.h),
          Row(
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
                onTap: () => _showCommentsSheet(context, isDark),
              ),
              _buildActionButton(
                icon: Icons.share_outlined,
                label: 'Share',
                color: isDark ? Colors.white60 : Colors.black54,
                onTap: () {},
              ),
            ],
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

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }

  void _showCommentsSheet(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.w)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(20.w),
          height: MediaQuery.of(context).size.height * 0.5,
          child: Column(
            children: [
              Container(
                 width: 40.w,
                 height: 4.h,
                 decoration: BoxDecoration(
                   color: isDark ? Colors.white24 : Colors.black26,
                   borderRadius: BorderRadius.circular(2.w),
                 ),
              ),
              SizedBox(height: 16.h),
              Text(
                'Comments',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 20.h),
              Expanded(
                child: Center(
                  child: Text(
                    'Comments section coming soon.',
                    style: TextStyle(
                      color: isDark ? Colors.white54 : Colors.black54, 
                      fontSize: 14.sp
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
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
          body { margin: 0; padding: 0; overflow: hidden; background-color: transparent; }
          iframe, twitter-widget, .fb-post { max-width: 100% !important; border-radius: 12px; }
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
