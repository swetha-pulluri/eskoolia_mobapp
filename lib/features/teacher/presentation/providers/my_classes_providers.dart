import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/my_classes_remote_datasource.dart';
import '../../data/repositories/my_classes_repository_impl.dart';
import '../../domain/entities/my_class_entity.dart';
import '../../domain/entities/student_credentials_entity.dart';
import '../../domain/entities/student_list_item_entity.dart';
import '../../domain/entities/student_profile_entity.dart';
import '../../domain/repositories/my_classes_repository.dart';

final myClassesRemoteDataSourceProvider = Provider<MyClassesRemoteDataSource>((ref) {
  return MyClassesRemoteDataSource(ref.watch(dioClientProvider));
});

final myClassesRepositoryProvider = Provider<MyClassesRepository>((ref) {
  return MyClassesRepositoryImpl(ref.watch(myClassesRemoteDataSourceProvider));
});

final myClassesProvider = FutureProvider.autoDispose<List<MyClassEntity>>((ref) {
  return ref.watch(myClassesRepositoryProvider).getMyClasses();
});

/// Which class tab is active on the Class Overview screen. Reset to 0 every
/// time the screen mounts (autoDispose) — matches web's own behaviour of
/// always selecting `data[0]` after `fetchMyClasses()` resolves.
final activeClassIndexProvider = StateProvider.autoDispose<int>((ref) => 0);

/// Re-fetches whenever the active class changes — mirrors web's own
/// no-caching-per-tab behaviour (`selectTab` always issues a fresh
/// `fetchStudentList` call, never reuses a previously-loaded roster).
final studentsForActiveClassProvider = FutureProvider.autoDispose<List<StudentListItemEntity>>((ref) async {
  final classes = await ref.watch(myClassesProvider.future);
  if (classes.isEmpty) return const [];
  final index = ref.watch(activeClassIndexProvider);
  final activeClass = classes[index.clamp(0, classes.length - 1)];
  return ref.watch(myClassesRepositoryProvider).getStudents(classId: activeClass.classId, sectionId: activeClass.sectionId);
});

final studentProfileProvider = FutureProvider.autoDispose.family<StudentProfileEntity, int>((ref, studentId) {
  return ref.watch(myClassesRepositoryProvider).getStudentProfile(studentId);
});

final studentCredentialsProvider = FutureProvider.autoDispose.family<StudentCredentialsEntity, int>((ref, studentId) {
  return ref.watch(myClassesRepositoryProvider).getStudentCredentials(studentId);
});
