import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../api_client.dart';

class FeedbackRepository {
  static String get _baseUrl => ApiClient.baseUrl;

  static Future<bool> send({
    required String type,
    required String content,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/user/feedback'),
            headers: await ApiClient.reqHeaders,
            body: jsonEncode({'type': type, 'content': content}),
          )
          .timeout(const Duration(seconds: 30));

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('Error sending feedback: $e');
      return false;
    }
  }
}
