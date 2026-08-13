import '../../domain/entities/teacher_timetable_entity.dart';
import '../../domain/repositories/teacher_timetable_repository.dart';
import '../datasources/teacher_timetable_remote_datasource.dart';

class TeacherTimetableRepositoryImpl implements TeacherTimetableRepository {
  final TeacherTimetableRemoteDataSource _remoteDataSource;

  TeacherTimetableRepositoryImpl(this._remoteDataSource);

  @override
  Future<TeacherTimetableEntity> getTimetable() => _remoteDataSource.getTimetable();
}
