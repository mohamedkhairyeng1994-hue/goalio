import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/constants.dart';
import '../../../core/utils/size_config.dart';
import '../../../core/utils/logo_utils.dart';
import '../../../core/utils/time_utils.dart';
import '../../../l10n/app_localizations.dart';
import '../prediction_page.dart';
import '../../fixtures/match_detail_page.dart';
import '../challenge_providers.dart';
import '../../../core/utils/number_utils.dart';
import '../../../core/utils/name_translator.dart';

class MatchItemWidget extends ConsumerWidget {
  final dynamic match;
  final bool isDark;

  const MatchItemWidget({super.key, required this.match, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final homeTeam = (match['home_team'] ?? l10n.homeTeam).toString().toArabicName(context);
    final awayTeam = (match['away_team'] ?? l10n.awayTeam).toString().toArabicName(context);
    final timeStr = formatMatchTime(match['match_time']?.toString());
    final status = match['status']?.toString() ?? 'TBD';
    final bool hasPredicted = match['has_predicted'] == true;
    final pointsValue = match['total_points']?.toString() ?? '0';
    final bool started =
        status != 'PRE' &&
        status != 'TBD' &&
        status != 'VS' &&
        status != 'Scheduled' &&
        status != 'Not Started' &&
        status != 'NS' &&
        status != 'FIXTURE' &&
        !status.contains(':');

    final bool isFinished =
        status == 'FT' ||
        status == 'AET' ||
        status == 'PEN' ||
        status == 'RESULT';

    final bool isLive = started && !isFinished;

    String homeScore =
        (match['home_score'] == null || match['home_score'] == 'N/A')
            ? '0'
            : match['home_score'].toString();
    String awayScore =
        (match['away_score'] == null || match['away_score'] == 'N/A')
            ? '0'
            : match['away_score'].toString();

    final homeRedCards = match['home_red_cards'];
    final awayRedCards = match['away_red_cards'];

    if (match['home_score_pen'] != null && match['away_score_pen'] != null) {
      homeScore += "(${match['home_score_pen']})";
      awayScore += "(${match['away_score_pen']})";
    }

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => MatchDetailPage(match: match)),
        );
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 6.h),
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12.w),
          border: Border.all(
            color:
                isLive
                    ? Colors.redAccent.withValues(alpha: 0.6)
                    : isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.03),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                homeTeam,
                                textAlign: TextAlign.end,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 9.sp,
                                  color:
                                      isDark
                                          ? Colors.white
                                          : const Color(0xFF0F172A),
                                ),
                              ),
                              if (homeRedCards != null && (homeRedCards is! int || homeRedCards > 0)) ...[
                                SizedBox(height: 2.h),
                                _buildRedCardBadge(
                                  context,
                                  homeRedCards,
                                  isHome: true,
                                ),
                              ],
                            ],
                          ),
                        ),
                        SizedBox(width: 6.w),
                        buildTeamLogo(match['home_logo'], size: 18.w),
                      ],
                    ),
                  ),
                  Container(
                    width: 40.w,
                    margin: EdgeInsets.symmetric(horizontal: 4.w),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        started
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    homeScore.toArabicNumbers(context),
                                    style: TextStyle(
                                      fontSize: 10.sp,
                                      fontWeight: FontWeight.w900,
                                      color:
                                          isFinished
                                              ? (isDark
                                                  ? Colors.white38
                                                  : Colors.black38)
                                              : GoalioColors.greenAccent,
                                      letterSpacing: 0,
                                    ),
                                  ),
                                  Text(
                                    "-",
                                    style: TextStyle(
                                      fontSize: 10.sp,
                                      fontWeight: FontWeight.w900,
                                      color:
                                          isFinished
                                              ? (isDark
                                                  ? Colors.white38
                                                  : Colors.black38)
                                              : GoalioColors.greenAccent,
                                      letterSpacing: 0,
                                    ),
                                  ),
                                  Text(
                                    awayScore.toArabicNumbers(context),
                                    style: TextStyle(
                                      fontSize: 10.sp,
                                      fontWeight: FontWeight.w900,
                                      color:
                                          isFinished
                                              ? (isDark
                                                  ? Colors.white38
                                                  : Colors.black38)
                                              : GoalioColors.greenAccent,
                                      letterSpacing: 0,
                                    ),
                                  ),
                                ],
                              )
                            : Text(
                                "VS",
                                style: TextStyle(
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w900,
                                  color: GoalioColors.greenAccent,
                                  letterSpacing: 0.5,
                                ),
                              ),
                        if (!isFinished) ...[
                          SizedBox(height: 1.h),
                          Text(
                            started &&
                                    (status == 'HT' ||
                                        status == 'FT' ||
                                        status.contains("'"))
                                ? localizeMatchStatus(context, status).toArabicNumbers(context)
                                : timeStr.toArabicNumbers(context),
                            style: TextStyle(
                              fontSize: 8.sp,
                              fontWeight: FontWeight.w900,
                              color:
                                  isLive
                                      ? Colors.redAccent
                                      : (isDark
                                          ? Colors.white38
                                          : Colors.black38),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        buildTeamLogo(match['away_logo'], size: 18.w),
                        SizedBox(width: 6.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                awayTeam,
                                textAlign: TextAlign.start,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 9.sp,
                                  color:
                                      isDark
                                          ? Colors.white
                                          : const Color(0xFF0F172A),
                                ),
                              ),
                              if (awayRedCards != null && (awayRedCards is! int || awayRedCards > 0)) ...[
                                SizedBox(height: 2.h),
                                _buildRedCardBadge(
                                  context,
                                  awayRedCards,
                                  isHome: false,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 1,
              height: 24.h,
              color:
                  isDark
                      ? Colors.white10
                      : Colors.black.withValues(alpha: 0.05),
              margin: EdgeInsets.symmetric(horizontal: 6.w),
            ),
            _MatchActionButton(
              match: match,
              isDark: isDark,
              hasPredicted: hasPredicted,
              started: started,
              pointsValue: pointsValue,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRedCardBadge(
    BuildContext context,
    dynamic redCardsData, {
    bool isHome = false,
  }) {
    if (redCardsData == null) return const SizedBox.shrink();

    List<String> playerNames = [];
    int count = 0;

    if (redCardsData is int) {
      count = redCardsData;
    } else if (redCardsData is List) {
      count = redCardsData.length;
      playerNames =
          redCardsData.map((e) {
            if (e is Map) {
              return e['player']?.toString() ?? e['name']?.toString() ?? '';
            }
            return e.toString();
          }).where((e) => e.isNotEmpty).toList();
    } else if (redCardsData is String) {
      if (redCardsData.startsWith('[') || redCardsData.startsWith('{')) {
        try {
          final decoded = json.decode(redCardsData);
          return _buildRedCardBadge(context, decoded, isHome: isHome);
        } catch (e) {
          // Fallback
        }
      }
      final parsed = int.tryParse(redCardsData);
      if (parsed != null) {
        count = parsed;
      } else if (redCardsData.isNotEmpty) {
        count = 1;
        playerNames = [redCardsData];
      }
    }

    if (count == 0) return const SizedBox.shrink();

    // If we have names, display them vertically aligned
    if (playerNames.isNotEmpty) {
      return Column(
        crossAxisAlignment:
            isHome ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children:
            playerNames.map((name) {
              return Padding(
                padding: EdgeInsets.symmetric(vertical: 0.5.h),
                child: Row(
                  mainAxisAlignment:
                      isHome
                          ? MainAxisAlignment.end
                          : MainAxisAlignment.start,
                  children:
                      isHome
                          ? [
                            Flexible(
                              child: Text(
                                name.toArabicName(context),
                                style: TextStyle(
                                  color: Colors.redAccent,
                                  fontSize: 7.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            SizedBox(width: 3.w),
                            _buildSingleRedCardIcon(),
                          ]
                          : [
                            _buildSingleRedCardIcon(),
                            SizedBox(width: 3.w),
                            Flexible(
                              child: Text(
                                name.toArabicName(context),
                                style: TextStyle(
                                  color: Colors.redAccent,
                                  fontSize: 7.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                ),
              );
            }).toList(),
      );
    }

    // Fallback: if no player names but we have a count, show that many red card icons
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: isHome ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: List.generate(count, (index) => Padding(
        padding: EdgeInsets.symmetric(horizontal: 1.w),
        child: _buildSingleRedCardIcon(),
      )),
    );
  }

  Widget _buildSingleRedCardIcon() {
    return Container(
      width: 5.w,
      height: 7.h,
      decoration: BoxDecoration(
        color: Colors.redAccent,
        borderRadius: BorderRadius.circular(1.w),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.18),
          width: 0.4,
        ),
      ),
    );
  }
}

class _MatchActionButton extends ConsumerWidget {
  final dynamic match;
  final bool isDark;
  final bool hasPredicted;
  final bool started;
  final String pointsValue;

  const _MatchActionButton({
    required this.match,
    required this.isDark,
    required this.hasPredicted,
    required this.started,
    required this.pointsValue,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (hasPredicted || started) {
      return GestureDetector(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) =>
                      PredictionPage(match: match, isReadOnly: started),
            ),
          );

          if (!started) {
            final date = ref.read(selectedChallengeDateProvider);
            ref.invalidate(challengeDataByDateProvider(date));
            ref.invalidate(userTotalPointsProvider);
            ref.invalidate(groupsProvider);
          }
        },
        child: Container(
          width: 52.w,
          height: 28.h,
          decoration: BoxDecoration(
            color: GoalioColors.greenAccent.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10.w),
            border: Border.all(
              color: GoalioColors.greenAccent.withValues(alpha: 0.2),
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                GoalioColors.greenAccent.withValues(alpha: 0.05),
                GoalioColors.greenAccent.withValues(alpha: 0.15),
              ],
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!started)
                Text(
                  AppLocalizations.of(context)!.edit.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w900,
                    color: GoalioColors.greenAccent,
                    letterSpacing: 0.5,
                  ),
                )
              else ...[
                Text(
                  pointsValue.toArabicNumbers(context),
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w900,
                    color: GoalioColors.greenAccent,
                    fontFamily: 'Montserrat',
                  ),
                ),
                SizedBox(width: 3.w),
                Text(
                  AppLocalizations.of(context)!.pts.toUpperCase(),
                  style: TextStyle(
                    fontSize: 8.sp,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white54 : Colors.black54,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return SizedBox(
      width: 52.w,
      height: 28.h,
      child: ElevatedButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PredictionPage(match: match),
            ),
          );

          final date = ref.read(selectedChallengeDateProvider);
          ref.invalidate(challengeDataByDateProvider(date));
          ref.invalidate(userTotalPointsProvider);
          ref.invalidate(groupsProvider);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: GoalioColors.greenAccent,
          foregroundColor: Colors.black,
          elevation: 0,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.w),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              AppLocalizations.of(context)!.start.toUpperCase(),
              style: TextStyle(
                fontSize: 8.sp,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
            SizedBox(width: 2.w),
            Icon(Icons.arrow_forward_ios_rounded, size: 9.w),
          ],
        ),
      ),
    );
  }
}
