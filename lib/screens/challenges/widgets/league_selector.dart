import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/constants.dart';
import '../../../core/utils/size_config.dart';
import '../../../core/utils/logo_utils.dart';
import '../challenge_models.dart';
import '../challenge_providers.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/utils/name_translator.dart';

class ChallengeLeagueSelector extends ConsumerWidget {
  final bool isDark;

  const ChallengeLeagueSelector({super.key, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaguesAsync = ref.watch(challengeLeaguesListProvider);
    final selectedLeague = ref.watch(selectedChallengeLeagueProvider);

    return leaguesAsync.when(
      data: (leagues) {
        if (leagues.isEmpty) return const SizedBox.shrink();

        return PopupMenuButton<ChallengeLeagueItem>(
          initialValue: selectedLeague,
          tooltip: AppLocalizations.of(context)!.selectLeague,
          onSelected: (league) {
            ref
                .read(selectedChallengeLeagueProvider.notifier)
                .selectLeague(league);
          },
          offset: const Offset(0, 40),
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.w),
          ),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 5.h),
            decoration: BoxDecoration(
              color:
                  isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(10.w),
              border: Border.all(
                color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (selectedLeague != null &&
                    selectedLeague.image.isNotEmpty) ...[
                  buildTeamLogo(selectedLeague.image, size: 14.w),
                  SizedBox(width: 6.w),
                ],
                Text(
                  (() {
                    if (leagues.isNotEmpty && selectedLeague != null) {
                      try {
                        final current = leagues.firstWhere((l) => l.id == selectedLeague.id);
                        return ArabicNameExtension(current.displayName).toArabicName(context);
                      } catch (_) {
                        return ArabicNameExtension(selectedLeague.displayName).toArabicName(context);
                      }
                    }
                    return selectedLeague != null 
                        ? ArabicNameExtension(selectedLeague.displayName).toArabicName(context) 
                        : AppLocalizations.of(context)!.selectLeague;
                  })(),
                  style: TextStyle(
                    fontSize: 8.5.sp,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white70 : const Color(0xFF475569),
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(width: 3.w),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 14.w,
                  color: isDark ? Colors.white54 : Colors.black54,
                ),
              ],
            ),
          ),
          itemBuilder: (context) {
            return leagues.map((league) {
              final isSelected = selectedLeague?.id == league.id;
              return PopupMenuItem<ChallengeLeagueItem>(
                value: league,
                child: Row(
                  children: [
                    if (league.image.isNotEmpty) ...[
                      buildTeamLogo(league.image, size: 20.w),
                      SizedBox(width: 12.w),
                    ],
                    Expanded(
                      child: Text(
                        ArabicNameExtension(league.displayName).toArabicName(context),
                        style: TextStyle(
                          color:
                              isSelected
                                  ? GoalioColors.greenAccent
                                  : (isDark ? Colors.white : Colors.black87),
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12.sp,
                        ),
                      ),
                    ),
                    if (isSelected)
                      const Icon(
                        Icons.check_circle,
                        color: GoalioColors.greenAccent,
                        size: 18,
                      ),
                  ],
                ),
              );
            }).toList();
          },
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
