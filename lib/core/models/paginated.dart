import 'json_parsing.dart';

/// Strongly-typed wrapper around Laravel's paginator response shape:
///
/// ```json
/// {
///   "data": [...],
///   "current_page": 1,
///   "last_page": 4,
///   "from": 1, "to": 20,
///   "total": 78,
///   "next_page_url": "http://...?page=2",
///   "prev_page_url": null
/// }
/// ```
///
/// Use [Paginated.fromJson] with the item factory: e.g.
/// `Paginated.fromJson(json, SocialPost.fromJson)`.
class Paginated<T> {
  final List<T> data;
  final int currentPage;
  final int lastPage;
  final int total;
  final String? nextPageUrl;
  final String? prevPageUrl;

  const Paginated({
    required this.data,
    required this.currentPage,
    required this.lastPage,
    required this.total,
    this.nextPageUrl,
    this.prevPageUrl,
  });

  factory Paginated.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) itemFromJson,
  ) {
    return Paginated<T>(
      data: parseList<T>(json['data'], itemFromJson),
      currentPage: parseInt(json['current_page'], fallback: 1),
      lastPage: parseInt(json['last_page'], fallback: 1),
      total: parseInt(json['total']),
      nextPageUrl: json['next_page_url']?.toString(),
      prevPageUrl: json['prev_page_url']?.toString(),
    );
  }

  static Paginated<T> empty<T>() =>
      Paginated<T>(data: const [], currentPage: 1, lastPage: 1, total: 0);

  bool get hasMore => nextPageUrl != null;
  bool get isEmpty => data.isEmpty;
}
