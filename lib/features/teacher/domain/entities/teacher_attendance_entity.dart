import '../../../attendance/domain/entities/attendance_entities.dart';
import 'teacher_me_entity.dart';

/// One class+section the teacher can view attendance for — mirrors web's
/// `ViewClass` type in `app/(teacher-portal)/teacher/attendance/page.tsx`
/// exactly (`class_id, class_name, section_id, section_name, is_ct`).
class TeacherClassOptionEntity {
  final int classId;
  final String className;
  final int sectionId;
  final String sectionName;
  final bool isClassTeacher;

  const TeacherClassOptionEntity({
    required this.classId,
    required this.className,
    required this.sectionId,
    required this.sectionName,
    required this.isClassTeacher,
  });

  String get key => '$classId-$sectionId';
}

/// Builds the deduplicated list of class+section pairs the teacher is
/// assigned to, from `TeacherMeEntity` (already fetched by `teacherMeProvider`
/// for the Teacher Dashboard — reused here rather than a second call).
/// Direct port of web's `buildAllClasses(me: TeacherMe): ViewClass[]`: the
/// class-teacher section (if any) is added first, then every subject
/// assignment's sections are added if not already present, and the result is
/// sorted by class id then section name — same order web renders its class
/// selector dropdown in.
List<TeacherClassOptionEntity> buildTeacherAttendanceClassOptions(TeacherMeEntity me) {
  final map = <String, TeacherClassOptionEntity>{};
  final ct = me.classTeacherFor;
  if (ct != null) {
    map['${ct.classId}-${ct.sectionId}'] = TeacherClassOptionEntity(
      classId: ct.classId,
      className: ct.className,
      sectionId: ct.sectionId,
      sectionName: ct.sectionName,
      isClassTeacher: true,
    );
  }
  for (final subject in me.subjectAssignments) {
    for (final section in subject.sections) {
      final key = '${section.classId}-${section.sectionId}';
      if (map.containsKey(key)) continue;
      map[key] = TeacherClassOptionEntity(
        classId: section.classId,
        className: section.className,
        sectionId: section.sectionId,
        sectionName: section.sectionName,
        isClassTeacher: false,
      );
    }
  }
  final list = map.values.toList()
    ..sort((a, b) => a.classId != b.classId ? a.classId.compareTo(b.classId) : a.sectionName.compareTo(b.sectionName));
  return list;
}

/// Response shape of `POST /api/v1/teacher/attendance/students/` — mirrors
/// `TeacherAttendanceFetchView`'s response exactly (`views.py:448-458`):
/// `{date, class_id, section_id, students, is_marked, is_locked, can_edit,
/// is_holiday, holiday_name}`. `is_marked` is returned by the backend but,
/// matching web's own `RawStudent`/page-level usage, is not consumed by this
/// app either — only `students`, `is_locked`, `can_edit`, `is_holiday` and
/// `holiday_name` are read.
class TeacherAttendanceRosterEntity {
  final List<AttendanceStudentEntity> students;
  final bool isLocked;
  final bool canEdit;
  final bool isHoliday;
  final String? holidayName;

  const TeacherAttendanceRosterEntity({
    this.students = const [],
    this.isLocked = false,
    this.canEdit = false,
    this.isHoliday = false,
    this.holidayName,
  });

  factory TeacherAttendanceRosterEntity.fromJson(Map<String, dynamic> json) {
    final studentsJson = json['students'] as List? ?? const [];
    return TeacherAttendanceRosterEntity(
      students: studentsJson.map((e) => AttendanceStudentEntity.fromJson(e as Map<String, dynamic>)).toList(),
      isLocked: json['is_locked'] as bool? ?? false,
      canEdit: json['can_edit'] as bool? ?? false,
      isHoliday: json['is_holiday'] as bool? ?? false,
      holidayName: json['holiday_name'] as String?,
    );
  }
}
