import '../entities/teacher_profile_entity.dart';

abstract class TeacherProfileRepository {
  /// `GET /api/v1/hr/staff/me/`.
  Future<TeacherProfileEntity> getMyProfile();
}
