import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';

import '../../core/constants/constants.dart';
import '../../core/services/api_service.dart';
import '../../core/utils/size_config.dart';
import '../../screens/news/news_detail_page.dart';
import '../../l10n/app_localizations.dart';
import '../../core/widgets/native_ad_widget.dart';

class NewsPage extends StatefulWidget {
  const NewsPage({super.key});

  @override
  State<NewsPage> createState() => NewsPageState();
}

class NewsPageState extends State<NewsPage> {
  List<dynamic> _news = [];
  bool _isLoading = false;
  String? _errorMessage;
  final ScrollController _scrollController = ScrollController();

  // Pagination
  int _offset = 0;
  static const int _limit = 50;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    loadNews(silent: true);
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoading &&
        !_isLoadingMore &&
        _hasMore) {
      _loadMoreNews();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void resetState() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> loadNews({
    bool silent = false,
    bool forceScrape = false,
    bool append = false,
  }) async {
    if (mounted) {
      setState(() {
        _isLoading = !silent || _news.isEmpty;
        _errorMessage = null;
        if (!silent && !append) _news = [];
      });
    }

    if (!append) {
      _offset = 0;
      _hasMore = true;
    }

    try {
      final fetchedNews = await ApiService.getNews(
        limit: _limit,
        offset: append ? 0 : _offset,
        scrape: forceScrape,
      );

      if (mounted) {
        setState(() {
          if (append) {
            final existingIds =
                _news
                    .whereType<Map<String, dynamic>>()
                    .map((item) => item['id'])
                    .toSet();
            final newItems =
                fetchedNews
                    .whereType<Map<String, dynamic>>()
                    .where(
                      (item) =>
                          item['id'] != null &&
                          !existingIds.contains(item['id']),
                    )
                    .toList();

            _news = [...newItems, ..._news];
            _offset = _news.length;
            _hasMore = newItems.length == _limit;
          } else {
            _news = fetchedNews;
            _offset += fetchedNews.length;
            _hasMore = fetchedNews.length == _limit;
          }

          _isLoading = false;
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (kDebugMode) debugPrint('📰 Error loading news: $e');
      if (mounted && (_news.isEmpty || !silent)) {
        setState(() {
          _isLoading = false;
          _errorMessage = AppLocalizations.of(context)!.noNewsAvailable;
        });
      }
    }
  }

  Future<void> appendLatestNews({bool silent = true}) async {
    await loadNews(silent: silent, forceScrape: true, append: true);
  }

  Future<void> _loadMoreNews() async {
    if (!mounted || _isLoadingMore || !_hasMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final fetchedNews = await ApiService.getNews(
        limit: _limit,
        offset: _offset,
      );

      if (mounted) {
        setState(() {
          _news.addAll(fetchedNews);
          _offset += fetchedNews.length;
          _hasMore = fetchedNews.length == _limit;
        });
      }
    } catch (e) {
      if (kDebugMode) debugPrint('📰 Error loading more news: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  Future<void> refreshNews() async {
    // Fast path: refresh from DB cache so the spinner dismisses quickly.
    // Background: scrape and prepend any new articles via append mode.
    await loadNews(silent: true, forceScrape: false);
    unawaited(appendLatestNews(silent: true));
  }

  List<dynamic> get _layoutItems {
    final List<dynamic> items = [];
    int i = 0;
    while (i < _news.length) {
      items.add(_news[i]);
      i++;

      if (i + 1 < _news.length) {
        items.add([_news[i], _news[i + 1]]);
        i += 2;
      } else if (i < _news.length) {
        items.add(_news[i]);
        i++;
      }
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: GoalioColors.greenAccent),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Text(
          _errorMessage!,
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
        ),
      );
    }

    if (_news.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.newspaper,
              size: 64.w,
              color: GoalioColors.greenAccent.withValues(alpha: 0.5),
            ),
            SizedBox(height: 16.h),
            Text(
              AppLocalizations.of(context)!.noNewsAvailable,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color,
                fontSize: 16.sp,
              ),
            ),
            SizedBox(height: 16.h),
            ElevatedButton.icon(
              onPressed: refreshNews,
              icon: const Icon(Icons.refresh),
              label: Text(AppLocalizations.of(context)!.refresh),
            ),
          ],
        ),
      );
    }

    final layoutItems = _layoutItems;
    final adCount = layoutItems.length ~/ 5;

    return Stack(
      children: [
        RefreshIndicator(
          color: GoalioColors.greenAccent,
          edgeOffset: 110.h,
          onRefresh: refreshNews,
          child: ListView.builder(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(16.w, 100.h, 16.w, 120.h),
            itemCount: layoutItems.length + adCount + (_isLoadingMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == layoutItems.length + adCount) {
                return Padding(
                  padding: EdgeInsets.symmetric(vertical: 20.h),
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: GoalioColors.greenAccent,
                    ),
                  ),
                );
              }

              // Show Native Ad after every 5 layout items
              if (index > 0 && (index + 1) % 6 == 0) {
                return const GoalioNativeAdWidget();
              }

              // Adjust index for ad positions
              final adOffset = (index + 1) ~/ 6;
              final actualIndex = index - adOffset;

              if (actualIndex >= layoutItems.length) {
                return const SizedBox.shrink();
              }

              final item = layoutItems[actualIndex];

              if (item is List) {
                return Padding(
                  padding: EdgeInsets.only(bottom: 16.h),
                  child: Row(
                    children: [
                      Expanded(
                        child: GoalioNewsCard(
                          article: item[0],
                          isSmall: true,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) => NewsDetailPage(
                                      article: item[0],
                                      heroTag:
                                          'news_tab_image_${item[0]['id']}',
                                    ),
                              ),
                            );
                          },
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: GoalioNewsCard(
                          article: item[1],
                          isSmall: true,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) => NewsDetailPage(
                                      article: item[1],
                                      heroTag:
                                          'news_tab_image_${item[1]['id']}',
                                    ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              }

              return GoalioNewsCard(
                article: item,
                isSmall: false,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => NewsDetailPage(
                            article: item,
                            heroTag: 'news_tab_image_${item['id']}',
                          ),
                    ),
                  );
                },
              );
            },
          ),
        ),

        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: EdgeInsetsDirectional.symmetric(
              horizontal: 16.w,
              vertical: 12.h,
            ),
            color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.95),
            child: SafeArea(
              bottom: false,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppLocalizations.of(context)!.latestNews,
                    style: TextStyle(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                      fontFamily: 'RobotoCondensed',
                      color: GoalioColors.greenAccent,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class GoalioNewsCard extends StatelessWidget {
  final Map<String, dynamic> article;
  final VoidCallback onTap;
  final bool isSmall;

  const GoalioNewsCard({
    super.key,
    required this.article,
    required this.onTap,
    this.isSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: isSmall ? 0 : 20.h),
      height: isSmall ? 180.h : 220.h,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16.w),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8.w,
            offset: Offset(0.w, 4.h),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.w),
        child: InkWell(
          onTap: onTap,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (article['image_url'] != null &&
                  article['image_url'].toString().isNotEmpty)
                Hero(
                  tag: 'news_tab_image_${article['id']}',
                  child: Image.network(
                    article['image_url'],
                    fit: BoxFit.cover,
                    errorBuilder:
                        (c, e, s) =>
                            Container(color: Theme.of(context).cardColor),
                  ),
                )
              else
                Container(color: Theme.of(context).cardColor),

              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.9),
                      Colors.black.withValues(alpha: 0.3),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),

              Padding(
                padding: EdgeInsets.all(isSmall ? 10.0.w : 16.0.w),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!isSmall)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: GoalioColors.greenAccent,
                          borderRadius: BorderRadius.circular(20.w),
                        ),
                        child: Text(
                          AppLocalizations.of(context)!.newsTag,
                          style: TextStyle(
                            color: const Color(0xFF0F172A),
                            fontWeight: FontWeight.bold,
                            fontSize: 10.sp,
                          ),
                        ),
                      ),
                    if (!isSmall) SizedBox(height: 10.h),

                    Text(
                      article['title'] ?? AppLocalizations.of(context)!.noTitle,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isSmall ? 13.sp : 17.sp,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                        fontFamily: 'RobotoCondensed',
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    SizedBox(height: 8.h),

                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          color: Colors.white70,
                          size: isSmall ? 10.w : 14.w,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          _formatDate(context, article['published_at']),
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: isSmall ? 10.sp : 12.sp,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(BuildContext context, String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inHours < 24) {
        if (diff.inHours > 0) {
          return AppLocalizations.of(context)!.hoursShort(diff.inHours);
        }
        return AppLocalizations.of(context)!.minutesShort(diff.inMinutes);
      }
      return DateFormat(
        'MMM d',
        AppLocalizations.of(context)!.localeName,
      ).format(date);
    } catch (e) {
      return '';
    }
  }
}
