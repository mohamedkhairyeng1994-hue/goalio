import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/services/api_service.dart';
import '../../core/utils/size_config.dart';
import '../../core/constants/constants.dart';
import '../../l10n/app_localizations.dart';

class NewsDetailPage extends StatefulWidget {
  final Map<String, dynamic> article;
  final String? heroTag;

  const NewsDetailPage({super.key, required this.article, this.heroTag});

  @override
  State<NewsDetailPage> createState() => _NewsDetailPageState();
}

class _NewsDetailPageState extends State<NewsDetailPage> {
  late Map<String, dynamic> _article;
  bool _isLoadingContent = false;

  @override
  void initState() {
    super.initState();
    _article = Map<String, dynamic>.from(widget.article);
    _checkAndFetchContent();
  }

  Future<void> _checkAndFetchContent() async {
    final String? description = _article['description'];
    final int? id = _article['id'];

    if (id != null && (description == null || description.length < 200)) {
      if (mounted) {
        setState(() {
          _isLoadingContent = true;
        });
      }

      try {
        final detailedArticle = await ApiService.getNewsDetail(id);
        if (detailedArticle != null && mounted) {
          setState(() {
            _article = detailedArticle;
            _isLoadingContent = false;
          });
        } else if (mounted) {
          setState(() {
            _isLoadingContent = false;
          });
        }
      } catch (e) {
        debugPrint("Error fetching full news content: $e");
        if (mounted) {
          setState(() {
            _isLoadingContent = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final String title =
        _article['title'] ?? AppLocalizations.of(context)!.news;
    final String? imageUrl = _article['image_url'];
    final String? description = _article['description'];
    final String author = _article['author'] ?? 'Goal';
    final String? publishedAt = _article['published_at'];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // Elegant App Bar with Hero Image
          SliverAppBar(
            expandedHeight: 300.h,
            pinned: true,
            stretch: true,
            backgroundColor: const Color(0xFF1E293B),
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [
                StretchMode.zoomBackground,
                StretchMode.blurBackground,
              ],
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (imageUrl != null && imageUrl.isNotEmpty)
                    Hero(
                      tag: widget.heroTag ?? 'news_image_${_article['id']}',
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        // Some news CDNs (img.btolat.com, mediayk.gemini.media,
                        // etc.) close TCP connections mid-stream. Without an
                        // errorBuilder Flutter rethrows HttpException all the
                        // way to the debugger; with one the user just sees the
                        // fallback panel.
                        errorBuilder: (c, e, s) =>
                            Container(color: const Color(0xFF1E293B)),
                      ),
                    )
                  else
                    Container(color: const Color(0xFF1E293B)),

                  // Gradient Overlay for visibility
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.3),
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // News Content
          SliverToBoxAdapter(
            child: Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30.w)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Meta Info Row
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: GoalioColors.greenAccent.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12.w),
                        ),
                        child: Text(
                          AppLocalizations.of(context)!.newsTag,
                          style: TextStyle(
                            color: GoalioColors.greenAccent,
                            fontSize: 10.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (publishedAt != null)
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 14.w,
                              color: Colors.grey,
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              _formatFullDate(publishedAt),
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12.sp,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  SizedBox(height: 16.h),

                  // Title
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                      fontFamily: 'RobotoCondensed',
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  SizedBox(height: 12.h),

                  // Author
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 12.w,
                        backgroundColor: GoalioColors.greenAccent.withOpacity(
                          0.2,
                        ),
                        child: Icon(
                          Icons.person,
                          size: 14.w,
                          color: GoalioColors.greenAccent,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        AppLocalizations.of(context)!.byAuthor(author),
                        style: TextStyle(
                          color: isDark ? Colors.white70 : Colors.black54,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),

                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 24.h),
                    child: Divider(color: Colors.grey.withOpacity(0.2)),
                  ),

                  // Description / Content
                  if (_isLoadingContent)
                    const Center(
                      child: CircularProgressIndicator(
                        color: GoalioColors.greenAccent,
                      ),
                    )
                  else if (description != null && description.length > 50)
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 16.sp,
                        height: 1.6,
                        color:
                            isDark
                                ? Colors.white.withOpacity(0.9)
                                : Colors.black87,
                      ),
                    )
                  else
                    Center(
                      child: Padding(
                        padding: EdgeInsets.only(top: 40.h),
                        child: Text(
                          AppLocalizations.of(context)!.fullContentNotAvailable,
                          style: TextStyle(
                            color: Colors.grey,
                            fontStyle: FontStyle.italic,
                            fontSize: 14.sp,
                          ),
                        ),
                      ),
                    ),

                  SizedBox(height: 40.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatFullDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat(
        'MMMM d, yyyy • HH:mm',
        Intl.defaultLocale,
      ).format(date);
    } catch (e) {
      return dateStr;
    }
  }
}
