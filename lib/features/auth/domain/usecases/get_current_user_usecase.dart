import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

/// Get Current User UseCase
/// Business logic for getting current user profile
class GetCurrentUserUseCase {
  final AuthRepository _repository;

  GetCurrentUserUseCase(this._repository);

  Future<UserEntity> call() async {
    return await _repository.getCurrentUser();
  }
}
