import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../models/paginated.dart';
import '../../models/social_post.dart';
import '../../models/social_post_comment.dart';
import '../api_client.dart';

/// Social feed: posts, paged + silent polling, likes, comments, plus
/// user-submitted posts that go through admin approval.
class SocialRepository {
  static String get _baseUrl => ApiClient.baseUrl;

  // ====== Typed reads (preferred) ======

  /// Typed equivalent of [getPostsPaged]. Returns a `Paginated<SocialPost>`.
  static Future<Paginated<SocialPost>> fetchPostsPaged({
    int page = 1,
    int limit = 10,
  }) async {
    final raw = await getPostsPaged(page: page, limit: limit);
    return Paginated<SocialPost>.fromJson(raw, SocialPost.fromJson);
  }

  /// Typed equivalent of [getPostsSince].
  static Future<List<SocialPost>> fetchPostsSince(int sinceId) async {
    final raw = await getPostsSince(sinceId);
    return raw.map(SocialPost.fromJson).toList();
  }

  /// Typed equivalent of [getComments]. Returns a paginator-shaped result;
  /// the comment endpoint doesn't include `total`/`last_page` reliably so the
  /// caller should treat those as best-effort.
  static Future<Paginated<SocialPostComment>> fetchComments(
    int postId, {
    int page = 1,
    int limit = 10,
  }) async {
    final raw = await getComments(postId, page: page, limit: limit);
    return Paginated<SocialPostComment>.fromJson(
      raw,
      SocialPostComment.fromJson,
    );
  }

  // ====== Reads ======

  static Future<Map<String, dynamic>> getPostsPaged({
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/social-posts?page=$page&limit=$limit'),
            headers: await ApiClient.reqHeaders,
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

  /// Silently fetch posts newer than [sinceId]. Used by the social page's
  /// background poll so a "N new posts" banner can appear without disturbing
  /// the user's scroll position.
  static Future<List<Map<String, dynamic>>> getPostsSince(int sinceId) async {
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/social-posts?since_id=$sinceId&limit=50'),
            headers: await ApiClient.reqHeaders,
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

  static Future<List<Map<String, dynamic>>> getPosts() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/social-posts'),
              headers: await ApiClient.reqHeaders)
          .timeout(const Duration(seconds: 30));

      final data = jsonDecode(response.body);
      if (data != null && data['data'] != null) {
        final posts = List<Map<String, dynamic>>.from(data['data']);
        _fixPostUrls(posts);
        return posts;
      }
      return [];
    } catch (e) {
      debugPrint('Error getting social posts: $e');
      return [];
    }
  }

  // ====== Likes ======

  static Future<Map<String, dynamic>?> toggleLike(int postId) async {
    try {
      final response = await http
          .post(Uri.parse('$_baseUrl/social-posts/$postId/toggle-like'),
              headers: await ApiClient.reqHeaders)
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

  // ====== Comments ======

  static Future<Map<String, dynamic>> getComments(int postId,
      {int page = 1, int limit = 10}) async {
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/social-posts/$postId/comments?page=$page&limit=$limit'),
            headers: await ApiClient.reqHeaders,
          )
          .timeout(const Duration(seconds: 20));

      final data = jsonDecode(response.body);
      if (data != null && data['data'] != null) {
        final comments = List<Map<String, dynamic>>.from(data['data']);
        for (final c in comments) {
          _fixCommentUrls(c);
        }
        return {'data': comments, 'next_page_url': data['next_page_url']};
      }
      return {'data': <Map<String, dynamic>>[], 'next_page_url': null};
    } catch (e) {
      debugPrint('Error getting comments: $e');
      return {'data': <Map<String, dynamic>>[], 'next_page_url': null};
    }
  }

  static Future<Map<String, dynamic>?> addComment(
    int postId,
    String comment, {
    int? parentId,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/social-posts/$postId/comments'),
            headers: await ApiClient.reqHeaders,
            body: jsonEncode({
              'comment': comment,
              if (parentId != null) 'parent_id': parentId,
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 201) {
        final c = jsonDecode(response.body) as Map<String, dynamic>;
        _fixCommentUrls(c);
        return c;
      }
      return null;
    } catch (e) {
      debugPrint('Error adding comment: $e');
      return null;
    }
  }

  // ====== User-submitted posts (held for admin approval) ======

  static Future<Map<String, dynamic>> createPost({required String content}) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/social-posts'),
            headers: await ApiClient.reqHeaders,
            body: jsonEncode({'content': content}),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 201) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      final decoded = jsonDecode(response.body);
      return {
        'error': decoded is Map ? (decoded['message'] ?? decoded['error'] ?? 'Failed') : 'Failed',
        'code': response.statusCode,
      };
    } catch (e) {
      debugPrint('Error creating social post: $e');
      return {'error': e.toString(), 'code': 500};
    }
  }

  static Future<List<Map<String, dynamic>>> getMyPosts({int page = 1, int limit = 20}) async {
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/social-posts/mine?page=$page&limit=$limit'),
            headers: await ApiClient.reqHeaders,
          )
          .timeout(const Duration(seconds: 30));

      final data = jsonDecode(response.body);
      if (data != null && data['data'] != null) {
        final posts = List<Map<String, dynamic>>.from(data['data']);
        _fixPostUrls(posts);
        return posts;
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching my posts: $e');
      return [];
    }
  }

  // ====== Helpers ======

  static void _fixPostUrls(List<Map<String, dynamic>> posts) {
    for (final post in posts) {
      if (post['mediaUrl'] != null) {
        post['mediaUrl'] = ApiClient.fixMediaUrl(post['mediaUrl'].toString());
      }
      if (post['sourceLogo'] != null) {
        post['sourceLogo'] = ApiClient.fixMediaUrl(post['sourceLogo'].toString());
      }
    }
  }

  static void _fixCommentUrls(Map<String, dynamic> c) {
    if (c['user'] != null && c['user']['avatarUrl'] != null) {
      c['user']['avatarUrl'] = ApiClient.fixMediaUrl(c['user']['avatarUrl'].toString());
    }
    if (c['replies'] != null && c['replies'] is List) {
      final replies = List<Map<String, dynamic>>.from(c['replies']);
      for (final r in replies) {
        _fixCommentUrls(r);
      }
    }
  }
}
