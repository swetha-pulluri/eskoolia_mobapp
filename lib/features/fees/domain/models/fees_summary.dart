/// GET /api/v1/fees/assignments/summary/ response.
/// Reference: backend/apps/fees/views.py::FeeAssignmentSummaryAPIView,
/// frontend lib/fees-api.ts::FeesSummary.
class FeesSummary {
  final int count;
  final String totalAssigned;
  final String totalDiscount;
  final String totalConcession;
  final String totalNet;
  final String totalPaid;
  final String totalDue;

  const FeesSummary({
    required this.count,
    required this.totalAssigned,
    required this.totalDiscount,
    required this.totalConcession,
    required this.totalNet,
    required this.totalPaid,
    required this.totalDue,
  });

  factory FeesSummary.fromJson(Map<String, dynamic> json) {
    return FeesSummary(
      count: json['count'] as int? ?? 0,
      totalAssigned: json['total_assigned']?.toString() ?? '0',
      totalDiscount: json['total_discount']?.toString() ?? '0',
      totalConcession: json['total_concession']?.toString() ?? '0',
      totalNet: json['total_net']?.toString() ?? '0',
      totalPaid: json['total_paid']?.toString() ?? '0',
      totalDue: json['total_due']?.toString() ?? '0',
    );
  }
}
