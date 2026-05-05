import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;


import '../../core/services/api_service.dart';
import '../../core/constants/constants.dart';
import '../../core/utils/logo_utils.dart';
import '../../core/utils/size_config.dart';
import '../../core/utils/time_utils.dart';
import '../../core/utils/number_utils.dart';
import '../../core/utils/name_translator.dart';
import '../../core/utils/messages.dart';
import '../../l10n/app_localizations.dart';
import 'fantasy_hub_tab.dart';

class MatchDetailPage extends StatefulWidget {
  final Map<String, dynamic> match;

  const MatchDetailPage({super.key, required this.match});

  @override
  State<MatchDetailPage> createState() => _MatchDetailPageState();
}

class _MatchDetailPageState extends State<MatchDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic> _overview = {};
  Map<String, dynamic> _lineup = {};
  bool _homeIsFavorite = false;
  bool _awayIsFavorite = false;

  bool get _isPremierLeague {
    final leagueId = widget.match['league_id'];
    return leagueId == 1 || leagueId?.toString() == '1';
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _isPremierLeague ? 5 : 4,
      vsync: this,
    );
    _homeIsFavorite = widget.match['home_is_favorite'] ?? false;
    _awayIsFavorite = widget.match['away_is_favorite'] ?? false;
    _loadDetails(forceRefresh: true);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDetails({bool forceRefresh = false}) async {
    final matchUrl = widget.match['match_url'];
    if (matchUrl == null || matchUrl.toString().isEmpty) {
      setState(() {
        _error = AppLocalizations.of(context)!.noMatchDetails;
        _isLoading =
            forceRefresh ? false : _isLoading; // Keep loading if initial
      });
      return;
    }

    if (!forceRefresh) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final refreshParam = forceRefresh ? '&refresh=true' : '';
      final uri = Uri.parse(
        '${ApiConstants.authBaseUrl}/match-details?url=${Uri.encodeComponent(matchUrl.toString())}$refreshParam',
      );
      final response = await http
          .get(uri, headers: await ApiService.reqHeaders)
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final decoded = json.decode(utf8.decode(response.bodyBytes));
        if (decoded is Map) {
          // Laravel API Resources wrap data in a 'data' key
          final data = decoded.containsKey('data') ? decoded['data'] : decoded;

          setState(() {
            _overview = (data['overview'] as Map<String, dynamic>?) ?? {};
            _lineup = (data['lineup'] as Map<String, dynamic>?) ?? {};
            _isLoading = false;
          });
          return;
        }
      }
      setState(() {
        _error =
            '${AppLocalizations.of(context)!.failedToLoadDetails} (${response.statusCode})';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = AppLocalizations.of(context)!.serverConnectionError;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleFavoriteTeam(bool isHome) async {
    final teamId =
        isHome ? widget.match['home_team_id'] : widget.match['away_team_id'];
    final name = isHome ? widget.match['home_team'] : widget.match['away_team'];
    final logo =
        isHome
            ? widget.match['home_team_image'] ?? widget.match['home_logo']
            : widget.match['away_team_image'] ?? widget.match['away_logo'];
    final leagueName = widget.match['competition'];

    final oldVal = isHome ? _homeIsFavorite : _awayIsFavorite;

    setState(() {
      if (isHome) {
        _homeIsFavorite = !oldVal;
      } else {
        _awayIsFavorite = !oldVal;
      }
    });

    final result = await ApiService.toggleFavoriteTeam(
      teamId: teamId,
      name: name,
      logo: logo,
      leagueName: leagueName,
    );

    if (result.containsKey('error')) {
      if (mounted) {
        setState(() {
          if (isHome) {
            _homeIsFavorite = oldVal;
          } else {
            _awayIsFavorite = oldVal;
          }
        });
        GoalioMessages.showError(context, result['error']);
      }
    } else {
      if (mounted) {
        final isFav = result['is_favorite'] ?? !oldVal;
        setState(() {
          if (isHome) {
            _homeIsFavorite = isFav;
          } else {
            _awayIsFavorite = isFav;
          }
        });
        GoalioMessages.showSuccess(
          context,
          isFav
              ? AppLocalizations.of(context)!.addedToFavorites
              : AppLocalizations.of(context)!.removedFromFavorites,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final match = widget.match;

    final homeTeam = match['home_team'] ?? 'Home';
    final awayTeam = match['away_team'] ?? 'Away';
    final homeScore = match['home_score'];
    final awayScore = match['away_score'];
    final status = match['status']?.toString() ?? '';
    final statusUpper = status.toUpperCase();
    final isLive =
        statusUpper == 'LIVE' ||
        statusUpper == 'HT' ||
        RegExp(r'^\d').hasMatch(status);
    final isFinished =
        statusUpper == 'FT' ||
        statusUpper == 'AET' ||
        statusUpper == 'PEN' ||
        statusUpper == 'FINAL' ||
        statusUpper == 'FINISHED';

    final competition = match['competition'] ?? '';
    final scoreInfo = (_overview['score_info'] as Map<String, dynamic>?) ?? {};

    int homeEventsCount = 0;
    int awayEventsCount = 0;
    final eventsList = (_overview['events'] as List<dynamic>?) ?? [];
    for (var e in eventsList) {
      if (e is Map<String, dynamic>) {
        final type = e['type']?.toString();
        if (type == 'goal' ||
            type == 'penalty_goal' ||
            type == 'own_goal' ||
            type == 'red_card' ||
            type == 'yellow_red') {
          if (e['team'] == 'home') {
            homeEventsCount++;
          } else if (e['team'] == 'away') {
            awayEventsCount++;
          }
        }
      }
    }
    final int maxEvents =
        homeEventsCount > awayEventsCount ? homeEventsCount : awayEventsCount;
    final double dynamicAppbarHeight = 180.h + (maxEvents * 16.h) + 16.h;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: RefreshIndicator(
        color: GoalioColors.greenAccent,
        backgroundColor: Theme.of(context).cardColor,
        onRefresh: () => _loadDetails(forceRefresh: true),
        // NestedScrollView > TabBarView > CustomScrollView = depth 2
        notificationPredicate: (notification) => notification.depth == 2,
        child: NestedScrollView(
          headerSliverBuilder:
              (context, innerBoxScrolled) => [
                SliverOverlapAbsorber(
                  handle: NestedScrollView.sliverOverlapAbsorberHandleFor(
                    context,
                  ),
                  sliver: SliverAppBar(
                    expandedHeight: dynamicAppbarHeight,
                    pinned: true,
                    backgroundColor: const Color(0xFF1E293B),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    flexibleSpace: FlexibleSpaceBar(
                      background: _buildHeroHeader(
                        context,
                        homeTeam,
                        awayTeam,
                        homeScore,
                        awayScore,
                        status,
                        competition,
                        match,
                        isDark,
                        isLive,
                        isFinished,
                        scoreInfo['minute']?.toString(),
                      ),
                    ),
                    bottom: PreferredSize(
                      preferredSize: Size.fromHeight(54.h),
                      child: Column(
                        children: [
                          Container(
                            height: 40.h,
                            margin: EdgeInsetsDirectional.fromSTEB(
                              16.w,
                              0,
                              16.w,
                              8.h,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(25.w),
                            ),
                            child: TabBar(
                              controller: _tabController,
                              isScrollable: true,
                              tabAlignment: TabAlignment.start,
                              dividerColor: Colors.transparent,
                              indicatorSize: TabBarIndicatorSize.tab,
                              indicatorPadding: EdgeInsets.all(4.w),
                              indicator: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    GoalioColors.greenAccent,
                                    GoalioColors.blueAccent,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(25.w),
                                boxShadow: [
                                  BoxShadow(
                                    color: GoalioColors.greenAccent.withValues(alpha: 0.3),
                                    blurRadius: 8.w,
                                    offset: Offset(0, 2.h),
                                  ),
                                ],
                              ),
                              labelColor: Colors.white,
                              unselectedLabelColor: Colors.white60,
                              labelStyle: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12.sp,
                                fontFamily: 'RobotoCondensed',
                              ),
                              unselectedLabelStyle: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 12.sp,
                                fontFamily: 'RobotoCondensed',
                              ),
                              tabs: [
                                Tab(
                                  text: AppLocalizations.of(context)!.overview,
                                ),
                                Tab(
                                  text:
                                      AppLocalizations.of(context)!.statistics,
                                ),
                                Tab(
                                  text: AppLocalizations.of(context)!.timeline,
                                ),
                                Tab(text: AppLocalizations.of(context)!.lineup),
                                if (_isPremierLeague)
                                  Tab(
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.emoji_events_rounded,
                                          size: 12.w,
                                        ),
                                        SizedBox(width: 4.w),
                                        Text(
                                          AppLocalizations.of(
                                            context,
                                          )!.fantasyHub,
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Divider(
                            height: 1.0,
                            thickness: 1.0,
                            color:
                                isDark
                                    ? Colors.white.withValues(alpha: 0.1)
                                    : Colors.black.withValues(alpha: 0.1),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
          body: Builder(
            builder: (innerContext) {
              if (_isLoading) {
                return CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: ClampingScrollPhysics(),
                  ),
                  slivers: [
                    SliverOverlapInjector(
                      handle: NestedScrollView.sliverOverlapAbsorberHandleFor(
                        innerContext,
                      ),
                    ),
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: CircularProgressIndicator(
                          color: GoalioColors.greenAccent,
                        ),
                      ),
                    ),
                  ],
                );
              }
              if (_error != null) {
                return _buildErrorState(innerContext);
              }
              return TabBarView(
                controller: _tabController,
                children: [
                  _buildOverviewTab(innerContext),
                  _buildStatisticsTab(innerContext),
                  _buildEventsTab(innerContext),
                  _buildLineupTab(innerContext),
                  if (_isPremierLeague)
                    _buildFantasyHubTab(innerContext),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  HERO HEADER
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildHeroHeader(
    BuildContext context,
    String home,
    String away,
    dynamic homeScore,
    dynamic awayScore,
    String status,
    String competition,
    Map<String, dynamic> match,
    bool isDark,
    bool isLive,
    bool isFinished,
    String? minute,
  ) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          SizedBox(height: MediaQuery.of(context).padding.top + 12.h),
          // Competition
          if (competition.isNotEmpty)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Text(
                competition.toString().toArabicName(context).toUpperCase(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: GoalioColors.greenAccent,
                  fontSize: 10.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          SizedBox(height: 4.h),

          // Teams & Score
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Home Team
              Expanded(
                child: Column(
                  children: [
                    buildTeamLogo(
                      match['home_team_image'] ?? match['home_logo'],
                      size: 48.w,
                    ),
                    SizedBox(height: 6.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () => _toggleFavoriteTeam(true),
                          child: Padding(
                            padding: EdgeInsetsDirectional.only(end: 4.w),
                            child: Icon(
                              _homeIsFavorite
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              color:
                                  _homeIsFavorite
                                      ? Colors.amber
                                      : Colors.white24,
                              size: 22.w,
                            ),
                          ),
                        ),
                        Flexible(
                          child: Text(
                            ArabicNameExtension(home).toArabicName(context),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13.sp,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'RobotoCondensed',
                            ),
                          ),
                        ),
                      ],
                    ),

                    _buildScorersAndCards(true),
                  ],
                ),
              ),

              // Score / Status
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12.w),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    if (isLive || homeScore != null && homeScore != 'N/A')
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            homeScore != null && homeScore != 'N/A'
                                ? homeScore.toString().toArabicNumbers(context)
                                : '-',
                            style: TextStyle(
                              color: isLive ? Colors.redAccent : Colors.white,
                              fontSize: 36.sp,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'RobotoCondensed',
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8.w),
                            child: Text(
                              ':',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 30.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Text(
                            awayScore != null && awayScore != 'N/A'
                                ? awayScore.toString().toArabicNumbers(context)
                                : '-',
                            style: TextStyle(
                              color: isLive ? Colors.redAccent : Colors.white,
                              fontSize: 36.sp,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'RobotoCondensed',
                            ),
                          ),
                        ],
                      ),
                    if (match['home_score_pen'] != null &&
                        match['home_score_pen'] != 'N/A' &&
                        match['away_score_pen'] != null &&
                        match['away_score_pen'] != 'N/A')
                      Padding(
                        padding: EdgeInsets.only(top: 2.h),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '(',
                              style: TextStyle(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w600,
                                color:
                                    isDark
                                        ? Colors.amber[300]
                                        : Colors.orange[700],
                              ),
                            ),
                            Text(
                              "${match['home_score_pen']}".toArabicNumbers(
                                context,
                              ),
                              style: TextStyle(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w600,
                                color:
                                    isDark
                                        ? Colors.amber[300]
                                        : Colors.orange[700],
                              ),
                            ),
                            Text(
                              ' - ',
                              style: TextStyle(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w600,
                                color:
                                    isDark
                                        ? Colors.amber[300]
                                        : Colors.orange[700],
                              ),
                            ),
                            Text(
                              "${match['away_score_pen']}".toArabicNumbers(
                                context,
                              ),
                              style: TextStyle(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w600,
                                color:
                                    isDark
                                        ? Colors.amber[300]
                                        : Colors.orange[700],
                              ),
                            ),
                            Text(
                              ')',
                              style: TextStyle(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w600,
                                color:
                                    isDark
                                        ? Colors.amber[300]
                                        : Colors.orange[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    SizedBox(height: 4.h),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isLive
                                ? Colors.redAccent
                                : Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12.w),
                      ),
                      child: Text(
                        isLive
                            ? (minute != null && minute.isNotEmpty
                                ? "$minute'".toArabicNumbers(context)
                                : localizeMatchStatus(context, status))
                            : isFinished
                            ? localizeMatchStatus(context, status)
                            : localizeMatchStatus(
                              context,
                              match['time'] ?? match['match_time'],
                            ).toArabicNumbers(context),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Away Team
              Expanded(
                child: Column(
                  children: [
                    buildTeamLogo(
                      match['away_team_image'] ?? match['away_logo'],
                      size: 48.w,
                    ),
                    SizedBox(height: 6.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () => _toggleFavoriteTeam(false),
                          child: Padding(
                            padding: EdgeInsetsDirectional.only(end: 4.w),
                            child: Icon(
                              _awayIsFavorite
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              color:
                                  _awayIsFavorite
                                      ? Colors.amber
                                      : Colors.white24,
                              size: 22.w,
                            ),
                          ),
                        ),
                        Flexible(
                          child: Text(
                            ArabicNameExtension(away).toArabicName(context),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13.sp,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'RobotoCondensed',
                            ),
                          ),
                        ),
                      ],
                    ),

                    _buildScorersAndCards(false),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
        ],
      ),
    );
  }



  Widget _buildScorersAndCards(bool isHome) {
    if (_overview.isEmpty) return const SizedBox.shrink();
    final events = (_overview['events'] as List?) ?? [];
    final sideKey = isHome ? 'home' : 'away';

    final teamEvents =
        events
            .where((e) => e['team'] == sideKey)
            .where(
              (e) =>
                  e['type'] == 'goal' ||
                  e['type'] == 'penalty_goal' ||
                  e['type'] == 'own_goal' ||
                  e['type'] == 'red_card' ||
                  e['type'] == 'yellow_red',
            )
            .toList();

    if (teamEvents.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        SizedBox(height: 4.h),
        ...teamEvents.map((e) {
          final isRedCard =
              e['type'] == 'red_card' || e['type'] == 'yellow_red';
          return Padding(
            padding: EdgeInsets.symmetric(vertical: 1.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isRedCard)
                  Container(
                    width: 7.w,
                    height: 10.h,
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  )
                else
                  Icon(
                    Icons.sports_soccer_rounded,
                    size: 10.w,
                    color: Colors.white54,
                  ),
                SizedBox(width: 4.w),
                Flexible(
                  child: Text(
                    "${ArabicNameExtension(e['player']?.toString() ?? '').toArabicName(context)} ${(e['minute']?.toString() ?? '').toArabicNumbers(context)}",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 10.sp,
                      fontFamily: 'RobotoCondensed',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        }),
        SizedBox(height: 8.h),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  ERROR STATE
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildErrorState(BuildContext context) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: ClampingScrollPhysics(),
      ),
      slivers: [
        SliverOverlapInjector(
          handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
        ),
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(32.w),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.sports_soccer_outlined,
                    size: 64.w,
                    color: GoalioColors.greenAccent.withValues(alpha: 0.4),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                      fontSize: 14.sp,
                    ),
                  ),
                  SizedBox(height: 24.h),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: GoalioColors.greenAccent,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.w),
                      ),
                    ),
                    onPressed: _loadDetails,
                    icon: const Icon(Icons.refresh),
                    label: Text(AppLocalizations.of(context)!.retry),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  OVERVIEW TAB
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildOverviewTab(BuildContext context) {
    final scoreInfo = (_overview['score_info'] as Map<String, dynamic>?) ?? {};
    final rawForm = (_overview['form'] as Map<String, dynamic>?) ?? {};

    final homeForm = (rawForm['home'] as List<dynamic>?) ?? [];
    final awayForm = (rawForm['away'] as List<dynamic>?) ?? [];
    final hasForm = homeForm.isNotEmpty || awayForm.isNotEmpty;

    final channels = (_overview['channels'] as List<dynamic>?) ?? [];
    final hasChannels = channels.isNotEmpty;

    final bool hasInfo =
        scoreInfo['venue'] != null || scoreInfo['date'] != null;

    if (!hasInfo && !hasForm && !hasChannels) {
      return _buildNoDataWidget(
        context: context,
        icon: Icons.info_outline,
        message: AppLocalizations.of(context)!.matchInfoNotAvailable,
      );
    }

    return CustomScrollView(
      key: const PageStorageKey('overview'),
      physics: const AlwaysScrollableScrollPhysics(
        parent: ClampingScrollPhysics(),
      ),
      slivers: [
        SliverOverlapInjector(
          handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
        ),
        SliverPadding(
          padding: EdgeInsetsDirectional.fromSTEB(16.w, 16.h, 16.w, 100.h),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Section Label
              Padding(
                padding: EdgeInsets.only(bottom: 12.h),
                child: _buildSectionTitle(
                  AppLocalizations.of(context)!.matchOverviewLabel,
                ),
              ),
              // Venue / Date info strip
              if (hasInfo) _buildInfoStrip(scoreInfo),

              // ── TV Channels ────────────────────────────────────────────
              if (hasChannels) ..._buildChannelsSection(context, channels),

              // ── Team Form ──────────────────────────────────────────────
              if (hasForm)
                ..._buildFormSection(
                  context,
                  homeForm,
                  awayForm,
                  ArabicNameExtension(
                    scoreInfo['home_team']?.toString() ??
                        widget.match['home_team']?.toString() ??
                        AppLocalizations.of(context)!.homeTeam,
                  ).toArabicName(context),
                  ArabicNameExtension(
                    scoreInfo['away_team']?.toString() ??
                        widget.match['away_team']?.toString() ??
                        AppLocalizations.of(context)!.awayTeam,
                  ).toArabicName(context),
                ),
            ]),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  STATISTICS TAB
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildStatisticsTab(BuildContext context) {
    final rawStats = _overview['stats'];
    bool hasStats = false;
    List<Widget> statWidgets = [];

    if (rawStats is Map<String, dynamic>) {
      hasStats = rawStats.isNotEmpty;
      rawStats.forEach((category, items) {
        if (items is List) {
          statWidgets.add(
            Padding(
              padding: EdgeInsets.only(top: 16.h, bottom: 8.h),
              child: _buildSectionTitle(
                _localizeStatCategory(context, category),
              ),
            ),
          );
          statWidgets.addAll(
            items.map((s) => _buildStatRow(s as Map<String, dynamic>)),
          );
        }
      });
    } else if (rawStats is List) {
      hasStats = rawStats.isNotEmpty;
      if (hasStats) {
        statWidgets.add(
          Padding(
            padding: EdgeInsets.only(top: 16.h, bottom: 8.h),
            child: _buildSectionTitle(AppLocalizations.of(context)!.matchStats),
          ),
        );
        statWidgets.addAll(
          rawStats.map((s) => _buildStatRow(s as Map<String, dynamic>)),
        );
      }
    }

    if (!hasStats) {
      return _buildNoDataWidget(
        context: context,
        icon: Icons.bar_chart_outlined,
        message: AppLocalizations.of(context)!.matchStatsNotAvailable,
      );
    }

    return CustomScrollView(
      key: const PageStorageKey('statistics'),
      physics: const AlwaysScrollableScrollPhysics(
        parent: ClampingScrollPhysics(),
      ),
      slivers: [
        SliverOverlapInjector(
          handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 100.h),
          sliver: SliverList(delegate: SliverChildListDelegate(statWidgets)),
        ),
      ],
    );
  }

  String _localizeStatLabel(BuildContext context, String rawLabel) {
    final langCode = Localizations.localeOf(context).languageCode;
    if (langCode != 'ar') return rawLabel;

    switch (rawLabel.trim().toLowerCase()) {
      case 'ball possession':
      case 'possession':
        return 'الاستحواذ على الكرة';
      case 'expected goals (xg)':
      case 'expected goals':
        return 'الأهداف المتوقعة (xG)';
      case 'goal attempts':
      case 'total shots':
        return 'إجمالي التسديدات';
      case 'shots on goal':
      case 'shots on target':
      case 'shot on target':
        return 'التسديدات على المرمى';
      case 'shots off goal':
      case 'shots off target':
      case 'shot off target':
        return 'التسديدات خارج المرمى';
      case 'blocked shots':
        return 'التسديدات المعترضة';
      case 'shots inside box':
        return 'تسديدات داخل المنطقة';
      case 'shots outside box':
        return 'تسديدات خارج المنطقة';
      case 'free kicks':
      case 'free kick':
        return 'الركلات الحرة';
      case 'corner kicks':
      case 'corners':
      case 'corner total':
        return 'الركلات الركنية';
      case 'offsides':
      case 'offside total':
        return 'التسلل';
      case 'goalkeeper saves':
      case 'saves':
      case 'save total':
        return 'تصديات الحارس';
      case 'fouls':
      case 'foul commited':
      case 'foul committed':
        return 'الأخطاء';
      case 'red cards':
      case 'red card total':
        return 'البطاقات الحمراء';
      case 'yellow cards':
      case 'yellow card total':
        return 'البطاقات الصفراء';
      case 'goal kicks':
      case 'goal kick':
        return 'ركلة مرمى';
      case 'total passes':
        return 'إجمالي التمريرات';
      case 'passes':
        return 'التمريرات';
      case 'completed passes':
        return 'التمريرات المكتملة';
      case 'accurate passes':
        return 'التمريرات الدقيقة';
      case 'tackles':
        return 'التدخلات';
      case 'tackles won':
        return 'التدخلات الناجحة';
      case 'attacks':
        return 'الهجمات';
      case 'dangerous attacks':
        return 'الهجمات الخطيرة';
      case 'crosses':
        return 'العرضيات';
      case 'interceptions':
        return 'الاعتراضات';
      case 'clearances':
        return 'التشتيت';
      case 'long balls':
        return 'الكرات الطويلة';
      case 'throw-ins':
      case 'throw ins':
        return 'رميات التماس';
      case 'duels won':
        return 'الالتحامات الناجحة';
      case 'aerials won':
        return 'الالتحامات الهوائية';
      case 'possession lost':
        return 'فقدان الاستحواذ';
      case 'big chances':
        return 'فرص محققة';
      case 'big chances missed':
        return 'فرص محققة ضائعة';
      case 'hit woodwork':
        return 'تسديدات في العارضة';
      default:
        return rawLabel;
    }
  }

  String _localizeStatCategory(BuildContext context, String rawCategory) {
    final langCode = Localizations.localeOf(context).languageCode;
    if (langCode != 'ar') return rawCategory.toUpperCase();

    switch (rawCategory.trim().toLowerCase()) {
      case 'general':
      case 'match overview':
      case 'overview':
        return 'نظرة عامة';
      case 'shots':
        return 'تسديدات';
      case 'possession':
        return 'الاستحواذ';
      case 'passes':
        return 'تمريرات';
      case 'defending':
      case 'defense':
        return 'دفاع';
      case 'cards':
        return 'بطاقات';
      case 'discipline':
        return 'انضباط';
      case 'attacks':
      case 'attack':
        return 'هجمات';
      case 'duels':
        return 'التحامات';
      case 'expected goals':
        return 'الأهداف المتوقعة';
      case 'goalkeeper':
      case 'goalkeeping':
        return 'حارس المرمى';
      case 'player statistics':
        return 'إحصائيات اللاعبين';
      default:
        return rawCategory.toUpperCase();
    }
  }

  String _getArabicMonth(int month) {
    const arabicMonths = [
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر',
    ];
    if (month >= 1 && month <= 12) return arabicMonths[month - 1];
    return '';
  }

  String _localizeWDL(BuildContext context, String wdl) {
    final langCode = Localizations.localeOf(context).languageCode;
    if (langCode != 'ar') return wdl;
    switch (wdl.trim().toUpperCase()) {
      case 'WIN':
        return 'فوز';
      case 'W':
        return 'ف';
      case 'DRAW':
        return 'تعادل';
      case 'D':
        return 'ت';
      case 'LOSS':
        return 'خسارة';
      case 'L':
        return 'خ';
      default:
        return wdl;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  EVENTS TAB
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildEventsTab(BuildContext context) {
    final rawEvents = (_overview['events'] as List<dynamic>?) ?? [];
    final events = List.from(rawEvents);

    // Check match status for Full Time / Kick Off markers
    final status = widget.match['status']?.toString().toUpperCase() ?? '';
    final isFT =
        status == 'FT' ||
        status == 'AET' ||
        status == 'PEN' ||
        status == 'FINAL' ||
        status == 'FINISHED';

    final isLive =
        status == 'LIVE' || status == 'HT' || RegExp(r'^\d').hasMatch(status);
    final isStarted = isFT || isLive;

    // Sort latest first
    events.sort((a, b) {
      final ma = (a['raw_minute'] as num?)?.toDouble() ?? 0.0;
      final mb = (b['raw_minute'] as num?)?.toDouble() ?? 0.0;
      return mb.compareTo(ma);
    });

    if (events.isEmpty && !isStarted) {
      return _buildNoDataWidget(
        context: context,
        icon: Icons.timeline_outlined,
        message:
            AppLocalizations.of(
              context,
            )!.matchInfoNotAvailable, // Reusing key as message is similar
      );
    }

    return CustomScrollView(
      key: const PageStorageKey('events'),
      physics: const AlwaysScrollableScrollPhysics(
        parent: ClampingScrollPhysics(),
      ),
      slivers: [
        SliverOverlapInjector(
          handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 100.h),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section Label
                  Padding(
                    padding: EdgeInsets.only(bottom: 12.h),
                    child: _buildSectionTitle(
                      AppLocalizations.of(context)!.matchTimeline,
                    ),
                  ),
                  _buildTimelineKey(),
                  SizedBox(height: 12.h),
                  SizedBox(
                    width: double.infinity,
                    child: Stack(
                      alignment: Alignment.topCenter,
                      children: [
                        // Central line
                        Positioned(
                          top: 0,
                          bottom: 0,
                          child: Container(
                            width: 2.w,
                            color: Colors.grey.withValues(alpha: 0.2),
                          ),
                        ),
                        // Events Column
                        Column(
                          children: [
                            if (isFT)
                              _buildMatchStatusMarker(
                                AppLocalizations.of(context)!.endOfMatch,
                                Icons.timer_outlined,
                              ),
                            ...events
                                .map(
                                  (e) => _buildTimelineEvent(
                                    e as Map<String, dynamic>,
                                  ),
                                ),
                            _buildMatchStatusMarker(
                              AppLocalizations.of(context)!.kickOff,
                              Icons.timer_outlined,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildMatchStatusMarker(String label, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: EdgeInsets.symmetric(vertical: 24.h),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20.w),
        border: Border.all(
          color:
              isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16.w, color: GoalioColors.greenAccent),
          SizedBox(width: 8.w),
          Text(
            label,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontSize: 12.sp,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineEvent(Map<String, dynamic> event) {
    final team = event['team']?.toString() ?? 'home';
    final isHome = team == 'home';
    final type = event['type']?.toString() ?? 'event';
    final minute = event['minute']?.toString() ?? '';
    final player = event['player']?.toString() ?? '';
    final detail = event['detail']?.toString() ?? '';

    IconData icon;
    Color iconColor;

    switch (type) {
      case 'goal':
        icon = Icons.sports_soccer;
        iconColor = GoalioColors.greenAccent;
        break;
      case 'own_goal':
        icon = Icons.sports_soccer;
        iconColor = Colors.redAccent;
        break;
      case 'penalty_goal':
        icon = Icons.sports_soccer;
        iconColor = GoalioColors.greenAccent;
        break;
      case 'penalty_missed':
        icon = Icons.cancel_outlined;
        iconColor = Colors.redAccent;
        break;
      case 'yellow_card':
        icon = Icons.square;
        iconColor = Colors.amber;
        break;
      case 'red_card':
        icon = Icons.square;
        iconColor = Colors.redAccent;
        break;
      case 'yellow_red':
        icon = Icons.square;
        iconColor = Colors.amber;
        break;
      case 'substitution':
        icon = Icons.swap_horiz;
        iconColor = GoalioColors.blueAccent;
        break;
      case 'assist':
        icon = Icons.sports_football;
        iconColor = Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey;
        break;
      case 'injury':
        icon = Icons.add;
        iconColor = Colors.redAccent;
        break;
      case 'var':
        icon = Icons.tv;
        iconColor = Colors.blueGrey;
        break;
      default:
        icon = Icons.circle;
        iconColor = Colors.grey;
    }

    final isSecondYellow = type == 'yellow_red';
    final iconWidget =
        isSecondYellow
            ? SizedBox(
              width: 18.w,
              height: 14.w,
              child: Stack(
                children: [
                  Positioned(
                    left: 4.w,
                    child: Icon(
                      Icons.square,
                      color: Colors.redAccent,
                      size: 14.w,
                    ),
                  ),
                  Icon(Icons.square, color: Colors.amber, size: 14.w),
                ],
              ),
            )
            : Icon(icon, color: iconColor, size: 14.w);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // HOME SIDE
          Expanded(
            child:
                isHome
                    ? Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          player,
                          style: TextStyle(
                            color:
                                Theme.of(context).textTheme.bodyMedium?.color,
                            fontWeight: FontWeight.bold,
                            fontSize: 12.sp,
                          ),
                        ),
                        Text(
                          detail,
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodySmall?.color,
                            fontSize: 10.sp,
                          ),
                        ),
                      ],
                    )
                    : const SizedBox(),
          ),

          // MIDDLE (ICON ON THE LINE)
          Container(
            width: 80.w,
            alignment: Alignment.center,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16.w),
                border: Border.all(color: iconColor.withValues(alpha: 0.5)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  iconWidget,
                  SizedBox(width: 4.w),
                  Text(
                    minute.toArabicNumbers(context),
                    style: TextStyle(
                      color: iconColor,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // AWAY SIDE
          Expanded(
            child:
                !isHome
                    ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          player,
                          style: TextStyle(
                            color:
                                Theme.of(context).textTheme.bodyMedium?.color,
                            fontWeight: FontWeight.bold,
                            fontSize: 12.sp,
                          ),
                        ),
                        Text(
                          detail,
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodySmall?.color,
                            fontSize: 10.sp,
                          ),
                        ),
                      ],
                    )
                    : const SizedBox(),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineKey() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12.w),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          unselectedWidgetColor: Theme.of(context).textTheme.bodyLarge?.color,
          colorScheme: Theme.of(context).colorScheme.copyWith(
            primary: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        child: ExpansionTile(
          key: const PageStorageKey('timeline_key_expansion_tile'),
          title: Text(
            AppLocalizations.of(context)!.timelineKey,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          tilePadding: EdgeInsets.symmetric(horizontal: 16.w),
          childrenPadding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 8.h),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    children: [
                      _buildKeyItem(
                        Icons.sports_soccer,
                        Theme.of(context).textTheme.bodyMedium?.color ??
                            Colors.black,
                        AppLocalizations.of(context)!.goalLabel,
                      ),
                      _buildKeyItem(
                        Icons.sports_soccer,
                        Colors.redAccent,
                        AppLocalizations.of(context)!.ownGoal,
                      ),
                      _buildKeyItem(
                        Icons.sports_football,
                        Theme.of(context).textTheme.bodySmall?.color ??
                            Colors.black87,
                        AppLocalizations.of(context)!.assist,
                      ),
                      _buildKeyItem(
                        Icons.history,
                        Colors.amber,
                        AppLocalizations.of(context)!.secondYellow,
                        isSecondYellow: true,
                      ),
                      _buildKeyItem(
                        Icons.add,
                        Colors.redAccent,
                        AppLocalizations.of(context)!.injury,
                      ),
                      _buildKeyItem(
                        Icons.timer_outlined,
                        Theme.of(context).textTheme.bodyMedium?.color ??
                            Colors.black,
                        AppLocalizations.of(context)!.kickOff,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    children: [
                      _buildKeyItem(
                        Icons.sports_soccer,
                        GoalioColors.greenAccent,
                        AppLocalizations.of(context)!.penaltyGoal,
                      ),
                      _buildKeyItem(
                        Icons.cancel_outlined,
                        Colors.redAccent,
                        AppLocalizations.of(context)!.penaltyMissed,
                      ),
                      _buildKeyItem(
                        Icons.square,
                        Colors.amber,
                        AppLocalizations.of(context)!.yellowCard,
                      ),
                      _buildKeyItem(
                        Icons.square,
                        Colors.redAccent,
                        AppLocalizations.of(context)!.redCard,
                      ),
                      _buildKeyItem(
                        Icons.swap_horiz,
                        GoalioColors.blueAccent,
                        AppLocalizations.of(context)!.substitutionLabel,
                      ),
                      _buildKeyItem(
                        Icons.tv,
                        Colors.blueGrey,
                        'VAR',
                        isVar: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeyItem(
    IconData icon,
    Color color,
    String label, {
    bool isSecondYellow = false,
    bool isVar = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Row(
        children: [
          SizedBox(
            width: 24.w,
            child:
                isSecondYellow
                    ? Stack(
                      children: [
                        Icon(Icons.square, color: Colors.amber, size: 12.w),
                        Positioned(
                          right: 2.w,
                          bottom: 0,
                          child: Icon(
                            Icons.square,
                            color: Colors.redAccent,
                            size: 12.w,
                          ),
                        ),
                      ],
                    )
                    : isVar
                    ? Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 2.w,
                        vertical: 1.h,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: color, width: 1),
                        borderRadius: BorderRadius.circular(2.w),
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.varLabel,
                        style: TextStyle(
                          color: color,
                          fontSize: 6.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                    : Icon(icon, color: color, size: 18.w),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: Theme.of(
                  context,
                ).textTheme.bodyMedium?.color?.withValues(alpha: 0.9),
                fontSize: 12.sp,
                fontWeight: FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoStrip(Map<String, dynamic> info) {
    return Container(
      margin: EdgeInsets.only(bottom: 6.h),
      padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 16.w),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12.w),
      ),
      child: Row(
        children: [
          if (info['venue'] != null) ...[
            Icon(
              Icons.stadium_outlined,
              size: 14.w,
              color: GoalioColors.greenAccent,
            ),
            SizedBox(width: 6.w),
            Expanded(
              child: Text(
                ArabicNameExtension(
                  info['venue'].toString(),
                ).toArabicName(context),
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodySmall?.color,
                  fontSize: 11.sp,
                ),
              ),
            ),
          ],
          if (info['date'] != null)
            Text(
              formatHumanDetailedDate(
                info['date']?.toString(),
                Localizations.localeOf(context).languageCode,
              ),
              style: TextStyle(
                color: Theme.of(context).textTheme.bodySmall?.color,
                fontSize: 11.sp,
              ),
            ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  FORM SECTION
  // ─────────────────────────────────────────────────────────────────────────

  /// TV CHANNELS section: a labelled `Wrap` of pill-shaped chips, each chip
  /// pairs the channel logo (when available) with its name. `Wrap` lays the
  /// chips horizontally and flows to the next line when the row fills, so
  /// the grid is responsive across phone widths and orientations.
  List<Widget> _buildChannelsSection(BuildContext context, List<dynamic> channels) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chipBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);
    final textColor = Theme.of(context).textTheme.bodyMedium?.color;

    return [
      Padding(
        padding: EdgeInsets.only(top: 10.h, bottom: 12.h),
        child: _buildSectionTitle(AppLocalizations.of(context)!.tvChannelsLabel),
      ),
      Wrap(
        spacing: 8.w,
        runSpacing: 8.h,
        children: channels.map<Widget>((c) {
          final ch = c as Map<String, dynamic>;
          final name = (ch['name'] ?? '').toString();
          final logo = (ch['logo_url'] ?? '').toString();
          return Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: chipBg,
              borderRadius: BorderRadius.circular(20.w),
              border: Border.all(
                color: GoalioColors.greenAccent.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (logo.isNotEmpty) ...[
                  ClipOval(
                    child: Image.network(
                      logo,
                      width: 16.w,
                      height: 16.w,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.live_tv,
                        size: 14.w,
                        color: GoalioColors.greenAccent,
                      ),
                    ),
                  ),
                  SizedBox(width: 6.w),
                ] else ...[
                  Icon(Icons.live_tv, size: 14.w, color: GoalioColors.greenAccent),
                  SizedBox(width: 6.w),
                ],
                Text(
                  name,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
      SizedBox(height: 4.h),
    ];
  }

  List<Widget> _buildFormSection(
    BuildContext context,
    List<dynamic> homeForm,
    List<dynamic> awayForm,
    String homeTeam,
    String awayTeam,
  ) {
    return [
      Padding(
        padding: EdgeInsets.only(top: 10.h, bottom: 12.h),
        child: _buildSectionTitle(AppLocalizations.of(context)!.teamForm),
      ),
      // Home team form
      if (homeForm.isNotEmpty)
        ..._buildTeamFormList(context, homeTeam, homeForm),
      // Away team form
      if (awayForm.isNotEmpty)
        ..._buildTeamFormList(context, awayTeam, awayForm),
      SizedBox(height: 4.h),
    ];
  }

  /// Builds a labelled block of match rows for one team
  List<Widget> _buildTeamFormList(
    BuildContext context,
    String teamName,
    List<dynamic> form,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final headerBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);

    return [
      // Team header
      Container(
        margin: EdgeInsets.only(top: 6.h, bottom: 8.h),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: headerBg,
          borderRadius: BorderRadius.circular(12.w),
          border: Border.all(
            color: GoalioColors.greenAccent.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(6.w),
              decoration: BoxDecoration(
                color: GoalioColors.greenAccent.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.history,
                size: 14.w,
                color: GoalioColors.greenAccent,
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                ArabicNameExtension(teamName).toArabicName(context),
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            Text(
              AppLocalizations.of(context)!.last5Matches,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodySmall?.color,
                fontSize: 11.sp,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
      // Match rows
      Column(
        children:
            form.take(5).toList().asMap().entries.map((entry) {
              final e = entry.value as Map<String, dynamic>;
              final wdl = (e['wdl'] as String? ?? '').toUpperCase();
              final opp = e['opponent']?.toString() ?? '?';
              final sf = e['score_for'];
              final sa = e['score_against'];
              final date = e['date']?.toString() ?? '';

              final Color wdlColor =
                  wdl == 'WIN'
                      ? const Color(0xFF22C55E)
                      : wdl == 'DRAW'
                      ? const Color(0xFFF59E0B)
                      : const Color(0xFFEF4444);

              final scoreStr =
                  (sf != null && sa != null)
                      ? '${sf.toString()} - ${sa.toString()}'
                      : '-';

              String dateLabel = '';
              String timeLabel = '';
              try {
                if (date.isNotEmpty) {
                  final dt = DateTime.parse(date).toLocal();
                  final isAr =
                      Localizations.localeOf(context).languageCode == 'ar';

                  if (isAr) {
                    dateLabel =
                        '${dt.day.toString().padLeft(2, '0')} ${_getArabicMonth(dt.month)} ${dt.year}';
                  } else {
                    const months = [
                      'Jan',
                      'Feb',
                      'Mar',
                      'Apr',
                      'May',
                      'Jun',
                      'Jul',
                      'Aug',
                      'Sep',
                      'Oct',
                      'Nov',
                      'Dec',
                    ];
                    dateLabel =
                        '${dt.day.toString().padLeft(2, '0')} ${months[dt.month - 1]} ${dt.year}';
                  }

                  timeLabel =
                      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
                }
              } catch (_) {}

              return Container(
                margin: EdgeInsets.only(bottom: 10.h),
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12.w),
                  border: Border.all(
                    color: wdlColor.withValues(alpha: 0.3),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Top row: Date, Time, WDL badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 12.sp,
                              color: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.color
                                  ?.withValues(alpha: 0.8),
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              dateLabel.toArabicNumbers(context),
                              style: TextStyle(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.color
                                    ?.withValues(alpha: 0.8),
                              ),
                            ),
                            if (timeLabel.isNotEmpty) ...[
                              SizedBox(width: 10.w),
                              Icon(
                                Icons.access_time,
                                size: 12.sp,
                                color: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.color
                                    ?.withValues(alpha: 0.8),
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                timeLabel.toArabicNumbers(context),
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.color
                                      ?.withValues(alpha: 0.8),
                                ),
                              ),
                            ],
                          ],
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 2.h,
                          ),
                          decoration: BoxDecoration(
                            color: wdlColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6.w),
                            border: Border.all(
                              color: wdlColor.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            _localizeWDL(context, wdl),
                            style: TextStyle(
                              color: wdlColor,
                              fontSize: 9.sp,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12.h),
                    // Bottom row: Teams and Score
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            ArabicNameExtension(teamName).toArabicName(context),
                            textAlign: TextAlign.right,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color:
                                  Theme.of(context).textTheme.bodyMedium?.color,
                              fontWeight: FontWeight.bold,
                              fontSize: 13.sp,
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12.w),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 14.w,
                              vertical: 6.h,
                            ),
                            decoration: BoxDecoration(
                              color: wdlColor.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8.w),
                              border: Border.all(
                                color: wdlColor.withValues(alpha: 0.5),
                                width: 1.5,
                              ),
                            ),
                            child: Text(
                              scoreStr.toArabicNumbers(context),
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w900,
                                color: wdlColor,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            ArabicNameExtension(opp).toArabicName(context),
                            textAlign: TextAlign.left,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.color
                                  ?.withValues(alpha: 0.85),
                              fontWeight: FontWeight.w600,
                              fontSize: 13.sp,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
      ),
    ];
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        color: GoalioColors.greenAccent,
        fontSize: 11.sp,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildStatRow(Map<String, dynamic> stat) {
    final rawLabel = stat['label']?.toString() ?? '';
    final label = _localizeStatLabel(context, rawLabel);
    final home = stat['home_value']?.toString() ?? '-';
    final away = stat['away_value']?.toString() ?? '-';

    // Try to parse percentage for progress bar
    final homeNum = double.tryParse(home.replaceAll('%', ''));
    final awayNum = double.tryParse(away.replaceAll('%', ''));
    final total = (homeNum ?? 0) + (awayNum ?? 0);
    final hasBar = homeNum != null && awayNum != null && total > 0;
    final homeVal = homeNum ?? 0.0;
    final awayVal = awayNum ?? 0.0;

    final displayHome = home.toArabicNumbers(context);
    final displayAway = away.toArabicNumbers(context);

    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(10.w),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                displayHome,
                style: TextStyle(
                  color: GoalioColors.blueAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 13.sp,
                ),
              ),
              Expanded(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Text(
                displayAway,
                style: TextStyle(
                  color: GoalioColors.greenAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 13.sp,
                ),
              ),
            ],
          ),
          if (hasBar) ...[
            SizedBox(height: 6.h),
            ClipRRect(
              borderRadius: BorderRadius.circular(4.w),
              child: Row(
                children: [
                  Flexible(
                    flex: (homeVal * 100).round(),
                    child: Container(
                      height: 4.h,
                      color: GoalioColors.blueAccent,
                    ),
                  ),
                  Flexible(
                    flex: (awayVal * 100).round(),
                    child: Container(
                      height: 4.h,
                      color: GoalioColors.greenAccent,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  LINEUP TAB
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildLineupTab(BuildContext context) {
    final home = (_lineup['home'] as Map<String, dynamic>?) ?? {};
    final away = (_lineup['away'] as Map<String, dynamic>?) ?? {};

    final homeStarting = (home['starting'] as List<dynamic>?) ?? [];
    final awayStarting = (away['starting'] as List<dynamic>?) ?? [];
    final homeBench = (home['bench'] as List<dynamic>?) ?? [];
    final awayBench = (away['bench'] as List<dynamic>?) ?? [];

    if (homeStarting.isEmpty && awayStarting.isEmpty) {
      return _buildNoDataWidget(
        context: context,
        icon: Icons.people_outline,
        message: AppLocalizations.of(context)!.matchInfoNotAvailable, // Reusing
      );
    }

    final match = widget.match;

    return CustomScrollView(
      key: const PageStorageKey('lineup'),
      physics: const AlwaysScrollableScrollPhysics(
        parent: ClampingScrollPhysics(),
      ),
      slivers: [
        SliverOverlapInjector(
          handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 100.h),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Section Label
              Padding(
                padding: EdgeInsets.only(bottom: 16.h),
                child: _buildSectionTitle(
                  AppLocalizations.of(context)!.teamLineups,
                ),
              ),
              // Formations row
              if (home['formation'] != null || away['formation'] != null) ...[
                _buildFormationRow(
                  match['home_team'] ?? 'Home',
                  match['away_team'] ?? 'Away',
                  _formatFormation(home['formation']?.toString()),
                  _formatFormation(away['formation']?.toString()),
                ),
                SizedBox(height: 16.h),
              ],

              // Tactical Pitch Visualization
              _buildLineupPitch(homeStarting, awayStarting),
              SizedBox(height: 24.h),

              // Starting XI
              _buildSectionTitle(AppLocalizations.of(context)!.lineupsLabel),
              SizedBox(height: 8.h),
              _buildPlayerTable(homeStarting, awayStarting),

              if (homeBench.isNotEmpty || awayBench.isNotEmpty) ...[
                SizedBox(height: 20.h),
                _buildSectionTitle(AppLocalizations.of(context)!.benchLabel),
                SizedBox(height: 8.h),
                _buildPlayerTable(homeBench, awayBench),
              ],
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildFormationRow(
    String home,
    String away,
    String? homeFormation,
    String? awayFormation,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12.w),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                Text(
                  home,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: GoalioColors.blueAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 12.sp,
                  ),
                ),
                if (homeFormation != null) ...[
                  SizedBox(height: 4.h),
                  Text(
                    homeFormation.toArabicNumbers(context),
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20.w),
            ),
            child: Text(
              AppLocalizations.of(context)!.vs,
              style: TextStyle(
                color: Colors.grey,
                fontSize: 10.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  away,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: GoalioColors.greenAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 11.sp,
                  ),
                ),
                if (awayFormation != null) ...[
                  SizedBox(height: 4.h),
                  Text(
                    awayFormation.toArabicNumbers(context),
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatFormation(String? formation) {
    if (formation == null || formation.isEmpty) return '';
    // If it's like 442, change to 4-4-2. Special cases for 4231 etc.
    if (!formation.contains('-') && RegExp(r'^\d+$').hasMatch(formation)) {
      if (formation.length > 3) {
        // Handle 4231 -> 4-2-3-1
        return formation.split('').join('-');
      }
      return formation.split('').join('-');
    }
    return formation;
  }

  Widget _buildPlayerTable(
    List<dynamic> homePlayers,
    List<dynamic> awayPlayers,
  ) {
    final maxLen =
        homePlayers.length > awayPlayers.length
            ? homePlayers.length
            : awayPlayers.length;

    return Column(
      children: List.generate(maxLen, (i) {
        final home =
            i < homePlayers.length
                ? homePlayers[i] as Map<String, dynamic>
                : null;
        final away =
            i < awayPlayers.length
                ? awayPlayers[i] as Map<String, dynamic>
                : null;

        return Container(
          padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 12.w),
          decoration: BoxDecoration(
            color:
                i % 2 == 0
                    ? Theme.of(context).cardColor
                    : Theme.of(context).cardColor.withValues(alpha: 0.6),
            borderRadius:
                i == 0
                    ? BorderRadius.vertical(top: Radius.circular(10.w))
                    : i == maxLen - 1
                    ? BorderRadius.vertical(bottom: Radius.circular(10.w))
                    : BorderRadius.zero,
          ),
          child: Row(
            children: [
              // Home player
              Expanded(child: _buildPlayerCell(home, align: TextAlign.left)),
              // Divider
              Container(
                width: 1,
                height: 32.h,
                color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
              ),
              // Away player
              Expanded(child: _buildPlayerCell(away, align: TextAlign.right)),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildPlayerCell(
    Map<String, dynamic>? player, {
    TextAlign align = TextAlign.left,
  }) {
    if (player == null) return const SizedBox.shrink();

    final name = player['name']?.toString() ?? '';
    final number = player['number']?.toString();
    final position = player['position']?.toString();

    final isRight = align == TextAlign.right;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8.w),
      child: Row(
        mainAxisAlignment:
            isRight ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isRight && number != null) ...[
            _buildJerseyBadge(number),
            SizedBox(width: 8.w),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Text(
                  ArabicNameExtension(name).toArabicName(context),
                  textAlign: align,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                    fontWeight: FontWeight.w600,
                    fontSize: 12.sp,
                  ),
                ),
                if (position != null && position.isNotEmpty)
                  Text(
                    position,
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodySmall?.color,
                      fontSize: 10.sp,
                    ),
                  ),
              ],
            ),
          ),
          if (isRight && number != null) ...[
            SizedBox(width: 8.w),
            _buildJerseyBadge(number),
          ],
        ],
      ),
    );
  }

  Widget _buildLineupPitch(List<dynamic> home, List<dynamic> away) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Safe fallbacks for infinite constraints
        final pitchWidth =
            constraints.hasBoundedWidth
                ? constraints.maxWidth
                : MediaQuery.of(context).size.width - 32.w;
        final pitchHeight = 320.h;

        return Container(
          width: pitchWidth,
          height: pitchHeight,
          decoration: BoxDecoration(
            color: const Color(0xFF2E7939),
            borderRadius: BorderRadius.circular(16.w),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16.w),
            child: Stack(
              children: [
                // Pitch background
                Positioned.fill(child: _buildPitchBackground()),

                // Home Team Players
                ...home.map(
                  (p) => _buildPitchPlayer(
                    p as Map<String, dynamic>,
                    isHome: true,
                    width: pitchWidth,
                    height: pitchHeight,
                  ),
                ),

                // Away Team Players
                ...away.map(
                  (p) => _buildPitchPlayer(
                    p as Map<String, dynamic>,
                    isHome: false,
                    width: pitchWidth,
                    height: pitchHeight,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPitchBackground() {
    return CustomPaint(painter: PitchPainter());
  }

  Widget _buildPitchPlayer(
    Map<String, dynamic> p, {
    required bool isHome,
    required double width,
    required double height,
  }) {
    // Goal.com coordinates: x=0-100 (GK at 50), y=0-100 (GK at 12, FW at 90)
    final xPercentRaw = (p['pitch_x'] as num?)?.toDouble() ?? 50.0;
    final yPercentRaw = (p['pitch_y'] as num?)?.toDouble() ?? 50.0;

    // Clamp to avoid outliers
    final xPercent = xPercentRaw.clamp(0.0, 100.0);
    final yPercent = yPercentRaw.clamp(0.0, 100.0);

    final number = p['number']?.toString() ?? '';
    final name = p['name']?.toString() ?? '';
    final isCaptain = p['is_captain'] == true;

    // Relative relative positions (0.0 to 1.0)
    double relX;
    if (isHome) {
      // Home GK is on left (y=12), map to 0.02 - 0.48
      relX = 0.02 + (yPercent / 100.0) * 0.46;
    } else {
      // Away GK is on right (y=12), map to 0.98 - 0.52
      relX = 0.98 - (yPercent / 100.0) * 0.46;
    }

    // Map x (width on vertical pitch) to y (height on horizontal pitch)
    double relY = 0.05 + (xPercent / 100.0) * 0.9;

    return Positioned(
      left: relX * width,
      top: relY * height,
      child: FractionalTranslation(
        translation: const Offset(-0.5, -0.5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 24.w,
                  height: 24.w,
                  decoration: BoxDecoration(
                    color: isHome ? Colors.white : Colors.black,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isHome ? Colors.black45 : Colors.white38,
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      number.toArabicNumbers(context),
                      style: TextStyle(
                        color: isHome ? Colors.black : Colors.white,
                        fontSize: 9.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                if (isCaptain)
                  Positioned(
                    right: -3.w,
                    top: -3.w,
                    child: Container(
                      padding: EdgeInsets.all(1.5.w),
                      decoration: const BoxDecoration(
                        color: GoalioColors.greenAccent,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        'C',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 6.sp,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 2.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(3.w),
              ),
              child: Text(
                ArabicNameExtension(
                  name.contains(' ') ? name.split(' ').last : name,
                ).toArabicName(context),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 7.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJerseyBadge(String number) {
    return Container(
      width: 24.w,
      height: 24.w,
      decoration: BoxDecoration(
        color: GoalioColors.greenAccent.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6.w),
        border: Border.all(color: GoalioColors.greenAccent.withValues(alpha: 0.4)),
      ),
      child: Center(
        child: Text(
          number.toArabicNumbers(context),
          style: TextStyle(
            color: GoalioColors.greenAccent,
            fontSize: 10.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  FANTASY HUB TAB
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildFantasyHubTab(BuildContext context) {
    final home = (_lineup['home'] as Map<String, dynamic>?) ?? {};
    final away = (_lineup['away'] as Map<String, dynamic>?) ?? {};
    final homeStarting = (home['starting'] as List<dynamic>?) ?? [];
    final awayStarting = (away['starting'] as List<dynamic>?) ?? [];

    if (homeStarting.isEmpty && awayStarting.isEmpty) {
      return _buildNoDataWidget(
        context: context,
        icon: Icons.emoji_events_outlined,
        message: AppLocalizations.of(context)!.matchInfoNotAvailable,
      );
    }

    return FantasyHubTab(
      matchId: (widget.match['id'] as num).toInt(),
      match: widget.match,
    );
  }

  Widget _buildNoDataWidget({
    required BuildContext context,
    required IconData icon,
    required String message,
  }) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: ClampingScrollPhysics(),
      ),
      slivers: [
        SliverOverlapInjector(
          handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
        ),
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(32.w),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 64.w,
                    color: GoalioColors.greenAccent.withValues(alpha: 0.3),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodySmall?.color,
                      fontSize: 14.sp,
                      height: 1.5,
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

// ─────────────────────────────────────────────────────────────────────────────
//  PITCH PAINTER
// ─────────────────────────────────────────────────────────────────────────────

class PitchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.white.withValues(alpha: 0.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;

    // Grass Stripes
    final stripePaint = Paint()..style = PaintingStyle.fill;
    const stripeCount = 10;
    final stripeWidth = size.width / stripeCount;
    for (int i = 0; i < stripeCount; i++) {
      stripePaint.color =
          i % 2 == 0 ? Colors.white.withValues(alpha: 0.05) : Colors.transparent;
      canvas.drawRect(
        Rect.fromLTWH(i * stripeWidth, 0, stripeWidth, size.height),
        stripePaint,
      );
    }

    // Outer Boundary
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // Halfway Line
    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height),
      paint,
    );

    // Center Circle
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), 35.h, paint);
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      2.h,
      paint..style = PaintingStyle.fill,
    );

    final boxWidth = size.width * 0.165;
    final boxHeight = size.height * 0.58;
    final smallBoxWidth = size.width * 0.058;
    final smallBoxHeight = size.height * 0.26;

    // Goal Boxes (Left)
    canvas.drawRect(
      Rect.fromLTWH(0, (size.height - boxHeight) / 2, boxWidth, boxHeight),
      paint..style = PaintingStyle.stroke,
    );
    canvas.drawRect(
      Rect.fromLTWH(
        0,
        (size.height - smallBoxHeight) / 2,
        smallBoxWidth,
        smallBoxHeight,
      ),
      paint,
    );
    // Penalty Arc (Left)
    canvas.drawArc(
      Rect.fromLTWH(boxWidth - 16.w, (size.height - 52.h) / 2, 32.w, 52.h),
      -1.57,
      3.14,
      false,
      paint,
    );

    // Goal Boxes (Right)
    canvas.drawRect(
      Rect.fromLTWH(
        size.width - boxWidth,
        (size.height - boxHeight) / 2,
        boxWidth,
        boxHeight,
      ),
      paint,
    );
    canvas.drawRect(
      Rect.fromLTWH(
        size.width - smallBoxWidth,
        (size.height - smallBoxHeight) / 2,
        smallBoxWidth,
        smallBoxHeight,
      ),
      paint,
    );
    // Penalty Arc (Right)
    canvas.drawArc(
      Rect.fromLTWH(
        size.width - boxWidth - 16.w,
        (size.height - 52.h) / 2,
        32.w,
        52.h,
      ),
      1.57,
      3.14,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
