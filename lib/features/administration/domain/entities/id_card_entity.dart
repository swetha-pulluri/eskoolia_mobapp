/// ID Card template — mirrors backend `IdCardTemplate` /
/// `/api/v1/admissions/id-card-templates/`.
class IdCardTemplateEntity {
  final int? id;
  final String title;
  final String pageLayoutStyle; // "horizontal" | "vertical"
  final List<int> applicableRoleIds; // empty = All roles
  final String? backgroundUrl;
  final String? profileUrl;
  final String? logoUrl;
  final String? signatureUrl;

  const IdCardTemplateEntity({
    this.id,
    required this.title,
    this.pageLayoutStyle = 'horizontal',
    this.applicableRoleIds = const [],
    this.backgroundUrl,
    this.profileUrl,
    this.logoUrl,
    this.signatureUrl,
  });
}

/// Class — from `/api/v1/admissions/id-card-templates/generate-setup/`.
class ClassEntity {
  final int id;
  final String name;
  const ClassEntity({required this.id, required this.name});
}

/// Section — scoped to a class, from the same generate-setup endpoint.
class SectionEntity {
  final int id;
  final int classId;
  final String name;
  const SectionEntity({required this.id, required this.classId, required this.name});
}

/// Recipient row (student or other role) for the Generate & Print screens.
class RecipientEntity {
  final int id;
  final String label;
  final String? admissionNo;
  final String? rollNo;
  final String? className;
  final String? sectionName;
  final String? gender;
  final String? dateOfBirth;

  const RecipientEntity({
    required this.id,
    required this.label,
    this.admissionNo,
    this.rollNo,
    this.className,
    this.sectionName,
    this.gender,
    this.dateOfBirth,
  });
}
