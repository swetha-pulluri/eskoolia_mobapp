/// Mirrors one `PortalAccountInfo` object in
/// `GET /api/v1/teacher/students/<id>/credentials/`. When `hasAccount` is
/// `false`, the Django view returns LITERALLY `{"has_account": false}` —
/// every other key is entirely ABSENT from the JSON, not present-with-null.
/// Every field below but [hasAccount] must stay nullable and be parsed with
/// a safe cast so a missing key never throws.
class PortalAccountInfoEntity {
  final bool hasAccount;
  final String? username;
  final bool? isActive;
  final String? lastLogin;
  final String? dateJoined;

  const PortalAccountInfoEntity({
    required this.hasAccount,
    this.username,
    this.isActive,
    this.lastLogin,
    this.dateJoined,
  });

  factory PortalAccountInfoEntity.fromJson(Map<String, dynamic> json) => PortalAccountInfoEntity(
        hasAccount: json['has_account'] as bool? ?? false,
        username: json['username'] as String?,
        isActive: json['is_active'] as bool?,
        lastLogin: json['last_login'] as String?,
        dateJoined: json['date_joined'] as String?,
      );
}

/// Mirrors `build_student_credentials()`'s response. `guardianName`/
/// `guardianRelation` are nullable here — a DIFFERENT convention from
/// `StudentOverviewEntity`'s `''`-fallback for the same underlying field on
/// the sibling `/students/<id>/` endpoint. Do not share a parser between
/// the two.
class StudentCredentialsEntity {
  final PortalAccountInfoEntity student;
  final PortalAccountInfoEntity parent;
  final String? guardianName;
  final String? guardianRelation;

  const StudentCredentialsEntity({
    required this.student,
    required this.parent,
    this.guardianName,
    this.guardianRelation,
  });

  factory StudentCredentialsEntity.fromJson(Map<String, dynamic> json) {
    final parentJson = json['parent'] as Map<String, dynamic>? ?? const {};
    return StudentCredentialsEntity(
      student: PortalAccountInfoEntity.fromJson(json['student'] as Map<String, dynamic>? ?? const {}),
      parent: PortalAccountInfoEntity.fromJson(parentJson),
      guardianName: parentJson['guardian_name'] as String?,
      guardianRelation: parentJson['guardian_relation'] as String?,
    );
  }
}
