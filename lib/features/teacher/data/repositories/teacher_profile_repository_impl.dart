import '../../domain/entities/teacher_profile_entity.dart';
import '../../domain/repositories/teacher_profile_repository.dart';
import '../datasources/teacher_profile_remote_datasource.dart';

class TeacherProfileRepositoryImpl implements TeacherProfileRepository {
  final TeacherProfileRemoteDataSource _remoteDataSource;

  TeacherProfileRepositoryImpl(this._remoteDataSource);

  @override
  Future<TeacherProfileEntity> getMyProfile() => _remoteDataSource.getMyProfile();
}
