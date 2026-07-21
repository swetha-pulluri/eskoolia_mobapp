// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dashboard_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DashboardDto _$DashboardDtoFromJson(Map<String, dynamic> json) => DashboardDto(
  totalSchools: (json['totalSchools'] as num).toInt(),
  activeSchools: (json['activeSchools'] as num).toInt(),
  totalStudents: (json['totalStudents'] as num).toInt(),
  activeStudents: (json['activeStudents'] as num?)?.toInt(),
  inactiveStudents: (json['inactiveStudents'] as num?)?.toInt(),
  totalStaff: (json['totalStaff'] as num).toInt(),
  mrr: MrrDto.fromJson(json['mrr'] as Map<String, dynamic>),
  alertCount: (json['alertCount'] as num).toInt(),
  overdueCount: (json['overdueCount'] as num?)?.toInt(),
  blockedCount: (json['blockedCount'] as num?)?.toInt(),
  boardBreakdown: (json['boardBreakdown'] as List<dynamic>)
      .map((e) => BoardBreakdownDto.fromJson(e as Map<String, dynamic>))
      .toList(),
  trends: TrendsDto.fromJson(json['trends'] as Map<String, dynamic>),
  recentEvents: (json['recentEvents'] as List<dynamic>?)
      ?.map((e) => RecentEventDto.fromJson(e as Map<String, dynamic>))
      .toList(),
  stateBreakdown: (json['stateBreakdown'] as List<dynamic>?)
      ?.map((e) => StateBreakdownDto.fromJson(e as Map<String, dynamic>))
      .toList(),
  planBreakdown: (json['planBreakdown'] as List<dynamic>?)
      ?.map((e) => PlanBreakdownDto.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$DashboardDtoToJson(DashboardDto instance) =>
    <String, dynamic>{
      'totalSchools': instance.totalSchools,
      'activeSchools': instance.activeSchools,
      'totalStudents': instance.totalStudents,
      'activeStudents': instance.activeStudents,
      'inactiveStudents': instance.inactiveStudents,
      'totalStaff': instance.totalStaff,
      'mrr': instance.mrr,
      'alertCount': instance.alertCount,
      'overdueCount': instance.overdueCount,
      'blockedCount': instance.blockedCount,
      'boardBreakdown': instance.boardBreakdown,
      'trends': instance.trends,
      'recentEvents': instance.recentEvents,
      'stateBreakdown': instance.stateBreakdown,
      'planBreakdown': instance.planBreakdown,
    };

MrrDto _$MrrDtoFromJson(Map<String, dynamic> json) => MrrDto(
  current: (json['current'] as num).toDouble(),
  previous: (json['previous'] as num).toDouble(),
  trend: (json['trend'] as num).toDouble(),
);

Map<String, dynamic> _$MrrDtoToJson(MrrDto instance) => <String, dynamic>{
  'current': instance.current,
  'previous': instance.previous,
  'trend': instance.trend,
};

BoardBreakdownDto _$BoardBreakdownDtoFromJson(Map<String, dynamic> json) =>
    BoardBreakdownDto(
      board: json['board'] as String,
      count: (json['count'] as num).toInt(),
      percent: (json['percent'] as num).toDouble(),
    );

Map<String, dynamic> _$BoardBreakdownDtoToJson(BoardBreakdownDto instance) =>
    <String, dynamic>{
      'board': instance.board,
      'count': instance.count,
      'percent': instance.percent,
    };

TrendsDto _$TrendsDtoFromJson(Map<String, dynamic> json) => TrendsDto(
  students: (json['students'] as num).toDouble(),
  mrr: (json['mrr'] as num).toDouble(),
);

Map<String, dynamic> _$TrendsDtoToJson(TrendsDto instance) => <String, dynamic>{
  'students': instance.students,
  'mrr': instance.mrr,
};

RecentEventDto _$RecentEventDtoFromJson(Map<String, dynamic> json) =>
    RecentEventDto(
      id: json['id'] as String,
      timestamp: json['timestamp'] as String,
      actor: json['actor'] as String,
      action: json['action'] as String,
      detail: json['detail'] as String,
      severity: json['severity'] as String,
      tenantId: json['tenantId'] as String?,
      schoolName: json['schoolName'] as String?,
    );

Map<String, dynamic> _$RecentEventDtoToJson(RecentEventDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'timestamp': instance.timestamp,
      'actor': instance.actor,
      'action': instance.action,
      'detail': instance.detail,
      'severity': instance.severity,
      'tenantId': instance.tenantId,
      'schoolName': instance.schoolName,
    };

StateBreakdownDto _$StateBreakdownDtoFromJson(Map<String, dynamic> json) =>
    StateBreakdownDto(
      state: json['state'] as String,
      code: json['code'] as String,
      count: (json['count'] as num).toInt(),
      students: (json['students'] as num).toInt(),
    );

Map<String, dynamic> _$StateBreakdownDtoToJson(StateBreakdownDto instance) =>
    <String, dynamic>{
      'state': instance.state,
      'code': instance.code,
      'count': instance.count,
      'students': instance.students,
    };

PlanBreakdownDto _$PlanBreakdownDtoFromJson(Map<String, dynamic> json) =>
    PlanBreakdownDto(
      plan: json['plan'] as String,
      count: (json['count'] as num).toInt(),
      mrr: (json['mrr'] as num).toDouble(),
      students: (json['students'] as num).toInt(),
    );

Map<String, dynamic> _$PlanBreakdownDtoToJson(PlanBreakdownDto instance) =>
    <String, dynamic>{
      'plan': instance.plan,
      'count': instance.count,
      'mrr': instance.mrr,
      'students': instance.students,
    };
