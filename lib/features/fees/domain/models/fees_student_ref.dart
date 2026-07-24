/// Lightweight student lookup used only to resolve a payer's display name
/// on the Live Payment Feed — GET /api/v1/students/students/.
/// Reference: frontend lib/fees-api.ts::StudentRow (subset actually read by
/// FeesPaymentsPanel: first_name/last_name for the feed's name + initials).
class FeesStudentRef {
  final int id;
  final String firstName;
  final String lastName;

  const FeesStudentRef({required this.id, required this.firstName, required this.lastName});

  factory FeesStudentRef.fromJson(Map<String, dynamic> json) {
    return FeesStudentRef(
      id: json['id'] as int,
      firstName: (json['first_name'] as String?) ?? '',
      lastName: (json['last_name'] as String?) ?? '',
    );
  }
}
