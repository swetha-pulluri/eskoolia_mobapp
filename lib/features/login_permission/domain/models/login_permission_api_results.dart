import 'login_permission_user.dart';

/// GET login-permission/users/ response shape — matches backend exactly.
class PageResult {
  final List<LoginPermissionUser> results;
  final int page;
  final int pageSize;
  final int totalPages;
  final int filteredCount;
  final LoginPermissionCounts counts;

  PageResult({
    required this.results,
    required this.page,
    required this.pageSize,
    required this.totalPages,
    required this.filteredCount,
    required this.counts,
  });

  factory PageResult.fromJson(Map<String, dynamic> json) {
    return PageResult(
      results: (json['results'] as List<dynamic>? ?? [])
          .map(
            (e) => LoginPermissionUser.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
      page: json['page'] as int? ?? 1,
      pageSize: json['pageSize'] as int? ?? 0,
      totalPages: json['totalPages'] as int? ?? 0,
      filteredCount: json['filteredCount'] as int? ?? 0,
      counts: LoginPermissionCounts.fromJson(
        json['counts'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }
}

/// Shared response shape for reset-password/ and set-initial-password/.
class CredentialActionResult {
  final bool ok;
  final String passwordBackup;
  final String message;

  CredentialActionResult({
    required this.ok,
    required this.passwordBackup,
    required this.message,
  });

  factory CredentialActionResult.fromJson(Map<String, dynamic> json) {
    return CredentialActionResult(
      ok: json['ok'] as bool? ?? false,
      passwordBackup: json['passwordBackup'] as String? ?? '',
      message: json['message'] as String? ?? '',
    );
  }
}
