import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../models/notification_item.dart';
import '../../models/paginated.dart';
import '../api_client.dart';

/// In-app notifications inbox + push preferences (per-match toggles, global
/// FCM registration, language-aware delivery confirmation).
class NotificationsRepository {
  static String get _baseUrl => ApiClient.baseUrl;

  /// Typed equivalent of [getNotifications].
  static Future<Paginated<NotificationItem>> fetchPage({int page = 1}) async {
    final raw = await getNotifications(page: page);
    return Paginated<NotificationItem>.fromJson(raw, NotificationItem.fromJson);
  }

  static Future<Map<String, dynamic>> getNotifications({int page = 1}) async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/notifications?page=$page'),
              headers: await ApiClient.reqHeaders)
          .timeout(const Duration(seconds: 30));

      ApiClient.checkAuth(response);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {};
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
      return {};
    }
  }

  static Future<int> getUnreadCount() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/notifications/unread-count'),
              headers: await ApiClient.reqHeaders)
          .timeout(const Duration(seconds: 15));

      ApiClient.checkAuth(response);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['unread_count'] ?? 0;
      }
      return 0;
    } catch (e) {
      debugPrint('Error fetching unread count: $e');
      return 0;
    }
  }

  static Future<bool> markAsRead(int id) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/notifications/read'),
            headers: await ApiClient.reqHeaders,
            body: jsonEncode({'notification_id': id}),
          )
          .timeout(const Duration(seconds: 15));
      ApiClient.checkAuth(response);
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
      return false;
    }
  }

  static Future<bool> markAllAsRead() async {
    try {
      final response = await http
          .post(Uri.parse('$_baseUrl/notifications/read-all'),
              headers: await ApiClient.reqHeaders)
          .timeout(const Duration(seconds: 15));
      ApiClient.checkAuth(response);
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
      return false;
    }
  }

  static Future<void> markAsReceived(String messageId) async {
    try {
      await http
          .post(
            Uri.parse('$_baseUrl/notifications/received'),
            headers: await ApiClient.reqHeaders,
            body: jsonEncode({'notification_id': messageId}),
          )
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      if (kDebugMode) debugPrint('Error confirming notification delivery: $e');
    }
  }

  static Future<Map<String, dynamic>> toggleMatchNotification(
      dynamic matchId, bool isEnabled) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/notifications/toggle-match'),
            headers: await ApiClient.reqHeaders,
            body: jsonEncode({'match_id': matchId, 'is_enabled': isEnabled}),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'status': 'error'};
    } catch (e) {
      debugPrint('Error toggling match notification: $e');
      return {'status': 'error'};
    }
  }

  static Future<bool> togglePush(bool isEnabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('notifications_enabled', isEnabled);

      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) return false;

      final response = await http
          .post(
            Uri.parse('$_baseUrl/notifications/toggle-global'),
            headers: await ApiClient.reqHeaders,
            body: jsonEncode({
              'fcm_token': token,
              'notifications_enabled': isEnabled,
            }),
          )
          .timeout(const Duration(seconds: 30));

      return response.statusCode == 200;
    } catch (e) {
      if (kDebugMode) debugPrint('Error toggling global notifications: $e');
      return false;
    }
  }

  static Future<Map<String, dynamic>?> getPreferences() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/notifications/preferences'),
              headers: await ApiClient.reqHeaders)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body is Map && body['data'] is Map) {
          return Map<String, dynamic>.from(body['data'] as Map);
        }
      }
      return null;
    } catch (e) {
      if (kDebugMode) debugPrint('Error fetching notification preferences: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> updatePreferences(
    Map<String, dynamic> prefs,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/notifications/preferences'),
            headers: await ApiClient.reqHeaders,
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
      if (kDebugMode) debugPrint('Error updating notification preferences: $e');
      return null;
    }
  }
}
