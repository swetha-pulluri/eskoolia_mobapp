/// Mirrors `ParentMeView`'s real response (`GET /api/v1/parent/me/`)
/// field-for-field — the guardian's profile plus a lightweight children list
/// (see web's `lib/api/parent.ts`'s `ParentMe`/`ChildSummary`).
class ParentMeEntity {
  final int guardianId;
  final String name;
  final String relation;
  final String? phone;
  final String? email;
  final String? occupation;
  final List<ChildSummaryEntity> children;
  final int childrenCount;

  const ParentMeEntity({
    required this.guardianId,
    required this.name,
    required this.relation,
    this.phone,
    this.email,
    this.occupation,
    this.children = const [],
    required this.childrenCount,
  });

  factory ParentMeEntity.fromJson(Map<String, dynamic> json) => ParentMeEntity(
        guardianId: json['guardian_id'] as int? ?? 0,
        name: (json['name'] as String?) ?? '',
        relation: (json['relation'] as String?) ?? '',
        phone: json['phone'] as String?,
        email: json['email'] as String?,
        occupation: json['occupation'] as String?,
        children: ((json['children'] as List?) ?? const [])
            .map((e) => ChildSummaryEntity.fromJson(e as Map<String, dynamic>))
            .toList(),
        childrenCount: json['children_count'] as int? ?? 0,
      );
}

class ChildSummaryEntity {
  final int id;
  final String name;
  final String? admissionNo;
  final String? rollNo;
  final String className;
  final String sectionName;
  final int? classId;
  final int? sectionId;
  final String? photoUrl;
  final String? gender;

  const ChildSummaryEntity({
    required this.id,
    required this.name,
    this.admissionNo,
    this.rollNo,
    required this.className,
    required this.sectionName,
    this.classId,
    this.sectionId,
    this.photoUrl,
    this.gender,
  });

  factory ChildSummaryEntity.fromJson(Map<String, dynamic> json) => ChildSummaryEntity(
        id: json['id'] as int,
        name: (json['name'] as String?) ?? '',
        admissionNo: json['admission_no'] as String?,
        rollNo: json['roll_no'] as String?,
        className: (json['class_name'] as String?) ?? '',
        sectionName: (json['section_name'] as String?) ?? '',
        classId: json['class_id'] as int?,
        sectionId: json['section_id'] as int?,
        photoUrl: json['photo_url'] as String?,
        gender: json['gender'] as String?,
      );

  /// "Class-Section" (e.g. "5-A"), matching web's
  /// `[class_name, section_name].filter(Boolean).join("-")`.
  String get classSectionLabel => [className, sectionName].where((s) => s.isNotEmpty).join('-');
}
