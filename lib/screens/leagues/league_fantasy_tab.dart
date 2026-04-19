import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../core/constants/constants.dart';
import '../../core/services/api_service.dart';
import '../../core/utils/size_config.dart';
import '../../core/utils/name_translator.dart';
import '../../core/utils/number_utils.dart';
import '../../l10n/app_localizations.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  LEAGUE FANTASY TAB — Premier League Dream Team for the latest round
// ─────────────────────────────────────────────────────────────────────────────

class LeagueFantasyTab extends StatefulWidget {
  final int leagueId;

  const LeagueFantasyTab({super.key, required this.leagueId});

  @override
  State<LeagueFantasyTab> createState() => _LeagueFantasyTabState();
}

class _LeagueFantasyTabState extends State<LeagueFantasyTab>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  bool _isPitchView = true;
  String? _error;
  Map<String, dynamic> _data = {};

  late AnimationController _shimmerCtrl;

  // ── Palette (Official FPL Style) ──────────────────────────────────────────
  static const Color _plPurple = Color(0xFF37003C); // Official PL Deep Purple
  static const Color _plGreen = Color(0xFF00FF85); // Official PL Neon Green
  static const Color _plBlue = Color(0xFF02EFFF); // Official PL Cyan
  static const Color _gold = Color(0xFFFFD700);
  static const Color _benchBg = Color(0xFF00FF85); // Lighter green for dugout

  // Position colours
  static const Color _gkColor = Color(0xFFEAB308);
  static const Color _defColor = Color(0xFF3B82F6);
  static const Color _midColor = Color(0xFF10B981);
  static const Color _fwdColor = Color(0xFFEF4444);

  // Pitch colours
  static const Color _pitchDark = Color(0xFF135730);
  static const Color _pitchLight = Color(0xFF186638);
  static const Color _pitchBorder = Color(0xFF2D9C5A);
  static const Color _lineWhite = Color(0x99FFFFFF);

  @override
  void initState() {
    super.initState();
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
    _fetch();
  }

  @override
  void dispose() {
    _shimmerCtrl.dispose();
    super.dispose();
  }

  // ── Fetch ──────────────────────────────────────────────────────────────────

  Future<void> _fetch() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final result = await ApiService.getLeagueFantasy(widget.leagueId);

      if (!mounted) return;

      if (result.containsKey('error')) {
        String errMsg =
            result['error']?.toString() ?? 'Error loading Dream Team';
        // Add debug info if available (to help the user report the exact issue)
        if (result.containsKey('requested_id') &&
            result.containsKey('premier_league_id')) {
          errMsg +=
              "\n(ID Mismatch: ${result['requested_id']} vs ${result['premier_league_id']})";
        }
        setState(() {
          _error = errMsg;
          _isLoading = false;
        });
      } else {
        setState(() {
          // Handle potential 'data' wrapper from production API
          _data = result.containsKey('data') ? result['data'] : result;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Connection error.';
          _isLoading = false;
        });
      }
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Color _posColor(String? group) {
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

  bool _isGoalkeeper(Map<String, dynamic> p) {
    final pg =
        (p['position_group'] ??
                p['position'] ??
                p['pos'] ??
                p['role'] ??
                p['type_name'] ??
                '')
            .toString()
            .toUpperCase()
            .trim();
    final pId =
        (p['position_id'] ??
                p['pos_id'] ??
                p['type_id'] ??
                p['position_type_id'] ??
                0)
            .toString();
    return pg.startsWith('G') || pg.contains('GK') || pId == '1';
  }

  String _getPositionShort(Map<String, dynamic> p) {
    if (_isGoalkeeper(p)) return 'GK';
    final pg =
        (p['position_group'] ??
                p['position'] ??
                p['pos'] ??
                p['role'] ??
                p['type_name'] ??
                '')
            .toString()
            .toUpperCase()
            .trim();
    final pId = (p['position_id'] ?? 0).toString();

    if (pg.startsWith('D') || pg.contains('BACK') || pId == '2') return 'DEF';
    if (pg.startsWith('M') || pg.contains('FIELD') || pId == '3') return 'MID';
    if (pg.startsWith('F') ||
        pg.startsWith('A') ||
        pg.contains('ATTACK') ||
        pId == '4')
      return 'FWD';

    // If absolutely nothing is found or it's 'UNK', default to MID (most common) or first 3 chars
    if (pg.isEmpty || pg == 'UNK' || pg == 'UNKNOWN') return 'MID';
    return pg.length > 3 ? pg.substring(0, 3) : pg;
  }

  List<Map<String, dynamic>> _group(String pos) {
    final list =
        (_data['starting'] as List<dynamic>?) ??
        (_data['starters'] as List<dynamic>?) ??
        (_data['players'] as List<dynamic>?) ??
        [];

    return list.map((e) => e as Map<String, dynamic>).where((p) {
      final pPos = _getPositionShort(p);
      return pPos == pos.toUpperCase();
    }).toList();
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return _buildLoading();
    if (_error != null) return _buildError();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bench = (_data['bench'] as List<dynamic>?) ?? [];
    final totalPts = _data['total_points'] ?? 0;
    final formation = _data['formation']?.toString() ?? '4-3-3';
    final roundDate = _data['round_date']?.toString() ?? '';
    final matchCount = _data['matches_count'] ?? 0;

    final gks = _group('GK');
    final defs = _group('DEF');
    final mids = _group('MID');
    final fwds = _group('FWD');

    // Filter bench to show exactly 1 GK and 3 Outfielders as requested
    final benchGks =
        bench.where((p) => _isGoalkeeper(p as Map<String, dynamic>)).toList();
    final benchOutfielders =
        bench.where((p) => !_isGoalkeeper(p as Map<String, dynamic>)).toList();
    final displayBench = [
      if (benchGks.isNotEmpty) benchGks.first,
      ...benchOutfielders.take(3),
    ];

    return RefreshIndicator(
      onRefresh: _fetch,
      color: _plPurple,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: ClampingScrollPhysics(),
        ),
        child: Column(
          children: [
            // ── Header ─────────────────────────────────────────────────────────
            _buildHeader(context, totalPts, formation, roundDate, matchCount),

            if (_isPitchView) ...[
              // ── Pitch ──────────────────────────────────────────────────────────
              _buildPitch(context, gks, defs, mids, fwds),

              SizedBox(height: 20.h),

              // ── Subs header ────────────────────────────────────────────────────
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Row(
                  children: [
                    Container(
                      width: 3.w,
                      height: 16.h,
                      decoration: BoxDecoration(
                        color: _plPurple.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      AppLocalizations.of(context)!.dreamTeamSubs.toUpperCase(),
                      style: TextStyle(
                        color: isDark ? Colors.white70 : _plPurple,
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 12.h),

              // ── Bench 'Dugout' Container ──────────────────────────────────────
              Container(
                margin: EdgeInsets.symmetric(horizontal: 16.w),
                padding: EdgeInsets.symmetric(vertical: 12.h),
                decoration: BoxDecoration(
                  color: const Color(0xFF65AC7F).withOpacity(0.4),
                  borderRadius: BorderRadius.circular(12.w),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.w),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(displayBench.length, (i) {
                        final p = displayBench[i] as Map<String, dynamic>;
                        final pos = _getPositionShort(p);
                        return Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4.w),
                          child: _pitchPlayer(context, p, _posColor(pos)),
                        );
                      }),
                    ),
                  ),
                ),
              ),
            ] else
              _buildListView(context, gks, defs, mids, fwds, bench),

            // Add ample bottom space to ensure dugout/bench isn't hidden by BottomNav
            SizedBox(height: 100.h),
          ],
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────

  Widget _buildHeader(
    BuildContext context,
    dynamic totalPts,
    String formation,
    String roundDate,
    dynamic matchCount,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : _plPurple;
    final subLabelColor = isDark ? Colors.white70 : Colors.black54;

    return Container(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      child: Column(
        children: [
          // ── Header Row (GW + Pts) ──────────────────
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Round Name (Clean style)
                Text(
                  _data['round_name']?.toString() ?? 'Gameweek',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w900,
                  ),
                ),

                // Total Points (Compact style)
                _buildTotalPtsBox(totalPts.toString().toArabicNumbers(context)),
              ],
            ),
          ),
          SizedBox(height: 10.h),

          // ── Pitch/List Toggle ──────────────────────
          Container(
            width: 180.w,
            height: 30.h,
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: isDark ? Colors.white12 : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(16.h),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isPitchView = true),
                    child: Container(
                      decoration: BoxDecoration(
                        color: _isPitchView ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(18.h),
                        boxShadow:
                            _isPitchView
                                ? [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                                : null,
                      ),
                      child: Center(
                        child: Text(
                          'Pitch',
                          style: TextStyle(
                            color: _isPitchView ? _plPurple : subLabelColor,
                            fontSize: 13.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isPitchView = false),
                    child: Container(
                      decoration: BoxDecoration(
                        color:
                            !_isPitchView ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(18.h),
                        boxShadow:
                            !_isPitchView
                                ? [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                                : null,
                      ),
                      child: Center(
                        child: Text(
                          'List',
                          style: TextStyle(
                            color: !_isPitchView ? _plPurple : subLabelColor,
                            fontSize: 11.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalPtsBox(String pts) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF02FEFF), Color(0xFF00FF85)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10.w),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF02FEFF).withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            pts,
            style: TextStyle(
              color: _plPurple,
              fontSize: 14.sp,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(width: 4.w),
          Text(
            'Pts',
            style: TextStyle(
              color: _plPurple.withOpacity(0.8),
              fontSize: 14.sp,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  // ── Pitch ──────────────────────────────────────────────────────────────────

  Widget _buildPitch(
    BuildContext context,
    List<Map<String, dynamic>> gks,
    List<Map<String, dynamic>> defs,
    List<Map<String, dynamic>> mids,
    List<Map<String, dynamic>> fwds,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      child: Column(
        children: [
          // ── The Field ────────────────────────────
          AspectRatio(
            aspectRatio: 0.80, // Increased field height
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(12.w),
                ),
                border: Border.all(
                  color: _plGreen.withOpacity(0.5),
                  width: 1.5,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(11.w),
                ),
                child: CustomPaint(
                  painter: _PitchPainter(),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 6.w,
                      vertical: 4.h, // Reduced from 10.h to prevent clipping
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        // GKP row (Top)
                        _playerRow(context, gks, _gkColor),
                        SizedBox(height: 10.h),
                        // DEF row
                        _playerRow(context, defs, _defColor),
                        SizedBox(height: 15.h),
                        // MID row
                        _playerRow(context, mids, _midColor),
                        SizedBox(height: 15.h),
                        // FWD row
                        _playerRow(context, fwds, _fwdColor),

                        const Spacer(), // Pushes everything to the top
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBannerItem() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.sports_soccer_rounded, color: _plPurple, size: 16.w),
        SizedBox(width: 8.w),
        Text(
          'Fantasy',
          style: TextStyle(
            color: _plPurple,
            fontSize: 14.sp,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _playerRow(
    BuildContext context,
    List<Map<String, dynamic>> players,
    Color color,
  ) {
    if (players.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children:
              players
                  .map(
                    (p) => Padding(
                      padding: EdgeInsets.symmetric(horizontal: 2.w),
                      child: _pitchPlayer(context, p, color),
                    ),
                  )
                  .toList(),
        ),
      ),
    );
  }

  Widget _pitchPlayer(
    BuildContext context,
    Map<String, dynamic> player,
    Color color,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final name = player['name']?.toString() ?? '';
    final pts = player['actual_points'] ?? player['suggested_points'] ?? 0;
    final isCap = player['is_captain'] == true;
    final isVice = player['is_vice_captain'] == true;

    final parts = name.trim().split(' ');
    final lastName = parts.length > 1 ? parts.last : name;
    final displayName = ArabicNameExtension(lastName).toArabicName(context);

    return SizedBox(
      width: 68.w,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Premium Badge ────────────────────────
          GestureDetector(
            onTap: () => _showPlayerDetails(context, player),
            child: Container(
              width: 42.w,
              height: 44.h,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Main Circular Badge
                  Center(
                    child: Container(
                      width: 36.w,
                      height: 36.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(
                          color: isDark ? Colors.white24 : Colors.white,
                          width: 2.w,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child:
                            (player['team_logo'] != null &&
                                    player['team_logo'].toString().isNotEmpty)
                                ? Image.network(
                                  player['team_logo'],
                                  fit: BoxFit.contain,
                                  width: 16.w,
                                  height: 16.w,
                                  errorBuilder:
                                      (c, e, s) => Icon(
                                        Icons.sports_soccer,
                                        color: _plPurple.withOpacity(0.2),
                                        size: 22.w,
                                      ),
                                )
                                : Icon(
                                  Icons.sports_soccer,
                                  color: _plPurple.withOpacity(0.2),
                                  size: 22.w,
                                ),
                      ),
                    ),
                  ),

                  // Floating Position Pill
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 6.w,
                          vertical: 1.h,
                        ),
                        decoration: BoxDecoration(
                          color: _plPurple,
                          borderRadius: BorderRadius.circular(10.w),
                          border: Border.all(color: Colors.white, width: 1),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 2,
                            ),
                          ],
                        ),
                        child: Text(
                          _getPositionShort(player),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 6.5.sp,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Captaincy badge
                  if (isCap || isVice)
                    Positioned(
                      top: -2.h,
                      right: -2.w,
                      child: Container(
                        width: 16.w,
                        height: 16.w,
                        decoration: BoxDecoration(
                          color: isCap ? _plGreen : Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: _plPurple, width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 2,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            isCap ? 'C' : 'V',
                            style: TextStyle(
                              color: _plPurple,
                              fontSize: 9.sp,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          SizedBox(height: 6.h),

          // ── Name Box (Adaptive) ──────────────────
          Container(
            width: double.infinity,
            margin: EdgeInsets.symmetric(horizontal: 2.w),
            padding: EdgeInsets.symmetric(vertical: 2.h),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2A2840) : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(3.w),
                topRight: Radius.circular(3.w),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Text(
              displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? Colors.white : _plPurple,
                fontSize: 7.5.sp,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),

          // ── Points Box (Premium Purple) ──────────
          Container(
            width: double.infinity,
            margin: EdgeInsets.symmetric(horizontal: 2.w),
            padding: EdgeInsets.symmetric(vertical: 2.h),
            decoration: BoxDecoration(
              color: _plPurple,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(3.w)),
              border: Border.all(
                color: isDark ? Colors.white10 : _plPurple,
                width: 0.5,
              ),
            ),
            child: Text(
              pts.toString().toArabicNumbers(context),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 8.5.sp,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Sub card ───────────────────────────────────────────────────────────────

  Widget _buildSubCard(
    BuildContext context,
    Map<String, dynamic> player,
    bool isDark,
  ) {
    // Reuse _pitchPlayer for perfect design consistency between pitch and dugout
    final pos = _getPositionShort(player);
    return _pitchPlayer(context, player, _posColor(pos));
  }

  // ── List View ─────────────────────────────────────────────────────────────

  Widget _buildListView(
    BuildContext context,
    List<Map<String, dynamic>> gks,
    List<Map<String, dynamic>> defs,
    List<Map<String, dynamic>> mids,
    List<Map<String, dynamic>> fwds,
    List<dynamic> bench,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildListSection('GOALKEEPERS', gks, isDark),
          _buildListSection('DEFENDERS', defs, isDark),
          _buildListSection('MIDFIELDERS', mids, isDark),
          _buildListSection('FORWARDS', fwds, isDark),
          if (bench.isNotEmpty)
            _buildListSection(
              'BENCH',
              bench.map((e) => e as Map<String, dynamic>).toList(),
              isDark,
            ),
        ],
      ),
    );
  }

  Widget _buildListSection(
    String title,
    List<Map<String, dynamic>> players,
    bool isDark,
  ) {
    if (players.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 12.h),
          child: Text(
            title,
            style: TextStyle(
              color: isDark ? Colors.white70 : _plPurple.withOpacity(0.6),
              fontSize: 11.sp,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
            borderRadius: BorderRadius.circular(12.w),
            border: Border.all(
              color: isDark ? Colors.white10 : Colors.grey.withOpacity(0.1),
            ),
          ),
          child: Column(
            children: List.generate(players.length, (i) {
              final p = players[i];
              return _buildListPlayerRow(
                context,
                p,
                isDark,
                isLast: i == players.length - 1,
              );
            }),
          ),
        ),
        SizedBox(height: 8.h),
      ],
    );
  }

  Widget _buildListPlayerRow(
    BuildContext context,
    Map<String, dynamic> player,
    bool isDark, {
    bool isLast = false,
  }) {
    final name = player['name']?.toString() ?? '';
    final pts = player['actual_points'] ?? player['suggested_points'] ?? 0;
    final team = player['team_name'] ?? player['team'] ?? '';
    final pos = player['position_group']?.toString() ?? 'UNK';

    return GestureDetector(
      onTap: () => _showPlayerDetails(context, player),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          border:
              isLast
                  ? null
                  : Border(
                    bottom: BorderSide(
                      color:
                          isDark
                              ? Colors.white10
                              : Colors.grey.withOpacity(0.1),
                    ),
                  ),
        ),
        child: Row(
          children: [
            if (player['team_logo'] != null &&
                player['team_logo'].toString().isNotEmpty)
              Image.network(
                player['team_logo'],
                width: 24.w,
                height: 24.w,
                fit: BoxFit.contain,
                errorBuilder: (c, e, s) => _shimmerBox(24.w, 24.w, radius: 6),
              )
            else
              _shimmerBox(24.w, 24.w, radius: 6),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ArabicNameExtension(name).toArabicName(context),
                    style: TextStyle(
                      color: isDark ? Colors.white : _plPurple,
                      fontSize: 11.5.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    ArabicNameExtension(team).toArabicName(context),
                    style: TextStyle(
                      color: isDark ? Colors.white54 : Colors.black54,
                      fontSize: 9.sp,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: _posColor(pos).withOpacity(0.1),
                borderRadius: BorderRadius.circular(6.w),
              ),
              child: Text(
                pts.toString().toArabicNumbers(context),
                style: TextStyle(
                  color: _posColor(pos),
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPlayerDetails(BuildContext context, Map<String, dynamic> player) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final name = player['name']?.toString() ?? '';
    final pts = player['actual_points'] ?? player['suggested_points'] ?? 0;
    final pos = player['position_group']?.toString() ?? 'UNK';
    final team = player['team_name'] ?? player['team'] ?? '';
    final events = (player['events'] as List<dynamic>?) ?? [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            height: MediaQuery.of(context).size.height * 0.6,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1B4B) : Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24.w)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              children: [
                SizedBox(height: 12.h),
                Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color:
                        isDark ? Colors.white24 : Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(height: 24.h),
                // Player Header
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: Row(
                    children: [
                      CustomPaint(
                        size: Size(50.w, 50.w),
                        painter: _JerseyPainter(
                          color: _posColor(pos),
                          isGk: pos == 'GK',
                        ),
                      ),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ArabicNameExtension(name).toArabicName(context),
                              style: TextStyle(
                                color: isDark ? Colors.white : _plPurple,
                                fontSize: 20.sp,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              ArabicNameExtension(team).toArabicName(context) +
                                  " • " +
                                  pos,
                              style: TextStyle(
                                color: isDark ? Colors.white70 : Colors.black54,
                                fontSize: 13.sp,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _buildTotalPtsBox(
                        pts.toString().toArabicNumbers(context),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 32.h),
                // Events / Stats
                Expanded(
                  child:
                      events.isEmpty
                          ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.analytics_outlined,
                                  color: Colors.grey.withOpacity(0.3),
                                  size: 48.w,
                                ),
                                SizedBox(height: 16.h),
                                Text(
                                  'No detailed events yet',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 14.sp,
                                  ),
                                ),
                              ],
                            ),
                          )
                          : ListView.builder(
                            padding: EdgeInsets.symmetric(horizontal: 24.w),
                            itemCount: events.length,
                            itemBuilder: (context, i) {
                              final e = events[i].toString();
                              return Padding(
                                padding: EdgeInsets.only(bottom: 12.h),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.check_circle_outline,
                                      color: _plGreen,
                                      size: 18.w,
                                    ),
                                    SizedBox(width: 12.w),
                                    Text(
                                      e,
                                      style: TextStyle(
                                        color:
                                            isDark
                                                ? Colors.white
                                                : Colors.black87,
                                        fontSize: 14.sp,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                ),
                SizedBox(height: 20.h),
              ],
            ),
          ),
    );
  }

  // ── Loading / Error ────────────────────────────────────────────────────────

  Widget _buildLoading() {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        children: [
          SizedBox(height: 20.h),
          // Header shimmer
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _shimmerBox(40.w, 40.h, radius: 8),
                _shimmerBox(100.w, 70.h, radius: 12),
                _shimmerBox(40.w, 40.h, radius: 8),
              ],
            ),
          ),
          SizedBox(height: 32.h),
          // Toggle shimmer
          Center(child: _shimmerBox(220.w, 40.h, radius: 20)),
          SizedBox(height: 32.h),
          // Pitch shimmer
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: _shimmerBox(double.infinity, 450.h, radius: 12),
          ),
        ],
      ),
    );
  }

  Widget _shimmerBox(double w, double h, {double radius = 4}) {
    return AnimatedBuilder(
      animation: _shimmerCtrl,
      builder: (context, child) {
        final gradient = LinearGradient(
          colors: [
            Colors.grey.withOpacity(0.1),
            Colors.grey.withOpacity(0.2),
            Colors.grey.withOpacity(0.1),
          ],
          stops: [
            math.max(0, _shimmerCtrl.value - 0.3),
            _shimmerCtrl.value,
            math.min(1, _shimmerCtrl.value + 0.3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );

        return Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(radius.w),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(radius.w),
            child: ShaderMask(
              shaderCallback: (bounds) => gradient.createShader(bounds),
              blendMode: BlendMode.srcATop,
              child: Container(color: Colors.white),
            ),
          ),
        );
      },
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.emoji_events_outlined,
              size: 60.w,
              color: const Color(0xFF7C3AED).withOpacity(0.35),
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
                backgroundColor: const Color(0xFF7C3AED),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.w),
                ),
              ),
              onPressed: _fetch,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  PITCH PAINTER
// ─────────────────────────────────────────────────────────────────────────────

class _PitchPainter extends CustomPainter {
  static const Color _dark = Color(0xFF008D46);
  static const Color _light = Color(0xFF059A4E);

  @override
  void paint(Canvas canvas, Size size) {
    final W = size.width;
    final H = size.height;
    const margin = 8.0;

    // ── Alternating grass stripes ─────────────────────────────────────────
    final stripeCount = 14;
    final stripeH = H / stripeCount;
    for (int i = 0; i < stripeCount; i++) {
      final paint = Paint()..color = i.isEven ? _dark : _light;
      canvas.drawRect(Rect.fromLTWH(0, i * stripeH, W, stripeH), paint);
    }

    final linePaint =
        Paint()
          ..color = Colors.white.withOpacity(0.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;

    // ── Field Perimeter ───────────────────────────────────────────────────
    canvas.drawRect(
      Rect.fromLTWH(margin, margin, W - 2 * margin, H - 2 * margin),
      linePaint,
    );

    // ── Midfield line ─────────────────────────────────────────────────────
    canvas.drawLine(
      Offset(margin, H / 2),
      Offset(W - margin, H / 2),
      linePaint,
    );

    // ── Centre circle ─────────────────────────────────────────────────────
    canvas.drawCircle(Offset(W / 2, H / 2), W * 0.16, linePaint);
    canvas.drawCircle(
      Offset(W / 2, H / 2),
      3.5,
      Paint()..color = Colors.white.withOpacity(0.8),
    );

    // ── Penalty boxes ─────────────────────────────────────────────────────
    final boxW = W * 0.58;
    final boxH = H * 0.16;
    final boxX = (W - boxW) / 2;

    // Top penalty box
    canvas.drawRect(Rect.fromLTWH(boxX, margin, boxW, boxH), linePaint);
    // Bottom penalty box
    canvas.drawRect(
      Rect.fromLTWH(boxX, H - margin - boxH, boxW, boxH),
      linePaint,
    );

    // ── Goal boxes ────────────────────────────────────────────────────────
    final goalW = W * 0.28;
    final goalH = H * 0.055;
    final goalX = (W - goalW) / 2;

    canvas.drawRect(Rect.fromLTWH(goalX, margin, goalW, goalH), linePaint);
    canvas.drawRect(
      Rect.fromLTWH(goalX, H - margin - goalH, goalW, goalH),
      linePaint,
    );

    // ── Penalty spots ─────────────────────────────────────────────────────
    final spotPaint = Paint()..color = Colors.white.withOpacity(0.7);
    canvas.drawCircle(Offset(W / 2, margin + boxH * 0.65), 3, spotPaint);
    canvas.drawCircle(Offset(W / 2, H - margin - boxH * 0.65), 3, spotPaint);

    // ── Corner arcs ───────────────────────────────────────────────────────
    const cr = 10.0;
    canvas.drawArc(
      Rect.fromCircle(center: Offset(margin, margin), radius: cr),
      0,
      math.pi / 2,
      false,
      linePaint,
    );
    canvas.drawArc(
      Rect.fromCircle(center: Offset(W - margin, margin), radius: cr),
      math.pi / 2,
      math.pi / 2,
      false,
      linePaint,
    );
    canvas.drawArc(
      Rect.fromCircle(center: Offset(margin, H - margin), radius: cr),
      -math.pi / 2,
      -math.pi / 2,
      false,
      linePaint,
    );
    canvas.drawArc(
      Rect.fromCircle(center: Offset(W - margin, H - margin), radius: cr),
      -math.pi,
      math.pi / 2,
      false,
      linePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
//  JERSEY PAINTER
// ─────────────────────────────────────────────────────────────────────────────

class _JerseyPainter extends CustomPainter {
  final Color color;
  final bool isGk;

  _JerseyPainter({required this.color, this.isGk = false});

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..style = PaintingStyle.fill;

    final path = Path();
    final w = size.width;
    final h = size.height;

    // Body
    path.moveTo(w * 0.2, h * 0.2);
    path.lineTo(w * 0.8, h * 0.2);
    path.lineTo(w * 0.8, h * 0.9);
    path.lineTo(w * 0.2, h * 0.9);
    path.close();

    // Sleeves
    path.moveTo(w * 0.2, h * 0.2);
    path.lineTo(0, h * 0.4);
    path.lineTo(w * 0.1, h * 0.5);
    path.lineTo(w * 0.2, h * 0.4);

    path.moveTo(w * 0.8, h * 0.2);
    path.lineTo(w, h * 0.4);
    path.lineTo(w * 0.9, h * 0.5);
    path.lineTo(w * 0.8, h * 0.4);

    canvas.drawPath(path, paint);

    // Collar detail
    final detailPaint =
        Paint()
          ..color = Colors.black.withOpacity(0.15)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;

    canvas.drawPath(path, detailPaint);

    // Neck
    final neckPath = Path();
    neckPath.moveTo(w * 0.4, h * 0.2);
    neckPath.quadraticBezierTo(w * 0.5, h * 0.35, w * 0.6, h * 0.2);
    canvas.drawPath(neckPath, Paint()..color = Colors.black.withOpacity(0.2));

    if (isGk) {
      // Add subtle pattern for GKs
      final patternPaint =
          Paint()
            ..color = Colors.white.withOpacity(0.2)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1;
      for (double i = 0.3; i < 0.8; i += 0.2) {
        canvas.drawLine(
          Offset(w * 0.2, h * i),
          Offset(w * 0.8, h * i),
          patternPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
