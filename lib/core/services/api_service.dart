import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../core/constants/constants.dart';
import 'widget_bridge.dart';

class ApiService {
  static String get baseUrl => ApiConstants.authBaseUrl;

  static const String _tokenKey = 'auth_token';
  static const String _userEmailKey = 'user_email';

  static Map<String, String> get headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
  };

  static Future<Map<String, String>> get reqHeaders async {
    final token = await getToken();
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString('user_language_code') ?? 'en';

    final Map<String, String> currentHeaders = {
      ...headers,
      'Accept-Language': languageCode,
    };

    if (token != null && token.isNotEmpty && token != "null") {
      return {...currentHeaders, 'Authorization': 'Bearer $token'};
    }
    return currentHeaders;
  }

  static Future<void> saveToken(String token) async {
    if (token.trim().isEmpty) {
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final trimmed = token.trim();
    await prefs.setString(_tokenKey, trimmed);
    await WidgetBridge.setAuthToken(trimmed);
  }

  static Future<void> saveEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userEmailKey, email);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    return token?.trim();
  }

  static Future<String?> getEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userEmailKey);
  }

  static Future<void> clearAuth() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userEmailKey);
    await WidgetBridge.setAuthToken(null);
  }

  static Future<Map<String, dynamic>> getSocialPostsPaged({int page = 1, int limit = 10}) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/social-posts?page=$page&limit=$limit'),
            headers: await reqHeaders,
          )
          .timeout(const Duration(seconds: 30));

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final rawList = List<Map<String, dynamic>>.from(data['data'] ?? []);
      _fixPostUrls(rawList);

      return {
        'data': rawList,
        'next_page_url': data['next_page_url'],
        'current_page': data['current_page'],
        'last_page': data['last_page'],
        'total': data['total'],
      };
    } catch (e) {
      debugPrint('Error getting social posts paged: $e');
      return {'data': <Map<String, dynamic>>[], 'next_page_url': null};
    }
  }

  /// Silently fetch posts newer than [sinceId]. Returns empty list if no new posts.
  static Future<List<Map<String, dynamic>>> getSocialPostsSince(int sinceId) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/social-posts?since_id=$sinceId&limit=50'),
            headers: await reqHeaders,
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);
      if (data != null && data['data'] != null) {
        final posts = List<Map<String, dynamic>>.from(data['data']);
        _fixPostUrls(posts);
        return posts;
      }
      return [];
    } catch (e) {
      debugPrint('Silent poll error: $e');
      return [];
    }
  }

  /// Shared helper — fixes mediaUrl and sourceLogo in-place.
  static void _fixPostUrls(List<Map<String, dynamic>> posts) {
    for (final post in posts) {
      if (post['mediaUrl'] != null) post['mediaUrl'] = fixMediaUrl(post['mediaUrl'].toString());
      if (post['sourceLogo'] != null) post['sourceLogo'] = fixMediaUrl(post['sourceLogo'].toString());
    }
  }


  /// Remaps a server-generated URL (e.g. http://scrapping.test/...) to the
  /// correct host for the current platform. On Android emulator, localhost
  /// is accessible as 10.0.2.2 instead of scrapping.test.
  static String fixMediaUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (ApiConstants.currentEnvironment != 'local') return url;
    // On Android emulator, replace the dev hostname with the emulator gateway
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return url
          .replaceFirst('http://scrapping.test', 'http://10.0.2.2')
          .replaceFirst('https://scrapping.test', 'http://10.0.2.2');
    }
    return url;
  }

  static Future<List<Map<String, dynamic>>> getSocialPosts() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/social-posts'), headers: await reqHeaders)
          .timeout(const Duration(seconds: 30));

      final data = jsonDecode(response.body);
      if (data != null && data['data'] != null) {
        final posts = List<Map<String, dynamic>>.from(data['data']);
        // Fix all media URLs for the current platform
        for (final post in posts) {
          if (post['mediaUrl'] != null) {
            post['mediaUrl'] = fixMediaUrl(post['mediaUrl'].toString());
          }
          if (post['sourceLogo'] != null) {
            post['sourceLogo'] = fixMediaUrl(post['sourceLogo'].toString());
          }
        }
        return posts;
      }
      return [];
    } catch (e) {
      debugPrint('Error getting social posts: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>?> toggleSocialPostLike(int postId) async {
    try {
      final response = await http
          .post(Uri.parse('$baseUrl/social-posts/$postId/toggle-like'), headers: await reqHeaders)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      debugPrint('Error toggling like: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>> getSocialPostComments(int postId, {int page = 1, int limit = 10}) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/social-posts/$postId/comments?page=$page&limit=$limit'), headers: await reqHeaders)
          .timeout(const Duration(seconds: 20));

      final data = jsonDecode(response.body);
      if (data != null && data['data'] != null) {
        final comments = List<Map<String, dynamic>>.from(data['data']);
        for (final c in comments) {
          _fixCommentUrls(c);
        }
        return {
          'data': comments,
          'next_page_url': data['next_page_url'],
        };
      }
      return {'data': <Map<String, dynamic>>[], 'next_page_url': null};
    } catch (e) {
      debugPrint('Error getting comments: $e');
      return {'data': <Map<String, dynamic>>[], 'next_page_url': null};
    }
  }

  static void _fixCommentUrls(Map<String, dynamic> c) {
    if (c['user'] != null && c['user']['avatarUrl'] != null) {
      c['user']['avatarUrl'] = fixMediaUrl(c['user']['avatarUrl'].toString());
    }
    if (c['replies'] != null && c['replies'] is List) {
      final replies = List<Map<String, dynamic>>.from(c['replies']);
      for (final r in replies) {
        _fixCommentUrls(r);
      }
    }
  }

  static Future<Map<String, dynamic>?> addSocialPostComment(int postId, String comment, {int? parentId}) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/social-posts/$postId/comments'),
            headers: await reqHeaders,
            body: jsonEncode({
              'comment': comment,
              if (parentId != null) 'parent_id': parentId,
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 201) {
        final comment = jsonDecode(response.body) as Map<String, dynamic>;
        if (comment['user'] != null && comment['user']['avatarUrl'] != null) {
          comment['user']['avatarUrl'] = fixMediaUrl(comment['user']['avatarUrl'].toString());
        }
        return comment;
      }
      return null;
    } catch (e) {
      debugPrint('Error adding comment: $e');
      return null;
    }
  }

  // Backwards compatibility
  static Future<void> clearToken() async {
    await clearAuth();
  }

  static Future<Map<String, dynamic>> signup(
    String fullname,
    String email,
    String password, {
    String? fcmToken,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/user/signup'),
            headers: await reqHeaders,
            body: jsonEncode({
              'fullname': fullname,
              'email': email,
              'password': password,
              if (fcmToken != null) 'fcm_token': fcmToken,
            }),
          )
          .timeout(const Duration(seconds: 120));

      final result = _handleResponse(response);
      if (result.containsKey('data') && (result['data'] as List).isNotEmpty) {
        final data = result['data'][0];
        final token = data['token'];
        final userEmail = data['email'];

        if (token != null) await saveToken(token);
        if (userEmail != null) await saveEmail(userEmail);
      }
      return result;
    } catch (e) {
      return {'error': 'Connection error: ${e.toString()}', 'code': 500};
    }
  }

  static Future<Map<String, dynamic>> login(
    String email,
    String password, {
    String? fcmToken,
  }) async {
    final url = '$baseUrl/user/login';
    final body = jsonEncode({
      'email': email,
      'password': password,
      if (fcmToken != null) 'fcm_token': fcmToken,
    });
    try {
      final response = await http
          .post(Uri.parse(url), headers: await reqHeaders, body: body)
          .timeout(const Duration(seconds: 120));

      final result = _handleResponse(response);

      // Support both {data: [...]} and {token: ..., email: ...} formats
      if (result.containsKey('data')) {
        final data = result['data'];
        var token;
        var userEmail;
        if (data is List && data.isNotEmpty) {
          token = data[0]['token'];
          userEmail = data[0]['email'];
        } else if (data is Map) {
          token = data['token'];
          userEmail = data['email'];
        }
        if (token != null) await saveToken(token);
        if (userEmail != null) await saveEmail(userEmail);
      } else {
        // Direct token/email at top level
        final token = result['token'];
        final userEmail = result['email'];
        if (token != null) await saveToken(token);
        if (userEmail != null) await saveEmail(userEmail);
      }
      return result;
    } catch (e) {
      debugPrint('Login exception: $e');
      return {'error': 'Connection error: ${e.toString()}', 'code': 500};
    }
  }

  static Future<Map<String, dynamic>> socialLogin({
    required String provider,
    required String token,
    String? email,
    String? name,
    String? fcmToken,
  }) async {
    final url = '$baseUrl/user/social-login';
    final body = jsonEncode({
      'provider': provider,
      'token': token,
      if (email != null) 'email': email,
      if (name != null) 'name': name,
      if (fcmToken != null) 'fcm_token': fcmToken,
    });

    // iOS keep-alive sockets occasionally land on a server-side closed connection
    // (ECONNRESET, errno 54). Retry transient socket failures with a fresh client.
    const maxAttempts = 3;
    Object? lastError;
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      final client = http.Client();
      try {
        final response = await client
            .post(Uri.parse(url), headers: await reqHeaders, body: body)
            .timeout(const Duration(seconds: 120));

        final result = _handleResponse(response);

        if (result.containsKey('data')) {
          final data = result['data'];
          dynamic responseToken;
          dynamic userEmail;
          if (data is List && data.isNotEmpty) {
            responseToken = data[0]['token'];
            userEmail = data[0]['email'];
          } else if (data is Map) {
            responseToken = data['token'];
            userEmail = data['email'];
          }
          if (responseToken != null) await saveToken(responseToken);
          if (userEmail != null) await saveEmail(userEmail);
        } else if (result.containsKey('token')) {
          final responseToken = result['token'];
          final userEmail = result['email'];
          if (responseToken != null) await saveToken(responseToken);
          if (userEmail != null) await saveEmail(userEmail);
        }
        return result;
      } catch (e) {
        lastError = e;
        if (!_isTransientNetworkError(e) || attempt == maxAttempts) break;
        await Future.delayed(Duration(milliseconds: 400 * attempt));
      } finally {
        client.close();
      }
    }
    debugPrint('Social login failed after retries: $lastError');
    return {
      'error': 'Network error. Please check your connection and try again.',
      'code': 0,
    };
  }

  static bool _isTransientNetworkError(Object e) {
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

  static Future<Map<String, dynamic>> forgotPassword(String email) async {
    final url = '$baseUrl/user/forgot-password';
    try {
      final response = await http
          .post(
            Uri.parse(url),
            headers: await reqHeaders,
            body: jsonEncode({'email': email}),
          )
          .timeout(const Duration(seconds: 30));

      return _handleResponse(response);
    } catch (e) {
      return {'error': 'Connection error: ${e.toString()}', 'code': 500};
    }
  }

  static Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String token,
    required String password,
    required String passwordConfirmation,
  }) async {
    final url = '$baseUrl/user/reset-password';
    try {
      final response = await http
          .post(
            Uri.parse(url),
            headers: await reqHeaders,
            body: jsonEncode({
              'email': email,
              'token': token,
              'password': password,
              'password_confirmation': passwordConfirmation,
            }),
          )
          .timeout(const Duration(seconds: 30));

      return _handleResponse(response);
    } catch (e) {
      return {'error': 'Connection error: ${e.toString()}', 'code': 500};
    }
  }

  static Future<List<dynamic>> getFavoriteTeams() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/user/favorites'), headers: await reqHeaders)
          .timeout(const Duration(seconds: 120));

      _checkAuth(response);
      if (response.statusCode == 200) {
        final list = _parseList(jsonDecode(response.body));
        await _mirrorFavoritesToPrefs(list);
        return list;
      }
      return [];
    } catch (e) {
      debugPrint("Error fetching favorites: $e");
      return [];
    }
  }

  // Mirrors favorite team names into SharedPreferences so the Android home-screen
  // widget can read them (the widget has no auth token, so it can't hit the API).
  static Future<void> _mirrorFavoritesToPrefs(List<dynamic> teams) async {
    final names = teams
        .map((t) => (t is Map ? (t['name'] ?? t['team_name']) : null)?.toString().trim() ?? '')
        .where((n) => n.isNotEmpty)
        .toSet()
        .toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('favorite_teams', names);
  }

  static Future<List<dynamic>> getStandings({
    String? leagueName,
    dynamic leagueId,
  }) async {
    try {
      String url = '$baseUrl/standings';
      List<String> params = [];
      if (leagueId != null) {
        params.add('league_id=$leagueId');
      } else if (leagueName != null) {
        params.add('league=${Uri.encodeComponent(leagueName)}');
      }

      if (params.isNotEmpty) {
        url += '?${params.join('&')}';
      }

      final response = await http
          .get(Uri.parse(url), headers: await reqHeaders)
          .timeout(const Duration(seconds: 120));

      _checkAuth(response);
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final data = _parseList(decoded);

        if (leagueName != null || leagueId != null) {
          return data;
        } else {
          // If leagueName/leagueId is null, the backend might return a Map our helper couldn't parse as a list
          if (decoded is Map && !decoded.containsKey('data')) {
            List<dynamic> allStandings = [];
            decoded.forEach((league, standings) {
              allStandings.add({'league': league, 'standings': standings});
            });
            return allStandings;
          }
          return data;
        }
      }
      return [];
    } catch (e) {
      debugPrint("Error fetching standings: $e");
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
            Uri.parse('$baseUrl/scrape/standings/league'),
            headers: await reqHeaders,
            body: jsonEncode({
              'league_name': leagueName,
              if (leagueId != null) 'league_id': leagueId,
            }),
          )
          .timeout(
            const Duration(seconds: 180),
          ); // 3 minutes timeout for scraping

      debugPrint('Standings scrape response status: ${response.statusCode}');
      debugPrint('Standings scrape response body: ${response.body}');

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return result['status'] == 'success';
      }
      return false;
    } catch (e) {
      debugPrint("Error scraping standings for $leagueName: $e");
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
            Uri.parse('$baseUrl/scrape/news/league'),
            headers: await reqHeaders,
            body: jsonEncode({
              'league_name': leagueName,
              if (leagueId != null) 'league_id': leagueId,
            }),
          )
          .timeout(const Duration(seconds: 120));

      debugPrint('News scrape response status: ${response.statusCode}');
      debugPrint('News scrape response body: ${response.body}');

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return result['status'] == 'success';
      }
      return false;
    } catch (e) {
      debugPrint("Error scraping news for $leagueName: $e");
      return false;
    }
  }

  static Future<List<dynamic>> getNewsForLeague(
    String leagueName, {
    dynamic leagueId,
  }) async {
    try {
      String url = '$baseUrl/news/league';
      if (leagueId != null) {
        url += '?league_id=$leagueId';
      } else {
        url += '?league=${Uri.encodeComponent(leagueName)}';
      }

      final response = await http
          .get(Uri.parse(url), headers: await reqHeaders)
          .timeout(const Duration(seconds: 120));

      _checkAuth(response);
      if (response.statusCode == 200) {
        return _parseList(jsonDecode(response.body));
      }
      return [];
    } catch (e) {
      debugPrint("Error fetching news for $leagueName: $e");
      return [];
    }
  }

  static Future<Map<String, List<dynamic>>> getTopPlayersForLeague(
    String leagueName, {
    dynamic leagueId,
  }) async {
    try {
      String url = '$baseUrl/players';
      if (leagueId != null) {
        url += '?league_id=$leagueId';
      } else {
        url += '?league=${Uri.encodeComponent(leagueName)}';
      }

      final response = await http
          .get(Uri.parse(url), headers: await reqHeaders)
          .timeout(const Duration(seconds: 120));

      _checkAuth(response);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic>) {
          // Convert dynamic values to List<dynamic>
          Map<String, List<dynamic>> result = {};
          data.forEach((key, value) {
            if (value is List) {
              result[key] = value;
            }
          });
          return result;
        }
      }
      return {};
    } catch (e) {
      debugPrint("Error fetching top players for $leagueName: $e");
      return {};
    }
  }

  static Future<Map<String, dynamic>> getLeagueFantasy(int leagueId) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/fantasy/league/$leagueId/round-team'),
            headers: await reqHeaders,
          )
          .timeout(const Duration(seconds: 30));

      return _handleResponse(response);
    } catch (e) {
      if (kDebugMode) debugPrint("Error fetching league fantasy: $e");
      return {'error': 'Connection error', 'code': 500};
    }
  }

  static Future<bool> scrapeTopPlayersForLeague(
    String leagueName, {
    dynamic leagueId,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/scrape/players/league'),
            headers: await reqHeaders,
            body: jsonEncode({
              'league_name': leagueName,
              if (leagueId != null) 'league_id': leagueId,
            }),
          )
          .timeout(const Duration(seconds: 120));

      debugPrint('Players scrape response status: ${response.statusCode}');
      debugPrint('Players scrape response body: ${response.body}');

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return result['status'] == 'success';
      }
      return false;
    } catch (e) {
      debugPrint("Error scraping top players for $leagueName: $e");
      return false;
    }
  }

  static Future<List<dynamic>> getFavoriteLeagues() async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/user/favorite-leagues'),
            headers: await reqHeaders,
          )
          .timeout(const Duration(seconds: 120));

      _checkAuth(response);
      if (response.statusCode == 200) {
        return _parseList(jsonDecode(response.body));
      }
      return [];
    } catch (e) {
      debugPrint("Error fetching favorite leagues: $e");
      return [];
    }
  }

  static Future<List<dynamic>> getAllTeams() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/teams'), headers: await reqHeaders)
          .timeout(const Duration(seconds: 120));

      _checkAuth(response);
      debugPrint("getAllTeams status: ${response.statusCode}");
      if (response.statusCode == 200) {
        try {
          return _parseList(jsonDecode(response.body));
        } catch (e) {
          debugPrint("JSON Decode Error in getAllTeams: $e");
          return [];
        }
      }
      return [];
    } catch (e) {
      debugPrint("Error fetching all teams: $e");
      return [];
    }
  }

  static Future<Map<String, dynamic>> getTeams({
    int page = 1,
    String? search,
    bool favoritesOnly = false,
  }) async {
    try {
      String url = '$baseUrl/teams?page=$page';
      if (search != null && search.isNotEmpty) {
        url += '&search=${Uri.encodeComponent(search)}';
      }
      if (favoritesOnly) {
        url += '&favorites_only=1';
      }
      final response = await http
          .get(Uri.parse(url), headers: await reqHeaders)
          .timeout(const Duration(seconds: 120));

      _checkAuth(response);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {};
    } catch (e) {
      debugPrint("Error fetching teams: $e");
      return {};
    }
  }

  static Future<Map<String, dynamic>?> getUserProfile({int? leagueId}) async {
    try {
      final token = await getToken();
      if (token == null) return null;

      String url = '$baseUrl/user/me';
      if (leagueId != null) {
        url += '?league_id=$leagueId';
      }

      final response = await http
          .get(Uri.parse(url), headers: await reqHeaders)
          .timeout(const Duration(seconds: 120));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map && data.containsKey('data')) {
          return data['data'];
        }
      }
      return null;
    } catch (e) {
      debugPrint("Error fetching profile: $e");
      return null;
    }
  }

  static Future<Map<String, dynamic>> getNotifications({int page = 1}) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/notifications?page=$page'), headers: await reqHeaders)
          .timeout(const Duration(seconds: 30));

      _checkAuth(response);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {};
    } catch (e) {
      debugPrint("Error fetching notifications: $e");
      return {};
    }
  }

  static Future<int> getUnreadNotificationsCount() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/notifications/unread-count'), headers: await reqHeaders)
          .timeout(const Duration(seconds: 15));

      _checkAuth(response);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['unread_count'] ?? 0;
      }
      return 0;
    } catch (e) {
      debugPrint("Error fetching unread count: $e");
      return 0;
    }
  }

  static Future<bool> markNotificationAsRead(int id) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/notifications/read'), 
            headers: await reqHeaders,
            body: jsonEncode({'notification_id': id})
          )
          .timeout(const Duration(seconds: 15));

      _checkAuth(response);
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("Error marking notification as read: $e");
      return false;
    }
  }

  static Future<bool> markAllNotificationsAsRead() async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/notifications/read-all'), 
            headers: await reqHeaders
          )
          .timeout(const Duration(seconds: 15));

      _checkAuth(response);
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("Error marking all notifications as read: $e");
      return false;
    }
  }

  static Future<List<dynamic>> getMatches({String? date}) async {
    try {
      final query = date != null ? '?date=$date' : '';
      final response = await http
          .get(Uri.parse('$baseUrl/matches$query'), headers: await reqHeaders)
          .timeout(const Duration(seconds: 40));

      _checkAuth(response);
      if (response.statusCode == 200) {
        return _parseList(jsonDecode(response.body));
      } else {
        debugPrint(
          "API Error getMatches: ${response.statusCode} - ${response.body}",
        );
        return [];
      }
    } catch (e) {
      debugPrint("Error fetching matches: $e");
      return [];
    }
  }

  static Future<Map<String, dynamic>?> getMatchById(String id) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/matches/$id'), headers: await reqHeaders)
          .timeout(const Duration(seconds: 30));

      _checkAuth(response);
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map && decoded.containsKey('data')) {
          return decoded['data'];
        }
        return decoded as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      debugPrint("Error fetching match by id $id: $e");
      return null;
    }
  }

  static Future<List<dynamic>> getNews({
    int limit = 50,
    int offset = 0,
    bool scrape = false,
  }) async {
    try {
      final response = await http
          .get(
            Uri.parse(
              '$baseUrl/news?limit=$limit&offset=$offset&scrape=${scrape ? "true" : "false"}',
            ),
            headers: await reqHeaders,
          )
          .timeout(const Duration(seconds: 120));

      _checkAuth(response);
      if (response.statusCode == 200) {
        return _parseList(jsonDecode(response.body));
      }
      return [];
    } catch (e) {
      debugPrint("Error fetching news: $e");
      return [];
    }
  }

  static Future<Map<String, dynamic>?> getNewsDetail(int id) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/news/$id'), headers: await reqHeaders)
          .timeout(const Duration(seconds: 40));

      _checkAuth(response);
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map && decoded.containsKey('data')) {
          return decoded['data'];
        }
        return decoded;
      }
      return null;
    } catch (e) {
      debugPrint("Error fetching news detail: $e");
      return null;
    }
  }

  static Future<List<dynamic>> getLeagues({
    int page = 1,
    String search = '',
    bool favoritesOnly = false,
  }) async {
    try {
      String url = '$baseUrl/leagues?page=$page&search=$search';
      if (favoritesOnly) {
        url += '&favorites_only=1';
      }
      final response = await http
          .get(Uri.parse(url), headers: await reqHeaders)
          .timeout(const Duration(seconds: 30));

      _checkAuth(response);
      if (response.statusCode == 200) {
        return _parseList(jsonDecode(response.body));
      }
      return [];
    } catch (e) {
      debugPrint("Error fetching leagues: $e");
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
          '$baseUrl/leagues/all?page=$page&search=${Uri.encodeComponent(search)}';
      if (favoritesOnly) {
        url += '&favorites_only=1';
      }
      final response = await http
          .get(Uri.parse(url), headers: await reqHeaders)
          .timeout(const Duration(seconds: 30));

      _checkAuth(response);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'data': []};
    } catch (e) {
      debugPrint("Error fetching all leagues: $e");
      return {'data': []};
    }
  }

  static Future<bool> scrapeAllLeagues() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/scrape/leagues'), headers: await reqHeaders)
          .timeout(const Duration(seconds: 120));
      _checkAuth(response);
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("Error scraping all leagues: $e");
      return false;
    }
  }

  static Future<bool> scrapeNews() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/scrape/news'), headers: await reqHeaders)
          .timeout(const Duration(seconds: 120));
      _checkAuth(response);
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("Error scraping news: $e");
      return false;
    }
  }

  static Future<bool> scrapeMatches({String? date}) async {
    try {
      final query = date != null ? '?date=$date' : '';
      final response = await http
          .get(Uri.parse('$baseUrl/scrape$query'), headers: await reqHeaders)
          .timeout(const Duration(seconds: 120));
      _checkAuth(response);
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("Error scraping matches: $e");
      return false;
    }
  }

  static Future<bool> saveFavoriteLeagues(
    List<Map<String, dynamic>> leagues,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/user/favorite-leagues'),
            headers: await reqHeaders,
            body: jsonEncode({'leagues': leagues}),
          )
          .timeout(const Duration(seconds: 120));

      return response.statusCode == 200;
    } catch (e) {
      debugPrint("Error saving favorite leagues: $e");
      return false;
    }
  }

  static Future<Map<String, dynamic>> toggleMatchNotification(
      dynamic matchId, bool isEnabled) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/notifications/toggle-match'),
            headers: await reqHeaders,
            body: jsonEncode({'match_id': matchId, 'is_enabled': isEnabled}),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'status': 'error'};
    } catch (e) {
      debugPrint("Error toggling match notification: $e");
      return {'status': 'error'};
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
            Uri.parse('$baseUrl/user/toggle-favorite-team'),
            headers: await reqHeaders,
            body: jsonEncode({
              'team_id': teamId,
              'team_name': name,
              'team_logo': logo,
              'league_name': leagueName,
            }),
          )
          .timeout(const Duration(seconds: 30));

      return _handleResponse(response);
    } catch (e) {
      return {'error': e.toString(), 'code': 500};
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
            Uri.parse('$baseUrl/user/toggle-favorite-league'),
            headers: await reqHeaders,
            body: jsonEncode({
              'league_id': leagueId,
              'league_name': name,
              'league_image': image,
            }),
          )
          .timeout(const Duration(seconds: 30));

      return _handleResponse(response);
    } catch (e) {
      return {'error': e.toString(), 'code': 500};
    }
  }

  static Future<bool> saveFavoriteTeams(
    List<Map<String, dynamic>> teams,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/user/favorites'),
            headers: await reqHeaders,
            body: jsonEncode({'teams': teams}),
          )
          .timeout(const Duration(seconds: 120));

      if (response.statusCode == 200) {
        await _mirrorFavoritesToPrefs(teams);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("Error saving favorites: $e");
      return false;
    }
  }

  static Future<bool> sendFeedback({
    required String type,
    required String content,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/user/feedback'),
            headers: await reqHeaders,
            body: jsonEncode({'type': type, 'content': content}),
          )
          .timeout(const Duration(seconds: 30));

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint("Error sending feedback: $e");
      return false;
    }
  }

  static Function? onUnauthorized;

  static void _checkAuth(http.Response response) {
    if (response.statusCode == 401) {
      if (kDebugMode) {
        debugPrint(
          "ApiService: 401 Unauthorized detected for ${response.request?.url}!",
        );
      }
      if (onUnauthorized != null) {
        if (kDebugMode) {
          debugPrint("ApiService: Triggering onUnauthorized callback...");
        }
        onUnauthorized!();
      }
    }
  }

  static Map<String, dynamic> _handleResponse(http.Response response) {
    _checkAuth(response);
    try {
      final decoded = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return decoded;
      } else {
        return {
          'error':
              decoded['detail'] ??
              decoded['error'] ??
              decoded['message'] ??
              'Request failed',
          'code': response.statusCode,
        };
      }
    } catch (e) {
      return {
        'error': 'Invalid server response: ${response.body}',
        'code': response.statusCode,
      };
    }
  }

  static List<dynamic> _parseList(dynamic data) {
    if (data is List) return data;
    if (data is Map && data.containsKey('data')) {
      final list = data['data'];
      if (list is List) return list;
    }
    return [];
  }

  static Future<List<dynamic>> getTodayEplMatches() async {
    try {
      final now = DateTime.now();
      final todayStr =
          "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

      // Fetch today's matches from the database instead of a static JSON file
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
      if (kDebugMode) debugPrint("Error checking EPL matchday: $e");
      return [];
    }
  }

  static Future<List<dynamic>> getChallengeLeagues({int? leagueId}) async {
    try {
      String url = '$baseUrl/challenge/leagues';
      if (leagueId != null) {
        url += '?league_id=$leagueId';
      }
      final response = await http
          .get(Uri.parse(url), headers: await reqHeaders)
          .timeout(const Duration(seconds: 30));

      _checkAuth(response);
      if (response.statusCode == 200) {
        return _parseList(jsonDecode(response.body));
      }
      return [];
    } catch (e) {
      if (kDebugMode) debugPrint("Error fetching challenge leagues: $e");
      return [];
    }
  }

  static Future<Map<String, dynamic>> createChallengeLeague(String name, {int? leagueId}) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/challenge/leagues/create'),
            headers: await reqHeaders,
            body: jsonEncode({
              'name': name,
              'league_id': leagueId,
            }),
          )
          .timeout(const Duration(seconds: 30));

      return _handleResponse(response);
    } catch (e) {
      return {'error': e.toString(), 'code': 500};
    }
  }

  static Future<Map<String, dynamic>> joinChallengeLeague(String code) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/challenge/leagues/join'),
            headers: await reqHeaders,
            body: jsonEncode({'code': code}),
          )
          .timeout(const Duration(seconds: 30));

      return _handleResponse(response);
    } catch (e) {
      return {'error': e.toString(), 'code': 500};
    }
  }

  static Future<dynamic> getChallengeMatches({String? date, int? leagueId}) async {
    try {
      String url = '$baseUrl/challenge/matches';
      List<String> params = [];
      if (date != null) params.add('date=$date');
      if (leagueId != null) params.add('league_id=$leagueId');
      
      if (params.isNotEmpty) {
        url += '?${params.join('&')}';
      }
      
      final response = await http
          .get(Uri.parse(url), headers: await reqHeaders)
          .timeout(const Duration(seconds: 30));

      _checkAuth(response);
      if (response.statusCode == 200) {
        final res = jsonDecode(response.body);
        return res['data'];
      }
      return null;
    } catch (e) {
      if (kDebugMode) debugPrint("Error fetching challenge matches: $e");
      return null;
    }
  }

  static Future<List<dynamic>> getChallengeDates({int? leagueId}) async {
    try {
      String url = '$baseUrl/challenge/dates';
      if (leagueId != null) {
        url += '?league_id=$leagueId';
      }
      final response = await http
          .get(Uri.parse(url), headers: await reqHeaders)
          .timeout(const Duration(seconds: 30));

      _checkAuth(response);
      if (response.statusCode == 200) {
        return _parseList(jsonDecode(response.body));
      }
      return [];
    } catch (e) {
      if (kDebugMode) debugPrint("Error fetching challenge dates: $e");
      return [];
    }
  }

  static Future<List<dynamic>> getChallengeLeaguesList() async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/challenge/leagues/list'),
            headers: await reqHeaders,
          )
          .timeout(const Duration(seconds: 30));

      _checkAuth(response);
      if (response.statusCode == 200) {
        final res = jsonDecode(response.body);
        return _parseList(res['data'] ?? res);
      }
      return [];
    } catch (e) {
      if (kDebugMode) debugPrint("Error fetching challenge leagues list: $e");
      return [];
    }
  }

  static Future<List<dynamic>> getPredictionQuestions(int matchId) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/challenge/questions/$matchId'),
            headers: await reqHeaders,
          )
          .timeout(const Duration(seconds: 30));

      _checkAuth(response);
      if (response.statusCode == 200) {
        return _parseList(jsonDecode(response.body));
      }
      return [];
    } catch (e) {
      if (kDebugMode) debugPrint("Error fetching prediction questions: $e");
      return [];
    }
  }

  static Future<Map<String, dynamic>> submitMatchPredictions(
    int matchId,
    List<Map<String, dynamic>> answers,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/challenge/predictions'),
            headers: await reqHeaders,
            body: jsonEncode({'match_id': matchId, 'answers': answers}),
          )
          .timeout(const Duration(seconds: 30));

      return _handleResponse(response);
    } catch (e) {
      return {'error': e.toString(), 'code': 500};
    }
  }

  static Future<Map<String, dynamic>> getChallengeLeagueLeaderboard(String id, {int page = 1}) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/challenge/leagues/$id/leaderboard?page=$page'),
            headers: await reqHeaders,
          )
          .timeout(const Duration(seconds: 30));

      _checkAuth(response);
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        return Map<String, dynamic>.from(decoded['data'] ?? {});
      }
      return {};
    } catch (e) {
      if (kDebugMode)
        debugPrint("Error fetching challenge league leaderboard: $e");
      return {};
    }
  }

  static Future<List<dynamic>> getUserPredictions(int userId, {int? leagueId, String? date}) async {
    try {
      String url = '$baseUrl/challenge/user/$userId/predictions';
      String sep = '?';
      if (leagueId != null) {
        url += '$sep' + 'league_id=$leagueId';
        sep = '&';
      }
      if (date != null) {
        url += '$sep' + 'date=$date';
      }
      final response = await http
          .get(Uri.parse(url), headers: await reqHeaders)
          .timeout(const Duration(seconds: 30));

      _checkAuth(response);
      if (response.statusCode == 200) {
        return _parseList(jsonDecode(response.body));
      }
      return [];
    } catch (e) {
      if (kDebugMode) debugPrint("Error fetching user predictions: $e");
      return [];
    }
  }

  static Future<void> updateFcmToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final language = prefs.getString('user_language_code') ?? 'en';
      final notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;

      final response = await http
          .post(
            Uri.parse('$baseUrl/user/fcm-token'),
            headers: await reqHeaders,
            body: jsonEncode({
              'fcm_token': token,
              'language': language,
              'notifications_enabled': notificationsEnabled,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (kDebugMode) {
        debugPrint(
          "FCM token update status: ${response.statusCode} (Language: $language)",
        );
      }
    } catch (e) {
      if (kDebugMode) debugPrint("Error updating FCM token: $e");
    }
  }

  static Future<bool> togglePushNotifications(bool isEnabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('notifications_enabled', isEnabled);

      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) return false;

      final response = await http
          .post(
            Uri.parse('$baseUrl/notifications/toggle-global'),
            headers: await reqHeaders,
            body: jsonEncode({
              'fcm_token': token,
              'notifications_enabled': isEnabled,
            }),
          )
          .timeout(const Duration(seconds: 30));

      return response.statusCode == 200;
    } catch (e) {
      if (kDebugMode) debugPrint("Error toggling global notifications: $e");
      return false;
    }
  }

  static Future<Map<String, dynamic>?> getNotificationPreferences() async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/notifications/preferences'),
            headers: await reqHeaders,
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body is Map && body['data'] is Map) {
          return Map<String, dynamic>.from(body['data'] as Map);
        }
      }
      return null;
    } catch (e) {
      if (kDebugMode) debugPrint("Error fetching notification preferences: $e");
      return null;
    }
  }

  static Future<Map<String, dynamic>?> updateNotificationPreferences(
    Map<String, dynamic> prefs,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/notifications/preferences'),
            headers: await reqHeaders,
            body: jsonEncode(prefs),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body is Map && body['data'] is Map) {
          return Map<String, dynamic>.from(body['data'] as Map);
        }
      }
      return null;
    } catch (e) {
      if (kDebugMode) debugPrint("Error updating notification preferences: $e");
      return null;
    }
  }

  static Future<void> markNotificationAsReceived(String messageId) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/notifications/received'),
            headers: await reqHeaders,
            body: jsonEncode({'notification_id': messageId}),
          )
          .timeout(const Duration(seconds: 10));

      if (kDebugMode) {
        debugPrint(
          "Notification delivery confirmation status: ${response.statusCode}",
        );
      }
    } catch (e) {
      if (kDebugMode) debugPrint("Error confirming notification delivery: $e");
    }
  }
}
