import '../models/fees_home_data.dart';
import '../models/fees_payment.dart';
import '../models/fees_student_ref.dart';
import '../models/fees_summary.dart';

/// Seam over the Fees Home screen's read-only data needs.
/// Reference: frontend components/fees/FeesPaymentsPanel.tsx (feesApi calls).
abstract class FeesRepository {
  Future<FeesSummary> fetchAssignmentsSummary();

  /// Never throws — the backend has no `/fees/home/` route yet, so this
  /// mirrors the web app's silently-swallowed 404 by returning an empty
  /// [FeesHomeData] on any failure.
  Future<FeesHomeData> fetchHomeDashboard();

  Future<List<FeesPayment>> fetchPayments();

  Future<List<FeesStudentRef>> fetchStudents();
}
