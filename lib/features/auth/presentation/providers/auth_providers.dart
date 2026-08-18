import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../data/local/preferences_service.dart';
import '../../../../data/local/secure_storage_service.dart';
import '../../../../data/local/shared_prefs.dart';
import '../../../../data/network/dio_client.dart';
import '../../data/datasources/auth_local_datasource.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/models/school_info_model.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/check_auth_status_usecase.dart';
import '../../domain/usecases/forgot_password_usecase.dart';
import '../../domain/usecases/get_current_user_usecase.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/reset_password_usecase.dart';
import '../../domain/usecases/verify_reset_code_usecase.dart';
import 'auth_notifier.dart';
import 'auth_state.dart';
import 'password_reset_notifier.dart';
import 'password_reset_state.dart';

// Core Services

final secureStorageServiceProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

final sharedPreferencesProvider = FutureProvider<SharedPreferences>((
  ref,
) async {
  return await SharedPreferences.getInstance();
});

final preferencesServiceProvider = Provider<PreferencesService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider).value;
  if (prefs == null) {
    throw Exception('SharedPreferences not initialized');
  }
  return PreferencesService(prefs);
});

final dioClientProvider = Provider<DioClient>((ref) {
  final secureStorage = ref.watch(secureStorageServiceProvider);
  return DioClient(secureStorage);
});

final dioProvider = Provider<Dio>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return dioClient.dio;
});

// Data Sources

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  final dio = ref.watch(dioProvider);
  return AuthRemoteDataSourceImpl(dio);
});

final authLocalDataSourceProvider = Provider<AuthLocalDataSource>((ref) {
  final secureStorage = ref.watch(secureStorageServiceProvider);
  return AuthLocalDataSourceImpl(secureStorage);
});

// Repository

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final remoteDataSource = ref.watch(authRemoteDataSourceProvider);
  final localDataSource = ref.watch(authLocalDataSourceProvider);
  return AuthRepositoryImpl(remoteDataSource, localDataSource);
});

// Use Cases

final loginUseCaseProvider = Provider<LoginUseCase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return LoginUseCase(repository);
});

final getCurrentUserUseCaseProvider = Provider<GetCurrentUserUseCase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return GetCurrentUserUseCase(repository);
});

final logoutUseCaseProvider = Provider<LogoutUseCase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return LogoutUseCase(repository);
});

final forgotPasswordUseCaseProvider = Provider<ForgotPasswordUseCase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return ForgotPasswordUseCase(repository);
});

final verifyResetCodeUseCaseProvider = Provider<VerifyResetCodeUseCase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return VerifyResetCodeUseCase(repository);
});

final resetPasswordUseCaseProvider = Provider<ResetPasswordUseCase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return ResetPasswordUseCase(repository);
});

final checkAuthStatusUseCaseProvider = Provider<CheckAuthStatusUseCase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return CheckAuthStatusUseCase(repository);
});

// Auth Notifier Provider

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((
  ref,
) {
  final loginUseCase = ref.watch(loginUseCaseProvider);
  final getCurrentUserUseCase = ref.watch(getCurrentUserUseCaseProvider);
  final logoutUseCase = ref.watch(logoutUseCaseProvider);
  final checkAuthStatusUseCase = ref.watch(checkAuthStatusUseCaseProvider);

  return AuthNotifier(
    loginUseCase,
    getCurrentUserUseCase,
    logoutUseCase,
    checkAuthStatusUseCase,
  );
});

// School Identification (optional, pre-login)
//
// The Main eskoolia.com login is the default and needs no tenant identified
// up front — the backend resolves an authenticated account's own school and
// role from credentials alone (see auth_notifier.dart; the login call itself
// is untouched by any of this). Separately, a school that has its own
// subdomain (e.g. vasavi.eskoolia.com, created via Admin > School Tenancy >
// Add School) can be identified via `SchoolSelectPage` — reachable only by
// an explicit link from the login page, never forced (see app_router.dart's
// redirect) — purely so that school's real name/logo can be shown before
// login. Nothing here ever constructs or guesses a URL: the typed subdomain
// is only ever handed to the backend's own `school-info` lookup below.
//
// The chosen subdomain is a device-level preference, not session auth data,
// so it's stored via `SharedPrefs` (survives logout) rather than
// `SecureStorageService` (wiped by clearAuthData() on every logout).

/// The subdomain the user has identified this device with, or null if
/// they're using the default Main eskoolia.com login. Read synchronously
/// from `SharedPrefs` at construction — safe because `main()` awaits
/// `SharedPrefs().init()` before the `ProviderScope` is even created.
final selectedSchoolSubdomainProvider = StateProvider<String?>((ref) {
  final stored = SharedPrefs().getString(AppConstants.selectedSchoolSubdomainKey);
  return (stored != null && stored.isNotEmpty) ? stored : null;
});

/// Persists the chosen subdomain and updates the live provider.
Future<void> selectSchool(WidgetRef ref, String subdomain) async {
  await SharedPrefs().setString(AppConstants.selectedSchoolSubdomainKey, subdomain);
  ref.read(selectedSchoolSubdomainProvider.notifier).state = subdomain;
}

/// Clears the chosen subdomain — used by the login page's "Use main login
/// instead" action to drop back to the default, tenant-agnostic login.
Future<void> clearSelectedSchool(WidgetRef ref) async {
  await SharedPrefs().remove(AppConstants.selectedSchoolSubdomainKey);
  ref.read(selectedSchoolSubdomainProvider.notifier).state = null;
}

/// Public branding lookup for a typed subdomain (name/logo/brand colour).
/// `.autoDispose` + `.family` — each distinct subdomain the user tries gets
/// its own request, discarded once nothing is watching it (e.g. the
/// school-select page is closed after a successful pick).
final schoolInfoProvider = FutureProvider.autoDispose
    .family<SchoolInfoModel?, String>((ref, subdomain) {
      final dataSource = ref.watch(authRemoteDataSourceProvider);
      return dataSource.resolveSchoolInfo(subdomain);
    });

// Forgot / Verify / Reset Password
//
// `.autoDispose` — this is transient, in-flight flow state, not app-wide
// state like auth; it should reset once the user leaves the
// forgot/reset-password pages, not linger for the rest of the app session.
final passwordResetNotifierProvider =
    StateNotifierProvider.autoDispose<PasswordResetNotifier, PasswordResetState>((ref) {
      return PasswordResetNotifier(
        ref.watch(forgotPasswordUseCaseProvider),
        ref.watch(verifyResetCodeUseCaseProvider),
        ref.watch(resetPasswordUseCaseProvider),
      );
    });
