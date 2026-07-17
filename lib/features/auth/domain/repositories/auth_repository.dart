import '../entities/user_entity.dart';

/// Auth Repository Interface
abstract class AuthRepository {
  Future<Map<String, String>> login(String username, String password);
  Future<UserEntity> getCurrentUser();
  Future<void> logout();
  Future<bool> isAuthenticated();
}
