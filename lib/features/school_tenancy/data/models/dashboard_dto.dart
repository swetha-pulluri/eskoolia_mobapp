import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/dashboard_entity.dart';

part 'dashboard_dto.g.dart';

@JsonSerializable()
class DashboardDto {
  @JsonKey(name: 'totalSchools')
  final int totalSchools;
  
  @JsonKey(name: 'activeSchools')
  final int activeSchools;
  
  @JsonKey(name: 'totalStudents')
  final int totalStudents;
  
  @JsonKey(name: 'activeStudents')
  final int? activeStudents;
  
  @JsonKey(name: 'inactiveStudents')
  final int? inactiveStudents;
  
  @JsonKey(name: 'totalStaff')
  final int totalStaff;
  
  @JsonKey(name: 'mrr')
  final MrrDto mrr;
  
  @JsonKey(name: 'alertCount')
  final int alertCount;
  
  @JsonKey(name: 'overdueCount')
  final int? overdueCount;
  
  @JsonKey(name: 'blockedCount')
  final int? blockedCount;
  
  @JsonKey(name: 'boardBreakdown')
  final List<BoardBreakdownDto> boardBreakdown;
  
  @JsonKey(name: 'trends')
  final TrendsDto trends;
  
  @JsonKey(name: 'recentEvents')
  final List<RecentEventDto>? recentEvents;
  
  @JsonKey(name: 'stateBreakdown')
  final List<StateBreakdownDto>? stateBreakdown;
  
  @JsonKey(name: 'planBreakdown')
  final List<PlanBreakdownDto>? planBreakdown;

  DashboardDto({
    required this.totalSchools,
    required this.activeSchools,
    required this.totalStudents,
    this.activeStudents,
    this.inactiveStudents,
    required this.totalStaff,
    required this.mrr,
    required this.alertCount,
    this.overdueCount,
    this.blockedCount,
    required this.boardBreakdown,
    required this.trends,
    this.recentEvents,
    this.stateBreakdown,
    this.planBreakdown,
  });

  factory DashboardDto.fromJson(Map<String, dynamic> json) => _$DashboardDtoFromJson(json);
  
  Map<String, dynamic> toJson() => _$DashboardDtoToJson(this);

  DashboardEntity toEntity() {
    return DashboardEntity(
      totalSchools: totalSchools,
      activeSchools: activeSchools,
      totalStudents: totalStudents,
      activeStudents: activeStudents ?? 0,
      inactiveStudents: inactiveStudents ?? 0,
      totalStaff: totalStaff,
      mrr: mrr.toEntity(),
      alertCount: alertCount,
      overdueCount: overdueCount ?? 0,
      blockedCount: blockedCount ?? 0,
      boardBreakdown: boardBreakdown.map((e) => e.toEntity()).toList(),
      trends: trends.toEntity(),
      recentEvents: recentEvents?.map((e) => e.toEntity()).toList() ?? [],
      stateBreakdown: stateBreakdown?.map((e) => e.toEntity()).toList() ?? [],
      planBreakdown: planBreakdown?.map((e) => e.toEntity()).toList() ?? [],
    );
  }
}

@JsonSerializable()
class MrrDto {
  final double current;
  final double previous;
  final double trend;

  MrrDto({
    required this.current,
    required this.previous,
    required this.trend,
  });

  factory MrrDto.fromJson(Map<String, dynamic> json) => _$MrrDtoFromJson(json);
  
  Map<String, dynamic> toJson() => _$MrrDtoToJson(this);

  MrrEntity toEntity() {
    return MrrEntity(
      current: current,
      previous: previous,
      trend: trend,
    );
  }
}

@JsonSerializable()
class BoardBreakdownDto {
  final String board;
  final int count;
  final double percent;

  BoardBreakdownDto({
    required this.board,
    required this.count,
    required this.percent,
  });

  factory BoardBreakdownDto.fromJson(Map<String, dynamic> json) => _$BoardBreakdownDtoFromJson(json);
  
  Map<String, dynamic> toJson() => _$BoardBreakdownDtoToJson(this);

  BoardBreakdownEntity toEntity() {
    return BoardBreakdownEntity(
      board: board,
      count: count,
      percent: percent,
    );
  }
}

@JsonSerializable()
class TrendsDto {
  final double students;
  final double mrr;

  TrendsDto({
    required this.students,
    required this.mrr,
  });

  factory TrendsDto.fromJson(Map<String, dynamic> json) => _$TrendsDtoFromJson(json);
  
  Map<String, dynamic> toJson() => _$TrendsDtoToJson(this);

  TrendsEntity toEntity() {
    return TrendsEntity(
      students: students,
      mrr: mrr,
    );
  }
}

@JsonSerializable()
class RecentEventDto {
  final String id;
  final String timestamp;
  final String actor;
  final String action;
  final String detail;
  final String severity;
  @JsonKey(name: 'tenantId')
  final String? tenantId;
  @JsonKey(name: 'schoolName')
  final String? schoolName;

  RecentEventDto({
    required this.id,
    required this.timestamp,
    required this.actor,
    required this.action,
    required this.detail,
    required this.severity,
    this.tenantId,
    this.schoolName,
  });

  factory RecentEventDto.fromJson(Map<String, dynamic> json) => _$RecentEventDtoFromJson(json);
  
  Map<String, dynamic> toJson() => _$RecentEventDtoToJson(this);

  RecentEventEntity toEntity() {
    return RecentEventEntity(
      id: id,
      timestamp: timestamp,
      actor: actor,
      action: action,
      detail: detail,
      severity: severity,
      tenantId: tenantId,
      schoolName: schoolName,
    );
  }
}

@JsonSerializable()
class StateBreakdownDto {
  final String state;
  final String code;
  final int count;
  final int students;

  StateBreakdownDto({
    required this.state,
    required this.code,
    required this.count,
    required this.students,
  });

  factory StateBreakdownDto.fromJson(Map<String, dynamic> json) => _$StateBreakdownDtoFromJson(json);
  
  Map<String, dynamic> toJson() => _$StateBreakdownDtoToJson(this);

  StateBreakdownEntity toEntity() {
    return StateBreakdownEntity(
      state: state,
      code: code,
      count: count,
      students: students,
    );
  }
}

@JsonSerializable()
class PlanBreakdownDto {
  final String plan;
  final int count;
  final double mrr;
  final int students;

  PlanBreakdownDto({
    required this.plan,
    required this.count,
    required this.mrr,
    required this.students,
  });

  factory PlanBreakdownDto.fromJson(Map<String, dynamic> json) => _$PlanBreakdownDtoFromJson(json);
  
  Map<String, dynamic> toJson() => _$PlanBreakdownDtoToJson(this);

  PlanBreakdownEntity toEntity() {
    return PlanBreakdownEntity(
      plan: plan,
      count: count,
      mrr: mrr,
      students: students,
    );
  }
}
