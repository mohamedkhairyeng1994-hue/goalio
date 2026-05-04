import '../services/api_client.dart';
import 'json_parsing.dart';

/// Minimal user representation embedded in nested API payloads
/// (story author, comment author, etc.). Not the full profile —
/// for that, fetch via the auth endpoints.
class User {
  final int id;
  final String? fullname;
  final String? email;
  final String? avatarUrl;

  const User({
    required this.id,
    this.fullname,
    this.email,
    this.avatarUrl,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    final rawAvatar =
        json['avatarUrl']?.toString() ?? json['avatar_url']?.toString();
    return User(
      id: parseInt(json['id']),
      fullname: json['fullname']?.toString(),
      email: json['email']?.toString(),
      avatarUrl: rawAvatar == null ? null : ApiClient.fixMediaUrl(rawAvatar),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        if (fullname != null) 'fullname': fullname,
        if (email != null) 'email': email,
        if (avatarUrl != null) 'avatarUrl': avatarUrl,
      };

  User copyWith({String? fullname, String? email, String? avatarUrl}) => User(
        id: id,
        fullname: fullname ?? this.fullname,
        email: email ?? this.email,
        avatarUrl: avatarUrl ?? this.avatarUrl,
      );
}
