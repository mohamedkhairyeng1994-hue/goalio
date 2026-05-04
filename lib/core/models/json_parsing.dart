/// Best-effort coercions between the loosely-typed JSON the API returns
/// (Laravel sends booleans as 0/1, ints as either int or numeric strings,
/// dates as ISO strings or null, etc.) and the strongly-typed Dart fields
/// our models declare. Every helper is total — never throws, always returns
/// either the parsed value or the documented fallback.
library;

/// Returns an int parsed from [value], or [fallback] when the value is null,
/// blank, or unparseable. Accepts ints, doubles, and numeric strings.
int parseInt(Object? value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return fallback;
    final parsed = int.tryParse(trimmed);
    if (parsed != null) return parsed;
    return double.tryParse(trimmed)?.toInt() ?? fallback;
  }
  return fallback;
}

/// Same as [parseInt] but returns null instead of a fallback when the value
/// is missing/unparseable. Use when "absent" must be distinguishable from 0.
int? parseIntOrNull(Object? value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    return int.tryParse(trimmed) ?? double.tryParse(trimmed)?.toInt();
  }
  return null;
}

/// Returns a double parsed from [value], or [fallback] for invalid input.
double parseDouble(Object? value, {double fallback = 0.0}) {
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return fallback;
    return double.tryParse(trimmed) ?? fallback;
  }
  return fallback;
}

double? parseDoubleOrNull(Object? value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    return double.tryParse(trimmed);
  }
  return null;
}

/// Coerces booleans coming from the API. Laravel commonly returns 1/0 from
/// boolean cast columns, and SQLite-style "true"/"false" strings also occur.
bool parseBool(Object? value, {bool fallback = false}) {
  if (value is bool) return value;
  if (value is int) return value != 0;
  if (value is num) return value != 0;
  if (value is String) {
    switch (value.trim().toLowerCase()) {
      case '1':
      case 'true':
      case 'yes':
      case 'on':
        return true;
      case '0':
      case 'false':
      case 'no':
      case 'off':
      case '':
        return false;
    }
  }
  return fallback;
}

/// Parses an ISO8601 datetime string. Returns null for blanks/invalid input.
/// Does NOT call .toLocal() — the caller decides display vs. storage tz.
DateTime? parseDateTime(Object? value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is String) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    return DateTime.tryParse(trimmed);
  }
  return null;
}

/// Returns [value] if it's already a `Map<String, dynamic>`, otherwise null.
/// Useful when an API field is "optional embedded relation".
Map<String, dynamic>? parseMap(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return null;
}

/// Parses a list of [T] from raw JSON using [itemFromJson]. Skips items that
/// aren't a Map. Returns an empty list on null / unexpected types.
List<T> parseList<T>(
  Object? value,
  T Function(Map<String, dynamic> json) itemFromJson,
) {
  if (value is! List) return const [];
  final out = <T>[];
  for (final raw in value) {
    final m = parseMap(raw);
    if (m != null) out.add(itemFromJson(m));
  }
  return out;
}
