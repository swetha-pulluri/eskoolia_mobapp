import '../repositories/auth_repository.dart';

/// Check Auth Status UseCase
/// Business logic for checking if user is logged in
class CheckAuthStatusUseCase {
  final AuthRepository _repository;

  CheckAuthStatusUseCase(this._repository);

  Future<bool> call() async {
    return await _repository.isLoggedIn();
  }
}
