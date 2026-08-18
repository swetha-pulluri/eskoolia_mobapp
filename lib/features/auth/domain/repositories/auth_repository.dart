import '../entities/login_entity.dart';
import '../entities/user_entity.dart';

/// Auth Repository Interface - Domain layer
/// Defines the contract for authentication operations
abstract class AuthRepository {
  /// Login with username and password
  Future<LoginEntity> login(String username, String password);

  /// Get current logged-in user
  Future<UserEntity> getCurrentUser();

  /// Logout current user
  Future<void> logout();

  /// Check if user is logged in
  Future<bool> isLoggedIn();

  /// Request a password-reset code be emailed to [email].
  /// Returns the backend's confirmation message.
  Future<String> forgotPassword(String email);

  /// Verify a previously-emailed reset [code] without consuming it.
  Future<void> verifyResetCode(String email, String code);

  /// Complete the reset — re-validates [code] and sets [newPassword].
  /// Returns the backend's confirmation message.
  Future<String> resetPassword(String email, String code, String newPassword);
}
