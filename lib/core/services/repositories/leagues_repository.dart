import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../api_client.dart';

/// Leagues catalog + standings (which are scoped per-league).
class LeaguesRepository {
  static String get _baseUrl => ApiClient.baseUrl;

  static Future<List<dynamic>> getLeagues({
    int page = 1,
    String search = '',
    bool favoritesOnly = false,
  }) async {
    try {
      String url = '$_baseUrl/leagues?page=$page&search=$search';
      if (favoritesOnly) url += '&favorites_only=1';

      final response = await http
          .get(Uri.parse(url), headers: await ApiClient.reqHeaders)
          .timeout(const Duration(seconds: 30));

      ApiClient.checkAuth(response);
      if (response.statusCode == 200) {
        return ApiClient.parseList(jsonDecode(response.body));
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching leagues: $e');
      return [];
    }
  }

  static Future<dynamic> getAllLeagues({
    int page = 1,
    String search = '',
    bool favoritesOnly = false,
  }) async {
    try {
      String url =
          '$_baseUrl/leagues/all?page=$page&search=${Uri.encodeComponent(search)}';
      if (favoritesOnly) url += '&favorites_only=1';

      final response = await http
          .get(Uri.parse(url), headers: await ApiClient.reqHeaders)
          .timeout(const Duration(seconds: 30));

      ApiClient.checkAuth(response);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'data': []};
    } catch (e) {
      debugPrint('Error fetching all leagues: $e');
      return {'data': []};
    }
  }

  static Future<bool> scrapeAllLeagues() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/scrape/leagues'),
              headers: await ApiClient.reqHeaders)
          .timeout(const Duration(seconds: 120));
      ApiClient.checkAuth(response);
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error scraping all leagues: $e');
      return false;
    }
  }

  // ====== Standings (scoped to a league) ======

  static Future<List<dynamic>> getStandings({
    String? leagueName,
    dynamic leagueId,
  }) async {
    try {
      String url = '$_baseUrl/standings';
      List<String> params = [];
      if (leagueId != null) {
        params.add('league_id=$leagueId');
      } else if (leagueName != null) {
        params.add('league=${Uri.encodeComponent(leagueName)}');
      }
      if (params.isNotEmpty) url += '?${params.join('&')}';

      final response = await http
          .get(Uri.parse(url), headers: await ApiClient.reqHeaders)
          .timeout(const Duration(seconds: 120));

      ApiClient.checkAuth(response);
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final data = ApiClient.parseList(decoded);

        if (leagueName != null || leagueId != null) {
          return data;
        }
        // No filter — backend may return a Map keyed by league name.
        if (decoded is Map && !decoded.containsKey('data')) {
          List<dynamic> allStandings = [];
          decoded.forEach((league, standings) {
            allStandings.add({'league': league, 'standings': standings});
          });
          return allStandings;
        }
        return data;
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching standings: $e');
      return [];
    }
  }

  static Future<bool> scrapeStandingsForLeague(
    String leagueName, {
    dynamic leagueId,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/scrape/standings/league'),
            headers: await ApiClient.reqHeaders,
            body: jsonEncode({
              'league_name': leagueName,
              if (leagueId != null) 'league_id': leagueId,
            }),
          )
          .timeout(const Duration(seconds: 180));

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return result['status'] == 'success';
      }
      return false;
    } catch (e) {
      debugPrint('Error scraping standings for $leagueName: $e');
      return false;
    }
  }
}
