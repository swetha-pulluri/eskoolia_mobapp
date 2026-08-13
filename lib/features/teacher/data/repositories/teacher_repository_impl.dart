import '../../domain/entities/teacher_me_entity.dart';
import '../../domain/repositories/teacher_repository.dart';
import '../datasources/teacher_remote_datasource.dart';

class TeacherRepositoryImpl implements TeacherRepository {
  final TeacherRemoteDataSource _dataSource;

  TeacherRepositoryImpl(this._dataSource);

  @override
  Future<TeacherMeEntity> getMe() => _dataSource.getMe();
}
