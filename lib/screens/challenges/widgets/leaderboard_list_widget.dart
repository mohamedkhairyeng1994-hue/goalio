import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/constants.dart';
import '../../../core/utils/size_config.dart';
import '../../../l10n/app_localizations.dart';
import '../challenge_models.dart';
import '../challenge_providers.dart';
import '../../../core/utils/number_utils.dart';
import '../user_predictions_page.dart';

class LeaderboardListWidget extends ConsumerWidget {
  final bool isDark;
  final Group group;

  const LeaderboardListWidget({
    super.key,
    required this.isDark,
    required this.group,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ranksState = ref.watch(groupRanksProvider);
    final selectedLeague = ref.watch(selectedChallengeLeagueProvider);
    final selectedDate = ref.watch(selectedChallengeDateProvider);

    return ranksState.when(
      skipLoadingOnRefresh: true,
      data: (state) {
        final ranks = state.list;
        // Surface empty state instead of an invisible zero-height sliver —
        // historically a UTF-8 / silent-decode failure on the leaderboard
        // request would land here and the table would just look "missing".
        if (ranks.isEmpty && !state.hasMore) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 24.w,
                vertical: 32.h,
              ),
              child: Center(
                child: Text(
                  AppLocalizations.of(context)!.errorLoadingLeaderboard,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isDark ? Colors.white54 : Colors.black54,
                    fontSize: 12.sp,
                  ),
                ),
              ),
            ),
          );
        }
        return SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            // Trigger load more when reaching the end
            if (index >= ranks.length - 3 &&
                state.hasMore &&
                !state.isLoadingMore) {
              Future.microtask(() {
                if (context.mounted) {
                  ref.read(groupRanksProvider.notifier).loadMore();
                }
              });
            }

            if (index >= ranks.length) {
              return _buildPaginationLoader();
            }

            final user = ranks[index];
            final isLast = index == ranks.length - 1 && !state.hasMore;
            final isEven = index % 2 == 0;

            return Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => UserPredictionsPage(
                            userId: user.id,
                            userName: user.name,
                            leagueId: selectedLeague?.id,
                            initialDate: selectedDate,
                          ),
                    ),
                  );
                },
                borderRadius:
                    isLast
                        ? BorderRadius.vertical(bottom: Radius.circular(16.w))
                        : BorderRadius.circular(8.w),
                child: Container(
                  decoration: BoxDecoration(
                    color:
                        user.isYou
                            ? (isDark
                                ? GoalioColors.greenAccent.withValues(alpha: 0.15,)
                                : GoalioColors.greenAccent.withValues(alpha: 0.08,))
                            : (isEven
                                ? (isDark
                                    ? const Color(0xFF0F172A)
                                    : const Color(0xFFF8FAFC))
                                : (isDark
                                    ? const Color(
                                      0xFF1E293B,
                                    ).withValues(alpha: 0.3)
                                    : Colors.white)),
                    borderRadius:
                        isLast
                            ? BorderRadius.vertical(
                              bottom: Radius.circular(16.w),
                            )
                            : null,
                    border: Border(
                      left:
                          user.isYou
                              ? BorderSide(
                                color: GoalioColors.greenAccent,
                                width: 3.w,
                              )
                              : BorderSide.none,
                      bottom:
                          isLast
                              ? BorderSide.none
                              : BorderSide(
                                color:
                                    isDark
                                        ? Colors.white.withValues(alpha: 0.03)
                                        : Colors.black.withValues(alpha: 0.02),
                              ),
                    ),
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 12.h,
                  ),
                  child: Row(
                    children: [
                      // POS
                      SizedBox(
                        width: 55.w,
                        child: Row(
                          children: [
                            _buildRankBadge(
                              user.rank,
                              user.rankChange,
                              isDark,
                              context,
                            ),
                            const Spacer(),
                            _buildRankChangeIcon(user.rankChange),
                            SizedBox(width: 8.w),
                          ],
                        ),
                      ),

                      // USER NAME + AVATAR
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              width: 22.w,
                              height: 22.w,
                              decoration: BoxDecoration(
                                color:
                                    user.isYou
                                        ? GoalioColors.greenAccent
                                        : (isDark
                                            ? Colors.white10
                                            : Colors.black.withValues(alpha: 0.05,)),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  (() {
                                    final n = user.name.trim();
                                    if (n.isEmpty) return "?";
                                    final parts = n.split(RegExp(r'\s+'));
                                    if (parts.length > 1 &&
                                        parts[1].isNotEmpty) {
                                      return parts[0][0] + parts[1][0];
                                    }
                                    return n.length >= 2
                                        ? n.substring(0, 2)
                                        : n;
                                  })().toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 8.sp,
                                    fontWeight: FontWeight.w900,
                                    color:
                                        user.isYou
                                            ? Colors.black
                                            : (isDark
                                                ? Colors.white70
                                                : Colors.black87),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 10.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user.name,
                                    style: TextStyle(
                                      fontSize: 10.sp,
                                      fontWeight:
                                          user.isYou
                                              ? FontWeight.w900
                                              : FontWeight.w700,
                                      color:
                                          isDark
                                              ? Colors.white
                                              : const Color(0xFF0F172A),
                                    ),
                                  ),
                                  if (user.isYou)
                                    Text(
                                      AppLocalizations.of(context)!.globalRank(
                                        user.rank.toString().toArabicNumbers(
                                          context,
                                        ),
                                      ),
                                      style: TextStyle(
                                        fontSize: 7.sp,
                                        fontWeight: FontWeight.bold,
                                        color: GoalioColors.greenAccent,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // MATCHDAY POINTS
                      SizedBox(
                        width: 45.w,
                        child: Text(
                          _formatNumber(user.matchdayPoints, context),
                          textAlign: TextAlign.end,
                          style: TextStyle(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                        ),
                      ),

                      // TOTAL POINTS
                      SizedBox(
                        width: 55.w,
                        child: Text(
                          _formatNumber(user.points, context),
                          textAlign: TextAlign.end,
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w900,
                            color:
                                user.isYou
                                    ? GoalioColors.greenAccent
                                    : (isDark
                                        ? Colors.white
                                        : const Color(0xFF0F172A)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }, childCount: ranks.length + (state.hasMore ? 1 : 0)),
        );
      },
      loading:
          () => SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildSkeletonRow(isDark),
              childCount: 10,
            ),
          ),
      error:
          (err, stack) => SliverToBoxAdapter(
            child: Center(
              child: Text(
                AppLocalizations.of(context)!.errorLoadingLeaderboard,
              ),
            ),
          ),
    );
  }

  Widget _buildPaginationLoader() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 20.w),
      child: Center(
        child: SizedBox(
          width: 20.w,
          height: 20.w,
          child: const CircularProgressIndicator(
            color: GoalioColors.greenAccent,
            strokeWidth: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildRankBadge(
    int rank,
    int change,
    bool isDark,
    BuildContext context,
  ) {
    Color color;
    if (change > 0) {
      color = Colors.green;
    } else if (change < 0) {
      color = Colors.red;
    } else {
      color = Colors.grey;
    }

    return Container(
      width: 24.w,
      height: 24.w,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: Text(
        "$rank".toArabicNumbers(context),
        style: TextStyle(
          fontSize: 10.sp,
          fontWeight: FontWeight.w900,
          color: color,
          fontFamily: 'RobotoCondensed',
        ),
      ),
    );
  }

  Widget _buildRankChangeIcon(int change) {
    Color color;
    IconData icon;
    if (change > 0) {
      color = Colors.green;
      icon = Icons.arrow_drop_up;
    } else if (change < 0) {
      color = Colors.red;
      icon = Icons.arrow_drop_down;
    } else {
      color = Colors.grey;
      icon = Icons.horizontal_rule;
    }

    return Container(
      width: 14.w,
      height: 14.w,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: Center(child: Icon(icon, color: color, size: 12.w)),
    );
  }

  Widget _buildSkeletonRow(bool isDark) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
      child: Container(
        height: 60.h,
        decoration: BoxDecoration(
          color:
              isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(12.w),
        ),
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: Row(
          children: [
            Container(
              width: 30.w,
              height: 30.w,
              decoration: BoxDecoration(
                color: isDark ? Colors.white10 : Colors.black12,
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: 16.w),
            Container(
              width: 120.w,
              height: 12.h,
              decoration: BoxDecoration(
                color: isDark ? Colors.white10 : Colors.black12,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const Spacer(),
            Container(
              width: 40.w,
              height: 12.h,
              decoration: BoxDecoration(
                color: isDark ? Colors.white10 : Colors.black12,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatNumber(int number, BuildContext context) {
    String formatted;
    if (number >= 1000000) {
      formatted = '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      formatted = '${(number / 1000).toStringAsFixed(1)}K';
    } else {
      formatted = number.toString();
    }
    return formatted.toArabicNumbers(context);
  }
}
