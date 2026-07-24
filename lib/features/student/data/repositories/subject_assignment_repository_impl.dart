import '../../domain/models/subject_assignment.dart';
import '../../domain/repositories/subject_assignment_repository.dart';
import '../datasources/subject_assignment_remote_datasource.dart';

class SubjectAssignmentRepositoryImpl implements SubjectAssignmentRepository {
  final SubjectAssignmentRemoteDataSource _remote;
  SubjectAssignmentRepositoryImpl(this._remote);

  @override
  Future<SubjectAssignmentStats> fetchStats() => _remote.fetchStats();

  @override
  Future<List<AssignmentClassNode>> fetchClassSectionTree() => _remote.fetchClassSectionTree();

  @override
  Future<AssignmentSectionPage> fetchSectionStudents({
    required int classId,
    required int sectionId,
    required int page,
    int pageSize = 10,
  }) {
    return _remote.fetchSectionStudents(classId: classId, sectionId: sectionId, page: page, pageSize: pageSize);
  }

  @override
  Future<void> upsertOptionalSubjects(int studentId, List<String> subjectNames) =>
      _remote.upsertOptionalSubjects(studentId, subjectNames);
}
