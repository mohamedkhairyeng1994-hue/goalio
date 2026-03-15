import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import '../../core/utils/time_utils.dart';

import 'dart:ui' as ui; // Needed for ImageFilter

import '../../core/constants/constants.dart';
import '../../core/utils/logo_utils.dart';
import '../../core/services/api_service.dart';
import '../../core/utils/size_config.dart';
import '../../screens/fixtures/match_detail_page.dart';
import '../../screens/news/news_detail_page.dart';
import '../../l10n/app_localizations.dart';

class HomePage extends StatefulWidget {
  final VoidCallback onNavigateToFixtures;
  final VoidCallback onNavigateToNews;
  final VoidCallback onNavigateToLeagues;
  final Function(Map<String, dynamic> league) onLeagueTap;
  final VoidCallback onOpenSettings;

  const HomePage({
    super.key,
    required this.onNavigateToFixtures,
    required this.onNavigateToNews,
    required this.onNavigateToLeagues,
    required this.onLeagueTap,
    required this.onOpenSettings,
  });

  @override
  State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  List<dynamic> _news = [];
  List<dynamic> _upcomingMatches = [];
  List<dynamic> _activatedLeagues = [];
  bool _isLoading = true;
  final ScrollController _scrollController = ScrollController();
  final ScrollController _horizontalMatchesController = ScrollController();
  final ScrollController _leaguesScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    loadData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _horizontalMatchesController.dispose();
    _leaguesScrollController.dispose();
    super.dispose();
  }

  void resetScrollOnly() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    }
    if (_horizontalMatchesController.hasClients) {
      _horizontalMatchesController.animateTo(
        0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    }
    if (_leaguesScrollController.hasClients) {
      _leaguesScrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void resetState() {
    resetScrollOnly();
  }

  Future<void> loadData({bool forceScrape = false, bool silent = false}) async {
    final hasData = _news.isNotEmpty || _upcomingMatches.isNotEmpty;

    if (!silent && !hasData && mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    // Prepare tasks for parallel execution
    final List<Future> tasks = [
      _loadUpcomingMatches(forceScrape: forceScrape),
      _loadActivatedLeagues(),
    ];

    // For news: Always do only a fast DB fetch.
    tasks.add(_loadNews());

    await Future.wait(tasks);

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadUpcomingMatches({bool forceScrape = false}) async {
    try {
      final highlightsUrl = Uri.parse(
        '${ApiConstants.authBaseUrl}/matches/highlights',
      );

      final headers = await ApiService.reqHeaders;
      final response = await http
          .get(highlightsUrl, headers: headers)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 && mounted) {
        final decoded = json.decode(utf8.decode(response.bodyBytes));
        final List<dynamic> rawMatches =
            decoded is Map ? (decoded['data'] ?? []) : (decoded as List);

        final l10n = AppLocalizations.of(context);
        final processed =
            rawMatches.map((m) {
              final map = Map<String, dynamic>.from(m);
              if (l10n != null) {
                map['date_label'] = _getDateLabel(map['match_date'], l10n);
              } else {
                map['date_label'] = '';
              }
              return map;
            }).toList();

        setState(() {
          _upcomingMatches = processed;
        });
      }

      // Background scrape to keep data fresh
      final now = DateTime.now();
      final todayDateStr =
          "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

      _triggerBackgroundScrape(todayDateStr, highlightsUrl);
    } catch (e) {
      debugPrint("Error in _loadUpcomingMatches: $e");
    }
  }

  void _triggerBackgroundScrape(String date, Uri highlightsUrl) async {
    try {
      final scrapeUrl = Uri.parse(
        '${ApiConstants.authBaseUrl}/scrape?date=$date',
      );
      final headers = await ApiService.reqHeaders;
      // Scrape for today
      await http
          .get(scrapeUrl, headers: headers)
          .timeout(const Duration(seconds: 120));

      // Also potentially scrape for tomorrow if it's early or forced
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final tomorrowDateStr =
          "${tomorrow.year}-${tomorrow.month.toString().padLeft(2, '0')}-${tomorrow.day.toString().padLeft(2, '0')}";
      final tomorrowScrapeUrl = Uri.parse(
        '${ApiConstants.authBaseUrl}/scrape?date=$tomorrowDateStr',
      );
      await http
          .get(tomorrowScrapeUrl, headers: headers)
          .timeout(const Duration(seconds: 120));

      // Refresh highlights from DB after scrape
      final response = await http
          .get(highlightsUrl, headers: headers)
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200 && mounted) {
        final now = DateTime.now();
        final todayDateStr =
            "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

        final decoded = json.decode(utf8.decode(response.bodyBytes));
        final List<dynamic> rawMatches =
            decoded is Map ? (decoded['data'] ?? []) : (decoded as List);

        final l10n = AppLocalizations.of(context);
        final processed =
            rawMatches.map((m) {
              final map = Map<String, dynamic>.from(m);
              if (l10n != null) {
                map['date_label'] = _getDateLabel(map['match_date'], l10n);
              } else {
                map['date_label'] = '';
              }
              return map;
            }).toList();

        setState(() {
          _upcomingMatches = processed;
        });
      }
    } catch (_) {}
  }

  String _getDateLabel(String? dateStr, AppLocalizations? l10n) {
    if (dateStr == null || l10n == null) return '';
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(const Duration(days: 1));

      final matchDate = DateTime.parse(dateStr);
      final matchDay = DateTime(matchDate.year, matchDate.month, matchDate.day);

      if (matchDay.isAtSameMomentAs(today)) return l10n.today;
      if (matchDay.isAtSameMomentAs(tomorrow)) return l10n.tomorrow;

      // format as "Mon, Jan 29"
      return DateFormat('EEE, MMM d', Intl.defaultLocale).format(matchDate);
    } catch (e) {
      return dateStr;
    }
  }

  Future<void> _loadNews() async {
    // We strictly follow "remove scrape news in home page"
    // so we always set scrape to false.
    try {
      final news = await ApiService.getNews(limit: 10, scrape: false);
      if (mounted) {
        setState(() {
          _news = news;
        });
      }
    } catch (e) {
      debugPrint("Error loading news on home: $e");
    }
  }

  Future<void> _loadActivatedLeagues() async {
    const mainLeagues = [
      'England - Premier League',
      'Spain - LaLiga',
      'Italy - Serie A',
      'Germany - Bundesliga',
      'France - Ligue 1',
      'Saudi Arabia - Saudi Pro League',
    ];

    try {
      final List<dynamic> leaguesData = await ApiService.getLeagues();
      if (mounted) {
        setState(() {
          // Parse all, then filter for the 6 main ones
          final parsed =
              leaguesData
                  .map((l) => l is Map ? Map<String, dynamic>.from(l) : null)
                  .where((l) => l != null && l['name'] != null)
                  .map((l) => l!)
                  .toList();

          _activatedLeagues =
              parsed
                  .where(
                    (l) =>
                        mainLeagues.contains(l['original_name'] ?? l['name']),
                  )
                  .toList();

          // Sort them according to the mainLeagues list order
          _activatedLeagues.sort((a, b) {
            return mainLeagues
                .indexOf(a['original_name'] ?? a['name'])
                .compareTo(
                  mainLeagues.indexOf(b['original_name'] ?? b['name']),
                );
          });
        });
      }
    } catch (e) {
      debugPrint("Error loading activated leagues: $e");
    }
  }

  bool isLive(dynamic m) {
    return isLiveStatus(m['status']?.toString());
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _upcomingMatches.isEmpty) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: const Center(
          child: CircularProgressIndicator(color: GoalioColors.greenAccent),
        ),
      );
    }

    // List is already sorted by Live > Favorites > Time in _loadUpcomingMatches.
    // So if there are live matches, they are at the top.

    dynamic heroMatch;
    List<dynamic> otherMatches = [];

    if (_upcomingMatches.isNotEmpty) {
      final first = _upcomingMatches.first;
      // Featured match is ONLY allowed if it is LIVE and associated with a Favorite TEAM
      // Use the backend-computed 'is_favorite_team' for reliability
      bool isFavoriteLive =
          isLive(first) && (first['is_favorite_team'] == true);

      if (isFavoriteLive) {
        heroMatch = first;
        otherMatches = _upcomingMatches.where((m) => m != heroMatch).toList();
      } else {
        // No favorite team is live, so don't show the featured card
        heroMatch = null;
        otherMatches = _upcomingMatches;
      }
      // Show up to 20 favorite matches if available
      otherMatches = otherMatches.take(20).toList();
    }

    final hasLive = _upcomingMatches.any(
      (m) => isLive(m) && (m['is_favorite_team'] == true),
    );

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final displayColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white;

    return Scaffold(
      extendBodyBehindAppBar: true, // For glassmorphism effect
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Container(
        decoration: BoxDecoration(
          gradient:
              isDark
                  ? const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF0F172A), // Dark Navy
                      Color(0xFF020617), // Almost Black
                    ],
                  )
                  : LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [const Color(0xFFF1F5F9), const Color(0xFFE2E8F0)],
                  ),
        ),
        child: RefreshIndicator(
          onRefresh: () => loadData(forceScrape: true),
          color: GoalioColors.greenAccent,
          backgroundColor: Theme.of(context).cardColor,
          child: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // Glassmorphic AppBar
              SliverAppBar(
                backgroundColor:
                    isDark
                        ? Colors.black.withOpacity(0.3)
                        : Colors.white.withOpacity(0.3),
                flexibleSpace: ClipRRect(
                  child: BackdropFilter(
                    filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(color: Colors.transparent),
                  ),
                ),
                expandedHeight: 70.h,
                collapsedHeight: 70.h,
                toolbarHeight: 70.h,
                automaticallyImplyLeading: false,
                floating: true,
                pinned: true,
                elevation: 0,
                centerTitle: false,
                titleSpacing: 0,
                title: Transform.translate(
                  offset: Offset(
                    Directionality.of(context) == ui.TextDirection.ltr
                        ? -25.w
                        : 25.w,
                    0,
                  ),
                  child: Image.asset(
                    isDark
                        ? 'assets/goalio_logo.png'
                        : 'assets/goalio_logo_light.png',
                    height: 140.h,
                    fit: BoxFit.contain,
                    alignment: AlignmentDirectional.centerStart,
                    errorBuilder:
                        (c, e, s) => const Icon(
                          Icons.sports_soccer,
                          color: GoalioColors.greenAccent,
                        ),
                  ),
                ),
                actions: [
                  Container(
                    margin: EdgeInsetsDirectional.only(end: 16.w),
                    decoration: BoxDecoration(
                      color:
                          isDark
                              ? Colors.white.withOpacity(0.08)
                              : Colors.black.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12.w),
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.menu,
                        color: isDark ? Colors.white : Colors.black87,
                        size: 22.w,
                      ),
                      onPressed: widget.onOpenSettings,
                    ),
                  ),
                ],
              ),

              // Hero Match Section (The Big Card)
              if (heroMatch != null) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20.w, 4.h, 20.w, 16.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              AppLocalizations.of(context)!.featuredMatch,
                              style: TextStyle(
                                color: GoalioColors.greenAccent,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                                fontSize: 12.sp,
                              ),
                            ),
                            SizedBox(width: 8.w),
                            if (hasLive)
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8.w,
                                  vertical: 4.h,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.redAccent,
                                  borderRadius: BorderRadius.circular(12.w),
                                ),
                                child: Text(
                                  AppLocalizations.of(context)!.live,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        SizedBox(height: 12.h),
                        _buildHeroMatchCard(heroMatch),
                      ],
                    ),
                  ),
                ),
              ],

              // Other Matches (Horizontal Scroll)
              if (otherMatches.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 10.h),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.upcomingMatches,
                          style: TextStyle(
                            color: displayColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 16.sp,
                          ),
                        ),
                        GestureDetector(
                          onTap: widget.onNavigateToFixtures,
                          child: Text(
                            AppLocalizations.of(context)!.seeAll,
                            style: TextStyle(
                              color: GoalioColors.blueAccent,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 160.h,
                    child: ListView.builder(
                      controller: _horizontalMatchesController,
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                      itemCount: otherMatches.length,
                      itemBuilder: (context, index) {
                        return _buildCompactMatchCard(otherMatches[index]);
                      },
                    ),
                  ),
                ),
              ],

              // Activated Leagues Section (Now after matches)
              _buildLeaguesSection(),

              // Featured News Section (Vertical)
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 8.h),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.trendingNews,
                        style: TextStyle(
                          color: displayColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 18.sp,
                        ),
                      ),
                      GestureDetector(
                        onTap: widget.onNavigateToNews,
                        child: Text(
                          AppLocalizations.of(context)!.seeAll,
                          style: TextStyle(
                            color: GoalioColors.blueAccent,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              if (_news.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(20.w),
                    child: Text(
                      AppLocalizations.of(context)!.noNewsAvailable,
                      style: TextStyle(
                        color:
                            Theme.of(context).textTheme.bodySmall?.color ??
                            Colors.white54,
                      ),
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    return _buildImmersiveNewsCard(_news[index]);
                  }, childCount: _news.length),
                ),

              SliverPadding(padding: EdgeInsets.only(bottom: 100.h)),
            ],
          ),
        ),
      ),
    );
  }

  // --- Widgets ---

  Widget _buildLeaguesSection() {
    if (_activatedLeagues.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    final displayColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white;

    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 10.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppLocalizations.of(context)!.leagueStandings,
                  style: TextStyle(
                    color: displayColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16.sp,
                  ),
                ),
                GestureDetector(
                  onTap: widget.onNavigateToLeagues,
                  child: Text(
                    AppLocalizations.of(context)!.seeAll,
                    style: TextStyle(
                      color: GoalioColors.blueAccent,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 150.h,
            child: ListView.builder(
              controller: _leaguesScrollController,
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 14.w),
              itemCount: _activatedLeagues.length,
              itemBuilder: (context, index) {
                final league = _activatedLeagues[index];
                return _buildLeagueCard(league);
              },
            ),
          ),
          // Removed bottom spacer to fix excessive gap
        ],
      ),
    );
  }

  Widget _buildLeagueCard(dynamic league) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fullName = league['name']?.toString() ?? 'League';
    final logoUrl = league['logo_url']?.toString();

    // Extract short name (e.g., "Premier League" from "England - Premier League")
    String displayName = fullName;
    if (fullName.contains(' - ')) {
      displayName = fullName.split(' - ').last;
    }

    return GestureDetector(
      onTap: () => widget.onLeagueTap(Map<String, dynamic>.from(league)),
      child: Container(
        width: 130.w,
        margin: EdgeInsets.symmetric(horizontal: 6.w, vertical: 8.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20.w),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors:
                isDark
                    ? [
                      const Color(0xFF1E293B),
                      const Color(0xFF0F172A).withOpacity(0.8),
                    ]
                    : [Colors.white, const Color(0xFFF1F5F9)],
          ),
          border: Border.all(
            color:
                isDark
                    ? Colors.white.withOpacity(0.08)
                    : Colors.black.withOpacity(0.05),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Ghost logo in background
            Positioned(
              right: -10.w,
              bottom: -10.w,
              child: Opacity(
                opacity: 0.05,
                child:
                    logoUrl != null && logoUrl.isNotEmpty
                        ? Image.network(
                          logoUrl,
                          width: 80.w,
                          height: 80.w,
                          fit: BoxFit.contain,
                        )
                        : Icon(Icons.emoji_events, size: 80.w),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(12.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Logo container
                  Container(
                    width: 44.w,
                    height: 44.w,
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color:
                          isDark
                              ? Colors.white.withOpacity(0.05)
                              : Colors.white,
                      borderRadius: BorderRadius.circular(12.w),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child:
                        logoUrl != null && logoUrl.isNotEmpty
                            ? Image.network(logoUrl, fit: BoxFit.contain)
                            : const Icon(
                              Icons.emoji_events,
                              color: GoalioColors.greenAccent,
                              size: 20,
                            ),
                  ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: TextStyle(
                          color:
                              isDark ? Colors.white : const Color(0xFF0F172A),
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                          height: 1.1,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4.h),
                      Row(
                        children: [
                          Text(
                            AppLocalizations.of(context)!.standingsTab,
                            style: TextStyle(
                              color: GoalioColors.greenAccent,
                              fontSize: 9.sp,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Icon(
                            Icons.chevron_right,
                            size: 10.sp,
                            color: GoalioColors.greenAccent,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroMatchCard(dynamic match) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (_) => MatchDetailPage(
                  match: Map<String, dynamic>.from(match as Map),
                ),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(24.w),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
          ),
          boxShadow: [
            BoxShadow(
              color: GoalioColors.greenAccent.withOpacity(0.15),
              blurRadius: 20.w,
              offset: Offset(0, 8.h),
            ),
          ],
        ),
        child: Column(
          children: [
            // Competition Tag
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(20.w),
              ),
              child: Text(
                match['competition'] ??
                    AppLocalizations.of(context)!.featuredMatch,
                style: TextStyle(
                  color: GoalioColors.greenAccent,
                  fontSize: 10.sp,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            SizedBox(height: 20.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    buildTeamLogo(match['home_team_image'], size: 56.w),
                    SizedBox(height: 12.h),
                    SizedBox(
                      width: 80.w,
                      child: Text(
                        match['home_team'] ??
                            AppLocalizations.of(context)!.homeTeam,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    if (isLive(match) ||
                        isFinishedStatus(match['status']?.toString()))
                      Column(
                        children: [
                          Text(
                            "${match['home_score'] == 'N/A' ? '0' : match['home_score']} - ${match['away_score'] == 'N/A' ? '0' : match['away_score']}",
                            style: TextStyle(
                              fontSize: 32.sp,
                              fontWeight: FontWeight.w900,
                              color: Colors.redAccent,
                            ),
                          ),
                          if (match['home_score_pen'] != null &&
                              match['home_score_pen'] != 'N/A' &&
                              match['away_score_pen'] != null &&
                              match['away_score_pen'] != 'N/A')
                            Text(
                              "(${match['home_score_pen']} - ${match['away_score_pen']})",
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                                color:
                                    Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.amber[300]
                                        : Colors.orange[700],
                              ),
                            ),
                        ],
                      )
                    else if (match['home_score'] != 'N/A')
                      Text(
                        "${match['home_score']} - ${match['away_score']}",
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontSize: 32.sp,
                          fontWeight: FontWeight.w900,
                        ),
                      )
                    else
                      Text(
                        AppLocalizations.of(context)!.vs,
                        style: TextStyle(
                          color: Colors.white24,
                          fontSize: 32.sp,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    SizedBox(height: 8.h),
                    if (isLive(match))
                      Text(
                        ((match['status'].toString().toUpperCase() == 'LIVE' ||
                                    match['status'].toString().toUpperCase() ==
                                        'HT') &&
                                match['time'] != null &&
                                match['time'].toString().isNotEmpty &&
                                (match['time'].toString().contains("'") ||
                                    RegExp(
                                      r'^\d+$',
                                    ).hasMatch(match['time'].toString())))
                            ? (match['time'].toString().contains("'")
                                ? match['time'].toString()
                                : "${match['time']}'")
                            : localizeMatchStatus(context, match['status']),
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 12.sp,
                        ),
                      )
                    else if (match['status'] == 'HT' || match['status'] == 'FT')
                      Text(
                        localizeMatchStatus(context, match['status']),
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 12.sp,
                        ),
                      )
                    else
                      Text(
                        formatMatchTime(match['time']),
                        style: TextStyle(
                          color: Colors.white54,
                          fontWeight: FontWeight.bold,
                          fontSize: 12.sp,
                        ),
                      ),
                  ],
                ),
                Column(
                  children: [
                    buildTeamLogo(match['away_team_image'], size: 56.w),
                    SizedBox(height: 12.h),
                    SizedBox(
                      width: 80.w,
                      child: Text(
                        match['away_team'] ??
                            AppLocalizations.of(context)!.awayTeam,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactMatchCard(dynamic match) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final status = match['status']?.toString();
    final isLive = isLiveStatus(status);
    final isFinished = isFinishedStatus(status);

    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = (screenWidth * 0.75).clamp(240.0, 320.0);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (_) => MatchDetailPage(
                  match: Map<String, dynamic>.from(match as Map),
                ),
          ),
        );
      },
      child: Container(
        width: cardWidth,
        margin: EdgeInsetsDirectional.only(end: 12.w),
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16.w),
          border: Border.all(
            color:
                isDark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.black.withOpacity(0.05),
          ),
          boxShadow:
              isDark
                  ? []
                  : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4.w,
                      offset: Offset(0, 2.h),
                    ),
                  ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Top row: League Name and Dynamic Badge (Live or Date)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    (match['competition'] ?? 'League').toString().toUpperCase(),
                    style: TextStyle(
                      color: GoalioColors.greenAccent,
                      fontSize: 8.sp,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color:
                        isLive
                            ? Colors.redAccent
                            : isDark
                            ? Colors.white.withOpacity(0.05)
                            : Colors.black.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(6.w),
                  ),
                  child: Text(
                    isLive
                        ? AppLocalizations.of(context)!.live
                        : (match['date_label'] ?? ''),
                    style: TextStyle(
                      color:
                          isLive
                              ? Colors.white
                              : isDark
                              ? Colors.white54
                              : Colors.black54,
                      fontSize: 8.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      buildTeamLogo(match['home_team_image'], size: 28.w),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          match['home_team'] ??
                              AppLocalizations.of(context)!.homeTeam,
                          style: TextStyle(
                            color:
                                Theme.of(context).textTheme.bodyMedium?.color,
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8.w),
                Text(
                  (isLive || isFinished)
                      ? (match['home_score'] != 'N/A'
                          ? "${match['home_score']}"
                          : '0')
                      : "-",
                  style: TextStyle(
                    color: isLive ? Colors.redAccent : Colors.grey,
                    fontWeight: FontWeight.bold,
                    fontSize: 16.sp,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      buildTeamLogo(match['away_team_image'], size: 28.w),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          match['away_team'] ??
                              AppLocalizations.of(context)!.awayTeam,
                          style: TextStyle(
                            color:
                                Theme.of(context).textTheme.bodyMedium?.color,
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8.w),
                Text(
                  (isLive || isFinished)
                      ? (match['away_score'] != 'N/A'
                          ? "${match['away_score']}"
                          : '0')
                      : "-",
                  style: TextStyle(
                    color: isLive ? Colors.redAccent : Colors.grey,
                    fontWeight: FontWeight.bold,
                    fontSize: 16.sp,
                  ),
                ),
              ],
            ),
            Divider(
              color: Theme.of(context).dividerColor.withOpacity(0.1),
              height: 16.h,
            ),
            Text(
              localizeMatchStatus(
                context,
                match['status'] == 'HT' ? 'HT' : match['time'],
              ),
              style: TextStyle(
                color:
                    isLive
                        ? Colors.redAccent
                        : Theme.of(context).textTheme.bodySmall?.color,
                fontSize: 10.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ), // close Column
      ), // close Container
    ); // close GestureDetector
  }

  Widget _buildImmersiveNewsCard(dynamic article) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (_) => NewsDetailPage(
                  article: article,
                  heroTag: 'home_news_${article['id']}',
                ),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
        height: 160.h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20.w),
          color: Theme.of(context).cardColor,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20.w),
          child: Stack(
            children: [
              // Background Image
              if (article['image_url'] != null)
                Positioned.fill(
                  child: Hero(
                    tag: 'home_news_${article['id']}',
                    child: Image.network(
                      article['image_url'],
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

              // Gradient Overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.9),
                      ],
                    ),
                  ),
                ),
              ),

              // Text Content
              Padding(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: GoalioColors.greenAccent,
                        borderRadius: BorderRadius.circular(4.w),
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.newsTag,
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 10.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      article['title'] ??
                          AppLocalizations.of(context)!.fullStory,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16.sp,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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
} // End HomePage
