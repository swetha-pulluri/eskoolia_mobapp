/// Section — Source: components/academics/foundation/panes/SectionsPane.tsx.
/// Backend: apps/core — Section model/SectionSerializer,
/// GET/PATCH/DELETE /api/v1/core/sections/{id}/, plus custom actions
/// POST /api/v1/core/sections/replace/ and /api/v1/core/sections/bulk-delete/.
class FoundationSection {
  final int id;
  final int classId;
  final String name;
  final int capacity;
  final int studentCount;

  const FoundationSection({
    required this.id,
    required this.classId,
    required this.name,
    required this.capacity,
    required this.studentCount,
  });

  factory FoundationSection.fromJson(Map<String, dynamic> json) {
    return FoundationSection(
      id: json['id'] as int,
      classId: json['school_class'] as int? ?? 0,
      name: (json['name'] as String?) ?? '',
      capacity: json['capacity'] as int? ?? 40,
      studentCount: json['student_count'] as int? ?? 0,
    );
  }
}

/// Mirrors SectionsPane.tsx's `PATTERNS`/`PATTERN_LABELS`.
const Map<String, List<String>> foundationSectionPatterns = {
  'alpha': ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J'],
  'num': ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10'],
  'roman': ['I', 'II', 'III', 'IV', 'V', 'VI', 'VII', 'VIII', 'IX', 'X'],
};
const Map<String, String> foundationSectionPatternLabels = {
  'alpha': 'A, B, C',
  'num': '1, 2, 3',
  'roman': 'I, II, III',
};
