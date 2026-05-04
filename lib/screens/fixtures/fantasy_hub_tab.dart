import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../core/constants/constants.dart';
import '../../core/services/api_service.dart';
import '../../core/utils/size_config.dart';
import '../../core/utils/name_translator.dart';
import '../../core/utils/number_utils.dart';
import '../../core/utils/logo_utils.dart';

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

  int _selectedTeam = 1; // 1=Home, 2=Away (Default to Home for tactical view)
  bool _showBench = true;
  bool _isPitchView = true;
  // 'predict' shows system-projected points, 'actual' shows real match points.
  // Auto-flips to 'actual' once the match is live/finished (see _fetchFantasyData).
  String _viewMode = 'predict';

  late AnimationController _pitchAnimCtrl;

  // ── Palette (aligned with rest of the app — greenAccent + blueAccent) ─────
  static const Color _green = GoalioColors.greenAccent;

  @override
  void initState() {
    super.initState();
    _pitchAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();
    _fetchFantasyData();
  }

  @override
  void dispose() {
    _pitchAnimCtrl.dispose();
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
        final isFinished = decoded['is_finished'] == true;
        final isLive = decoded['is_live'] == true;
        setState(() {
          _data = decoded;
          _isLoading = false;
          if (isFinished || isLive) _viewMode = 'actual';
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

  Color _posColor(String group) {
    switch (group) {
      case 'GK':
        return const Color(0xFFF59E0B);
      case 'DEF':
        return const Color(0xFF3B82F6);
      case 'MID':
        return const Color(0xFF10B981);
      case 'FWD':
        return const Color(0xFFEF4444);
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
        final rawName = p['name']?.toString() ?? '';
        final number = p['number']?.toString() ?? '';
        // Keep the slot even if the scraper couldn't resolve the name —
        // otherwise the pitch silently drops a starter. Fall back to
        // "#<shirt>" or "?" so all 11 starters still render.
        final name = rawName.isNotEmpty
            ? rawName
            : (number.isNotEmpty ? '#$number' : '?');
        result.add(
          _FantasyPlayer(
            name: name,
            position: p['position']?.toString() ?? '',
            positionGroup: p['position_group']?.toString() ?? 'UNK',
            number: number,
            isHome: isHome,
            isStarting: group == 'starting',
            isCaptain: p['is_captain'] == true,
            suggestedPoints: (p['suggested_points'] as num?)?.toInt() ?? 5,
            actualPoints:
                p['actual_points'] != null
                    ? (p['actual_points'] as num).toInt()
                    : null,
            events: List<dynamic>.from(p['events'] ?? []),
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
    final homeName = _data['home_team']?.toString() ?? widget.match['home_team']?.toString() ?? 'Home';
    final awayName = _data['away_team']?.toString() ?? widget.match['away_team']?.toString() ?? 'Away';
    final homeLogo = _data['home_logo'] ?? widget.match['home_team_image'] ?? widget.match['home_logo'];
    final awayLogo = _data['away_logo'] ?? widget.match['away_team_image'] ?? widget.match['away_logo'];
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

    // Sort by whichever mode is active.
    int Function(_FantasyPlayer, _FantasyPlayer) sorter;
    if (_viewMode == 'actual') {
      sorter = (a, b) => (b.actualPoints ?? 0).compareTo(a.actualPoints ?? 0);
    } else {
      sorter = (a, b) => b.suggestedPoints.compareTo(a.suggestedPoints);
    }
    starters.sort(sorter);
    bench.sort(sorter);

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        children: [
          // ── Premium Sticky Header ───────────────────────────────────────────
          _buildCompactHeader(context, homeName, awayName, homeLogo, awayLogo, isDark),
          
          Expanded(
            child: CustomScrollView(
              key: const PageStorageKey('fantasy_hub_revamp'),
              physics: const BouncingScrollPhysics(),
              slivers: [
                // ── Controls & Summary ───────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                    child: Column(
                      children: [
                        _buildStatusRow(context),
                        SizedBox(height: 12.h),
                        _buildPredictActualTabs(context, isDark),
                        SizedBox(height: 16.h),
                        _buildViewToggle(context, isDark),
                      ],
                    ),
                  ),
                ),

                // ── Main Content Area ────────────────────────────────────────
                if (_isPitchView)
                  SliverToBoxAdapter(
                    child: _buildTacticalPitch(context, filtered, isDark),
                  )
                else ...[
                  // List View Sections
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
                ],

                // ── Bench Section ────────────────────────────────────────────
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
                          _showBench ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                          color: Colors.grey,
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
                          (_, i) => _buildPlayerCard(context, bench[i], isDark, isBench: true),
                          childCount: bench.length,
                        ),
                      ),
                    ),
                ],
                
                SliverToBoxAdapter(child: SizedBox(height: 100.h)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── New UI Components ──────────────────────────────────────────────────────

  Widget _buildCompactHeader(
    BuildContext context,
    String home,
    String away,
    dynamic hLogo,
    dynamic aLogo,
    bool isDark,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12.w),
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.5)),
      ),
      margin: EdgeInsets.all(16.w),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _headerTeamStandard(context, home, hLogo, isLeft: true),
              _headerVS(context),
              _headerTeamStandard(context, away, aLogo, isLeft: false),
            ],
          ),
          SizedBox(height: 16.h),
          _buildTeamSegmentedControl(context, home, away, isDark),
        ],
      ),
    );
  }

  Widget _headerTeamStandard(BuildContext context, String name, dynamic logo, {required bool isLeft}) {
    return Expanded(
      child: Column(
        children: [
          buildTeamLogo(logo?.toString(), size: 36.w),
          SizedBox(height: 6.h),
          Text(
            ArabicNameExtension(name).toArabicName(context),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyLarge?.color,
              fontWeight: FontWeight.bold,
              fontSize: 12.sp,
            ),
          ),
          Text(
            isLeft ? 'HOME' : 'AWAY',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 8.sp,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerVS(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20.w),
      ),
      child: Text(
        'VS',
        style: TextStyle(
          color: Colors.grey,
          fontSize: 10.sp,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTeamSegmentedControl(BuildContext context, String home, String away, bool isDark) {
    return Container(
      height: 40.h,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10.h),
      ),
      child: Row(
        children: [
          _teamTabItem(context, 'ALL', 0, isDark),
          _teamTabItem(context, home, 1, isDark),
          _teamTabItem(context, away, 2, isDark),
        ],
      ),
    );
  }

  Widget _teamTabItem(BuildContext context, String label, int index, bool isDark) {
    final isSelected = _selectedTeam == index;
    final displayLabel = label == 'ALL' ? 'الكل' : ArabicNameExtension(label).toArabicName(context);
    
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTeam = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(8.h),
          ),
          child: Text(
            displayLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey,
              fontSize: 11.sp,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPredictActualTabs(BuildContext context, bool isDark) {
    final actualAvailable = _isFinished || _isLive;

    return Container(
      height: 45.h,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(10.w),
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          _predictActualBtn(
            context,
            label: 'PREDICT',
            active: _viewMode == 'predict',
            enabled: true,
            onTap: () => setState(() => _viewMode = 'predict'),
          ),
          _predictActualBtn(
            context,
            label: 'ACTUAL',
            active: _viewMode == 'actual',
            enabled: actualAvailable,
            onTap: actualAvailable
                ? () => setState(() => _viewMode = 'actual')
                : null,
          ),
        ],
      ),
    );
  }

  Widget _predictActualBtn(
    BuildContext context, {
    required String label,
    required bool active,
    required bool enabled,
    required VoidCallback? onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? Theme.of(context).primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(8.w),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: active ? Colors.white : (enabled ? Colors.grey : Colors.grey.withValues(alpha: 0.3)),
              fontSize: 11.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildViewToggle(BuildContext context, bool isDark) {
    return Row(
      children: [
        _toggleBtn(context, 'TACTICAL', Icons.grid_view_rounded, _isPitchView, true),
        SizedBox(width: 12.w),
        _toggleBtn(context, 'LIST VIEW', Icons.format_list_bulleted_rounded, !_isPitchView, false),
      ],
    );
  }

  Widget _toggleBtn(BuildContext context, String label, IconData icon, bool active, bool isPitch) {
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _isPitchView = isPitch),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 10.h),
          decoration: BoxDecoration(
            color: active ? Theme.of(context).primaryColor.withValues(alpha: 0.1) : Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(10.w),
            border: Border.all(
              color: active ? Theme.of(context).primaryColor : Theme.of(context).dividerColor.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16.sp, color: active ? Theme.of(context).primaryColor : Colors.grey),
              SizedBox(width: 8.w),
              Text(
                label,
                style: TextStyle(
                  color: active ? Theme.of(context).primaryColor : Colors.grey,
                  fontSize: 11.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Tactical Pitch Visualization ───────────────────────────────────────────

  Widget _buildTacticalPitch(BuildContext context, List<_FantasyPlayer> players, bool isDark) {
    final starters = players.where((p) => p.isStarting).toList();
    
    return Container(
      height: 540.h,
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24.w),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.5) : const Color(0xFF10B981).withValues(alpha: 0.3), 
            blurRadius: 30, 
            offset: const Offset(0, 15)
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24.w),
        child: Stack(
          children: [
            // Pitch Background
            _PitchPainterWidget(isDark: isDark),

            // Players
            ..._buildPitchPlayers(context, starters),
            
            // Subtle Overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black.withValues(alpha: 0.2), Colors.transparent, Colors.black.withValues(alpha: 0.2)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildPitchPlayers(BuildContext context, List<_FantasyPlayer> starters) {
    final widgets = <Widget>[];
    const groupOrder = ['GK', 'DEF', 'MID', 'FWD'];

    // Bucket starters by canonical position. UNK falls back to MID so the
    // 11th player never disappears from the pitch.
    final byGroup = <String, List<_FantasyPlayer>>{
      'GK': [], 'DEF': [], 'MID': [], 'FWD': [],
    };
    for (final p in starters) {
      final grp = groupOrder.contains(p.positionGroup) ? p.positionGroup : 'MID';
      byGroup[grp]!.add(p);
    }

    // Keep the pitch visually balanced: DEF and MID must each hold at least
    // 3 players. Borrow from whichever outfield row has the largest surplus,
    // but never drop a donor row below its own minimum.
    int minFor(String g) => (g == 'DEF' || g == 'MID') ? 3 : 0;
    for (final target in const ['DEF', 'MID']) {
      while (byGroup[target]!.length < 3) {
        String? donor;
        int maxSurplus = 0;
        for (final g in const ['FWD', 'MID', 'DEF']) {
          if (g == target) continue;
          final surplus = byGroup[g]!.length - minFor(g);
          if (surplus > maxSurplus) {
            maxSurplus = surplus;
            donor = g;
          }
        }
        if (donor == null) break; // nothing left to borrow
        byGroup[target]!.add(byGroup[donor]!.removeLast());
      }
    }

    for (int i = 0; i < groupOrder.length; i++) {
      final grp = groupOrder[i];
      final inGrp = byGroup[grp]!;
      if (inGrp.isEmpty) continue;

      // Vertical position (0 to 1)
      double y;
      switch (grp) {
        case 'GK': y = 0.9; break;   // Bottom
        case 'DEF': y = 0.65; break;
        case 'MID': y = 0.4; break;
        case 'FWD': y = 0.15; break; // Top
        default: y = 0.5;
      }

      for (int k = 0; k < inGrp.length; k++) {
        // Horizontal distribution
        double x = (k + 1) / (inGrp.length + 1);
        
        widgets.add(
          _PitchPlayerIcon(
            player: inGrp[k],
            x: x,
            y: y,
            posColor: _posColor(grp),
            viewMode: _viewMode,
            onTap: () => _showPlayerDetails(context, inGrp[k]),
          ),
        );
      }
    }
    return widgets;
  }

  void _showPlayerDetails(BuildContext context, _FantasyPlayer player) {
    showDialog(
      context: context,
      builder: (_) => _PlayerDetailsDialog(player: player, posColor: _posColor(player.positionGroup)),
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
                    color: Theme.of(context).dividerColor,
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
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6.w),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12.w, color: color),
          SizedBox(width: 6.w),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10.sp,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }


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
      statusColor = const Color(0xFFEF4444);
      statusLabel = 'LIVE FANTASY';
      statusSub = 'Updating as match progresses';
      isLive = true;
    } else {
      statusColor = Theme.of(context).primaryColor;
      statusLabel = 'PROJECTED POINTS';
      statusSub = 'Pre-match position-based estimate';
      isLive = false;
    }

    return Container(
      margin: EdgeInsets.symmetric(vertical: 8.h),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12.w),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: isLive
                ? _LiveDot(color: statusColor)
                : Icon(
                    Icons.info_outline_rounded,
                    size: 16.sp,
                    color: statusColor,
                  ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusLabel,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  statusSub,
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                    fontSize: 9.sp,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
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
          Icon(icon, size: 13.w, color: Colors.grey),
          SizedBox(width: 6.w),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey,
              fontSize: 10.sp,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
          SizedBox(width: 6.w),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.h),
            decoration: BoxDecoration(
              color: Theme.of(context).dividerColor,
              borderRadius: BorderRadius.circular(6.w),
            ),
            child: Text(
              count.toString(),
              style: TextStyle(
                color: Theme.of(context).textTheme.bodySmall?.color,
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

  Widget _buildPlayerCard(BuildContext context, _FantasyPlayer player, bool isDark, {bool isBench = false}) {
    final showActual = _viewMode == 'actual';
    final actualPts = player.calculateFantasyPoints();
    final diff = actualPts - player.suggestedPoints;


    final posColor = _posColor(player.positionGroup);
    final teamColor = player.isHome ? Theme.of(context).primaryColor : const Color(0xFF22C55E);

    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(10.w),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Jersey Badge
          _jerseyBadgeSimplified(player.number, posColor),
          SizedBox(width: 12.w),
          
          // Name and Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        ArabicNameExtension(player.name).toArabicName(context),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                          fontWeight: FontWeight.bold,
                          fontSize: 13.sp,
                        ),
                      ),
                    ),
                    if (player.isCaptain) ...[
                      SizedBox(width: 4.w),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFACC15),
                          borderRadius: BorderRadius.circular(4.w),
                        ),
                        child: Text('C', style: TextStyle(color: Colors.black, fontSize: 8.sp, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ],
                ),
                SizedBox(height: 2.h),
                Row(
                  children: [
                    Text(
                      player.position,
                      style: TextStyle(color: Colors.grey, fontSize: 9.sp, fontWeight: FontWeight.w500),
                    ),
                    SizedBox(width: 6.w),
                    Container(width: 4.w, height: 4.w, decoration: BoxDecoration(color: teamColor.withValues(alpha: 0.5), shape: BoxShape.circle)),
                    SizedBox(width: 6.w),
                    ...player.events.take(3).map((e) => Padding(
                      padding: EdgeInsets.only(right: 4.w),
                      child: _eventChip(e, isDark),
                    )),
                  ],
                ),
              ],
            ),
          ),

          // Points Column
          _pointsColumn(
            context,
            player: player,
            showActual: showActual,
            actualPts: actualPts,
            diff: diff,
          ),
        ],
      ),
    );
  }

  Widget _jerseyBadgeSimplified(String number, Color color) {
    return Container(
      width: 32.w,
      height: 32.w,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1.5),
      ),
      child: Center(
        child: Text(
          number.isEmpty ? '–' : number.toArabicNumbers(context),
          style: TextStyle(color: color, fontSize: 13.sp, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }



  Widget _pointsColumn(
    BuildContext context, {
    required _FantasyPlayer player,
    required bool showActual,
    required int actualPts,
    required int diff,
  }) {
    final points = showActual ? actualPts : player.suggestedPoints;
    final color = showActual ? (diff >= 0 ? _green : Colors.redAccent) : Theme.of(context).primaryColor;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          points.toString().toArabicNumbers(context),
          style: TextStyle(color: color, fontSize: 16.sp, fontWeight: FontWeight.w900),
        ),
        Text(
          showActual ? 'PTS' : 'PROJ',
          style: TextStyle(color: Colors.grey, fontSize: 8.sp, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _eventChip(dynamic event, bool isDark) {
    String t;
    String? detail;
    String? minute;

    if (event is String) {
      t = event;
    } else if (event is Map) {
      t = event['type']?.toString() ?? '';
      detail = event['detail']?.toString();
      minute = event['minute']?.toString();
    } else {
      return const SizedBox.shrink();
    }

    IconData? icon;
    Color color = Colors.grey;
    String? emoji;

    if (t == 'goal' || t == 'G') {
      icon = Icons.sports_soccer_rounded;
      color = const Color(0xFF10B981);
    } else if (t == 'penalty_goal') {
      icon = Icons.sports_score_rounded;
      color = const Color(0xFF10B981);
    } else if (t == 'own_goal') {
      icon = Icons.sports_soccer_rounded;
      color = const Color(0xFFEF4444);
    } else if (t == 'yellow_card' || t == 'YC') {
      icon = Icons.square_rounded;
      color = const Color(0xFFFACC15);
    } else if (t == 'red_card' || t == 'RC') {
      icon = Icons.square_rounded;
      color = const Color(0xFFEF4444);
    } else if (t == 'yellow_red') {
      icon = Icons.amp_stories_rounded;
      color = const Color(0xFFFACC15);
    } else if (t == 'clean_sheet') {
      emoji = '🛡️';
    } else if (t == 'assist') {
      emoji = '👟';
    } else {
      icon = Icons.circle;
      color = isDark ? Colors.white24 : Colors.black12;
    }

    final isEmoji = emoji != null;
    return Container(
      padding: isEmoji ? EdgeInsets.zero : EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      decoration: isEmoji ? null : BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.15 : 0.1),
        borderRadius: BorderRadius.circular(6.w),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 8.w, color: color),
            SizedBox(width: 2.w),
          ],
          Text(
            isEmoji ? emoji : (minute ?? detail ?? t.toUpperCase()),
            style: TextStyle(
              color: isEmoji ? null : color,
              fontSize: 8.sp,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
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
          child: Center(child: CircularProgressIndicator()),
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
                    color: Colors.grey.withValues(alpha: 0.3),
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

// ── Tactical Pitch Painter ──────────────────────────────────────────────────

class _PitchPainterWidget extends StatelessWidget {
  final bool isDark;
  const _PitchPainterWidget({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.infinite,
      painter: _PitchPainter(isDark: isDark),
    );
  }
}

class _PitchPainter extends CustomPainter {
  final bool isDark;
  _PitchPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = isDark ? const Color(0xFF064E3B) : GoalioColors.greenAccent;

    canvas.drawRect(Offset.zero & size, paint);

    // Lines
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Boundary
    canvas.drawRect(Rect.fromLTRB(10, 10, size.width - 10, size.height - 10), linePaint);

    // Halfway line
    canvas.drawLine(Offset(0, size.height / 2), Offset(size.width, size.height / 2), linePaint);
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), 60, linePaint);

    // Penalty Areas
    _drawBox(canvas, size, linePaint, isTop: true);
    _drawBox(canvas, size, linePaint, isTop: false);
  }

  void _drawBox(Canvas canvas, Size size, Paint paint, {required bool isTop}) {
    double y = isTop ? 10 : size.height - 10;
    double h = 100 * (isTop ? 1 : -1);
    canvas.drawRect(Rect.fromLTWH(size.width / 2 - 120, y, 240, h), paint);
    canvas.drawRect(Rect.fromLTWH(size.width / 2 - 60, y, 120, h / 2.5), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Pitch Player Icon ────────────────────────────────────────────────────────

class _PitchPlayerIcon extends StatelessWidget {
  final _FantasyPlayer player;
  final double x, y;
  final Color posColor;
  final String viewMode;
  final VoidCallback onTap;

  const _PitchPlayerIcon({
    required this.player,
    required this.x,
    required this.y,
    required this.posColor,
    required this.viewMode,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment(x * 2 - 1, y * 2 - 1),
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Jersey Icon
            Container(
              width: 38.w,
              height: 38.w,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: posColor, width: 2.5),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                   Center(
                    child: Text(
                      player.number.isEmpty ? '?' : player.number.toArabicNumbers(context),
                      style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 13.sp),
                    ),
                  ),
                  if (player.isCaptain)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: EdgeInsets.all(1.w),
                        decoration: const BoxDecoration(color: Color(0xFFFACC15), shape: BoxShape.circle),
                        child: Text('C', style: TextStyle(color: Colors.black, fontSize: 6.sp, fontWeight: FontWeight.bold)),
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(height: 4.h),
            // Player Name Label
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(4.w),
              ),
              child: Text(
                ArabicNameExtension(player.name).toArabicName(context),
                maxLines: 1,
                style: TextStyle(color: Colors.white, fontSize: 8.sp, fontWeight: FontWeight.bold),
              ),
            ),
            // Points Tag
            if (viewMode == 'actual' || player.actualPoints != null)
              Container(
                margin: EdgeInsets.only(top: 2.h),
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                decoration: BoxDecoration(
                  color: posColor,
                  borderRadius: BorderRadius.circular(4.w),
                ),
                child: Text(
                  (player.actualPoints ?? 0).toString().toArabicNumbers(context),
                  style: TextStyle(color: Colors.white, fontSize: 9.sp, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Player Details Dialog ────────────────────────────────────────────────────

class _PlayerDetailsDialog extends StatelessWidget {
  final _FantasyPlayer player;
  final Color posColor;

  const _PlayerDetailsDialog({required this.player, required this.posColor});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.all(20.w),
      child: Container(
        padding: EdgeInsets.all(24.w),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(28.w),
          border: Border.all(color: posColor.withValues(alpha: 0.3), width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                CircleAvatar(backgroundColor: posColor.withValues(alpha: 0.2), child: Text(player.number, style: TextStyle(color: posColor, fontWeight: FontWeight.bold))),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ArabicNameExtension(player.name).toArabicName(context), style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w900)),
                      Text(player.position, style: TextStyle(color: posColor, fontSize: 10.sp, fontWeight: FontWeight.bold, letterSpacing: 1)),
                    ],
                  ),
                ),
                GestureDetector(onTap: () => Navigator.pop(context), child: Icon(Icons.close_rounded, color: Colors.grey)),
              ],
            ),
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _statCircle(context, 'PROJ', player.suggestedPoints.toString(), Colors.grey),
                _statCircle(context, 'ACTUAL', (player.actualPoints ?? 0).toString(), const Color(0xFF6366F1)),
              ],
            ),
            if (player.events.isNotEmpty) ...[
              SizedBox(height: 24.h),
              Text('MATCH EVENTS', style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.bold, color: Colors.grey)),
              SizedBox(height: 8.h),
              Wrap(spacing: 8, children: player.events.map((e) => _eventTag(e)).toList()),
            ],
            SizedBox(height: 24.h),
          ],
        ),
      ),
    );
  }

  Widget _statCircle(BuildContext context, String label, String val, Color color) {
    return Column(
      children: [
        Text(
          val.toArabicNumbers(context),
          style: TextStyle(color: color, fontSize: 24.sp, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.bold, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _eventTag(String type) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6.w),
      ),
      child: Text(
        type.replaceAll('_', ' ').toUpperCase(),
        style: TextStyle(fontSize: 9.sp, fontWeight: FontWeight.bold, color: Colors.grey),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  DATA MODEL & LIVE DOT
// ─────────────────────────────────────────────────────────────────────────────

class _FantasyPlayer {
  final String name, position, positionGroup, number;
  final bool isHome, isStarting, isCaptain;
  final int suggestedPoints;
  final int? actualPoints;
  final List<dynamic> events;

  const _FantasyPlayer({
    required this.name, required this.position, required this.positionGroup,
    required this.number, required this.isHome, required this.isStarting,
    required this.isCaptain, required this.suggestedPoints, this.actualPoints,
    required this.events,
  });

  int calculateFantasyPoints() => actualPoints ?? 0;
}

class _LiveDot extends StatefulWidget {
  final Color color;
  const _LiveDot({required this.color});
  @override State<_LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<_LiveDot> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..repeat(reverse: true);
    _anim = Tween(begin: 0.3, end: 1.0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }
  @override void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: 10.w, height: 10.w,
        decoration: BoxDecoration(
          color: widget.color.withValues(alpha: _anim.value),
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: widget.color.withValues(alpha: _anim.value * 0.5), blurRadius: 6, spreadRadius: 1)],
        ),
      ),
    );
  }
}
