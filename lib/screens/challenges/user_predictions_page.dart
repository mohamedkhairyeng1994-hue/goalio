import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants/constants.dart';
import '../../core/services/api_service.dart';
import '../../core/utils/size_config.dart';
import '../../core/utils/time_utils.dart';
import '../../core/utils/number_utils.dart';
import '../../core/utils/name_translator.dart';
import '../../l10n/app_localizations.dart';
import 'challenge_providers.dart';

class UserPredictionsPage extends ConsumerStatefulWidget {
  final int userId;
  final String userName;
  final int? leagueId;
  final DateTime? initialDate;

  const UserPredictionsPage({
    super.key,
    required this.userId,
    required this.userName,
    this.leagueId,
    this.initialDate,
  });

  @override
  ConsumerState<UserPredictionsPage> createState() => _UserPredictionsPageState();
}

class _UserPredictionsPageState extends ConsumerState<UserPredictionsPage> {
  bool _isLoading = true;
  List<dynamic> _groupedData = [];
  String? _error;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate ?? DateTime.now();
    _fetchData();
  }

  Future<void> _fetchData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final dateStr = DateFormat('yyyy-MM-dd', 'en_US').format(_selectedDate);
      final data = await ApiService.getUserPredictions(
        widget.userId,
        leagueId: widget.leagueId,
        date: dateStr,
      );
      if (mounted) {
        setState(() {
          _groupedData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _onDateSelected(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
    _fetchData();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final availableDates = ref.watch(challengeMatchDatesProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.userName,
              style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            Text(
              l10n.userPredictions,
              style: TextStyle(
                fontSize: 10.sp,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).cardColor,
        elevation: 0,
        centerTitle: false,
      ),
      body: Column(
        children: [
          _buildDateSelector(availableDates, isDark, l10n),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: GoalioColors.greenAccent))
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(l10n.errorPrefix(_error!), textAlign: TextAlign.center),
                            TextButton(onPressed: _fetchData, child: Text(l10n.retry)),
                          ],
                        ),
                      )
                    : _groupedData.isEmpty
                        ? _buildEmptyState(l10n, isDark)
                        : RefreshIndicator(
                            onRefresh: _fetchData,
                            color: GoalioColors.greenAccent,
                            child: ListView.builder(
                              padding: EdgeInsets.fromLTRB(10.w, 12.h, 10.w, 100.h),
                              itemCount: _groupedData.length,
                              itemBuilder: (context, index) {
                                final group = _groupedData[index];
                                return _buildDateGroup(group, isDark, l10n);
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy_rounded, size: 54.w, color: isDark ? Colors.white10 : Colors.black12),
          SizedBox(height: 12.h),
          Text(
            l10n.noPredictionsFound,
            style: TextStyle(fontSize: 12.sp, color: isDark ? Colors.white38 : Colors.black38),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector(List<DateTime> availableDates, bool isDark, AppLocalizations l10n) {
    // Normalize dates to midnight for consistent comparison
    final normalizedSelected = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    final uniqueDates = availableDates.map((d) => DateTime(d.year, d.month, d.day)).toSet().toList();
    
    // Sort ASCENDING (Earliest to Latest)
    uniqueDates.sort((a, b) => a.compareTo(b));

    if (uniqueDates.isEmpty) return const SizedBox.shrink();

    final currentIndex = uniqueDates.indexWhere((d) => d.isAtSameMomentAs(normalizedSelected));
    final displayDate = DateFormat('EEE, dd MMM').format(_selectedDate);

    return Container(
      padding: EdgeInsets.symmetric(vertical: 6.h, horizontal: 16.w),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Previous Date (Goes older)
          _buildNavButton(
            icon: Icons.chevron_left_rounded,
            onPressed: () => _onDateSelected(uniqueDates[currentIndex - 1]),
            disabled: currentIndex <= 0,
            isDark: isDark,
          ),
          
          GestureDetector(
            onTap: () async {
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: uniqueDates.first,
                lastDate: uniqueDates.last,
              );
              if (picked != null) {
                _onDateSelected(picked);
              }
            },
            child: Column(
              children: [
                Text(
                  l10n.selectDate.toUpperCase(),
                  style: TextStyle(
                    fontSize: 7.sp,
                    fontWeight: FontWeight.w900,
                    color: GoalioColors.greenAccent,
                    letterSpacing: 1.2,
                  ),
                ),
                SizedBox(height: 1.h),
                Text(
                  displayDate.toArabicNumbers(context),
                  style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87),
                ),
              ],
            ),
          ),
          
          // Next Date (Goes newer)
          _buildNavButton(
            icon: Icons.chevron_right_rounded,
            onPressed: () => _onDateSelected(uniqueDates[currentIndex + 1]),
            disabled: currentIndex == -1 || currentIndex >= uniqueDates.length - 1,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildNavButton({required IconData icon, required VoidCallback onPressed, bool disabled = false, required bool isDark}) {
    return IconButton(
      onPressed: disabled ? null : onPressed,
      icon: Icon(icon),
      color: disabled ? (isDark ? Colors.white12 : Colors.black12) : GoalioColors.greenAccent,
      iconSize: 24.w,
    );
  }

  Widget _buildDateGroup(dynamic group, bool isDark, AppLocalizations l10n) {
    final matches = group['matches'] as List;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...matches.map((m) => _buildMatchTile(m, isDark, l10n)),
        SizedBox(height: 16.h),
      ],
    );
  }

  Widget _buildMatchTile(dynamic match, bool isDark, AppLocalizations l10n) {
    final predictions = match['predictions'] as List;
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12.w),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04),
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: ExpansionTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.w)),
          collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.w)),
          tilePadding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
          title: _buildPremiumMatchHeader(match, isDark),
          trailing: _buildMatchTrailing(match, isDark),
          childrenPadding: EdgeInsets.fromLTRB(14.w, 0, 14.w, 14.h),
          expandedAlignment: Alignment.topCenter,
          children: [
            Divider(height: 1, color: isDark ? Colors.white10 : Colors.black12),
            SizedBox(height: 12.h),
            if (predictions.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 8.h),
                child: Text(
                  l10n.noPredictionsFound,
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: isDark ? Colors.white38 : Colors.black38,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              )
            else
              ...List.generate(predictions.length, (i) => _buildPredictionRow(predictions[i], i + 1, isDark, l10n)),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumMatchHeader(dynamic match, bool isDark) {
    final homeScore = (match['home_score'] ?? '-').toString();
    final awayScore = (match['away_score'] ?? '-').toString();
    final status = match['status']?.toString() ?? 'TBD';
    final isFinished = isFinishedStatus(status);
    final isLive = isLiveStatus(status);

    return Row(
      children: [
        // Home Name
        Expanded(
          flex: 5,
          child: Text(
            ArabicNameExtension(match['home_team'] ?? '').toArabicName(context),
            style: TextStyle(
              fontSize: 10.sp,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : Colors.black87,
              height: 1.2,
            ),
            textAlign: TextAlign.end,
          ),
        ),
        
        SizedBox(width: 6.w),
        
        // Home Logo
        _buildTeamLogo(match['home_logo']),
        
        SizedBox(width: 6.w),

        // Score / Status Box
        Container(
          width: 38.w,
          padding: EdgeInsets.symmetric(vertical: 3.h),
          decoration: BoxDecoration(
            color: isLive ? Colors.red.withValues(alpha: 0.08) : (isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.04)),
            borderRadius: BorderRadius.circular(6.w),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isFinished || isLive)
                Text("$homeScore-$awayScore".toArabicNumbers(context), style: _scoreStyle(isDark, isLive))
              else
                Text(
                  formatMatchTime(match['time']).toArabicNumbers(context),
                  style: TextStyle(
                    fontSize: 9.sp,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
              if (isLive)
                Text(
                  localizeMatchStatus(context, status),
                  style: TextStyle(
                    fontSize: 6.sp,
                    fontWeight: FontWeight.w900,
                    color: Colors.red,
                  ),
                ),
            ],
          ),
        ),

        SizedBox(width: 6.w),

        // Away Logo
        _buildTeamLogo(match['away_logo']),

        SizedBox(width: 6.w),

        // Away Name
        Expanded(
          flex: 5,
          child: Text(
            ArabicNameExtension(match['away_team'] ?? '').toArabicName(context),
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : Colors.black87,
              height: 1.2,
            ),
            textAlign: TextAlign.start,
          ),
        ),
      ],
    );
  }

  Widget _buildMatchTrailing(dynamic match, bool isDark) {
    final points = (match['total_points'] as num).toInt();
    final dividerColor = isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.06);

    return Container(
      padding: EdgeInsets.only(left: 4.w),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Vertical Line
          Container(height: 38.h, width: 1, color: dividerColor),
          SizedBox(width: 10.w),
          
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: points > 0 ? GoalioColors.greenAccent.withValues(alpha: 0.1) : (isDark ? Colors.white10 : Colors.black12),
                  borderRadius: BorderRadius.circular(6.w),
                ),
                child: Text(
                  "+$points".toArabicNumbers(context),
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w900,
                    color: points > 0 ? GoalioColors.greenAccent : (isDark ? Colors.white24 : Colors.black26),
                  ),
                ),
              ),
              SizedBox(height: 4.h),
              Icon(Icons.keyboard_arrow_down, size: 16.w, color: isDark ? Colors.white24 : Colors.black26),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTeamLogo(String? logo) {
    return logo != null && logo.isNotEmpty
        ? Image.network(logo, width: 18.w, height: 18.w, errorBuilder: (_, __, ___) => Icon(Icons.shield, size: 18.w, color: Colors.grey))
        : Icon(Icons.shield, size: 18.w, color: Colors.grey);
  }

  TextStyle _scoreStyle(bool isDark, bool isLive) {
    return TextStyle(
      fontSize: 11.sp,
      fontWeight: FontWeight.w900,
      color: isLive ? Colors.red : (isDark ? Colors.white : Colors.black),
      fontFamily: 'Montserrat',
      letterSpacing: -0.5,
    );
  }

  Widget _buildPredictionRow(dynamic pred, int index, bool isDark, AppLocalizations l10n) {
    final isCorrect = pred['is_correct'] == true;
    final points = (pred['points_earned'] as num).toInt();

    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.02) : Colors.black.withValues(alpha: 0.015),
          borderRadius: BorderRadius.circular(12.w),
          border: Border.all(
            color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.03),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Question Number
            Container(
              width: 22.w,
              height: 22.w,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: Text(
                index.toString().toArabicNumbers(context),
                style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.w900, color: isDark ? Colors.white38 : Colors.black38),
              ),
            ),
            
            SizedBox(width: 12.w),
            
            // Status Icon
            Padding(
              padding: EdgeInsets.only(top: 2.h),
              child: Icon(
                isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                size: 16.w,
                color: isCorrect ? Colors.green.withValues(alpha: 0.8) : Colors.red.withValues(alpha: 0.8),
              ),
            ),
            
            SizedBox(width: 12.w),
            
            // Question & Answer
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ArabicNameExtension(pred['question'].toString()).toArabicName(context),
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: isDark ? Colors.white70 : Colors.black87,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Row(
                    children: [
                      Container(
                        width: 4.w,
                        height: 4.w,
                        decoration: BoxDecoration(color: isDark ? Colors.white24 : Colors.black26, shape: BoxShape.circle),
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        ArabicNameExtension(pred['answer'].toString()).toArabicName(context),
                        style: TextStyle(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w900,
                          color: GoalioColors.greenAccent,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            if (points > 0)
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "+$points".toArabicNumbers(context),
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w900,
                      color: Colors.green,
                    ),
                  ),
                  Text(
                    l10n.ptsShort.toUpperCase(),
                    style: TextStyle(
                      fontSize: 8.sp,
                      fontWeight: FontWeight.w900,
                      color: Colors.green.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
