import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/user_entity.dart';
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
      if (!isLoggedIn) {
        state = const AuthState.unauthenticated();
        return;
      }

      // A valid token exists locally — a failure fetching the profile right
      // here is often transient (network/backend not fully up yet at cold
      // start), not proof the session is actually invalid. Previously any
      // such hiccup was treated identically to "no token" and silently
      // logged the user out, forcing them to re-enter credentials even
      // though their session was still good. One short-delayed retry
      // before giving up on it.
      UserEntity? user;
      for (var attempt = 0; attempt < 2 && user == null; attempt++) {
        try {
          user = await _getCurrentUserUseCase();
        } catch (_) {
          if (attempt == 0) await Future.delayed(const Duration(milliseconds: 700));
        }
      }
      state = user != null ? AuthState.authenticated(user) : const AuthState.unauthenticated();
    } catch (e) {
      state = const AuthState.unauthenticated();
    }
  }

  /// Login user
  Future<void> login(String username, String password) async {
    state = const AuthState.loading();
    debugPrint('[AuthNotifier] login: calling loginUseCase for "$username"');
    try {
      final loginResult = await _loginUseCase(username, password);
      debugPrint('[AuthNotifier] login: loginUseCase succeeded, mustChangePassword=${loginResult.mustChangePassword}, portalType=${loginResult.portalType}');

      // Get user profile after successful login
      debugPrint('[AuthNotifier] login: calling getCurrentUserUseCase (GET /api/v1/auth/me/)');
      final user = await _getCurrentUserUseCase();
      debugPrint('[AuthNotifier] login: getCurrentUserUseCase succeeded for user=${user.username}');

      // Check if password change is required
      if (loginResult.mustChangePassword) {
        state = AuthState.error('Password change required');
        // Navigation will be handled by the UI
        debugPrint('[AuthNotifier] login: mustChangePassword=true, staying on error state');
        return;
      }

      state = AuthState.authenticated(user);
      debugPrint('[AuthNotifier] login: state -> authenticated');
    } catch (e) {
      debugPrint('[AuthNotifier] login: FAILED with error: $e');
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
