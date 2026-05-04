import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../api_client.dart';

class TeamsRepository {
  static String get _baseUrl => ApiClient.baseUrl;

  static Future<List<dynamic>> getAllTeams() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/teams'),
              headers: await ApiClient.reqHeaders)
          .timeout(const Duration(seconds: 120));

      ApiClient.checkAuth(response);
      debugPrint('getAllTeams status: ${response.statusCode}');
      if (response.statusCode == 200) {
        try {
          return ApiClient.parseList(jsonDecode(response.body));
        } catch (e) {
          debugPrint('JSON Decode Error in getAllTeams: $e');
          return [];
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching all teams: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>> getTeams({
    int page = 1,
    String? search,
    bool favoritesOnly = false,
  }) async {
    try {
      String url = '$_baseUrl/teams?page=$page';
      if (search != null && search.isNotEmpty) {
        url += '&search=${Uri.encodeComponent(search)}';
      }
      if (favoritesOnly) url += '&favorites_only=1';

      final response = await http
          .get(Uri.parse(url), headers: await ApiClient.reqHeaders)
          .timeout(const Duration(seconds: 120));

      ApiClient.checkAuth(response);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {};
    } catch (e) {
      debugPrint('Error fetching teams: $e');
      return {};
    }
  }
}
