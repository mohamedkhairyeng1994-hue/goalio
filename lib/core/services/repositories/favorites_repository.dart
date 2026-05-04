import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../api_client.dart';

/// User favorites — leagues + teams. Also mirrors team-name list to
/// SharedPreferences so the Android home-screen widget (no auth token)
/// can render the user's favorites.
class FavoritesRepository {
  static String get _baseUrl => ApiClient.baseUrl;

  // ====== Leagues ======

  static Future<List<dynamic>> getFavoriteLeagues() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/user/favorite-leagues'),
              headers: await ApiClient.reqHeaders)
          .timeout(const Duration(seconds: 120));

      ApiClient.checkAuth(response);
      if (response.statusCode == 200) {
        return ApiClient.parseList(jsonDecode(response.body));
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching favorite leagues: $e');
      return [];
    }
  }

  static Future<bool> saveFavoriteLeagues(
    List<Map<String, dynamic>> leagues,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/user/favorite-leagues'),
            headers: await ApiClient.reqHeaders,
            body: jsonEncode({'leagues': leagues}),
          )
          .timeout(const Duration(seconds: 120));
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error saving favorite leagues: $e');
      return false;
    }
  }

  static Future<Map<String, dynamic>> toggleFavoriteLeague({
    dynamic leagueId,
    String? name,
    String? image,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/user/toggle-favorite-league'),
            headers: await ApiClient.reqHeaders,
            body: jsonEncode({
              'league_id': leagueId,
              'league_name': name,
              'league_image': image,
            }),
          )
          .timeout(const Duration(seconds: 30));
      return ApiClient.handleResponse(response);
    } catch (e) {
      return {'error': e.toString(), 'code': 500};
    }
  }

  // ====== Teams ======

  static Future<List<dynamic>> getFavoriteTeams() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/user/favorites'),
              headers: await ApiClient.reqHeaders)
          .timeout(const Duration(seconds: 120));

      ApiClient.checkAuth(response);
      if (response.statusCode == 200) {
        final list = ApiClient.parseList(jsonDecode(response.body));
        await _mirrorFavoritesToPrefs(list);
        return list;
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching favorites: $e');
      return [];
    }
  }

  static Future<bool> saveFavoriteTeams(
    List<Map<String, dynamic>> teams,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/user/favorites'),
            headers: await ApiClient.reqHeaders,
            body: jsonEncode({'teams': teams}),
          )
          .timeout(const Duration(seconds: 120));

      if (response.statusCode == 200) {
        await _mirrorFavoritesToPrefs(teams);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error saving favorites: $e');
      return false;
    }
  }

  static Future<Map<String, dynamic>> toggleFavoriteTeam({
    dynamic teamId,
    String? name,
    String? logo,
    String? leagueName,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/user/toggle-favorite-team'),
            headers: await ApiClient.reqHeaders,
            body: jsonEncode({
              'team_id': teamId,
              'team_name': name,
              'team_logo': logo,
              'league_name': leagueName,
            }),
          )
          .timeout(const Duration(seconds: 30));
      return ApiClient.handleResponse(response);
    } catch (e) {
      return {'error': e.toString(), 'code': 500};
    }
  }

  // The Android home-screen widget reads favorite team names directly from
  // SharedPreferences because it has no auth token and can't hit the API.
  static Future<void> _mirrorFavoritesToPrefs(List<dynamic> teams) async {
    final names = teams
        .map((t) => (t is Map ? (t['name'] ?? t['team_name']) : null)
                ?.toString()
                .trim() ??
            '')
        .where((n) => n.isNotEmpty)
        .toSet()
        .toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('favorite_teams', names);
  }
}
