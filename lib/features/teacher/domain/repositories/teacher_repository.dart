import '../entities/teacher_me_entity.dart';

abstract class TeacherRepository {
  Future<TeacherMeEntity> getMe();
}
