import '../models/fees_payment.dart';
import '../models/fees_reconciliation.dart';
import '../models/school_header_info.dart';

/// Seam over the Collection screen's own additive data needs — payment
/// posting, bank/UPI/cheque reconciliation records, and the authenticated
/// school header used on receipts/ledgers. Students, assignments, payments
/// listing, and fee groups are already covered by [FeesAssignmentRepository]
/// / [FeesRepository] / [FeesConfigRepository] and reused as-is.
/// Reference: frontend components/fees/FeesCollectionPanel.tsx.
abstract class FeesCollectionRepository {
  /// Do NOT pass student/status — the backend derives both (student from
  /// the assignment, status from method) per FeesCollectionPanel.tsx's own
  /// comment; sending them causes a TypeError server-side.
  Future<FeesPayment> createPayment({
    required int assignment,
    required String amountPaid,
    required String method,
    required String paidAt,
    String? note,
  });

  Future<List<FeesReconciliation>> fetchReconciliations();

  Future<FeesReconciliation> createReconciliation(FeesReconciliation draft);

  Future<SchoolHeaderInfo> fetchMySchoolInfo();
}
