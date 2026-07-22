/// Generic wrapper for DRF-style paginated list responses
/// (`{count, next, previous, results}`), also tolerating a plain list
/// response for endpoints that don't paginate.
class PaginatedResult<T> {
  final List<T> results;
  final int count;

  const PaginatedResult({required this.results, required this.count});

  factory PaginatedResult.fromJson(
    dynamic json,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    if (json is List) {
      final items = json.map((e) => fromJson(e as Map<String, dynamic>)).toList();
      return PaginatedResult(results: items, count: items.length);
    }
    final map = json as Map<String, dynamic>;
    final rawResults = (map['results'] as List?) ?? const [];
    final items = rawResults.map((e) => fromJson(e as Map<String, dynamic>)).toList();
    return PaginatedResult(results: items, count: map['count'] as int? ?? items.length);
  }
}
