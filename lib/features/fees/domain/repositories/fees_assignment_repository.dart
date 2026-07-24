import '../models/assignment_student.dart';
import '../models/fee_assignment.dart';

/// Seam over the Fee Assignment screen's own data needs — students (with
/// class info) and fee assignment CRUD. Fee groups/types/schedules/academic
/// years/classes are already covered by [FeesConfigRepository] and reused
/// as-is (same live data, no need to duplicate those fetches here).
/// Reference: frontend components/fees/FeesAssignmentPanel.tsx.
abstract class FeesAssignmentRepository {
  Future<List<AssignmentStudent>> fetchStudents({int? academicYear});

  Future<List<FeeAssignment>> fetchAssignments({int? academicYear});

  /// Mirrors the source's own explicit create-or-update: callers should
  /// check for an existing assignment for (student, feesType) themselves
  /// and call [updateAssignment] instead when one exists — matching
  /// FeesAssignmentPanel.tsx's `confirmAssign`/`confirmBulkAssign`, which
  /// look up `existingAsgn` client-side before deciding create vs update.
  /// (The backend itself also upserts on the same triple, but the source
  /// never relies on that — it always resolves the branch client-side.)
  Future<FeeAssignment> createAssignment({
    required int academicYear,
    required int student,
    required int feesType,
    required String amount,
    String discountAmount = '0.00',
    String concessionAmount = '0.00',
    String? dueDate,
  });

  Future<FeeAssignment> updateAssignment(
    int id, {
    required int academicYear,
    required int student,
    required int feesType,
    required String amount,
    String discountAmount = '0.00',
    String concessionAmount = '0.00',
    String? dueDate,
  });
}
