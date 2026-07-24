import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_providers.dart' show dioProvider;
import '../../data/datasources/student_category_remote_datasource.dart';
import '../../data/datasources/student_group_remote_datasource.dart';
import '../../data/datasources/promotion_remote_datasource.dart';
import '../../data/datasources/student_remote_datasource.dart';
import '../../data/datasources/subject_assignment_remote_datasource.dart';
import '../../data/repositories/promotion_repository_impl.dart';
import '../../data/repositories/student_category_repository_impl.dart';
import '../../data/repositories/student_group_repository_impl.dart';
import '../../data/repositories/student_repository_impl.dart';
import '../../data/repositories/subject_assignment_repository_impl.dart';
import '../../domain/repositories/promotion_repository.dart';
import '../../domain/repositories/student_category_repository.dart';
import '../../domain/repositories/student_group_repository.dart';
import '../../domain/repositories/student_repository.dart';
import '../../domain/repositories/subject_assignment_repository.dart';
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

final studentCategoryRemoteDataSourceProvider = Provider<StudentCategoryRemoteDataSource>((ref) {
  final dio = ref.watch(dioProvider);
  return StudentCategoryRemoteDataSourceImpl(dio);
});

final studentCategoryRepositoryProvider = Provider<StudentCategoryRepository>((ref) {
  final remoteDataSource = ref.watch(studentCategoryRemoteDataSourceProvider);
  return StudentCategoryRepositoryImpl(remoteDataSource);
});

final studentGroupRemoteDataSourceProvider = Provider<StudentGroupRemoteDataSource>((ref) {
  final dio = ref.watch(dioProvider);
  return StudentGroupRemoteDataSourceImpl(dio);
});

final studentGroupRepositoryProvider = Provider<StudentGroupRepository>((ref) {
  final remoteDataSource = ref.watch(studentGroupRemoteDataSourceProvider);
  return StudentGroupRepositoryImpl(remoteDataSource);
});

final subjectAssignmentRemoteDataSourceProvider = Provider<SubjectAssignmentRemoteDataSource>((ref) {
  final dio = ref.watch(dioProvider);
  return SubjectAssignmentRemoteDataSourceImpl(dio);
});

final subjectAssignmentRepositoryProvider = Provider<SubjectAssignmentRepository>((ref) {
  final remoteDataSource = ref.watch(subjectAssignmentRemoteDataSourceProvider);
  return SubjectAssignmentRepositoryImpl(remoteDataSource);
});

final promotionRemoteDataSourceProvider = Provider<PromotionRemoteDataSource>((ref) {
  final dio = ref.watch(dioProvider);
  return PromotionRemoteDataSourceImpl(dio);
});

final promotionRepositoryProvider = Provider<PromotionRepository>((ref) {
  final remoteDataSource = ref.watch(promotionRemoteDataSourceProvider);
  return PromotionRepositoryImpl(remoteDataSource);
});
