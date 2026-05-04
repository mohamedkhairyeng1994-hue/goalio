import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../api_client.dart';

class NewsRepository {
  static String get _baseUrl => ApiClient.baseUrl;

  static Future<List<dynamic>> getNews({
    int limit = 50,
    int offset = 0,
    bool scrape = false,
  }) async {
    try {
      final response = await http
          .get(
            Uri.parse(
              '$_baseUrl/news?limit=$limit&offset=$offset&scrape=${scrape ? "true" : "false"}',
            ),
            headers: await ApiClient.reqHeaders,
          )
          .timeout(const Duration(seconds: 120));

      ApiClient.checkAuth(response);
      if (response.statusCode == 200) {
        return ApiClient.parseList(jsonDecode(response.body));
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching news: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>?> getNewsDetail(int id) async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/news/$id'),
              headers: await ApiClient.reqHeaders)
          .timeout(const Duration(seconds: 40));

      ApiClient.checkAuth(response);
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map && decoded.containsKey('data')) {
          return decoded['data'];
        }
        return decoded;
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching news detail: $e');
      return null;
    }
  }

  static Future<List<dynamic>> getNewsForLeague(
    String leagueName, {
    dynamic leagueId,
  }) async {
    try {
      String url = '$_baseUrl/news/league';
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
        return ApiClient.parseList(jsonDecode(response.body));
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching news for $leagueName: $e');
      return [];
    }
  }

  static Future<bool> scrapeAll() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/scrape/news'),
              headers: await ApiClient.reqHeaders)
          .timeout(const Duration(seconds: 120));
      ApiClient.checkAuth(response);
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error scraping news: $e');
      return false;
    }
  }

  static Future<bool> scrapeNewsForLeague(
    String leagueName, {
    dynamic leagueId,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/scrape/news/league'),
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
      debugPrint('Error scraping news for $leagueName: $e');
      return false;
    }
  }
}
