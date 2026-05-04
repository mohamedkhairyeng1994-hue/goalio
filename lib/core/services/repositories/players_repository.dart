import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../api_client.dart';

class PlayersRepository {
  static String get _baseUrl => ApiClient.baseUrl;

  static Future<Map<String, List<dynamic>>> getTopPlayersForLeague(
    String leagueName, {
    dynamic leagueId,
  }) async {
    try {
      String url = '$_baseUrl/players';
      if (leagueId != null) {
        url += '?league_id=$leagueId';
      } else {
        url += '?league=${Uri.encodeComponent(leagueName)}';
      }

      final response = await http
          .get(Uri.parse(url), headers: await ApiClient.reqHeaders)
          .timeout(const Duration(seconds: 120));

      ApiClient.checkAuth(response);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic>) {
          final Map<String, List<dynamic>> result = {};
          data.forEach((key, value) {
            if (value is List) result[key] = value;
          });
          return result;
        }
      }
      return {};
    } catch (e) {
      debugPrint('Error fetching top players for $leagueName: $e');
      return {};
    }
  }

  static Future<bool> scrapeTopPlayersForLeague(
    String leagueName, {
    dynamic leagueId,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/scrape/players/league'),
            headers: await ApiClient.reqHeaders,
            body: jsonEncode({
              'league_name': leagueName,
              if (leagueId != null) 'league_id': leagueId,
            }),
          )
          .timeout(const Duration(seconds: 120));

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return result['status'] == 'success';
      }
      return false;
    } catch (e) {
      debugPrint('Error scraping top players for $leagueName: $e');
      return false;
    }
  }
}
