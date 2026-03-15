import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/constants.dart';
import '../../../core/utils/size_config.dart';
import '../../../l10n/app_localizations.dart';
import '../challenge_providers.dart';
import 'match_item_widget.dart';

class UnifiedChallengeCard extends ConsumerWidget {
  final bool isDark;
  final DateTime selectedDate;
  final int datePoints;
  final int totalPoints;
  final AsyncValue<List<dynamic>> eplMatchesState;

  const UnifiedChallengeCard({
    super.key,
    required this.isDark,
    required this.selectedDate,
    required this.datePoints,
    required this.totalPoints,
    required this.eplMatchesState,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final datesAsync = ref.watch(allChallengeMatchesProvider);
    final isDatesLoading = datesAsync.isLoading;
    final availableDates = ref.watch(challengeMatchDatesProvider);
    final summary = ref.watch(challengeSummaryProvider);

    final currentDateNormalized = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    );

    DateTime? nearestDate;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    try {
      nearestDate = availableDates.firstWhere((d) => !d.isBefore(today));
    } catch (_) {
      if (availableDates.isNotEmpty) nearestDate = availableDates.last;
    }

    final bool canGoNext = nearestDate != null && currentDateNormalized.isBefore(nearestDate);
    final bool canGoBack = availableDates.any((d) => d.isBefore(currentDateNormalized));

    final bool isAtNextLimit = isDatesLoading || availableDates.isEmpty || !canGoNext;
    final bool isAtBackLimit = isDatesLoading || availableDates.isEmpty || !canGoBack;

    final isToday = selectedDate.year == now.year &&
        selectedDate.month == now.month &&
        selectedDate.day == now.day;

    String dateText = DateFormat('EEEE, dd MMM').format(selectedDate);
    if (isToday) {
      dateText = "${AppLocalizations.of(context)!.today}, ${DateFormat('dd MMM').format(selectedDate)}";
    } else {
      final tomorrow = now.add(const Duration(days: 1));
      if (selectedDate.year == tomorrow.year &&
          selectedDate.month == tomorrow.month &&
          selectedDate.day == tomorrow.day) {
        dateText = "${AppLocalizations.of(context)!.tomorrow}, ${DateFormat('dd MMM').format(selectedDate)}";
      }
    }

    final matches = eplMatchesState.value ?? [];
    final isEplMatchday = matches.isNotEmpty;

    final bool isAnyMatchStarted = matches.any((m) {
      final status = m['status']?.toString() ?? 'TBD';
      return status != 'PRE' && status != 'TBD' && status != 'VS' && status != 'Scheduled';
    });

    Color cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    Color accentColor = GoalioColors.greenAccent;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(32.w),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.04),
        ),
        boxShadow: [
          if (isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 30,
              offset: const Offset(0, 15),
            )
          else
            BoxShadow(
              color: const Color(0xFF64748B).withValues(alpha: 0.12),
              blurRadius: 25,
              offset: const Offset(0, 12),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. HEADER: DATE SELECTOR
          Container(
            padding: EdgeInsetsDirectional.fromSTEB(16.w, 14.h, 16.w, 14.h),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [
                        GoalioColors.greenAccent.withValues(alpha: 0.15),
                        GoalioColors.blueAccent.withValues(alpha: 0.15),
                      ]
                    : [
                        GoalioColors.greenAccent.withValues(alpha: 0.08),
                        GoalioColors.blueAccent.withValues(alpha: 0.08),
                      ],
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(32.w),
                topRight: Radius.circular(32.w),
              ),
            ),
            child: Row(
              children: [
                _buildCircleNavButton(
                  icon: Icons.chevron_left_rounded,
                  isDark: isDark,
                  disabled: isAtBackLimit,
                  onPressed: () {
                    ref.read(selectedChallengeDateProvider.notifier).previousDay();
                  },
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2024),
                        lastDate: DateTime.now(),
                        builder: (context, child) {
                          return Theme(
                            data: isDark
                                ? ThemeData.dark().copyWith(
                                    colorScheme: const ColorScheme.dark(
                                      primary: GoalioColors.greenAccent,
                                      surface: Color(0xFF1E293B),
                                    ),
                                  )
                                : ThemeData.light().copyWith(
                                    colorScheme: const ColorScheme.light(
                                      primary: GoalioColors.greenAccent,
                                    ),
                                  ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) {
                        ref.read(selectedChallengeDateProvider.notifier).selectDate(picked);
                      }
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.matchday,
                          style: TextStyle(
                            fontSize: 7.sp,
                            fontWeight: FontWeight.w900,
                            color: accentColor,
                            letterSpacing: 2.5,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          dateText,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w900,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                _buildCircleNavButton(
                  icon: Icons.chevron_right_rounded,
                  isDark: isDark,
                  disabled: isAtNextLimit,
                  onPressed: () {
                    ref.read(selectedChallengeDateProvider.notifier).nextDay();
                  },
                ),
              ],
            ),
          ),

          // 2. STATS DASHBOARD
          Padding(
            padding: EdgeInsetsDirectional.fromSTEB(15.w, 12.h, 15.w, 8.h),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: _buildStatCard(
                    label: AppLocalizations.of(context)!.points.toUpperCase(),
                    value: "$datePoints",
                    icon: Icons.bolt_rounded,
                    isDark: isDark,
                    accentColor: accentColor,
                    isLoading: false,
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  flex: 4,
                  child: _buildStatCard(
                    label: AppLocalizations.of(context)!.predictions.toUpperCase(),
                    value: "${summary['correct_predictions'] ?? 0}/${summary['total_predictions'] ?? 0}",
                    icon: Icons.check_circle_outline_rounded,
                    isDark: isDark,
                    accentColor: Colors.blueAccent,
                    isLoading: false,
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  flex: 3,
                  child: _buildStatCard(
                    label: AppLocalizations.of(context)!.overall.toUpperCase(),
                    value: _formatNumber(totalPoints),
                    icon: Icons.emoji_events_rounded,
                    isDark: isDark,
                    accentColor: const Color(0xFFFFB800),
                    isLoading: false,
                  ),
                ),
              ],
            ),
          ),

          // 3. MATCHES LISTING
          Padding(
            padding: EdgeInsets.fromLTRB(15.w, 15.h, 15.w, 24.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        AppLocalizations.of(context)!.predictAndEarn,
                        style: TextStyle(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white70 : const Color(0xFF475569),
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    if (isToday) ...[
                      SizedBox(width: 8.w),
                      _buildLiveBadge(context, isAnyMatchStarted),
                    ],
                  ],
                ),
                SizedBox(height: 16.h),
                if (!isEplMatchday)
                  _buildEmptyState(context, isDark)
                else
                  ...matches.map(
                    (match) => MatchItemWidget(match: match, isDark: isDark),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircleNavButton({
    required IconData icon,
    required bool isDark,
    required VoidCallback onPressed,
    bool disabled = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: disabled ? null : onPressed,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 36.w,
          height: 36.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
            border: Border.all(
              color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
            ),
          ),
          child: Icon(
            icon,
            size: 20.w,
            color: disabled ? (isDark ? Colors.white10 : Colors.black12) : GoalioColors.greenAccent,
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required IconData icon,
    required bool isDark,
    required Color accentColor,
    bool isLoading = false,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 8.w),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.02) : Colors.white,
        borderRadius: BorderRadius.circular(22.w),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0),
          width: 0.8,
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: const Color(0xFF64748B).withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 12.w, color: accentColor),
              SizedBox(width: 4.w),
              Flexible(
                child: Text(
                  label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 9.5.sp,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white70 : const Color(0xFF475569),
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 4.h),
          if (isLoading)
            Container(
              height: 26.sp,
              alignment: Alignment.center,
              child: SizedBox(
                width: 14.w,
                height: 14.w,
                child: CircularProgressIndicator(
                  color: accentColor,
                  strokeWidth: 2,
                ),
              ),
            )
          else
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 26.sp,
                  fontWeight: FontWeight.w900,
                  color: accentColor,
                  fontFamily: 'Montserrat',
                  letterSpacing: -0.8,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLiveBadge(BuildContext context, bool isLive) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isLive
              ? const [Color(0xFFFF4B4B), Color(0xFFFF0000)]
              : const [GoalioColors.greenAccent, Color(0xFF059669)],
        ),
        borderRadius: BorderRadius.circular(8.w),
        boxShadow: [
          BoxShadow(
            color: isLive
                ? Colors.red.withValues(alpha: 0.3)
                : GoalioColors.greenAccent.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isLive) ...[
            Container(
              width: 4.w,
              height: 4.w,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: 4.w),
          ],
          Text(
            isLive
                ? AppLocalizations.of(context)!.live.toUpperCase()
                : AppLocalizations.of(context)!.today.toUpperCase(),
            style: TextStyle(
              fontSize: 8.sp,
              fontWeight: FontWeight.w900,
              color: isLive ? Colors.white : Colors.black87,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 40.h),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.event_busy_rounded,
                size: 32.w,
                color: isDark ? Colors.white10 : Colors.black12,
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              AppLocalizations.of(context)!.noMatchesOnDate,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white38 : Colors.black38,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) return '${(number / 1000000).toStringAsFixed(1)}M';
    if (number >= 1000) return '${(number / 1000).toStringAsFixed(1)}K';
    return number.toString();
  }
}
