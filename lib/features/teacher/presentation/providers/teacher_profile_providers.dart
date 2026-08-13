import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/teacher_profile_remote_datasource.dart';
import '../../data/repositories/teacher_profile_repository_impl.dart';
import '../../domain/entities/teacher_profile_entity.dart';
import '../../domain/repositories/teacher_profile_repository.dart';

final teacherProfileRemoteDataSourceProvider = Provider<TeacherProfileRemoteDataSource>((ref) {
  return TeacherProfileRemoteDataSource(ref.watch(dioClientProvider));
});

final teacherProfileRepositoryProvider = Provider<TeacherProfileRepository>((ref) {
  return TeacherProfileRepositoryImpl(ref.watch(teacherProfileRemoteDataSourceProvider));
});

/// The signed-in teacher's own HR staff profile — fetched once per visit,
/// matching web's fetch-on-mount `useEffect` (no polling, no staff picker;
/// a teacher never has `human_resource.staff.view`).
final teacherProfileProvider = FutureProvider.autoDispose<TeacherProfileEntity>((ref) async {
  return ref.watch(teacherProfileRepositoryProvider).getMyProfile();
});
