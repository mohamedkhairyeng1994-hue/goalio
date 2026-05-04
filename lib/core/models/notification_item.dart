import 'json_parsing.dart';

/// One row from the `notifications` inbox. Names use camelCase but JSON
/// keys are snake_case to match the Laravel migration:
///   id, user_id, title, title_ar, body, body_ar, is_read,
///   fcm_message_id, received_at, data (json), created_at, updated_at.
///
/// Uses [data] to carry per-notification payloads (match_id, league_id, etc.)
/// — kept as a `Map<String, dynamic>` because it's free-form on the backend.
class NotificationItem {
  final int id;
  final int? userId;
  final String title;
  final String? titleAr;
  final String body;
  final String? bodyAr;
  final bool isRead;
  final String? fcmMessageId;
  final DateTime? receivedAt;
  final Map<String, dynamic> data;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const NotificationItem({
    required this.id,
    this.userId,
    required this.title,
    this.titleAr,
    required this.body,
    this.bodyAr,
    this.isRead = false,
    this.fcmMessageId,
    this.receivedAt,
    this.data = const {},
    this.createdAt,
    this.updatedAt,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: parseInt(json['id']),
      userId: parseIntOrNull(json['user_id']),
      title: json['title']?.toString() ?? '',
      titleAr: json['title_ar']?.toString(),
      body: json['body']?.toString() ?? '',
      bodyAr: json['body_ar']?.toString(),
      isRead: parseBool(json['is_read']),
      fcmMessageId: json['fcm_message_id']?.toString(),
      receivedAt: parseDateTime(json['received_at']),
      data: parseMap(json['data']) ?? const {},
      createdAt: parseDateTime(json['created_at']),
      updatedAt: parseDateTime(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'title': title,
        'title_ar': titleAr,
        'body': body,
        'body_ar': bodyAr,
        'is_read': isRead,
        'fcm_message_id': fcmMessageId,
        'received_at': receivedAt?.toIso8601String(),
        'data': data,
        'created_at': createdAt?.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
      };

  NotificationItem copyWith({bool? isRead}) => NotificationItem(
        id: id,
        userId: userId,
        title: title,
        titleAr: titleAr,
        body: body,
        bodyAr: bodyAr,
        isRead: isRead ?? this.isRead,
        fcmMessageId: fcmMessageId,
        receivedAt: receivedAt,
        data: data,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  /// Picks the locale-appropriate title.
  String localizedTitle(String languageCode) {
    if (languageCode.toLowerCase().startsWith('ar')) {
      final ar = titleAr?.trim();
      if (ar != null && ar.isNotEmpty) return ar;
    }
    return title;
  }

  String localizedBody(String languageCode) {
    if (languageCode.toLowerCase().startsWith('ar')) {
      final ar = bodyAr?.trim();
      if (ar != null && ar.isNotEmpty) return ar;
    }
    return body;
  }
}
