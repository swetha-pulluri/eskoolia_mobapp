import '../repositories/auth_repository.dart';

/// Verify Reset Code UseCase
/// Business logic for verifying a password-reset code
class VerifyResetCodeUseCase {
  final AuthRepository _repository;

  VerifyResetCodeUseCase(this._repository);

  Future<void> call(String email, String code) async {
    final trimmedCode = code.trim();
    if (trimmedCode.isEmpty) {
      throw Exception('Enter the code sent to your email');
    }
    if (!RegExp(r'^\d{6}$').hasMatch(trimmedCode)) {
      throw Exception('Enter the 6-digit code sent to your email');
    }

    await _repository.verifyResetCode(email.trim(), trimmedCode);
  }
}
