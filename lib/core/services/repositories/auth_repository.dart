import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../api_client.dart';
import '../widget_bridge.dart';

/// Authentication, token storage, profile, and FCM token sync.
class AuthRepository {
  static String get _baseUrl => ApiClient.baseUrl;

  // ====== Token / email persistence ======

  static Future<void> saveToken(String token) async {
    if (token.trim().isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final trimmed = token.trim();
    await prefs.setString(ApiClient.tokenKey, trimmed);
    await WidgetBridge.setAuthToken(trimmed);
  }

  static Future<void> saveEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(ApiClient.userEmailKey, email);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(ApiClient.tokenKey)?.trim();
  }

  static Future<String?> getEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(ApiClient.userEmailKey);
  }

  static Future<void> clearAuth() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(ApiClient.tokenKey);
    await prefs.remove(ApiClient.userEmailKey);
    await WidgetBridge.setAuthToken(null);
  }

  // ====== Auth flows ======

  static Future<Map<String, dynamic>> signup(
    String fullname,
    String email,
    String password, {
    String? fcmToken,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/user/signup'),
            headers: await ApiClient.reqHeaders,
            body: jsonEncode({
              'fullname': fullname,
              'email': email,
              'password': password,
              if (fcmToken != null) 'fcm_token': fcmToken,
            }),
          )
          .timeout(const Duration(seconds: 120));

      final result = ApiClient.handleResponse(response);
      if (result.containsKey('data')) {
        final data = result['data'];
        dynamic token;
        dynamic userEmail;
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
        final token = result['token'];
        final userEmail = result['email'];
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
    final url = '$_baseUrl/user/login';
    final body = jsonEncode({
      'email': email,
      'password': password,
      if (fcmToken != null) 'fcm_token': fcmToken,
    });
    try {
      final response = await http
          .post(Uri.parse(url), headers: await ApiClient.reqHeaders, body: body)
          .timeout(const Duration(seconds: 120));

      final result = ApiClient.handleResponse(response);

      if (result.containsKey('data')) {
        final data = result['data'];
        dynamic token;
        dynamic userEmail;
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
    final url = '$_baseUrl/user/social-login';
    final body = jsonEncode({
      'provider': provider,
      'token': token,
      if (email != null) 'email': email,
      if (name != null) 'name': name,
      if (fcmToken != null) 'fcm_token': fcmToken,
    });

    try {
      final response = await http
          .post(Uri.parse(url), headers: await ApiClient.reqHeaders, body: body)
          .timeout(const Duration(seconds: 120));

      final result = ApiClient.handleResponse(response);

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
      debugPrint('Social login exception: $e');
      return {'error': 'Network error. Please check your connection and try again.', 'code': 500};
    }
  }

  static Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/user/forgot-password'),
            headers: await ApiClient.reqHeaders,
            body: jsonEncode({'email': email}),
          )
          .timeout(const Duration(seconds: 30));
      return ApiClient.handleResponse(response);
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
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/user/reset-password'),
            headers: await ApiClient.reqHeaders,
            body: jsonEncode({
              'email': email,
              'token': token,
              'password': password,
              'password_confirmation': passwordConfirmation,
            }),
          )
          .timeout(const Duration(seconds: 30));
      return ApiClient.handleResponse(response);
    } catch (e) {
      return {'error': 'Connection error: ${e.toString()}', 'code': 500};
    }
  }

  static Future<Map<String, dynamic>?> getUserProfile({int? leagueId}) async {
    try {
      final token = await getToken();
      if (token == null) return null;

      String url = '$_baseUrl/user/me';
      if (leagueId != null) url += '?league_id=$leagueId';

      final response = await http
          .get(Uri.parse(url), headers: await ApiClient.reqHeaders)
          .timeout(const Duration(seconds: 120));

      final result = ApiClient.handleResponse(response);
      
      if (!result.containsKey('error')) {
        if (result.containsKey('data')) {
          final innerData = result['data'];
          if (innerData is Map) {
            return Map<String, dynamic>.from(innerData);
          } else if (innerData is List && innerData.isNotEmpty) {
            return Map<String, dynamic>.from(innerData.first);
          }
        } else if (result.containsKey('id') || result.containsKey('email')) {
          return Map<String, dynamic>.from(result);
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching profile: $e');
      return null;
    }
  }

  static Future<void> updateFcmToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final language = prefs.getString('user_language_code') ?? 'en';
      final notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;

      final response = await http
          .post(
            Uri.parse('$_baseUrl/user/fcm-token'),
            headers: await ApiClient.reqHeaders,
            body: jsonEncode({
              'fcm_token': token,
              'language': language,
              'notifications_enabled': notificationsEnabled,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (kDebugMode) {
        debugPrint('FCM token update status: ${response.statusCode} (Language: $language)');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Error updating FCM token: $e');
    }
  }
}
