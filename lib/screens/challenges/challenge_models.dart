class Group {
  final String id;
  final String name;
  final String type; // 'general', 'custom'
  final int userRank;
  final int totalUsers;
  final String? code;
  final bool isAdmin;

  Group({
    required this.id,
    required this.name,
    required this.type,
    required this.userRank,
    required this.totalUsers,
    this.code,
    this.isAdmin = false,
  });

  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      type: json['type'] ?? 'custom',
      userRank: json['userRank'] ?? 0,
      totalUsers: json['totalUsers'] ?? 0,
      code: json['code'],
      isAdmin: json['isAdmin'] ?? false,
    );
  }
}

class UserRank {
  final int id;
  final String name;
  final int rank;
  final int points;
  final bool isYou;
  final int rankChange;

  UserRank({
    required this.id,
    required this.name,
    required this.rank,
    required this.points,
    this.isYou = false,
    this.rankChange = 0,
  });
}

class LeaderboardState {
  final List<UserRank> list;
  final int currentPage;
  final bool hasMore;
  final bool isLoadingMore;

  LeaderboardState({
    required this.list,
    required this.currentPage,
    required this.hasMore,
    this.isLoadingMore = false,
  });

  LeaderboardState copyWith({
    List<UserRank>? list,
    int? currentPage,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return LeaderboardState(
      list: list ?? this.list,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

class ChallengeLeagueItem {
  final int id;
  final String name;
  final String displayName;
  final String image;

  ChallengeLeagueItem({
    required this.id,
    required this.name,
    required this.displayName,
    required this.image,
  });

  factory ChallengeLeagueItem.fromJson(Map<String, dynamic> json) {
    return ChallengeLeagueItem(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      name: json['name'] ?? '',
      displayName: json['display_name'] ?? json['name'] ?? '',
      image: json['image'] ?? '',
    );
  }
}
