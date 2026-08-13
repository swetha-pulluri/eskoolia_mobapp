/// Mirrors the success body of
/// `POST /api/v1/teacher/students/<id>/reset-password/`.
class ResetPasswordResultEntity {
  final bool success;
  final String newPassword;
  final String username;
  final String target;

  const ResetPasswordResultEntity({
    required this.success,
    required this.newPassword,
    required this.username,
    required this.target,
  });

  factory ResetPasswordResultEntity.fromJson(Map<String, dynamic> json) => ResetPasswordResultEntity(
        success: json['success'] as bool? ?? false,
        newPassword: (json['new_password'] as String?) ?? '',
        username: (json['username'] as String?) ?? '',
        target: (json['target'] as String?) ?? '',
      );
}
