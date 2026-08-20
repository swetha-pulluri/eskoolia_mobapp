import '../../../student/domain/models/student_group.dart';
import '../../domain/models/competition.dart';

/// Which slice of the school roster is eligible for a given competition,
/// derived from its level/scope fields — mirrors web's `buildScopeInfo()`.
class ScopeInfo {
  final bool active;
  final List<GroupStudentRow> pool;
  final String icon;
  final String label;
  const ScopeInfo({required this.active, required this.pool, this.icon = '', this.label = ''});
}

ScopeInfo buildScopeInfo(Competition? competition, List<GroupStudentRow> students) {
  if (competition == null) return ScopeInfo(active: false, pool: students);

  switch (competition.level) {
    case CompetitionLevel.interHouse:
      final ids = [competition.houseAId, competition.houseBId].whereType<int>().toList();
      if (ids.length < 2) return ScopeInfo(active: false, pool: students);
      final pool = students.where((s) => s.currentGroupId != null && ids.contains(s.currentGroupId)).toList();
      return ScopeInfo(active: true, pool: pool, icon: '🏠', label: 'Inter-House scope');
    case CompetitionLevel.interClass:
      if (competition.classes.isEmpty) return ScopeInfo(active: false, pool: students);
      final pool = students.where((s) => competition.classes.contains(s.className)).toList();
      return ScopeInfo(
        active: true,
        pool: pool,
        icon: '🎓',
        label: 'Inter-Class: ${competition.classes.join(" · ")}',
      );
    case CompetitionLevel.intraClass:
      if (competition.className.isEmpty) return ScopeInfo(active: false, pool: students);
      final secs = competition.sections;
      final pool = students
          .where((s) => s.className == competition.className && (secs.isEmpty || secs.contains(s.sectionName)))
          .toList();
      final label = secs.isNotEmpty
          ? 'Intra-Class ${competition.className} · Sec ${secs.join(", ")}'
          : 'Intra-Class ${competition.className}';
      return ScopeInfo(active: true, pool: pool, icon: '🏫', label: label);
    default:
      return ScopeInfo(active: false, pool: students);
  }
}
