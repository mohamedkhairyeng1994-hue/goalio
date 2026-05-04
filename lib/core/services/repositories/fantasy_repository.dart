import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../api_client.dart';

class FantasyRepository {
  static String get _baseUrl => ApiClient.baseUrl;

  static Future<Map<String, dynamic>> getLeagueFantasy(int leagueId) async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/fantasy/league/$leagueId/round-team'),
              headers: await ApiClient.reqHeaders)
          .timeout(const Duration(seconds: 30));

      return ApiClient.handleResponse(response);
    } catch (e) {
      if (kDebugMode) debugPrint('Error fetching league fantasy: $e');
      return {'error': 'Connection error', 'code': 500};
    }
  }
}
