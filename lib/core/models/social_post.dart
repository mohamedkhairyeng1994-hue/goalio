import '../services/api_client.dart';
import 'json_parsing.dart';

enum SocialPostMediaType { text, image, video, embed, unknown }
enum SocialPostApprovalStatus { pending, approved, rejected, unknown }

/// One row from `social_posts` plus a couple of client-side fields the rest of
/// the app expects ([isLiked], populated when the request was authenticated).
class SocialPost {
  final int id;
  final int? userId;
  final bool isGlobal;
  final int? dataId;
  final String? dataText;
  final String sourceName;
  final String? sourceLogo;
  final String? content;
  final String? contentAr;
  final String? mediaUrl;
  final SocialPostMediaType mediaType;
  final String? embedHtml;
  final double? embedHeight;
  final int likesCount;
  final int commentsCount;
  final bool isActive;
  final SocialPostApprovalStatus approvalStatus;
  final String? rejectionReason;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Optional client-side flag — populated by the API when the request was
  /// authenticated, otherwise false.
  final bool isLiked;

  const SocialPost({
    required this.id,
    this.userId,
    this.isGlobal = false,
    this.dataId,
    this.dataText,
    required this.sourceName,
    this.sourceLogo,
    this.content,
    this.contentAr,
    this.mediaUrl,
    this.mediaType = SocialPostMediaType.text,
    this.embedHtml,
    this.embedHeight,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.isActive = true,
    this.approvalStatus = SocialPostApprovalStatus.unknown,
    this.rejectionReason,
    this.createdAt,
    this.updatedAt,
    this.isLiked = false,
  });

  factory SocialPost.fromJson(Map<String, dynamic> json) {
    final media = json['mediaUrl']?.toString();
    final logo = json['sourceLogo']?.toString();
    return SocialPost(
      id: parseInt(json['id']),
      userId: parseIntOrNull(json['user_id']),
      isGlobal: parseBool(json['is_global']),
      dataId: parseIntOrNull(json['data_id']),
      dataText: json['data_text']?.toString(),
      sourceName: json['sourceName']?.toString() ?? 'Goalio',
      sourceLogo: logo == null ? null : ApiClient.fixMediaUrl(logo),
      content: json['content']?.toString(),
      contentAr: json['content_ar']?.toString(),
      mediaUrl: media == null ? null : ApiClient.fixMediaUrl(media),
      mediaType: _parseMediaType(json['mediaType']),
      embedHtml: json['embedHtml']?.toString(),
      embedHeight: parseDoubleOrNull(json['embedHeight']),
      likesCount: parseInt(json['likesCount']),
      commentsCount: parseInt(json['commentsCount']),
      isActive: parseBool(json['isActive'], fallback: true),
      approvalStatus: _parseApprovalStatus(json['approval_status']),
      rejectionReason: json['rejection_reason']?.toString(),
      createdAt: parseDateTime(json['created_at']),
      updatedAt: parseDateTime(json['updated_at']),
      isLiked: parseBool(json['isLiked']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'is_global': isGlobal,
        'data_id': dataId,
        'data_text': dataText,
        'sourceName': sourceName,
        'sourceLogo': sourceLogo,
        'content': content,
        'content_ar': contentAr,
        'mediaUrl': mediaUrl,
        'mediaType': mediaType.name,
        'embedHtml': embedHtml,
        'embedHeight': embedHeight,
        'likesCount': likesCount,
        'commentsCount': commentsCount,
        'isActive': isActive,
        'approval_status': approvalStatus.name,
        'rejection_reason': rejectionReason,
        'created_at': createdAt?.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
        'isLiked': isLiked,
      };

  SocialPost copyWith({
    int? likesCount,
    int? commentsCount,
    bool? isLiked,
    SocialPostApprovalStatus? approvalStatus,
  }) =>
      SocialPost(
        id: id,
        userId: userId,
        isGlobal: isGlobal,
        dataId: dataId,
        dataText: dataText,
        sourceName: sourceName,
        sourceLogo: sourceLogo,
        content: content,
        contentAr: contentAr,
        mediaUrl: mediaUrl,
        mediaType: mediaType,
        embedHtml: embedHtml,
        embedHeight: embedHeight,
        likesCount: likesCount ?? this.likesCount,
        commentsCount: commentsCount ?? this.commentsCount,
        isActive: isActive,
        approvalStatus: approvalStatus ?? this.approvalStatus,
        rejectionReason: rejectionReason,
        createdAt: createdAt,
        updatedAt: updatedAt,
        isLiked: isLiked ?? this.isLiked,
      );

  /// Picks the locale-appropriate body text. Pass `'ar'` to prefer
  /// [contentAr] when present.
  String? localizedContent(String languageCode) {
    if (languageCode.toLowerCase().startsWith('ar')) {
      final ar = contentAr?.trim();
      if (ar != null && ar.isNotEmpty) return ar;
    }
    return content;
  }

  static SocialPostMediaType _parseMediaType(Object? value) {
    switch (value?.toString().toLowerCase()) {
      case 'text':
        return SocialPostMediaType.text;
      case 'image':
        return SocialPostMediaType.image;
      case 'video':
        return SocialPostMediaType.video;
      case 'embed':
        return SocialPostMediaType.embed;
      default:
        return SocialPostMediaType.unknown;
    }
  }

  static SocialPostApprovalStatus _parseApprovalStatus(Object? value) {
    switch (value?.toString().toLowerCase()) {
      case 'pending':
        return SocialPostApprovalStatus.pending;
      case 'approved':
        return SocialPostApprovalStatus.approved;
      case 'rejected':
        return SocialPostApprovalStatus.rejected;
      default:
        return SocialPostApprovalStatus.unknown;
    }
  }
}
