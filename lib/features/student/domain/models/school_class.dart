// School Class + Section models
// Source: frontend/components/students/StudentListPanel.tsx — SchoolClass /
// Section types (used by the "Browse & edit by class" accordion).
// Backend: GET /api/v1/core/classes/ (nested sections) + GET
// /api/v1/core/sections/ (apps/core — ClassSerializer/SectionSerializer).

/// Mirrors `UNASSIGNED_SECTION_ID = -1` — a sentinel id (no real backend
/// section has this) used to represent the synthetic "Unassigned" tab that
/// the frontend appends to any class with section-less students.
const int kUnassignedSectionId = -1;

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

  /// The synthetic "Unassigned" section frontend appends per-class
  /// (`classSectionsMap`'s `push({id: UNASSIGNED_SECTION_ID, ...})`).
  factory SectionData.unassigned({required int classId, required int studentCount}) {
    return SectionData(id: kUnassignedSectionId, classId: classId, name: 'Unassigned', studentCount: studentCount);
  }

  bool get isUnassigned => id == kUnassignedSectionId;

  /// Mirrors `formatSectionLabel`: "Unassigned" for the synthetic bucket
  /// (no "Section " prefix), else "Section {name}".
  String get displayLabel => isUnassigned ? 'Unassigned' : 'Section $name';
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

  /// Mirrors `formatClassLabel`: numeric class names 1–12 become "Grade N"
  /// (the backend stores plain numeric strings for these); non-numeric
  /// names (Nursery/LKG/UKG/etc.) are shown as-is.
  String get displayLabel {
    final text = name.trim();
    if (text.isEmpty) return 'Class $id';
    final num = int.tryParse(text);
    if (num != null && num > 0 && num <= 12) return 'Grade $num';
    return text;
  }

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
