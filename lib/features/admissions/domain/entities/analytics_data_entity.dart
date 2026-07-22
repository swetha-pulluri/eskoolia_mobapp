/// Mirrors backend `GET /api/v1/admissions/analytics/overview/?period=...`
/// response `data` shape, and web's local `AnalyticsData` type.
class AnalyticsDataEntity {
  final int total;
  final int contacted;
  final int visited;
  final int enrolled;
  final int declined;
  final double contactRatePct;
  final double visitRatePct;
  final double enrollRatePct;
  final List<MonthlyTrendPoint> monthlyTrend;
  final List<SourceStat> bySource;
  final List<GradeStat> byGrade;
  final List<CounsellorStat> counsellorStats;
  final List<ChannelStat> channelBreakdown;

  const AnalyticsDataEntity({
    this.total = 0,
    this.contacted = 0,
    this.visited = 0,
    this.enrolled = 0,
    this.declined = 0,
    this.contactRatePct = 0,
    this.visitRatePct = 0,
    this.enrollRatePct = 0,
    this.monthlyTrend = const [],
    this.bySource = const [],
    this.byGrade = const [],
    this.counsellorStats = const [],
    this.channelBreakdown = const [],
  });
}

class MonthlyTrendPoint {
  final String month; // "YYYY-MM"
  final int inquiries;
  final int enrolled;
  const MonthlyTrendPoint({required this.month, required this.inquiries, required this.enrolled});
}

class SourceStat {
  final String? sourceName;
  final int count;
  final int enrolled;
  const SourceStat({this.sourceName, required this.count, required this.enrolled});
}

class GradeStat {
  final String? gradeName;
  final int count;
  const GradeStat({this.gradeName, required this.count});
}

class CounsellorStat {
  final String assigned;
  final int total;
  final int enrolled;
  final int contacted;
  final double conversionPct;
  const CounsellorStat({
    required this.assigned,
    required this.total,
    required this.enrolled,
    required this.contacted,
    required this.conversionPct,
  });
}

class ChannelStat {
  final String channel;
  final int count;
  const ChannelStat({required this.channel, required this.count});
}
