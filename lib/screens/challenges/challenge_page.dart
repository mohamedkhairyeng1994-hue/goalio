import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/size_config.dart';
import '../../core/constants/constants.dart';
import '../../core/localization/language_manager.dart';
import 'challenge_providers.dart';
import 'widgets/challenge_app_bar.dart';
import 'widgets/unified_challenge_card.dart';
import 'widgets/groups_list_widget.dart';
import 'widgets/leaderboard_header.dart';
import 'widgets/leaderboard_list_widget.dart';
import 'challenge_models.dart';

class ChallengePage extends ConsumerStatefulWidget {
  const ChallengePage({super.key});

  @override
  ConsumerState<ChallengePage> createState() => ChallengePageState();
}

class ChallengePageState extends ConsumerState<ChallengePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(selectedChallengeLeagueProvider) == null) {
        _initializeDefaultLeague();
      }
    });
  }

  bool onBackPressed() {
    final selectedGroup = ref.read(selectedGroupProvider);
    if (selectedGroup != null) {
      ref.read(selectedGroupProvider.notifier).selectGroup(null);
      return true;
    }
    return false;
  }

  Future<void> _initializeDefaultLeague() async {
    try {
      final leagues = await ref.read(challengeLeaguesListProvider.future);
      if (leagues.isNotEmpty) {
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

    // Listen to leagues list to ensure a default is selected
    ref.listen(challengeLeaguesListProvider, (prev, next) {
      if (next is AsyncData && next.value != null && next.value!.isNotEmpty) {
        if (ref.read(selectedChallengeLeagueProvider) == null) {
          final leagues = next.value!;
          final defaultLeague = leagues.any((l) => l.id == 1)
              ? leagues.firstWhere((l) => l.id == 1)
              : leagues.first;
          ref.read(selectedChallengeLeagueProvider.notifier).selectLeague(defaultLeague);
        }
      }
    });

    // Listen to dates changes to perform auto-jump on league switch
    ref.listen(allChallengeMatchesProvider, (previous, next) {
      if (next is AsyncData && next.value != null) {
        // Use microtask to avoid building while listening
        Future.microtask(() {
          ref.read(selectedChallengeDateProvider.notifier).autoJumpToNearest();
        });
      }
    });

    // Detect RTL more robustly
    final appLocale = ref.watch(appLocaleProvider);
    final bool isRtl = appLocale.languageCode == 'ar' || Directionality.of(context) == TextDirection.rtl;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      extendBodyBehindAppBar: true,
      appBar: ChallengeAppBar(selectedGroup: selectedGroup, isDark: isDark),
      body: Container(
        width: double.infinity,
        height: double.infinity,
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
        child: SafeArea(
          child: Stack(
            children: [
              // 1. MAIN CONTENT (Always visible in background)
              selectedGroup != null
                  ? _buildLeaderboardView(isDark, selectedGroup)
                  : RefreshIndicator(
                      color: GoalioColors.greenAccent,
                      onRefresh: () async {
                        ref.invalidate(challengeDataByDateProvider(selectedDate));
                        ref.invalidate(userTotalPointsProvider);
                        ref.invalidate(groupsProvider);
                        return await ref
                            .read(challengeDataByDateProvider(selectedDate).future);
                      },
                      child: CustomScrollView(
                        slivers: [
                          SliverPadding(
                            padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 16.h),
                            sliver: SliverToBoxAdapter(
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onHorizontalDragEnd: (details) {
                                  const int threshold = 300;
                                  if (details.primaryVelocity! < -threshold) {
                                    if (isRtl) {
                                      ref.read(selectedChallengeDateProvider.notifier).previousDay();
                                    } else {
                                      ref.read(selectedChallengeDateProvider.notifier).nextDay();
                                    }
                                  } else if (details.primaryVelocity! > threshold) {
                                    if (isRtl) {
                                      ref.read(selectedChallengeDateProvider.notifier).nextDay();
                                    } else {
                                      ref.read(selectedChallengeDateProvider.notifier).previousDay();
                                    }
                                  }
                                },
                                child: Consumer(
                                  builder: (context, ref, child) {
                                    final currentDataAsync = ref.watch(challengeDataByDateProvider(selectedDate));
                                    final totalPointsAsync = ref.watch(userTotalPointsProvider);
                                    
                                    return currentDataAsync.maybeWhen(
                                      data: (data) {
                                        final summary = Map<String, dynamic>.from(data['summary'] ?? {});
                                        final matches = List<dynamic>.from(data['matches'] ?? []);
                                        return UnifiedChallengeCard(
                                          isDark: isDark,
                                          selectedDate: selectedDate,
                                          datePoints: (summary['points'] as num?)?.toInt() ?? 0,
                                          totalPoints: totalPointsAsync.maybeWhen(data: (d) => d, orElse: () => 0),
                                          eplMatchesState: AsyncData(matches),
                                          summary: summary,
                                          isLoading: false,
                                        );
                                      },
                                      // When loading, we pass isLoading: false to suppress redundant internal spinners
                                      // as the global blurred overlay will be shown above it.
                                      loading: () => UnifiedChallengeCard(
                                        isDark: isDark,
                                        selectedDate: selectedDate,
                                        datePoints: 0,
                                        totalPoints: totalPointsAsync.maybeWhen(data: (d) => d, orElse: () => 0),
                                        eplMatchesState: const AsyncData([]),
                                        summary: const {},
                                        isLoading: false,
                                      ),
                                      orElse: () => UnifiedChallengeCard(
                                        isDark: isDark,
                                        selectedDate: selectedDate,
                                        datePoints: 0,
                                        totalPoints: totalPointsAsync.maybeWhen(data: (d) => d, orElse: () => 0),
                                        eplMatchesState: const AsyncData([]),
                                        summary: const {},
                                        isLoading: false,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                          GroupsListWidget(isDark: isDark),
                          SliverToBoxAdapter(child: SizedBox(height: 100.h)),
                        ],
                      ),
                    ),

              // 2. GLOBAL PREMIUM BLUR OVERLAY (The specific loader the user requested)
              Consumer(
                builder: (context, ref, child) {
                  final challengeDataAsync = ref.watch(challengeDataByDateProvider(selectedDate));
                  
                  // Show overlay ONLY during initialization or actual data loading
                  if (!challengeDataAsync.isLoading) {
                    return const SizedBox.shrink();
                  }

                  return Positioned.fill(
                    child: ClipRRect(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 4.0, sigmaY: 4.0),
                        child: Container(
                          color: (isDark ? Colors.black : Colors.white)
                              .withValues(alpha: 0.15),
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: GoalioColors.greenAccent,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLeaderboardView(bool isDark, Group group) {
    return RefreshIndicator(
      color: GoalioColors.greenAccent,
      onRefresh: () async {
        ref.invalidate(groupRanksProvider);
        return await ref.read(groupRanksProvider.future);
      },
      child: CustomScrollView(
        slivers: [
          LeaderboardHeaderWidget(isDark: isDark),
          LeaderboardListWidget(isDark: isDark, group: group),
          SliverToBoxAdapter(child: SizedBox(height: 100.h)),
        ],
      ),
    );
  }
}
