import '../entities/login_entity.dart';
import '../repositories/auth_repository.dart';

/// Login UseCase
/// Business logic for user login
class LoginUseCase {
  final AuthRepository _repository;

  LoginUseCase(this._repository);

  Future<LoginEntity> call(String username, String password) async {
    // Validate inputs
    if (username.trim().isEmpty) {
      throw Exception('Username is required');
    }
    if (password.isEmpty) {
      throw Exception('Password is required');
    }
    if (password.length < 6) {
      throw Exception('Password must be at least 6 characters');
    }

    // Call repository
    return await _repository.login(username.trim(), password);
  }
}
