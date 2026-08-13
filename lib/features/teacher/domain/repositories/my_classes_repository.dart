import '../entities/my_class_entity.dart';
import '../entities/reset_password_result_entity.dart';
import '../entities/student_credentials_entity.dart';
import '../entities/student_list_item_entity.dart';
import '../entities/student_profile_entity.dart';

abstract class MyClassesRepository {
  Future<List<MyClassEntity>> getMyClasses();
  Future<List<StudentListItemEntity>> getStudents({required int classId, required int sectionId});
  Future<StudentProfileEntity> getStudentProfile(int studentId);
  Future<StudentCredentialsEntity> getStudentCredentials(int studentId);
  Future<ResetPasswordResultEntity> resetStudentPassword(int studentId, String target);
}
