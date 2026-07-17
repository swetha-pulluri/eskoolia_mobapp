import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/usecases/check_auth_status_usecase.dart';
import '../../domain/usecases/get_current_user_usecase.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import 'auth_state.dart';

/// Auth Notifier
/// Manages authentication state and operations
class AuthNotifier extends StateNotifier<AuthState> {
  final LoginUseCase _loginUseCase;
  final GetCurrentUserUseCase _getCurrentUserUseCase;
  final LogoutUseCase _logoutUseCase;
  final CheckAuthStatusUseCase _checkAuthStatusUseCase;

  AuthNotifier(
    this._loginUseCase,
    this._getCurrentUserUseCase,
    this._logoutUseCase,
    this._checkAuthStatusUseCase,
  ) : super(const AuthState.initial());

  /// Check if user is logged in on app start
  Future<void> checkAuthStatus() async {
    try {
      final isLoggedIn = await _checkAuthStatusUseCase();
      if (isLoggedIn) {
        final user = await _getCurrentUserUseCase();
        state = AuthState.authenticated(user);
      } else {
        state = const AuthState.unauthenticated();
      }
    } catch (e) {
      state = const AuthState.unauthenticated();
    }
  }

  /// Login user
  Future<void> login(String username, String password) async {
    state = const AuthState.loading();
    try {
      final loginResult = await _loginUseCase(username, password);

      // Get user profile after successful login
      final user = await _getCurrentUserUseCase();

      // Check if password change is required
      if (loginResult.mustChangePassword) {
        state = AuthState.error('Password change required');
        // Navigation will be handled by the UI
        return;
      }

      state = AuthState.authenticated(user);
    } catch (e) {
      state = AuthState.error(e.toString().replaceAll('Exception: ', ''));
    }
  }

  /// Logout user
  Future<void> logout() async {
    try {
      await _logoutUseCase();
      state = const AuthState.unauthenticated();
    } catch (e) {
      // Even if logout API fails, clear state
      state = const AuthState.unauthenticated();
    }
  }

  /// Clear error state
  void clearError() {
    state.maybeWhen(
      error: (_) => state = const AuthState.unauthenticated(),
      orElse: () {},
    );
  }
}
