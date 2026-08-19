import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../data/local/preferences_service.dart';
import '../../../../data/local/secure_storage_service.dart';
import '../../../../data/network/dio_client.dart';
import '../../data/datasources/auth_local_datasource.dart';
import '../../data/datasources/auth_remote_datasource.dart';
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
