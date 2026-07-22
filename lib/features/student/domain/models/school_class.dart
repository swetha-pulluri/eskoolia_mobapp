/// School Class + Section models
/// Source: frontend/components/students/StudentListPanel.tsx — SchoolClass /
/// Section types (used by the "Browse & edit by class" accordion).
/// Backend: GET /api/v1/core/classes/ (nested sections) + GET
/// /api/v1/core/sections/ (apps/core — ClassSerializer/SectionSerializer).
class SectionData {
  final int id;
  final int classId;
  final String name;
  final int studentCount;

  const SectionData({
    required this.id,
    required this.classId,
    required this.name,
    required this.studentCount,
  });

  factory SectionData.fromJson(Map<String, dynamic> json) {
    return SectionData(
      id: json['id'] as int,
      // Backend field is `school_class` (the FK id) — some call sites
      // (nested under a class) omit it since it's implied by the parent.
      classId: (json['school_class'] as int?) ?? (json['classId'] as int? ?? 0),
      name: (json['name'] as String?) ?? (json['section_name'] as String?) ?? '',
      studentCount: json['student_count'] as int? ?? 0,
    );
  }
}

class SchoolClass {
  final int id;
  final String name;
  final int totalStudents;
  final List<SectionData> sections;

  /// Class-level aggregates for the "Browse & edit by class" card's badge
  /// row. The real backend has no single endpoint that returns these
  /// up front (unlike the mock, which had every student in memory) —
  /// `specialNeedsCount` has no backing field on the Student model at all
  /// (mirrors the frontend's own client-side-only special-needs/allergy/
  /// medication filters, which are permanently inert against real data for
  /// the same reason) and stays 0. `activeCount`/`docsPendingCount` start at
  /// 0 and are filled in progressively — accumulated from real student rows
  /// as the user browses a class's sections (see StudentListNotifier),
  /// exactly mirroring the frontend's own `classSectionStudents`-driven
  /// per-class stats, which are likewise only as complete as what's been
  /// fetched so far.
  final int activeCount;
  final int specialNeedsCount;
  final int docsPendingCount;

  const SchoolClass({
    required this.id,
    required this.name,
    required this.totalStudents,
    required this.sections,
    this.activeCount = 0,
    this.specialNeedsCount = 0,
    this.docsPendingCount = 0,
  });

  factory SchoolClass.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as int;
    final rawSections = (json['sections'] as List<dynamic>?) ?? const [];
    return SchoolClass(
      id: id,
      name: (json['name'] as String?) ?? (json['class_name'] as String?) ?? '',
      totalStudents: json['total_students'] as int? ?? 0,
      sections: rawSections
          .map((e) => SectionData.fromJson({
                ...e as Map<String, dynamic>,
                // Nested sections may omit `school_class` since the parent
                // class is already known here.
                'school_class': e['school_class'] ?? id,
              }))
          .toList(),
    );
  }

  SchoolClass copyWith({
    int? activeCount,
    int? specialNeedsCount,
    int? docsPendingCount,
  }) {
    return SchoolClass(
      id: id,
      name: name,
      totalStudents: totalStudents,
      sections: sections,
      activeCount: activeCount ?? this.activeCount,
      specialNeedsCount: specialNeedsCount ?? this.specialNeedsCount,
      docsPendingCount: docsPendingCount ?? this.docsPendingCount,
    );
  }
}
