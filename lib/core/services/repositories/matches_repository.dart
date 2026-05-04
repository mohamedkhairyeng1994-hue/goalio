import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../models/match.dart';
import '../api_client.dart';

class MatchesRepository {
  static String get _baseUrl => ApiClient.baseUrl;

  // ====== Typed (preferred) ======

  /// Typed equivalent of [getMatches]. Items that aren't object-shaped (e.g.
  /// stray nulls in the response) are skipped.
  static Future<List<MatchModel>> fetchMatches({String? date}) async {
    final raw = await getMatches(date: date);
    final out = <MatchModel>[];
    for (final m in raw) {
      if (m is Map<String, dynamic>) out.add(MatchModel.fromJson(m));
    }
    return out;
  }

  /// Typed equivalent of [getMatchById].
  static Future<MatchModel?> fetchMatchById(String id) async {
    final raw = await getMatchById(id);
    if (raw == null) return null;
    return MatchModel.fromJson(raw);
  }

  // ====== Raw (legacy) ======

  static Future<List<dynamic>> getMatches({String? date}) async {
    try {
      final query = date != null ? '?date=$date' : '';
      final response = await http
          .get(Uri.parse('$_baseUrl/matches$query'),
              headers: await ApiClient.reqHeaders)
          .timeout(const Duration(seconds: 40));

      ApiClient.checkAuth(response);
      if (response.statusCode == 200) {
        return ApiClient.parseList(jsonDecode(response.body));
      }
      debugPrint('API Error getMatches: ${response.statusCode} - ${response.body}');
      return [];
    } catch (e) {
      debugPrint('Error fetching matches: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>?> getMatchById(String id) async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/matches/$id'),
              headers: await ApiClient.reqHeaders)
          .timeout(const Duration(seconds: 30));

      ApiClient.checkAuth(response);
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map && decoded.containsKey('data')) {
          return decoded['data'];
        }
        return decoded as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching match by id $id: $e');
      return null;
    }
  }

  static Future<bool> scrapeMatches({String? date}) async {
    try {
      final query = date != null ? '?date=$date' : '';
      final response = await http
          .get(Uri.parse('$_baseUrl/scrape$query'),
              headers: await ApiClient.reqHeaders)
          .timeout(const Duration(seconds: 120));
      ApiClient.checkAuth(response);
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error scraping matches: $e');
      return false;
    }
  }

  /// Subset of today's matches filtered to England Premier League.
  /// Pulled live from the matches endpoint instead of a static asset so the
  /// home screen always reflects the current schedule.
  static Future<List<dynamic>> getTodayEplMatches() async {
    try {
      final now = DateTime.now();
      final todayStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      final allMatches = await getMatches(date: todayStr);
      final List<dynamic> eplMatches = [];

      for (var match in allMatches) {
        final comp = match['competition']?.toString().toLowerCase() ?? '';
        if (comp.contains('england') && comp.contains('premier league')) {
          eplMatches.add(match);
        }
      }
      return eplMatches;
    } catch (e) {
      if (kDebugMode) debugPrint('Error checking EPL matchday: $e');
      return [];
    }
  }
}
