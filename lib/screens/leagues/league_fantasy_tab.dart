import 'dart:convert';
import 'dart:math' as math;
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
  String? _error;
  Map<String, dynamic> _data = {};

  late AnimationController _shimmerCtrl;

  // ── Palette ────────────────────────────────────────────────────────────────
  static const Color _gold       = Color(0xFFFFD700);
  static const Color _goldDark   = Color(0xFFB8860B);
  static const Color _purple     = Color(0xFF7C3AED);
  static const Color _purpleLight= Color(0xFFA78BFA);
  static const Color _green      = Color(0xFF00FF85);

  // Position colours
  static const Color _gkColor   = Color(0xFFF59E0B);
  static const Color _defColor  = Color(0xFF3B82F6);
  static const Color _midColor  = Color(0xFF10B981);
  static const Color _fwdColor  = Color(0xFFEF4444);

  // Pitch colours
  static const Color _pitchDark  = Color(0xFF1A6B3C);
  static const Color _pitchLight = Color(0xFF1E7D45);

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
    setState(() { _isLoading = true; _error = null; });
    try {
      final uri = Uri.parse(
        '${ApiConstants.authBaseUrl}/fantasy/league/${widget.leagueId}/round-team',
      );
      final resp = await http
          .get(uri, headers: await ApiService.reqHeaders)
          .timeout(const Duration(seconds: 25));

      if (!mounted) return;
      if (resp.statusCode == 200) {
        setState(() {
          _data = json.decode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Could not load Dream Team (${resp.statusCode})';
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() { _error = 'Connection error.'; _isLoading = false; });
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Color _posColor(String? group) {
    switch (group) {
      case 'GK':  return _gkColor;
      case 'DEF': return _defColor;
      case 'MID': return _midColor;
      case 'FWD': return _fwdColor;
      default:    return Colors.grey;
    }
  }

  List<Map<String, dynamic>> _group(String pos) {
    final starting = (_data['starting'] as List<dynamic>?) ?? [];
    return starting
        .map((e) => e as Map<String, dynamic>)
        .where((p) => (p['position_group'] ?? '') == pos)
        .toList();
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return _buildLoading();
    if (_error != null) return _buildError();

    final isDark     = Theme.of(context).brightness == Brightness.dark;
    final bench      = (_data['bench'] as List<dynamic>?) ?? [];
    final totalPts   = _data['total_points'] ?? 0;
    final formation  = _data['formation']?.toString() ?? '4-3-3';
    final roundDate  = _data['round_date']?.toString() ?? '';
    final matchCount = _data['matches_count'] ?? 0;

    final gks  = _group('GK');
    final defs = _group('DEF');
    final mids = _group('MID');
    final fwds = _group('FWD');

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(parent: ClampingScrollPhysics()),
      child: Column(
        children: [
          // ── Header ─────────────────────────────────────────────────────────
          _buildHeader(context, totalPts, formation, roundDate, matchCount),

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
                    color: _purpleLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(width: 8.w),
                Text(
                  AppLocalizations.of(context)!.dreamTeamSubs.toUpperCase(),
                  style: TextStyle(
                    color: _purpleLight,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 12.h),

          // ── Subs row ───────────────────────────────────────────────────────
          SizedBox(
            height: 110.h,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              itemCount: bench.length,
              separatorBuilder: (_, __) => SizedBox(width: 10.w),
              itemBuilder: (_, i) => _buildSubCard(
                context,
                bench[i] as Map<String, dynamic>,
                isDark,
              ),
            ),
          ),

          SizedBox(height: 32.h),
        ],
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
    return AnimatedBuilder(
      animation: _shimmerCtrl,
      builder: (_, __) => Container(
        margin: EdgeInsets.all(16.w),
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0D0B1A), Color(0xFF1A1240), Color(0xFF0D0B1A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20.w),
          border: Border.all(color: _purpleLight.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: _purple.withValues(alpha: 0.25),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            // Trophy icon
            Container(
              width: 52.w,
              height: 52.w,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_gold, _goldDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14.w),
                boxShadow: [
                  BoxShadow(
                    color: _gold.withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(Icons.emoji_events_rounded, color: Colors.white, size: 28.w),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Shimmer title
                  ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: const [_gold, Colors.white, _gold],
                      stops: [
                        math.max(0.0, _shimmerCtrl.value - 0.3),
                        _shimmerCtrl.value,
                        math.min(1.0, _shimmerCtrl.value + 0.3),
                      ],
                    ).createShader(bounds),
                    child: Text(
                      AppLocalizations.of(context)!.dreamTeam,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.0,
                      ),
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    AppLocalizations.of(context)!.dreamTeamRound,
                    style: TextStyle(
                      color: _purpleLight.withValues(alpha: 0.8),
                      fontSize: 10.sp,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // PL badge
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 3.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3D195B),
                    borderRadius: BorderRadius.circular(6.w),
                    border: Border.all(color: _green, width: 1),
                  ),
                  child: Text(
                    'PL',
                    style: TextStyle(
                      color: _green,
                      fontSize: 9.sp,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                SizedBox(height: 6.h),
                // Total points
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4C1D95), Color(0xFF7C3AED)],
                    ),
                    borderRadius: BorderRadius.circular(8.w),
                    boxShadow: [
                      BoxShadow(
                        color: _purple.withValues(alpha: 0.35),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star_rounded, color: _gold, size: 12.w),
                      SizedBox(width: 4.w),
                      Text(
                        totalPts.toString().toArabicNumbers(context),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w900,
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
      child: AspectRatio(
        aspectRatio: 0.62,
        child: CustomPaint(
          painter: _PitchPainter(),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 10.h),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // FWD row (top)
                _playerRow(context, fwds, _fwdColor),
                // MID row
                _playerRow(context, mids, _midColor),
                // DEF row
                _playerRow(context, defs, _defColor),
                // GK row (bottom)
                _playerRow(context, gks, _gkColor),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _playerRow(
    BuildContext context,
    List<Map<String, dynamic>> players,
    Color color,
  ) {
    if (players.isEmpty) return const SizedBox.shrink();
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: players.map((p) => _pitchPlayer(context, p, color)).toList(),
    );
  }

  Widget _pitchPlayer(
    BuildContext context,
    Map<String, dynamic> player,
    Color color,
  ) {
    final name     = player['name']?.toString() ?? '';
    final pts      = player['actual_points'] ?? player['suggested_points'] ?? 0;
    final team     = player['team']?.toString() ?? '';
    final isCap    = player['is_captain'] == true;

    // Last name for display
    final parts    = name.trim().split(' ');
    final lastName = parts.length > 1 ? parts.last : name;
    final displayName = ArabicNameExtension(lastName).toArabicName(context);

    return SizedBox(
      width: 64.w,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Jersey + captain badge
          Stack(
            clipBehavior: Clip.none,
            children: [
              // Jersey icon
              Container(
                width: 44.w,
                height: 44.w,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color.withValues(alpha: 0.85), color],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12.w),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.45),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.35),
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.sports_soccer_rounded,
                    color: Colors.white.withValues(alpha: 0.9),
                    size: 22.w,
                  ),
                ),
              ),
              // Captain badge
              if (isCap)
                Positioned(
                  top: -4.h,
                  right: -4.w,
                  child: Container(
                    width: 16.w,
                    height: 16.w,
                    decoration: const BoxDecoration(
                      color: _gold,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        'C',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 7.sp,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 5.h),
          // Player name
          Container(
            padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(4.w),
            ),
            child: Text(
              displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 9.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(height: 3.h),
          // Points badge
          Container(
            padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 2.h),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4C1D95), Color(0xFF7C3AED)],
              ),
              borderRadius: BorderRadius.circular(5.w),
              boxShadow: [
                BoxShadow(
                  color: _purple.withValues(alpha: 0.4),
                  blurRadius: 6,
                ),
              ],
            ),
            child: Text(
              pts.toString().toArabicNumbers(context),
              style: TextStyle(
                color: Colors.white,
                fontSize: 10.sp,
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
    final name    = player['name']?.toString() ?? '';
    final pos     = player['position_group']?.toString() ?? 'UNK';
    final pts     = player['actual_points'] ?? player['suggested_points'] ?? 0;
    final team    = player['team']?.toString() ?? '';
    final color   = _posColor(pos);

    final parts    = name.trim().split(' ');
    final lastName = parts.length > 1 ? parts.last : name;

    return Container(
      width: 78.w,
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1A2E) : Colors.white,
        borderRadius: BorderRadius.circular(14.w),
        border: Border.all(
          color: isDark ? const Color(0xFF2A2840) : Colors.grey.withValues(alpha: 0.15),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Position colored icon
          Container(
            width: 36.w,
            height: 36.w,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withValues(alpha: 0.7), color],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10.w),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.35),
                  blurRadius: 6,
                ),
              ],
            ),
            child: Center(
              child: Text(
                pos == 'UNK' ? '?' : pos,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 9.sp,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            ArabicNameExtension(lastName).toArabicName(context),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyMedium?.color,
              fontSize: 10.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4C1D95), Color(0xFF7C3AED)],
              ),
              borderRadius: BorderRadius.circular(6.w),
            ),
            child: Text(
              pts.toString().toArabicNumbers(context),
              style: TextStyle(
                color: Colors.white,
                fontSize: 11.sp,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Loading / Error ────────────────────────────────────────────────────────

  Widget _buildLoading() {
    return const Center(
      child: CircularProgressIndicator(color: Color(0xFF7C3AED)),
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
              color: const Color(0xFF7C3AED).withValues(alpha: 0.35),
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
  static const Color _dark  = Color(0xFF1A6B3C);
  static const Color _light = Color(0xFF1E7D45);
  static const Color _line  = Colors.white;

  @override
  void paint(Canvas canvas, Size size) {
    final W = size.width;
    final H = size.height;

    // ── Alternating grass stripes ─────────────────────────────────────────
    final stripeCount = 10;
    final stripeH = H / stripeCount;
    for (int i = 0; i < stripeCount; i++) {
      final paint = Paint()
        ..color = i.isEven ? _dark : _light;
      canvas.drawRect(Rect.fromLTWH(0, i * stripeH, W, stripeH), paint);
    }

    // ── Outer border ───────────────────────────────────────────────────────
    final linePaint = Paint()
      ..color = _line.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    const margin = 10.0;
    final field = Rect.fromLTWH(margin, margin, W - margin * 2, H - margin * 2);
    canvas.drawRect(field, linePaint);

    // ── Centre line ───────────────────────────────────────────────────────
    canvas.drawLine(
      Offset(margin, H / 2),
      Offset(W - margin, H / 2),
      linePaint,
    );

    // ── Centre circle ─────────────────────────────────────────────────────
    canvas.drawCircle(
      Offset(W / 2, H / 2),
      W * 0.14,
      linePaint,
    );
    // Centre dot
    canvas.drawCircle(
      Offset(W / 2, H / 2),
      3,
      Paint()..color = _line.withValues(alpha: 0.55),
    );

    // ── Penalty boxes ─────────────────────────────────────────────────────
    final boxW  = W * 0.55;
    final boxH  = H * 0.16;
    final boxX  = (W - boxW) / 2;

    // Top penalty box
    canvas.drawRect(
      Rect.fromLTWH(boxX, margin, boxW, boxH),
      linePaint,
    );
    // Bottom penalty box
    canvas.drawRect(
      Rect.fromLTWH(boxX, H - margin - boxH, boxW, boxH),
      linePaint,
    );

    // ── Goal boxes ────────────────────────────────────────────────────────
    final goalW = W * 0.25;
    final goalH = H * 0.06;
    final goalX = (W - goalW) / 2;

    canvas.drawRect(
      Rect.fromLTWH(goalX, margin, goalW, goalH),
      linePaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(goalX, H - margin - goalH, goalW, goalH),
      linePaint,
    );

    // ── Penalty spots ─────────────────────────────────────────────────────
    final spotPaint = Paint()..color = _line.withValues(alpha: 0.55);
    canvas.drawCircle(Offset(W / 2, margin + boxH * 0.65), 2.5, spotPaint);
    canvas.drawCircle(Offset(W / 2, H - margin - boxH * 0.65), 2.5, spotPaint);

    // ── Corner arcs ───────────────────────────────────────────────────────
    final cornerPaint = Paint()
      ..color = _line.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    const cr = 10.0;
    canvas.drawArc(Rect.fromCircle(center: Offset(margin, margin), radius: cr),
        0, math.pi / 2, false, cornerPaint);
    canvas.drawArc(Rect.fromCircle(center: Offset(W - margin, margin), radius: cr),
        math.pi / 2, math.pi / 2, false, cornerPaint);
    canvas.drawArc(Rect.fromCircle(center: Offset(margin, H - margin), radius: cr),
        -math.pi / 2, -math.pi / 2, false, cornerPaint);
    canvas.drawArc(
        Rect.fromCircle(center: Offset(W - margin, H - margin), radius: cr),
        -math.pi, math.pi / 2, false, cornerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
