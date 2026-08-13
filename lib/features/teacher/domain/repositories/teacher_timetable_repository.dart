import '../entities/teacher_timetable_entity.dart';

abstract class TeacherTimetableRepository {
  Future<TeacherTimetableEntity> getTimetable();
}
