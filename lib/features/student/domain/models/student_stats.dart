import 'student_data.dart';

/// Student summary/KPI stats — Source: StudentListPanel.tsx
/// StudentSummaryResponse (GET /students/students/summary/).
class StudentStats {
  final int totalCount;
  final int activeCount;
  final int inactiveCount;
  final int archivedCount;
  final int newCount;
  final int docsPendingCount;

  const StudentStats({
    required this.totalCount,
    required this.activeCount,
    required this.inactiveCount,
    required this.archivedCount,
    required this.newCount,
    required this.docsPendingCount,
  });

  /// `json` is the inner `data` object of the summary endpoint's
  /// `{success, message, data: {...}}` envelope.
  factory StudentStats.fromJson(Map<String, dynamic> json) {
    return StudentStats(
      totalCount: json['total_count'] as int? ?? 0,
      activeCount: json['active_count'] as int? ?? 0,
      inactiveCount: json['inactive_count'] as int? ?? 0,
      archivedCount: json['archived_count'] as int? ?? 0,
      newCount: json['new_count'] as int? ?? 0,
      docsPendingCount: json['docs_pending_count'] as int? ?? 0,
    );
  }
}

/// GET /students/students/ paginated response shape — matches the generic
/// `ListApiResponse` shape used by both frontend panels (lib/pagination.ts)
/// and the backend's standard DRF `{count, next, previous, results}` envelope.
class StudentsPage {
  final List<StudentData> results;
  final int count;

  const StudentsPage({required this.results, required this.count});

  factory StudentsPage.fromJson(Map<String, dynamic> json) {
    final rawResults = json['results'] as List<dynamic>? ?? const [];
    return StudentsPage(
      results: rawResults.map((e) => StudentData.fromJson(e as Map<String, dynamic>)).toList(),
      count: json['count'] as int? ?? rawResults.length,
    );
  }
}
