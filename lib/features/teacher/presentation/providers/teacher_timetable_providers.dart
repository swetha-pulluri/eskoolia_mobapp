import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/teacher_timetable_remote_datasource.dart';
import '../../data/repositories/teacher_timetable_repository_impl.dart';
import '../../domain/entities/teacher_timetable_entity.dart';
import '../../domain/repositories/teacher_timetable_repository.dart';

final teacherTimetableRemoteDataSourceProvider = Provider<TeacherTimetableRemoteDataSource>((ref) {
  return TeacherTimetableRemoteDataSource(ref.watch(dioClientProvider));
});

final teacherTimetableRepositoryProvider = Provider<TeacherTimetableRepository>((ref) {
  return TeacherTimetableRepositoryImpl(ref.watch(teacherTimetableRemoteDataSourceProvider));
});

final teacherTimetableProvider = FutureProvider.autoDispose<TeacherTimetableEntity>((ref) {
  return ref.watch(teacherTimetableRepositoryProvider).getTimetable();
});
