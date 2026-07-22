import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_providers.dart' show dioProvider;
import '../../data/datasources/student_remote_datasource.dart';
import '../../data/repositories/student_repository_impl.dart';
import '../../domain/repositories/student_repository.dart';
import 'student_list_notifier.dart';
import 'student_list_state.dart';

/// Reuses the app-wide dioProvider (and its auth/error interceptors) defined
/// in the auth feature — no separate Dio/DioClient instance for this
/// feature, mirroring roles_providers.dart / login_permission_providers.dart.
final studentRemoteDataSourceProvider = Provider<StudentRemoteDataSource>((ref) {
  final dio = ref.watch(dioProvider);
  return StudentRemoteDataSourceImpl(dio);
});

final studentRepositoryProvider = Provider<StudentRepository>((ref) {
  final remoteDataSource = ref.watch(studentRemoteDataSourceProvider);
  return StudentRepositoryImpl(remoteDataSource);
});

final studentListNotifierProvider =
    StateNotifierProvider.autoDispose<StudentListNotifier, StudentListState>((ref) {
      final repository = ref.watch(studentRepositoryProvider);
      return StudentListNotifier(repository);
    });
