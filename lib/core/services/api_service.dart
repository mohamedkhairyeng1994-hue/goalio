import 'api_client.dart';
import 'repositories/auth_repository.dart';
import 'repositories/challenge_repository.dart';
import 'repositories/fantasy_repository.dart';
import 'repositories/favorites_repository.dart';
import 'repositories/feedback_repository.dart';
import 'repositories/leagues_repository.dart';
import 'repositories/matches_repository.dart';
import 'repositories/news_repository.dart';
import 'repositories/notifications_repository.dart';
import 'repositories/players_repository.dart';
import 'repositories/social_repository.dart';
import 'repositories/stories_repository.dart';
import 'repositories/teams_repository.dart';

/// Backward-compatible facade.
///
/// This used to be a 1500-line class that owned every HTTP call in the app.
/// It's now a thin shim that delegates each former method to a domain-scoped
/// repository under [repositories/]. Call sites stay identical so production
/// behavior is preserved — new code should prefer importing the relevant
/// repository directly (e.g. [MatchesRepository.getMatches]).
class ApiService {
  // ====== Shared HTTP plumbing ======

  static String get baseUrl => ApiClient.baseUrl;
  static Map<String, String> get headers => ApiClient.headers;
  static Future<Map<String, String>> get reqHeaders => ApiClient.reqHeaders;
  static String fixMediaUrl(String? url) => ApiClient.fixMediaUrl(url);

  static Function? get onUnauthorized => ApiClient.onUnauthorized;
  static set onUnauthorized(Function? cb) => ApiClient.onUnauthorized = cb;

  // ====== Auth ======

  static Future<void> saveToken(String token) => AuthRepository.saveToken(token);
  static Future<void> saveEmail(String email) => AuthRepository.saveEmail(email);
  static Future<String?> getToken() => AuthRepository.getToken();
  static Future<String?> getEmail() => AuthRepository.getEmail();
  static Future<void> clearAuth() => AuthRepository.clearAuth();

  /// Backwards-compat alias retained because older code still calls it.
  static Future<void> clearToken() => AuthRepository.clearAuth();

  static Future<Map<String, dynamic>> signup(
    String fullname,
    String email,
    String password, {
    String? fcmToken,
  }) =>
      AuthRepository.signup(fullname, email, password, fcmToken: fcmToken);

  static Future<Map<String, dynamic>> login(
    String email,
    String password, {
    String? fcmToken,
  }) =>
      AuthRepository.login(email, password, fcmToken: fcmToken);

  static Future<Map<String, dynamic>> socialLogin({
    required String provider,
    required String token,
    String? email,
    String? name,
    String? fcmToken,
  }) =>
      AuthRepository.socialLogin(
        provider: provider,
        token: token,
        email: email,
        name: name,
        fcmToken: fcmToken,
      );

  static Future<Map<String, dynamic>> forgotPassword(String email) =>
      AuthRepository.forgotPassword(email);

  static Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String token,
    required String password,
    required String passwordConfirmation,
  }) =>
      AuthRepository.resetPassword(
        email: email,
        token: token,
        password: password,
        passwordConfirmation: passwordConfirmation,
      );

  static Future<Map<String, dynamic>?> getUserProfile({int? leagueId}) =>
      AuthRepository.getUserProfile(leagueId: leagueId);

  static Future<void> updateFcmToken(String token) =>
      AuthRepository.updateFcmToken(token);

  // ====== Matches ======

  static Future<List<dynamic>> getMatches({String? date}) =>
      MatchesRepository.getMatches(date: date);

  static Future<Map<String, dynamic>?> getMatchById(String id) =>
      MatchesRepository.getMatchById(id);

  static Future<bool> scrapeMatches({String? date}) =>
      MatchesRepository.scrapeMatches(date: date);

  static Future<List<dynamic>> getTodayEplMatches() =>
      MatchesRepository.getTodayEplMatches();

  // ====== News ======

  static Future<List<dynamic>> getNews({
    int limit = 50,
    int offset = 0,
    bool scrape = false,
  }) =>
      NewsRepository.getNews(limit: limit, offset: offset, scrape: scrape);

  static Future<Map<String, dynamic>?> getNewsDetail(int id) =>
      NewsRepository.getNewsDetail(id);

  static Future<List<dynamic>> getNewsForLeague(
    String leagueName, {
    dynamic leagueId,
  }) =>
      NewsRepository.getNewsForLeague(leagueName, leagueId: leagueId);

  static Future<bool> scrapeNewsForLeague(
    String leagueName, {
    dynamic leagueId,
  }) =>
      NewsRepository.scrapeNewsForLeague(leagueName, leagueId: leagueId);

  static Future<bool> scrapeNews() => NewsRepository.scrapeAll();

  // ====== Leagues / Standings ======

  static Future<List<dynamic>> getLeagues({
    int page = 1,
    String search = '',
    bool favoritesOnly = false,
  }) =>
      LeaguesRepository.getLeagues(
        page: page,
        search: search,
        favoritesOnly: favoritesOnly,
      );

  static Future<dynamic> getAllLeagues({
    int page = 1,
    String search = '',
    bool favoritesOnly = false,
  }) =>
      LeaguesRepository.getAllLeagues(
        page: page,
        search: search,
        favoritesOnly: favoritesOnly,
      );

  static Future<bool> scrapeAllLeagues() => LeaguesRepository.scrapeAllLeagues();

  static Future<List<dynamic>> getStandings({
    String? leagueName,
    dynamic leagueId,
  }) =>
      LeaguesRepository.getStandings(
        leagueName: leagueName,
        leagueId: leagueId,
      );

  static Future<bool> scrapeStandingsForLeague(
    String leagueName, {
    dynamic leagueId,
  }) =>
      LeaguesRepository.scrapeStandingsForLeague(leagueName, leagueId: leagueId);

  // ====== Teams ======

  static Future<List<dynamic>> getAllTeams() => TeamsRepository.getAllTeams();

  static Future<Map<String, dynamic>> getTeams({
    int page = 1,
    String? search,
    bool favoritesOnly = false,
  }) =>
      TeamsRepository.getTeams(
        page: page,
        search: search,
        favoritesOnly: favoritesOnly,
      );

  // ====== Favorites ======

  static Future<List<dynamic>> getFavoriteTeams() =>
      FavoritesRepository.getFavoriteTeams();

  static Future<bool> saveFavoriteTeams(List<Map<String, dynamic>> teams) =>
      FavoritesRepository.saveFavoriteTeams(teams);

  static Future<Map<String, dynamic>> toggleFavoriteTeam({
    dynamic teamId,
    String? name,
    String? logo,
    String? leagueName,
  }) =>
      FavoritesRepository.toggleFavoriteTeam(
        teamId: teamId,
        name: name,
        logo: logo,
        leagueName: leagueName,
      );

  static Future<List<dynamic>> getFavoriteLeagues() =>
      FavoritesRepository.getFavoriteLeagues();

  static Future<bool> saveFavoriteLeagues(List<Map<String, dynamic>> leagues) =>
      FavoritesRepository.saveFavoriteLeagues(leagues);

  static Future<Map<String, dynamic>> toggleFavoriteLeague({
    dynamic leagueId,
    String? name,
    String? image,
  }) =>
      FavoritesRepository.toggleFavoriteLeague(
        leagueId: leagueId,
        name: name,
        image: image,
      );

  // ====== Players ======

  static Future<Map<String, List<dynamic>>> getTopPlayersForLeague(
    String leagueName, {
    dynamic leagueId,
  }) =>
      PlayersRepository.getTopPlayersForLeague(leagueName, leagueId: leagueId);

  static Future<bool> scrapeTopPlayersForLeague(
    String leagueName, {
    dynamic leagueId,
  }) =>
      PlayersRepository.scrapeTopPlayersForLeague(leagueName, leagueId: leagueId);

  // ====== Notifications ======

  static Future<Map<String, dynamic>> getNotifications({int page = 1}) =>
      NotificationsRepository.getNotifications(page: page);

  static Future<int> getUnreadNotificationsCount() =>
      NotificationsRepository.getUnreadCount();

  static Future<bool> markNotificationAsRead(int id) =>
      NotificationsRepository.markAsRead(id);

  static Future<bool> markAllNotificationsAsRead() =>
      NotificationsRepository.markAllAsRead();

  static Future<void> markNotificationAsReceived(String messageId) =>
      NotificationsRepository.markAsReceived(messageId);

  static Future<Map<String, dynamic>> toggleMatchNotification(
          dynamic matchId, bool isEnabled) =>
      NotificationsRepository.toggleMatchNotification(matchId, isEnabled);

  static Future<bool> togglePushNotifications(bool isEnabled) =>
      NotificationsRepository.togglePush(isEnabled);

  static Future<Map<String, dynamic>?> getNotificationPreferences() =>
      NotificationsRepository.getPreferences();

  static Future<Map<String, dynamic>?> updateNotificationPreferences(
    Map<String, dynamic> prefs,
  ) =>
      NotificationsRepository.updatePreferences(prefs);

  // ====== Challenges ======

  static Future<List<dynamic>> getChallengeLeagues({int? leagueId}) =>
      ChallengeRepository.getLeagues(leagueId: leagueId);

  static Future<Map<String, dynamic>> createChallengeLeague(
    String name, {
    int? leagueId,
  }) =>
      ChallengeRepository.createLeague(name, leagueId: leagueId);

  static Future<Map<String, dynamic>> joinChallengeLeague(String code) =>
      ChallengeRepository.joinLeague(code);

  static Future<dynamic> getChallengeMatches({String? date, int? leagueId}) =>
      ChallengeRepository.getMatches(date: date, leagueId: leagueId);

  static Future<List<dynamic>> getChallengeDates({int? leagueId}) =>
      ChallengeRepository.getDates(leagueId: leagueId);

  static Future<List<dynamic>> getChallengeLeaguesList() =>
      ChallengeRepository.getLeaguesList();

  static Future<List<dynamic>> getPredictionQuestions(int matchId) =>
      ChallengeRepository.getPredictionQuestions(matchId);

  static Future<Map<String, dynamic>> submitMatchPredictions(
    int matchId,
    List<Map<String, dynamic>> answers,
  ) =>
      ChallengeRepository.submitPredictions(matchId, answers);

  static Future<Map<String, dynamic>> getChallengeLeagueLeaderboard(
    String id, {
    int page = 1,
  }) =>
      ChallengeRepository.getLeaderboard(id, page: page);

  static Future<List<dynamic>> getUserPredictions(
    int userId, {
    int? leagueId,
    String? date,
  }) =>
      ChallengeRepository.getUserPredictions(
        userId,
        leagueId: leagueId,
        date: date,
      );

  // ====== Fantasy ======

  static Future<Map<String, dynamic>> getLeagueFantasy(int leagueId) =>
      FantasyRepository.getLeagueFantasy(leagueId);

  // ====== Social ======

  static Future<Map<String, dynamic>> getSocialPostsPaged({
    int page = 1,
    int limit = 10,
  }) =>
      SocialRepository.getPostsPaged(page: page, limit: limit);

  static Future<List<Map<String, dynamic>>> getSocialPostsSince(int sinceId) =>
      SocialRepository.getPostsSince(sinceId);

  static Future<List<Map<String, dynamic>>> getSocialPosts() =>
      SocialRepository.getPosts();

  static Future<Map<String, dynamic>?> toggleSocialPostLike(int postId) =>
      SocialRepository.toggleLike(postId);

  static Future<Map<String, dynamic>> getSocialPostComments(
    int postId, {
    int page = 1,
    int limit = 10,
  }) =>
      SocialRepository.getComments(postId, page: page, limit: limit);

  static Future<Map<String, dynamic>?> addSocialPostComment(
    int postId,
    String comment, {
    int? parentId,
  }) =>
      SocialRepository.addComment(postId, comment, parentId: parentId);

  static Future<Map<String, dynamic>> createSocialPost({required String content}) =>
      SocialRepository.createPost(content: content);

  static Future<List<Map<String, dynamic>>> getMySocialPosts({
    int page = 1,
    int limit = 20,
  }) =>
      SocialRepository.getMyPosts(page: page, limit: limit);

  // ====== Stories ======

  static Future<List<Map<String, dynamic>>> getStories() =>
      StoriesRepository.getStories();

  static Future<Map<String, dynamic>> createStory({
    required String filePath,
    String? caption,
  }) =>
      StoriesRepository.createStory(filePath: filePath, caption: caption);

  // ====== Feedback ======

  static Future<bool> sendFeedback({
    required String type,
    required String content,
  }) =>
      FeedbackRepository.send(type: type, content: content);
}
