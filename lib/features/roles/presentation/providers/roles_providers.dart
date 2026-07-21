import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_providers.dart' show dioProvider;
import '../../data/datasources/role_remote_datasource.dart';
import '../../data/repositories/role_repository_impl.dart';
import '../../domain/repositories/role_repository.dart';
import 'roles_notifier.dart';
import 'roles_state.dart';

// Reuses the app-wide dioProvider (and its auth/error interceptors) defined
// in the auth feature — no separate Dio/DioClient instance for this feature.

final roleRemoteDataSourceProvider = Provider<RoleRemoteDataSource>((ref) {
  final dio = ref.watch(dioProvider);
  return RoleRemoteDataSourceImpl(dio);
});

final roleRepositoryProvider = Provider<RoleRepository>((ref) {
  final remoteDataSource = ref.watch(roleRemoteDataSourceProvider);
  return RoleRepositoryImpl(remoteDataSource);
});

final rolesNotifierProvider =
    StateNotifierProvider.autoDispose<RolesNotifier, RolesScreenState>((ref) {
      final repository = ref.watch(roleRepositoryProvider);
      return RolesNotifier(repository);
    });
