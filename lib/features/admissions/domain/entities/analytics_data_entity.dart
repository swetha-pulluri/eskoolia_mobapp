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

  /// Mirrors `AnalyticsOverviewView`'s response `data` shape
  /// (`views.py:1631-1747`) exactly — including the raw ORM `values()`
  /// key names `source__name`/`school_class__name` for `by_source`/`by_grade`.
  factory AnalyticsDataEntity.fromJson(Map<String, dynamic> json) {
    double asDouble(dynamic v) => (v as num?)?.toDouble() ?? 0;
    int asInt(dynamic v) => (v as num?)?.toInt() ?? 0;
    return AnalyticsDataEntity(
      total: asInt(json['total']),
      contacted: asInt(json['contacted']),
      visited: asInt(json['visited']),
      enrolled: asInt(json['enrolled']),
      declined: asInt(json['declined']),
      contactRatePct: asDouble(json['contact_rate_pct']),
      visitRatePct: asDouble(json['visit_rate_pct']),
      enrollRatePct: asDouble(json['enroll_rate_pct']),
      monthlyTrend: (json['monthly_trend'] as List? ?? const [])
          .map((e) => MonthlyTrendPoint.fromJson(e as Map<String, dynamic>))
          .toList(),
      bySource: (json['by_source'] as List? ?? const []).map((e) => SourceStat.fromJson(e as Map<String, dynamic>)).toList(),
      byGrade: (json['by_grade'] as List? ?? const []).map((e) => GradeStat.fromJson(e as Map<String, dynamic>)).toList(),
      counsellorStats: (json['counsellor_stats'] as List? ?? const [])
          .map((e) => CounsellorStat.fromJson(e as Map<String, dynamic>))
          .toList(),
      channelBreakdown: (json['channel_breakdown'] as List? ?? const [])
          .map((e) => ChannelStat.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class MonthlyTrendPoint {
  final String month; // "YYYY-MM"
  final int inquiries;
  final int enrolled;
  const MonthlyTrendPoint({required this.month, required this.inquiries, required this.enrolled});

  factory MonthlyTrendPoint.fromJson(Map<String, dynamic> json) {
    return MonthlyTrendPoint(
      month: json['month'] as String? ?? '',
      inquiries: (json['inquiries'] as num?)?.toInt() ?? 0,
      enrolled: (json['enrolled'] as num?)?.toInt() ?? 0,
    );
  }
}

class SourceStat {
  final String? sourceName;
  final int count;
  final int enrolled;
  const SourceStat({this.sourceName, required this.count, required this.enrolled});

  /// Backend key is the raw ORM `values()` field `source__name`.
  factory SourceStat.fromJson(Map<String, dynamic> json) {
    return SourceStat(
      sourceName: json['source__name'] as String?,
      count: (json['count'] as num?)?.toInt() ?? 0,
      enrolled: (json['enrolled'] as num?)?.toInt() ?? 0,
    );
  }
}

class GradeStat {
  final String? gradeName;
  final int count;
  const GradeStat({this.gradeName, required this.count});

  /// Backend key is the raw ORM `values()` field `school_class__name`.
  factory GradeStat.fromJson(Map<String, dynamic> json) {
    return GradeStat(
      gradeName: json['school_class__name'] as String?,
      count: (json['count'] as num?)?.toInt() ?? 0,
    );
  }
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

  factory CounsellorStat.fromJson(Map<String, dynamic> json) {
    return CounsellorStat(
      assigned: json['assigned'] as String? ?? '',
      total: (json['total'] as num?)?.toInt() ?? 0,
      enrolled: (json['enrolled'] as num?)?.toInt() ?? 0,
      contacted: (json['contacted'] as num?)?.toInt() ?? 0,
      conversionPct: (json['conversion_pct'] as num?)?.toDouble() ?? 0,
    );
  }
}

class ChannelStat {
  final String channel;
  final int count;
  const ChannelStat({required this.channel, required this.count});

  factory ChannelStat.fromJson(Map<String, dynamic> json) {
    return ChannelStat(
      channel: json['channel'] as String? ?? '',
      count: (json['count'] as num?)?.toInt() ?? 0,
    );
  }
}
