import '../models/year_end_fee_amount_row.dart';

/// Seam over the Year-End screen's own additive data needs — next-year fee
/// amount staging and the CSV year-end report. Outstanding-dues data
/// (`getDuesByClass`), the collected/outstanding/concessions summary
/// (`assignmentsSummary`), and the list of fee groups (`listGroups`) are
/// already covered by [FeesDuesRepository] / [FeesRepository] /
/// [FeesConfigRepository] and reused as-is.
/// Reference: frontend app/(dashboard)/fees/year-end/page.tsx.
abstract class FeesYearEndRepository {
  Future<List<YearEndFeeAmountRow>> fetchGroupAmounts(int groupId);

  Future<void> saveGroupAmounts(int groupId, List<YearEndFeeAmountRow> rows);

  /// Raw CSV bytes — mobile has no browser download tray, so the caller
  /// writes these to a temp file, mirroring the same convention already
  /// used by the Dues & Reminders screen's CSV export.
  Future<List<int>> fetchReportCsv(String reportType);
}
