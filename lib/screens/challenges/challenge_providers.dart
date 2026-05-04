import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/localization/language_manager.dart';
import '../../core/services/api_service.dart';
import 'challenge_models.dart';

// --- SHARED PROVIDERS ---

final userPointsProvider = Provider<int>((ref) {
  final summary = ref.watch(challengeSummaryProvider);
  return (summary['points'] as num?)?.toInt() ?? 0;
});

final userTotalPointsProvider = FutureProvider<int>((ref) async {
  final league = ref.watch(selectedChallengeLeagueProvider);
  final profile = await ApiService.getUserProfile(leagueId: league?.id);
  return profile?['points'] ?? 0;
});

// --- GROUPS & LEADERS ---

class GroupsNotifier extends AsyncNotifier<List<Group>> {
  @override
  Future<List<Group>> build() async {
    // Watch the selected league and locale
    ref.watch(selectedChallengeLeagueProvider);
    ref.watch(appLocaleProvider);
    return _fetchLeagues();
  }

  Future<List<Group>> _fetchLeagues() async {
    final selectedLeague = ref.read(selectedChallengeLeagueProvider);
    final data = await ApiService.getChallengeLeagues(leagueId: selectedLeague?.id);
    return data.map((item) => Group.fromJson(item)).toList();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchLeagues());
  }

  Future<String?> addCustomLeague(String name) async {
    if (name.trim().isEmpty) return null;
    final selectedLeague = ref.read(selectedChallengeLeagueProvider);
    final result = await ApiService.createChallengeLeague(name, leagueId: selectedLeague?.id);
    if (result.containsKey('data')) {
      await refresh();
      return result['data']['code'];
    }
    return null;
  }

  Future<bool> joinLeagueByCode(String code) async {
    if (code.trim().isEmpty) return false;
    final result = await ApiService.joinChallengeLeague(code);
    if (result.containsKey('data')) {
      await refresh();
      return true;
    }
    return false;
  }
}

final groupsProvider = AsyncNotifierProvider<GroupsNotifier, List<Group>>(
  () => GroupsNotifier(),
);

class SelectedGroupNotifier extends Notifier<Group?> {
  @override
  Group? build() => null;
  void selectGroup(Group? group) => state = group;
}

final selectedGroupProvider = NotifierProvider<SelectedGroupNotifier, Group?>(
  () => SelectedGroupNotifier(),
);

class GroupRanksNotifier extends AsyncNotifier<LeaderboardState> {
  @override
  FutureOr<LeaderboardState> build() async {
    // Watch selected group AND locale so the leaderboard refetches if the
    // user switches language while a group is open (without a watch on
    // appLocaleProvider the cached LeaderboardState would survive the
    // locale change unchanged).
    final group = ref.watch(selectedGroupProvider);
    ref.watch(appLocaleProvider);

    if (group == null) {
      return LeaderboardState(list: [], currentPage: 0, hasMore: false);
    }

    final data = await ApiService.getChallengeLeagueLeaderboard(group.id, page: 1);
    return LeaderboardState(
      list: _parseUsers(data['list'] ?? []),
      currentPage: 1,
      hasMore: data['has_more'] ?? false,
    );
  }

  List<UserRank> _parseUsers(List<dynamic> list) {
    return list.map((json) {
      return UserRank(
        id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
        rank: json['rank'] ?? 0,
        name: json['name'] ?? 'Unknown',
        points: (json['points'] as num?)?.toInt() ?? 0,
        matchdayPoints: (json['matchday_points'] as num?)?.toInt() ?? 0,
        isYou: json['isYou'] ?? false,
        rankChange: json['rankChange'] ?? 0,
      );
    }).toList();
  }

  Future<void> loadMore() async {
    final group = ref.read(selectedGroupProvider);
    if (group == null) return;

    final currentState = state.value;
    if (currentState == null || !currentState.hasMore || currentState.isLoadingMore) return;

    state = AsyncData(currentState.copyWith(isLoadingMore: true));
    
    try {
       final nextPage = currentState.currentPage + 1;
       final data = await ApiService.getChallengeLeagueLeaderboard(group.id, page: nextPage);
       final newUsers = _parseUsers(data['list'] ?? []);
       
       state = AsyncData(currentState.copyWith(
         list: [...currentState.list, ...newUsers],
         currentPage: nextPage,
         hasMore: data['has_more'] ?? false,
         isLoadingMore: false,
       ));
    } catch (e) {
      if (kDebugMode) debugPrint("Error loading more leaderboard: $e");
      state = AsyncData(currentState.copyWith(isLoadingMore: false));
    }
  }
}

final groupRanksProvider = AsyncNotifierProvider<GroupRanksNotifier, LeaderboardState>(
  () => GroupRanksNotifier(),
);

// --- LEAGUE & DATA FILTERING ---

final challengeLeaguesListProvider = FutureProvider<List<ChallengeLeagueItem>>((ref) async {
  ref.watch(appLocaleProvider); // Re-fetch when language changes
  final data = await ApiService.getChallengeLeaguesList();
  final leagues = data.map((json) => ChallengeLeagueItem.fromJson(json)).toList();
  
  // Define requested sort order
  final order = [
    'England - Premier League',
    'Spain - LaLiga',
    'Italy - Serie A',
    'Germany - Bundesliga',
    'France - Ligue 1',
    'Saudi Arabia - Saudi Pro League',
    'Egypt - Premier League',
  ];

  // Sort by the predefined order, fallback entries to the end
  leagues.sort((a, b) {
    int indexA = order.indexOf(a.name); // Using stable English name
    int indexB = order.indexOf(b.name);
    if (indexA == -1) indexA = 99;
    if (indexB == -1) indexB = 99;
    return indexA.compareTo(indexB);
  });
  
  return leagues;
});

class SelectedChallengeLeagueNotifier extends Notifier<ChallengeLeagueItem?> {
  @override
  ChallengeLeagueItem? build() => null;

  void selectLeague(ChallengeLeagueItem? league) async {
    if (state?.id == league?.id) return;
    state = league;
    
    // Persist selection
    if (league != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('last_challenge_league_id', league.id);
    }

    // Reset secondary states
    ref.read(selectedGroupProvider.notifier).selectGroup(null);
    ref.read(selectedChallengeDateProvider.notifier).resetToToday();
    ref.read(selectedChallengeDateProvider.notifier).resetJump();
  }
}

final selectedChallengeLeagueProvider = NotifierProvider<SelectedChallengeLeagueNotifier, ChallengeLeagueItem?>(
  () => SelectedChallengeLeagueNotifier(),
);

// Provider to fetch all dates that have matches for the challenge
final allChallengeMatchesProvider = FutureProvider<List<dynamic>>((ref) async {
  ref.watch(appLocaleProvider);
  final league = ref.watch(selectedChallengeLeagueProvider);
  return await ApiService.getChallengeDates(leagueId: league?.id);
});

// Provider to extract unique available dates
final challengeMatchDatesProvider = Provider<List<DateTime>>((ref) {
  final datesAsync = ref.watch(allChallengeMatchesProvider);
  return datesAsync.maybeWhen(
    data: (dates) {
      if (dates.isEmpty) return [];
      final Set<DateTime> parsedDates = {};
      for (var d in dates) {
        try {
          final dt = DateTime.parse(d.toString());
          // Normalize to local midnight for consistent UI behavior
          parsedDates.add(DateTime(dt.year, dt.month, dt.day));
        } catch (_) {}
      }
      final sorted = parsedDates.toList()..sort();
      return sorted;
    },
    orElse: () => [],
  );
});

class SelectedChallengeDateNotifier extends Notifier<DateTime> {
  bool _hasInitialJumped = false;

  @override
  DateTime build() {
    _hasInitialJumped = false; // Reset the flag every time the provider is built
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  void resetToToday() {
    final now = DateTime.now();
    state = DateTime(now.year, now.month, now.day);
    _hasInitialJumped = false;
  }

  void resetJump() {
    _hasInitialJumped = false;
  }

  void selectDate(DateTime date) => state = date;

  void autoJumpToNearest() {
    if (_hasInitialJumped) return;
    jumpToLatest();
    _hasInitialJumped = true;
  }

  void jumpToLatest() {
    final availableDates = ref.read(challengeMatchDatesProvider);
    if (availableDates.isEmpty) return;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    try {
      final nearest = availableDates.firstWhere((d) => !d.isBefore(today));
      state = nearest;
    } catch (_) {
      if (availableDates.isNotEmpty) {
        state = availableDates.last;
      }
    }
  }

  void nextDay() {
    final availableDates = ref.read(challengeMatchDatesProvider);
    if (availableDates.isEmpty) return;

    final currentDate = DateTime(state.year, state.month, state.day);
    try {
      final next = availableDates.firstWhere((d) => d.isAfter(currentDate));
      state = next;
      _invalidateData();
    } catch (_) {}
  }

  void previousDay() {
    final availableDates = ref.read(challengeMatchDatesProvider);
    if (availableDates.isEmpty) return;

    final currentDate = DateTime(state.year, state.month, state.day);
    try {
      final prev = availableDates.lastWhere((d) => d.isBefore(currentDate));
      state = prev;
      _invalidateData();
    } catch (_) {}
  }

  void _invalidateData() {
    ref.invalidate(challengeDataRawProvider);
    ref.invalidate(userTotalPointsProvider);
    ref.invalidate(groupsProvider);
  }
}

final selectedChallengeDateProvider =
    NotifierProvider<SelectedChallengeDateNotifier, DateTime>(
      () => SelectedChallengeDateNotifier(),
    );

final challengeDataByDateProvider = FutureProvider.family<Map<String, dynamic>, DateTime>((ref, date) async {
  ref.watch(appLocaleProvider);
  final league = ref.watch(selectedChallengeLeagueProvider);
  
  final dateStr = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  final data = await ApiService.getChallengeMatches(date: dateStr, leagueId: league?.id);
  if (data == null) return {};
  return Map<String, dynamic>.from(data);
});

final challengeDataRawProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final date = ref.watch(selectedChallengeDateProvider);
  return await ref.watch(challengeDataByDateProvider(date).future);
});

final challengeMatchesProvider = FutureProvider<List<dynamic>>((ref) async {
  final raw = await ref.watch(challengeDataRawProvider.future);
  return List<dynamic>.from(raw['matches'] ?? []);
});

final challengeSummaryProvider = Provider<Map<String, dynamic>>((ref) {
  final raw = ref.watch(challengeDataRawProvider);
  final data = raw.value;
  if (data == null) return {};
  return Map<String, dynamic>.from(data['summary'] ?? {});
});
