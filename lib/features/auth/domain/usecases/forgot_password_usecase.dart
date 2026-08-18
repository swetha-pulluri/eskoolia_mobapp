import '../repositories/auth_repository.dart';

/// Forgot Password UseCase
/// Business logic for requesting a password-reset code
class ForgotPasswordUseCase {
  final AuthRepository _repository;

  ForgotPasswordUseCase(this._repository);

  Future<String> call(String email) async {
    final trimmed = email.trim();
    if (trimmed.isEmpty) {
      throw Exception('Email is required');
    }
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(trimmed)) {
      throw Exception('Enter a valid email address');
    }

    return await _repository.forgotPassword(trimmed);
  }
}
