// Class / Stream — Source: components/academics/foundation/panes/ClassesPane.tsx.
// Backend: apps/core — Class/Stream/ClassStream models, ClassSerializer/
// StreamSerializer, GET/POST/PATCH/DELETE /api/v1/core/classes/ +
// /api/v1/core/streams/.

import 'section_entity.dart';

class StreamDetail {
  final int id;
  final String name;
  final bool isActive;
  final int capacity;

  const StreamDetail({required this.id, required this.name, this.isActive = true, this.capacity = 35});

  factory StreamDetail.fromJson(Map<String, dynamic> json) {
    return StreamDetail(
      id: json['id'] as int,
      name: (json['name'] as String?) ?? '',
      isActive: json['is_active'] as bool? ?? true,
      capacity: json['capacity'] as int? ?? 35,
    );
  }
}

class FoundationClass {
  final int id;
  final String name;
  final int numericOrder;
  final bool isActive;
  final int totalStudents;
  final List<FoundationSection> sections;
  final List<StreamDetail> streamDetails;

  const FoundationClass({
    required this.id,
    required this.name,
    this.numericOrder = 0,
    this.isActive = true,
    this.totalStudents = 0,
    this.sections = const [],
    this.streamDetails = const [],
  });

  factory FoundationClass.fromJson(Map<String, dynamic> json) {
    final rawSections = (json['sections'] as List<dynamic>?) ?? const [];
    final streams = (json['stream_details'] as List<dynamic>?) ?? const [];
    final id = json['id'] as int;
    return FoundationClass(
      id: id,
      name: (json['name'] as String?) ?? '',
      numericOrder: json['numeric_order'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      totalStudents: json['total_students'] as int? ?? 0,
      sections: rawSections
          .map((e) => FoundationSection.fromJson({...e as Map<String, dynamic>, 'school_class': e['school_class'] ?? id}))
          .toList(),
      streamDetails: streams.map((e) => StreamDetail.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}

/// Mirrors ClassesPane.tsx's `LEVEL_OPTS`.
const List<(String value, String label, String hint)> foundationLevelOptions = [
  ('pre', 'Pre-Primary', 'Nursery / LKG / UKG'),
  ('primary', 'Primary', 'Grade 1 – 5'),
  ('middle', 'Middle School', 'Grade 6 – 8'),
  ('secondary', 'Secondary', 'Grade 9 – 10'),
  ('senior', 'Senior Secondary', 'Grade 11 – 12'),
];

/// Mirrors `NAMES_BY_LEVEL`.
const Map<String, List<String>> foundationNamesByLevel = {
  'pre': ['Nursery', 'LKG', 'UKG'],
  'primary': ['Grade 1', 'Grade 2', 'Grade 3', 'Grade 4', 'Grade 5'],
  'middle': ['Grade 6', 'Grade 7', 'Grade 8'],
  'secondary': ['Grade 9', 'Grade 10'],
  'senior': ['Grade 11', 'Grade 12'],
};

/// Mirrors `VALID_NAMES` (fallback / "Load Defaults" order).
const List<String> foundationValidClassNames = [
  'Nursery', 'LKG', 'UKG',
  'Grade 1', 'Grade 2', 'Grade 3', 'Grade 4', 'Grade 5', 'Grade 6', 'Grade 7', 'Grade 8', 'Grade 9', 'Grade 10', 'Grade 11', 'Grade 12',
];

/// Mirrors the level-based default capacity used in `handleLevelChange`.
const Map<String, int> foundationLevelDefaultCapacity = {
  'pre': 25,
  'primary': 40,
  'middle': 40,
  'secondary': 40,
  'senior': 35,
};

String foundationLevelLabel(String value) {
  return foundationLevelOptions.firstWhere((o) => o.$1 == value, orElse: () => (value, value, '')).$2;
}

/// Mirrors `inferLevel()` — classes don't store a level; it's derived from name.
String foundationInferLevel(String className) {
  final n = className.trim();
  if (n == 'Nursery' || n == 'LKG' || n == 'UKG') return 'pre';
  final m = RegExp(r'Grade\s*(\d+)').firstMatch(n);
  if (m == null) return '';
  final num = int.parse(m.group(1)!);
  if (num >= 11) return 'senior';
  if (num >= 9) return 'secondary';
  if (num >= 6) return 'middle';
  if (num >= 1) return 'primary';
  return '';
}
