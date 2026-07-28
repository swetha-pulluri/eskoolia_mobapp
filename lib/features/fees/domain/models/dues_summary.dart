/// GET /api/v1/fees/dues/summary/ response — drives the Dues & Reminders
/// screen's top 4-card stats row. Reference: FeesDuesRemindersPanel.tsx's
/// inline `summary` state type.
class DuesSummary {
  final String totalOverdueAmount; // numeric string
  final int studentsWithDues;
  final num avgDaysOverdue;
  final num pctCollected;

  const DuesSummary({
    required this.totalOverdueAmount,
    required this.studentsWithDues,
    required this.avgDaysOverdue,
    required this.pctCollected,
  });

  factory DuesSummary.fromJson(Map<String, dynamic> json) {
    return DuesSummary(
      totalOverdueAmount: json['total_overdue_amount']?.toString() ?? '0',
      studentsWithDues: (json['students_with_dues'] as num?)?.toInt() ?? 0,
      avgDaysOverdue: (json['avg_days_overdue'] as num?) ?? 0,
      pctCollected: (json['pct_collected'] as num?) ?? 0,
    );
  }
}
