import '../repositories/auth_repository.dart';

/// Reset Password UseCase
/// Business logic for completing a password reset
///
/// Minimum length is 8, matching web's `frontend/app/reset-password/page.tsx`
/// client-side rule — stricter than the backend's own 6-character minimum,
/// kept here so mobile behaves the same as web rather than merely the
/// backend's floor.
class ResetPasswordUseCase {
  final AuthRepository _repository;

  ResetPasswordUseCase(this._repository);

  Future<String> call(String email, String code, String newPassword) async {
    final trimmedCode = code.trim();
    if (trimmedCode.isEmpty || !RegExp(r'^\d{6}$').hasMatch(trimmedCode)) {
      throw Exception('Enter the 6-digit code sent to your email');
    }
    if (newPassword.length < 8) {
      throw Exception('Access key must be at least 8 characters');
    }

    return await _repository.resetPassword(email.trim(), trimmedCode, newPassword);
  }
}
