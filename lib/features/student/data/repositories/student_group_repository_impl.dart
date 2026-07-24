import '../../domain/models/student_group.dart';
import '../../domain/repositories/student_group_repository.dart';
import '../datasources/student_group_remote_datasource.dart';

class StudentGroupRepositoryImpl implements StudentGroupRepository {
  final StudentGroupRemoteDataSource _remote;
  StudentGroupRepositoryImpl(this._remote);

  @override
  Future<List<StudentGroup>> fetchGroups({String? type, String? search}) =>
      _remote.fetchGroups(type: type, search: search);

  @override
  Future<StudentGroupStats> fetchStats() => _remote.fetchStats();

  @override
  Future<List<GroupStudentRow>> fetchStudents({String? className, String? sectionName, String? status}) =>
      _remote.fetchStudents(className: className, sectionName: sectionName, status: status);

  @override
  Future<StudentGroup> createGroup({
    required String name,
    required String type,
    String emoji = '',
    String description = '',
    required int capacity,
    required String color,
    required String bgColor,
  }) {
    return _remote.createGroup({
      'name': name,
      'type': type,
      'emoji': emoji,
      'description': description,
      'capacity': capacity,
      'color': color,
      'bg_color': bgColor,
    });
  }

  @override
  Future<StudentGroup> updateGroup(
    int id, {
    required String name,
    String emoji = '',
    String description = '',
    int? capacity,
  }) {
    return _remote.updateGroup(id, {
      'name': name,
      'emoji': emoji,
      'description': description,
      'capacity': ?capacity,
    });
  }

  @override
  Future<void> deleteGroup(int id) => _remote.deleteGroup(id);

  @override
  Future<void> assignHouse(int studentId, int? groupId) => _remote.assignHouse(studentId, groupId);

  @override
  Future<void> bulkAssignHouse(List<int> studentIds, int? groupId) => _remote.bulkAssignHouse(studentIds, groupId);

  @override
  Future<List<int>> toggleClubMembership(int studentId, int clubId) =>
      _remote.toggleClubMembership(studentId, clubId);

  @override
  Future<void> addToClub(int studentId, int clubId) => _remote.addToClub(studentId, clubId);

  @override
  Future<List<SortwellPreviewItem>> fetchSortwellPreview(String scope) => _remote.fetchSortwellPreview(scope);

  @override
  Future<SortwellResult> runSortwell({required String method, required String scope}) =>
      _remote.runSortwell(method: method, scope: scope);
}
