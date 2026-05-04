import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../models/story.dart';
import '../api_client.dart';

class StoriesRepository {
  static String get _baseUrl => ApiClient.baseUrl;

  /// Typed variant of [getStories]. Prefer this in new code — it returns
  /// `List<Story>` so call sites get type safety + helpers like [Story.displayLabel].
  static Future<List<Story>> fetchAll() async {
    final raw = await getStories();
    return raw.map(Story.fromJson).toList();
  }

  static Future<List<Map<String, dynamic>>> getStories() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/stories'),
              headers: await ApiClient.reqHeaders)
          .timeout(const Duration(seconds: 20));

      final data = jsonDecode(response.body);
      if (data != null && data['data'] != null) {
        final stories = List<Map<String, dynamic>>.from(data['data']);
        for (final s in stories) {
          if (s['media_url'] != null) {
            s['media_url'] = ApiClient.fixMediaUrl(s['media_url'].toString());
          }
        }
        return stories;
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching stories: $e');
      return [];
    }
  }

  /// Multipart upload for a user-submitted story. Server marks it pending
  /// until an admin approves it.
  static Future<Map<String, dynamic>> createStory({
    required String filePath,
    String? caption,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/stories');
      final request = http.MultipartRequest('POST', uri);
      final headers = await ApiClient.reqHeaders;
      headers.remove('Content-Type'); // multipart sets its own boundary
      request.headers.addAll(headers);
      request.files.add(await http.MultipartFile.fromPath('media', filePath));
      if (caption != null && caption.isNotEmpty) {
        request.fields['caption'] = caption;
      }

      final streamed = await request.send().timeout(const Duration(seconds: 60));
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 201) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      final decoded = jsonDecode(response.body);
      return {
        'error': decoded is Map ? (decoded['message'] ?? decoded['error'] ?? 'Failed') : 'Failed',
        'code': response.statusCode,
      };
    } catch (e) {
      debugPrint('Error creating story: $e');
      return {'error': e.toString(), 'code': 500};
    }
  }
}
