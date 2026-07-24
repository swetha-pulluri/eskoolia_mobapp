import '../models/student_group.dart';

/// Seam over the real Django Groups/Clubs API (apps/students —
/// StudentGroupViewSet, `/api/v1/students/groups/...`) — confirmed genuine
/// backend persistence (not the Next.js-only proxy routes the reference
/// frontend also happens to have).
abstract class StudentGroupRepository {
  Future<List<StudentGroup>> fetchGroups({String? type, String? search});

  Future<StudentGroupStats> fetchStats();

  Future<List<GroupStudentRow>> fetchStudents({String? className, String? sectionName, String? status});

  Future<StudentGroup> createGroup({
    required String name,
    required String type,
    String emoji = '',
    String description = '',
    required int capacity,
    required String color,
    required String bgColor,
  });

  Future<StudentGroup> updateGroup(
    int id, {
    required String name,
    String emoji = '',
    String description = '',
    int? capacity,
  });

  Future<void> deleteGroup(int id);

  /// Assigns (or, with `groupId: null`, unassigns) a student's house.
  Future<void> assignHouse(int studentId, int? groupId);

  Future<void> bulkAssignHouse(List<int> studentIds, int? groupId);

  /// Add/remove a student from a club (toggle) — returns the student's
  /// resulting club id list.
  Future<List<int>> toggleClubMembership(int studentId, int clubId);

  /// Idempotently adds a student to a club (used for bulk "add selected" —
  /// never removes, unlike [toggleClubMembership]).
  Future<void> addToClub(int studentId, int clubId);

  /// Per-house share of a Sortwell distribution, for the live preview.
  Future<List<SortwellPreviewItem>> fetchSortwellPreview(String scope);

  /// Runs the Sortwell auto-distribution across all houses.
  Future<SortwellResult> runSortwell({required String method, required String scope});
}
