/// School Tenancy Dashboard Entity
class DashboardEntity {
  final int totalSchools;
  final int activeSchools;
  final int totalStudents;
  final int activeStudents;
  final int inactiveStudents;
  final int totalStaff;
  final MrrEntity mrr;
  final int alertCount;
  final int overdueCount;
  final int blockedCount;
  final List<BoardBreakdownEntity> boardBreakdown;
  final TrendsEntity trends;
  final List<RecentEventEntity> recentEvents;
  final List<StateBreakdownEntity> stateBreakdown;
  final List<PlanBreakdownEntity> planBreakdown;

  const DashboardEntity({
    required this.totalSchools,
    required this.activeSchools,
    required this.totalStudents,
    required this.activeStudents,
    required this.inactiveStudents,
    required this.totalStaff,
    required this.mrr,
    required this.alertCount,
    required this.overdueCount,
    required this.blockedCount,
    required this.boardBreakdown,
    required this.trends,
    required this.recentEvents,
    required this.stateBreakdown,
    required this.planBreakdown,
  });
}

class MrrEntity {
  final double current;
  final double previous;
  final double trend;

  const MrrEntity({
    required this.current,
    required this.previous,
    required this.trend,
  });
}

class BoardBreakdownEntity {
  final String board;
  final int count;
  final double percent;

  const BoardBreakdownEntity({
    required this.board,
    required this.count,
    required this.percent,
  });
}

class TrendsEntity {
  final double students;
  final double mrr;

  const TrendsEntity({
    required this.students,
    required this.mrr,
  });
}

class RecentEventEntity {
  final String id;
  final String timestamp;
  final String actor;
  final String action;
  final String detail;
  final String severity;
  final String? tenantId;
  final String? schoolName;

  const RecentEventEntity({
    required this.id,
    required this.timestamp,
    required this.actor,
    required this.action,
    required this.detail,
    required this.severity,
    this.tenantId,
    this.schoolName,
  });
}

class StateBreakdownEntity {
  final String state;
  final String code;
  final int count;
  final int students;

  const StateBreakdownEntity({
    required this.state,
    required this.code,
    required this.count,
    required this.students,
  });
}

class PlanBreakdownEntity {
  final String plan;
  final int count;
  final double mrr;
  final int students;

  const PlanBreakdownEntity({
    required this.plan,
    required this.count,
    required this.mrr,
    required this.students,
  });
}
