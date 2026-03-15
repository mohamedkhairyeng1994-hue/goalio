import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/size_config.dart';
import '../../core/constants/constants.dart';
import 'challenge_providers.dart';
import 'widgets/challenge_app_bar.dart';
import 'widgets/unified_challenge_card.dart';
import 'widgets/groups_list_widget.dart';
import 'widgets/leaderboard_header.dart';
import 'widgets/leaderboard_list_widget.dart';

class ChallengePage extends ConsumerStatefulWidget {
  const ChallengePage({super.key});

  @override
  ConsumerState<ChallengePage> createState() => ChallengePageState();
}

class ChallengePageState extends ConsumerState<ChallengePage> {
  @override
  void initState() {
    super.initState();
    // After the first frame, ensure we have a default league if none is selected
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(selectedChallengeLeagueProvider) == null) {
        _initializeDefaultLeague();
      }
    });
  }

  bool onBackPressed() {
    // If a group is currently selected (meaning we are viewing the leaderboard), 
    // clear it so we go back to the list of groups instead of closing the app.
    final selectedGroup = ref.read(selectedGroupProvider);
    if (selectedGroup != null) {
      ref.read(selectedGroupProvider.notifier).selectGroup(null);
      return true; // We handled the back press internally
    }
    return false; // Let the system handle it
  }

  Future<void> _initializeDefaultLeague() async {
    try {
      final leagues = await ref.read(challengeLeaguesListProvider.future);
      if (leagues.isNotEmpty) {
        // Try to find Premier League (id:1) or just take the first one
        final defaultLeague = leagues.any((l) => l.id == 1)
            ? leagues.firstWhere((l) => l.id == 1)
            : leagues.first;
        ref.read(selectedChallengeLeagueProvider.notifier).selectLeague(defaultLeague);
      }
    } catch (e) {
      debugPrint("Error initializing default league: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedGroup = ref.watch(selectedGroupProvider);
    final selectedDate = ref.watch(selectedChallengeDateProvider);
    final challengeMatchesAsync = ref.watch(challengeMatchesProvider);
    final totalPointsAsync = ref.watch(userTotalPointsProvider);
    final datePoints = ref.watch(userPointsProvider);

    ref.listen(challengeMatchDatesProvider, (previous, next) {
      if (next.isNotEmpty) {
        Future.microtask(() {
          if (mounted) {
            ref.read(selectedChallengeDateProvider.notifier).autoJumpToNearest();
          }
        });
      }
    });

    final challengeDataRaw = ref.watch(challengeDataRawProvider);
    final groupsState = ref.watch(groupsProvider);
    final allMatchesState = ref.watch(allChallengeMatchesProvider);

    final isLoadingPage = challengeDataRaw.isLoading ||
                         groupsState.isLoading ||
                         allMatchesState.isLoading ||
                         challengeDataRaw.isRefreshing ||
                         groupsState.isRefreshing ||
                         allMatchesState.isRefreshing;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: isDark
                  ? const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF0F172A), Color(0xFF020617)],
                    )
                  : const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFFF1F5F9), Color(0xFFE2E8F0)],
                    ),
            ),
            child: RefreshIndicator(
              color: GoalioColors.greenAccent,
              onRefresh: () async {
                ref.invalidate(challengeLeaguesListProvider);
                ref.invalidate(allChallengeMatchesProvider);
                ref.invalidate(challengeDataRawProvider);
                ref.invalidate(userTotalPointsProvider);
                ref.invalidate(groupsProvider);
                ref.invalidate(groupRanksProvider);
                return await ref.read(challengeDataRawProvider.future);
              },
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: ClampingScrollPhysics(),
                ),
                slivers: [
                  ChallengeAppBar(selectedGroup: selectedGroup, isDark: isDark),
                  
                  if (selectedGroup == null) ...[
                    // VIEW 1: Main Challenge Dashboard
                    SliverPadding(
                      padding: EdgeInsetsDirectional.fromSTEB(20.w, 16.h, 20.w, 8.h),
                      sliver: SliverToBoxAdapter(
                        child: UnifiedChallengeCard(
                          isDark: isDark,
                          selectedDate: selectedDate,
                          datePoints: datePoints,
                          totalPoints: totalPointsAsync.maybeWhen(
                            data: (d) => d,
                            orElse: () => 0,
                          ),
                          eplMatchesState: challengeMatchesAsync,
                        ),
                      ),
                    ),
                    GroupsListWidget(isDark: isDark),
                  ] else ...[
                    // VIEW 2: Leaderboard (Group Detail)
                    LeaderboardHeaderWidget(isDark: isDark),
                    LeaderboardListWidget(isDark: isDark, group: selectedGroup),
                  ],
                  // Safe space at the bottom to avoid being hidden by Nav Bar
                  SliverToBoxAdapter(child: SizedBox(height: 100.h)),
                ],
              ),
            ),
          ),
          if (isLoadingPage)
            Positioned.fill(
              child: Container(
                color: isDark ? Colors.black.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.3),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: GoalioColors.greenAccent,
                      strokeWidth: 3,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
