import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/local/secure_storage.dart';
import '../../../../data/network/dio_client.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/get_current_user_usecase.dart';

// Dependencies
final dioClientProvider = Provider((ref) => DioClient());
final secureStorageProvider = Provider((ref) => SecureStorage());

final authRemoteDataSourceProvider = Provider((ref) {
  return AuthRemoteDataSource(ref.watch(dioClientProvider));
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    ref.watch(authRemoteDataSourceProvider),
    ref.watch(secureStorageProvider),
  );
});

// Use Cases
final getCurrentUserUseCaseProvider = Provider((ref) {
  return GetCurrentUserUseCase(ref.watch(authRepositoryProvider));
});

// Auth State Provider
final authStateProvider = StateNotifierProvider<AuthStateNotifier, AsyncValue<UserEntity?>>((ref) {
  return AuthStateNotifier(
    ref.watch(authRepositoryProvider),
    ref.watch(getCurrentUserUseCaseProvider),
  );
});

class AuthStateNotifier extends StateNotifier<AsyncValue<UserEntity?>> {
  final AuthRepository _authRepository;
  final GetCurrentUserUseCase _getCurrentUserUseCase;

  AuthStateNotifier(this._authRepository, this._getCurrentUserUseCase) 
      : super(const AsyncValue.loading()) {
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    try {
      final isAuth = await _authRepository.isAuthenticated();
      if (isAuth) {
        final user = await _getCurrentUserUseCase();
        state = AsyncValue.data(user);
      } else {
        state = const AsyncValue.data(null);
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> login(String username, String password) async {
    state = const AsyncValue.loading();
    try {
      await _authRepository.login(username, password);
      final user = await _getCurrentUserUseCase();
      state = AsyncValue.data(user);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> logout() async {
    try {
      await _authRepository.logout();
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> refreshUser() async {
    try {
      final user = await _getCurrentUserUseCase();
      state = AsyncValue.data(user);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

// Convenience provider to get current user
final currentUserProvider = Provider<UserEntity?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.value;
});
