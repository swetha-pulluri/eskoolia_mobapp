import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_providers.dart' show dioProvider;
import '../../data/datasources/login_permission_remote_datasource.dart';
import '../../data/repositories/login_permission_repository_impl.dart';
import '../../domain/repositories/login_permission_repository.dart';
import 'login_permission_notifier.dart';
import 'login_permission_state.dart';

// Reuses the app-wide dioProvider (and its auth/error interceptors) defined
// in the auth feature — no separate Dio/DioClient instance for this feature.

final loginPermissionRemoteDataSourceProvider =
    Provider<LoginPermissionRemoteDataSource>((ref) {
      final dio = ref.watch(dioProvider);
      return LoginPermissionRemoteDataSourceImpl(dio);
    });

final loginPermissionRepositoryProvider = Provider<LoginPermissionRepository>((
  ref,
) {
  final remoteDataSource = ref.watch(loginPermissionRemoteDataSourceProvider);
  return LoginPermissionRepositoryImpl(remoteDataSource);
});

final loginPermissionNotifierProvider = StateNotifierProvider.autoDispose<
  LoginPermissionNotifier,
  LoginPermissionScreenState
>((ref) {
  final repository = ref.watch(loginPermissionRepositoryProvider);
  return LoginPermissionNotifier(repository);
});
