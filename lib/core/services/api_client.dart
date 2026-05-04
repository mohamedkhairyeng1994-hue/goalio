import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/constants.dart';

/// Shared HTTP plumbing for every repository: base URL, headers (with bearer
/// token + Accept-Language), response decoding, and the auth-failure callback.
///
/// This class has no domain logic — repositories own that. Pure I/O glue.
class ApiClient {
  static const String tokenKey = 'auth_token';
  static const String userEmailKey = 'user_email';

  static String get baseUrl => ApiConstants.authBaseUrl;

  /// Set by the app shell so repositories can signal token expiry without
  /// importing UI code. Triggered for any 401 response.
  static Function? onUnauthorized;

  static Map<String, String> get headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'User-Agent': 'GoalioApp/1.0',
  };

  /// Headers + bearer token + Accept-Language. Token comes from shared prefs.
  static Future<Map<String, String>> get reqHeaders async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(tokenKey)?.trim();
    final languageCode = prefs.getString('user_language_code') ?? 'en';

    final Map<String, String> currentHeaders = {
      ...headers,
      'Accept-Language': languageCode,
    };

    if (token != null && token.isNotEmpty && token != 'null') {
      return {...currentHeaders, 'Authorization': 'Bearer $token'};
    }
    return currentHeaders;
  }

  /// Fires the unauthorized callback if the response is 401. No-op otherwise.
  static void checkAuth(http.Response response) {
    if (response.statusCode == 401) {
      onUnauthorized?.call();
    }
  }

  /// Decodes a response into a map, surfacing API errors via the {error, code}
  /// shape the rest of the app expects.
  static Map<String, dynamic> handleResponse(http.Response response) {
    checkAuth(response);
    try {
      final decoded = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return decoded is Map<String, dynamic> ? decoded : {'data': decoded};
      }
      return {
        'error':
            decoded is Map
                ? (decoded['detail'] ??
                    decoded['error'] ??
                    decoded['message'] ??
                    'Request failed')
                : 'Request failed',
        'code': response.statusCode,
      };
    } catch (_) {
      return {
        'error': 'Invalid server response: ${response.body}',
        'code': response.statusCode,
      };
    }
  }

  /// Accepts either a List or a {data: [...]} envelope and returns the inner
  /// list. Returns an empty list for unexpected shapes.
  static List<dynamic> parseList(dynamic data) {
    if (data is List) return data;
    if (data is Map && data.containsKey('data')) {
      final list = data['data'];
      if (list is List) return list;
    }
    return [];
  }

  /// Remaps a server-generated URL (e.g. http://scrapping.test/...) to the
  /// correct host for the current platform. On Android emulator, localhost is
  /// reachable as 10.0.2.2 instead of scrapping.test.
  static String fixMediaUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (ApiConstants.currentEnvironment != 'local') return url;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return url
          .replaceFirst('http://scrapping.test', 'http://10.0.2.2/scrapping')
          .replaceFirst('https://scrapping.test', 'http://10.0.2.2/scrapping');
    }
    return url;
  }

  static bool isTransientNetworkError(Object e) {
    final s = e.toString().toLowerCase();
    return s.contains('connection reset') ||
        s.contains('connection closed') ||
        s.contains('socketexception') ||
        s.contains('handshakeexception') ||
        s.contains('connection terminated') ||
        s.contains('errno = 54') ||
        s.contains('errno = 32') ||
        s.contains('clientexception');
  }
}
