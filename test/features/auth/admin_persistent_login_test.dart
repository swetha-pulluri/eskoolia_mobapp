import 'package:eskoolia_mobapp/features/auth/domain/entities/login_entity.dart';
import 'package:eskoolia_mobapp/features/auth/domain/entities/user_entity.dart';
import 'package:eskoolia_mobapp/features/auth/domain/repositories/auth_repository.dart';
import 'package:eskoolia_mobapp/features/auth/domain/usecases/check_auth_status_usecase.dart';
import 'package:eskoolia_mobapp/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:eskoolia_mobapp/features/auth/domain/usecases/login_usecase.dart';
import 'package:eskoolia_mobapp/features/auth/domain/usecases/logout_usecase.dart';
import 'package:eskoolia_mobapp/features/auth/presentation/providers/auth_notifier.dart';
import 'package:eskoolia_mobapp/features/auth/presentation/providers/auth_state.dart';
import 'package:eskoolia_mobapp/config/router/portal_routes.dart';
import 'package:flutter_test/flutter_test.dart';

/// Stands in for the real backend + secure storage (`AuthRepositoryImpl` +
/// `SecureStorageService`) for these tests. [hasStoredToken]/[storedUser]
/// model exactly what real device storage holds — they are NOT reset when
/// a new [AuthNotifier] is built against the same [FakeAuthRepository]
/// instance, which is precisely how a real app restart behaves: the OS
/// keeps the secure-storage token across process death, only the Dart
/// runtime's in-memory provider state resets. Building a fresh
/// [AuthNotifier] against the same repository instance is therefore a
/// faithful simulation of "kill and relaunch the app."
class FakeAuthRepository implements AuthRepository {
  bool hasStoredToken = false;
  UserEntity? storedUser;

  /// How many successive `getCurrentUser()` calls should throw before
  /// succeeding — simulates a temporary network interruption right at
  /// cold start.
  int getCurrentUserFailuresBeforeSuccess = 0;
  int getCurrentUserCallCount = 0;

  @override
  Future<LoginEntity> login(String username, String password) async {
    hasStoredToken = true;
    return const LoginEntity(
      accessToken: 'fake-access-token',
      refreshToken: 'fake-refresh-token',
      mustChangePassword: false,
      portalType: 'admin',
    );
  }

  @override
  Future<UserEntity> getCurrentUser() async {
    getCurrentUserCallCount++;
    if (getCurrentUserCallCount <= getCurrentUserFailuresBeforeSuccess) {
      throw Exception('Network error: could not reach server');
    }
    return storedUser!;
  }

  @override
  Future<void> logout() async {
    hasStoredToken = false;
    storedUser = null;
  }

  @override
  Future<bool> isLoggedIn() async => hasStoredToken;

  @override
  Future<String> forgotPassword(String email) => throw UnimplementedError();

  @override
  Future<void> verifyResetCode(String email, String code) => throw UnimplementedError();

  @override
  Future<String> resetPassword(String email, String code, String newPassword) => throw UnimplementedError();
}

const _adminUser = UserEntity(
  id: 1,
  username: 'admin',
  email: 'admin@school.edu',
  firstName: 'School',
  lastName: 'Admin',
  portalType: 'admin',
  isSuperuser: false,
  roleNames: ['admin'],
  mustChangePassword: false,
);

AuthNotifier _notifierFor(FakeAuthRepository repo) {
  return AuthNotifier(
    LoginUseCase(repo),
    GetCurrentUserUseCase(repo),
    LogoutUseCase(repo),
    CheckAuthStatusUseCase(repo),
  );
}

void main() {
  group('Admin persistent login', () {
    test('1-2. successful admin login authenticates and resolves to the Admin Dashboard route', () async {
      final repo = FakeAuthRepository()..storedUser = _adminUser;
      final notifier = _notifierFor(repo);

      await notifier.login('admin', 'password123');

      final state = notifier.state;
      expect(state, isA<AuthState>());
      final user = state.maybeWhen(authenticated: (u) => u, orElse: () => null);
      expect(user, isNotNull, reason: 'login should reach the authenticated state');
      expect(user!.portalType, 'admin');
      // This is exactly the mapping SplashPage uses to pick a destination
      // once checkAuthStatus() resolves — proves an authenticated admin
      // lands on the Admin Dashboard ('/home'), not some other portal home.
      expect(resolveHomeRouteForPortal(user.portalType), '/home');
    });

    test('3-5. a session saved before "restart" is recognized by a brand-new AuthNotifier, with internet up', () async {
      final repo = FakeAuthRepository()..storedUser = _adminUser;
      final beforeRestart = _notifierFor(repo);
      await beforeRestart.login('admin', 'password123');
      expect(beforeRestart.state.maybeWhen(authenticated: (_) => true, orElse: () => false), isTrue);

      // Simulate "completely kill/close the app, relaunch": a fresh
      // AuthNotifier starting at AuthState.initial(), wired to the SAME
      // repository instance (== same persisted secure storage).
      final afterRestart = _notifierFor(repo);
      expect(afterRestart.state, const AuthState.initial());

      await afterRestart.checkAuthStatus();

      final user = afterRestart.state.maybeWhen(authenticated: (u) => u, orElse: () => null);
      expect(user, isNotNull, reason: 'a previously-saved session must be recognized on relaunch without re-entering credentials');
      expect(user!.portalType, 'admin');
      expect(resolveHomeRouteForPortal(user.portalType), '/home');
    });

    test('6. a temporary network interruption at cold start does not force a re-login', () async {
      final repo = FakeAuthRepository()
        ..hasStoredToken = true
        ..storedUser = _adminUser
        ..getCurrentUserFailuresBeforeSuccess = 1; // first attempt fails, second (the retry) succeeds
      final notifier = _notifierFor(repo);

      await notifier.checkAuthStatus();

      expect(repo.getCurrentUserCallCount, 2, reason: 'the retry added in AuthNotifier.checkAuthStatus should have fired once');
      final user = notifier.state.maybeWhen(authenticated: (u) => u, orElse: () => null);
      expect(user, isNotNull, reason: 'a transient network hiccup must not discard a valid saved session');
      expect(user!.username, 'admin');
    });

    test('boundary: a persistent (non-transient) failure still safely falls back to unauthenticated, never hangs', () async {
      final repo = FakeAuthRepository()
        ..hasStoredToken = true
        ..storedUser = _adminUser
        ..getCurrentUserFailuresBeforeSuccess = 99; // every attempt fails
      final notifier = _notifierFor(repo);

      await notifier.checkAuthStatus();

      expect(notifier.state, const AuthState.unauthenticated());
    });

    test('no saved session at all resolves straight to unauthenticated without any network call', () async {
      final repo = FakeAuthRepository(); // hasStoredToken defaults to false
      final notifier = _notifierFor(repo);

      await notifier.checkAuthStatus();

      expect(notifier.state, const AuthState.unauthenticated());
      expect(repo.getCurrentUserCallCount, 0, reason: 'no token means no profile fetch should even be attempted');
    });

    test('7. logout clears the session, and a subsequent relaunch shows the login screen (unauthenticated)', () async {
      final repo = FakeAuthRepository()..storedUser = _adminUser;
      final loggedIn = _notifierFor(repo);
      await loggedIn.login('admin', 'password123');
      expect(loggedIn.state.maybeWhen(authenticated: (_) => true, orElse: () => false), isTrue);

      await loggedIn.logout();
      expect(loggedIn.state, const AuthState.unauthenticated());
      expect(repo.hasStoredToken, isFalse, reason: 'logout must clear the persisted session, not just in-memory state');

      // Simulate reopening the app after logout.
      final afterLogout = _notifierFor(repo);
      await afterLogout.checkAuthStatus();
      expect(afterLogout.state, const AuthState.unauthenticated());
    });
  });
}
