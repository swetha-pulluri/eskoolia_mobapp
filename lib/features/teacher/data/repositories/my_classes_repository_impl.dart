import '../../domain/entities/my_class_entity.dart';
import '../../domain/entities/reset_password_result_entity.dart';
import '../../domain/entities/student_credentials_entity.dart';
import '../../domain/entities/student_list_item_entity.dart';
import '../../domain/entities/student_profile_entity.dart';
import '../../domain/repositories/my_classes_repository.dart';
import '../datasources/my_classes_remote_datasource.dart';

class MyClassesRepositoryImpl implements MyClassesRepository {
  final MyClassesRemoteDataSource _remoteDataSource;

  MyClassesRepositoryImpl(this._remoteDataSource);

  @override
  Future<List<MyClassEntity>> getMyClasses() => _remoteDataSource.getMyClasses();

  @override
  Future<List<StudentListItemEntity>> getStudents({required int classId, required int sectionId}) =>
      _remoteDataSource.getStudents(classId: classId, sectionId: sectionId);

  @override
  Future<StudentProfileEntity> getStudentProfile(int studentId) => _remoteDataSource.getStudentProfile(studentId);

  @override
  Future<StudentCredentialsEntity> getStudentCredentials(int studentId) =>
      _remoteDataSource.getStudentCredentials(studentId);

  @override
  Future<ResetPasswordResultEntity> resetStudentPassword(int studentId, String target) =>
      _remoteDataSource.resetStudentPassword(studentId, target);
}
