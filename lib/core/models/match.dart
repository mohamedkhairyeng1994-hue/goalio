import '../services/api_client.dart';
import 'json_parsing.dart';

/// One row from the matches API. Mirrors `MatchResource` on the backend
/// minus the cosmetic `_original_name` / list relations that UI rarely needs;
/// keep using the raw `Map` if you need those.
class MatchModel {
  final int id;
  final String? matchDate; // 'yyyy-MM-dd' — kept as string for UI consistency
  final String competition;
  final String? competitionImage;
  final String homeTeam;
  final String awayTeam;
  final String? homeTeamImage;
  final String? awayTeamImage;
  final int? homeTeamId;
  final int? awayTeamId;
  final int? homeScore;
  final int? awayScore;
  final int? homeScorePen;
  final int? awayScorePen;
  /// `home_red_cards` / `away_red_cards` come back as either an int or a
  /// JSON array of player names. We expose the raw value plus a count so
  /// the UI can choose the cheapest representation.
  final Object? homeRedCardsRaw;
  final Object? awayRedCardsRaw;
  final int homeRedCardsCount;
  final int awayRedCardsCount;
  final String? status;
  /// Server now returns ISO timestamps for kick-off (e.g.
  /// `2026-05-03T18:00:00.000Z`). Stored as DateTime for type-safe display.
  final DateTime? matchTime;
  final String? matchTimeRaw;
  final String? matchUrl;
  final int? leagueId;
  final bool isFavorite;
  final bool isFavoriteTeam;
  final bool isFavoriteLeague;
  final bool homeIsFavorite;
  final bool awayIsFavorite;
  final bool matchNotifications;
  final int predictionsCount;

  const MatchModel({
    required this.id,
    this.matchDate,
    required this.competition,
    this.competitionImage,
    required this.homeTeam,
    required this.awayTeam,
    this.homeTeamImage,
    this.awayTeamImage,
    this.homeTeamId,
    this.awayTeamId,
    this.homeScore,
    this.awayScore,
    this.homeScorePen,
    this.awayScorePen,
    this.homeRedCardsRaw,
    this.awayRedCardsRaw,
    this.homeRedCardsCount = 0,
    this.awayRedCardsCount = 0,
    this.status,
    this.matchTime,
    this.matchTimeRaw,
    this.matchUrl,
    this.leagueId,
    this.isFavorite = false,
    this.isFavoriteTeam = false,
    this.isFavoriteLeague = false,
    this.homeIsFavorite = false,
    this.awayIsFavorite = false,
    this.matchNotifications = false,
    this.predictionsCount = 0,
  });

  factory MatchModel.fromJson(Map<String, dynamic> json) {
    final timeRaw = json['match_time']?.toString() ?? json['time']?.toString();
    final homeRC = json['home_red_cards'];
    final awayRC = json['away_red_cards'];

    return MatchModel(
      id: parseInt(json['id']),
      matchDate: json['match_date']?.toString(),
      competition: json['competition']?.toString() ?? '',
      competitionImage: _resolveUrl(json['competition_image']),
      homeTeam: json['home_team']?.toString() ?? '',
      awayTeam: json['away_team']?.toString() ?? '',
      homeTeamImage: _resolveUrl(json['home_team_image']),
      awayTeamImage: _resolveUrl(json['away_team_image']),
      homeTeamId: parseIntOrNull(json['home_team_id']),
      awayTeamId: parseIntOrNull(json['away_team_id']),
      homeScore: parseIntOrNull(json['home_score']),
      awayScore: parseIntOrNull(json['away_score']),
      homeScorePen: parseIntOrNull(json['home_score_pen']),
      awayScorePen: parseIntOrNull(json['away_score_pen']),
      homeRedCardsRaw: homeRC,
      awayRedCardsRaw: awayRC,
      homeRedCardsCount: _redCardsCount(homeRC),
      awayRedCardsCount: _redCardsCount(awayRC),
      status: json['status']?.toString(),
      matchTime: parseDateTime(timeRaw),
      matchTimeRaw: timeRaw,
      matchUrl: json['match_url']?.toString(),
      leagueId: parseIntOrNull(json['league_id']),
      isFavorite: parseBool(json['is_favorite']),
      isFavoriteTeam: parseBool(json['is_favorite_team']),
      isFavoriteLeague: parseBool(json['is_favorite_league']),
      homeIsFavorite: parseBool(json['home_is_favorite']),
      awayIsFavorite: parseBool(json['away_is_favorite']),
      matchNotifications: parseBool(json['match_notifications']),
      predictionsCount:
          parseInt(json['predictions_count'] ?? json['predictions']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'match_date': matchDate,
        'competition': competition,
        'competition_image': competitionImage,
        'home_team': homeTeam,
        'away_team': awayTeam,
        'home_team_image': homeTeamImage,
        'away_team_image': awayTeamImage,
        'home_team_id': homeTeamId,
        'away_team_id': awayTeamId,
        'home_score': homeScore,
        'away_score': awayScore,
        'home_score_pen': homeScorePen,
        'away_score_pen': awayScorePen,
        'home_red_cards': homeRedCardsRaw,
        'away_red_cards': awayRedCardsRaw,
        'status': status,
        'time': matchTimeRaw,
        'match_time': matchTimeRaw,
        'match_url': matchUrl,
        'league_id': leagueId,
        'is_favorite': isFavorite,
        'is_favorite_team': isFavoriteTeam,
        'is_favorite_league': isFavoriteLeague,
        'home_is_favorite': homeIsFavorite,
        'away_is_favorite': awayIsFavorite,
        'match_notifications': matchNotifications,
        'predictions_count': predictionsCount,
        'predictions': predictionsCount,
      };

  // ====== Convenience getters ======

  bool get isLive {
    final s = status?.toUpperCase() ?? '';
    return s == 'LIVE' || s == 'HT' || s.contains("'");
  }

  bool get isFinished {
    const finished = {
      'FT', 'AET', 'PEN', 'RESULT', 'FINISHED', 'FULL TIME', 'FINAL'
    };
    return finished.contains(status?.toUpperCase() ?? '');
  }

  bool get hasScore => homeScore != null && awayScore != null;

  String get scoreLine => hasScore ? '$homeScore - $awayScore' : '- : -';

  static String? _resolveUrl(Object? v) {
    final s = v?.toString();
    if (s == null || s.isEmpty) return null;
    return ApiClient.fixMediaUrl(s);
  }

  static int _redCardsCount(Object? raw) {
    if (raw == null) return 0;
    if (raw is int) return raw;
    if (raw is List) return raw.length;
    if (raw is String) {
      final asInt = int.tryParse(raw);
      if (asInt != null) return asInt;
      // Could be a JSON-encoded array — best-effort length
      if (raw.startsWith('[') && raw.endsWith(']')) {
        final inner = raw.substring(1, raw.length - 1).trim();
        if (inner.isEmpty) return 0;
        return inner.split(',').length;
      }
    }
    return 0;
  }
}
