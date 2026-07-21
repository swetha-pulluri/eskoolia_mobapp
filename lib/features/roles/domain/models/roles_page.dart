import 'role_data.dart';

/// GET access-control/roles/ response shape — matches backend's
/// RoleViewSet.list() envelope: {success, message, data, count, next, previous}.
class RolesPage {
  final List<RoleData> results;
  final int count;

  const RolesPage({required this.results, required this.count});

  factory RolesPage.fromJson(Map<String, dynamic> json) {
    final rawResults = (json['data'] ?? json['results']) as List<dynamic>? ?? [];
    return RolesPage(
      results: rawResults
          .map((e) => RoleData.fromJson(e as Map<String, dynamic>))
          .toList(),
      count: json['count'] as int? ?? rawResults.length,
    );
  }
}
