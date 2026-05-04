import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../api_client.dart';

/// Prediction leagues / challenges and their leaderboards.
class ChallengeRepository {
  static String get _baseUrl => ApiClient.baseUrl;

  static Future<List<dynamic>> getLeagues({int? leagueId}) async {
    try {
      String url = '$_baseUrl/challenge/leagues';
      if (leagueId != null) url += '?league_id=$leagueId';

      final response = await http
          .get(Uri.parse(url), headers: await ApiClient.reqHeaders)
          .timeout(const Duration(seconds: 30));

      ApiClient.checkAuth(response);
      if (response.statusCode == 200) {
        // Force UTF-8 decoding. response.body picks the charset from
        // Content-Type and falls back to Latin-1 — that mangles any Arabic
        // bytes (group/user names) and makes jsonDecode throw, which our
        // outer catch then silently turns into an empty list.
        return ApiClient.parseList(jsonDecode(utf8.decode(response.bodyBytes)));
      }
      return [];
    } catch (e) {
      if (kDebugMode) debugPrint('Error fetching challenge leagues: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>> createLeague(String name, {int? leagueId}) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/challenge/leagues/create'),
            headers: await ApiClient.reqHeaders,
            body: jsonEncode({'name': name, 'league_id': leagueId}),
          )
          .timeout(const Duration(seconds: 30));
      return ApiClient.handleResponse(response);
    } catch (e) {
      return {'error': e.toString(), 'code': 500};
    }
  }

  static Future<Map<String, dynamic>> joinLeague(String code) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/challenge/leagues/join'),
            headers: await ApiClient.reqHeaders,
            body: jsonEncode({'code': code}),
          )
          .timeout(const Duration(seconds: 30));
      return ApiClient.handleResponse(response);
    } catch (e) {
      return {'error': e.toString(), 'code': 500};
    }
  }

  static Future<dynamic> getMatches({String? date, int? leagueId}) async {
    try {
      String url = '$_baseUrl/challenge/matches';
      List<String> params = [];
      if (date != null) params.add('date=$date');
      if (leagueId != null) params.add('league_id=$leagueId');
      if (params.isNotEmpty) url += '?${params.join('&')}';

      final response = await http
          .get(Uri.parse(url), headers: await ApiClient.reqHeaders)
          .timeout(const Duration(seconds: 30));

      ApiClient.checkAuth(response);
      if (response.statusCode == 200) {
        final res = jsonDecode(response.body);
        return res['data'];
      }
      return null;
    } catch (e) {
      if (kDebugMode) debugPrint('Error fetching challenge matches: $e');
      return null;
    }
  }

  static Future<List<dynamic>> getDates({int? leagueId}) async {
    try {
      String url = '$_baseUrl/challenge/dates';
      if (leagueId != null) url += '?league_id=$leagueId';

      final response = await http
          .get(Uri.parse(url), headers: await ApiClient.reqHeaders)
          .timeout(const Duration(seconds: 30));

      ApiClient.checkAuth(response);
      if (response.statusCode == 200) {
        return ApiClient.parseList(jsonDecode(response.body));
      }
      return [];
    } catch (e) {
      if (kDebugMode) debugPrint('Error fetching challenge dates: $e');
      return [];
    }
  }

  static Future<List<dynamic>> getLeaguesList() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/challenge/leagues/list'),
              headers: await ApiClient.reqHeaders)
          .timeout(const Duration(seconds: 30));

      ApiClient.checkAuth(response);
      if (response.statusCode == 200) {
        final res = jsonDecode(response.body);
        return ApiClient.parseList(res['data'] ?? res);
      }
      return [];
    } catch (e) {
      if (kDebugMode) debugPrint('Error fetching challenge leagues list: $e');
      return [];
    }
  }

  static Future<List<dynamic>> getPredictionQuestions(int matchId) async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/challenge/questions/$matchId'),
              headers: await ApiClient.reqHeaders)
          .timeout(const Duration(seconds: 30));

      ApiClient.checkAuth(response);
      if (response.statusCode == 200) {
        return ApiClient.parseList(jsonDecode(response.body));
      }
      return [];
    } catch (e) {
      if (kDebugMode) debugPrint('Error fetching prediction questions: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>> submitPredictions(
    int matchId,
    List<Map<String, dynamic>> answers,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/challenge/predictions'),
            headers: await ApiClient.reqHeaders,
            body: jsonEncode({'match_id': matchId, 'answers': answers}),
          )
          .timeout(const Duration(seconds: 30));
      return ApiClient.handleResponse(response);
    } catch (e) {
      return {'error': e.toString(), 'code': 500};
    }
  }

  static Future<Map<String, dynamic>> getLeaderboard(String id, {int page = 1}) async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/challenge/leagues/$id/leaderboard?page=$page'),
              headers: await ApiClient.reqHeaders)
          .timeout(const Duration(seconds: 30));

      ApiClient.checkAuth(response);
      if (response.statusCode == 200) {
        // Force UTF-8 — see note in getLeagues. Without this, an Arabic name
        // anywhere in the response trips jsonDecode and the catch below hides
        // it as an empty leaderboard.
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        return Map<String, dynamic>.from(decoded['data'] ?? {});
      }
      return {};
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('Error fetching challenge league leaderboard: $e\n$st');
      }
      return {};
    }
  }

  static Future<List<dynamic>> getUserPredictions(int userId, {int? leagueId, String? date}) async {
    try {
      String url = '$_baseUrl/challenge/user/$userId/predictions';
      String sep = '?';
      if (leagueId != null) {
        url += '${sep}league_id=$leagueId';
        sep = '&';
      }
      if (date != null) {
        url += '${sep}date=$date';
      }
      final response = await http
          .get(Uri.parse(url), headers: await ApiClient.reqHeaders)
          .timeout(const Duration(seconds: 30));

      ApiClient.checkAuth(response);
      if (response.statusCode == 200) {
        return ApiClient.parseList(jsonDecode(response.body));
      }
      return [];
    } catch (e) {
      if (kDebugMode) debugPrint('Error fetching user predictions: $e');
      return [];
    }
  }
}
