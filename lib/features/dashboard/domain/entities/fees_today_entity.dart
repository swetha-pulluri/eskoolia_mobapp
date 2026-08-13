/// Home screen → "Today's Pulse" → Today's Fees card. Reference:
/// backend/apps/fees/views.py::TodayFeesSummaryAPIView,
/// frontend/components/widgets/pulse/FeesToday.tsx.
///
/// Field names are camelCase on the wire — confirmed against the real
/// backend view, unlike most of this backend's snake_case convention (see
/// [AttendancePulseEntity]'s doc comment for the same note on that
/// endpoint) — not a porting inconsistency to "fix".
class FeesTodayEntity {
  final double collectedAmount;
  final int transactionCount;
  final int vsAvgPercent;
  final String vsAvgDay;
  final List<double> sparkline7d;

  const FeesTodayEntity({
    required this.collectedAmount,
    required this.transactionCount,
    required this.vsAvgPercent,
    required this.vsAvgDay,
    required this.sparkline7d,
  });

  /// Mirrors the web's own `EMPTY` initial-state constant
  /// (`FeesToday.tsx`) — used both before the first successful fetch and,
  /// deliberately matching the web's silent-failure behavior, on any fetch
  /// error (no error banner exists on this card in the real frontend).
  const FeesTodayEntity.empty()
      : collectedAmount = 0,
        transactionCount = 0,
        vsAvgPercent = 0,
        vsAvgDay = '',
        sparkline7d = const [];

  factory FeesTodayEntity.fromJson(Map<String, dynamic> json) {
    return FeesTodayEntity(
      collectedAmount: (json['collectedAmount'] as num?)?.toDouble() ?? 0,
      transactionCount: json['transactionCount'] as int? ?? 0,
      vsAvgPercent: json['vsAvgPercent'] as int? ?? 0,
      vsAvgDay: json['vsAvgDay'] as String? ?? '',
      sparkline7d: ((json['sparkline7d'] as List?) ?? const []).map((e) => (e as num).toDouble()).toList(),
    );
  }
}
