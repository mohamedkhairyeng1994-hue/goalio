import 'json_parsing.dart';
import 'user.dart';

class SocialPostComment {
  final int id;
  final int socialPostId;
  final int? userId;
  final String comment;
  final int? parentId;
  final DateTime? createdAt;
  final User? user;
  final List<SocialPostComment> replies;

  const SocialPostComment({
    required this.id,
    required this.socialPostId,
    this.userId,
    required this.comment,
    this.parentId,
    this.createdAt,
    this.user,
    this.replies = const [],
  });

  factory SocialPostComment.fromJson(Map<String, dynamic> json) {
    final userJson = parseMap(json['user']);
    return SocialPostComment(
      id: parseInt(json['id']),
      socialPostId: parseInt(json['social_post_id']),
      userId: parseIntOrNull(json['user_id']),
      comment: json['comment']?.toString() ?? '',
      parentId: parseIntOrNull(json['parent_id']),
      createdAt: parseDateTime(json['created_at']),
      user: userJson == null ? null : User.fromJson(userJson),
      replies: parseList<SocialPostComment>(
        json['replies'],
        SocialPostComment.fromJson,
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'social_post_id': socialPostId,
        'user_id': userId,
        'comment': comment,
        'parent_id': parentId,
        'created_at': createdAt?.toIso8601String(),
        if (user != null) 'user': user!.toJson(),
        'replies': replies.map((r) => r.toJson()).toList(),
      };

  bool get isReply => parentId != null;
  int get replyCount => replies.length;
}
