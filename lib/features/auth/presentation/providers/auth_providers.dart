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
import '../../domain/usecases/get_current_user_usecase.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import 'auth_notifier.dart';
import 'auth_state.dart';

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

// School Identification (pre-login)
//
// Each school gets its own subdomain on web (e.g. vasavi.eskoolia.com,
// created via Admin > School Tenancy > Add School); the mobile app hits a
// single fixed base URL instead, so it asks the user to type that subdomain
// once, upfront, and shows the matching school's branding before login. This
// is purely an identification/branding step — the login call itself is
// unchanged (still just username + password; see auth_notifier.dart) and
// already resolves the account's own school after authenticating.
//
// The chosen subdomain is a device-level preference, not session auth data,
// so it's stored via `SharedPrefs` (survives logout) rather than
// `SecureStorageService` (wiped by clearAuthData() on every logout).

/// The subdomain the user has already identified this device with, or null
/// if they haven't picked one yet. Read synchronously from `SharedPrefs` at
/// construction — safe because `main()` awaits `SharedPrefs().init()` before
/// the `ProviderScope` is even created — so the router's `redirect` callback
/// (which cannot await) sees the correct value on the very first check, with
/// no cold-start flicker.
final selectedSchoolSubdomainProvider = StateProvider<String?>((ref) {
  final stored = SharedPrefs().getString(AppConstants.selectedSchoolSubdomainKey);
  return (stored != null && stored.isNotEmpty) ? stored : null;
});

/// Persists the chosen subdomain and updates the live provider so the
/// router's redirect re-evaluates immediately (see _AuthRefreshNotifier in
/// app_router.dart).
Future<void> selectSchool(WidgetRef ref, String subdomain) async {
  await SharedPrefs().setString(AppConstants.selectedSchoolSubdomainKey, subdomain);
  ref.read(selectedSchoolSubdomainProvider.notifier).state = subdomain;
}

/// Clears the chosen subdomain — used by the login page's "Change School"
/// action to go back to the school-identification step.
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
