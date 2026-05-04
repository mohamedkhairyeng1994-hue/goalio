import '../services/api_client.dart';
import 'json_parsing.dart';
import 'user.dart';

enum StoryMediaType { image, video, unknown }
enum StoryApprovalStatus { pending, approved, rejected, unknown }

/// A single story shown on the home rail. Mirrors the `stories` table on the
/// backend plus the optional `user` relation that's eager-loaded by the
/// /stories index endpoint.
class Story {
  final int id;
  final int? userId;
  final int? newsId;
  final String mediaUrl;
  final StoryMediaType mediaType;
  final String? caption;
  final StoryApprovalStatus approvalStatus;
  final String? rejectionReason;
  final DateTime? expiresAt;
  final DateTime? createdAt;
  final User? user;

  const Story({
    required this.id,
    this.userId,
    this.newsId,
    required this.mediaUrl,
    this.mediaType = StoryMediaType.image,
    this.caption,
    this.approvalStatus = StoryApprovalStatus.unknown,
    this.rejectionReason,
    this.expiresAt,
    this.createdAt,
    this.user,
  });

  factory Story.fromJson(Map<String, dynamic> json) {
    final rawMedia = json['media_url']?.toString() ?? '';
    final user = parseMap(json['user']);
    return Story(
      id: parseInt(json['id']),
      userId: parseIntOrNull(json['user_id']),
      newsId: parseIntOrNull(json['news_id']),
      mediaUrl: ApiClient.fixMediaUrl(rawMedia),
      mediaType: _parseMediaType(json['media_type']),
      caption: json['caption']?.toString(),
      approvalStatus: _parseApprovalStatus(json['approval_status']),
      rejectionReason: json['rejection_reason']?.toString(),
      expiresAt: parseDateTime(json['expires_at']),
      createdAt: parseDateTime(json['created_at']),
      user: user == null ? null : User.fromJson(user),
    );
  }

  /// Convenience for code paths still working with raw maps. The output is
  /// shape-compatible with what the API originally returned, plus URL
  /// normalisation already applied to [mediaUrl].
  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'news_id': newsId,
        'media_url': mediaUrl,
        'media_type': mediaType.name,
        'caption': caption,
        'approval_status': approvalStatus.name,
        'rejection_reason': rejectionReason,
        'expires_at': expiresAt?.toIso8601String(),
        'created_at': createdAt?.toIso8601String(),
        if (user != null) 'user': user!.toJson(),
      };

  /// True when the story's expiry is in the past. Approved-but-expired stories
  /// are filtered server-side, but this is handy for client-side defensive
  /// display logic too.
  bool get isExpired =>
      expiresAt != null && DateTime.now().isAfter(expiresAt!);

  /// Best-effort label for the rail tile: prefers the author name, falls back
  /// to the caption, then a generic "Story".
  String get displayLabel {
    final name = user?.fullname?.trim();
    if (name != null && name.isNotEmpty) return name;
    final cap = caption?.trim();
    if (cap != null && cap.isNotEmpty) return cap;
    return 'Story';
  }

  static StoryMediaType _parseMediaType(Object? value) {
    final s = value?.toString().toLowerCase();
    if (s == 'image') return StoryMediaType.image;
    if (s == 'video') return StoryMediaType.video;
    return StoryMediaType.unknown;
  }

  static StoryApprovalStatus _parseApprovalStatus(Object? value) {
    switch (value?.toString().toLowerCase()) {
      case 'pending':
        return StoryApprovalStatus.pending;
      case 'approved':
        return StoryApprovalStatus.approved;
      case 'rejected':
        return StoryApprovalStatus.rejected;
      default:
        return StoryApprovalStatus.unknown;
    }
  }
}
