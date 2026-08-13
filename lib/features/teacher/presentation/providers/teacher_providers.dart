import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/teacher_remote_datasource.dart';
import '../../data/repositories/teacher_repository_impl.dart';
import '../../domain/entities/teacher_me_entity.dart';
import '../../domain/repositories/teacher_repository.dart';

final teacherRemoteDataSourceProvider = Provider<TeacherRemoteDataSource>((ref) {
  return TeacherRemoteDataSource(ref.watch(dioClientProvider));
});

final teacherRepositoryProvider = Provider<TeacherRepository>((ref) {
  return TeacherRepositoryImpl(ref.watch(teacherRemoteDataSourceProvider));
});

final teacherMeProvider = FutureProvider.autoDispose<TeacherMeEntity>((ref) {
  return ref.watch(teacherRepositoryProvider).getMe();
});
