import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../core/constants/constants.dart';
import '../../core/services/api_service.dart';
import '../../core/utils/size_config.dart';
import '../../core/utils/name_translator.dart';
import '../../core/utils/number_utils.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  FANTASY HUB TAB  —  Premier League only, data served by the backend
// ─────────────────────────────────────────────────────────────────────────────

class FantasyHubTab extends StatefulWidget {
  final int matchId;
  final Map<String, dynamic> match;

  const FantasyHubTab({super.key, required this.matchId, required this.match});

  @override
  State<FantasyHubTab> createState() => _FantasyHubTabState();
}

class _FantasyHubTabState extends State<FantasyHubTab>
    with SingleTickerProviderStateMixin {
  // ── State ──────────────────────────────────────────────────────────────────
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic> _data = {};

  int _selectedTeam = 0; // 0=All, 1=Home, 2=Away
  bool _showBench = false;

  late AnimationController _shimmerCtrl;

  // ── Palette ────────────────────────────────────────────────────────────────
  static const Color _gold = Color(0xFFFFD700);
  static const Color _goldDark = Color(0xFFB8860B);
  static const Color _purple = Color(0xFF6366F1); // Indigo-ish for premium feel
  static const Color _purpleLight = Color(0xFF818CF8);
  static const Color _green = Color(0xFF10B981); // Emerald
  static const Color _darkBg = Color(0xFF0F172A);
  static const Color _card = Color(0xFF1E293B);
  static const Color _cardBorder = Color(0xFF334155);

  // Position colors (Premium shades)
  static const Color _gkColor = Color(0xFFF59E0B); // Amber
  static const Color _defColor = Color(0xFF3B82F6); // Blue
  static const Color _midColor = Color(0xFF10B981); // Emerald
  static const Color _fwdColor = Color(0xFFEF4444); // Red

  @override
  void initState() {
    super.initState();
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
    _fetchFantasyData();
  }

  @override
  void dispose() {
    _shimmerCtrl.dispose();
    super.dispose();
  }

  // ── Data fetching ──────────────────────────────────────────────────────────

  Future<void> _fetchFantasyData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final uri = Uri.parse(
        '${ApiConstants.authBaseUrl}/fantasy/match/${widget.matchId}',
      );
      final response = await http
          .get(uri, headers: await ApiService.reqHeaders)
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final decoded =
            json.decode(utf8.decode(response.bodyBytes))
                as Map<String, dynamic>;
        setState(() {
          _data = decoded;
          _isLoading = false;
        });
        return;
      }
      setState(() {
        _error = 'Failed to load Fantasy data (${response.statusCode})';
        _isLoading = false;
      });
    } catch (_) {
      setState(() {
        _error = 'Could not connect to server.';
        _isLoading = false;
      });
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  bool get _isFinished => _data['is_finished'] == true;
  bool get _isLive => _data['is_live'] == true;

  Map<String, dynamic> get _summary =>
      (_data['summary'] as Map<String, dynamic>?) ?? {};

  Color _posColor(String group) {
    switch (group) {
      case 'GK':
        return _gkColor;
      case 'DEF':
        return _defColor;
      case 'MID':
        return _midColor;
      case 'FWD':
        return _fwdColor;
      default:
        return Colors.grey;
    }
  }

  List<_FantasyPlayer> _parseSide(String side) {
    final sideData = (_data[side] as Map<String, dynamic>?) ?? {};
    final isHome = side == 'home';
    final result = <_FantasyPlayer>[];
    for (final group in ['starting', 'bench']) {
      for (final raw in (sideData[group] as List<dynamic>?) ?? []) {
        final p = raw as Map<String, dynamic>;
        final name = p['name']?.toString() ?? '';
        if (name.isEmpty) continue;
        result.add(
          _FantasyPlayer(
            name: name,
            position: p['position']?.toString() ?? '',
            positionGroup: p['position_group']?.toString() ?? 'UNK',
            number: p['number']?.toString() ?? '',
            isHome: isHome,
            isStarting: group == 'starting',
            isCaptain: p['is_captain'] == true,
            suggestedPoints: (p['suggested_points'] as num?)?.toInt() ?? 5,
            actualPoints:
                p['actual_points'] != null
                    ? (p['actual_points'] as num).toInt()
                    : null,
            events: List<String>.from(p['events'] ?? []),
          ),
        );
      }
    }
    return result;
  }

  List<_FantasyPlayer> get _allPlayers => [
    ..._parseSide('home'),
    ..._parseSide('away'),
  ];

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return _buildLoading();
    if (_error != null) return _buildError();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final homeName =
        _data['home_team']?.toString() ??
        widget.match['home_team']?.toString() ??
        'Home';
    final awayName =
        _data['away_team']?.toString() ??
        widget.match['away_team']?.toString() ??
        'Away';
    final homeForm = (_data['home'] as Map?) ?? {};
    final awayForm = (_data['away'] as Map?) ?? {};
    final homeFormation = homeForm['formation']?.toString() ?? '';
    final awayFormation = awayForm['formation']?.toString() ?? '';

    // All players list
    final all = _allPlayers;

    // Apply team filter
    List<_FantasyPlayer> filtered;
    if (_selectedTeam == 1) {
      filtered = all.where((p) => p.isHome).toList();
    } else if (_selectedTeam == 2) {
      filtered = all.where((p) => !p.isHome).toList();
    } else {
      filtered = all;
    }

    // Starters / bench split
    final starters = filtered.where((p) => p.isStarting).toList();
    final bench = filtered.where((p) => !p.isStarting).toList();

    // Sort by actual (if available) else suggested
    int Function(_FantasyPlayer, _FantasyPlayer) sorter;
    if (_isFinished || _isLive) {
      sorter = (a, b) => (b.actualPoints ?? 0).compareTo(a.actualPoints ?? 0);
    } else {
      sorter = (a, b) => b.suggestedPoints.compareTo(a.suggestedPoints);
    }
    starters.sort(sorter);
    bench.sort(sorter);

    return CustomScrollView(
      key: const PageStorageKey('fantasy_hub'),
      physics: const AlwaysScrollableScrollPhysics(
        parent: ClampingScrollPhysics(),
      ),
      slivers: [
        SliverOverlapInjector(
          handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
        ),

        // ── Top section ──────────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(14.w, 16.h, 14.w, 0),
            child: Column(
              children: [
                _buildHeroBanner(
                  context,
                  homeName,
                  awayName,
                  homeFormation,
                  awayFormation,
                  isDark,
                ),
                SizedBox(height: 16.h),
                _buildStatusRow(context),
                if ((_isFinished || _isLive) && _summary.isNotEmpty) ...[
                  SizedBox(height: 16.h),
                  _buildScoreboard(context, homeName, awayName, isDark),
                ],
                SizedBox(height: 16.h),
                _buildSegmentedControl(context, homeName, awayName, isDark),
                SizedBox(height: 20.h),
              ],
            ),
          ),
        ),

        // ── Starters Grouped by Position ─────────────────────────────────────
        if (starters.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: _sectionHeader(
              context,
              'STARTING XI',
              Icons.sports_soccer_rounded,
              starters.length,
            ),
          ),
          ..._groupStartersByPosition(context, starters, isDark),
        ],

        // ── Bench toggle ──────────────────────────────────────────────────────
        if (bench.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: GestureDetector(
              onTap: () => setState(() => _showBench = !_showBench),
              child: _sectionHeader(
                context,
                'BENCH',
                Icons.chair_alt_rounded,
                bench.length,
                trailing: Icon(
                  _showBench
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: _purpleLight,
                  size: 18.w,
                ),
              ),
            ),
          ),
          if (_showBench)
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: 14.w),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => _buildPlayerCard(
                    context,
                    bench[i],
                    isDark,
                    isBench: true,
                  ),
                  childCount: bench.length,
                ),
              ),
            ),
        ],

        SliverToBoxAdapter(child: SizedBox(height: 100.h)),
      ],
    );
  }

  // ── Helper: Group Starters by Position ───────────────────────────────────────

  List<Widget> _groupStartersByPosition(
    BuildContext context,
    List<_FantasyPlayer> players,
    bool isDark,
  ) {
    const order = ['GK', 'DEF', 'MID', 'FWD'];
    final widgets = <Widget>[];

    for (final pos in order) {
      final inPos = players.where((p) => p.positionGroup == pos).toList();
      if (inPos.isEmpty) continue;

      widgets.add(
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 8.h),
            child: Row(
              children: [
                _posTag(pos),
                SizedBox(width: 8.w),
                Expanded(
                  child: Divider(
                    color: _posColor(pos).withOpacity(0.15),
                    thickness: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      widgets.add(
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: 14.w),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, i) => _buildPlayerCard(context, inPos[i], isDark),
              childCount: inPos.length,
            ),
          ),
        ),
      );
    }
    return widgets;
  }

  Widget _posTag(String pos) {
    String label = pos;
    IconData icon = Icons.person;
    switch (pos) {
      case 'GK':
        label = 'GOALKEEPERS';
        icon = Icons.pan_tool_rounded;
        break;
      case 'DEF':
        label = 'DEFENDERS';
        icon = Icons.security_rounded;
        break;
      case 'MID':
        label = 'MIDFIELDERS';
        icon = Icons.insights_rounded;
        break;
      case 'FWD':
        label = 'FORWARDS';
        icon = Icons.flash_on_rounded;
        break;
    }

    final color = _posColor(pos);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6.w),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10.w, color: color),
          SizedBox(width: 4.w),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 9.sp,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroBanner(
    BuildContext context,
    String homeName,
    String awayName,
    String homeFormation,
    String awayFormation,
    bool isDark,
  ) {
    return AnimatedBuilder(
      animation: _shimmerCtrl,
      builder: (_, __) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _purple.withOpacity(0.8),
                const Color(0xFF1E1B4B),
                _purple.withOpacity(0.8),
              ],
              stops: const [0, 0.5, 1],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24.w),
            border: Border.all(color: Colors.white.withOpacity(0.15), width: 1),
            boxShadow: [
              BoxShadow(
                color: _purple.withOpacity(0.3),
                blurRadius: 32,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24.w),
            child: Stack(
              children: [
                // Mesh circles
                Positioned(
                  top: -50,
                  right: -50,
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _purpleLight.withOpacity(0.1),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -30,
                  left: -20,
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _green.withOpacity(0.05),
                    ),
                  ),
                ),

                // Shimmer overlay
                Positioned.fill(
                  child: ShaderMask(
                    shaderCallback:
                        (bounds) => LinearGradient(
                          colors: [
                            Colors.transparent,
                            Colors.white.withOpacity(0.08),
                            Colors.transparent,
                          ],
                          stops: [
                            math.max(0.0, _shimmerCtrl.value - 0.2),
                            _shimmerCtrl.value,
                            math.min(1.0, _shimmerCtrl.value + 0.2),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ).createShader(bounds),
                    child: Container(color: Colors.white),
                  ),
                ),

                Padding(
                  padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 18.h),
                  child: Column(
                    children: [
                      // Badge + Title
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 10.w,
                              vertical: 4.h,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8.w),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                              ),
                            ),
                            child: Text(
                              'PL',
                              style: TextStyle(
                                color: _green,
                                fontSize: 10.sp,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Text(
                            'FANTASY HUB',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 4.0,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withOpacity(0.5),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 24.h),

                      // VS Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  ArabicNameExtension(
                                    homeName,
                                  ).toArabicName(context),
                                  textAlign: TextAlign.end,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                if (homeFormation.isNotEmpty)
                                  Text(
                                    homeFormation,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.6),
                                      fontSize: 10.sp,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.w),
                            child: Container(
                              width: 32.w,
                              height: 32.w,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.1),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.2),
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  'VS',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  ArabicNameExtension(
                                    awayName,
                                  ).toArabicName(context),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                if (awayFormation.isNotEmpty)
                                  Text(
                                    awayFormation,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.6),
                                      fontSize: 10.sp,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                              ],
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
        );
      },
    );
  }

  // ── Status row ─────────────────────────────────────────────────────────────

  Widget _buildStatusRow(BuildContext context) {
    final Color statusColor;
    final String statusLabel;
    final String statusSub;
    final bool isLive;

    if (_isFinished) {
      statusColor = const Color(0xFF22C55E);
      statusLabel = 'ACTUAL POINTS';
      statusSub = 'Goals · Assists · Clean Sheets · Cards';
      isLive = false;
    } else if (_isLive) {
      statusColor = Colors.redAccent;
      statusLabel = 'LIVE FANTASY';
      statusSub = 'Updating as match progresses';
      isLive = true;
    } else {
      statusColor = _purpleLight;
      statusLabel = 'PROJECTED POINTS';
      statusSub = 'Pre-match position-based estimate';
      isLive = false;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16.w),
        border: Border.all(color: statusColor.withOpacity(0.2), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child:
                isLive
                    ? _LiveDot(color: statusColor)
                    : Icon(
                      Icons.info_outline_rounded,
                      size: 14.w,
                      color: statusColor,
                    ),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusLabel,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  statusSub,
                  style: TextStyle(
                    color: statusColor.withOpacity(0.7),
                    fontSize: 9.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Scoreboard ─────────────────────────────────────────────────────────────

  Widget _buildScoreboard(
    BuildContext context,
    String homeName,
    String awayName,
    bool isDark,
  ) {
    final homePts = (_summary['home_total_points'] as num?)?.toInt() ?? 0;
    final awayPts = (_summary['away_total_points'] as num?)?.toInt() ?? 0;
    final maxPts = homePts > awayPts ? homePts : awayPts;
    final scorer = _summary['top_scorer'] as Map<String, dynamic>?;
    final assister = _summary['top_assister'] as Map<String, dynamic>?;
    final homeRatio = maxPts > 0 ? homePts / maxPts : 0.0;
    final awayRatio = maxPts > 0 ? awayPts / maxPts : 0.0;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? _card : Colors.white,
        borderRadius: BorderRadius.circular(24.w),
        border: Border.all(
          color: isDark ? _cardBorder : Colors.grey.withOpacity(0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.35 : 0.08),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header bar
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: _purple.withOpacity(0.12),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20.w)),
              border: Border(
                bottom: BorderSide(
                  color: _purpleLight.withOpacity(0.1),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.query_stats_rounded,
                  size: 16.w,
                  color: _purpleLight,
                ),
                SizedBox(width: 8.w),
                Text(
                  'MATCH PERFORMANCE',
                  style: TextStyle(
                    color: _purpleLight,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),

          // Points bars
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
            child: Column(
              children: [
                _teamBar(
                  context,
                  homeName,
                  homePts,
                  homeRatio,
                  _defColor,
                  isHome: true,
                ),
                SizedBox(height: 12.h),
                _teamBar(
                  context,
                  awayName,
                  awayPts,
                  awayRatio,
                  _midColor,
                  isHome: false,
                ),
              ],
            ),
          ),

          // Top performers
          if (scorer != null || assister != null) ...[
            Divider(
              height: 1,
              color: isDark ? _cardBorder : Colors.grey.withOpacity(0.1),
            ),
            Padding(
              padding: EdgeInsets.all(12.w),
              child: Row(
                children: [
                  if (scorer != null)
                    Expanded(
                      child: _perfChip(
                        context,
                        emoji: '⚽',
                        label: 'Top Scorer',
                        name: scorer['name']?.toString() ?? '',
                        pts: (scorer['actual_points'] as num?)?.toInt() ?? 0,
                        color: const Color(0xFF22C55E),
                      ),
                    ),
                  if (scorer != null && assister != null) SizedBox(width: 8.w),
                  if (assister != null)
                    Expanded(
                      child: _perfChip(
                        context,
                        emoji: '🅰️',
                        label: 'Top Assist',
                        name: assister['name']?.toString() ?? '',
                        pts: (assister['actual_points'] as num?)?.toInt() ?? 0,
                        color: _defColor,
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

  Widget _teamBar(
    BuildContext context,
    String name,
    int pts,
    double ratio,
    Color color, {
    required bool isHome,
  }) {
    return Row(
      children: [
        Container(
          width: 8.w,
          height: 8.w,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: color.withOpacity(0.3), blurRadius: 6),
            ],
          ),
        ),
        SizedBox(width: 10.w),
        SizedBox(
          width: 85.w,
          child: Text(
            ArabicNameExtension(name).toArabicName(context),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).textTheme.bodyMedium?.color,
              fontFamily: 'RobotoCondensed',
            ),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Stack(
            children: [
              Container(
                height: 8.h,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10.w),
                ),
              ),
              FractionallySizedBox(
                widthFactor: ratio.clamp(0.05, 1.0),
                child: Container(
                  height: 8.h,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color.withOpacity(0.6), color],
                    ),
                    borderRadius: BorderRadius.circular(10.w),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: 12.w),
        SizedBox(
          width: 36.w,
          child: Text(
            pts.toString().toArabicNumbers(context),
            textAlign: TextAlign.end,
            style: TextStyle(
              color: _gold,
              fontWeight: FontWeight.w900,
              fontSize: 16.sp,
            ),
          ),
        ),
      ],
    );
  }

  Widget _perfChip(
    BuildContext context, {
    required String emoji,
    required String label,
    required String name,
    required int pts,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(10.w),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Row(
        children: [
          Text(emoji, style: TextStyle(fontSize: 14.sp)),
          SizedBox(width: 7.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    color: color,
                    fontSize: 8.sp,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  ArabicNameExtension(name).toArabicName(context),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'RobotoCondensed',
                  ),
                ),
              ],
            ),
          ),
          Text(
            pts.toString().toArabicNumbers(context),
            style: TextStyle(
              color: _gold,
              fontSize: 14.sp,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  // ── Segmented control ──────────────────────────────────────────────────────

  Widget _buildSegmentedControl(
    BuildContext context,
    String homeName,
    String awayName,
    bool isDark,
  ) {
    String clip(String s) {
      final t = ArabicNameExtension(s).toArabicName(context);
      return t.length > 7 ? '${t.substring(0, 7)}…' : t;
    }

    final bg =
        isDark
            ? Colors.white.withOpacity(0.05)
            : Colors.black.withOpacity(0.04);

    return Container(
      height: 44.h,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14.w),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          _segTab(context, 'All', 0),
          _segTab(context, clip(homeName), 1, dotColor: _defColor),
          _segTab(context, clip(awayName), 2, dotColor: _midColor),
        ],
      ),
    );
  }

  Widget _segTab(
    BuildContext context,
    String label,
    int index, {
    Color? dotColor,
  }) {
    final selected = _selectedTeam == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTeam = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: EdgeInsets.all(3.w),
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
          decoration: BoxDecoration(
            gradient:
                selected
                    ? const LinearGradient(
                      colors: [Color(0xFF6D28D9), _purple],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                    : null,
            borderRadius: BorderRadius.circular(9.w),
            boxShadow:
                selected
                    ? [
                      BoxShadow(
                        color: _purple.withOpacity(0.35),
                        blurRadius: 8,
                      ),
                    ]
                    : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (dotColor != null && !selected) ...[
                Container(
                  width: 6.w,
                  height: 6.w,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 4.w),
              ],
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color:
                      selected
                          ? Colors.white
                          : Theme.of(context).textTheme.bodySmall?.color,
                  fontSize: 10.sp,
                  fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Section header ─────────────────────────────────────────────────────────

  Widget _sectionHeader(
    BuildContext context,
    String title,
    IconData icon,
    int count, {
    Widget? trailing,
  }) {
    return Padding(
      padding: EdgeInsets.fromLTRB(14.w, 6.h, 14.w, 8.h),
      child: Row(
        children: [
          Icon(icon, size: 13.w, color: _purpleLight),
          SizedBox(width: 6.w),
          Text(
            title,
            style: TextStyle(
              color: _purpleLight,
              fontSize: 10.sp,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
          SizedBox(width: 6.w),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.h),
            decoration: BoxDecoration(
              color: _purple.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6.w),
            ),
            child: Text(
              count.toString(),
              style: TextStyle(
                color: _purpleLight,
                fontSize: 9.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Spacer(),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  // ── Player card ────────────────────────────────────────────────────────────

  Widget _buildPlayerCard(
    BuildContext context,
    _FantasyPlayer player,
    bool isDark, {
    bool isBench = false,
  }) {
    final posColor = _posColor(player.positionGroup);
    final showActual = (_isFinished || _isLive) && player.actualPoints != null;
    final actualPts = player.actualPoints ?? 0;
    final diff = actualPts - player.suggestedPoints;
    final teamColor = player.isHome ? _defColor : _midColor;

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color:
            isDark ? (isBench ? _card.withOpacity(0.5) : _card) : Colors.white,
        borderRadius: BorderRadius.circular(20.w),
        border: Border.all(
          color:
              showActual && actualPts >= 10
                  ? _gold.withOpacity(0.3)
                  : isDark
                  ? _cardBorder
                  : Colors.grey.withOpacity(0.1),
          width: showActual && actualPts >= 10 ? 1.5 : 1,
        ),
        boxShadow: [
          if (showActual && actualPts >= 10)
            BoxShadow(
              color: _gold.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Corner indicator for Home/Away
          Positioned(
            top: 0,
            left: 0,
            child: Container(
              width: 24.w,
              height: 24.w,
              decoration: BoxDecoration(
                color: teamColor.withOpacity(0.1),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(18.w),
                  bottomRight: Radius.circular(12.w),
                ),
              ),
              child: Center(
                child: Container(
                  width: 5.w,
                  height: 5.w,
                  decoration: BoxDecoration(
                    color: teamColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: teamColor.withOpacity(0.4),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Position Icon & Number ──────────────────────────────────
                Container(
                  width: 52.w,
                  decoration: BoxDecoration(
                    color: posColor.withOpacity(0.04),
                    borderRadius: BorderRadius.horizontal(
                      left: Radius.circular(18.w),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        player.number.isEmpty
                            ? '–'
                            : player.number.toArabicNumbers(context),
                        style: TextStyle(
                          color: isBench ? posColor.withOpacity(0.5) : posColor,
                          fontSize: 15.sp,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'RobotoCondensed',
                        ),
                      ),
                      Text(
                        player.position,
                        style: TextStyle(
                          color: posColor.withOpacity(0.6),
                          fontSize: 8.sp,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Main content ───────────────────────────────────────────
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(12.w, 14.h, 4.w, 14.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                ArabicNameExtension(
                                  player.name,
                                ).toArabicName(context),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color:
                                      isBench
                                          ? Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.color
                                              ?.withOpacity(0.6)
                                          : Theme.of(
                                            context,
                                          ).textTheme.bodyMedium?.color,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13.sp,
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ),
                            if (player.isCaptain) ...[
                              SizedBox(width: 8.w),
                              _captainBadge(),
                            ],
                          ],
                        ),
                        SizedBox(height: 6.h),
                        Wrap(
                          spacing: 4.w,
                          runSpacing: 4.h,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            _posBadge(player.positionGroup, posColor),
                            _teamDot(teamColor, player.isHome),
                            ...player.events.take(5).map(_eventChip),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Points chip ────────────────────────────────────────────
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 8.h,
                  ),
                  child: _pointsColumn(
                    context,
                    player: player,
                    showActual: showActual,
                    actualPts: actualPts,
                    diff: diff,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _captainBadge() {
    return Container(
      width: 16.w,
      height: 16.w,
      decoration: BoxDecoration(color: _gold, shape: BoxShape.circle),
      child: Center(
        child: Text(
          'C',
          style: TextStyle(
            color: Colors.black,
            fontSize: 8.sp,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  Widget _posBadge(String group, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(5.w),
      ),
      child: Text(
        group == 'UNK' ? '?' : group,
        style: TextStyle(
          color: color,
          fontSize: 8.sp,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _teamDot(Color color, bool isHome) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 5.w,
          height: 5.w,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        SizedBox(width: 3.w),
        Text(
          isHome ? 'HM' : 'AW',
          style: TextStyle(
            color: color,
            fontSize: 8.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _eventChip(String type) {
    String label;
    Color color;
    switch (type) {
      case 'goal':
      case 'penalty_goal':
        label = '⚽';
        color = const Color(0xFF22C55E);
        break;
      case 'own_goal':
        label = '⚽';
        color = Colors.redAccent;
        break;
      case 'assist':
        label = '🅰️';
        color = _defColor;
        break;
      case 'yellow_card':
        label = '🟨';
        color = Colors.amber;
        break;
      case 'yellow_red':
        label = '🟧';
        color = Colors.orange;
        break;
      case 'red_card':
        label = '🟥';
        color = Colors.redAccent;
        break;
      case 'penalty_missed':
        label = '✗';
        color = Colors.redAccent;
        break;
      case 'sub_on':
        label = '↑';
        color = const Color(0xFF22C55E);
        break;
      case 'sub_off':
        label = '↓';
        color = Colors.redAccent;
        break;
      default:
        return const SizedBox.shrink();
    }

    final isEmoji = label.runes.first > 127;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isEmoji ? 2.w : 5.w,
        vertical: 1.h,
      ),
      decoration:
          isEmoji
              ? null
              : BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(4.w),
              ),
      child: Text(
        label,
        style: TextStyle(
          color: isEmoji ? null : color,
          fontSize: isEmoji ? 10.sp : 9.sp,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // ── Points column ──────────────────────────────────────────────────────────

  Widget _pointsColumn(
    BuildContext context, {
    required _FantasyPlayer player,
    required bool showActual,
    required int actualPts,
    required int diff,
  }) {
    if (showActual) {
      final diffColor =
          diff > 0
              ? const Color(0xFF22C55E)
              : diff < 0
              ? Colors.redAccent
              : Colors.grey;

      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48.w,
            height: 32.h,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4C1D95), Color(0xFF7C3AED)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12.w),
              boxShadow: [
                BoxShadow(
                  color: _purple.withOpacity(0.35),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Text(
              actualPts.toString().toArabicNumbers(context),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16.sp,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          SizedBox(height: 4.h),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                diff > 0
                    ? Icons.trending_up_rounded
                    : diff < 0
                    ? Icons.trending_down_rounded
                    : Icons.remove,
                size: 14.w,
                color: diffColor,
              ),
              SizedBox(width: 2.w),
              Text(
                diff.abs().toString().toArabicNumbers(context),
                style: TextStyle(
                  color: diffColor,
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 48.w,
          height: 32.h,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _gold.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12.w),
            border: Border.all(color: _gold.withOpacity(0.3)),
          ),
          child: Text(
            player.suggestedPoints.toString().toArabicNumbers(context),
            style: TextStyle(
              color: _gold,
              fontSize: 16.sp,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        SizedBox(height: 5.h),
        Text(
          'PROJ',
          style: TextStyle(
            color: Theme.of(
              context,
            ).textTheme.bodySmall?.color?.withOpacity(0.4),
            fontSize: 8.sp,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }

  // ── Loading / Error ────────────────────────────────────────────────────────

  Widget _buildLoading() {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: ClampingScrollPhysics(),
      ),
      slivers: [
        SliverOverlapInjector(
          handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
        ),
        const SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: CircularProgressIndicator(color: _purple)),
        ),
      ],
    );
  }

  Widget _buildError() {
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
                    Icons.emoji_events_outlined,
                    size: 64.w,
                    color: _purple.withOpacity(0.35),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                      fontSize: 14.sp,
                      height: 1.5,
                    ),
                  ),
                  SizedBox(height: 24.h),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _purple,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.w),
                      ),
                    ),
                    onPressed: _fetchFantasyData,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
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
//  DATA MODEL
// ─────────────────────────────────────────────────────────────────────────────

class _FantasyPlayer {
  final String name;
  final String position;
  final String positionGroup;
  final String number;
  final bool isHome;
  final bool isStarting;
  final bool isCaptain;
  final int suggestedPoints;
  final int? actualPoints;
  final List<String> events;

  const _FantasyPlayer({
    required this.name,
    required this.position,
    required this.positionGroup,
    required this.number,
    required this.isHome,
    required this.isStarting,
    required this.isCaptain,
    required this.suggestedPoints,
    this.actualPoints,
    required this.events,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
//  LIVE DOT
// ─────────────────────────────────────────────────────────────────────────────

class _LiveDot extends StatefulWidget {
  final Color color;
  const _LiveDot({required this.color});

  @override
  State<_LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<_LiveDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _anim = Tween(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder:
          (_, __) => Container(
            width: 9.w,
            height: 9.w,
            decoration: BoxDecoration(
              color: widget.color.withOpacity(_anim.value),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: widget.color.withOpacity(_anim.value * 0.5),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
    );
  }
}
