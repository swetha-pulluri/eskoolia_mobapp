import '../models/subject_assignment.dart';

abstract class SubjectAssignmentRepository {
  Future<SubjectAssignmentStats> fetchStats();

  Future<List<AssignmentClassNode>> fetchClassSectionTree();

  Future<AssignmentSectionPage> fetchSectionStudents({
    required int classId,
    required int sectionId,
    required int page,
    int pageSize = 10,
  });

  /// Replaces a student's optional-subject list (2nd/3rd language, sport,
  /// art) — non-empty entries only, order matters (see backend doc comment
  /// in subject_assignment_remote_datasource.dart).
  Future<void> upsertOptionalSubjects(int studentId, List<String> subjectNames);
}
