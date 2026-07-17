import '../repositories/auth_repository.dart';

/// Logout UseCase
/// Business logic for user logout
class LogoutUseCase {
  final AuthRepository _repository;

  LogoutUseCase(this._repository);

  Future<void> call() async {
    return await _repository.logout();
  }
}
