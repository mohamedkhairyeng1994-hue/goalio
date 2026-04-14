import 'dart:convert';
import 'dart:math' as math;
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
  bool _showBench = false;
  bool _isPitchView = true;

  late AnimationController _pitchAnimCtrl;

  // ── Palette ────────────────────────────────────────────────────────────────
  static const Color _gold = Color(0xFFFFD700);
  static const Color _purple = Color(0xFF6366F1);
  static const Color _purpleLight = Color(0xFF818CF8);
  static const Color _green = Color(0xFF34D399); // Brand Green
  static const Color _blue = Color(0xFF3B82F6); // Brand Blue
  static const Color _darkBg = Color(0xFF0F172A);
  static const Color _card = Color(0xFF1E293B);
  static const Color _cardBorder = Color(0xFF334155);

  // Position colors (Premium shades)
  static const Color _gkColor = Color(0xFFF59E0B);
  static const Color _defColor = Color(0xFF3B82F6);
  static const Color _midColor = Color(0xFF10B981);
  static const Color _fwdColor = Color(0xFFEF4444);

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

  static const Color _neonGreen = Color(0xFF10B981);
  static const Color _neonBlue = Color(0xFF3B82F6);
  static const Color _accentGold = Color(0xFFFFD700);

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
    final homeName = _data['home_team']?.toString() ?? widget.match['home_team']?.toString() ?? 'Home';
    final awayName = _data['away_team']?.toString() ?? widget.match['away_team']?.toString() ?? 'Away';
    final homeLogo = _data['home_logo'] ?? widget.match['home_team_image'] ?? widget.match['home_logo'];
    final awayLogo = _data['away_logo'] ?? widget.match['away_team_image'] ?? widget.match['away_logo'];
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

    return Container(
      color: isDark ? _darkBg : const Color(0xFFF8FAFC),
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
                        _buildStatQuickGrid(context, isDark),
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
      padding: EdgeInsets.fromLTRB(16.w, MediaQuery.of(context).padding.top + 10.h, 16.w, 16.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark 
            ? [const Color(0xFF1E1B4B), const Color(0xFF0F172A)]
            : [const Color(0xFF6366F1), const Color(0xFF4F46E5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _headerTeam(context, home, hLogo, isLeft: true),
              _headerDivider(context),
              _headerTeam(context, away, aLogo, isLeft: false),
            ],
          ),
          SizedBox(height: 16.h),
          _buildTeamSegmentedControl(context, home, away, isDark),
        ],
      ),
    );
  }

  Widget _headerTeam(BuildContext context, String name, dynamic logo, {required bool isLeft}) {
    return Expanded(
      child: Row(
        mainAxisAlignment: isLeft ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: [
          if (!isLeft) const Spacer(),
          if (!isLeft) 
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  ArabicNameExtension(name).toArabicName(context),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.white, fontSize: 13.sp, fontWeight: FontWeight.w800),
                ),
                Text('AWAY', style: TextStyle(color: Colors.white54, fontSize: 8.sp, fontWeight: FontWeight.bold, letterSpacing: 1)),
              ],
            ),
          SizedBox(width: 8.w),
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(color: Colors.white12, shape: BoxShape.circle),
            child: buildTeamLogo(logo?.toString(), size: 32.w),
          ),
          SizedBox(width: 8.w),
          if (isLeft)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ArabicNameExtension(name).toArabicName(context),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.white, fontSize: 13.sp, fontWeight: FontWeight.w800),
                ),
                Text('HOME', style: TextStyle(color: Colors.white54, fontSize: 8.sp, fontWeight: FontWeight.bold, letterSpacing: 1)),
              ],
            ),
          if (isLeft) const Spacer(),
        ],
      ),
    );
  }

  Widget _headerDivider(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.w),
        border: Border.all(color: Colors.white24),
      ),
      child: Text(
        'VS',
        style: TextStyle(color: Colors.white, fontSize: 10.sp, fontWeight: FontWeight.w900),
      ),
    );
  }

  Widget _buildTeamSegmentedControl(BuildContext context, String home, String away, bool isDark) {
    return Container(
      height: 38.h,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(19.h),
      ),
      child: Row(
        children: [
          _teamTabItem(context, 'ALL', 0),
          _teamTabItem(context, home, 1),
          _teamTabItem(context, away, 2),
        ],
      ),
    );
  }

  Widget _teamTabItem(BuildContext context, String label, int index) {
    final isSelected = _selectedTeam == index;
    final displayLabel = label == 'ALL' ? 'الكل' : ArabicNameExtension(label).toArabicName(context);
    
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTeam = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: EdgeInsets.all(3.w),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(16.h),
          ),
          child: Text(
            displayLabel.length > 8 ? '${displayLabel.substring(0, 8)}…' : displayLabel,
            style: TextStyle(
              color: isSelected ? const Color(0xFF1E1B4B) : Colors.white70,
              fontSize: 10.sp,
              fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatQuickGrid(BuildContext context, bool isDark) {
    final homePts = (_summary['home_total_points'] as num?)?.toInt() ?? 0;
    final awayPts = (_summary['away_total_points'] as num?)?.toInt() ?? 0;
    
    return Row(
      children: [
        _statBox(context, 'HOME PTS', homePts.toString(), _neonBlue, isDark),
        SizedBox(width: 8.w),
        _statBox(context, 'AWAY PTS', awayPts.toString(), _neonGreen, isDark),
        SizedBox(width: 8.w),
        _statBox(context, 'TOTAL', (homePts + awayPts).toString(), _accentGold, isDark),
      ],
    );
  }

  Widget _statBox(BuildContext context, String label, String val, Color color, bool isDark) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10.h),
        decoration: BoxDecoration(
          color: isDark ? _card : Colors.white,
          borderRadius: BorderRadius.circular(16.w),
          border: Border.all(color: color.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(color: color.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          children: [
            Text(label, style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 8.sp, fontWeight: FontWeight.bold)),
            Text(val.toArabicNumbers(context), style: TextStyle(color: color, fontSize: 16.sp, fontWeight: FontWeight.w900, fontFamily: 'RobotoCondensed')),
          ],
        ),
      ),
    );
  }

  Widget _buildViewToggle(BuildContext context, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? _card : Colors.white,
        borderRadius: BorderRadius.circular(16.w),
        border: Border.all(color: _purple.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          _toggleBtn(context, 'TACTICAL', Icons.grid_view_rounded, _isPitchView, true),
          _toggleBtn(context, 'LIST VIEW', Icons.format_list_bulleted_rounded, !_isPitchView, false),
        ],
      ),
    );
  }

  Widget _toggleBtn(BuildContext context, String label, IconData icon, bool active, bool isPitch) {
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _isPitchView = isPitch),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: EdgeInsets.symmetric(vertical: 10.h),
          decoration: BoxDecoration(
            color: active ? _purple.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(16.w),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14.w, color: active ? _purpleLight : Colors.grey),
              SizedBox(width: 8.w),
              Text(label, style: TextStyle(color: active ? _purpleLight : Colors.grey, fontSize: 10.sp, fontWeight: FontWeight.w800)),
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
      height: 520.h,
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24.w),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10)),
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
                  colors: [Colors.black.withOpacity(0.4), Colors.transparent, Colors.black.withOpacity(0.4)],
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
    
    for (int i = 0; i < groupOrder.length; i++) {
      final grp = groupOrder[i];
      final inGrp = starters.where((p) => p.positionGroup == grp).toList();
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
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10.w),
        border: Border.all(color: color.withOpacity(0.2)),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
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

    return ClipRRect(
      borderRadius: BorderRadius.circular(20.w),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: statusColor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20.w),
          border: Border.all(color: statusColor.withOpacity(0.15), width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.12),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: statusColor.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: isLive
                  ? _LiveDot(color: statusColor)
                  : Icon(
                      Icons.info_outline_rounded,
                      size: 16.w,
                      color: statusColor,
                    ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    statusLabel,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    statusSub,
                    style: TextStyle(
                      color: isDark ? Colors.white60 : Colors.black54,
                      fontSize: 9.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
      margin: EdgeInsets.only(bottom: 14.h),
      decoration: BoxDecoration(
        color: isDark ? (isBench ? Color(0xFF1E293B).withOpacity(0.4) : Color(0xFF1E293B)) : Colors.white,
        borderRadius: BorderRadius.circular(24.w),
        border: Border.all(
          color: showActual && actualPts >= 10
              ? _gold.withOpacity(0.5)
              : isDark
                  ? _cardBorder.withOpacity(0.5)
                  : Colors.grey.withOpacity(0.1),
          width: showActual && actualPts >= 10 ? 2 : 1,
        ),
        boxShadow: [
          if (showActual && actualPts >= 10)
            BoxShadow(
              color: _gold.withOpacity(0.15),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.04),
            blurRadius: 15,
            offset: const Offset(0, 8),
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
      width: 18.w,
      height: 18.w,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_gold, Color(0xFFB8860B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: _gold.withOpacity(0.3),
            blurRadius: 4,
          ),
        ],
      ),
      child: Center(
        child: Text(
          'C',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 9.sp,
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
            width: 52.w,
            height: 36.h,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: actualPts >= 10 
                  ? [const Color(0xFFB8860B), _gold]
                  : [const Color(0xFF4C1D95), const Color(0xFF7C3AED)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14.w),
              boxShadow: [
                BoxShadow(
                  color: (actualPts >= 10 ? _gold : _purple).withOpacity(0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              actualPts.toString().toArabicNumbers(context),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: actualPts >= 10 ? Colors.black87 : Colors.white,
                fontSize: 17.sp,
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
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: isDark 
          ? [const Color(0xFF064E3B), const Color(0xFF065F46), const Color(0xFF047857)]
          : [const Color(0xFF10B981), const Color(0xFF059669), const Color(0xFF047857)],
      ).createShader(Offset.zero & size);

    canvas.drawRect(Offset.zero & size, paint);

    // Lines
    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.15)
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
  final VoidCallback onTap;

  const _PitchPlayerIcon({
    required this.player,
    required this.x,
    required this.y,
    required this.posColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasHighPoints = (player.actualPoints ?? 0) >= 8;
    
    return Align(
      alignment: Alignment(x * 2 - 1, y * 2 - 1),
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                if (hasHighPoints)
                  _GlowEffect(color: Colors.amber),
                Container(
                  width: 38.w,
                  height: 38.w,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: posColor, width: 2.5),
                    boxShadow: [
                      BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      player.number.isEmpty ? '?' : player.number.toArabicNumbers(context),
                      style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w900, fontSize: 13.sp, fontFamily: 'RobotoCondensed'),
                    ),
                  ),
                ),
                if (player.isCaptain)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: EdgeInsets.all(2.w),
                      decoration: const BoxDecoration(color: Colors.amber, shape: BoxShape.circle),
                      child: Text('C', style: TextStyle(color: Colors.black, fontSize: 8.sp, fontWeight: FontWeight.w900)),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 4.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(4.w),
              ),
              child: Text(
                ArabicNameExtension(player.name).toArabicName(context),
                maxLines: 1,
                style: TextStyle(color: Colors.white, fontSize: 8.sp, fontWeight: FontWeight.bold),
              ),
            ),
            if (player.actualPoints != null)
              Container(
                margin: EdgeInsets.only(top: 2.h),
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                decoration: BoxDecoration(color: posColor, borderRadius: BorderRadius.circular(4.w)),
                child: Text(
                  player.actualPoints.toString().toArabicNumbers(context),
                  style: TextStyle(color: Colors.white, fontSize: 9.sp, fontWeight: FontWeight.w900),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _GlowEffect extends StatefulWidget {
  final Color color;
  const _GlowEffect({required this.color});

  @override
  State<_GlowEffect> createState() => _GlowEffectState();
}

class _GlowEffectState extends State<_GlowEffect> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true);
  }
  @override
  void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) => Container(
        width: 48.w, height: 48.w,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: widget.color.withOpacity(0.4 * _c.value), blurRadius: 15, spreadRadius: 5)],
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
          border: Border.all(color: posColor.withOpacity(0.3), width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                CircleAvatar(backgroundColor: posColor.withOpacity(0.2), child: Text(player.number, style: TextStyle(color: posColor, fontWeight: FontWeight.bold))),
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
                _statCircle(context, 'ACTUAL', (player.actualPoints ?? 0).toString(), const Color(0xFF6366F1), isLarge: true),
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

  Widget _statCircle(BuildContext context, String label, String val, Color color, {bool isLarge = false}) {
    return Column(
      children: [
        Container(
          width: isLarge ? 80.w : 60.w,
          height: isLarge ? 80.w : 60.w,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: color.withOpacity(0.3), width: 2),
          ),
          child: Text(val.toArabicNumbers(context), style: TextStyle(color: color, fontSize: isLarge ? 28.sp : 20.sp, fontWeight: FontWeight.w900)),
        ),
        SizedBox(height: 8.h),
        Text(label, style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _eventTag(String type) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(20)),
      child: Text(type.replaceAll('_', ' ').toUpperCase(), style: TextStyle(fontSize: 9.sp, fontWeight: FontWeight.bold)),
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
  final List<String> events;

  const _FantasyPlayer({
    required this.name, required this.position, required this.positionGroup,
    required this.number, required this.isHome, required this.isStarting,
    required this.isCaptain, required this.suggestedPoints, this.actualPoints,
    required this.events,
  });
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
          color: widget.color.withOpacity(_anim.value),
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: widget.color.withOpacity(_anim.value * 0.5), blurRadius: 6, spreadRadius: 1)],
        ),
      ),
    );
  }
}
